%% W02 · 실험 2-4 와 2-6 — P 만 / Experiments 2-4 and 2-6 — P only
%  모델 W02_C_P 를 Kp = 2, 10, 50 으로 돌려, 정상상태값과 오버슛을 §2-6 의 공식과 나란히 적는다.
%  Runs W02_C_P at Kp = 2, 10, 50 and prints the steady value and overshoot next to §2-6's formulas.
%
%  출력에서 볼 것 / what to look for in the output
%      - 정상상태값이 공식 Kp/(k + Kp) 와 같고 1 에 닿지 않는다: P 는 오차가 있어야 힘을 낸다.
%      - Kp 가 클수록 빠르고 더 울린다 (오버슛 16.3 -> 64.4 %).
%      - 정착시간은 Kp 를 25 배로 올려도 4.04 -> 3.64 s: 극점이 위로만 가고 왼쪽으로 가지 않는다.
%      - 첨두시간은 공식 pi/wd 와 정확히 같다. 마지막 줄은 §2-4 그림의 다섯 숫자다.
%      - The steady value equals Kp/(k + Kp) and never reaches 1: P produces
%        force only from error.
%      - A larger Kp is faster and rings more (overshoot 16.3 -> 64.4 %).
%      - Settling barely moves (4.04 -> 3.64 s) for 25 times the gain: the poles
%        move up, not left.
%      - The peak time equals pi/wd exactly. The last line is the five numbers
%        of the §2-4 figure.
%
%  만드는 것 / produces: img/W02_result_P.png, img/W02_result_metrics.png

%% 0) 경로와 플랜트 값 / paths and plant values
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
k = 2;  b = 2;                                       % 플랜트의 스프링과 감쇠 / spring and damper

%% 1) Kp 세 개: 첫째 표 (공식과 나란히), 둘째 표를 위한 값 M 을 모은다
%     Three gains: the first table (next to the formulas), and M for the second
fprintf('\n  W02 Experiment 2-6  P only\n');
fprintf('    Kp    y_ss (formula)   overshoot %% (formula)   rise [s]  settle [s]  peak tau [N]\n');
f = lab_fig('W02 Exp 2-6  P only', 1000, 620);
M = zeros(3, 8);                                     % 두 번째 표 / the second table
for Kp = [2 10 50]
    R = W02_read('W02_C_P', 'Kp', Kp);
    yss = mean(R.y(R.t > 9));
    [Mp, ts, tr] = step_metrics(R.t, R.y, yss, 1);
    z = b/(2*sqrt(k + Kp));  wn = sqrt(k + Kp);      % 감쇠비, 고유진동수 / damping ratio, natural frequency
    fprintf('    %-4g  %5.3f (%5.3f)    %6.1f (%5.1f)       %7.3f  %9.2f  %11.1f\n', Kp, yss, ...
            Kp/(k + Kp), Mp, 100*exp(-pi*z/sqrt(1 - z^2)), tr, ts, max(R.tau));
    [~, i] = max(R.y);  j = R.t >= 1;
    M(Kp == [2 10 50], :) = [Kp z wn R.t(i)-1 pi/(wn*sqrt(1 - z^2)) ts 4/(z*wn) ...
                             trapz(R.t(j), abs(R.y_d(j) - R.y(j)))];
    subplot(2,1,1); hold on; plot(R.t, R.y, 'LineWidth', 2, 'DisplayName', sprintf('K_p = %g', Kp));
    subplot(2,1,2); hold on; plot(R.t, R.tau, 'LineWidth', 1.6, 'DisplayName', sprintf('K_p = %g', Kp));
end
subplot(2,1,1); plot(R.t, R.y_d, 'k--', 'DisplayName', 'setpoint');
ylabel('position y [m]'); legend('Location','southeast'); grid on;
title('P alone: a larger K_p is faster and rings more, and never reaches 1');
subplot(2,1,2); ylabel('force \tau [N]'); xlabel('time [s]'); legend; grid on;
title('the force jumps to K_p at the step');
exportgraphics(f, fullfile(here, 'img', 'W02_result_P.png'), 'Resolution', 150);

fprintf('    Kp    zeta     wn   peak time [s] (pi/wd)   settle [s] (4/(zeta wn))   IAE over 9 s [m s]\n');
fprintf('    %-4g  %5.3f  %5.3f    %6.3f (%6.3f)          %5.2f (%5.2f)             %6.3f\n', M.');

%% 응답 하나에 다섯 숫자를 표시한다 (§2-4) / the five numbers marked on one response (§2-4)
R = W02_read('W02_C_P', 'Kp', 10);
t = R.t - 1;  y = R.y;  yss = mean(y(R.t > 9));                 % 계단 뒤의 시간 / time after the step
[Mp, ts, tr] = step_metrics(R.t, y, yss, 1);
[yp, i] = max(y);  tp = t(i);
k = t >= 0;  e = R.y_d(k) - y(k);  IAE = trapz(t(k), abs(e));
fprintf('    Kp = 10:  rise %.3f s  peak time %.3f s  overshoot %.1f %%  settle %.2f s  error %.3f m  IAE %.3f m s\n', ...
        tr, tp, Mp, ts, 1 - yss, IAE);
t1 = t(find(y >= 0.1*yss, 1));  t9 = t(find(y >= 0.9*yss, 1));
f = lab_fig('W02 Exp 2-4  five numbers', 1000, 560);  hold on; grid on;
fill([0 9 9 0], yss*[0.98 0.98 1.02 1.02], [0.85 0.85 0.85], 'EdgeColor','none');
plot(t, y, 'LineWidth', 2.2);  plot(t, R.y_d, 'k--');
plot([t1 t9], 0.9*yss*[1 1], 'g-', 'LineWidth', 4);
plot([t1 t9], [0.1 0.9]*yss, 'o', 'Color', [0 0.5 0], 'MarkerFaceColor', [0 0.8 0]);
yline([0.1 0.9]*yss, ':', 'Color', [0 0.5 0]);
xline(tp, 'r:', 'LineWidth', 1.5);  plot(tp, yp, 'ro', 'MarkerFaceColor', 'r');
plot([tp tp], [yss yp], 'r-', 'LineWidth', 3);  xline(ts, 'm:', 'LineWidth', 1.5);
plot([8.5 8.5], [yss 1], 'b-', 'LineWidth', 3);
text(t9 + 0.05, 0.9*yss - 0.05, sprintf('rise time t_r = %.2f s  (10 %% to 90 %%)', tr), 'Color', [0 0.5 0]);
text(tp + 0.08, yp, sprintf('peak time t_p = %.2f s,  overshoot M_p = %.1f %%', tp, Mp), 'Color', 'r');
text(ts + 0.08, 0.55, sprintf('settling time t_s = %.2f s\n(inside the grey 2 %% band for good)', ts), 'Color', 'm');
text(6.2, 0.93, sprintf('steady-state error e_{ss} = %.3f m', 1 - yss), 'Color', 'b');
xlim([0 9]); ylim([0 1.25]); xlabel('time after the step [s]'); ylabel('position y [m]');
title('K_p = 10, P only: five numbers read off one step response');
exportgraphics(f, fullfile(here, 'img', 'W02_result_metrics.png'), 'Resolution', 150);
