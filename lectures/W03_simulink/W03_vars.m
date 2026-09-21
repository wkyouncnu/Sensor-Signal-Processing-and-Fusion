function V = W03_vars()
%W03_VARS  W03_surge_control.slx 가 필요로 하는 모든 변수를 하나의 구조체로.
%          Every variable W03_surge_control.slx needs, in one struct.
%
%   V = W03_vars
%
%   왜 W03_0_setup 과 따로 있는가 / why this is separate from W03_0_setup
%       W03_0_setup 은 같은 값들을 기본 작업공간에 채운다. 모델을 열고 Run 을
%       누르기만 하면 되게 하려는 것이다. 절 스크립트는 같은 값들을 구조체로
%       필요로 한다. run_sim 이 값 하나만 바꾸어 여러 번 돌릴 때, 작업공간이
%       마지막 실행의 상태로 남지 않게 하기 위해서다.
%
%       W03_0_setup places the same values in the base workspace, which is
%       what is needed to open the model and press Run. The section scripts
%       need them as a struct instead, so that run_sim can vary one value for
%       one run without leaving the workspace in the state of that run.
%
%       둘 다 여기서 같은 숫자를 읽는다. 게인을 적어 두는 곳은 한 군데여야 한다.
%       Both read the same numbers from here, so there is exactly one place
%       where a gain is written down.

mss_path();
cfg = otter_config('base');

%  ---- the plant, from otter.m --------------------------------------------
V.M11   = 85.50;                      % surge mass incl. added mass [kg]
V.Xu    = 24.4*9.81/(6*0.5144);       % |X_u|, linear surge damping [N per m/s]
V.K_u   = 1/V.Xu;                     % DC gain [(m/s)/N]
V.T_u = V.M11/V.Xu;                 % time constant [s]
V.X_hi  =  2*cfg.k_pos*cfg.n_max^2;   % most the propellers can push [N]
V.X_lo  = -2*cfg.k_neg*cfg.n_min^2;   % most they can pull back [N]

%  ---- the PI design of 3-3 -----------------------------------------------
zeta_d = 0.7;  wn_d = 1.5;
V.zeta_d = zeta_d;  V.wn_d = wn_d;
V.Ki_d = wn_d^2 * V.T_u / V.K_u;
V.Kp_d = (2*zeta_d*sqrt(V.T_u*V.K_u*V.Ki_d) - 1)/V.K_u;

%  ---- controller, as the model reads it ----------------------------------
V.Kp = V.Kp_d;  V.Ki = V.Ki_d;  V.Kd = 0;  V.Nf = 20;

%  미분항의 설정값 가중 / the setpoint weight of the derivative term
%    c_d = 0  측정값을 미분한다 (이 강의의 기본값)
%    c_d = 1  오차를 미분한다 (교과서형, Simulink PID 블록과 같다)
%    c_d = 0  differentiate the measurement, which is this course's default
%    c_d = 1  differentiate the error, the textbook form and the one
%             Simulink's PID Controller block uses
V.c_d = 0;
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
