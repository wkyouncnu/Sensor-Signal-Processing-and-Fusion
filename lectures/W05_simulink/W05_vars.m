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
V.law      = 3;        % 1 atan2, 2 LOS, 3 ILOS — 절 스크립트가 명시해 넘긴다
                       %                           the section scripts pass it explicitly
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
V.X_max = 120;         % 속도 루프가 낼 수 있는 최대 전진력 / the most the speed loop can push  [N]
%  요 모멘트 한계 - 전진력이 남겨 주는 만큼 (5-7 절) / what the surge force leaves over
Nl = @(X) min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X/2), ...
              2*cfg.y_pont*(X/2 + cfg.k_neg*cfg.n_min^2));
V.N_max   = Nl(V.X_ff);    % 70.85 N m,  전진력이 상수인 모델 / constant surge force
V.N_speed = Nl(V.X_max);   % 47.15 N m,  속도 루프가 붙은 모델 / with the speed loop

%  실시간 화면 / the live view — animate = 0 이면 Animate 블록이 아무것도 안 한다
%  pace = 1 이면 현실 시간에 맞춰 돈다 / pace = 1 runs at wall-clock speed
%  절 스크립트는 한 번에 여러 번 돌리므로 여기서는 꺼 둔다. 화면이 보이는 것은
%  W05_0_setup 으로 값을 올리고 Run 을 누를 때다 / off for batch runs; the live view
%  belongs to pressing Run after W05_0_setup, where animate = 1.
V.animate = 0;  V.animate_every = 0.5;  V.pace = 0;
V.track_Emin = -30;  V.track_Emax = 140;
V.track_Nmin = -30;  V.track_Nmax = 100;

%  속도 루프 (3주차) — §5-7 의 W05_H_speed_path 만 쓴다
%  the speed loop of Week 3; used only by W05_H_speed_path in §5-7
V.u_d   = 1.0;         % 목표 전진속도 / commanded surge speed    [m/s]
V.Kp_u  = 200;         % 3주차의 게인 그대로 / the gains of Week 3, unchanged
V.Ki_u  = 200;
V.Kb    = 1;           % 되감기 이득, 3주차와 같다 / back-calculation gain, as in Week 3

%  선체와 추진기 / hull and thrusters
V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;  V.y_pont = cfg.y_pont;
V.n_max = cfg.n_max;  V.n_min = cfg.n_min;   % 축 회전수 한계 / shaft-speed limits [rad/s]
V.mp = 25;  V.rp = [0.05 0 -0.35]';

%  조류 / the current — 기본은 없음 / none by default
V.V_c = 0;  V.beta_c = pi/2;   % 속도 [m/s], 향하는 방향 (pi/2 = 동쪽으로) / speed, direction it flows to

V.h = 0.02;  V.T_final = 400;
end
