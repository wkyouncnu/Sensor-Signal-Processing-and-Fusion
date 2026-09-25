function V = W09_vars()
%W09_VARS  W09_0_setup 과 같은 값을 구조체로 / the values of W09_0_setup, as a struct.

cfg = otter_config('base');

%% 임무 / the mission — 이동과 유지를 오가며 세 지점
V.WP_N = [60 60  0]';  V.WP_E = [ 0 60 60]';
V.R_arrive = 3;  V.T_hold = 30;    % 도착 반경 [m], 유지 시간 [s]
V.u_d = 1.0;                       % 이동 속도 / the transit speed               [m/s]

%% 각 주차가 넣은 것 / what each week contributed — 0 으로 두면 그 주차를 빼고 돌린다
V.use_Ki_u   = 1;                  % 3주차: 속도 루프의 적분 / the speed integral
V.use_ssa    = 1;                  % 4주차: 최단각 (§4-6) / the shortest-angle wrap
V.use_Kd     = 1;                  % 4주차: 선수각의 미분 / the heading derivative
V.use_ilos   = 1;                  % 5주차: 유도의 적분 / the guidance integral
V.use_pass   = 1;                  % 5주차: 지나갔는가로 웨이포인트를 넘긴다 / the along-track switch
V.use_scale  = 1;                  % 6주차: 한계에서 비율로 줄이기 / scaling at the limits
V.use_notch  = 1;                  % 7주차: 파랑 필터 / the wave filter
V.use_vane   = 1;                  % 8주차: 유지에서 뱃머리를 놓아 준다 / the bow set free in a hold
V.hand_over  = 1;                  % 8주차: 모드가 바뀔 때 적분을 넘겨받는다 / the handover

%% 3주차 · 속도 루프 / the speed loop
V.Kp_u = 200;  V.Ki_u = 200;

%% 4주차 · 선수각 / the heading loop
V.Kp = 300;  V.Kd = 100;

%% 5주차 · 유도 / the guidance
V.Delta = 5;  V.kappa = 0.3;

%% 7주차 · 바다와 노치 / the sea and the notch
V.Hs = 0.3;  V.T0 = 2.0;  V.gamma_j = 3.3;  V.N_comp = 20;  V.sigma_psi = 3;
V.w0 = 2*pi/V.T0;
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
V.wave_on = 1;
V.phase_shift = 0;                 % 같은 스펙트럼의 다른 실현 / another realisation  [rad]
V.zeta_n = 0.05;  V.zeta_d = 0.3;

%% 8주차 · 위치 루프 / the position loop
V.Kp_x = 30;  V.Ki_x = 3;  V.Kd_x = 60;  V.e_min = 0.3;

%% 한계 / the limits
V.X_max = 120;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_max/2), ...
              2*cfg.y_pont*(V.X_max/2 + cfg.k_neg*cfg.n_min^2));
%  전진력이 0 일 때의 요 한계. 6주차의 결합을 잊은 설계가 쓰는 값이다 (§9-3).
%  The yaw limit at zero surge — what a design that forgets the coupling would use.
V.N_open = 2*cfg.y_pont*cfg.k_pos*cfg.n_max^2;

%% 환경과 선체 / the environment and the hull
V.V_c = 0.3;  V.beta_c = pi/2;
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.x0 = zeros(12,1);

V.h = 0.02;  V.T_final = 290;
end
