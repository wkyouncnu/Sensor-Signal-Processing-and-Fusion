%% W02 · 절 D — D 를 더한다 / Section D — add D
%  모델 W02_D_PD 를 Kp = 10 에서 Kd = 0, 2, 6 으로 돌린다. D 는 브레이크(감쇠)이고, 남는 오차에는 손대지 못한다.
%  Runs W02_D_PD at Kp = 10 with Kd = 0, 2, 6. D is a brake (damping); it cannot touch the error left.
%  만드는 것 / produces: img/W02_result_D.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
Kp = 10;  k = 2;  b = 2;

fprintf('\n  W02 D  P + D  (Kp = %g)\n', Kp);
fprintf('    Kd   zeta   zero    overshoot %%  settle [s]  error left  peak tau [N]\n');
f = lab_fig('W02 D  P + D', 1000, 620);
for Kd = [0 2 6]
    R = W02_read('W02_D_PD', 'Kp', Kp, 'Kd', Kd);
    yss = mean(R.y(R.t > 9));
    [Mp, ts] = step_metrics(R.t, R.y, yss, 1);
    if Kd > 0, z = sprintf('%6.2f', -Kp/Kd); else, z = '  none'; end   % 영점 -Kp/Kd / the zero
    fprintf('    %-3g  %5.3f  %s  %10.1f  %10.2f  %10.3f  %11.1f\n', Kd, ...
            (b + Kd)/(2*sqrt(k + Kp)), z, Mp, ts, 1 - yss, max(R.tau));
    subplot(2,1,1); hold on; plot(R.t, R.y, 'LineWidth', 2, 'DisplayName', sprintf('K_d = %g', Kd));
    subplot(2,1,2); hold on; plot(R.t, R.D, 'LineWidth', 1.6, 'DisplayName', sprintf('K_d = %g', Kd));
end
subplot(2,1,1); plot(R.t, R.y_d, 'k--', 'DisplayName', 'setpoint');
ylabel('position y [m]'); legend('Location','southeast'); grid on;
title('K_p = 10: more K_d, less overshoot — the level 0.833 does not move');
subplot(2,1,2); xlim([0.8 4]); ylabel('D term [N]'); xlabel('time [s]'); legend; grid on;
title('the brake: a spike at the step (the kick), then negative while the error closes');
exportgraphics(f, fullfile(here, 'img', 'W02_result_D.png'), 'Resolution', 150);
