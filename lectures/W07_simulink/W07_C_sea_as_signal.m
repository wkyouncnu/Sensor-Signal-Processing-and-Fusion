%% W07 · 실험 7-2 — 바다를 신호 하나로 / Experiment 7-2 — the sea as one signal
%
%  이 절이 묻는 것 / the question
%      파랑이 제어기에게 무엇으로 보이는가? 얼마나 빠르고 얼마나 큰가?
%      What does a seaway look like to a controller: how fast, and how large?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W07_C_wave 를 한 번 돌린다. 배도 제어기도 없다 — 파랑만 있다.
%      ② 선수각과 그 변화율의 표준편차·최대값·평균을 찍는다.
%      ③ 스펙트럼을 구해 첨두가 w0 에 있는지 본다.
%      ④ 시간 이력과 스펙트럼을 그린다.
%      ① Runs W07_C_wave once: no vessel, no controller, only the sea.
%      ② Prints the standard deviation, the largest value and the mean of the
%         wave-induced heading and of its rate.
%      ③ Finds the spectrum and checks that its peak is at w0.
%      ④ Plots the time history and the spectrum.
%
%  출력에서 볼 것 / what to look for in the output
%      - 평균이 0 이다. 파랑은 배를 밀어내지 않고 **흔든다**.
%      - 선수각은 3 도 남짓인데 변화율은 11 도/s 가 넘는다. 이 배가 낼 수 있는
%        회두율이 12 도/s 이므로, 파랑을 따라가려면 배는 늘 전속으로 돌아야 한다.
%      - 스펙트럼의 첨두는 w0 = 3.14 rad/s 다. 제어 대역보다 위에 있다.
%      - The mean is zero: a wave shakes the vessel, it does not push it.
%      - The heading is about 3 deg but its rate exceeds 11 deg/s, and this vessel
%        can turn at 12 deg/s: following the sea would take everything it has.
%      - The spectrum peaks at w0 = 3.14 rad/s, above the loop's bandwidth.
%
%  만드는 것 / produces: img/W07_result_sea.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 바다만 한 번 / the sea alone, once
R = W07_read('W07_C_wave');
fprintf('\n  W07 Experiment 7-2  the sea as one signal  (Hs %.2f m, T0 %.1f s)\n', R.V.Hs, R.V.T0);
fprintf('    %-28s %8s %8s %8s\n', 'signal', 'std', 'max', 'mean');
fprintf('    %-28s %8.3f %8.3f %8.4f   [deg]\n',   'wave-induced heading', std(R.psi_w), max(abs(R.psi_w)), mean(R.psi_w));
fprintf('    %-28s %8.3f %8.3f %8.4f   [deg/s]\n', 'its rate',             std(R.r_w),   max(abs(R.r_w)),   mean(R.r_w));

%% 2) 스펙트럼의 첨두 / where the spectrum peaks
[P, f] = pwelch(R.psi_w, [], [], [], 1/R.V.h);
[~, i] = max(P);
fprintf('    the heading spectrum peaks at %.3f rad/s;  w0 = 2 pi / T0 = %.3f rad/s\n', 2*pi*f(i), R.V.w0);

%% 3) 시간 이력과 스펙트럼 / the time history and the spectrum
fg = lab_fig('W07 Exp 7-2  the sea', 1000, 620);
subplot(2,1,1); plot(R.t, R.psi_w, 'LineWidth', 1.4); grid on; xlim([0 30]);
ylabel('\psi_w [deg]'); xlabel('time [s]');
title(sprintf('one realisation of a JONSWAP sea: %d components, standard deviation %.2f deg', ...
      R.V.N_comp, std(R.psi_w)));
subplot(2,1,2); plot(2*pi*f, P, 'LineWidth', 1.6); grid on; xlim([0 12]);
xline(R.V.w0, 'r--', '\omega_0'); xlabel('frequency [rad/s]'); ylabel('power [deg^2 s]');
title('its spectrum: the energy sits in a narrow band around the peak frequency');
exportgraphics(fg, fullfile(here, 'img', 'W07_result_sea.png'), 'Resolution', 150);
