%% W02 · 절 C — P 만 / Section C — P only
%  모델 W02_C_P 를 Kp = 2, 10, 50 으로 돌려, 정상상태값과 오버슛을 §2-3 의 공식과 나란히 적는다.
%  Runs W02_C_P at Kp = 2, 10, 50 and prints the steady value and overshoot next to §2-3's formulas.
%  만드는 것 / produces: img/W02_result_P.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
k = 2;  b = 2;                                       % 플랜트의 스프링과 감쇠 / spring and damper

fprintf('\n  W02 C  P only\n');
fprintf('    Kp    y_ss (formula)   overshoot %% (formula)   rise [s]  settle [s]  peak tau [N]\n');
f = lab_fig('W02 C  P only', 1000, 620);
for Kp = [2 10 50]
    R = W02_read('W02_C_P', 'Kp', Kp);
    yss = mean(R.y(R.t > 9));
    [Mp, ts, tr] = step_metrics(R.t, R.y, yss, 1);
    z = b/(2*sqrt(k + Kp));                          % 감쇠비 / damping ratio
    fprintf('    %-4g  %5.3f (%5.3f)    %6.1f (%5.1f)       %7.3f  %9.2f  %11.1f\n', Kp, yss, ...
            Kp/(k + Kp), Mp, 100*exp(-pi*z/sqrt(1 - z^2)), tr, ts, max(R.tau));
    subplot(2,1,1); hold on; plot(R.t, R.y, 'LineWidth', 2, 'DisplayName', sprintf('K_p = %g', Kp));
    subplot(2,1,2); hold on; plot(R.t, R.tau, 'LineWidth', 1.6, 'DisplayName', sprintf('K_p = %g', Kp));
end
subplot(2,1,1); plot(R.t, R.y_d, 'k--', 'DisplayName', 'setpoint');
ylabel('position y [m]'); legend('Location','southeast'); grid on;
title('P alone: a larger K_p is faster and rings more, and never reaches 1');
subplot(2,1,2); ylabel('force \tau [N]'); xlabel('time [s]'); legend; grid on;
title('the force jumps to K_p at the step');
exportgraphics(f, fullfile(here, 'img', 'W02_result_P.png'), 'Resolution', 150);
