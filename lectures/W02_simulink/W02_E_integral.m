%% W02 · 실험 2-8 — I 를 더한다, 그리고 그 한계 / Experiment 2-8 — add I, and its limit
%
%  이 절이 묻는 것 / the question
%      P 와 D 가 남긴 오차를 I (적분항) 가 없앨 수 있는가? Ki 를 얼마까지 올릴 수 있는가?
%      Can I (the integral term) remove the error that P and D leave? How far
%      can Ki be raised?
%
%  이 스크립트가 하는 일 / what this script does
%      1) 모델 W02_E_PID 를 Kp = 10, Kd = 4 에 두고 Ki = 0, 4, 12 로 돌린다.
%         10 s 의 위치, 오버슛, 정착시간, 남은 오차, 10 s 의 적분항을 찍는다.
%      2) Ki 의 안정 한계를 찾는다: 이상적인 미분이면 Routh 로 72, 모델에 실제로 든
%         거른 미분이면 폐루프 극점을 이분법으로 조사해 87.07.
%      3) 그 한계의 0.9 배와 1.1 배로 40 s 를 돌려, 30 ~ 40 s 의 최대 오차를 찍는다.
%      1) Runs W02_E_PID at Kp = 10, Kd = 4 with Ki = 0, 4, 12; prints the
%         position at 10 s, overshoot, settling time, error left and integral.
%      2) Finds the stability limit on Ki: 72 by Routh for an ideal derivative;
%         87.07 for the filtered derivative in the model, by bisection on the
%         closed-loop poles.
%      3) Runs 0.9 and 1.1 times the limit for 40 s and prints the largest
%         error between 30 and 40 s.
%
%  출력에서 볼 것 / what to look for in the output
%      - Ki > 0 이면 오차가 사라지고, 적분항은 2 N 에서 멈춘다: 1 m 에서 스프링이 당기는 힘 k y_d.
%      - Ki = 4 는 느리고 (4.84 s), Ki = 12 는 빠르지만 오버슛이 돌아온다.
%      - 한계의 0.9 배는 진동이 줄고 (0.046 m), 1.1 배는 커진다 (13.4 m): 적분이 너무 크면 불안정.
%      - With Ki > 0 the error goes and the integral stops at 2 N: the spring
%        force k y_d at 1 m.
%      - Ki = 4 is slow (4.84 s); Ki = 12 is fast but the overshoot returns.
%      - At 0.9 times the limit the oscillation decays (0.046 m); at 1.1 times
%        it grows (13.4 m): too much integral destabilises.
%
%  만드는 것 / produces: img/W02_result_I.png

%% 0) 경로와 값 / paths and values
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  게인과 플랜트 (m = 1): 한계 계산에 쓴다 / gains and plant (m = 1), used for the limit
Kp = 10;  Kd = 4;  Nf = 20;  k = 2;  b = 2;

%% 1) 적분 게인 세 개 / three integral gains
fprintf('\n  W02 Experiment 2-8  P + I + D  (Kp = %g, Kd = %g)\n', Kp, Kd);
fprintf('    Ki   y at 10 s  overshoot %%  settle [s]  error left   I at 10 s [N]\n');
f = lab_fig('W02 Exp 2-8  integral', 1100, 700);
for Ki = [0 4 12]
    %  돌리고, 자기 최종값 기준으로 오버슛·정착시간을 잰다 (§2-4)
    %  Run, then measure overshoot and settling against the run's own final value (§2-4)
    R = W02_read('W02_E_PID', 'Kp', Kp, 'Kd', Kd, 'Ki', Ki);
    [Mp, ts] = step_metrics(R.t, R.y, R.y(end), 1);
    fprintf('    %-3g  %9.4f  %10.1f  %10.2f  %10.2e  %12.3f\n', Ki, R.y(end), Mp, ts, 1 - R.y(end), R.I(end));
    subplot(2,2,[1 2]); hold on; plot(R.t, R.y, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
    subplot(2,2,3); hold on; plot(R.t, R.I, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
end

%% 2) 안정 한계 / the stability limit
%  플랜트 G 와 모델에 든 법칙 C (거른 미분 포함) 로 폐루프를 만들고, 가장 오른쪽 극점의
%  실수부가 0 을 넘는 Ki 를 이분법으로 좁힌다 (60 번 반으로 나누면 충분히 정확하다).
%  Build the closed loop from the plant G and the law C in the model (filtered
%  derivative included), and bisect on the Ki at which the rightmost pole
%  crosses zero (60 halvings are ample).
s = tf('s');  G = 1/(s^2 + b*s + k);
C = @(ki) Kp + ki/s + Kd*Nf*s/(s + Nf);              % 모델에 들어 있는 법칙 / the law in the model
lo = 1;  hi = 500;
for it = 1:60
    ki = (lo + hi)/2;
    if max(real(pole(feedback(C(ki)*G, 1)))) < 0, lo = ki; else, hi = ki; end
end
fprintf('\n    Routh, ideal derivative:  Ki < (b + Kd)(k + Kp) = %g\n', (b + Kd)*(k + Kp));
fprintf('    the filtered law of the model is unstable above Ki = %.2f\n', lo);
%% 3) 한계의 양쪽에서 돌려 본다 / run either side of the limit
fprintf('    largest error between 30 and 40 s:\n');
for g = [0.9 1.1]
    R = W02_read('W02_E_PID', 'Kp', Kp, 'Kd', Kd, 'Ki', g*lo, 'T_final', 40);
    fprintf('      Ki = %.1f x %.2f   %.3f m\n', g, lo, max(abs(R.y(R.t >= 30) - 1)));
    subplot(2,2,4); hold on; plot(R.t, R.y, 'LineWidth', 1.4, 'DisplayName', sprintf('%.1f x limit', g));
end

%% 4) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,2,[1 2]); plot(R.t(R.t <= 10), R.y_d(R.t <= 10), 'k--', 'DisplayName', 'setpoint');
xlim([0 10]); ylim([0 1.15]); ylabel('position y [m]'); legend('Location','southeast'); grid on;
title('the integral removes the error that P and D leave');
subplot(2,2,3); yline(2, 'k:', 'k y_d = 2 N'); xlim([0 10]); ylabel('integral term I [N]'); xlabel('time [s]');
legend('Location','southeast'); grid on; title('it settles on the force the spring needs');
subplot(2,2,4); ylim([-4 6]); ylabel('position y [m]'); xlabel('time [s]'); legend('Location','northwest');
grid on; title(sprintf('either side of the limit K_i = %.1f', lo));
exportgraphics(f, fullfile(here, 'img', 'W02_result_I.png'), 'Resolution', 150);
