function [xdot,U] = otter_bow(x,n,mp,rp,V_c,beta_c,bow)
%OTTER_BOW  Otter USV with a bow tunnel thruster, three shaft speeds in.
%
%   [xdot,U] = otter_bow(x,n,mp,rp,V_c,beta_c)
%   [xdot,U] = otter_bow(x,n,mp,rp,V_c,beta_c,bow)
%
%   MSS 의 VESSELS/otter.m 을 **그대로 복사**한 뒤 네 군데만 고친 것이다.
%   A verbatim copy of MSS VESSELS/otter.m with four changes, each marked
%   below with  % ---- CHANGED (i of 4).
%
%     1  입력 검사    n 은 두 개가 아니라 **세 개**다
%     2  추진기 자료  선수추진기의 팔 l3 · 계수 k3 · 회전수 한계 n3_max
%     3  추력 루프    2 회가 아니라 3 회
%     4  tau          2 행(sway)이 더 이상 0 이 아니고, 6 행에 l3*T3 이 붙는다
%
%   그 밖의 모든 줄 — MRB · CRB · 부가질량 · 복원력 · 감쇠 · crossFlowDrag ·
%   운동학 — 은 **한 글자도 다르지 않다.** 선체가 같다는 것이 이 강의의 전제이고,
%   달라진 것은 추진기뿐이라는 것을 코드가 그대로 보여야 하기 때문이다.
%   Everything else is character-for-character identical. The hull is the same
%   hull; only the actuation changed, and the file must show that.
%
%   왜 복사인가 / why a copy
%     otter.m 은 축 회전수를 **둘** 만 받고 그 tau(2) 는 항등적으로 0 이다. 그래서
%     6주차는 지금까지 선수추진기의 힘을 호출 **바깥**에서 M\tau_ext 로 더했다.
%     가속도가 tau 에 대해 아핀이므로 그 중첩은 정확하지만, 운동모델 자체는
%     여전히 "횡력을 못 내는 배" 였다. 이 파일은 **운동모델 안에서** 세 추진기의
%     힘을 모아 tau 를 만든다 — 2025년 강의 PPT 125~135 쪽이 요구하는 모양이다.
%     otter.m takes TWO shaft speeds and its tau(2) is identically zero, so the
%     bow force used to be superposed outside the call. Exact, but the motion
%     model itself still described a vessel that cannot push sideways. Here the
%     three thrusters are summed INSIDE the model.
%
%   INPUTS
%     x       12 x 1  [u v w p q r x y z phi theta psi]'
%     n        3 x 1  축 회전수 / shaft speeds (rad/s)
%                       n(1)  좌현 선미 프로펠러 / port stern propeller
%                       n(2)  우현 선미 프로펠러 / starboard stern propeller
%                       n(3)  선수 터널 추진기, 양수면 우현으로 민다
%                             bow tunnel thruster, positive pushes to starboard
%     mp      적재 질량 / payload mass (kg), maximum 45 kg
%     rp      적재 위치 / payload position [xp yp zp]' (m) w.r.t. the CO
%     V_c     조류 속도 / current speed (m/s)
%     beta_c  조류 방향 / current direction (rad)
%     bow     [l3 k3 n3_max] 선수추진기 제원. 생략하면 이 강의의 값을 쓴다.
%             the bow unit: arm (m), thrust coefficient (N/(rad/s)^2) and
%             shaft-speed limit (rad/s). Defaults to this course's values.
%
%   부호 / signs
%     열 규칙(3주차) 하나에서 나온다. (x,y) 에서 단위벡터 e 로 미는 추진기는
%     [e_x ; e_y ; x*e_y - y*e_x] 을 낸다. 선수추진기는 (l3, 0) 에서 +y 로 미므로
%     [0 ; 1 ; l3] 이고, 선미 한 쌍은 otter.m 의 -l1*T1 - l2*T2 와 같다.
%     From the column rule of Week 3. A thruster at (x,y) pushing along the
%     unit vector e contributes [e_x; e_y; x*e_y - y*e_x].
%
%     2025년 강의 PPT 128 쪽은 T 의 셋째 행을 [l1 -l2 l3] 로, 그 아래에
%     l1 = -l2 = -Y_pont 로 적었다. 둘을 함께 넣으면 tau_N = -y_pont*T1 -
%     y_pont*T2 + l3*T3 이 되어 선미 두 프로펠러가 **같은 쪽으로** 배를 돌린다.
%     같은 PPT 135 쪽의 MATLAB 코드는 -l1*T1 - l2*T2 로 올바르며, otter.m 과
%     열 규칙도 그와 같다. 코드가 맞고 행렬이 틀렸다 — 여기서는 코드를 따른다.
%     Slide 128 writes the third row of T as [l1 -l2 l3] with l1 = -l2 = -Y_pont,
%     which would turn both stern propellers the same way. The MATLAB code on
%     slide 135 is correct and agrees with otter.m and with the column rule.
%
%   검증 / verification
%     verify_otter_bow 가 두 가지를 잰다.
%       (a) n(3) = 0 이면 otter(x,n(1:2),...) 와 반올림오차까지 같다
%       (b) n(3) ~= 0 이면 옛 중첩 xdot + Minv*[0;T3;0;0;0;l3*T3] 과 같다
%     Run verify_otter_bow for both equalities.
%
%   See also OTTER, OTTER_CONFIG, OTTER_B, OTTER_M, VERIFY_OTTER_BOW.
%
%   Hull author:  Thor I. Fossen (MSS, otter.m, 2019-07-17)
%   This file:    2026 센서신호처리 및 융합 — 추진기 부분만 고쳤다

% ---- CHANGED (1 of 4) ---------------------------------------------------
% Check of input and state dimensions
if (length(x) ~= 12),error('x vector must have dimension 12!'); end
if (length(n) ~= 3),error('n vector must have dimension 3!'); end
if nargin < 7 || isempty(bow)
    bow = [1.5, 0.02216/2, sqrt(40/(0.02216/2))];   % 이 강의의 선수추진기
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
% 선수 터널 추진기. 팔은 CO 에서 앞으로 l3, 미는 방향은 +y(우현)다. 터널
% 추진기는 **양쪽으로 같은 추력**을 내므로 선미 프로펠러의 전진·후진 비대칭
% (k_pos 대 k_neg) 이 여기에는 없다 — 계수도 한계도 하나씩이다.
% The bow tunnel thruster, l3 forward of the CO, pushing along +y. A tunnel
% thruster is symmetric, so the k_pos/k_neg asymmetry of the stern propellers
% does not appear: one coefficient, one limit.
l3     = bow(1);                        % lever arm, bow thruster (m)
k3     = bow(2);                        % thrust coefficient, both ways
n3_max = bow(3);                        % shaft-speed limit, both ways (rad/s)
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
% 루프가 2 회에서 3 회로 늘고, 셋째 추진기만 제 계수와 제 한계를 쓴다.
% The loop runs three times; the third unit uses its own coefficient and limit.
Thrust = zeros(3,1);
for i = 1:1:3
    if i < 3                                % 선미 프로펠러 / stern propellers
        if n(i) > n_max                     % saturation, physical limits
            n(i) = n_max;
        elseif n(i) < n_min
            n(i) = n_min;
        end

        if n(i) > 0
            Thrust(i) = k_pos * n(i)*abs(n(i));   % positive thrust (N)
        else
            Thrust(i) = k_neg * n(i)*abs(n(i));   % negative thrust (N)
        end
    else                                    % 선수추진기 / the bow thruster
        if n(i) > n3_max
            n(i) = n3_max;
        elseif n(i) < -n3_max
            n(i) = -n3_max;
        end

        Thrust(i) = k3 * n(i)*abs(n(i));          % symmetric, both ways (N)
    end
end
% -------------------------------------------------------------------------

% ---- CHANGED (4 of 4) ---------------------------------------------------
% Control forces and moments
% otter.m:  tau = [T1+T2  0  0 0 0  -l1*T1 - l2*T2]'      <- sway is zero
% here:     the bow thrust enters row 2, and its moment l3*T3 enters row 6.
tau = [Thrust(1) + Thrust(2)
       Thrust(3)
       0
       0
       0
       -l1 * Thrust(1) - l2 * Thrust(2) + l3 * Thrust(3)];
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
