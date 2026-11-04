function [xdot,U] = otter_tilt4(x,n,delta,mp,rp,V_c,beta_c,quad)
%OTTER_TILT4  Otter USV with four tilting thrusters: four shaft speeds and
%             four tilt angles in.
%
%   [xdot,U] = otter_tilt4(x,n,delta,mp,rp,V_c,beta_c)
%   [xdot,U] = otter_tilt4(x,n,delta,mp,rp,V_c,beta_c,quad)
%
%   MSS 의 VESSELS/otter.m 을 **그대로 복사**한 뒤 네 군데만 고친 것이다.
%   `otter_bow.m` 과 **같은 방식**이다 — 고치는 자리도 같은 네 곳이다.
%   A verbatim copy of MSS VESSELS/otter.m with four changes, each marked
%   below with  % ---- CHANGED (i of 4), in the same four places as otter_bow.m.
%
%     1  입력 검사    n 과 delta 가 각각 **네 개**다
%     2  추진기 자료  네 자리의 (x,y) 와 각 추진기의 틸팅 한계
%     3  추력 루프    2 회가 아니라 4 회, 그리고 각도도 함께 포화된다
%     4  tau          1·2·6 행이 **모두** 각도를 쓴다
%
%   그 밖의 모든 줄 — MRB · CRB · 부가질량 · 복원력 · 감쇠 · crossFlowDrag ·
%   운동학 — 은 **한 글자도 다르지 않다.** 선체가 같다는 것이 이 강의의 전제이고,
%   달라진 것은 추진기뿐이라는 것을 코드가 그대로 보여야 하기 때문이다.
%   Everything else is character-for-character identical. The hull is the same
%   hull; only the actuation changed, and the file must show that.
%
%   왜 복사인가 / why a copy
%     otter.m 은 축 회전수를 **둘** 만 받고 그 tau(2) 는 항등적으로 0 이다. 횡력을
%     호출 **바깥**에서 M\tau_ext 로 더하는 것은 가속도가 tau 에 대해 아핀이므로
%     정확하지만, 운동모델 자체는 여전히 "횡력을 못 내는 배" 였다. 이 파일은
%     **운동모델 안에서** 네 추진기의 힘을 모아 tau 를 만든다 — 6주차가
%     `otter_bow.m` 으로 간 길과 같다.
%     otter.m takes TWO shaft speeds and its tau(2) is identically zero.
%     Superposing a lateral force outside the call is exact, because the
%     acceleration is affine in tau, but the motion model would still describe a
%     vessel that cannot push sideways. Here the four thrusters are summed
%     INSIDE the model, as Week 6 did with otter_bow.m.
%
%   INPUTS
%     x       12 x 1  [u v w p q r x y z phi theta psi]'
%     n        4 x 1  축 회전수 / shaft speeds (rad/s), **not rpm**
%     delta    4 x 1  틸팅 각 / tilt angles (rad)
%
%             번호는 otter_config('quad_tilt') 의 cfg.pos 열 순서다.
%             The numbering is the column order of cfg.pos:
%               1  선수 좌현 / fore port        ( +1.5, -0.395)
%               2  선수 우현 / fore starboard   ( +1.5, +0.395)
%               3  선미 좌현 / aft port         ( -1.0, -0.395)
%               4  선미 우현 / aft starboard    ( -1.0, +0.395)
%
%     mp      적재 질량 / payload mass (kg), maximum 45 kg
%     rp      적재 위치 / payload position [xp yp zp]' (m) w.r.t. the CO
%     V_c     조류 속도 / current speed (m/s)
%     beta_c  조류 방향 / current direction (rad)
%     quad    3 x 4  추진기 제원. 생략하면 이 강의의 값을 쓴다.
%             1 행 x 위치 (m) · 2 행 y 위치 (m) · 3 행 틸팅 한계 (rad)
%             the thruster data: x station, y station and tilt limit per unit.
%             Defaults to this course's values, the same numbers that
%             otter_config('quad_tilt') carries.
%
%   각도의 정의 — 쌍마다 0 도가 다르다 / what the angle means
%     선수 둘(1·2)은 **앞**을 보고, 선미 둘(3·4)은 **뒤**를 보고 달려 있다.
%     그래서 서보 0 도의 뜻이 쌍마다 다르다.
%     Units 1 and 2 are mounted facing forward and units 3 and 4 facing aft, so
%     servo zero means a different direction for each pair.
%
%       unit  station            delta = 0 pushes   delta = +90 deg pushes
%       1·2   x = +l_f           +x_b (ahead)       +y_b (to starboard)
%       3·4   x = -l_a           -x_b (astern)      -y_b (to port)
%
%     즉 미는 방향은 e_i = s_i [cos delta_i ; sin delta_i] 이고
%     s = [+1 +1 -1 -1] 이 그 거치 부호다. 두 쌍의 0 도가 모두 **배 가운데에서
%     바깥**을 보므로, 네 각을 같게 주면 힘이 아니라 **모멘트**가 남는다.
%     So the pushed direction is e_i = s_i [cos delta_i ; sin delta_i] with the
%     mounting sign s = [+1 +1 -1 -1]. Both zeros point outward from amidships,
%     so four equal angles leave a moment rather than a force.
%
%   행렬 형태 / matrix form
%     각 추진기의 추력을 극형식이 아니라 직교 성분으로 쓰면 tau 가 delta 에
%     대해 **선형**이 된다 (Fossen 2011 §12.3.4, extended thrust vector).
%     Writing each thrust in Cartesian components rather than polar form makes
%     tau linear in the commands:
%
%       f = [ T_1 cos d_1 ; T_1 sin d_1 ; ... ; T_4 cos d_4 ; T_4 sin d_4 ]
%       tau_3 = B_thr f,   B_thr written out below with its arms named,   3 x 8
%
%     이 파일 안에서는 그 행렬을 **B_thr** 이라 부른다. otter.m 의 `B` 는 이미
%     **선폭** 1.08 m 이고, 그 줄을 고치지 않는 것이 이 복사본의 규칙이다.
%     Inside this file the matrix is called B_thr: `B` is already the beam,
%     1.08 m, and no line of otter.m is renamed.
%
%     B 는 3주차의 열 규칙 하나에서 나온다. (x,y) 에서 단위벡터 e 로 미는
%     추진기는 [e_x ; e_y ; x e_y - y e_x] 을 내므로, 틸팅 추진기 하나는
%     e = s_i (1,0) 과 e = s_i (0,1) 두 열을 기여한다.
%     B comes from the Week 3 column rule: a thruster at (x,y) pushing along the
%     unit vector e contributes [e_x; e_y; x e_y - y e_x], so one tilting unit
%     contributes the two columns e = s_i (1,0) and e = s_i (0,1).
%
%       B = [  1   0   1   0  -1   0  -1   0
%              0   1   0   1   0  -1   0  -1
%              d  l_f -d  l_f -d  l_a  d  l_a ]       d = y_pont
%
%     루프를 돌며 더하던 것과 **수치가 같다** — 같은 합을 행렬곱으로 쓴 것이다.
%     verify_otter_tilt4 가 둘을 대조한다.
%     This is numerically identical to accumulating the same sum in a loop;
%     verify_otter_tilt4 compares the two.
%
%   후진 추력이 더 약하다 / reverse thrust is weaker
%     k_neg < k_pos 이므로 같은 크기의 회전수를 앞뒤로 주어도 추력은 상쇄되지
%     않는다. +60 rad/s 가 39.888 N 을 내는 동안 -60 rad/s 는 -23.202 N 밖에
%     내지 못한다. 네 추진기를 대칭으로 지시하면 전진력이 남는다 — 이것이
%     개루프 검증에서 가장 먼저 보이는 것이다.
%     Since k_neg < k_pos, equal and opposite shaft speeds do not cancel:
%     +60 rad/s gives 39.888 N while -60 rad/s gives only -23.202 N.
%
%   검증 / verification
%     verify_otter_tilt4 가 다음을 잰다.
%       (a) delta = 0 이고 n(1:2) = 0 이면 otter(x,n(3:4),...) 와 같은가 —
%           선미 두 추진기만 살아 있을 때 1~5 주차의 Otter 로 돌아가는가
%       (b) tau 가 열 규칙으로 손으로 센 값과 같은가 (차원 · 극한 · 부호)
%       (c) 포화가 회전수와 각도 양쪽에 제대로 걸리는가
%     Run verify_otter_tilt4 for all three.
%
%   See also OTTER, OTTER_BOW, OTTER_CONFIG, OTTER_B, OTTER_M,
%            VERIFY_OTTER_TILT4.
%
%   Hull author:  Thor I. Fossen (MSS, otter.m, 2019-07-17)
%   This file:    2026 센서신호처리 및 융합 — 추진기 부분만 고쳤다

% ---- CHANGED (1 of 4) ---------------------------------------------------
% Check of input and state dimensions
if (length(x) ~= 12),error('x vector must have dimension 12!'); end
if (length(n) ~= 4),error('n vector must have dimension 4!'); end
if (length(delta) ~= 4),error('delta vector must have dimension 4!'); end
if nargin < 8 || isempty(quad)
    quad = [ 1.5   1.5  -1.0  -1.0              % x 위치 / x stations (m)
            -0.395 0.395 -0.395 0.395           % y 위치 / y stations (m)
             pi/4  pi/4  pi/4  pi/4              % 틸팅 한계 / tilt limits (rad)
              1     1    -1    -1 ];            % 거치 부호 / mounting signs
end
% -------------------------------------------------------------------------

% trim: theta = -7.5 deg corresponds to 13.5 cm less height aft maximum load
trim_setpoint = 280;

% trim_setpoint is a step input, which is filtered using the state trim_moment
trim_moment = 0;

% Main data
g   = 9.81;         % acceleration of gravity (m/s^2)
rho = 1025;         % density of water
L = 2.0;            % length (m)
B = 1.08;           % beam (m)
m = 55.0;           % mass (kg)
rg = [0.2 0 -0.2]'; % CG for hull only (m)
R44 = 0.4 * B;      % radii of gyrations (m)
R55 = 0.25 * L;
R66 = 0.25 * L;
T_yaw = 1;          % time constant in yaw (s)
Umax = 6 * 0.5144;  % max forward speed (m/s)

% Data for one pontoon
B_pont  = 0.25;     % beam of one pontoon (m)
y_pont  = 0.395;    % distance from centerline to waterline area center (m)
Cw_pont = 0.75;     % waterline area coefficient (-)
Cb_pont = 0.4;      % block coefficient, computed from m = 55 kg

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% State and current variables
nu = x(1:6);  nu1 = x(1:3); nu2 = x(4:6);   % velocities
eta = x(7:12);                              % positions
U = sqrt(nu(1)^2 + nu(2)^2 + nu(3)^2);      % speed
u_c = V_c * cos(beta_c - eta(6));           % current surge velocity
v_c = V_c * sin(beta_c - eta(6));           % current sway velocity
nu_r = nu - [u_c v_c 0 0 0 0]';             % relative velocity vector

% Inertia dyadic, volume displacement and draft
nabla = (m+mp)/rho;                         % volume
T = nabla / (2 * Cb_pont * B_pont*L);       % draft
Ig_CG = m * diag([R44^2, R55^2, R66^2]);    % only hull in CG
rg = (m*rg + mp*rp)/(m+mp);           % CG location corrected for payload
Ig = Ig_CG - m * Smtrx(rg)^2 - mp * Smtrx(rp)^2;  % hull + payload in CO

% Experimental propeller data including lever arms
l1 = -y_pont;                           % lever arm, left propeller (m)
l2 = y_pont;                            % lever arm, right propeller (m)
k_pos = 0.02216/2;                      % Positive Bollard, one propeller
k_neg = 0.01289/2;                      % Negative Bollard, one propeller
n_max =  sqrt((0.5*24.4 * g)/k_pos);    % maximum propeller rev. (rad/s)
n_min = -sqrt((0.5*13.6 * g)/k_neg);    % minimum propeller rev. (rad/s)

% ---- CHANGED (2 of 4) ---------------------------------------------------
% 네 추진기의 자리와 틸팅 한계. 프로펠러는 **otter.m 과 같은 프로펠러**이므로
% k_pos · k_neg · n_max · n_min 을 그대로 쓴다 — 위에서 이미 정한 값이다.
% 달라진 것은 (ⅰ) 둘이 아니라 넷이라는 것과 (ⅱ) 미는 방향을 돌릴 수 있다는 것
% 둘뿐이다. l1 · l2 는 더 쓰지 않는다. 자리가 네 곳이므로 (x,y) 를 직접 쓴다.
% The four stations and tilt limits. The propellers are the SAME propellers as
% otter.m, so k_pos, k_neg, n_max and n_min above are used unchanged. Only two
% things differ: there are four of them, and each can be turned. l1 and l2 are
% no longer used; with four stations the (x,y) pairs are written out.
px     = quad(1,:);                     % x stations (m)
py     = quad(2,:);                     % y stations (m)
d_max  = quad(3,:);                     % tilt limits, both ways (rad)
s      = quad(4,:);                     % mounting signs, +1 forward, -1 aft

% 3 행의 여섯 칸은 전부 **모멘트 팔**이다. 열 규칙(3주차)에 자리와 거치 부호를
% 넣으면 cos 열은 -s_i y_i, sin 열은 s_i x_i 이므로, 길이에 이름을 붙여 둔다.
% Row 3 is nothing but moment arms. Putting the station and the mounting sign
% into the Week 3 column rule gives -s_i y_i for a cos column and s_i x_i for a
% sin column, so each of those lengths is given a name here.
l_f = s(1)*px(1);                       % +1.500 m  forward pair, along the hull
l_a = s(3)*px(3);                       % +1.000 m  aft pair  (s = -1, x = -1 m)
d1  = -s(1)*py(1);                      % +0.395 m  unit 1, across the beam
d2  = -s(2)*py(2);                      % -0.395 m  unit 2, the other side
d3  = -s(3)*py(3);                      % -0.395 m  unit 3
d4  = -s(4)*py(4);                      % +0.395 m  unit 4

% 유효행렬을 **여기서** 쓴다 — 강의 §12-1 의 행렬 그대로다. 이름이 B_thr 인
% 것은 otter.m 의 B 가 이미 **선폭**이라서다 — 그 줄은 고치지 않는다.
% 1·2 행은 거치 부호만, 3 행은 위에서 이름 붙인 팔만 들고 있다.
% The effectiveness matrix, written out here exactly as the matrix of 12-1. It
% is named B_thr because B is already the beam in otter.m, and that line is not
% touched. Rows 1 and 2 hold only the mounting sign; row 3 holds only the arms
% named above.
B_thr = [ s(1)   0    s(2)   0    s(3)   0    s(4)   0
           0    s(1)   0    s(2)   0    s(3)   0    s(4)
          d1    l_f   d2    l_f   d3    l_a   d4    l_a ];
% -------------------------------------------------------------------------

% MRB and CRB (Fossen 2021)
I3 = eye(3);
O3 = zeros(3,3);

MRB_CG = [ (m+mp) * I3  O3
           O3           Ig ];
CRB_CG = [ (m+mp) * Smtrx(nu2)         O3
           O3               -Smtrx(Ig*nu2)  ];

H = Hmtrx(rg);              % Transform MRB and CRB from the CG to the CO
MRB = H' * MRB_CG * H;
CRB = H' * CRB_CG * H;

% Hydrodynamic added mass (best practise)
Xudot = -0.1 * m;
Yvdot = -1.5 * m;
Zwdot = -1.0 * m;
Kpdot = -0.2 * Ig(1,1);
Mqdot = -0.8 * Ig(2,2);
Nrdot = -1.7 * Ig(3,3);

MA = -diag([Xudot, Yvdot, Zwdot, Kpdot, Mqdot, Nrdot]);
CA  = m2c(MA, nu_r);
CA(6,1) = 0; % Assume that the Munk moment in yaw can be neglected
CA(6,2) = 0; % These terms, if nonzero, must be balanced by adding nonlinear damping

% System mass and Coriolis-centripetal matrices
M = MRB + MA;
C = CRB + CA;

% Hydrostatic quantities (Fossen 2021)
Aw_pont = Cw_pont * L * B_pont;    % waterline area, one pontoon
I_T = 2 * (1/12)*L*B_pont^3 * (6*Cw_pont^3/((1+Cw_pont)*(1+2*Cw_pont)))...
    + 2 * Aw_pont * y_pont^2;
I_L = 0.8 * 2 * (1/12) * B_pont * L^3;
KB = (1/3)*(5*T/2 - 0.5*nabla/(L*B_pont) );
BM_T = I_T/nabla;       % BM values
BM_L = I_L/nabla;
KM_T = KB + BM_T;       % KM values
KM_L = KB + BM_L;
KG = T - rg(3);
GM_T = KM_T - KG;       % GM values
GM_L = KM_L - KG;

G33 = rho * g * (2 * Aw_pont);      % spring stiffness
G44 = rho * g *nabla * GM_T;
G55 = rho * g *nabla * GM_L;

G_CF = diag([0 0 G33 G44 G55 0]);   % spring stiffness matrix in the CF
LCF = -0.2;
H = Hmtrx([LCF 0 0]);               % transform G_CF from the CF to the CO
G = H' * G_CF * H;

% Natural frequencies
w3 = sqrt( G33/M(3,3) );
w4 = sqrt( G44/M(4,4) );
w5 = sqrt( G55/M(5,5) );

% Linear damping terms (hydrodynamic derivatives)
Xu = -24.4 * g / Umax;           % specified using the maximum speed
Yv = 0;
Zw = -2 * 0.3 *w3 * M(3,3);      % specified using relative damping factors
Kp = -2 * 0.2 *w4 * M(4,4);
Mq = -2 * 0.4 *w5 * M(5,5);
Nr = -M(6,6) / T_yaw;            % specified using the time constant in T_yaw

% ---- CHANGED (3 of 4) ---------------------------------------------------
% Control forces and moments - with propeller revolution saturation
% 지시가 둘이 되었고, **각도도 함께 포화된다.** 서보가 ±45 도까지만 돌아가므로
% 그보다 큰 각을 지시해도 모델은 ±45 도로 받는다. 회전수의 한계는 otter.m 과
% 같은 값이다 — 같은 프로펠러이기 때문이다. 네 단위를 한 줄에서 한꺼번에
% 자르고, 어느 것이 벽인지가 그 줄에 그대로 쓰여 있다.
% There are two commands now, and the ANGLE saturates too: the servo turns only
% to +-45 deg, so a larger command is received as +-45 deg. The shaft-speed
% limits are the same values as otter.m, because they are the same propellers.
% All four units are clipped in one line each, with the wall named on the line.
n     = min(max(n(:),      n_min),      n_max);        % shaft speed (rad/s)
delta = min(max(delta(:), -d_max(:)),   d_max(:));     % tilt servo  (rad)

% 추력은 n|n| 이고, 계수가 전진과 후진에서 다르다 — 부호가 계수를 고른다.
% The thrust is k n|n|, and k differs ahead and astern, so the sign of n picks
% which coefficient applies.
k_thr  = k_pos * (n > 0) + k_neg * (n <= 0);
Thrust = k_thr .* n .* abs(n);          % 4 x 1, N
% -------------------------------------------------------------------------

% ---- CHANGED (4 of 4) ---------------------------------------------------
% Control forces and moments — written as a matrix product
% otter.m:  tau = [T1+T2  0  0 0 0  -l1*T1 - l2*T2]'      <- sway is zero
% here:     tau_3 = B f.  Each tilting thruster contributes TWO columns of B
%           and two entries of f, so the 3-by-8 B is constant and the whole
%           dependence on the commands sits in f.
%
%     f = [ T_1 cos d_1 ; T_1 sin d_1 ; ... ; T_4 cos d_4 ; T_4 sin d_4 ]
%
% 쌍마다 0 도가 다른 것은 B_thr 안에 있다 — 위에서 거치 부호 s = [1 1 -1 -1]
% 을 열에 실어 두었다. 그래서 여기에는 부호가 하나도 없다. 한 줄이 한 열에
% 대응하므로, 어느 줄이 어느 열과 곱해지는지 세지 않고 읽을 수 있다.
% The per-pair zero lives inside B_thr: the mounting sign s = [1 1 -1 -1] was
% carried into its columns above, so no sign appears here. One line per column,
% so which entry meets which column is read off rather than counted.
f = [ Thrust(1)*cos(delta(1))
      Thrust(1)*sin(delta(1))
      Thrust(2)*cos(delta(2))
      Thrust(2)*sin(delta(2))
      Thrust(3)*cos(delta(3))
      Thrust(3)*sin(delta(3))
      Thrust(4)*cos(delta(4))
      Thrust(4)*sin(delta(4)) ];

tau3 = B_thr * f;                       % [X ; Y ; N]

tau = [tau3(1)
       tau3(2)
       0
       0
       0
       tau3(3)];
% -------------------------------------------------------------------------

% Linear damping using relative velocities + nonlinear yaw damping
Xh = Xu * nu_r(1);
Yh = Yv * nu_r(2);
Zh = Zw * nu_r(3);
Kh = Kp * nu_r(4);
Mh = Mq * nu_r(5);
Nh = Nr * (1 + 10 * abs(nu_r(6))) * nu_r(6);

tau_damp = [Xh Yh Zh Kh Mh Nh]';

% Strip theory: cross-flow drag integrals for Yh and Nh
tau_crossflow = crossFlowDrag(L,B_pont,T,nu_r);

% Ballast
g_0 = [0 0 0 0 trim_moment 0]';

% Kinematics
J = eulerang(eta(4),eta(5),eta(6));

% Time derivative of the state vector - numerical integration; see ExOtter.m
xdot = [ M \ ( tau + tau_damp + tau_crossflow - C * nu_r - G * eta - g_0)
         J * nu ];

trim_moment = trim_moment + 0.05 * (trim_setpoint - trim_moment);

end
