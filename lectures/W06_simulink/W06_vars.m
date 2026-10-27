function V = W06_vars()
%W06_VARS  W06_0_setup 과 같은 값을 struct 하나로 돌려준다.
%          The same values as W06_0_setup, returned as one struct.
%
%   V = W06_vars()
%
%   절 스크립트는 이것을 받아 **한 필드만** 바꿔 돌린다. 그래야 표의 한 줄과 다른
%   줄 사이에 무엇이 달라졌는지가 코드에 그대로 보인다.
%
%       R = W06_read('W06_F_position', 'Kp_v', 300);
%
%   A section script takes this and changes ONE field, so that what differs
%   between two rows of a table is visible in the code.
%
%   W06_0_setup 과 이 파일은 같은 값을 들고 있어야 한다. 사람이 둘을 맞추지 않고
%   `verify_w06_actuation` 이 필드마다 대조한다. 다른 것이 허용되는 것은 셋뿐이고
%   (animate · pace · T_final), 그 이유는 절 스크립트가 그림을 그리지 않고 조용히
%   빨리 돌아야 하기 때문이다.
%
%   This file and W06_0_setup must agree. verify_w06_actuation compares them
%   field by field rather than trusting a person to keep them in step. Three
%   fields are allowed to differ -- animate, pace and T_final -- because a
%   section script runs quietly and fast instead of drawing.
%
%   See also W06_READ, W06_0_SETUP, VERIFY_W06_ACTUATION.

cfg = otter_config('bow_thruster');

%% ---- 선체와 추진기 / hull and thrusters
V.y_pont = cfg.y_pont;          % 0.395 m
V.l_f    = cfg.l_f;             % 1.5 m
V.k_pos  = cfg.k_pos;
V.k_neg  = cfg.k_neg;
V.n_max  = cfg.n_max;
V.n_min  = cfg.n_min;
V.B      = cfg.B;
V.Binv   = inv(cfg.B);          %#ok<MINV>
V.T_max  =  cfg.k_pos*cfg.n_max^2;    %  119.68 N
V.T_min  = -cfg.k_neg*cfg.n_min^2;    %  -66.71 N
V.F_B_max = 40;                       % 선수추진기 정격 / the bow unit's rating [N]

%% ---- 적재 · 조류 · 질량행렬 / payload, current, inertia
V.mp     = 25;
V.rp     = [0.05 0 -0.35]';
V.V_c    = 0;
V.beta_c = pi/2;
[~, V.Minv] = otter_M(V.mp, V.rp);    % 중첩이 쓰는 역행렬 / used by the superposition

%% ---- 열린 루프 명령 / the open-loop demand
V.X_cmd = 0;
V.Y_cmd = 25;
V.N_cmd = 0;

%% ---- 위치제어 / position control
V.N_d   = 20;
V.E_d   = 10;
V.psi_d_cmd = 0;

V.Kp_pos = 0.30;
V.u_lim  = 0.80;
V.v_lim  = 0.35;

V.Kp_u = 200;   V.Ki_u = 200;
V.Kp_v = 150;   V.Ki_v = 120;
V.Kb   = 1;
V.X_max = 120;
%  횡력 한계는 선수추진기의 정격이 아니라 선미의 후진 한계가 정한다 (6-2 절)
%  the sway limit comes from the stern REVERSE limit, not the bow unit's rating
V.Y_max = min(abs(V.T_min)/(V.l_f/(2*V.y_pont)), V.F_B_max);   % 35.13 N

V.Kp = 300;     V.Kd = 100;
V.N_max = 2*cfg.y_pont*min(V.T_max, -V.T_min);    % 52.70 N m

%% ---- NED 좌표에서 도는 같은 제어기 (6-7 절) / the same control, run in NED
%  축 둘이 게인 하나를 함께 쓴다. NED 의 북축은 선수각에 따라 전진일 수도 횡일
%  수도 있으므로 **느린 축(횡)** 의 값을 쓴다 / one gain pair for both axes
V.Kp_ned = 150;   V.Ki_ned = 120;
%  속도 한계도 느린 축의 것이다. 축마다 자르지 않고 **크기**로 자른다
V.v_ned_max = V.v_lim;                            % 0.35 m/s

%% ---- 접안 / berthing
V.quay_E   = 0;
V.berth_N  = 40;
V.berth_E  = 1.2;
V.stand_off = 7;
V.app_N = V.berth_N;
V.app_E = V.berth_E + V.stand_off;
V.bow_on = 0;
if V.bow_on, V.psi_berth = -pi/2; else, V.psi_berth = 0; end
V.R_app   = 1.5;
V.R_berth = 0.40;
V.psi_tol = deg2rad(5);
V.v_tol   = 0.05;
V.r_tol   = deg2rad(1.0);

%% ---- 출발점 / the start
V.x0 = zeros(12,1);
V.x0(7) = 0;
V.x0(8) = 25;

%% ---- 실시간 화면 / the live view
%  절 스크립트는 그리지 않는다. 사람이 Run 을 누를 때만 그린다 (W06_0_setup).
%  A section script does not draw; only a person pressing Run does.
V.animate       = 0;
V.animate_every = 0.5;
V.pace          = 0;
V.track_Emin = -4;   V.track_Emax = 30;
V.track_Nmin = -8;   V.track_Nmax = 52;

%% ---- 시뮬레이션 / simulation
V.h       = 0.02;
V.T_final = 120;       % 절 스크립트는 짧게 돈다 / a section script runs shorter
end
