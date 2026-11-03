%W12_0_SETUP  12주차가 쓰는 값 전부. 학생이 고치는 파일은 이것 하나다.
%             Every value Week 12 uses. This is the only file a student edits.
%
%   실행 / to run
%       W12_0_setup
%
%   이 주차가 보는 것 / what this week looks at
%       추진기 넷이 각각 ±45 도로 기울 수 있는 Otter 다. 1단계에서는 제어기도
%       배분기도 없다. 축회전수 넷과 틸팅 각 넷을 **손으로 주고**, 그 여덟 개의
%       숫자에서 손으로 계산한 힘과 모멘트가 실제로 나오는지, 그래서 배가
%       예상한 방향으로 가는지만 본다. 배분은 뒤에 온다.
%       The Otter with four thrusters, each on a servo limited to +-45 deg.
%       Stage 1 has no controller and no allocation: four shaft speeds and four
%       tilt angles are given BY HAND, and the only question is whether the
%       force, the moment and therefore the direction of travel come out as
%       computed by hand from those eight numbers. Allocation comes later.
%
%   추진기 번호 / thruster numbering  (otter_config('quad_tilt').pos 의 열 순서)
%       1  선수 좌현 / fore port    x = +1.50 m,  y = -0.395 m
%       2  선수 우현 / fore stbd    x = +1.50 m,  y = +0.395 m
%       3  선미 좌현 / aft  port    x = -1.00 m,  y = -0.395 m
%       4  선미 우현 / aft  stbd    x = -1.00 m,  y = +0.395 m
%
%   See also W12_1_BUILD_OPENLOOP, W12_V_OPENLOOP, W12_VARS, W12_PLOT,
%            OTTER_TILT4, OTTER_CONFIG, VERIFY_OTTER_TILT4.

clear; close all;

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));                 % ...\00_GradCourse_2026
addpath(fullfile(root, '_tools'), here);
mss_path();                                        % MSS 를 찾아 경로에 얹는다

cfg = otter_config('quad_tilt');

%% ---- 적재와 해류 / payload and current --------------------------------
%  1~6주차와 **같은 값**이다. 달라진 것은 구동장치뿐이어야 하므로 선체와 적재를
%  건드리지 않는다 / unchanged from Weeks 1-6: only the actuation differs
mp     = 25;                     % 적재 질량 [kg] / payload mass
rp     = [0.05 0 -0.35]';        % 적재 위치 {b} [m] / payload position in {b}
V_c    = 0.0;                    % 해류 속력 [m/s] / current speed
beta_c = pi/2;                   % 해류 방향 [rad] / current direction

%% ---- 추진기 배치와 틸팅 한계 / stations and tilt limits ----------------
%  운동모델 otter_tilt4 가 이 4x4 하나로 자리·한계·거치 방향을 모두 받는다.
%  숫자를 두 군데 적지 않으려고 cfg 에서 그대로 만든다 / built from cfg so the
%  geometry is written once
%
%  넷째 줄이 **거치 부호**다. 선수 둘(1·2)은 앞을, 선미 둘(3·4)은 뒤를 보고
%  달려 있어 서보 0 도의 뜻이 쌍마다 다르다 / the fourth row is the mounting
%  sign: servo zero means +x_b for the bow pair and -x_b for the stern pair
quad = [cfg.pos ; cfg.alpha_max ; cfg.mount];   % [x ; y ; 한계 ; 거치 부호]

alpha_lim  = cfg.alpha_max(1);         % 서보 각 한계 [rad], 네 서보가 같다
alpha_rate = cfg.alpha_rlim(1);        % 서보 각속도 한계 [rad/s]
n_max      = cfg.n_max;                % 축회전수 상한 [rad/s]
n_min      = cfg.n_min;                % 축회전수 하한 [rad/s]

%% ---- 명령: 여덟 개의 숫자 / the command: eight numbers ----------------
%  **이번 주차의 전부가 이 여덟 줄이다.** 모델의 Constant 여덟 개가 이 벡터의
%  원소를 하나씩 집어 가므로, 캔버스의 `n_cmd(3)` 은 선미 좌현 추진기다.
%  각도는 도로 적고 라디안으로 넘긴다 — 사람은 도로 생각하고 모델은 라디안으로
%  돈다 / the whole of stage 1 is these eight numbers; the angles are written in
%  degrees and passed in radians
%
%  이름이 `d_cmd` 인 이유 / why the angles are called d_cmd
%      캔버스의 Constant 폭은 MSS 치수를 그대로 따라 55 px 이고, 거기에
%      `delta_cmd(1)` 은 들어가지 않아 Simulink 가 `-C-` 만 찍는다. 그러면
%      어느 추진기에 무엇을 지시했는지 **그림에서 읽을 수 없다.** d 는 delta 다.
n_cmd = [60 60 60 60]';          % 축회전수 [rad/s], **rpm 이 아니다**
d_deg = [45 45 45 45]';          % 틸팅 각 delta [deg], ±45 가 한계
d_cmd = deg2rad(d_deg);          % 틸팅 각 delta [rad] — 모델이 받는 것

%% ---- 시작 상태 / the start state --------------------------------------
x0     = zeros(12,1);            % 정지, 원점, 선수방위 0
x0(7)  = 0;                      % N [m]
x0(8)  = 0;                      % E [m]

%% ---- 실시간 화면 / the live view --------------------------------------
%  Animate 블록을 빼지 않는다. animate = 0 이면 블록이 아무것도 하지 않는다
%  the Animate block is never removed; animate = 0 makes it do nothing
animate       = 1;               % 사람이 Run 을 누를 때는 1
animate_every = 0.5;             % 다시 그리는 간격 [s]
pace          = 0;               % 1 이면 현실 시간으로 진행한다
track_Emin    = -60;             % 실시간 화면의 축 범위 [m]
track_Emax    =  140;
track_Nmin    = -60;
track_Nmax    =  140;

%% ---- 시뮬레이션 / the simulation --------------------------------------
h       = 0.02;                  % 고정 스텝 [s] / fixed step
T_final = 60;                    % 길이 [s] / run length

%% ---- 이 구성에서 실제로 잰 것 / what this configuration measures -------
%  강의 본문이 인용하는 수치를 **여기서 계산해** 찍는다. 문서에 손으로 적어 둔
%  숫자가 코드와 어긋나지 않게 하려는 것이다
T_fwd = cfg.k_pos * 60^2;
T_rev = -cfg.k_neg * 60^2;
n_cxl = -sqrt(T_fwd / cfg.k_neg);
fprintf(['\n  Week 12  four tilting thrusters, open loop\n' ...
         '    thruster stations   x = [%+.2f %+.2f %+.2f %+.2f] m\n' ...
         '                        y = [%+.3f %+.3f %+.3f %+.3f] m\n' ...
         '    servo limit         %+.0f deg,  rate %.0f deg/s\n' ...
         '    shaft limits        %+.3f .. %+.3f rad/s\n' ...
         '    thrust at +-60      %+7.3f N ahead, %+7.3f N astern' ...
         '   (k_neg/k_pos = %.4f)\n' ...
         '    cancelling astern   %+8.3f rad/s, not -60\n' ...
         '    B                   %d x %d, rank %d, null space %d\n' ...
         '    command             n = [%g %g %g %g] rad/s\n' ...
         '                    delta = [%g %g %g %g] deg\n\n'], ...
        cfg.pos(1,:), cfg.pos(2,:), rad2deg(alpha_lim), rad2deg(alpha_rate), ...
        cfg.n_min, cfg.n_max, T_fwd, T_rev, cfg.k_neg/cfg.k_pos, n_cxl, ...
        size(cfg.B,1), size(cfg.B,2), rank(cfg.B), ...
        size(cfg.B,2) - rank(cfg.B), n_cmd, d_deg);
