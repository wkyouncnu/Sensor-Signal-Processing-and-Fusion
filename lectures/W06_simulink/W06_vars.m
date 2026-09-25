function V = W06_vars()
%W06_VARS  W06_0_setup 과 같은 값을 구조체로 / the values of W06_0_setup, as a struct.
%
%   절 스크립트는 W06_read 를 통해 이 값에서 몇 개만 바꿔 돌린다. 값을 고치면 두 파일을
%   함께 고친다 (verify_w06_allocation 이 대조한다).
%   Section scripts change a few of these through W06_read. Edit both files
%   together; verify_w06_allocation compares them.

cfg = otter_config('base');

%  선체와 추진기 / hull and thrusters
V.y_pont = cfg.y_pont;                 % 추진기 팔 / thruster arm            [m]
V.k_pos  = cfg.k_pos;                  % 전진 추력계수 / ahead coefficient   [N/(rad/s)^2]
V.k_neg  = cfg.k_neg;                  % 후진 추력계수 / astern coefficient
V.n_max  = cfg.n_max;                  % 회전수 한계 / shaft speed limits    [rad/s]
V.n_min  = cfg.n_min;

%  추진기 하나가 낼 수 있는 추력 / what one propeller can produce
V.T_max = cfg.k_pos * cfg.n_max^2;     %  119.68 N
V.T_min = -cfg.k_neg * cfg.n_min^2;    % -66.71 N

%  요구하는 일반화 힘 / the generalised force demanded — 절마다 시간표가 다르다
V.X_cmd = 100;     % 전진력 / surge force                 [N]
V.N_cmd = 20;      % 요 모멘트 / yaw moment               [N m]
V.Y_cmd = 30;      % 횡력 — 이 선체가 낼 수 없는 것 / sway force, which this hull cannot make  [N]
V.X_big = 220;     % 한계를 넘기는 요구 / a demand past the limits          [N]
V.N_big = 50;      %                                                        [N m]

%  배분기의 두 스위치 / the two switches of the allocator
V.fit_mode = 1;    % 1 = 비율로 줄인다 (방향 유지), 0 = 잘라 낸다 / 1 scales, 0 clips
V.use_kneg = 1;    % 1 = 후진에 k_neg 를 쓴다 (옳다), 0 = 양방향 k_pos / 1 uses k_neg astern

%  선체 / the vessel
V.mp = 25;  V.rp = [0.05 0 -0.35]';    % 적재물 / payload
V.V_c = 0;  V.beta_c = 0;              % 조류 없음 / no current
V.x0 = zeros(12,1);

V.h = 0.02;  V.T_final = 45;
end
