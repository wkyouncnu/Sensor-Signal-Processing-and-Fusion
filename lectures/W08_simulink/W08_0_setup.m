%% W08 · 실험 8-0 — 이번 주의 값들 / Experiment 8-0 — the parameters of this week
%
%  학생이 손으로 고치는 유일한 파일이다 / the only file edited by hand.
%
%  무엇이 들어 있는가 / what is in it
%      붙잡을 자리, 위치 제어기의 게인 셋, 4주차의 선수각 오토파일럿,
%      임무(웨이포인트·도착 반경·유지 시간), 그리고 조류
%      the station, the three gains of the position loop, the Week 4 autopilot,
%      the mission, and the current
%
%  같은 값이 W08_vars.m 에도 있다 — verify_w08_dp 의 검사 1 이 대조한다.

clear

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

%% 붙잡을 자리 / the station to hold
N_hold = 0;  E_hold = 0;      % 유지할 위치 / the position to hold                 [m]
psi_fix = 0;                  % §8-2 가 고정하는 선수각 / the heading §8-2 fixes   [deg]

%% 위치 제어기 (전진축만) / the position controller, along the bow only
%  이 선체는 옆으로 밀 수 없다 (6주차: B 의 둘째 행이 0). 그래서 위치 제어기는
%  **전진축 성분에만** 작용하고, 옆으로 벌어진 몫은 선수각을 돌려서 갚는다 (§8-3).
%  This hull cannot push sideways (Week 6: the sway row of B is zero), so the
%  position controller acts on the along-bow component only, and the sideways
%  part is paid for by turning the vessel (§8-3).
Kp_x = 30;                    % 위치 오차 -> 힘 / position error to force          [N/m]
Ki_x = 3;                     % 남는 오차를 없앤다 / removes what is left          [N/(m s)]
Kd_x = 60;                    % 전진속도에 대한 제동 / damping on surge speed      [N/(m/s)]
e_min = 0.3;                  % 이보다 가까우면 선수각을 유지 / hold the heading inside this [m]
X_max = 120;                  % 전진력 한계 / surge force limit                    [N]

%% 선수각 오토파일럿 (4주차) / the heading autopilot of Week 4
cfg = otter_config('base');
Kp = 300;  Kd = 100;
N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X_max/2), ...
            2*cfg.y_pont*(X_max/2 + cfg.k_neg*cfg.n_min^2));

%% 임무 (§8-5) / the mission
WP_N = [0 40 40]';            % 웨이포인트 / waypoints                             [m]
WP_E = [0  0 40]';
R_arrive = 2;                 % 도착 판정 반경 / the arrival radius                [m]
T_hold   = 40;                % 각 지점에서 붙잡는 시간 / how long to hold         [s]
X_ff     = 60;                % 이동 중의 전진력 / the surge force in transit      [N]
Delta    = 5;                 % 5주차의 앞보기 거리 / the look-ahead of Week 5     [m]
hand_over = 1;                % 1 이면 모드가 바뀔 때 적분을 넘겨받는다 / hands the integral over

%% 환경 / the environment
V_c = 0.3;  beta_c = pi/2;    % 동쪽으로 흐르는 조류 / a current towards the east  [m/s]

%% 선체와 추진기 / hull and thrusters
y_pont = cfg.y_pont;  k_pos = cfg.k_pos;  k_neg = cfg.k_neg;
T_max  = cfg.k_pos*cfg.n_max^2;  T_min = -cfg.k_neg*cfg.n_min^2;
mp = 25;  rp = [0.05 0 -0.35]';
x0 = zeros(12,1);

h = 0.02;  T_final = 200;

fprintf(['\n  W08_0_setup\n' ...
         '    station   hold (N, E) = (%g, %g) m;  the current runs at %.2f m/s towards %.0f deg\n' ...
         '    position  Kp_x = %g N/m, Ki_x = %g, Kd_x = %g;  |X| <= %g N\n' ...
         '    heading   the Week 4 autopilot, Kp = %g, Kd = %g;  |N| <= %.2f N m\n' ...
         '    mission   %d waypoints, arrive within %g m, hold %g s at each\n\n'], ...
        N_hold, E_hold, V_c, beta_c*180/pi, Kp_x, Ki_x, Kd_x, X_max, Kp, Kd, N_max, ...
        numel(WP_N), R_arrive, T_hold);
