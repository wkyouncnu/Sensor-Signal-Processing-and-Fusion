%% W05 · 실험 5-5 — 조류, 그리고 적분 (ILOS) / Experiment 5-5 — a current, and the integral (ILOS)
%
%  이 절이 묻는 것 / the question
%      옆에서 조류가 계속 밀면 LOS 는 경로에 붙는가? 붙지 못한다면 적분이 해결하는가?
%      With a current pushing from the side, does LOS reach the path? If not,
%      does an integral fix it?
%
%  이 스크립트가 하는 일 / what this script does
%      1) 북쪽 곧은 경로, 동쪽으로 흐르는 조류 0.1 ~ 0.4 m/s. LOS (Delta = 5 m) 의 남는 오차와
%         배가 기울어 향한 선수각을 찍고, 예측 Delta * tan(선수각) 과 나란히 적는다.
%      2) 조류 0.3 m/s 에서 ILOS 를 kappa = 0.1, 0.3, 1, 3 으로 돌린다. 마지막 100 s 의 평균 오차,
%         반대쪽으로 넘어간 거리, 마지막의 적분 상태를 찍고 그린다.
%      1) Straight path north, a current flowing east at 0.1 to 0.4 m/s. For LOS
%         (Delta = 5 m), prints the error left and the heading the vessel holds
%         into the current, next to the prediction Delta * tan(heading).
%      2) At 0.3 m/s, runs ILOS with kappa = 0.1, 0.3, 1 and 3; prints the mean
%         error over the last 100 s, the overshoot to the other side, and the
%         final integral state; plots them.
%
%  출력에서 볼 것 / what to look for in the output
%      - LOS 는 조류가 셀수록 더 멀리 남는다 (0.3 m/s 에서 2.107 m). 2~3주차의 P 가 남기던 오차와 같다:
%        배가 조류를 거슬러 비스듬히 서야 하는데, LOS 는 오차가 있어야만 비스듬히 선다.
%        남는 오차는 Delta * tan(선수각) 과 같다 (5 x tan 22.8 도 = 2.10 m).
%      - ILOS 는 오차를 없앤다. kappa 가 크면 반대쪽으로 넘어가고 (1 에서 4.10 m) 흔들린다 (3).
%      - LOS leaves an error that grows with the current (2.107 m at 0.3 m/s),
%        the error P left in Weeks 2 and 3: the vessel must point into the
%        current, and LOS only points it there while an error remains. The error
%        equals Delta * tan(heading) (5 x tan 22.8 deg = 2.10 m).
%      - ILOS removes it. A large kappa overshoots (4.10 m at 1) and swings (3).
%
%  만드는 것 / produces: img/W05_result_current.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400};   % 곧은 경로, 400 s / a straight leg, 400 s

%% 1) LOS 와 조류 / LOS in a current
fprintf('\n  W05 Experiment 5-5  1) LOS in a current flowing east  (Delta = 5 m)\n');
fprintf('    V_c [m/s]   error left [m]   heading held [deg]   Delta*tan(heading) [m]\n');
for Vc = [0.1 0.2 0.3 0.4]
    R = W05_read('W05_D_LOS', L{:}, 'V_c', Vc);
    %  마지막 값 = 정상상태 / the last sample = the steady state
    fprintf('    %-9g   %14.3f   %18.1f   %22.3f\n', Vc, R.y_e(end), R.psi(end), 5*tand(abs(R.psi(end))));
end

%% 2) ILOS, 적분 계수 kappa 를 바꾼다 / ILOS, varying the integral constant kappa
fprintf('\n  2) ILOS at 0.3 m/s  (I gain = kappa / Delta)\n');
fprintf('    kappa   mean y_e, last 100 s [m]   overshoot [m]   integral state at 400 s\n');
f = lab_fig('W05 F  current', 1000, 620);
R0 = W05_read('W05_D_LOS', L{:}, 'V_c', 0.3);                      % 비교용 LOS / LOS for comparison
subplot(2,1,1); hold on; plot(R0.t, R0.y_e, 'k', 'LineWidth', 2, 'DisplayName', 'LOS');
for kap = [0.1 0.3 1 3]
    R = W05_read('W05_F_ILOS', L{:}, 'V_c', 0.3, 'kappa', kap);
    fprintf('    %-5g   %24.3f   %13.2f   %22.2f\n', kap, mean(R.y_e(R.t > 300)), max(0, -min(R.y_e)), R.aux(end));
    subplot(2,1,1); plot(R.t, R.y_e, 'LineWidth', 1.6, 'DisplayName', sprintf('ILOS, \\kappa = %g', kap));
    subplot(2,1,2); hold on; plot(R.t, R.aux, 'LineWidth', 1.6, 'DisplayName', sprintf('\\kappa = %g', kap));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); yline(0, 'k--', 'HandleVisibility','off'); grid on; ylim([-7 21]); xlim([0 250]);
ylabel('y_e [m]'); legend('Location','northeast');
title('a 0.3 m/s current: LOS stays 2.1 m off; the integral brings ILOS onto the path');
subplot(2,1,2); grid on; xlim([0 250]); ylabel('integral state y_{int}'); xlabel('time [s]'); legend;
title('the integral grows until it holds the vessel into the current');
exportgraphics(f, fullfile(here, 'img', 'W05_result_current.png'), 'Resolution', 150);
