function V = W03_vars()
%W03_VARS  Every variable W03_heading_control.slx needs, in one struct.
%
%   Same split as Week 2: W03_0_setup fills the BASE workspace so a student can
%   open the model and press Run; this returns the same numbers as a struct so
%   run_sim can vary one of them without leaving the workspace in the state of
%   the last run.
%
%   The two plant numbers are checked against otter.m by verify_constants.

mss_path();
c = otter_config('base');

%  ---- the yaw axis, from otter.m -----------------------------------------
V.M66 = 42.65;          % (6,6) of M, incl. added mass   [kg m^2]
V.Nr  = -42.65;         % linear yaw damping, = -M66/T_yaw with T_yaw = 1 s

%  ---- command -------------------------------------------------------------
V.psi_1 = 60;   V.psi_2 = 60;   V.t_up = 5;   V.t_dn = 1e6;
V.X_ff  = 60;                   % constant surge command, so the vessel moves

%  ---- controller ----------------------------------------------------------
%  tau_N = Kp ssa(psi_d - psi) - Kd r    (P-D on the RATE, MSS convention)
V.Kp = 100.00;  V.Kd = 74.90;   V.use_ssa = 1;

%  ---- actuator and plant --------------------------------------------------
V.k_pos = c.k_pos;  V.k_neg = c.k_neg;
V.n_max = c.n_max;  V.n_min = c.n_min;  V.y_pont = c.y_pont;
V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.V_c = 0;  V.beta_c = 0;  V.x0 = zeros(12,1);

%  ---- simulation ----------------------------------------------------------
V.h = 0.02;  V.T_final = 40;

%  ---- live view (off; the section scripts plot at the end) ----------------
V.animate = 0;  V.animate_every = 0.5;
V.track_Nmin = -10;  V.track_Nmax = 40;
V.track_Emin = -25;  V.track_Emax = 25;
end
