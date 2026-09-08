%% W01 · section E — the same command in four currents
%
%      W01_0_setup
%      W01_E_current_run
%
%  One command, held for the whole run: both propellers at n0, no steering.
%  Only the water changes. Whatever the track does, the vessel was never told
%  to do it.
%
%  Produces img/W01_result_current.png
%
%  SIMPLIFIED 2026-09-08, at the lecturer's request.
%
%  This section used to run sixteen simulations — four named cases and a
%  twelve-point sweep of the current direction — and draw a three-panel
%  figure plus a polar "drift rose". It made one point, and made it four
%  times over. The point is:
%
%      the command never changes, and the track changes anyway.
%
%  Four runs and one picture say that. `W01_cur_plot.m` still holds the
%  three-panel and rose drawings and nothing calls it; it is kept so they can
%  be brought back without rewriting them.

clear V CASES R M i o y f COL
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_current.slx')), W01_E_build_current; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W01_vars('current');

%% ---- four currents, one command ---------------------------------------
CASES = { 'still water',      0.0,   0
          'following, 0 deg', V.V_c,   0
          'beam, 90 deg',     V.V_c,  90
          'head, 180 deg',    V.V_c, 180 };

fprintf('\n  W01 section E — what an ocean current does to an open loop\n');
fprintf('\n  command: both propellers at n0 = %g rad/s, no steering, %g s\n', V.n0, V.T_final);
fprintf('  the command is the SAME in all four runs. Only the water changes.\n\n');
fprintf('    %-18s %14s %14s %14s\n', ...
        'current', 'ground speed', 'track [deg]', 'heading [deg]');
fprintf('    %s\n', repmat('-', 1, 62));

R = cell(size(CASES,1),1);
M = zeros(size(CASES,1), 3);
for i = 1:size(CASES,1)
    o = run_sim('W01_current', V, 'V_c', CASES{i,2}, 'beta_c', deg2rad(CASES{i,3}));
    y = W01_read(o);
    R{i} = y;
    k = y.t >= 0.8*V.T_final;                       % settled fifth of the run
    M(i,:) = [ hypot(mean(diff(y.N(k))), mean(diff(y.E(k))))/V.h, ...
               atan2d(y.E(end) - y.E(1), y.N(end) - y.N(1)), ...
               mean(y.psi(k)) ];
    fprintf('    %-18s %14.4f %14.2f %14.2f\n', CASES{i,1}, M(i,:));
end

fprintf(['\n    Same shaft speed, same thrust, no steering — and four different\n' ...
         '    answers. A following current adds %.2f m/s over the ground and a\n' ...
         '    head current takes the same amount away. The beam current is the\n' ...
         '    one to look at: it carries the vessel %.1f deg off its own heading\n' ...
         '    without any sideways force acting on the hull.\n'], ...
        V.V_c, M(3,2) - M(3,3));

%% ---- one picture: four tracks -----------------------------------------
%  The tracks alone are the whole section. The hull is drawn along each so
%  that the beam case shows what a track on its own cannot: the bow still
%  points north while the vessel travels north-east.
f   = lab_fig('W01 E  four currents', 620, 560);
COL = [0.35 0.35 0.35; 0 0.45 0.74; 0.85 0.33 0.10; 0.49 0.18 0.56];
hold on; grid on; axis equal
for i = 1:numel(R)
    plot(R{i}.E, R{i}.N, 'LineWidth', 1.6, 'Color', COL(i,:));
end
track_ships(cellfun(@(y) [y.N y.E y.psi], R, 'UniformOutput', false), COL, 'Marks', 6);
xlabel('East  [m]'); ylabel('North  [m]');
legend(CASES(:,1), 'Location','northwest');
title({'one command, four currents', ...
       'the vessel was never told to go anywhere but north'});
exportgraphics(f, fullfile(here,'img','W01_result_current.png'), 'Resolution', 150);

fprintf('\n  figure -> img/W01_result_current.png\n\n');
