function V = W02_vars()
%W02_VARS  Every variable W02_surge_control.slx needs, in one struct.
%
%   V = W02_vars
%
%   WHY THIS IS SEPARATE FROM W02_0_setup
%
%   W02_0_setup puts the variables in the BASE workspace, which is what a
%   student needs when they open the model and press Run. The section scripts
%   need the same values as a STRUCT, so that run_sim can vary one of them for
%   one run without leaving the workspace in the state of the last run.
%
%   Both read the same numbers from here, so there is exactly one place where
%   a gain is written down.

mss_path();
cfg = otter_config('base');

%  ---- the plant, from otter.m --------------------------------------------
V.M11   = 85.50;                      % surge mass incl. added mass [kg]
V.Xu    = 24.4*9.81/(6*0.5144);       % |X_u|, linear surge damping [N per m/s]
V.K_u   = 1/V.Xu;                     % DC gain [(m/s)/N]
V.tau_u = V.M11/V.Xu;                 % time constant [s]
V.X_hi  =  2*cfg.k_pos*cfg.n_max^2;   % most the propellers can push [N]
V.X_lo  = -2*cfg.k_neg*cfg.n_min^2;   % most they can pull back [N]

%  ---- the PI design of 2-3 -----------------------------------------------
zeta_d = 0.7;  wn_d = 1.5;
V.zeta_d = zeta_d;  V.wn_d = wn_d;
V.Ki_d = wn_d^2 * V.tau_u / V.K_u;
V.Kp_d = (2*zeta_d*sqrt(V.tau_u*V.K_u*V.Ki_d) - 1)/V.K_u;

%  ---- controller, as the model reads it ----------------------------------
V.Kp = V.Kp_d;  V.Ki = V.Ki_d;  V.Kd = 0;  V.Nf = 20;
V.aw_mode = 2;  V.K_aw = 5;

%  ---- command -------------------------------------------------------------
V.u_d1 = 1.5;   V.u_d2 = 1.5;   V.t_up = 5;   V.t_dn = 1e6;

%  ---- open-loop switch ----------------------------------------------------
V.loop_closed = 1;  V.X_open = 100;  V.pid_mode = 0;

%  ---- plant and environment -----------------------------------------------
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.V_c = 0;  V.beta_c = 0;
V.x0 = zeros(12,1);
V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.n_max = cfg.n_max;  V.n_min = cfg.n_min;

%  ---- simulation ----------------------------------------------------------
V.h = 0.02;  V.T_final = 30;

%  ---- live view (off for the section scripts; they plot at the end) -------
V.animate = 0;  V.animate_every = 0.5;
V.track_Nmin = -5;   V.track_Nmax = 65;
V.track_Emin = -35;  V.track_Emax = 35;
end
