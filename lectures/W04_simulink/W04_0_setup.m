%% W04_0_setup — 이번 주에 학생이 고치는 유일한 파일
%  W04_0_setup — the only file to be edited in Week 4
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 A 이다. 이후의 모든 절이 여기서 만든 변수를 쓰므로 가장
%      먼저 실행한다.
%      This is section A of Part 2, run first because every later section uses
%      the variables it defines.
%
%  이 파일의 역할 / what this file is for
%      W04_heading_control.slx 의 모든 Constant, Gain, Step 블록이 여기서 정의한
%      변수의 이름을 갖고 있다. 게인이나 명령을 바꾸려면 모델을 열 것 없이 이
%      파일을 고치고 다시 실행한다.
%      Every Constant, Gain and Step block in W04_heading_control.slx holds the
%      name of a variable defined here, so a gain or a command is changed by
%      editing this file and running it again, without opening the model.
%
%  실행 / to run
%      W04_0_setup
%
%  모델이 망가졌을 때 / to rebuild a model that has been damaged
%      W04_1_build_heading

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
%  선수방위에 대한 P-D 제어. 미분항은 오차의 미분이 아니라 요 각속도에 작용한다.
%  W03 §3-4 의 일반형으로 쓰면
%
%     tau_N = Kp ssa(psi_d - psi) + Kd (c_d r_d - r)
%
%  이고, c_d = 0 이면 흔히 보는 tau_N = Kp ssa(psi_d - psi) - Kd r 이 된다.
%
%  P-D on the heading, with the derivative acting on the yaw rate rather than
%  on the derivative of the error. Written in the general form of §3-4 in
%  Week 3 it is the expression above, and at c_d = 0 it reduces to the
%  familiar tau_N = Kp ssa(psi_d - psi) - Kd r.
%
%  §4-3 에서 다음 두 식으로 설계했다 / designed in §4-3 from
%
%     wn = sqrt(Kp/M66),   zeta = (|Nr| + Kd) / (2 sqrt(Kp M66))
%
%  wn = 1.53 rad/s, zeta = 0.9 로 두면 아래 두 값이 나온다.
%  With wn = 1.53 rad/s and zeta = 0.9 this gives the pair below.
Kp = 100.00;                 % [N m per rad]
Kd = 74.90;                  % [N m per rad/s]

%  미분항의 설정값 가중. 0 이면 측정한 요 각속도만 되먹임한다 (이번 주의 기본값).
%  1 이면 명령한 각속도 r_d 와의 차이를 되먹임하며, 명령이 계단인 이번 주에는
%  r_d = 0 이므로 결과가 같다. 8주차의 기준모델이 r_d 를 실제 값으로 채운다.
%  The setpoint weight of the derivative term. At 0 the measured yaw rate
%  alone is fed back, which is this week's default. At 1 the error in rate is
%  fed back; this week's command is a step, so r_d is zero and the result is
%  the same. The reference model of Week 8 fills r_d with a real value.
c_d = 0;

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
fprintf('\n  W04 setup complete\n');
fprintf('    plant           M66 = %.2f kg m^2,  Nr = %.2f\n', M66, Nr);
fprintf('    controller      Kp = %g, Kd = %g, ssa = %d\n', Kp, Kd, use_ssa);
fprintf('    closed loop     wn = %.4f rad/s,  zeta = %.4f\n', wn, ze);
fprintf('    hull alone      zeta = %.4f  (Kd = 0)\n', abs(Nr)/(2*sqrt(Kp*M66)));
fprintf('    reference       %g -> %g deg at t = %g s\n', psi_1, psi_2, t_up);
fprintf('    forward force   %g N\n', X_ff);
fprintf('    simulation      %g s at h = %g s\n\n', T_final, h);
