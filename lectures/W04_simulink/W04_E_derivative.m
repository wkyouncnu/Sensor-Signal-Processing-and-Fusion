%% W04 · 절 E — D 를 더한다 / Section E — add D
%  W04_E_PD 에서 Kp = 300 으로 두고 Kd 를 0 ~ 200 으로 바꾼다. 10 도 선회.
%  On W04_E_PD with Kp = 300, Kd from 0 to 200, for a 10 deg turn.
%  만드는 것 / produces: img/W04_result_D.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W04 E  P + D  (Kp = 300, psi_d = 10 deg)\n');
fprintf('    Kd     overshoot %%   rise [s]   settle [s]\n');
f = lab_fig('W04 E  derivative', 1000, 460);  hold on; grid on;
for Kd = [0 10 25 50 100 150 200]
    R = W04_read('W04_E_PD', 'Kd', Kd);
    [Mp, ts, tr] = step_metrics(R.t, R.psi, 10, 5);
    fprintf('    %-5g  %11.2f   %8.2f   %10.2f\n', Kd, max(Mp,0), tr, ts);
    if any(Kd == [0 25 100 200])
        plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_d = %g', Kd));
    end
end
plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command'); xlim([3 20]);
ylabel('\psi [deg]'); xlabel('time [s]'); legend('Location','southeast');
title('on the heading D damps again: less overshoot, and too much is slow');
exportgraphics(f, fullfile(here, 'img', 'W04_result_D.png'), 'Resolution', 150);
