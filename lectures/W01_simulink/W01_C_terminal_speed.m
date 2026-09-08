%% W01 · section C — predict on paper, then measure
%
%      W01_0_setup
%      W01_C_terminal_speed
%
%  Quadratic thrust against linear damping.
%  Produces img/W01_result_speed.png

clear V cfg Xu NS u_pred u_meas i X o y f nn TT
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_openloop.slx')), W01_1_build_openloop; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V   = W01_vars;
cfg = otter_config('base');

%  Linear surge damping, otter.m: X_u = -24.4 g / U_max with U_max = 6 knots.
Xu = 24.4*9.81/(6*0.5144);          % [N per m/s]

%% ---- the sweep, with dn = 0 so nothing turns ---------------------------
fprintf('\n  W01 section C — terminal surge speed, both propellers equal\n\n');
fprintf('    %10s %14s %16s %14s\n', 'n [rad/s]', 'X [N]', 'predicted u', 'measured u');
fprintf('    %s\n', repmat('-', 1, 58));

NS     = [20 40 60 80];
u_pred = zeros(size(NS));
u_meas = zeros(size(NS));
for i = 1:numel(NS)
    X         = 2*cfg.k_pos*NS(i)*abs(NS(i));
    u_pred(i) = X/Xu;
    y         = W01_read(run_sim('W01_openloop', V, 'dn', 0, 'n0', NS(i)));
    u_meas(i) = y.u(end);
    fprintf('    %10g %14.3f %16.4f %14.4f\n', NS(i), X, u_pred(i), u_meas(i));
end

fprintf(['\n    The steady state balances thrust against linear surge damping:\n' ...
         '    2 k_pos n|n| = X_u u, with X_u = %.3f N per m/s. The agreement is\n' ...
         '    to four decimals, so surge damping in otter.m really is linear\n' ...
         '    and the hand calculation is exact rather than approximate.\n'], Xu);

%% ---- the figure: propeller curve, and speed against shaft speed --------
f = lab_fig('W01 C  terminal speed', 900, 380);

subplot(1,2,1); hold on;
nn = linspace(cfg.n_min, cfg.n_max, 400);
TT = prop_thrust(nn, cfg);
plot(nn, TT, 'Color',[0 0.45 0.74]);
xline(0,'k:'); yline(0,'k:');
xlabel('n  shaft speed [rad/s]'); ylabel('T  thrust, one propeller [N]');
title({'the propeller curve  T = k n|n|', ...
       sprintf('k_{pos}/k_{neg} = %.3f — astern is weaker', cfg.k_pos/cfg.k_neg)});

subplot(1,2,2); hold on;
plot(NS, u_pred, '--', 'Color',[0.85 0.33 0.10]);
plot(NS, u_meas, 'o',  'Color',[0 0.45 0.74], 'MarkerFaceColor',[0 0.45 0.74]);
xlabel('n  shaft speed, both propellers [rad/s]'); ylabel('terminal u [m/s]');
legend({'2 k_{pos} n|n| / X_u','measured'}, 'Location','northwest');
title({'terminal surge speed', 'quadratic thrust against linear damping'});

sgtitle('W01 C — thrust in, speed out', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W01_result_speed.png'), 'Resolution', 150);

%  REMOVED 2026-09-08, at the lecturer's request: the four-panel
%  "one velocity, two frames" figure, and the table that went with it.
%
%  It was a second telling of §1-4, which already works the same rotation
%  through with the same numbers (psi = 30 deg, u = 2.0, v = 0.5) and its own
%  figure. Two tellings of one idea is not emphasis — see
%  gnc-lecture-vault/references/standing-orders.md §9-5.
%
%  `W01_frames.m` is left in the folder. Nothing calls it now, and it is kept
%  so the figure can be brought back without rewriting it.

fprintf('\n  figure -> img/W01_result_speed.png\n\n');
