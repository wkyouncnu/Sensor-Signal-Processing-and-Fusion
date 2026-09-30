%% W05 · 실험 5-5b — 적분이 그 오차를 없앤다 (ILOS) / Experiment 5-5b — the integral removes it (ILOS)
%
%  이 절이 묻는 것 / the question
%      실험 5-5a 가 남긴 오차를 어떻게 없애는가? 그 값은 얼마인가?
%      How is the offset of Experiment 5-5a removed, and what does it cost?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W05_F_ILOS 를 kappa = 0.1, 0.3, 1, 3 으로 한 번씩 돌린다 (조류 0.3 m/s).
%      ② 마지막 100 s 의 평균 오차, 반대쪽으로 넘어간 양, 적분 상태의 최종값을 찍는다.
%      ③ 위 칸에 오차(LOS 포함), 아래 칸에 적분 상태를 그려 저장한다.
%      ① Runs W05_F_ILOS at kappa = 0.1, 0.3, 1 and 3, in a 0.3 m/s current.
%      ② Prints the mean error over the last 100 s, the overshoot, and the final integral state.
%      ③ Plots the errors (with LOS for comparison) above and the integral states below.
%
%  출력에서 볼 것 / what to look for in the output
%      - kappa 가 무엇이든 오차는 0 으로 간다. 적분이 조류를 대신 붙잡기 때문이다.
%      - 적분 상태가 멈추는 값은 kappa 마다 다르다: 중요한 것은 곱 (kappa/Delta) * y_int 다.
%      - kappa 가 크면 반대쪽으로 더 넘어간다 (1 에서 4.10 m, 3 에서 6.32 m).
%      - Every kappa removes the offset: the integral holds the crab angle instead.
%      - The state settles at a different value for each kappa; what matters is the product.
%      - A larger kappa swings further past the path (4.10 m at 1, 6.32 m at 3).
%
%  만드는 것 / produces: img/W05_result_current.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400};   % 곧은 경로, 400 s / a straight leg, 400 s

%% 1) 적분 계수 kappa 네 가지 / four values of the integral constant
fprintf('\n  W05 Experiment 5-5b  ILOS at 0.3 m/s  (I gain = kappa / Delta)\n');
fprintf('    kappa   mean y_e, last 100 s [m]   overshoot [m]   integral state at 400 s\n');
f = lab_fig('W05 Exp 5-5b  current', 1000, 620);
R0 = W05_read('W05_F_LOS', L{:}, 'law', 2, 'V_c', 0.3);            % 2 = LOS, 비교용 / for comparison
subplot(2,1,1); hold on; plot(R0.t, R0.y_e, 'k', 'LineWidth', 2, 'DisplayName', 'LOS');
for kap = [0.1 0.3 1 3]
    R = W05_read('W05_F_ILOS', L{:}, 'law', 3, 'V_c', 0.3, 'kappa', kap);   % 3 = ILOS
    fprintf('    %-5g   %24.3f   %13.2f   %22.2f\n', kap, mean(R.y_e(R.t > 300)), max(0, -min(R.y_e)), R.aux(end));
    subplot(2,1,1); plot(R.t, R.y_e, 'LineWidth', 1.6, 'DisplayName', sprintf('ILOS, \\kappa = %g', kap));
    subplot(2,1,2); hold on; plot(R.t, R.aux, 'LineWidth', 1.6, 'DisplayName', sprintf('\\kappa = %g', kap));
end

%% 2) 유도 8 행: 적분은 **LOS 가 남기던 바로 그 오프셋**으로 수렴하는가?
%    kappa*y_int -> Delta*tan(beta). 400 s 로는 큰 kappa 가 아직 흔들리므로 긴 다리에서
%    1100 s 를 준다. 9·11 행의 갱신 속도 한계(1/2)도 여기서 잰다.
%    Line 8 of the derivation: does the integral converge to the very offset LOS was
%    leaving? A longer leg and 1100 s, because the large kappa is still ringing at 400 s.
%    Lines 9 and 11 also measure the cap on the update rate.
Lg = {'WP_N', [0 900]', 'WP_E', [0 0]', 'T_final', 1100, 'V_c', 0.3};
RL = W05_read('W05_F_LOS', Lg{:}, 'law', 2);
fprintf('\n    line 8   the LOS offset is Delta*tan(beta) = %.4f m;  does kappa*y_int reach it?\n', ...
        R0.V.Delta * tand(abs(RL.psi(end))));
fprintf('      kappa   kappa*y_int at the end [m]   mean y_e, last 200 s [m]   max |dy_int/dt|\n');
for kap = [0.1 0.3 1 3]
    R = W05_read('W05_F_ILOS', Lg{:}, 'law', 3, 'kappa', kap);
    fprintf('      %-5g %22.4f %24.4f %17.4f\n', kap, kap*R.aux(end), ...
            mean(R.y_e(R.t > 900)), max(abs(diff(R.aux)))/R.V.h);
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); yline(0, 'k--', 'HandleVisibility','off'); grid on; ylim([-7 21]); xlim([0 250]);
ylabel('y_e [m]'); legend('Location','northeast');
title('a 0.3 m/s current: LOS stays 2.1 m off; the integral brings ILOS onto the path');
subplot(2,1,2); grid on; xlim([0 250]); ylabel('integral state y_{int}'); xlabel('time [s]'); legend;
title('the integral grows until it holds the vessel into the current');
exportgraphics(f, fullfile(here, 'img', 'W05_result_current.png'), 'Resolution', 150);
