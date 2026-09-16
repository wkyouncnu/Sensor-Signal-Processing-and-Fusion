%% W02_0_setup — 이번 주에 학생이 고치는 유일한 파일
%  W02_0_setup — the only file to be edited in Week 2
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 A 이다. 이후의 모든 절이 여기서 만든 변수를 쓰므로 가장 먼저
%      실행한다.
%      This is section A of Part 2, and it is run first because every later
%      section uses the variables it defines.
%
%  이 파일의 역할 / what this file is for
%      W02_surge_control.slx 의 모든 Constant, Gain, Step 블록은 숫자가 아니라
%      여기서 정의한 변수의 이름을 갖고 있다. 게인을 바꾸려면 모델을 열 것 없이
%      이 파일을 고치고 다시 실행한다. 실험 조건이 한곳에 모여 있어야 무엇을
%      바꾸어 무엇이 달라졌는지 말할 수 있다.
%
%      Every Constant, Gain and Step block in W02_surge_control.slx holds the
%      name of a variable defined here rather than a number, so a gain is
%      changed by editing this file and running it again. Keeping the
%      conditions of an experiment in one place is what makes it possible to
%      say which change produced which result.
%
%  실행 / to run
%      W02_0_setup
%
%  모델이 망가졌을 때 / to rebuild a model that has been damaged
%      W02_1_build_surge_control

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

%  미분항은 (c_d*u_d - u) 를 미분한다. c_d 가 그 설정값 가중이다.
%    c_d = 0  측정값을 미분한다. 설정값이 계단으로 변해도 미분 킥이 없다
%    c_d = 1  오차를 미분한다. 교과서형이며 Simulink PID 블록과 같아진다
%  The derivative acts on (c_d*u_d - u), and c_d is its setpoint weight:
%    c_d = 0  differentiate the measurement, so a step in u_d produces no kick
%    c_d = 1  differentiate the error, the textbook form, which is what
%             Simulink's PID Controller block does
c_d = 0;

%% ---- anti-windup --------------------------------------------------------
%  aw_mode  0  none            the integrator never stops
%           1  clamping        integration is frozen while the actuator is
%                              saturated and the error drives it further in
%           2  back-calculation the excess (X_sat - X_cmd) is fed back into
%                              the integrator through K_aw
aw_mode = 2;
%  역계산 게인 [1/s]. 1/K_aw 가 추종 시상수이므로 이것은 비가 아니라 **율**이다.
%  2026-09-16 까지 이 파일은 1/T_u = 0.9071 을, W02_vars 는 5 를 갖고 있었다.
%  같은 수를 담아야 하는 두 파일이 갈라져 있었고, 그래서 학생이 Run 을 눌러 얻는
%  결과와 강의노트의 표가 서로 달랐다. 강의의 모든 측정값이 5 로 재어진 것이므로
%  5 로 맞춘다. §2-6 의 표가 그 선택의 근거를 수치로 보인다.
%
%  The back-calculation gain [1/s]. Since 1/K_aw is the tracking time constant
%  this is a rate, not a ratio. Until 2026-09-16 this file held 1/T_u = 0.9071
%  while W02_vars held 5: two files that must carry the same number had drifted
%  apart, so what a student got by pressing Run did not match the tables in the
%  notes. Every measurement in the lecture was taken at 5, and §2-6 shows the
%  evidence for that choice.
K_aw    = 5;

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
