%% W01 · section D — one manoeuvre: straight, port, straight, starboard, straight
%
%      W01_0_setup
%      W01_D_the_manoeuvre
%
%  Nothing reverses. A turn is a small DIFFERENCE between two propellers that
%  both run ahead, because N = y_p (T_left - T_right).
%  Produces img/W01_result_track.png

clear V cfg y_p o y tp PH seg i k u v r nL nR dpsi N_cmd Ymax nn kP kS f Ls b ax
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_openloop.slx')), W01_1_build_openloop; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V   = W01_vars;
cfg = otter_config('base');
y_p = cfg.y_pont;                    % 0.395 m, half the propeller separation

o  = run_sim('W01_openloop', V);
y  = W01_read(o);
tp = V.t_phase;

PH  = {'straight   1', 'PORT turn', 'straight   2', 'STARBOARD turn', 'straight   3'};
seg = { y.t <  tp(1), ...
        y.t >= tp(1) & y.t < tp(2), ...
        y.t >= tp(2) & y.t < tp(3), ...
        y.t >= tp(3) & y.t < tp(4), ...
        y.t >= tp(4) };

%% ---- the five phases ---------------------------------------------------
%  Steady values are read from the LAST FIFTH of each phase, after the
%  transient at the phase boundary has died away. Averaging over the whole
%  phase would mix the transient into the steady number.
fprintf('\n  W01 section D — the manoeuvre, %g s, n0 = %g, dn = %g rad/s\n\n', ...
        V.T_final, V.n0, V.dn);
fprintf('    %-16s %9s %9s %10s %10s %10s %10s\n', ...
        'phase', 'n_L', 'n_R', 'u [m/s]', 'v [m/s]', 'r [deg/s]', 'beta [deg]');
fprintf('    %s\n', repmat('-', 1, 82));

for i = 1:numel(PH)
    k = last_fifth(seg{i});
    switch i
        case 2,    nL = V.n0 - V.dn;  nR = V.n0 + V.dn;
        case 4,    nL = V.n0 + V.dn;  nR = V.n0 - V.dn;
        otherwise, nL = V.n0;         nR = V.n0;
    end
    fprintf('    %-16s %9.1f %9.1f %10.4f %10.4f %10.4f %10.4f\n', PH{i}, nL, nR, ...
            mean(y.u(k)), mean(y.v(k)), mean(y.r(k)), mean(y.beta(k)));
end

dpsi = @(i) y.psi(find(seg{i}, 1, 'last')) - y.psi(find(seg{i}, 1, 'first'));
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

%% ---- the empty sway row ------------------------------------------------
Ymax = 0;
for i = [1 2 4]
    switch i
        case 2,    nn = [V.n0 - V.dn; V.n0 + V.dn];
        case 4,    nn = [V.n0 + V.dn; V.n0 - V.dn];
        otherwise, nn = [V.n0; V.n0];
    end
    Ymax = max(Ymax, abs(cfg.B(2,:) * prop_thrust(nn, cfg)));
end
kP = last_fifth(seg{2});
kS = last_fifth(seg{4});

fprintf('\n  the sway row, over the whole manoeuvre\n\n');
fprintf('    max |Y| over every command in the manoeuvre   %.1e N\n', Ymax);
fprintf('    mean v in the port turn                        %+.4f m/s\n', mean(y.v(kP)));
fprintf('    mean v in the starboard turn                   %+.4f m/s\n', mean(y.v(kS)));
fprintf(['\n    Y is identically zero. Both propellers are bolted to the hull\n' ...
         '    facing forward, so no combination of them has a component across\n' ...
         '    the centreline. That is a property of the geometry, not a small\n' ...
         '    number that could be tuned away.\n' ...
         '\n    The vessel nevertheless sways in both turns, and v CHANGES SIGN\n' ...
         '    between them. That sway velocity is produced by the hull ROTATING\n' ...
         '    while it moves, through the Coriolis term in otter.m, and not by\n' ...
         '    any side force. It is the crab angle, and Week 3 has to steer\n' ...
         '    around it.\n']);

%  WITHDRAWN 2026-09-08, at the lecturer's request: the five-panel state
%  figure that used to be saved here as img/W01_result_states.png.
%
%  It drew u, v, r, psi and the track — and the live dashboard inside
%  W01_openloop.slx now draws exactly those six signals WHILE the run is in
%  progress. Saving them a second time afterwards is the same picture twice.
%  See gnc-lecture-vault/references/standing-orders.md §9-8.
%
%  `W01_plot.m` is untouched and still in use: it is the model's StopFcn.

%% ---- the figure: where it went, and where it pointed -------------------
%  Two panels. The track answers "where did it go", the angle panel answers
%  "where was it pointing while it went there" — which is the whole reason
%  the hull is drawn on the track rather than a bare line.
f = lab_fig('W01 D  track', 1150, 470);

subplot(1,2,1); hold on; axis equal;
plot(y.E, y.N, 'Color',[0 0.45 0.74]);
Ls = track_ships({[y.N y.E y.psi]}, [0 0.45 0.74], 'Marks', 14, 'Heading', 0.7);
plot(0, 0, 'ks', 'MarkerFaceColor','w');
for i = [2 4]
    plot(y.E(seg{i}), y.N(seg{i}), 'Color',[0.85 0.33 0.10], 'LineWidth',1.6);
end
xlabel('East [m]'); ylabel('North [m]');
title({'the horizontal track — turns in orange', ...
       sprintf('hull drawn at %.0f x true size', Ls/2.00)});

subplot(1,2,2); hold on;
plot(y.t, y.psi,  'Color',[0 0.45 0.74],     'DisplayName','heading \psi');
plot(y.t, y.chi,  'Color',[0.85 0.33 0.10],  'DisplayName','course \chi = \psi + \beta');
plot(y.t, y.beta, 'Color',[0.47 0.67 0.19],  'DisplayName','crab angle \beta');
yline(0, 'k:', 'HandleVisibility','off');
for b = tp, xline(b, 'Color',[0.7 0.7 0.7], 'HandleVisibility','off'); end
legend('Location','best');
xlabel('time [s]'); ylabel('angle [deg]');
title({'where it points, and where it goes', ...
       sprintf('|\\beta| reaches %.2f deg, and changes sign between the turns', ...
               max(abs(y.beta)))});

sgtitle('W01 D — where the vessel went, and where it pointed', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W01_result_track.png'), 'Resolution', 150);

fprintf('\n  figure -> img/W01_result_track.png\n\n');


% =========================================================================
function k = last_fifth(mask)
%LAST_FIFTH  The settled part of a phase: its final fifth.
idx = find(mask);
k   = false(size(mask));
if isempty(idx), return; end
k(idx(max(1, round(0.8*numel(idx))):end)) = true;
end
