function V = W04_vars()
%W04_VARS  W04_0_setup 과 같은 값을 구조체로 / the values of W04_0_setup, as a struct.
%
%   절 스크립트는 W04_read 를 통해 이 값에서 하나만 바꿔 돌린다. 값을 고치면 두 파일을
%   함께 고친다 (verify_w04_heading 이 대조한다).
%   Section scripts change one value through W04_read. Edit both files together.

cfg = otter_config('base');
V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;  V.y_pont = cfg.y_pont;
V.T_hi = cfg.k_pos*cfg.n_max^2;   V.T_lo = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.V_c = 0;  V.beta_c = 0;  V.x0 = zeros(12,1);

V.X_ff = 60;
V.N_max = min(2*V.y_pont*(V.T_hi - V.X_ff/2), 2*V.y_pont*(V.X_ff/2 - V.T_lo));
V.port_eff = 1;
V.N_open = 10;
V.psi_step = 10;  V.t_step = 5;  V.psi_step2 = 10;  V.t_step2 = 1e6;  V.use_ssa = 1;

V.Kp = 300;  V.Ki = 20;  V.Kd = 100;  V.Nf = 20;  V.Kb = 0.1;

V.T_final = 40;  V.h = 0.02;
end
