%% W01_0_setup.m — the only file to edit this week
%
%  Every Constant block in W01_openloop.slx reads a variable defined here.
%  Change a value, run this script, and the model runs with it.
%
%     >> W01_0_setup
%
%  Then work through the laboratory one section at a time:
%
%     >> W01_C_terminal_speed    section C — predict on paper, then measure
%     >> W01_D_the_manoeuvre     section D — straight, port, straight, starboard
%     >> W01_E_current_run       section E — the same command in four currents
%
%  To restore a model that has been broken:
%
%     >> W01_1_build_openloop        W01_openloop.slx
%     >> W01_E_build_current         W01_current.slx

clear; close all; bdclose('all');

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));            % ...\GradCourse
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

%% ---- the manoeuvre ------------------------------------------------------
%  straight  ->  turn to port  ->  straight  ->  turn to starboard  ->  straight
%
%  Both propellers run ahead the whole time. A turn is a small DIFFERENCE
%  between them:
%
%     straight       n = [n0    ; n0   ]
%     to port        n = [n0-dn ; n0+dn]
%     to starboard   n = [n0+dn ; n0-dn]
%
%  because the yaw moment is N = y_p (T_left - T_right). More thrust on the
%  left turns the bow to starboard, so a PORT turn slows the LEFT propeller.

n0 = 60;          % common shaft speed [rad/s] — sets the speed, about 1.03 m/s
dn = 3.5;         % differential [rad/s] — sets the turn rate, about 3.2 deg/s

%  phase boundaries [s]:  port turn runs t_phase(1)..t_phase(2)
%                         starboard turn runs t_phase(3)..t_phase(4)
t_phase = [30 60 90 120];

%  dn = 0 collapses the manoeuvre to a constant command. W01_C_terminal_speed uses that for
%  the terminal-speed sweep, where a turn would only get in the way.

%% ---- vessel and environment --------------------------------------------
mp     = 25;                  % payload mass [kg], otter.m accepts up to 45
rp     = [0.05 0 -0.35]';     % payload position in {b} [m]
V_c    = 0;                   % current speed [m/s]
beta_c = 0;                   % current direction [rad]

%% ---- initial state ------------------------------------------------------
%  x = [u v w p q r  x y z  phi theta psi]'
x0        = zeros(12,1);
x0(12)    = 0;                % initial heading [rad]

%% ---- simulation ---------------------------------------------------------
h       = 0.02;               % fixed step [s]
T_final = 150;                % the whole manoeuvre, with a straight leg after it

%% ---- live view -----------------------------------------------------------
%  The model draws the hull, its heading and its track while the simulation
%  runs. Watching the heading line matters here: in each turn the vessel
%  points one way and moves another, and no track on its own shows that.
animate       = 1;            % 1 draws the live view, 0 switches it off
animate_every = 0.5;          % redraw interval in simulated seconds

%  The axes are fixed before the run starts, so they do not auto-range.
%  Widen these if the vessel leaves the box. The S-shape runs about 130 m
%  north and swings about 65 m to the west before straightening up again.
track_Nmin = -10;   track_Nmax = 140;
track_Emin = -85;   track_Emax =  25;

%% ---- report -------------------------------------------------------------
cfg = otter_config('base');
fprintf('\n  W01 setup complete\n');
fprintf('    configuration   %s, %d thrusters, rank(B) = %d\n', ...
        cfg.name, cfg.n_thr, rank(cfg.B));
fprintf('    manoeuvre       n0 = %g, dn = %g rad/s\n', n0, dn);
fprintf('                    port %g..%g s, starboard %g..%g s\n', t_phase);
fprintf('    n limits        %.1f .. %.1f rad/s\n', cfg.n_min, cfg.n_max);
fprintf('    current         %.2f m/s at %.0f deg\n', V_c, rad2deg(beta_c));
fprintf('    simulation      %g s at h = %g s\n\n', T_final, h);
