%% W03 · 절 D — P 만 / Section D — P only
%  모델 W03_D_P 를 Kp = 50 ~ 800 으로 돌려, 남는 오차와 빠르기와 힘을 잰다.
%  Runs W03_D_P at Kp = 50 to 800: the error left, the speed of response and the force.
%  만드는 것 / produces: img/W03_result_P.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W03 D  P only  (u_d = 1.5 m/s at t = 5 s)\n');
fprintf('    Kp    final u   error left   overshoot %%   rise [s]   settle [s]   time at thrust limit [s]\n');
f = lab_fig('W03 D  P only', 1000, 620);
for Kp = [50 100 200 400 800]
    R = W03_read('W03_D_P', 'Kp', Kp);
    [Mp, ts, tr] = step_metrics(R.t, R.u, R.u(end), 5);
    fprintf('    %-4g  %7.3f   %10.3f   %11.1f   %8.2f   %10.2f   %24.2f\n', Kp, R.u(end), ...
            1.5 - R.u(end), max(Mp,0), tr, ts, sum(R.X >= R.V.X_hi - 1e-6)*R.V.h);
    subplot(2,1,1); hold on; plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_p = %g', Kp));
    subplot(2,1,2); hold on; plot(R.t, R.X, 'LineWidth', 1.6, 'DisplayName', sprintf('K_p = %g', Kp));
end
subplot(2,1,1); plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); xlim([0 20]); grid on;
ylabel('u [m/s]'); legend('Location','southeast');
title('P alone: a larger K_p leaves less error, never none, and does not ring');
subplot(2,1,2); yline(R.V.X_hi, 'r:', 'HandleVisibility','off'); xlim([0 20]); grid on;
ylabel('thrust X [N]'); xlabel('time [s]'); title('above K_p = 160 the step asks for more than 239 N');
exportgraphics(f, fullfile(here, 'img', 'W03_result_P.png'), 'Resolution', 150);
