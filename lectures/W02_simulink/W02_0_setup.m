%% W02_0_SETUP  2주차 모델이 쓰는 모든 값을 기본 작업공간에 올린다.
%                Put every value the Week 2 model uses into the base workspace.
%
%  실행 / to run
%      W02_0_setup
%      open_system('W02_E_PID')    그리고 Run / then press Run
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 A 이다. 학생이 고치는 유일한 파일이며, 모델의 블록에는 숫자가
%      아니라 여기의 변수 이름이 들어 있다. Kp 를 명령창에서 바꾸고 Run 을 다시
%      누르면 그 값으로 돈다.
%      This is section A of Part 2 and the only file a student edits. Every
%      block in the model holds a variable name from this file rather than a
%      number, so changing Kp in the Command Window and pressing Run again runs
%      the model with the new value.
%
%  이 주차의 플랜트는 배가 아니다 / this week's plant is not a vessel
%      질량-스프링-댐퍼 하나이다. 배는 게인 하나를 바꿔도 항력·프로펠러 곡선·
%      축 사이의 얽힘이 함께 움직여서, 무엇 때문에 응답이 달라졌는지 가려낼 수
%      없다. 그래서 먼저 출렁이는 것 하나뿐인 가장 단순한 2차 시스템에서 P, I, D
%      가 각각 무엇을 하는지 본다. 3주차가 같은 제어기를 Otter 의 전진 속도에
%      옮긴다.
%
%      A single mass-spring-damper. On a vessel, changing one gain also moves
%      the drag, the propeller curve and the coupling between axes, and the
%      cause of a change in the response cannot be isolated. The effect of P,
%      I and D is therefore seen first on the simplest second-order system
%      that can oscillate. Week 3 moves the same controller onto the surge
%      speed of the Otter.
%
%          m y'' + b y' + k y = tau        G(s) = 1 / (m s^2 + b s + k)

clear; close all;
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);

%% ---- 플랜트 / the plant --------------------------------------------------
%  극은 -1 +- 1j. 제어기 없이 두어도 조금 출렁이다 멈춘다 (감쇠비 0.707).
%  Poles at -1 +- 1j: left alone it rings a little and stops (damping 0.707).
pid_m = 1;            % 질량 / mass                        [kg]
pid_b = 2;            % 감쇠 / damping                      [N s/m]
pid_k = 2;            % 스프링 / spring                     [N/m]

%% ---- PID 게인 / the PID gains -------------------------------------------
%  절 C, D, E 는 이 가운데 하나만 바꾸어 가며 돌린다. 여기의 값은 세 갈래를
%  모두 켠 기본값이다.
%  Sections C, D and E vary one of these at a time. The values here are the
%  default with all three terms switched on.
Kp = 10;              % 비례 / proportional                 [N/m]
Ki = 8;               % 적분 / integral                     [N/(m s)]
Kd = 4;               % 미분 / derivative                   [N s/m]
Nf = 20;              % 미분 필터 계수 / derivative filter    [rad/s]
Nf_blk = 20;          % 라이브러리 PID 블록의 필터 계수. 보통 Nf 와 같다 — 절 F 의 대조 실험만 바꾼다
                      % filter coefficient of the library PID block; equal to Nf except
                      % in the control run of section F
                      %   Simulink PID 블록 대화상자의 "Filter coefficient (N)"
                      %   the "Filter coefficient (N)" of the PID block dialog
d_filtered = 1;       % 1 = Nf s/(s+Nf) 로 거른 미분, 0 = 순수 미분 (손으로 만든 쪽만)
                      % 1 = filtered derivative, 0 = pure derivative (hand-built row only)

%% ---- 목표값 / the setpoint -----------------------------------------------
y_step = 1;           % 목표 위치 / target position          [m]
t_step = 1;           % 계단이 들어가는 시각 / step instant   [s]
ref_filter = 0;       % 1 이면 목표를 1차 필터로 부드럽게 / 1 smooths the setpoint
ref_Tf     = 0.3;     % 그 필터의 시상수 / its time constant  [s]
y_step2 = 0.5;        % 두 번째 목표 (W02_H_windup 만) / the second target (W02_H_windup only) [m]
t_step2 = 1e6;        % 그 시각. 1e6 은 "바뀌지 않음" / its instant; 1e6 means never  [s]

%% ---- 액추에이터 한계와 안티와인드업 / actuator limit and anti-windup ------
tau_max = 1e6;        % 힘의 한계. 1e6 은 사실상 한계가 없는 것
                      % force limit [N]; 1e6 means effectively none
Kb      = 2;          % 되감기 이득. 0 이면 안티와인드업이 없다
                      % back-calculation gain [1/s]; 0 removes anti-windup

%% ---- 센서 잡음 / sensor noise ---------------------------------------------
noise_std = 0;        % 위치 센서 잡음의 표준편차. 0 이면 잡음이 없다
                      % standard deviation of the position sensor noise; 0 = none   [m]
noise_ts  = 0.01;     % 잡음이 새 값을 뽑는 주기 (100 Hz 센서) / noise sample time  [s]

%% ---- 미분 시험대 (W02_G_derivative_bench) / the derivative bench ---------
bench_w     = 0.5;    % 사인파의 각주파수 / frequency of the sine        [rad/s]
bench_noise = 0.005;  % 사인파에 섞는 잡음의 표준편차 / noise on the sine
bench_T     = 20;     % 시험 시간 / run length                           [s]

%% ---- 플랜트 세 가지 표현 (W02_B_three_ways) / the plant three ways --------
F_step = 1;           % 질량을 미는 계단 힘 / step force on the mass       [N]
x0_pos = 0;           % 처음 위치. 0.5 로 두면 전달함수 줄만 반응하지 못한다
                      % initial position; with 0.5 only the transfer-function row misses it  [m]
x0_vel = 0;           % 처음 속도 / initial velocity                     [m/s]

%% ---- 표준 2차 시스템 (W02_B_second_order) / the standard second-order system
zeta = 0.5;           % 감쇠비. 클수록 덜 출렁인다 / damping ratio; larger rings less
wn   = 2;             % 고유진동수. 클수록 빠르다 / natural frequency; larger is faster  [rad/s]

%% ---- 시뮬레이션 / simulation -----------------------------------------------
T_final = 10;         % [s]
h       = 1e-3;       % 고정 스텝 / fixed step (ode4)          [s]

fprintf(['\n  W02_0_setup\n' ...
         '    plant    G(s) = 1/(%g s^2 + %g s + %g)\n' ...
         '    gains    Kp = %g   Ki = %g   Kd = %g   Nf = %g\n' ...
         '    step     y_d = 0 -> %g at t = %g s\n' ...
         '    limit    |tau| <= %g,  Kb = %g\n' ...
         '    noise    std %g m every %g s\n\n'], ...
        pid_m, pid_b, pid_k, Kp, Ki, Kd, Nf, y_step, t_step, tau_max, Kb, noise_std, noise_ts);
