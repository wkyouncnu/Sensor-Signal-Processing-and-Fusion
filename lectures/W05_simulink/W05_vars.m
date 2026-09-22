function V = W05_vars()
%W05_VARS  W05_0_setup 과 같은 값을 구조체로 / the values of W05_0_setup, as a struct.
%
%   절 스크립트는 W05_read 를 통해 이 값에서 몇 개만 바꿔 돌린다. 값을 고치면 두 파일을
%   함께 고친다 (verify_w05_guidance 가 대조한다).
%   Section scripts change a few of these through W05_read. Edit both files
%   together; verify_w05_guidance compares them.

cfg = otter_config('base');

%  경로 / the path — 기본은 다섯 웨이포인트 임무, 한 다리 60 m
%  the default is the five-waypoint mission, 60 m legs
V.WP_N = [0 60 60  0  60]';
V.WP_E = [0  0 60 60 120]';

%  유도 / guidance
V.Delta    = 5;        % 앞보기 거리 / look-ahead distance         [m]
V.R_switch = 3;        % 전환 거리 / switching distance            [m]
V.kappa    = 0.3;      % ILOS 적분 계수 / ILOS integral constant

%  출발점: 경로에서 동쪽으로 E0 만큼 떨어져 북쪽을 보고 선다
%  start: E0 metres east of the path, at rest, facing north
V.E0 = 20;
V.x0 = zeros(12,1);  V.x0(8) = V.E0;

%  선수각 오토파일럿 (4주차 식, 미분은 요각속도에) / heading autopilot (Week 4, D on the yaw rate)
V.Kp = 300;  V.Kd = 100;
V.X_ff  = 60;          % 전진력 / surge force  [N]  -> about 0.77 m/s
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_ff/2), ...
              2*cfg.y_pont*(V.X_ff/2 + cfg.k_neg*cfg.n_min^2));

%  선체와 추진기 / hull and thrusters
V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;  V.y_pont = cfg.y_pont;
V.mp = 25;  V.rp = [0.05 0 -0.35]';

%  조류 / the current — 기본은 없음 / none by default
V.V_c = 0;  V.beta_c = pi/2;   % 속도 [m/s], 향하는 방향 (pi/2 = 동쪽으로) / speed, direction it flows to

V.h = 0.02;  V.T_final = 400;
end
