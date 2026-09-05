%% W01 · section E — the same command in four currents
%
%      W01_0_setup
%      W01_E_current_run
%
%  One command, held for the whole run: both propellers at n0, no steering.
%  Only the water changes. Whatever the track does, the vessel was never told
%  to do it.
%  Produces img/W01_result_current.png and img/W01_result_current_rose.png

clear V CASES R M i o y k f BET sw Ri sp ax COL dpsi
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
fprintf('  current: V_c = %g m/s\n\n', V.V_c);
fprintf('    %-18s %9s %9s %9s %9s %10s %10s\n', ...
        'current', 'u [m/s]', 'u_r', 'v [m/s]', 'v_r', 'psi [deg]', 'track [deg]');
fprintf('    %s\n', repmat('-', 1, 84));

R = cell(size(CASES,1),1);
M = zeros(size(CASES,1), 6);
for i = 1:size(CASES,1)
    o = run_sim('W01_current', V, 'V_c', CASES{i,2}, 'beta_c', deg2rad(CASES{i,3}));
    y = W01_read(o);
    R{i}        = o;
    R{i}.V_c    = CASES{i,2};      % carried so the track plot can draw the
    R{i}.beta_c = CASES{i,3};      % current as arrows rather than words
    k = y.t >= 0.8*V.T_final;                        % settled fifth of the run
    M(i,:) = [mean(y.u(k)) mean(y.u_r(k)) mean(y.v(k)) mean(y.v_r(k)) ...
              mean(y.psi(k)) trackangle(y)];
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

%% ---- sweeping the current direction ------------------------------------
BET = 0:30:330;
sw  = zeros(numel(BET), 3);
fprintf('\n  sweeping the current direction at V_c = %g m/s\n\n', V.V_c);
fprintf('    %10s %12s %12s %12s\n', 'beta_c [deg]', 'ground speed', 'drift [deg]', 'psi [deg]');
fprintf('    %s\n', repmat('-', 1, 52));
for i = 1:numel(BET)
    Ri = W01_read(run_sim('W01_current', V, 'V_c', V.V_c, 'beta_c', deg2rad(BET(i))));
    k  = Ri.t >= 0.8*V.T_final;
    sp = hypot(mean(diff(Ri.N(k))), mean(diff(Ri.E(k)))) / V.h;
    sw(i,:) = [sp, trackangle(Ri) - mean(Ri.psi(k)), mean(Ri.psi(k))];
    fprintf('    %10g %12.4f %12.3f %12.3f\n', BET(i), sw(i,:));
end
fprintf(['\n    Ground speed is largest with the current astern and smallest with\n' ...
         '    it ahead, and the drift angle is largest on the beam. The vessel\n' ...
         '    is doing the same thing in every one of these runs.\n']);

%% ---- figure 1: the four tracks, and what the hull felt -----------------
f = W01_cur_plot(R, CASES(:,1)', V, ...
    'W01 E — one command, four currents: the track the vessel was never given');
exportgraphics(f, fullfile(here,'img','W01_result_current.png'), 'Resolution', 150);

%% ---- figure 2: the sweep, as a compass ---------------------------------
COL = [0 0.45 0.74; 0.85 0.33 0.10];
f = lab_fig('W01 E  current direction', 1000, 430);

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
plot(BET, sw(:,2), 'o-', 'Color', COL(2,:), 'MarkerFaceColor', COL(2,:));
yline(0,'k:'); grid on;
xlabel('\beta_c  current direction [deg from north]');
ylabel('drift = track - heading [deg]');
xlim([0 330]);
title({'drift angle against current direction', 'zero when the current is fore-and-aft'});

sgtitle('W01 E — the same command in twelve different currents', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W01_result_current_rose.png'), 'Resolution', 150);

fprintf('\n  figures -> img/W01_result_current.png, img/W01_result_current_rose.png\n\n');


% =========================================================================
function a = trackangle(y)
%TRACKANGLE  Direction of the straight line from start to finish [deg from north].
a = atan2d(y.E(end) - y.E(1), y.N(end) - y.N(1));
end
