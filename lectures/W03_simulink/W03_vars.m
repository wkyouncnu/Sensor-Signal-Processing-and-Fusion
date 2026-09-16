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

%  ---- 제어기 / the controller --------------------------------------------
%  tau_N = Kp ssa(psi_d - psi) + Kd (c_d r_d - r)
%
%  c_d 는 미분항의 설정값 가중이며, W02 §2-4 의 것과 같은 뜻이다.
%    c_d = 0  측정한 요 각속도만 되먹임한다. MSS 의 관용이며 이번 주의 기본값
%    c_d = 1  명령한 각속도와의 차이를 되먹임한다. 명령이 계단인 이번 주에는
%             r_d = 0 이므로 두 값이 같은 결과를 준다
%
%  c_d is the setpoint weight of the derivative term, in the sense of §2-4 in
%  Week 2:
%    c_d = 0  feed back the measured yaw rate alone, the MSS convention and
%             this week's default
%    c_d = 1  feed back the error in rate. This week's command is a step, so
%             r_d is zero and the two give the same result
V.Kp = 100.00;  V.Kd = 74.90;   V.use_ssa = 1;
V.c_d = 0;

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
