%% A1_0_setup — 이 부록에서 학생이 고치는 유일한 파일
%  A1_0_setup — the only file to be edited in this appendix
%
%  이 파일의 역할 / what this file is for
%      A1_actuation.slx 의 모든 Constant 와 Gain 블록이 여기서 정의한 변수의
%      이름을 갖고 있다. 값을 바꾸고 이 스크립트를 실행하면 모델이 그 값으로 돈다.
%      Every Constant and Gain block in A1_actuation.slx holds the name of a
%      variable defined here, so changing a value and running this script is
%      enough to make the model run with it.
%
%  실행 / to run
%      A1_0_setup
%
%  그다음 절을 하나씩 / then, one section at a time
%      A1_C_four_layouts        열 규칙, 네 가지 추진기 배치, 그리고 계수(rank)
%                               the column rule, four layouts, and rank
%      A1_D_attainable_set      선체에 요구할 수 있는 (X, N) 의 범위
%                               what (X, N) the hull can be asked for
%      A1_E_command_that_turns  선회가 아닌 선회 명령
%                               the turn that is not a turn
%      A1_F_sway_without_force  B 의 빈 행이 M 역행렬의 빈 행은 아니다
%                               an empty row in B is not an empty M inverse
%
%  모델이 망가졌을 때 / to rebuild a model that has been damaged
%      A1_1_build_actuation

clear; close all; bdclose('all');

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));            % ...\GradCourse
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

%% ---- propeller command --------------------------------------------------
%  n = [n_left ; n_right] in rad/s.
%
%     [ 60 ;  60   ]   straight ahead
%     [ 60 ; -60   ]   the command that LOOKS like a pure turn, but is not
%     [ 60 ; -78.67]   the command that IS a pure turn, derived in §2-5

n_cmd = [60; -60];

%% ---- the actuator model -------------------------------------------------
%  These are not free parameters. They are read from otter_config, which reads
%  them from otter.m, so the model and the plant cannot disagree.
k_pos = cfg.k_pos;            % forward bollard coefficient, one propeller
k_neg = cfg.k_neg;            % reverse bollard coefficient
n_max = cfg.n_max;            % saturation, forward  [rad/s]
n_min = cfg.n_min;            % saturation, reverse  [rad/s]

%% ---- the control effectiveness matrix -----------------------------------
%  B is DERIVED from the column rule by otter_B. It is never transcribed.
%  Editing this line is how the assignment changes the layout.
B_alloc = cfg.B;              % 3 x 2, tau = B * f

%% ---- vessel and environment --------------------------------------------
mp     = 25;                  % payload mass [kg]
rp     = [0.05 0 -0.35]';     % payload position in {b} [m]
V_c    = 0;                   % current speed [m/s]
beta_c = 0;                   % current direction [rad]

x0     = zeros(12,1);

%% ---- simulation ---------------------------------------------------------
h       = 0.02;
T_final = 60;

%% ---- live view -----------------------------------------------------------
animate       = 1;
animate_every = 0.5;
track_Nmin = -15;   track_Nmax = 15;
track_Emin = -15;   track_Emax = 15;

%% ---- report -------------------------------------------------------------
fprintf('\n  A1 setup complete\n');
fprintf('    configuration   %s, %d thrusters, %d columns, rank(B) = %d\n', ...
        cfg.name, cfg.n_thr, cfg.n_cols, rank(cfg.B));
fprintf('    B  = [%6.3f %6.3f ; %6.3f %6.3f ; %6.3f %6.3f]\n', cfg.B');
fprintf('    sway row        max |B(2,:)| = %.1e   -> Y is unreachable\n', max(abs(cfg.B(2,:))));
fprintf('    n_cmd           [%g ; %g] rad/s\n', n_cmd(1), n_cmd(2));
fprintf('    simulation      %g s at h = %g s\n\n', T_final, h);
