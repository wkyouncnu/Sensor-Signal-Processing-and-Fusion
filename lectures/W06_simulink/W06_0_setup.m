%% W06_0_SETUP  6주차 모델이 쓰는 모든 값을 기본 작업공간에 올린다.
%                Put every value the Week 6 models use into the base workspace.
%
%  실행 / to run
%      W06_0_setup
%      open_system('W06_F_position')    그리고 Run / then press Run
%
%  강의에서의 위치 / place in the lecture
%      실험 6-0 이다. 학생이 고치는 유일한 파일이다. 블록에는 숫자가 아니라 이
%      파일의 변수 이름이 들어 있다. F_B_max 를 명령창에서 바꾸고 Run 을 누르면
%      횡방향 권한이 어디서 막히는지 바로 보인다.
%      The file of Experiment 6-0, and the only one a student edits. Changing
%      F_B_max in the Command Window and pressing Run shows at once where the
%      lateral authority runs out.
%
%  이번 주에 달라지는 것 / what changes this week
%      선체는 1~5 주차와 **같은 Otter** 다. 달라지는 것은 추진기가 둘에서 셋으로
%      늘었다는 것 하나뿐이고, 그 하나가 B 의 계급을 2 에서 3 으로 올려 배를
%      **완전구동(fully actuated)** 으로 만든다. 그 결과로 처음 할 수 있게 되는
%      일이 위치제어와 접안이다.
%      The hull is the same Otter as Weeks 1 to 5. The only change is a third
%      thruster, and that one change takes the rank of B from 2 to 3 and makes
%      the vessel fully actuated. Position control and berthing are what that
%      buys.

clear; close all;
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % MSS 를 찾아 경로에 올린다 / finds MSS
cfg = otter_config('bow_thruster');

%% ---- 적재와 조류 / payload and current ------------------------------------
%  otter_M 이 이 둘을 받아 질량행렬을 만들므로 먼저 둔다.
%  otter_M takes these two, so they come first.
mp     = 25;                  % 적재 질량 / payload mass                    [kg]
rp     = [0.05 0 -0.35]';     % 적재 위치 / payload position in {b}         [m]
V_c    = 0;                   % 조류 속도. 실험 6-7 은 0.2 / current speed  [m/s]
beta_c = pi/2;                % 조류가 흘러가는 방향. pi/2 = 동쪽 / flows east

%% ---- 선체와 추진기 / hull and thrusters -----------------------------------
y_pont = cfg.y_pont;     % 폰툰 반간격 0.395 m / half the pontoon separation
l_f    = cfg.l_f;        % 선수추진기의 전방 거리 1.5 m / the bow thruster's arm
k_pos  = cfg.k_pos;   k_neg = cfg.k_neg;   % 추력 곡선 계수 / thrust-curve coefficients
n_max  = cfg.n_max;   n_min = cfg.n_min;   % 축 회전수 한계 / shaft-speed limits [rad/s]

%  제어 유효행렬. otter_B 가 열 규칙 하나에서 유도한다 (6-2 절).
%  The control effectiveness matrix, derived by otter_B from the column rule.
B    = cfg.B;            % [1 1 0; 0 0 1; 0.395 -0.395 1.5]
Binv = inv(B);           %#ok<MINV>   det B = 0.79, 그래서 역행렬이 있다 / so it exists

%  선미 프로펠러 하나가 낼 수 있는 추력 / what one stern propeller can produce
T_max = k_pos*n_max^2;        %  119.68 N   전진 / ahead
T_min = -k_neg*n_min^2;       % -66.71 N    후진 / astern

%  선수추진기의 정격. 터널 추진기는 양쪽으로 같은 추력을 낸다 — 선미 프로펠러의
%  전진·후진 비대칭(119.68 대 66.71)이 여기에는 없다.
%  The bow unit's rating. A tunnel thruster is symmetric, so the fore-and-aft
%  asymmetry of the stern propellers does not appear here.
F_B_max = 40;                 % [N]

%% ---- 질량행렬 / the system inertia ----------------------------------------
%  선수추진기의 힘은 otter.m 안으로 들어갈 자리가 없으므로 중첩으로 더한다
%  (6-5 절). 그 중첩이 M 의 역행렬을 쓰며, otter_M 이 otter.m 과 같은 줄로
%  M 을 다시 만든다 — 유한차분으로 재지 않는다.
%  The bow thruster's force has no argument in otter.m and is added by
%  superposition, which needs inv(M). otter_M rebuilds M line by line as
%  otter.m builds it; it is not measured by finite differences.
[Mmat, Minv] = otter_M(mp, rp);          %#ok<ASGLU>

%% ---- 열린 루프 명령 (6-2 ~ 6-4 절) / the open-loop demand -----------------
%  배가 세 방향으로 따로 힘을 낼 수 있는지 보는 실험이다. 셋 중 하나만 0 이
%  아니게 두면 그 방향으로만 움직여야 한다.
%  The experiment that asks whether the three generalized forces can be
%  commanded independently: with one of the three non-zero the vessel should
%  move that way and no other.
X_cmd = 0;            % 전진력 / surge force       [N]
Y_cmd = 25;           % 횡력   / sway force        [N]
N_cmd = 0;            % 요 모멘트 / yaw moment     [N m]

%% ---- 위치제어 (6-6 절) / position control ---------------------------------
%  바깥 루프: 위치오차 -> 속도명령 (P). 안쪽 루프: 속도오차 -> 힘 (PI).
%  선수각은 4주차의 P-D 를 그대로 쓴다. 세 루프의 게인이 전부 여기 있다.
%  Outer loop: position error to a velocity command, proportional. Inner loop:
%  velocity error to a force, PI. The heading loop is Week 4's P-D unchanged.
N_d   = 20;           % 목표 북쪽 좌표 / commanded north   [m]
E_d   = 10;           % 목표 동쪽 좌표 / commanded east    [m]
psi_d_cmd = 0;        % 목표 선수각 / commanded heading    [rad]

Kp_pos = 0.30;        % 위치 P 게인 / outer proportional gain     [1/s]
u_lim  = 0.80;        % 전진 속도명령 한계 / surge command limit  [m/s]
v_lim  = 0.35;        % 횡방향 속도명령 한계 / sway command limit [m/s]
                      %  횡방향이 더 작다. 낼 수 있는 횡력이 작기 때문이다 (6-4 절)
                      %  smaller, because the lateral force available is smaller

Kp_u = 200;   Ki_u = 200;        % 전진 PI. 3주차가 고른 게인 그대로 / as Week 3 chose
Kp_v = 150;   Ki_v = 120;        % 횡방향 PI / the sway PI
Kb   = 1;                        % back-calculation 게인 / anti-windup gain  [1/s]
                                 % 0 이면 안티와인드업이 없다 / 0 switches it off
X_max = 120;                     % 전진력 한계 / the surge force limit  [N]

%  횡력 한계. 막는 것은 선수추진기의 정격이 아니라 **선미의 후진 한계**다 — 횡력
%  1 N 을 내려면 선미 한 쌍이 1.8987 N 씩 반대로 일해야 하기 때문이다 (6-4 절).
%  정격 40 N 보다 35.13 N 이 먼저 걸린다.
%  The sway-force limit. What binds is not the bow unit's rating but the stern
%  REVERSE limit, because 1 N of sway costs the stern pair 1.8987 N each in
%  opposition: 35.13 N arrives before the unit's own 40 N.
Y_max = min(abs(T_min)/(l_f/(2*y_pont)), F_B_max);    % 35.13 N

Kp = 300;     Kd = 100;          % 선수각 P-D (4주차) / the heading P-D of Week 4
%  요 모멘트의 한계는 남은 추력이 정한다. 세 추진기가 있으므로 4·5 주차의 N_lim
%  식을 그대로 쓸 수 없다 — 배분이 셋을 함께 풀기 때문이다. 여기서는 보수적으로
%  선미 한 쌍이 혼자 낼 수 있는 값을 쓴다 (6-4 절이 그 이유를 센다).
%  The yaw-moment limit is set by the thrust left over. With three thrusters the
%  N_lim of Weeks 4 and 5 no longer applies, because the allocation solves for
%  all three at once; the conservative value the stern pair alone can reach is
%  used here.
N_max = 2*y_pont*min(T_max, -T_min);      % 52.70 N m

%% ---- 같은 제어기를 NED 에서 돌릴 때 (6-7 절) / the same control, run in NED --
%  선체고정 제어기는 위치오차를 한 번 돌려 놓고 전진·횡 속도를 요구했다. NED
%  제어기는 오차를 돌리지 않고 **북·동 속도**를 요구하며, 회전은 안쪽 루프로
%  내려가 측정 속도와 요구 힘에 **두 번** 걸린다. 블록은 그대로이고 자리만 바뀐다.
%  The body-fixed controller rotates the position error once and asks for surge
%  and sway. The NED controller leaves the error in NED and asks for north and
%  east; the rotation moves into the inner loop and acts TWICE, on the measured
%  velocity going in and on the demanded force coming out.
%
%  축마다 게인을 다르게 둘 수 없다. NED 의 북축이 선체의 어느 축을 밀게 되는지는
%  선수각에 따라 달라지므로, 전진에 맞춘 게인은 배가 돌아섰을 때 과도해진다.
%  그래서 **느린 축의 값**(횡) 을 두 축에 함께 쓴다.
%  The axes cannot have different gains: which hull axis a NED axis pushes
%  depends on the heading, so gains tuned for surge become excessive once the
%  vessel has turned. The slower axis's values are used for both.
Kp_ned = 150;   Ki_ned = 120;    % 북·동이 함께 쓰는 PI / one pair for both axes

%  속도명령 한계도 느린 축의 것이다. 그리고 축마다 자르지 않고 **크기**로 자른다 —
%  0.35 를 두 축에 따로 걸면 비스듬한 방향에서 0.35*sqrt(2) = 0.495 m/s 가 된다.
%  The velocity limit is the slow axis's too, and it is applied to the MAGNITUDE:
%  0.35 on each axis separately gives 0.495 m/s on a diagonal.
v_ned_max = v_lim;               % 0.35 m/s

%% ---- 접안 (6-7 ~ 6-9 절) / berthing ---------------------------------------
%  부두는 동쪽 좌표가 일정한 직선이고, 배는 그 동쪽에서 다가온다.
%  The quay is a line of constant east coordinate; the vessel comes from the east.
quay_E   = 0;                 % 부두 벽 / the wall                         [m]
berth_N  = 40;                % 접안점 북쪽 / the berth, north             [m]
berth_E  = 1.2;               % 접안점 동쪽. 벽에서 1.2 m / 1.2 m off the wall
stand_off = 7;                % 접근점이 벽에서 떨어진 거리 / the stand-off [m]
app_N = berth_N;                       % 접근점 / the approach point
app_E = berth_E + stand_off;           %   접안점의 법선 위 / on the berth normal

%  접안 전략 / the berthing strategy
%    0  옆으로 붙인다. 최종 선수각 0 — 뱃머리가 북쪽, 부두와 나란하다
%    1  뱃머리를 먼저 넣는다. 최종 선수각 -90 도 — 뱃머리가 벽을 향한다
%  접근점은 둘이 같다. 다른 것은 최종 선수각 하나뿐이고, 그것이 마지막 7 m 를
%  횡방향 운동으로 할지 전진 운동으로 할지를 정한다 (6-9 절).
%    0 sideways: final heading 0, the bow north and the hull parallel to the quay
%    1 bow first: final heading -90 deg, the bow into the wall
%  The approach point is the SAME for both. The one difference is the final
%  heading, and that decides whether the last 7 m are sway or surge.
bow_on = 0;
if bow_on, psi_berth = -pi/2; else, psi_berth = 0; end   % 최종 선수각 / final heading [rad]

R_app   = 1.5;                % 접근점 도착 반경 / arrival radius, approach point [m]
R_berth = 0.40;               % 접안 판정 반경 / arrival radius, the berth        [m]
psi_tol = deg2rad(5);         % 선수각 정렬 판정 / the heading-alignment test     [rad]
v_tol   = 0.05;               % 정지 판정 속도 / the speed below which it is stopped
%  선회가 **죽었는지**도 함께 본다. 각도만 보면 선수각이 맞은 순간을 지나가는
%  중에도 다음 단계로 넘어가고, 그러면 접안 구간에서 선체가 계속 돌아간다
%  the yaw rate must have died too: on angle alone the phase advances while the
%  heading is merely passing through, and the hull then keeps turning at the berth
r_tol   = deg2rad(1.0);       % 선회 정지 판정 / the yaw rate below which it is still [rad/s]

%% ---- 출발점 / the start ----------------------------------------------------
%  정지 상태, 북쪽을 보고, 부두에서 동쪽으로 25 m
%  at rest, facing north, 25 m east of the quay
x0 = zeros(12,1);
x0(7) = 0;      % 북 / north  [m]
x0(8) = 25;     % 동 / east   [m]

%% ---- 실시간 화면 / the live view ------------------------------------------
%   animate = 1 이면 도는 동안 창이 하나 뜬다: 왼쪽에 부두·접근점·접안점·궤적·
%   선체, 오른쪽에 거리와 선수각 오차 · 세 요구 힘 · 세 추진기 · 단계 번호.
%   0 이면 Animate 블록이 아무것도 하지 않는다 (블록을 빼지 않는다).
%   animate = 1 opens one window while the model runs; 0 makes the Animate
%   block do nothing. No block is added or removed either way.
animate       = 1;
animate_every = 0.5;   % 다시 그리는 간격 [시뮬레이션 초] / redraw interval

%   pace = 1 이면 현실 시간에 맞춰 돈다 (Simulink Simulation Pacing).
%   결과는 완전히 같고 기다리는 시간만 다르다 / identical results, different waiting.
pace = 0;

%   실시간 화면의 축 범위 / the limits of the live view
track_Emin = -4;   track_Emax = 30;
track_Nmin = -8;   track_Nmax = 52;

%% ---- 시뮬레이션 / simulation -----------------------------------------------
h       = 0.02;       % [s]
T_final = 200;        % [s]

fprintf(['\n  W06_0_setup\n' ...
         '    actuation   3 thrusters, rank B = %d, det B = %.3f  ->  fully actuated\n' ...
         '    thrust      stern %+.2f .. %+.2f N per propeller,  bow +-%.0f N\n' ...
         '    lever       l_f/(2 y_pont) = %.4f\n' ...
         '    sway limit  %.2f N from the stern reverse limit, %.2f N from the bow unit\n' ...
         '    berth       (%.1f, %.1f) via (%.1f, %.1f), final heading %+.0f deg\n\n'], ...
        rank(B), det(B), T_min, T_max, F_B_max, ...
        l_f/(2*y_pont), ...
        abs(T_min)/(l_f/(2*y_pont)), F_B_max, ...
        berth_N, berth_E, app_N, app_E, rad2deg(psi_berth));
