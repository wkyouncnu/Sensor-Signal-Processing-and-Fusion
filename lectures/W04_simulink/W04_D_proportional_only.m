%% W04 · 절 D — P 만 / Section D — P only
%  W04_D_P 를 Kp = 30 ~ 1000 으로 돌린다. 10 도 선회.
%  Runs W04_D_P at Kp = 30 to 1000, for a 10 deg turn.
%  만드는 것 / produces: img/W04_result_P.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W04 D  P only  (psi_d = 10 deg at t = 5 s)\n');
fprintf('    Kp     final psi [deg]   overshoot %%   rise [s]   settle [s]   peak |N| [N m]\n');
f = lab_fig('W04 D  P only', 1000, 620);
for Kp = [30 100 300 1000]
    R = W04_read('W04_D_P', 'Kp', Kp);
    [Mp, ts, tr] = step_metrics(R.t, R.psi, 10, 5);
    fprintf('    %-5g  %15.3f   %11.1f   %8.2f   %10.2f   %14.1f\n', Kp, R.psi(end), max(Mp,0), tr, ts, max(abs(R.N)));
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_p = %g', Kp));
    subplot(2,1,2); hold on; plot(R.t, R.N, 'LineWidth', 1.6, 'DisplayName', sprintf('K_p = %g', Kp));
end
subplot(2,1,1); plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command'); xlim([0 20]); grid on;
ylabel('\psi [deg]'); legend('Location','southeast');
title('P alone: every gain ends exactly at 10 deg; a larger gain rings more');
subplot(2,1,2); yline(R.V.N_max*[-1 1], 'r:'); xlim([0 20]); grid on;
ylabel('yaw moment N [N m]'); xlabel('time [s]'); title('the dotted red lines are the moment limit');
exportgraphics(f, fullfile(here, 'img', 'W04_result_P.png'), 'Resolution', 150);
