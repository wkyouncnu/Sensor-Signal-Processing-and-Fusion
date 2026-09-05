%% W04_0_setup.m — the only file to edit this week
%
%     >> W04_0_setup
%
%  Then work through the laboratory one section at a time:
%
%     >> W04_C_aim_at_the_waypoint     C — why atan2 is not path following
%     >> W04_D_line_of_sight           D — the LOS law, and what it fixes
%     >> W04_E_lookahead_distance      E — what Delta trades against what
%     >> W04_F_waypoint_switching      F — the two switching criteria
%     >> W04_G_current_and_integral    G — the current, ILOS and ALOS
%     >> W04_H_adaptive_and_stability  H — the gains, and the Lyapunov function
%
%  To restore a model that has been broken:
%
%     >> W04_1_build_guidance

clear; close all; bdclose('all');

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));            % ...\GradCourse
addpath(fullfile(root,'_tools'), here);
mss_path();

V = W04_vars;

%% ---- the mission --------------------------------------------------------
%  Five waypoints, four legs. Three sides of a square and then a diagonal, so
%  the pattern has two 90 deg corners AND one of 135 deg: a gentle turn and a
%  hard one. Section F needs both.
WP   = V.WP;
WP_N = V.WP_N;
WP_E = V.WP_E;

%% ---- the guidance tuning ------------------------------------------------
Delta    = V.Delta;        % look-ahead distance [m]. 8 m is 4 x hull length
R_switch = V.R_switch;     % switching parameter [m]. MUST be < shortest leg
sw_mode  = V.sw_mode;      % 1 = along-track (MSS), 2 = circle of acceptance
kappa    = V.kappa;        % ILOS integral gain constant, Ki = kappa/Delta
gamma    = V.gamma;        % ALOS adaptation gain

%  0 plots all four laws, 1..4 plots one of them
%  (1 atan2, 2 LOS, 3 ILOS, 4 ALOS)
guid_show = V.guid_show;

%% ---- the heading autopilot, from Week 3 ---------------------------------
%  Not retuned. All four rows carry an identical copy, so no difference in
%  the results can come from the inner loop.
Kp   = V.Kp;
Kd   = V.Kd;
X_ff = V.X_ff;             % constant surge force [N]

%% ---- actuator and plant -------------------------------------------------
k_pos = V.k_pos;  k_neg = V.k_neg;
n_max = V.n_max;  n_min = V.n_min;  y_pont = V.y_pont;
mp = V.mp;  rp = V.rp;  x0 = V.x0;

%% ---- the current --------------------------------------------------------
%  Off here. Sections G and H switch it on; that is where ILOS and ALOS earn
%  their keep and plain LOS cannot.
V_c    = V.V_c;
beta_c = V.beta_c;

%% ---- simulation ---------------------------------------------------------
h       = V.h;
T_final = V.T_final;

%% ---- live view -----------------------------------------------------------
animate       = 1;
animate_every = V.animate_every;
track_Nmin = V.track_Nmin;   track_Nmax = V.track_Nmax;
track_Emin = V.track_Emin;   track_Emax = V.track_Emax;

%% ---- report -------------------------------------------------------------
legs = hypot(diff(WP(:,1)), diff(WP(:,2)));
fprintf('\n  W04 setup complete\n');
fprintf('    mission         %d waypoints, %d legs, shortest %.1f m\n', ...
        size(WP,1), numel(legs), min(legs));
fprintf('    guidance        Delta = %g m, R_switch = %g m, mode = %d (%s)\n', ...
        Delta, R_switch, sw_mode, ternary(sw_mode==1,'along-track','circle'));
fprintf('    feasibility     R_switch < shortest leg?  %s\n', ...
        ternary(R_switch < min(legs), 'yes', 'NO — a waypoint would be skipped'));
fprintf('    Delta / L       %.1f x hull length (rule of thumb: 2 to 5)\n', Delta/2.0);
fprintf('    ILOS            kappa = %g   ->  Ki = %.4f\n', kappa, kappa/Delta);
fprintf('    ALOS            gamma = %g\n', gamma);
fprintf('    autopilot       Kp = %g, Kd = %g,  X_ff = %g N\n', Kp, Kd, X_ff);
fprintf('    current         %.2f m/s at %.0f deg\n', V_c, rad2deg(beta_c));
fprintf('    simulation      %g s at h = %g s\n\n', T_final, h);

function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
