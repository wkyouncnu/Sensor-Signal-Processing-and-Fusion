%% W02 · 절 G-0 — 저역통과 필터 Nf/(s+Nf) / Section G-0 — the low-pass filter Nf/(s+Nf)
%  보드 선도를 Nf = 5, 20, 200 에 대해 그리고, W02_G_lowpass 에 느린 사인(1 rad/s)과
%  빠른 사인(100 rad/s)을 따로 넣어 통과한 진폭을 잰다.
%  Draws the Bode plot for Nf = 5, 20, 200, then runs W02_G_lowpass with the slow
%  (1 rad/s) and the fast (100 rad/s) sine separately and measures what passes.
%
%  출력에서 볼 것 / what to look for in the output
%      - 느린 사인 (1 rad/s) 은 Nf 가 무엇이든 거의 그대로 지나간다 (0.981 ~ 1.000).
%      - 빠른 사인 (100 rad/s) 은 Nf = 5 에서 0.050, 20 에서 0.196, 200 에서 0.894 만 남는다.
%      - 잰 값이 괄호 안의 공식 Nf / sqrt(w^2 + Nf^2) 과 세 자리까지 같다.
%      - The slow sine (1 rad/s) passes almost unchanged whatever Nf is (0.981 to 1.000).
%      - Of the fast sine (100 rad/s) only 0.050 survives at Nf = 5, 0.196 at 20,
%        0.894 at 200.
%      - Every measured ratio equals Nf / sqrt(w^2 + Nf^2) to three digits.
%
%  만드는 것 / produces: img/W02_result_bode.png, img/W02_result_lowpass.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
NF = [5 20 200];

%% 1) 보드 선도 / the Bode plot
w = logspace(-1, 4, 400);
f = lab_fig('W02 G  Bode', 1000, 600);
for Nf = NF
    H = Nf./(1i*w + Nf);
    subplot(2,1,1); semilogx(w, 20*log10(abs(H)), 'LineWidth', 2, 'DisplayName', sprintf('N_f = %g', Nf)); hold on;
    subplot(2,1,2); semilogx(w, rad2deg(angle(H)), 'LineWidth', 2, 'DisplayName', sprintf('N_f = %g', Nf)); hold on;
end
subplot(2,1,1); yline(-3, 'k:', '-3 dB', 'HandleVisibility','off');
xline([1 100], 'k--', {'slow sine','fast sine'}, 'HandleVisibility','off');
grid on; ylabel('gain [dB]'); legend('Location','southwest'); ylim([-60 5]);
title('N_f / (s + N_f): flat below N_f, falling 20 dB per decade above it');
subplot(2,1,2); grid on; ylabel('phase [deg]'); xlabel('\omega [rad/s]'); ylim([-95 5]);
title('and the output lags: -45 deg exactly at \omega = N_f');
exportgraphics(f, fullfile(here, 'img', 'W02_result_bode.png'), 'Resolution', 150);

%% 2) Simulink 로 잰 통과 진폭 / the amplitude that passes, measured in Simulink
fprintf('\n  W02 G-0  the low-pass filter Nf/(s+Nf)  (bandwidth = Nf)\n');
fprintf('    Nf     slow 1 rad/s: out/in (formula)    fast 100 rad/s: out/in (formula)\n');
k = @(R) R.t > R.t(end)/2;                                       % 뒤 절반, 느린 사인 세 주기 이상 / last half, over three slow periods
g = @(R) (max(R.out(k(R))) - min(R.out(k(R))))/(max(R.in(k(R))) - min(R.in(k(R))));
for Nf = NF
    A = W02_read('W02_G_lowpass', 'Nf', Nf, 'lp_a2', 0, 'lp_T', 40);         % 느린 것만 / slow alone
    B = W02_read('W02_G_lowpass', 'Nf', Nf, 'lp_a1', 0, 'lp_T', 40);         % 빠른 것만 / fast alone
    fprintf('    %-5g  %13.3f (%5.3f)             %15.3f (%5.3f)\n', Nf, g(A), Nf/sqrt(1 + Nf^2), ...
            g(B), Nf/sqrt(100^2 + Nf^2));
end

f = lab_fig('W02 G  low-pass', 1000, 560);
for i = 1:2
    Nf = NF([1 3]);  Nf = Nf(i);
    R = W02_read('W02_G_lowpass', 'Nf', Nf);
    subplot(2,1,i); hold on; grid on;
    plot(R.t, R.in, 'Color', [0.7 0.7 0.7]);  plot(R.t, R.out, 'LineWidth', 2);
    plot(R.t, sin(R.t), 'k--');
    xlim([4 10]); ylabel('signal'); legend({'input: slow + fast','output','slow sine alone'}, 'Location','southwest');
    title(sprintf('N_f = %g: %s', Nf, ternary(Nf < 50, 'the fast sine is removed', 'the fast sine passes')));
end
xlabel('time [s]');
exportgraphics(f, fullfile(here, 'img', 'W02_result_lowpass.png'), 'Resolution', 150);

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
