%% W02_0_setup.m — the only file to edit this week
%
%  Every Constant, Gain and Step block in W02_surge_control.slx reads a variable
%  defined here.
%
%     >> W02_0_setup
%
%  To restore a model that has been broken:
%
%     >> W02_1_build_surge_control

clear; close all; bdclose('all');

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));            % ...\GradCourse
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

%% ---- the plant, as three numbers ----------------------------------------
%  Week 1 reduced the surge axis to  M11 u_dot = X + Xu u.  Everything the
%  controller design needs is in the two derived constants.
M11  = 85.50;                       % surge mass including added mass [kg]
Xu   = 24.4*9.81/(6*0.5144);        % linear surge damping [N per m/s]
K_u  = 1/Xu;                        % DC gain  [(m/s) per N]
T_u = M11/Xu;                     % time constant [s]

%% ---- the reference ------------------------------------------------------
%  Two steps are summed, so one model covers a single step and the up-then-down
%  profile that the windup experiment needs.
%
%     u_d = u_d1  for  t_up  <= t < t_dn
%     u_d = u_d2  for  t_dn  <= t
%
%  Setting u_d2 = u_d1 turns the second step off.
u_d1 = 1.5;                  % first commanded speed [m/s]
u_d2 = 1.5;                  % second commanded speed [m/s]
t_up = 5;                    % time of the first step [s]
t_dn = 1e6;                  % time of the second step [s]

%% ---- the controller -----------------------------------------------------
%  Designed in §3-4 for a closed-loop damping ratio and natural frequency:
%
%     K_i = wn^2 T_u / K_u,     K_p = (2 zeta sqrt(T_u K_u K_i) - 1)/K_u
%
%  With zeta = 0.7 and wn = 1.5 rad/s this gives the pair below.
Kp = 102.00;                 % proportional gain [N per m/s]
Ki = 192.38;                 % integral gain     [N per m]
Kd = 0;                      % derivative gain   [N per m/s^2]
Nf = 20;                     % derivative filter bandwidth [rad/s]

%% ---- anti-windup --------------------------------------------------------
%  aw_mode  0  none            the integrator never stops
%           1  clamping        integration is frozen while the actuator is
%                              saturated and the error drives it further in
%           2  back-calculation the excess (X_sat - X_cmd) is fed back into
%                              the integrator through K_aw
aw_mode = 2;
K_aw    = 1/T_u;           % back-calculation gain [1/s]

%% ---- open loop ----------------------------------------------------------
%  loop_closed = 0 disconnects the controller and applies X_open directly,
%  which is how the plant constants are identified in Part 2, section C.
pid_mode    = 0;             % 0 = the hand-built PID, 1 = Simulink's PID Controller block
loop_closed = 1;
X_open      = 100;           % surge force applied in open loop [N]

%% ---- actuator -----------------------------------------------------------
k_pos = cfg.k_pos;   k_neg = cfg.k_neg;
n_max = cfg.n_max;   n_min = cfg.n_min;

%  The surge force the propellers can actually produce. These are the limits
%  the allocation imposes, and the same numbers are given to the PID block so
%  that its internal saturation and the real one coincide.
X_hi  =  2*k_pos*n_max^2;    %  239.36 N
X_lo  = -2*k_neg*n_min^2;    % -133.42 N

%% ---- vessel and environment --------------------------------------------
mp     = 25;
rp     = [0.05 0 -0.35]';
V_c    = 0;
beta_c = 0;
x0     = zeros(12,1);

%% ---- simulation ---------------------------------------------------------
h       = 0.02;
T_final = 30;

%% ---- live view -----------------------------------------------------------
animate       = 1;
animate_every = 0.5;
track_Nmin = -5;    track_Nmax = 65;
track_Emin = -35;   track_Emax = 35;

%% ---- report -------------------------------------------------------------
X_lim = [2*k_neg*n_min*abs(n_min), 2*k_pos*n_max*abs(n_max)];
fprintf('\n  W02 setup complete\n');
fprintf('    plant           T_u = %.4f s,  K_u = %.6f (m/s)/N\n', T_u, K_u);
fprintf('    actuator        X in [%.2f, %.2f] N  ->  u_ss in [%.4f, %.4f] m/s\n', ...
        X_lim(1), X_lim(2), X_lim(1)*K_u, X_lim(2)*K_u);
fprintf('    controller      Kp = %g, Ki = %g, Kd = %g, Nf = %g\n', Kp, Ki, Kd, Nf);
if Ki > 0
    wn = sqrt(K_u*Ki/T_u);
    ze = (1 + K_u*Kp)/(2*sqrt(T_u*K_u*Ki));
    fprintf('    closed loop     wn = %.4f rad/s,  zeta = %.4f\n', wn, ze);
else
    fprintf('    closed loop     P only, steady-state error = %.2f %%\n', 100/(1+K_u*Kp));
end
AW = {'none','clamping','back-calculation'};
fprintf('    anti-windup     %s\n', AW{aw_mode+1});
fprintf('    reference       %g -> %g m/s at t = %g s\n', u_d1, u_d2, t_up);
fprintf('    simulation      %g s at h = %g s\n\n', T_final, h);
