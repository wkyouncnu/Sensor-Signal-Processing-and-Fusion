function R = verify_w01_theory()
%VERIFY_W01_THEORY  W01 §1-5 · §1-11 · §1-12 에 실린 수를 otter.m 과 MSS 에서 다시 잰다.
%
%   verify_w01_theory          표를 찍는다
%   R = verify_w01_theory      같은 수를 구조체로도 돌려준다
%
%   그림은 만들지 않는다. 쿼터니언 절은 설명과 MSS 코드만 싣기로 했다 (2026-09-11).
%
%   왜 있는가
%     강의의 모든 수는 러너 출력까지 추적할 수 있어야 한다 (CLAUDE.md §4-8,
%     standing-orders.md §7-3). §1-11 에 실려 있던 "63.2 % 시각 1.1064 s" 는
%     어떤 러너도 찍지 않던 수였고, 다시 재 보니 1.1057 s 였다. §1-12 의 sway
%     Coriolis 계수는 (m - X_udot) 로 적혀 있었는데 otter.m 은 M11 = 85.50 kg 을
%     쓴다. 이 함수가 그 두 수와 쿼터니언 절의 수를 전부 다시 만든다.
%     MSS 가 바뀌면 verify_constants 와 함께 이것부터 다시 돌린다.
%
%   무엇을 보는가
%     A  otter.m (2021 판) 98-126 행을 그대로 다시 세워 M 을 읽고,
%        C(nu)nu 의 1행(surge)·2행(sway) 계수를 단위 속도를 넣어 뽑는다
%     B  1차 surge 모델 대 플랜트 — 학생이 돌리는 W01_openloop.slx 와 ode45 둘 다
%     C  sway 정상 선회 — M11 u r 과 cross-flow drag 가 정말 맞서는가
%     D  쿼터니언 — euler2q · q2euler · Rquat · Tquat 를 Rzyx · Tzyx 와 대조하고,
%        이 강의가 쓰는 2021 판 q2euler 의 round-off 분기를 실제로 밟아 본다
%
%   유한차분으로 M(1,1) 을 재지 않는다 (standing-orders.md §3-3). 행렬은
%   otter.m 과 같은 줄로 다시 세워서 읽는다. 기호 계산 도구 없이 돌도록
%   Coriolis 계수도 수치로 뽑는다.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
W    = fullfile(root, 'lectures', 'W01_simulink');
addpath(here, W);
mss_path();
R.otter = which('otter');

%% ---- A. otter.m (2021) 55-126 행을 그대로 --------------------------------
g = 9.81;  rho = 1025;  L = 2.0;  B = 1.08;  m = 55;  mp = 25;
rp = [0.05 0 -0.35]';   rg = [0.2 0 -0.2]';
R44 = 0.4*B;  R55 = 0.25*L;  R66 = 0.25*L;  Umax = 6*0.5144;
B_pont = 0.25;  Cb_pont = 0.4;
nabla = (m+mp)/rho;   Tdr = nabla/(2*Cb_pont*B_pont*L);
Ig_CG = m*diag([R44^2 R55^2 R66^2]);
rg    = (m*rg + mp*rp)/(m+mp);
Ig    = Ig_CG - m*Smtrx(rg)^2 - mp*Smtrx(rp)^2;
H     = Hmtrx(rg);
MRB   = H'*[(m+mp)*eye(3) zeros(3); zeros(3) Ig]*H;
Xudot = -0.1*m;  Yvdot = -1.5*m;  Zwdot = -1.0*m;
Kpdot = -0.2*Ig(1,1);  Mqdot = -0.8*Ig(2,2);  Nrdot = -1.7*Ig(3,3);
MA    = -diag([Xudot Yvdot Zwdot Kpdot Mqdot Nrdot]);
M     = MRB + MA;   Mi = inv(M);
Xu    = -24.4*g/Umax;
k_pos = 0.02216/2;

%  C(nu) nu 는 속도의 2차식이다. 단위 속도를 넣어 계수를 하나씩 뽑는다.
%     (C nu)_1 = a vr + b r^2      (C nu)_2 = c ur       — 수평면, w = p = q = 0
e   = @(i) full(sparse(i,1,1,6,1));
Cn  = @(nu) local_C(nu, m, mp, Ig, H, MA) * nu;
c_rr = Cn(e(6));                       c_rr = c_rr(1);
c_vr = Cn(e(2)+e(6));                  c_vr = c_vr(1) - c_rr;
c_ur = Cn(e(1)+e(6));                  c_ur = c_ur(2);
[~, CRB, CA] = local_C(e(1)+e(6), m, mp, Ig, H, MA);
c_ur_RB = CRB(2,:)*(e(1)+e(6));        c_ur_A = CA(2,:)*(e(1)+e(6));

R.M = M;  R.T_u = M(1,1)/abs(Xu);  R.K_u = 1/abs(Xu);
R.c_ur = c_ur;  R.c_vr = c_vr;  R.c_rr = c_rr;

fprintf('\n  W01 theory check — otter.m rebuilt from lines 98-126 (2021 release)\n');
fprintf('    otter.m in force : %s\n\n', R.otter);
fprintf('    surge row of M   : [%s]\n',  sprintf('%8.2f', M(1,:)));
fprintf('    sway  row of M   : [%s]\n',  sprintf('%8.2f', M(2,:)));
fprintf('    M15 = (m+mp) z_g = %.2f kg m,  z_g = %.4f m\n', M(1,5), rg(3));
fprintf('    1/[inv(M)]_11    = %.2f kg   (M11 = %.2f kg)\n', 1/Mi(1,1), M(1,1));
fprintf('    [inv(M)]_26      = %.4e m/s^2 per N m\n\n', Mi(2,6));
fprintf('    (C nu)_1, planar = %.2f v r %+.2f r^2      M22 = %.2f, M26 = %.2f\n', ...
        c_vr, c_rr, M(2,2), M(2,6));
fprintf('    (C nu)_2, planar = %.2f u r  = %.2f (C_RB) + %.2f (C_A)     M11 = %.2f\n\n', ...
        c_ur, c_ur_RB, c_ur_A, M(1,1));

%% ---- B. 1차 surge 모델 대 플랜트 -----------------------------------------
X   = 2*k_pos*60^2;
uss = X/abs(Xu);
opt = odeset('RelTol',1e-10, 'AbsTol',1e-12, 'MaxStep',0.01);
[t,Xs] = ode45(@(t,x) otter(x,[60;60],mp,rp,0,0), [0 60], zeros(12,1), opt);
R.t63_ode45 = local_t63(t, Xs(:,1));

V = W01_vars;
y = W01_read(run_sim('W01_openloop', V, 'dn', 0, 'n0', 60));
R.t63_slx = local_t63(y.t, y.u);

xd0 = otter(zeros(12,1),[60;60],mp,rp,0,0);
XD  = zeros(numel(t),12);
for i = 1:numel(t), XD(i,:) = otter(Xs(i,:)',[60;60],mp,rp,0,0)'; end
R.m_eff0   = X/xd0(1);
R.M15qdot  = max(abs(M(1,5)*XD(:,5)));
R.qw_term  = max(abs(M(3,3)*Xs(:,5).*Xs(:,3)));
R.qq_term  = max(abs(M(2,6)*Xs(:,5).^2));
R.du_max   = max(abs(Xs(:,1) - uss*(1-exp(-t/R.T_u))));
R.theta_max = rad2deg(max(abs(Xs(:,11))));

fprintf('    T_u = %.4f s   K_u = %.6f (m/s)/N   u_ss(n = 60) = %.4f m/s\n', R.T_u, R.K_u, uss);
fprintf('    63.2 %% of u_ss reached at  %.4f s  W01_openloop.slx (ode4, h = %g s)\n', R.t63_slx, V.h);
fprintf('                             %.4f s  otter.m with ode45\n', R.t63_ode45);
fprintf('    difference from T_u         %+.2f %%\n', 100*(R.t63_slx - R.T_u)/R.T_u);
fprintf('    X / udot(0)               = %.2f kg  (= 1/[inv(M)]_11, not M11)\n', R.m_eff0);
fprintf('    terms dropped from the surge row, peak over the run:\n');
fprintf('        |M15 qdot| = %.2f N   |M33 q w| = %.3f N   |M26 q^2| = %.3f N   (X = %.2f N)\n', ...
        R.M15qdot, R.qw_term, R.qq_term, X);
fprintf('    max |u_plant - u_first-order| = %.4f m/s,   max |theta| = %.3f deg\n\n', R.du_max, R.theta_max);

%  종단속도 표 — 추력은 n|n| 에, 감쇠는 u 에 비례하므로 u_ss 는 n^2 에 비례한다.
%  n_max 는 otter.m 이 2 k_pos n_max^2 = 24.4 g 로 정의하고 |X_u| = 24.4 g / U_max 이므로
%  전속에서의 종단속도는 정의상 U_max 와 같다.
n_max = sqrt((0.5*24.4*g)/k_pos);
nn    = [30 60 90 n_max];
R.uss_table = [nn; 2*k_pos*nn.^2; 2*k_pos*nn.^2/abs(Xu)]';
fprintf('      n [rad/s]     X [N]    u_ss [m/s]   u_ss [kn]\n');
fprintf('      %9.2f  %9.3f  %11.4f  %9.3f\n', [R.uss_table R.uss_table(:,3)/0.5144]');
fprintf('    u_ss(n_max) / U_max = %.6f     time to within 2 %% = 4 T_u = %.2f s\n\n', ...
        R.uss_table(end,3)/Umax, 4*R.T_u);

%% ---- C. sway 정상 선회 -------------------------------------------------
nT = [V.n0-V.dn; V.n0+V.dn];
[~,Xt] = ode45(@(t,x) otter(x,nT,mp,rp,0,0), [0 120], zeros(12,1), odeset(opt,'MaxStep',0.02));
x  = Xt(end,:)';
tc = crossFlowDrag(L, B_pont, Tdr, x(1:6));
R.turn = struct('u',x(1), 'v',x(2), 'r_deg',rad2deg(x(6)), ...
                'Cor',M(1,1)*x(1)*x(6), 'Ycf',tc(2), 'beta_deg',rad2deg(atan2(x(2),x(1))));
fprintf('    steady port turn, n = [%g %g] rad/s\n', nT);
fprintf('        u = %.4f m/s   v = %.4f m/s   r = %.4f deg/s   beta = %.3f deg\n', ...
        x(1), x(2), R.turn.r_deg, R.turn.beta_deg);
fprintf('        M11 u r = %+.4f N     Y_cf = %+.4f N     residual %.1e N\n\n', ...
        R.turn.Cor, R.turn.Ycf, R.turn.Cor - R.turn.Ycf);

%% ---- D. 쿼터니언 --------------------------------------------------------
d2r = pi/180;  ph = 10*d2r;  th = 7*d2r;  ps = 50*d2r;
q = euler2q(ph, th, ps);
[p2,t2,s2] = q2euler(q);
qp = @(a,b) [a(1)*b(1)-a(2:4)'*b(2:4); a(1)*b(2:4)+b(1)*a(2:4)+cross(a(2:4),b(2:4))];
qx = [cos(ph/2) sin(ph/2) 0 0]';  qy = [cos(th/2) 0 sin(th/2) 0]';  qz = [cos(ps/2) 0 0 sin(ps/2)]';
Tq = Tquat(q);
w  = [0.02 0.05 0.10]';  dt = 1e-7;  Thd = Tzyx(ph,th)*w;
qn = euler2q(ph+Thd(1)*dt, th+Thd(2)*dt, ps+Thd(3)*dt);

R.q          = q;
R.q_norm_err = norm(q) - 1;
R.roundtrip  = max(abs(rad2deg([p2-ph t2-th s2-ps])));
R.R_err      = max(max(abs(Rquat(q) - Rzyx(ph,th,ps))));
R.cover_err  = max(max(abs(Rquat(-q) - Rquat(q))));
R.TT_err     = max(max(abs(Tq'*Tq - eye(3)/4)));
R.prod_err   = max(abs(qp(qp(qz,qy),qx) - q));
R.qzy        = qp(qz,qy);                                % 유도의 중간 단계
R.qdot_err   = max(abs((qn-q)/dt - Tq*w));
R.prodT_err  = max(abs(0.5*qp(q,[0;w]) - Tq*w));         % qdot = q (x) [0;w] / 2
qa = euler2q(0.3,-0.4,1.2);  qb = euler2q(-0.7,0.2,-2.1);
R.compose_err = max(max(abs(Rquat(qp(qa,qb)) - Rquat(qa)*Rquat(qb))));

%  정규화 없이 적분하면 노름이 얼마나 벗어나는가 (전진 오일러, h = 0.02 s, 100 s)
qq = euler2q(0.1,0.2,0.3);  wq = [0.3 -0.2 0.5]';
for k = 1:5000, qq = qq + 0.02*Tquat(qq)*wq; end
R.drift = norm(qq) - 1;

%  2021 판 q2euler : |R31| 이 round-off 로 1 을 넘으면 theta 가 할당되지 않는다
rng(1);  R.q2euler_roundoff = 'no case found';
for k = 1:200000
    qk = euler2q(2*pi*rand-pi, sign(rand-0.5)*pi/2, 2*pi*rand-pi);  qk = qk/norm(qk);
    Rk = Rquat(qk);
    if abs(Rk(3,1)) > 1
        try
            [~,~,~] = q2euler(qk);
            R.q2euler_roundoff = sprintf('R31 = %.17g, q2euler returned normally', Rk(3,1));
        catch ME
            R.q2euler_roundoff = sprintf('R31 = %.17g, q2euler FAILED: %s', Rk(3,1), ME.message);
        end
        break
    end
end

thd = [0 45 80 89 89.9];
R.sing = zeros(numel(thd),3);
for i = 1:numel(thd)
    TT = Tzyx(0, thd(i)*d2r);  Tq2 = Tquat(euler2q(0, thd(i)*d2r, 0));
    R.sing(i,:) = [thd(i) max(abs(TT(:))) max(abs(Tq2(:)))];
end

fprintf('    euler2q(10, 7, 50 deg)      = [%s]\n', sprintf(' %.6f', q));
fprintf('    |q| - 1                     = %.1e\n', R.q_norm_err);
fprintf('    Euler -> q -> Euler         = %.1e deg\n', R.roundtrip);
fprintf('    max |Rquat(q) - Rzyx|       = %.1e\n', R.R_err);
fprintf('    max |Rquat(-q) - Rquat(q)|  = %.1e\n', R.cover_err);
fprintf('    max |Tq''Tq - I/4|           = %.1e\n', R.TT_err);
fprintf('    qz(50) (x) qy(7)            = [%s]\n', sprintf(' %.6f', R.qzy));
fprintf('    max |qz*qy*qx - euler2q|    = %.1e\n', R.prod_err);
fprintf('    max |R(qa (x) qb) - R(qa)R(qb)| = %.1e\n', R.compose_err);
fprintf('    max |q (x) [0;w]/2 - Tquat(q) w| = %.1e\n', R.prodT_err);
fprintf('    max |qdot_fd - Tquat(q) w|  = %.1e   (|qdot| = %.2e)\n', R.qdot_err, norm(Tq*w));
fprintf('    100 s of forward Euler without renormalising: |q| - 1 = %.4f\n', R.drift);
fprintf('    q2euler round-off branch    : %s\n\n', R.q2euler_roundoff);
fprintf('      theta [deg]   max|T_Theta|   max|T_q|\n');
fprintf('      %9.1f   %12.2f   %8.4f\n', R.sing');
fprintf('\n');
end

% ======================================================================
function [C, CRB, CA] = local_C(nu, m, mp, Ig, H, MA)
%  otter.m 104-126 행 그대로 : C_RB 는 CG 에서 세워 CO 로 옮기고,
%  C_A 는 m2c 로 만든 뒤 yaw 의 Munk 모멘트 두 항만 0 으로 둔다.
nu2 = nu(4:6);
CRB = H' * [ (m+mp)*Smtrx(nu2) zeros(3); zeros(3) -Smtrx(Ig*nu2) ] * H;
CA  = m2c(MA, nu);   CA(6,1) = 0;   CA(6,2) = 0;
C   = CRB + CA;
end

function t63 = local_t63(t, u)
%  최종값의 1 - e^-1 = 63.2 % 에 닿는 시각. 격자 사이는 선형 보간한다.
thr = (1 - exp(-1))*u(end);
k   = find(u >= thr, 1);
t63 = interp1(u(k-1:k), t(k-1:k), thr);
end

