%% W06 · 실험 6-0 — 이번 주의 값들 / Experiment 6-0 — the parameters of this week
%
%  학생이 손으로 고치는 유일한 파일이다. 모델의 어느 블록에도 숫자가 없다 — 전부
%  여기 있는 변수 이름을 읽는다. 값을 하나 바꾸고 모델에서 Run 을 누르면 된다.
%  The only file edited by hand. No block holds a number; every one of them reads
%  a variable defined here. Change one value and press Run in a model.
%
%  같은 값이 W06_vars.m 에도 있다 (스크립트가 한 번에 여러 값을 바꿔 돌릴 때 쓴다).
%  둘을 함께 고친다 — verify_w06_allocation 의 검사 1 이 대조한다.
%  The same values live in W06_vars.m, which the section scripts use to change a
%  few at a time. Edit both; check 1 of verify_w06_allocation compares them.

clear

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

%% 선체와 추진기 / the hull and its thrusters — 부록 A1 의 값
cfg    = otter_config('base');
y_pont = cfg.y_pont;          % 추진기 팔, 폰툰 간격의 절반 / thruster arm    [m]
k_pos  = cfg.k_pos;           % 전진 추력계수 / ahead coefficient             [N/(rad/s)^2]
k_neg  = cfg.k_neg;           % 후진 추력계수 / astern coefficient
n_max  = cfg.n_max;           % 회전수 한계 / shaft speed limits              [rad/s]
n_min  = cfg.n_min;
T_max  =  k_pos*n_max^2;      % 추진기 하나의 추력 한계 / one propeller's limits  [N]
T_min  = -k_neg*n_min^2;

%% 요구하는 일반화 힘 / the generalised force demanded — 시간표는 모델마다 다르다
X_cmd = 100;                  % 전진력 / surge force                          [N]
N_cmd = 20;                   % 요 모멘트 / yaw moment                        [N m]
Y_cmd = 30;                   % 횡력 — 이 선체가 낼 수 없는 것 / sway, which this hull cannot make  [N]
X_big = 220;                  % 한계를 넘기는 요구 / a demand past the limits  [N]
N_big = 50;                   %                                               [N m]

%% 배분기의 두 스위치 / the two switches of the allocator
fit_mode = 1;                 % 1 = 비율로 줄인다 (방향 유지), 0 = 잘라 낸다 / 1 scales, 0 clips
use_kneg = 1;                 % 1 = 후진에 k_neg 를 쓴다 (옳다), 0 = 양방향 k_pos

%% 선체 상태와 시뮬레이션 / the vessel and the run
mp = 25;  rp = [0.05 0 -0.35]';     % 적재물 / payload
V_c = 0;  beta_c = 0;               % 조류 없음 / no current
x0 = zeros(12,1);
h = 0.02;  T_final = 45;

fprintf(['\n  W06_0_setup\n' ...
         '    hull      arm y_pont = %.3f m,  one propeller gives T in [%.2f, %.2f] N\n' ...
         '    curve     T = k n|n| with k_pos = %.5f ahead, k_neg = %.5f astern\n' ...
         '    demand    X = %g N, N = %g N m;  the sway asked for in 6-3 is Y = %g N\n' ...
         '    allocator fit_mode = %g (1 scales, 0 clips),  use_kneg = %g\n\n'], ...
        y_pont, T_min, T_max, k_pos, k_neg, X_cmd, N_cmd, Y_cmd, fit_mode, use_kneg);
