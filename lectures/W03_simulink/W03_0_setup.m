%% W03_0_SETUP  3주차 모델이 쓰는 모든 값을 기본 작업공간에 올린다.
%                Put every value the Week 3 models use into the base workspace.
%
%  실행 / to run
%      W03_0_setup
%      open_system('W03_E_PID')    그리고 Run / then press Run
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 A 이다. 학생이 고치는 유일한 파일이다. 블록에는 숫자가 아니라 이
%      파일의 변수 이름이 들어 있다. Kp 를 명령창에서 바꾸고 Run 을 누르면 바로 보인다.
%      Section A of Part 2 and the only file a student edits. The blocks hold
%      variable names from this file, so changing Kp in the Command Window and
%      pressing Run shows the new response at once.
%
%  2주차와 같은 제어기, 다른 플랜트 / the Week 2 controller, a new plant
%      플랜트는 Otter 의 전진 속도 u 이다. 모델을 몰라도 튜닝할 수 있다 — 2주차의
%      튜닝 순서를 그대로 밟는다 (model-free tuning).
%      The plant is the surge speed u of the Otter. It is tuned without a model
%      of it, following the tuning order of Week 2.

clear; close all;
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % MSS 를 찾아 경로에 올린다 / finds MSS

%% ---- 선체와 추진기 / hull and thrusters (Week 1) ---------------------------
cfg   = otter_config('base');
k_pos = cfg.k_pos;   k_neg = cfg.k_neg;       % 추력 계수, 프로펠러 하나 / thrust coefficient, one propeller
n_max = cfg.n_max;   n_min = cfg.n_min;       % 축 회전수 한계 / shaft speed limits  [rad/s]
X_hi  =  2*k_pos*n_max^2;                     % 두 추진기의 최대 전진력 / largest forward force  [N]
X_lo  = -2*k_neg*n_min^2;                     % 최대 후진력 / largest backward force  [N]
mp = 25;   rp = [0.05 0 -0.35]';              % 탑재물 / payload  [kg], [m]
V_c = 0;   beta_c = 0;                        % 조류 없음 / no current
x0 = zeros(12,1);                             % 정지 상태에서 출발 / start at rest

%% ---- 열린 루프 시험 (W03_C_open_loop) / the open-loop test ----------------
X_open = 100;         % 계단으로 가하는 전진력 / step surge force  [N]

%% ---- 목표 속도 / the speed command ----------------------------------------
u_step  = 1.5;        % 목표 속도 / commanded speed               [m/s]
t_step  = 5;          % 계단 시각 / step instant                  [s]
u_step2 = 1.5;        % 두 번째 목표 (W03_F_windup) / the second command  [m/s]
t_step2 = 1e6;        % 그 시각. 1e6 은 "바뀌지 않음" / its instant; 1e6 means never  [s]
ref_filter = 0;       % 1 이면 목표를 1/(ref_Tf s + 1) 로 부드럽게 / 1 smooths the command
ref_Tf     = 1;       % 그 시정수 / its time constant             [s]

%% ---- PID 게인 / the PID gains ---------------------------------------------
Kp = 200;             % 비례 / proportional     [N per m/s]
Ki = 200;             % 적분 / integral         [N per m]
Kd = 0;               % 미분 / derivative       [N per m/s^2]
Nf = 20;              % 미분 필터 / derivative filter  [rad/s]
Kb = 1;               % 되감기 이득. 0 이면 안티와인드업 없음 / back-calculation gain; 0 = none  [1/s]

%% ---- 시뮬레이션 / simulation -----------------------------------------------
T_final = 40;         % [s]
h       = 0.02;       % 고정 스텝 / fixed step (ode4)  [s]

fprintf(['\n  W03_0_setup\n' ...
         '    thrust   X in [%.2f, %.2f] N\n' ...
         '    gains    Kp = %g   Ki = %g   Kd = %g   Nf = %g   Kb = %g\n' ...
         '    command  u_d = 0 -> %g m/s at t = %g s\n\n'], ...
        X_lo, X_hi, Kp, Ki, Kd, Nf, Kb, u_step, t_step);
