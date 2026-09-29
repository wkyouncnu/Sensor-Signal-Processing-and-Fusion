%% W05_0_SETUP  5주차 모델이 쓰는 모든 값을 기본 작업공간에 올린다.
%                Put every value the Week 5 models use into the base workspace.
%
%  실행 / to run
%      W05_0_setup
%      open_system('W05_D_LOS')    그리고 Run / then press Run
%
%  강의에서의 위치 / place in the lecture
%      실험 5-0 이다. 학생이 고치는 유일한 파일이다. 블록에는 숫자가 아니라 이
%      파일의 변수 이름이 들어 있다. Delta 를 명령창에서 바꾸고 Run 을 누르면 바로 보인다.
%      the file of Experiment 5-0, and the only one a student edits. Changing Delta in
%      the Command Window and pressing Run shows the new track at once.
%
%  이번 주에 튜닝하는 것 / what is tuned this week
%      선수각 오토파일럿(4주차)은 그대로 두고, 그 앞의 유도 법칙을 모델 없이 튜닝한다.
%      LOS 는 횡방향 오차에 대한 P 제어기(Kp = 1/Delta), ILOS 는 PI 제어기다.
%      The heading autopilot (Week 4) is left alone; the guidance law in front
%      of it is tuned without a model. LOS is a P controller on the cross-track
%      error (Kp = 1/Delta); ILOS is a PI controller.

clear; close all;
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % MSS 를 찾아 경로에 올린다 / finds MSS
cfg = otter_config('base');

%% ---- 경로 / the path -------------------------------------------------------
%  다섯 웨이포인트 임무, 다리 넷, 각 60 m / the five-waypoint mission, four 60 m legs
WP_N = [0 60 60  0  60]';     % 북쪽 좌표 / north coordinates   [m]
WP_E = [0  0 60 60 120]';     % 동쪽 좌표 / east coordinates    [m]

%% ---- 유도 / guidance ---------------------------------------------------------
Delta    = 5;         % 앞보기 거리. 작을수록 세게 경로로 돌아온다 (P 게인 = 1/Delta)
                      % look-ahead distance; smaller turns back harder (P gain = 1/Delta)  [m]
R_switch = 3;         % 다음 다리로 넘어가는 거리 / distance at which the next leg starts  [m]
kappa    = 0.3;       % ILOS 적분 계수 (I 게인 = kappa/Delta) / ILOS integral constant (I gain = kappa/Delta)

%% ---- 출발점 / the start ------------------------------------------------------
E0 = 20;              % 경로에서 동쪽으로 떨어진 거리 / distance east of the path  [m]
x0 = zeros(12,1);  x0(8) = E0;   % 정지, 북쪽을 봄 / at rest, facing north

%% ---- 선수각 오토파일럿 (4주차) / heading autopilot (Week 4) -------------------
Kp    = 300;          % [N m per rad]
Kd    = 100;          % 요각속도에 곱한다 / multiplies the yaw rate  [N m s per rad]
X_ff  = 60;           % 전진력 / surge force (about 0.77 m/s)  [N]
%  요 모멘트의 한계는 **전진력이 얼마나 남겨 주느냐**로 정해진다 (5-7 절).
%  두 추력 T = X/2 +- N/(2 y_pont) 가 각각 [-k_neg n_min^2, k_pos n_max^2] 안에
%  있어야 하고, 그 조건을 |N| 에 대해 푼 것이 아래 둘 중 작은 쪽이다.
%  The yaw-moment limit is what the surge force leaves over: both thrusts must stay
%  inside the propellers' range, and solving that for |N| gives the smaller of two.
N_lim = @(X) min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X/2), ...
                 2*cfg.y_pont*(X/2 + cfg.k_neg*cfg.n_min^2));
N_max   = N_lim(X_ff);    % 전진력이 상수인 모델 / where the surge force is constant   70.85 N m

%% ---- 실시간 화면 / the live view -----------------------------------------
%   animate = 1 이면 도는 동안 창이 하나 뜬다: 왼쪽에 경로·웨이포인트·궤적·선체,
%   오른쪽에 횡방향 오차 · 속도와 그 명령 · 두 축의 회전수 · 웨이포인트 번호.
%   0 이면 Animate 블록이 아무것도 하지 않는다 (블록을 빼지 않는다).
%   animate = 1 opens one window while the model runs; 0 makes the Animate block
%   do nothing. No block is added or removed either way.
animate       = 1;
animate_every = 0.5;   % 다시 그리는 간격 [시뮬레이션 초] / redraw interval

%   pace = 1 이면 **현실 시간에 맞춰** 돈다 (Simulink Simulation Pacing).
%   0 이면 낼 수 있는 만큼 빨리 돈다. 결과는 완전히 같고 기다리는 시간만 다르다 —
%   수업에서 보여 줄 때는 1, 수치를 낼 때는 0 이다.
%   pace = 1 runs at wall-clock speed; 0 runs as fast as it can. The results are
%   identical and only the waiting differs.
pace = 0;

%   실시간 화면의 축 범위 / the limits of the live view
track_Emin = -30;  track_Emax = 140;
track_Nmin = -30;  track_Nmax = 100;

%% ---- 속도 루프 (3주차) / the speed loop of Week 3 ------------------------
%   §5-7 의 W05_H_speed_path 만 이 넷을 쓴다. 다른 모델은 전진력이 상수 X_ff 다.
%   Only W05_H_speed_path uses these four; every other model pushes at X_ff.
u_d   = 1.0;          % 목표 전진속도 / commanded surge speed         [m/s]
Kp_u  = 200;          % 3주차가 고른 게인 그대로 / the gains Week 3 chose
Ki_u  = 200;
Kb    = 1;            % back-calculation gain, as in Week 3            [1/s]
                      % 0 이면 안티와인드업이 없다 / 0 switches the anti-windup off
X_max = 120;          % 전진력 한계 / the surge force limit            [N]

%  속도 루프가 붙으면 전진력이 X_max 까지 올라갈 수 있으므로 한계를 **거기서** 잡는다.
%  그러지 않으면 배분기가 낼 수 없는 회전수를 요구한다 - 실제로 n = 116.2 rad/s 를
%  요구했고 프로펠러의 한계는 103.9 였다 (5-7 절).
%  With a speed loop the force can reach X_max, so the limit is taken there. Left at
%  N_max the allocator asks for shaft speeds the propellers cannot reach: it asked
%  for 116.2 rad/s against a limit of 103.9.
N_speed = N_lim(X_max);   % 속도 루프가 붙은 모델 / where a speed loop can push harder  47.15 N m

%% ---- 선체와 추진기 / hull and thrusters --------------------------------------
k_pos = cfg.k_pos;   k_neg = cfg.k_neg;   y_pont = cfg.y_pont;
n_max = cfg.n_max;   n_min = cfg.n_min;    % 축 회전수 한계 / the shaft-speed limits [rad/s]
mp = 25;   rp = [0.05 0 -0.35]';

%% ---- 조류 / the current ------------------------------------------------------
V_c    = 0;           % 조류 속도. 실험 5-5 는 0.3 / current speed; Experiment 5-5 uses 0.3  [m/s]
beta_c = pi/2;        % 조류가 흘러가는 방향. pi/2 = 동쪽으로 / direction it flows to; pi/2 = east

%% ---- 시뮬레이션 / simulation -------------------------------------------------
h       = 0.02;       % [s]
T_final = 400;        % [s]

fprintf(['\n  W05_0_setup\n' ...
         '    path      %d waypoints, legs of 60 m\n' ...
         '    guidance  Delta = %g m (P gain %.3f), R_switch = %g m, kappa = %g\n' ...
         '    start     %g m east of the path;  current %g m/s\n\n'], ...
        numel(WP_N), Delta, 1/Delta, R_switch, kappa, E0, V_c);
