%% W02 · 실험 2-4 와 2-6 — P 만 / Experiments 2-4 and 2-6 — P only
%  모델 W02_C_P 를 Kp = 2, 10, 50 으로 돌려, 정상상태값과 오버슛을 §2-6 의 공식과 나란히 적는다.
%  Runs W02_C_P at Kp = 2, 10, 50 and prints the steady value and overshoot next to §2-6's formulas.
%
%  출력에서 볼 것 / what to look for in the output
%      - 정상상태값이 공식 Kp/(k + Kp) 와 같고 1 에 닿지 않는다: P 는 오차가 있어야 힘을 낸다.
%      - Kp 가 클수록 빠르고 더 울린다 (오버슛 16.3 -> 64.4 %).
%      - 정착시간은 Kp 를 25 배로 올려도 4.04 -> 3.64 s: 극점이 위로만 가고 왼쪽으로 가지 않는다.
%      - 첨두시간은 공식 pi/wd 와 정확히 같다.
%      - The steady value equals Kp/(k + Kp) and never reaches 1: P produces
%        force only from error.
%      - A larger Kp is faster and rings more (overshoot 16.3 -> 64.4 %).
%      - Settling barely moves (4.04 -> 3.64 s) for 25 times the gain: the poles
%        move up, not left.
%      - The peak time equals pi/wd exactly.
%
%  만드는 것 / produces: img/W02_result_P.png
%  다섯 지표를 한 응답에서 읽는 것은 실험 2-4, W02_C_five_numbers.m 이다.
%  The five metrics read off one response are Experiment 2-4, W02_C_five_numbers.m.

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
