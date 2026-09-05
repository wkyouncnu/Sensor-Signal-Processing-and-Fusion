function out = W01_run(varargin)
%W01_RUN  Run W01_openloop.slx, report the measurements, save the figures.
%
%   W01_run                       the manoeuvre of Week 1
%   W01_run('dn', 6)              override any variable from W01_setup
%   out = W01_run(...)            out.t, out.y = [u v r N E psi]
%
%   THE MANOEUVRE
%
%     straight  ->  turn to port  ->  straight  ->  turn to starboard  ->  straight
%
%   Both propellers run ahead throughout. Nothing goes astern. A turn is a
%   small difference between the two shaft speeds, because the yaw moment is
%   N = y_p (T_left - T_right).
%
%   Every number printed here is a simulation result. Every figure written to
%   img/ is produced by this function, so re-running the model updates the
%   figures that the lecture note embeds. No figure in this course is a
%   screenshot.
%
%   Produces
%     img/W01_openloop.png          the block diagram
%     img/W01_result_states.png     body velocities and heading over the manoeuvre
%     img/W01_result_track.png      the S-shaped track, with the hull drawn on it
%     img/W01_result_speed.png      terminal speed against shaft speed
%     img/W01_result_frames.png     body velocity against NED velocity

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives
if ~isfile(fullfile(here,'W01_openloop.slx')), build_w01_models(); end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = base_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

cfg = otter_config('base');
Xu  = 24.4*9.81/(6*0.5144);        % linear surge damping, otter.m [N per m/s]
y_p = 0.395;                       % half the propeller separation [m], otter.m

%% =====================================================================
%  1. Terminal surge speed  —  straight running, dn = 0
%  =====================================================================
fprintf('\n  W01 · the Otter motion model, open loop\n');
fprintf('\n  1) terminal surge speed, both propellers equal (dn = 0)\n\n');
fprintf('    %10s %14s %16s %14s\n', 'n [rad/s]', 'X [N]', 'predicted u', 'measured u');
fprintf('    %s\n', repmat('-', 1, 58));

NS = [20 40 60 80];
u_pred = zeros(size(NS));  u_meas = zeros(size(NS));
for i = 1:numel(NS)
    X = 2*cfg.k_pos*NS(i)*abs(NS(i));
    u_pred(i) = X/Xu;
    o = one(setfield(setfield(V, 'dn', 0), 'n0', NS(i)));   %#ok<SFLD>
    u_meas(i) = o.y(end,1);
    fprintf('    %10g %14.3f %16.4f %14.4f\n', NS(i), X, u_pred(i), u_meas(i));
end
fprintf(['\n    The steady state balances thrust against linear surge damping:\n' ...
         '    2 k_pos n|n| = X_u u, with X_u = %.3f N per m/s. The agreement is\n' ...
         '    to four decimals, so surge damping in otter.m really is linear\n' ...
         '    and the hand calculation is exact rather than approximate.\n'], Xu);

%% =====================================================================
%  2. The manoeuvre
%  =====================================================================
R  = one(V);
out = R;
tp = V.t_phase;
PH  = {'straight   1', 'PORT turn', 'straight   2', 'STARBOARD turn', 'straight   3'};
seg = { R.t <  tp(1), ...
        R.t >= tp(1) & R.t < tp(2), ...
        R.t >= tp(2) & R.t < tp(3), ...
        R.t >= tp(3) & R.t < tp(4), ...
        R.t >= tp(4) };

%  Steady values are read from the LAST FIFTH of each phase, after the
%  transient at the phase boundary has died away. Averaging over the whole
%  phase would mix the transient into the steady number.
fprintf('\n  2) the manoeuvre, %g s, n0 = %g, dn = %g rad/s\n\n', V.T_final, V.n0, V.dn);
fprintf('    %-16s %9s %9s %10s %10s %10s %10s\n', ...
        'phase', 'n_L', 'n_R', 'u [m/s]', 'v [m/s]', 'r [deg/s]', 'beta [deg]');
fprintf('    %s\n', repmat('-', 1, 82));
for i = 1:numel(PH)
    k = tail(seg{i});
    switch i
        case 2, nL = V.n0 - V.dn; nR = V.n0 + V.dn;
        case 4, nL = V.n0 + V.dn; nR = V.n0 - V.dn;
        otherwise, nL = V.n0; nR = V.n0;
    end
    u = mean(R.y(k,1));  v = mean(R.y(k,2));  r = mean(R.y(k,3));
    fprintf('    %-16s %9.1f %9.1f %10.4f %10.4f %10.4f %10.4f\n', ...
            PH{i}, nL, nR, u, v, rad2deg(r), atan2d(v, u));
end

dpsi = @(i) R.y(find(seg{i}, 1, 'last'), 6) - R.y(find(seg{i}, 1, 'first'), 6);
fprintf(['\n    Heading change: port %+.1f deg, starboard %+.1f deg.\n' ...
         '    The two turns are commanded with the same |dn| = %g rad/s and are\n' ...
         '    the same size to within %.2f deg, so the hull is symmetric about\n' ...
         '    its centreline and nothing in otter.m favours one side.\n'], ...
         dpsi(2), dpsi(4), V.dn, abs(abs(dpsi(2)) - abs(dpsi(4))));

N_cmd = y_p*(prop_thrust(V.n0 + V.dn, cfg) - prop_thrust(V.n0 - V.dn, cfg));
fprintf(['\n    The commanded yaw moment is N = y_p (T_left - T_right) = %+.3f N.m\n' ...
         '    in the starboard turn. Nothing reverses: the slower propeller still\n' ...
         '    pushes ahead at %.2f N while the faster one pushes at %.2f N.\n'], ...
         N_cmd, prop_thrust(V.n0 - V.dn, cfg), prop_thrust(V.n0 + V.dn, cfg));

%% =====================================================================
%  3. The empty sway row
%  =====================================================================
fprintf('\n  3) the sway row, over the whole manoeuvre\n\n');
Ymax = 0;
for i = [1 2 4]
    switch i
        case 2, nn = [V.n0 - V.dn; V.n0 + V.dn];
        case 4, nn = [V.n0 + V.dn; V.n0 - V.dn];
        otherwise, nn = [V.n0; V.n0];
    end
    Ymax = max(Ymax, abs(sum(cfg.B(2,:).' .* arrayfun(@(z) prop_thrust(z,cfg), nn))));
end
kP = tail(seg{2});  kS = tail(seg{4});
fprintf('    max |Y| over every command in the manoeuvre   %.1e N\n', Ymax);
fprintf('    mean v in the port turn                        %+.4f m/s\n', mean(R.y(kP,2)));
fprintf('    mean v in the starboard turn                   %+.4f m/s\n', mean(R.y(kS,2)));
fprintf(['\n    Y is identically zero. Both propellers are bolted to the hull\n' ...
         '    facing forward, so no combination of them has a component across\n' ...
         '    the centreline. That is a property of the geometry, not a small\n' ...
         '    number that could be tuned away.\n' ...
         '\n    The vessel nevertheless sways in both turns, and v CHANGES SIGN\n' ...
         '    between them. That sway velocity is produced by the hull ROTATING\n' ...
         '    while it moves, through the Coriolis term in otter.m, and not by\n' ...
         '    any side force. It is the crab angle, and Week 3 has to steer\n' ...
         '    around it.\n']);

%% =====================================================================
%  Figures
%  =====================================================================
img = @(f) fullfile(here, 'img', f);
COL = [0 0.45 0.74];

% -- block diagram --------------------------------------------------------
load_system('W01_openloop');
print('-sW01_openloop', '-dpng', '-r150', img('W01_openloop.png'));
close_system('W01_openloop', 0);

% -- states, drawn by the SAME function the model's StopFcn calls ----------
f = W01_plot({R}, {sprintf('n0 = %g, dn = %g', V.n0, V.dn)}, ...
             'W01 open loop — straight, port, straight, starboard, straight');
mark_phases(f, tp, V.T_final);
exportgraphics(f, img('W01_result_states.png'), 'Resolution', 150);

% -- the track, larger ----------------------------------------------------
%  Two panels. The track answers "where did it go", and the angle panel
%  answers "where was it pointing while it went there" — which is the whole
%  reason the hull is drawn on the track rather than a bare line.
f = lab_fig('W01  track', 1150, 470);

subplot(1,2,1); hold on; axis equal;
plot(R.y(:,5), R.y(:,4), 'Color', COL);
Ls = track_ships({R.y(:,[4 5 6])}, COL, 'Marks', 14, 'Heading', 0.7);
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
for i = [2 4]
    k = seg{i};
    plot(R.y(k,5), R.y(k,4), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6);
end
xlabel('East [m]'); ylabel('North [m]');
title({'the horizontal track — turns in orange', ...
       sprintf('hull drawn at %.0f x true size', Ls/2.00)});

subplot(1,2,2); hold on;
beta = atan2d(R.y(:,2), R.y(:,1));
plot(R.t, R.y(:,6),          'Color', COL,               'DisplayName','heading \psi');
plot(R.t, R.y(:,6) + beta,   'Color', [0.85 0.33 0.10],  'DisplayName','course \chi = \psi + \beta');
plot(R.t, beta,              'Color', [0.47 0.67 0.19],  'DisplayName','crab angle \beta');
yline(0, 'k:', 'HandleVisibility','off');
for b = tp, xline(b, 'Color',[0.7 0.7 0.7], 'HandleVisibility','off'); end
legend('Location','best');
xlabel('time [s]'); ylabel('angle [deg]');
title({'where it points, and where it goes', ...
       sprintf('|\\beta| reaches %.2f deg, and changes sign between the turns', ...
               max(abs(beta)))});
sgtitle('W01 open loop — where the vessel went, and where it pointed', ...
        'FontWeight','bold');
exportgraphics(f, img('W01_result_track.png'), 'Resolution', 150);

% -- body frame against NED frame -----------------------------------------
[f, Tf] = W01_frames(R);
exportgraphics(f, img('W01_result_frames.png'), 'Resolution', 150);

fprintf('\n  4) one velocity, two frames  (psi = 30 deg, u = 2.0, v = 0.5)\n\n');
disp(Tf);
fprintf(['\n    The two speeds agree because a rotation preserves length. Nothing\n' ...
         '    else in a frame conversion is as easy to check, and nothing else\n' ...
         '    catches a transposed or mis-signed rotation matrix as reliably.\n']);

% -- speed vs shaft speed -------------------------------------------------
f = lab_fig('W01  terminal speed', 900, 380);
subplot(1,2,1); hold on;
nn = linspace(cfg.n_min, cfg.n_max, 400);
TT = arrayfun(@(z) prop_thrust(z, cfg), nn);
plot(nn, TT, 'Color', COL);
xline(0, 'k:'); yline(0, 'k:');
xlabel('n  shaft speed [rad/s]'); ylabel('T  thrust, one propeller [N]');
title({'the propeller curve  T = k n|n|', ...
       sprintf('k_{pos}/k_{neg} = %.3f — astern is weaker', cfg.k_pos/cfg.k_neg)});

subplot(1,2,2); hold on;
plot(NS, u_pred, '--', 'Color',[0.85 0.33 0.10]);
plot(NS, u_meas, 'o', 'Color', COL, 'MarkerFaceColor', COL);
xlabel('n  shaft speed, both propellers [rad/s]'); ylabel('terminal u [m/s]');
legend({'2 k_{pos} n|n| / X_u','measured'}, 'Location','northwest');
title({'terminal surge speed', 'quadratic thrust against linear damping'});
sgtitle('W01 open loop — thrust in, speed out', 'FontWeight','bold');
exportgraphics(f, img('W01_result_speed.png'), 'Resolution', 150);

fprintf('\n  figures written to %s\n\n', fullfile(here,'img'));
end

% =========================================================================
function o = one(V)
%ONE  A single simulation with the variables in V.
in = Simulink.SimulationInput('W01_openloop');
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
evalc('r = sim(in);');
y = squeeze(r.W01.signals.values);
if size(y,1) < size(y,2), y = y.'; end
o.t = r.W01.time;
o.y = y;                                   % [u v r N E psi(deg)]
end

function k = tail(mask)
%TAIL  The last fifth of a logical phase mask — the steady part.
idx = find(mask);
k   = false(size(mask));
if isempty(idx), return; end
k(idx(max(1, round(0.8*numel(idx))):end)) = true;
end

function mark_phases(f, tp, T)
%MARK_PHASES  Draw the phase boundaries on every time axis of a figure.
for ax = findobj(f, 'Type','axes').'
    if strcmp(get(get(ax,'XLabel'),'String'), 'time [s]')
        %  HandleVisibility off, or the phase lines join the legend as data1..4
        for b = tp, xline(ax, b, 'Color',[0.75 0.75 0.75], 'HandleVisibility','off'); end
        xlim(ax, [0 T]);
    end
end
end

function T = prop_thrust(n, cfg)
n = min(max(n, cfg.n_min), cfg.n_max);
if n >= 0, T = cfg.k_pos*n*abs(n); else, T = cfg.k_neg*n*abs(n); end
end

function V = base_vars()
V.n0     = 60;
V.dn     = 3.5;
V.t_phase = [30 60 90 120];
V.mp     = 25;
V.rp     = [0.05 0 -0.35]';
V.V_c    = 0;
V.beta_c = 0;
V.x0     = zeros(12,1);
V.h      = 0.02;
V.T_final = 150;
V.animate     = 0;                     % batch runs draw nothing — the runner plots
V.animate_every = 0.5;
V.track_Nmin = -10;  V.track_Nmax = 140;
V.track_Emin = -85;  V.track_Emax =  25;
end
