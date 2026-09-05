function out = W01_cur_run(varargin)
%W01_CUR_RUN  Run W01_current.slx for several currents and report the drift.
%
%   W01_cur_run                    the four cases of section E
%   W01_cur_run('V_c', 1.0)        override any variable
%   out = W01_cur_run(...)         the still-water run
%
%   THE EXPERIMENT
%
%   One command, held for the whole run: both propellers at n0, no steering.
%   Only the water changes. Whatever the track does, the vessel was never
%   told to do it.
%
%   Produces
%     img/W01_current.png             the block diagram
%     img/W01_result_current.png      the four tracks, and what the hull felt
%     img/W01_result_current_rose.png the drift swept over current direction

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_current.slx')), build_w01_current(); end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = base_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

%% =====================================================================
%  1. Four currents, one command
%  =====================================================================
CASES = { 'still water',      0.0,   0
          'following, 0 deg', V.V_c,   0
          'beam, 90 deg',     V.V_c,  90
          'head, 180 deg',    V.V_c, 180 };

fprintf('\n  W01 · what an ocean current does to an open loop\n');
fprintf('\n  command: both propellers at n0 = %g rad/s, no steering, %g s\n', V.n0, V.T_final);
fprintf('  current: V_c = %g m/s\n\n', V.V_c);

fprintf('    %-18s %9s %9s %9s %9s %10s %10s\n', ...
        'current', 'u [m/s]', 'u_r', 'v [m/s]', 'v_r', 'psi [deg]', 'track [deg]');
fprintf('    %s\n', repmat('-', 1, 84));

R = cell(size(CASES,1),1);
M = zeros(size(CASES,1), 6);
for i = 1:size(CASES,1)
    R{i} = one(V, 'V_c', CASES{i,2}, 'beta_c', deg2rad(CASES{i,3}));
    R{i}.V_c    = CASES{i,2};       % carried so the track plot can draw the
    R{i}.beta_c = CASES{i,3};       % current as arrows rather than words
    k    = R{i}.t >= 0.8*V.T_final;                 % settled fifth of the run
    y    = R{i}.y;
    M(i,:) = [mean(y(k,1)) mean(y(k,9)) mean(y(k,2)) mean(y(k,10)) ...
              mean(y(k,6)) trackangle(y)];
    fprintf('    %-18s %9.4f %9.4f %9.4f %9.4f %10.3f %10.3f\n', CASES{i,1}, M(i,:));
end

fprintf(['\n    STILL WATER. The track runs due north, %0.3f deg from it. Y is\n' ...
         '    structurally zero and nothing turns the vessel, so nothing can.\n'], ...
         abs(M(1,6)));

fprintf(['\n    FOLLOWING and HEAD. The heading stays at %.2f and %.2f deg and the\n' ...
         '    track stays straight, but the ground speed changes: %.4f against\n' ...
         '    %.4f m/s. Look at u_r - through the WATER the vessel settles at\n' ...
         '    %.4f and %.4f m/s, within %.4f m/s of each other. The hull cannot\n' ...
         '    tell the two runs apart; only the ground can.\n'], ...
         M(2,5), M(4,5), M(2,1), M(4,1), M(2,2), M(4,2), abs(M(2,2)-M(4,2)));

fprintf(['\n    BEAM. The track leaves the heading by %.2f deg. Nothing pushed the\n' ...
         '    vessel sideways: v_r = %.4f m/s is the water moving past the hull,\n' ...
         '    and eta_dot = J(eta) nu carries the vessel with it.\n'], ...
         M(3,6)-M(3,5), M(3,4));

dpsi = M(3,5) - M(1,5);
fprintf(['\n    And the beam case TURNS: psi drifts %.2f deg over the run with no\n' ...
         '    yaw command at all. Cross-flow drag acts on v_r, and its line of\n' ...
         '    action is not through the origin, so it makes a yaw moment. The\n' ...
         '    vessel weathervanes into the flow.\n'], dpsi);

out = R{1};

%% =====================================================================
%  2. Sweep the current direction
%  =====================================================================
BET = 0:30:330;
sw  = zeros(numel(BET), 3);
fprintf('\n  2) sweeping the current direction at V_c = %g m/s\n\n', V.V_c);
fprintf('    %10s %12s %12s %12s\n', 'beta_c [deg]', 'ground speed', 'drift [deg]', 'psi [deg]');
fprintf('    %s\n', repmat('-', 1, 52));
for i = 1:numel(BET)
    Ri = one(V, 'V_c', V.V_c, 'beta_c', deg2rad(BET(i)));
    k  = Ri.t >= 0.8*V.T_final;
    sp = hypot(mean(diff(Ri.y(k,4))), mean(diff(Ri.y(k,5)))) / V.h;
    sw(i,:) = [sp, trackangle(Ri.y) - mean(Ri.y(k,6)), mean(Ri.y(k,6))];
    fprintf('    %10g %12.4f %12.3f %12.3f\n', BET(i), sw(i,:));
end
fprintf(['\n    Ground speed is largest with the current astern and smallest with\n' ...
         '    it ahead, and the drift angle is largest on the beam. The vessel\n' ...
         '    is doing the same thing in every one of these runs.\n']);

%% =====================================================================
%  Figures
%  =====================================================================
img = @(f) fullfile(here, 'img', f);
COL = [0 0.45 0.74; 0.47 0.67 0.19; 0.85 0.33 0.10; 0.49 0.18 0.56];

load_system('W01_current');
print('-sW01_current', '-dpng', '-r150', img('W01_current.png'));
close_system('W01_current', 0);

f = W01_cur_plot(R, CASES(:,1)', V, ...
    'W01 — one command, four currents: the track the vessel was never given');
exportgraphics(f, img('W01_result_current.png'), 'Resolution', 150);

%  ---- the sweep, as a polar picture ------------------------------------
f = lab_fig('W01  current direction', 1000, 430);
subplot(1,2,1);
polarplot(deg2rad([BET BET(1)]), [sw(:,1); sw(1,1)], 'o-', ...
          'Color', COL(1,:), 'MarkerFaceColor', COL(1,:));
%  MATLAB puts 0 deg to the right and counts counter-clockwise. NED counts
%  CLOCKWISE FROM NORTH, so without these two lines the polar plot is not a
%  compass and every direction on it is wrong but plausible.
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.ThetaDir          = 'clockwise';
title({'ground speed against current direction', ...
       sprintf('north up, east right (V_c = %g m/s)', V.V_c)});
subplot(1,2,2);
plot(BET, sw(:,2), 'o-', 'Color', COL(3,:), 'MarkerFaceColor', COL(3,:));
yline(0, 'k:'); grid on;
xlabel('\beta_c  current direction [deg from north]');
ylabel('drift = track - heading [deg]');
xlim([0 330]);
title({'drift angle against current direction', 'zero when the current is fore-and-aft'});
sgtitle('W01 — the same command in twelve different currents', 'FontWeight','bold');
exportgraphics(f, img('W01_result_current_rose.png'), 'Resolution', 150);

fprintf('\n  figures written to %s\n\n', fullfile(here,'img'));
end

% =========================================================================
function o = one(V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput('W01_current');
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
evalc('r = sim(in);');
y = squeeze(r.W01c.signals.values);
if size(y,1) < size(y,2), y = y.'; end
o.t = r.W01c.time;
o.y = y;          % [u v r N E psi | u_c v_c u_r v_r]
end

function a = trackangle(y)
%TRACKANGLE  Direction of the straight line from start to finish [deg from north].
a = atan2d(y(end,5) - y(1,5), y(end,4) - y(1,4));
end

function V = base_vars()
V.n0      = 60;                 % both propellers, rad/s
V.V_c     = 0.5;                % current speed [m/s]
V.beta_c  = 0;                  % current direction [rad from north]
V.mp      = 25;
V.rp      = [0.05 0 -0.35]';
V.x0      = zeros(12,1);
V.h       = 0.02;
V.T_final = 120;
V.animate = 0;
V.animate_every = 0.5;
V.track_Nmin = -20;  V.track_Nmax = 160;
V.track_Emin = -80;  V.track_Emax =  80;
end
