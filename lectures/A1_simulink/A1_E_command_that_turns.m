%% A1 · section E — the command that looks like a turn, and the one that is
%
%      A1_0_setup
%      A1_E_command_that_turns
%
%  n = [n, -n] is symmetric in the COMMAND. It is not symmetric in the FORCE,
%  because k_pos and k_neg are different numbers. Produces img/A1_result_turn.png

clear V n1 n2 CMD LBL R i o y f
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'A1_actuation.slx')), A1_1_build_actuation; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V   = A1_vars;
cfg = otter_config('base');

%% ---- the correction, derived ------------------------------------------
%  A pure yaw moment requires X = T_L + T_R = 0, that is
%
%      k_pos n1^2 + k_neg n2 |n2| = 0        with n1 > 0 and n2 < 0
%      k_pos n1^2 = k_neg n2^2
%      n2 = -n1 sqrt(k_pos/k_neg)
%
n1 = 60;
n2 = -n1*sqrt(cfg.k_pos/cfg.k_neg);

CMD = {[n1; n1], [n1; -n1], [n1; n2]};
LBL = {'ahead     [60, 60]', 'naive     [60, -60]', sprintf('corrected [60, %.2f]', n2)};

%% ---- three commands, one hull -----------------------------------------
fprintf('\n  A1 section E — three commands, %g s each\n\n', V.T_final);
fprintf('    %-24s %9s %9s %10s %10s %10s\n', ...
        'command', 'X [N]', 'N [N.m]', 'u [m/s]', 'v [m/s]', 'r [deg/s]');
fprintf('    %s\n', repmat('-', 1, 78));

R    = cell(1,3);
dft  = zeros(1,3);
for i = 1:3
    o      = run_sim('A1_actuation', V, 'n_cmd', CMD{i});
    y      = A1_read(o);
    R{i}   = struct('t', y.t, 'y', o.y(:,1:6), 'tau', y.tau);
    dft(i) = hypot(y.N(end), y.E(end));          % distance from the start point
    fprintf('    %-24s %9.3f %9.3f %10.4f %10.4f %10.4f\n', LBL{i}, ...
            y.X(end), y.Nm(end), y.u(end), y.v(end), rad2deg(y.r(end)));
end

%  The same result stated as a distance: a turn that is meant to be a turn
%  should leave the vessel where it started.
fprintf('\n    %-24s %14s %14s\n', 'turning command', 'drift [m]', 'r [deg/s]');
fprintf('    %s\n', repmat('-', 1, 56));
for i = 2:3
    fprintf('    %-24s %14.4f %14.4f\n', LBL{i}, dft(i), rad2deg(R{i}.y(end,3)));
end
fprintf('    %-24s %14.1f %14s\n', 'ratio', dft(2)/dft(3), '');

fprintf(['\n    n2 = -n1 sqrt(k_pos/k_neg) = %.4f rad/s. The corrected command\n' ...
         '    produces X = %.2e N, which is zero, AND a yaw moment %.1f per cent\n' ...
         '    LARGER than the naive one. Symmetry in the COMMAND is not\n' ...
         '    symmetry in the FORCE.\n'], ...
         n2, R{3}.tau(end,1), 100*(R{3}.tau(end,3)/R{2}.tau(end,3) - 1));

%% ---- the figure --------------------------------------------------------
f = A1_plot(R, LBL, 'A1 E — symmetry in the command is not symmetry in the force');
exportgraphics(f, fullfile(here,'img','A1_result_turn.png'), 'Resolution', 150);
fprintf('\n  figure -> img/A1_result_turn.png\n\n');
