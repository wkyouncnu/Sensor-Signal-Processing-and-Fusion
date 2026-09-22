%% W05_0_SETUP  5주차 모델이 쓰는 모든 값을 기본 작업공간에 올린다.
%                Put every value the Week 5 models use into the base workspace.
%
%  실행 / to run
%      W05_0_setup
%      open_system('W05_D_LOS')    그리고 Run / then press Run
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 A 이다. 학생이 고치는 유일한 파일이다. 블록에는 숫자가 아니라 이
%      파일의 변수 이름이 들어 있다. Delta 를 명령창에서 바꾸고 Run 을 누르면 바로 보인다.
%      Section A of Part 2 and the only file a student edits. Changing Delta in
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
N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X_ff/2), ...
            2*cfg.y_pont*(X_ff/2 + cfg.k_neg*cfg.n_min^2));   % 요 모멘트 한계 / yaw-moment limit  [N m]

%% ---- 선체와 추진기 / hull and thrusters --------------------------------------
k_pos = cfg.k_pos;   k_neg = cfg.k_neg;   y_pont = cfg.y_pont;
mp = 25;   rp = [0.05 0 -0.35]';

%% ---- 조류 / the current ------------------------------------------------------
V_c    = 0;           % 조류 속도. 절 F 는 0.3 / current speed; section F uses 0.3  [m/s]
beta_c = pi/2;        % 조류가 흘러가는 방향. pi/2 = 동쪽으로 / direction it flows to; pi/2 = east

%% ---- 시뮬레이션 / simulation -------------------------------------------------
h       = 0.02;       % [s]
T_final = 400;        % [s]

fprintf(['\n  W05_0_setup\n' ...
         '    path      %d waypoints, legs of 60 m\n' ...
         '    guidance  Delta = %g m (P gain %.3f), R_switch = %g m, kappa = %g\n' ...
         '    start     %g m east of the path;  current %g m/s\n\n'], ...
        numel(WP_N), Delta, 1/Delta, R_switch, kappa, E0, V_c);
