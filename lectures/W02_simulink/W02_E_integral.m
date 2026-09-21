%% W02 · 절 E — I 를 더한다, 그리고 그 한계 / Section E — add I, and its limit
%  모델 W02_E_PID 를 Kp = 10, Kd = 4 에서 Ki = 0, 4, 12 로 돌린다. 적분이 남는 오차를 없앤다.
%  그다음 Ki 의 안정 한계를 구하고(이상 미분: Routh 72, 실제 필터 미분: 극점으로), 그 0.9 배와 1.1 배로 돌린다.
%  Runs W02_E_PID at Kp = 10, Kd = 4 with Ki = 0, 4, 12: the integral removes the error. Then finds the
%  stability limit on Ki and runs 0.9 and 1.1 times it.
%  만드는 것 / produces: img/W02_result_I.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
Kp = 10;  Kd = 4;  Nf = 20;  k = 2;  b = 2;

fprintf('\n  W02 E  P + I + D  (Kp = %g, Kd = %g)\n', Kp, Kd);
fprintf('    Ki   y at 10 s  overshoot %%  settle [s]  error left   I at 10 s [N]\n');
f = lab_fig('W02 E  integral', 1100, 700);
for Ki = [0 4 12]
    R = W02_read('W02_E_PID', 'Kp', Kp, 'Kd', Kd, 'Ki', Ki);
    [Mp, ts] = step_metrics(R.t, R.y, R.y(end), 1);
    fprintf('    %-3g  %9.4f  %10.1f  %10.2f  %10.2e  %12.3f\n', Ki, R.y(end), Mp, ts, 1 - R.y(end), R.I(end));
    subplot(2,2,[1 2]); hold on; plot(R.t, R.y, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
    subplot(2,2,3); hold on; plot(R.t, R.I, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
end

%  안정 한계 / the stability limit
s = tf('s');  G = 1/(s^2 + b*s + k);
C = @(ki) Kp + ki/s + Kd*Nf*s/(s + Nf);              % 모델에 들어 있는 법칙 / the law in the model
lo = 1;  hi = 500;
for it = 1:60
    ki = (lo + hi)/2;
    if max(real(pole(feedback(C(ki)*G, 1)))) < 0, lo = ki; else, hi = ki; end
end
fprintf('\n    Routh, ideal derivative:  Ki < (b + Kd)(k + Kp) = %g\n', (b + Kd)*(k + Kp));
fprintf('    the filtered law of the model is unstable above Ki = %.2f\n', lo);
fprintf('    largest error between 30 and 40 s:\n');
for g = [0.9 1.1]
    R = W02_read('W02_E_PID', 'Kp', Kp, 'Kd', Kd, 'Ki', g*lo, 'T_final', 40);
    fprintf('      Ki = %.1f x %.2f   %.3f m\n', g, lo, max(abs(R.y(R.t >= 30) - 1)));
    subplot(2,2,4); hold on; plot(R.t, R.y, 'LineWidth', 1.4, 'DisplayName', sprintf('%.1f x limit', g));
end

subplot(2,2,[1 2]); plot(R.t(R.t <= 10), R.y_d(R.t <= 10), 'k--', 'DisplayName', 'setpoint');
xlim([0 10]); ylim([0 1.15]); ylabel('position y [m]'); legend('Location','southeast'); grid on;
title('the integral removes the error that P and D leave');
subplot(2,2,3); yline(2, 'k:', 'k y_d = 2 N'); xlim([0 10]); ylabel('integral term I [N]'); xlabel('time [s]');
legend('Location','southeast'); grid on; title('it settles on the force the spring needs');
subplot(2,2,4); ylim([-4 6]); ylabel('position y [m]'); xlabel('time [s]'); legend('Location','northwest');
grid on; title(sprintf('either side of the limit K_i = %.1f', lo));
exportgraphics(f, fullfile(here, 'img', 'W02_result_I.png'), 'Resolution', 150);
