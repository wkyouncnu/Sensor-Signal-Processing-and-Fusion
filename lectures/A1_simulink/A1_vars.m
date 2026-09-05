function V = A1_vars()
%A1_VARS  Every variable A1_actuation.slx needs, in one struct.
%
%   Same split as Weeks 2 and 3: A1_0_setup fills the base workspace for a
%   student pressing Run; this returns the same numbers as a struct so that
%   run_sim can vary one per run.

mss_path();
c = otter_config('base');

V.n_cmd   = [60; -60];
V.k_pos   = c.k_pos;  V.k_neg = c.k_neg;
V.n_max   = c.n_max;  V.n_min = c.n_min;
V.B_alloc = c.B;                     % the matrix under test

V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.V_c = 0;  V.beta_c = 0;  V.x0 = zeros(12,1);

V.h = 0.02;  V.T_final = 60;

V.animate = 0;  V.animate_every = 0.5;
V.track_Nmin = -15;  V.track_Nmax = 15;
V.track_Emin = -15;  V.track_Emax = 15;
end
