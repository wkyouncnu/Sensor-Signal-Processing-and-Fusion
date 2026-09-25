%% W07 · 실험 7-4 — 노치 필터 / Experiment 7-4 — the notch filter
%
%  이 절이 묻는 것 / the question
%      파랑 주파수 하나만 골라서 지울 수 있는가? 지우면 무엇이 달라지는가?
%      Can one frequency be removed from the measurement, and what changes if it is?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 필터가 없는 모델과 노치가 있는 모델을 같은 바다에서 한 번씩 돌린다.
%      ② 계단이 끝난 뒤의 선수각·모멘트·회전수 통계를 나란히 찍는다.
%      ③ 노치의 주파수 응답을 그리고, 그 아래 두 실행의 모멘트를 겹쳐 그린다.
%      ① Runs the unfiltered model and the notched one in the same sea.
%      ② Prints the statistics of both, side by side.
%      ③ Plots the notch's frequency response, and the two moments below it.
%
%  출력에서 볼 것 / what to look for in the output
%      - 노치는 w0 에서 |H| = zeta_n/zeta_d = 0.167 (-15.6 dB) 로 내려간다.
%      - 모멘트의 표준편차가 18.85 -> 13.41 N m 로 줄고, 회전수의 떨림도 준다.
%      - **진짜 선수각도 좋아진다** (1.551 -> 1.042 도). 파랑을 쫓지 않으면 배가 덜 흔들린다.
%      - The notch reaches zeta_n/zeta_d = 0.167 (-15.6 dB) at w0.
%      - The moment falls from 18.85 to 13.41 N m in standard deviation.
%      - **The true heading improves as well**, 1.551 to 1.042 deg: not chasing
%        the sea leaves the vessel steadier.
%
%  만드는 것 / produces: img/W07_result_notch.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 같은 바다, 필터만 다르게 / the same sea, with and without the filter
Rn = W07_read('W07_D_no_filter');
Rf = W07_read('W07_E_notch');
V  = Rf.V;
fprintf('\n  W07 Experiment 7-4  the notch  (zeta_n %.2f, zeta_d %.2f  ->  |H(j w0)| = %.3f)\n', ...
        V.zeta_n, V.zeta_d, V.zeta_n/V.zeta_d);
fprintf('    %-12s  heading std   moment std   moment max   shaft n1 std\n', 'filter');
NAME = {'none', 'notch'};  RUN = {Rn, Rf};
for i = 1:2
    R = RUN{i};  j = R.t > 20;
    fprintf('    %-12s %9.3f deg %11.2f Nm %10.2f Nm %11.2f rad/s\n', NAME{i}, ...
            std(R.psi(j)), std(R.N(j)), max(abs(R.N(j))), std(R.n1(j)));
end

%% 2) 노치의 주파수 응답과 두 모멘트 / the notch, and the two moments
s = tf('s');
H = (s^2 + 2*V.zeta_n*V.w0*s + V.w0^2)/(s^2 + 2*V.zeta_d*V.w0*s + V.w0^2);
w = logspace(-1, 1.3, 400);  mag = squeeze(bode(H, w));
fg = lab_fig('W07 Exp 7-4  the notch', 1000, 620);
subplot(2,1,1); semilogx(w, 20*log10(mag), 'LineWidth', 2); grid on;
xline(V.w0, 'r--', '\omega_0'); ylabel('|H| [dB]'); xlabel('frequency [rad/s]');
title(sprintf('the notch: %.1f dB at \\omega_0, and 0 dB where the vessel is steered', 20*log10(V.zeta_n/V.zeta_d)));
subplot(2,1,2); hold on; grid on; xlim([20 40]);
plot(Rn.t, Rn.N, 'Color', [0.7 0.7 0.7], 'LineWidth', 1.2, 'DisplayName', 'no filter');
plot(Rf.t, Rf.N, 'LineWidth', 1.4, 'DisplayName', 'notch');
yline([-1 1]*V.N_max, 'r:', 'HandleVisibility','off');
ylabel('N [N m]'); xlabel('time [s]'); legend('Location','northeast');
title('the same sea, the same gains: what the propellers are asked for');
exportgraphics(fg, fullfile(here, 'img', 'W07_result_notch.png'), 'Resolution', 150);
