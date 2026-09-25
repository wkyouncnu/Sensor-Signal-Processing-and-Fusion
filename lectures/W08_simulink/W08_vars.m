function V = W08_vars()
%W08_VARS  W08_0_setup 과 같은 값을 구조체로 / the values of W08_0_setup, as a struct.

cfg = otter_config('base');

%% 붙잡을 자리 / the station to hold
V.N_hold = 0;  V.E_hold = 0;      % 유지할 위치 / the position to hold            [m]
V.psi_fix = 0;                     % §8-2 가 고정하는 선수각 / the heading §8-2 fixes [deg]

%% 위치 제어기 (전진축만) / the position controller, along the bow only
V.Kp_x = 30;                       % 위치 오차 -> 힘 / position error to force     [N/m]
V.Ki_x = 3;                        % 남는 오차를 없앤다 / removes what is left     [N/(m s)]
V.Kd_x = 60;                       % 전진속도에 대한 제동 / damping on surge speed [N/(m/s)]
V.e_min = 0.3;                     % 이보다 가까우면 선수각을 유지한다 / hold the heading inside this [m]
V.X_max = 120;                     % 전진력 한계 / surge force limit               [N]

%% 선수각 오토파일럿 (4주차) / the heading autopilot of Week 4
V.Kp = 300;  V.Kd = 100;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_max/2), ...
              2*cfg.y_pont*(V.X_max/2 + cfg.k_neg*cfg.n_min^2));

%% 임무 (§8-5) / the mission
V.WP_N = [0 40 40]';               % 웨이포인트 / waypoints                        [m]
V.WP_E = [0  0 40]';
V.R_arrive = 2;                    % 도착 판정 반경 / the arrival radius           [m]
V.T_hold   = 40;                   % 각 지점에서 붙잡는 시간 / how long to hold    [s]
V.X_ff     = 60;                   % 이동 중의 전진력 / the surge force in transit [N]
V.Delta    = 5;                    % 5주차의 앞보기 거리 / the look-ahead of Week 5 [m]
V.hand_over = 1;                   % 1 이면 모드가 바뀔 때 적분을 넘겨받는다 / 1 hands the integral over

%% 환경 / the environment — 조류 하나. 파랑은 7주차가 다룬다
V.V_c = 0.3;  V.beta_c = pi/2;     % 동쪽으로 0.3 m/s / 0.3 m/s towards the east

%% 선체와 추진기 / hull and thrusters
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.x0 = zeros(12,1);

V.h = 0.02;  V.T_final = 200;
end
