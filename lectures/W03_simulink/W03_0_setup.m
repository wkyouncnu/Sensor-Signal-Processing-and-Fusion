%% W03_0_setup.m — the only file to edit this week
%
%     >> W03_0_setup
%
%  To restore a model that has been broken:
%
%     >> W03_1_build_heading

clear; close all; bdclose('all');

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));            % ...\GradCourse
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

%% ---- the plant, as two numbers ------------------------------------------
%  The yaw axis of Week 1, keeping only the linear part:
%
%     M66 psi_ddot = tau_N + Nr psi_dot
%
M66 = 42.65;                 % yaw inertia including added mass [kg m^2]
Nr  = -42.65;                % linear yaw damping [N m per rad/s]

%% ---- the reference ------------------------------------------------------
%  Two steps in DEGREES, summed. Setting psi_2 = psi_1 turns the second off.
psi_1 = 60;                  % first commanded heading [deg]
psi_2 = 60;                  % second commanded heading [deg]
t_up  = 5;                   % time of the first step [s]
t_dn  = 1e6;                 % time of the second step [s]

%  A constant forward force, so the vessel travels while it turns and the
%  track is something to look at. It plays no part in the heading loop.
X_ff = 60;                   % surge force [N]

%% ---- the controller -----------------------------------------------------
%  P-D on the heading, with the D term acting on the YAW RATE and not on the
%  derivative of the error:
%
%     tau_N = Kp ssa(psi_d - psi) - Kd r
%
%  Designed in §3-3 from
%
%     wn = sqrt(Kp/M66),   zeta = (|Nr| + Kd) / (2 sqrt(Kp M66))
%
%  With wn = 1.53 rad/s and zeta = 0.9 this gives the pair below.
Kp = 100.00;                 % [N m per rad]
Kd = 74.90;                  % [N m per rad/s]

%  use_ssa = 0 removes the smallest-signed-angle wrap, so the vessel steers
%  the long way round a +-180 deg boundary. Section E is that experiment.
use_ssa = 1;

%% ---- actuator -----------------------------------------------------------
k_pos = cfg.k_pos;   k_neg = cfg.k_neg;
n_max = cfg.n_max;   n_min = cfg.n_min;
y_pont = cfg.y_pont;         % 0.395 m, the moment arm of each propeller

%% ---- vessel and environment --------------------------------------------
mp     = 25;
rp     = [0.05 0 -0.35]';
V_c    = 0;
beta_c = 0;
x0     = zeros(12,1);

%% ---- simulation ---------------------------------------------------------
h       = 0.02;
T_final = 40;

%% ---- live view -----------------------------------------------------------
animate       = 1;
animate_every = 0.5;
track_Nmin = -10;   track_Nmax = 40;
track_Emin = -25;   track_Emax = 25;

%% ---- report -------------------------------------------------------------
wn = sqrt(Kp/M66);
ze = (abs(Nr) + Kd)/(2*sqrt(Kp*M66));
fprintf('\n  W03 setup complete\n');
fprintf('    plant           M66 = %.2f kg m^2,  Nr = %.2f\n', M66, Nr);
fprintf('    controller      Kp = %g, Kd = %g, ssa = %d\n', Kp, Kd, use_ssa);
fprintf('    closed loop     wn = %.4f rad/s,  zeta = %.4f\n', wn, ze);
fprintf('    hull alone      zeta = %.4f  (Kd = 0)\n', abs(Nr)/(2*sqrt(Kp*M66)));
fprintf('    reference       %g -> %g deg at t = %g s\n', psi_1, psi_2, t_up);
fprintf('    forward force   %g N\n', X_ff);
fprintf('    simulation      %g s at h = %g s\n\n', T_final, h);
