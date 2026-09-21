function V = W03_vars()
%W03_VARS  W03_0_setup 과 같은 값을 구조체로 / the values of W03_0_setup, as a struct.
%
%   절 스크립트는 W03_read 를 통해 이 값에서 하나만 바꿔 돌린다. 그래야 작업공간이
%   마지막 실행의 값으로 남지 않는다. 값을 고치면 두 파일을 함께 고친다.
%   Section scripts change one value of this struct through W03_read, so a
%   sweep never leaves the workspace changed. Edit both files together.

cfg = otter_config('base');
V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;  V.n_max = cfg.n_max;  V.n_min = cfg.n_min;
V.X_hi = 2*cfg.k_pos*cfg.n_max^2;   V.X_lo = -2*cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.V_c = 0;  V.beta_c = 0;  V.x0 = zeros(12,1);

V.X_open = 100;
V.u_step = 1.5;   V.t_step = 5;   V.u_step2 = 1.5;   V.t_step2 = 1e6;
V.ref_filter = 0; V.ref_Tf = 1;

V.Kp = 200;  V.Ki = 200;  V.Kd = 0;  V.Nf = 20;  V.Kb = 1;

V.T_final = 40;  V.h = 0.02;
end
