function V = W04_vars()
%W04_VARS  Every variable W04_guidance.slx needs, in one struct.
%
%   Same split as Weeks 1 to 3: W04_0_setup fills the BASE workspace so a
%   student can open the model and press Run; this returns the same numbers as
%   a struct so that run_sim can vary one of them without leaving the
%   workspace in the state of the last run.

mss_path();
c = otter_config('base');

%  ---- the mission -------------------------------------------------------
%  Five waypoints, four legs of 60 m. Three sides of a square and then a
%  diagonal, so the pattern contains a 90 deg corner AND a 135 deg one: a
%  gentle turn and a hard one, which is what section F needs.
V.WP = [   0    0
          60    0
          60   60
           0   60
          60  120 ];

%  The model reads the two columns separately, because a Constant block holds
%  a vector and not a matrix. WP stays for the plotting functions.
V.WP_N = V.WP(:,1);
V.WP_E = V.WP(:,2);

V.Delta    = 8;        % look-ahead distance [m] — 4 x hull length
V.R_switch = 5;        % switching parameter [m] — must be < shortest leg
V.sw_mode  = 1;        % 1 = along-track (MSS), 2 = circle of acceptance

%  ---- the four guidance laws --------------------------------------------
%  Row 1 atan2, row 2 LOS, row 3 ILOS, row 4 ALOS. They differ in one thing
%  each and share everything else, which is what makes the comparison honest.
V.kappa = 0.3;         % ILOS integral gain constant, Ki = kappa/Delta
V.gamma = 0.005;       % ALOS adaptation gain [rad per metre-second]
V.guid_show = 0;       % 0 = all four on the plots, 1..4 = one of them

%  BOTH GAINS ARE SMALL, AND THE UNITS SAY WHY. The ALOS update is
%
%      d/dt b_hat = gamma * Delta * y_e / sqrt(Delta^2 + y_e^2)
%
%  whose right-hand side approaches gamma*Delta as y_e grows. With Delta = 8 m
%  a gamma of 0.02 gives 0.16 rad/s, which drives the estimate through a
%  radian in six seconds and makes it chase the corner transients instead of
%  the current. Section H sweeps both gains and these two values are what it
%  chose: gamma = 0.005 settles the ALOS vessel at 0.006 m and kappa = 0.3
%  settles the ILOS one at 0.010 m, both in a 0.3 m/s beam current.

%  ---- the heading autopilot, one set of gains for all four rows ---------
%  The same P-D law as Week 3, at the same gains. Nothing here is retuned
%  between rows: every difference in the results belongs to the guidance.
V.Kp = 100.00;         % [N m per rad]
V.Kd = 74.90;          % [N m per rad/s]
V.X_ff = 60;           % constant surge force [N] -> about 0.77 m/s

%  ---- actuator and plant -------------------------------------------------
V.k_pos = c.k_pos;  V.k_neg = c.k_neg;
V.n_max = c.n_max;  V.n_min = c.n_min;  V.y_pont = c.y_pont;
V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.x0 = zeros(12,1);

%  ---- the current --------------------------------------------------------
%  Off by default. Sections G and H switch it on; that is where ILOS and ALOS
%  earn their keep and plain LOS cannot.
V.V_c = 0;  V.beta_c = 0;

%  ---- simulation ---------------------------------------------------------
%  500 s is chosen so the last quarter of the run is well clear of the final
%  135 deg corner at about 222 s: a settled number measured across a corner
%  is not a settled number.
V.h = 0.02;  V.T_final = 500;

%  ---- live view (off; the section scripts plot at the end) ---------------
V.animate = 0;  V.animate_every = 1.0;
V.track_Nmin = -20;  V.track_Nmax = 200;
V.track_Emin = -30;  V.track_Emax = 220;
end
