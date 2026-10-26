%% W04_0_SETUP  4주차 모델이 쓰는 모든 값을 기본 작업공간에 올린다.
%                Put every value the Week 4 models use into the base workspace.
%
%  실행 / to run
%      W04_0_setup
%      open_system('W04_E_PD')     그리고 Run / then press Run
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 A 이다. 학생이 고치는 유일한 파일이다. 블록에는 숫자가 아니라 이
%      파일의 변수 이름이 들어 있다. Kp 를 명령창에서 바꾸고 Run 을 누르면 바로 보인다.
%      Section A of Part 2 and the only file a student edits. Changing Kp in the
%      Command Window and pressing Run shows the new response at once.
%
%  2·3주차와 같은 제어기, 출력만 선수각 / the same controller, the heading as output
%      모델 없이 Scope 를 보며 튜닝한다 (model-free tuning).
%      Tuned without a model, from what the Scope shows.

clear; close all;
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
mss_path();                                   % MSS 를 찾아 경로에 올린다 / finds MSS

%% ---- 선체와 추진기 / hull and thrusters (Week 1) ---------------------------
cfg    = otter_config('base');
k_pos  = cfg.k_pos;   k_neg = cfg.k_neg;      % 추력 계수, 프로펠러 하나 / thrust coefficient, one propeller
y_pont = cfg.y_pont;                          % 프로펠러의 팔 길이 / each propeller's moment arm  [m]
T_hi   =  k_pos*cfg.n_max^2;                  % 프로펠러 하나의 최대 전진 추력 / largest forward thrust, one  [N]
T_lo   = -k_neg*cfg.n_min^2;                  % 최대 후진 추력 / largest backward thrust, one  [N]
mp = 25;   rp = [0.05 0 -0.35]';              % 탑재물 / payload
V_c = 0;   beta_c = 0;                        % 조류 없음 / no current
x0 = zeros(12,1);                             % 정지, 선수각 0 / at rest, heading 0

%% ---- 전진력과 요 모멘트의 한계 / surge force and the yaw-moment limit -----
X_ff  = 60;           % 두 프로펠러가 함께 내는 전진력 / surge force from both propellers  [N]
N_max = min(2*y_pont*(T_hi - X_ff/2), 2*y_pont*(X_ff/2 - T_lo));
                      % X_ff 를 내면서 낼 수 있는 가장 큰 요 모멘트 / the largest yaw moment
                      % available while X_ff is delivered  [N m]
port_eff = 1;         % 좌현 프로펠러 효율. 0.7 이면 30 % 약하다 (절 F)
                      % port propeller efficiency; 0.7 = 30 % weak (section F)

%% ---- 열린 루프 시험 (W04_C_open_loop) / the open-loop test ----------------
N_open = 10;          % 계단으로 가하는 요 모멘트 / step yaw moment  [N m]

%% ---- 목표 선수각 / the heading command (도 / degrees) ---------------------
psi_step  = 10;       % 목표 선수각 / commanded heading          [deg]
t_step    = 5;        % 계단 시각 / step instant                 [s]
psi_step2 = 10;       % 두 번째 목표 / the second command          [deg]
t_step2   = 1e6;      % 그 시각. 1e6 은 "바뀌지 않음" / its instant; 1e6 means never  [s]
use_ssa   = 1;        % 1 이면 오차를 (-180, 180] 로 감는다 / 1 wraps the error into (-180, 180]

%% ---- PID 게인 / the PID gains (오차는 rad / the error is in rad) -----------
Kp = 300;             % 비례 / proportional     [N m per rad]
Ki = 20;              % 적분 / integral         [N m per rad s]
Kd = 100;             % 미분 / derivative       [N m s per rad]
Nf = 20;              % 미분 필터 / derivative filter  [rad/s]
Kb = 0.1;             % 되감기 이득. 0 이면 안티와인드업 없음 / back-calculation gain; 0 = none  [1/s]

%% ---- D 항을 어디서 얻는가 / where the D term comes from (§4-3 의 소절) ----
%   1  -Kd r                 회두율 되먹임. 자이로가 직접 내는 값이고, MSS 의
%                            기본형이며 (SIMclarke83 · SIMremus100 · SIMrig),
%                            5~10주차가 그대로 가져다 쓴다
%   2  +Kd Nf s/(s+Nf) e     오차를 미분. W04_E_PD 와 2·3주차가 쓰는 교과서 형태
%   3  +Kd r                 부호만 뒤집은 것. 제동이 가속이 된다
%   1 and 2 are the same term while psi_d is not moving; 3 is what happens when
%   the sign of a damping term is wrong.
d_form = 1;

%% ---- 두 루프를 함께 (W04_J_both) / both loops at once ---------------------
%   4-8 절. 선수각 루프는 위의 Kp·Kd 그대로, 속도 루프는 3주차의 PI 그대로다.
%   명령은 둘 다 **계단으로 조금씩 바뀐다** — 한 번의 계단 응답이 아니라 명령을
%   따라가는 모습을 보려는 것이다.
%   Section 4-8. The heading loop keeps the gains above and the speed loop is the
%   PI of Week 3. Both commands move in small steps, so what is seen is tracking
%   rather than one step response.
u_d_steps   = [0.8 1.2 1.0 1.4];   % 목표 속도의 계단 / the speed command   [m/s]
psi_d_steps = [0 20 -15 90];       % 목표 선수각의 계단 / the heading command [deg]
cmd_hold    = 30;                  % 한 계단이 유지되는 시간 / how long each step is held [s]

Kp_u  = 200;          % 속도 루프 비례 / surge proportional   [N per m/s]
Ki_u  = 200;          % 속도 루프 적분 / surge integral       [N per m]
Kb_u  = 1;            % 속도 루프 되감기. 위의 Kb 는 선수각 적분기의 것이다
                      % the speed loop's back-calculation gain; Kb above is the heading one
X_max = 120;          % 전진력의 한계 / the surge force limit  [N]
n_max = cfg.n_max;    % 축 회전수의 한계 / the shaft-speed limits  [rad/s]
n_min = cfg.n_min;    %   배분기가 여기서 자른다 (otter.m 도 안에서 자른다)
                      %   where the allocator clamps; otter.m clamps internally too

%   전진력이 X_max 까지 갈 수 있으므로 요 모멘트의 한계를 **그 힘에서** 다시 계산한다
%   (5-7 절의 규칙). X_ff 에서 계산한 N_max 를 그대로 쓰면 낼 수 없는 모멘트를 요구한다.
%   The surge force can reach X_max, so the moment limit is recomputed there, as
%   section 5-7 requires: N_max, worked out at X_ff, would ask for the impossible.
N_speed = min(2*y_pont*(T_hi - X_max/2), 2*y_pont*(X_max/2 - T_lo));

%% ---- 시뮬레이션 / simulation -----------------------------------------------
T_final = 40;         % [s]
T_both  = cmd_hold * numel(u_d_steps);   % 4-8 절의 길이 / the length of section 4-8  [s]
h       = 0.02;       % 고정 스텝 / fixed step (ode4)  [s]

fprintf(['\n  W04_0_setup\n' ...
         '    thrust   X_ff = %g N forward, yaw moment |N| <= %.2f N m\n' ...
         '    gains    Kp = %g   Ki = %g   Kd = %g   Nf = %g   Kb = %g\n' ...
         '    command  psi_d = 0 -> %g deg at t = %g s\n' ...
         '    both     W04_J_both: u_d %s m/s and psi_d %s deg, %g s each, |N| <= %.2f N m\n\n'], ...
        X_ff, N_max, Kp, Ki, Kd, Nf, Kb, psi_step, t_step, ...
        mat2str(u_d_steps), mat2str(psi_d_steps), cmd_hold, N_speed);
