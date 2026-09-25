%% W07 · 실험 7-3 — 파랑을 쫓는 루프 / Experiment 7-3 — the loop that chases the waves
%
%  이 절이 묻는 것 / the question
%      4주차의 오토파일럿을 그대로 파랑 속에 두면 무슨 일이 생기는가?
%      What happens to the Week 4 autopilot when the sea is switched on?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W07_D_no_filter 를 파랑을 끄고 한 번, 켜고 한 번 돌린다.
%      ② 계단이 끝난 뒤(t > 20 s)의 선수각·모멘트·회전수 통계를 표로 찍는다.
%      ③ 계측 선수각과 진짜 선수각, 모멘트, 회전수를 그린다.
%      ① Runs W07_D_no_filter twice: with the sea off, then on.
%      ② Prints the statistics after the step has settled (t > 20 s).
%      ③ Plots the measured and the true heading, the moment and the shaft speeds.
%
%  출력에서 볼 것 / what to look for in the output
%      - 모멘트가 한계(70.85 N m)에 붙었다 떨어지기를 되풀이한다. 배는 파랑을
%        따라갈 힘이 없고, 있어도 따라갈 이유가 없다.
%      - 진짜 선수각도 나빠진다 (표준편차 1.55 도): 제어기가 흔들어 놓은 것이다.
%      - 회전수의 표준편차 29 rad/s — 추진기가 쉬지 않고 방향을 바꾼다.
%      - The moment keeps hitting its limit of 70.85 N m: the vessel has neither
%        the authority to follow the sea nor any reason to.
%      - The true heading gets worse too (standard deviation 1.55 deg): the
%        controller is shaking the vessel.
%      - The shaft speeds wander by 29 rad/s, reversing continually.
%
%  만드는 것 / produces: img/W07_result_chasing.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 바다를 끄고, 켜고 / the sea off, then on
fprintf('\n  W07 Experiment 7-3  the loop in waves, with no filter  (after t = 20 s)\n');
fprintf('    %-10s  heading std   moment std   moment max   shaft n1 std   time on the limit\n', 'sea');
SEA = {'off', 'on'};
for on = [0 1]
    R = W07_read('W07_D_no_filter', 'wave_on', on);
    j = R.t > 20;
    sat = sum(abs(R.N(j)) >= R.V.N_max - 1e-6) * R.V.h;   % 한계에 붙어 있던 시간 / time on the limit
    fprintf('    %-10s %9.3f deg %11.2f Nm %10.2f Nm %11.2f rad/s %10.2f s\n', ...
            SEA{on+1}, std(R.psi(j)), std(R.N(j)), max(abs(R.N(j))), std(R.n1(j)), sat);
end

%% 2) 파랑을 켠 실행을 그린다 / the run with the sea on
R = W07_read('W07_D_no_filter');
fg = lab_fig('W07 Exp 7-3  chasing the waves', 1000, 700);
subplot(3,1,1); hold on; grid on; xlim([20 40]);
plot(R.t, R.psi_m, 'Color', [0.7 0.7 0.7], 'DisplayName', 'measured (true + wave)');
plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', 'true heading');
yline(R.V.psi_step, 'k--', 'HandleVisibility','off');
ylabel('\psi [deg]'); legend('Location','northeast');
title('the controller acts on the grey line; the vessel is the blue one');
subplot(3,1,2); plot(R.t, R.N, 'LineWidth', 1.2); grid on; xlim([20 40]);
yline([-1 1]*R.V.N_max, 'r:'); ylabel('N [N m]');
title('the yaw moment, against the limit it keeps reaching');
subplot(3,1,3); hold on; grid on; xlim([20 40]);
plot(R.t, R.n1, 'LineWidth', 1.2, 'DisplayName', 'n_1');
plot(R.t, R.n2, 'LineWidth', 1.2, 'DisplayName', 'n_2');
ylabel('shaft speed [rad/s]'); xlabel('time [s]'); legend('Location','northeast');
title('and what that costs the propellers');
exportgraphics(fg, fullfile(here, 'img', 'W07_result_chasing.png'), 'Resolution', 150);
