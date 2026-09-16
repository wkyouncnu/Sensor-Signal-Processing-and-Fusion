function ok = verify_w02_antiwindup()
%VERIFY_W02_ANTIWINDUP  안티와인드업 세 방식의 결과가 옳은지 두 가지로 확인한다.
%                       Check the results of the three anti-windup schemes two
%                       independent ways.
%
%      ok = verify_w02_antiwindup
%
%VERIFY_W02_ANTIWINDUP  안티와인드업 세 방식의 결과가 옳은지 여러 방향에서 본다.
%
%  ── 왜 한 가지로는 부족한가 / why one check is not enough ───────────────
%  회귀 검증만으로는 "예전과 같다" 밖에 말하지 못한다. 예전 것이 틀렸다면 같이
%  틀린 채로 통과한다. 그래서 두 방향을 더 붙였다 — 강의에 적힌 식에서 고리
%  전체를 Simulink 없이 다시 구현한 것, 그리고 MathWorks 의 PID 블록.
%
%  A regression check alone can only say "the same as before", and if what came
%  before was wrong it passes while still being wrong. Two further directions
%  are therefore added: the whole loop reimplemented from the equations in the
%  lecture without Simulink, and MathWorks's own PID Controller block.
%
%    검증 1  회귀 — 강의노트 §F 표의 세 행을 다시 재어 인쇄된 자릿수까지 대조
%    검증 2  독립 — 평범한 MATLAB 으로 PI · 안티와인드업 · 배분 · otter.m 을
%            같은 고정 스텝 RK4 로 적분하고, u(t) · I(t) · X_cmd(t) 를 대조
%    검증 3  외부 — Simulink 의 PID Controller 블록이 자기 안티와인드업으로
%            같은 궤적을 내는가
%    검증 4  경계 — Ki = 0 에서 역계산이 막히는가
%    검증 5  등가 — 클램핑의 얼림 조건 두 표현이 같은 값을 주는가
%
%    check 1  regression: the three rows of the section F table, to the
%             precision printed there
%    check 2  independence: PI, anti-windup, allocation and otter.m integrated
%             in plain MATLAB with the same fixed-step RK4, compared on
%             u(t), I(t) and X_cmd(t)
%    check 3  an outside implementation: does Simulink's own PID Controller
%             block, using its own anti-windup, produce the same trajectory
%    check 4  boundary: is back-calculation gated off when Ki = 0
%    check 5  equivalence: do the two ways of writing the clamping condition
%             agree
%
%  세 곳에서 같은 답이 나온다 — 이 모델, 강의의 식, 그리고 MathWorks 의 구현.
%  The same answer from three places: this model, the equations in the lecture,
%  and MathWorks's implementation.

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(fileparts(here), 'lectures', 'W02_simulink'));
mss_path();

%           방식 / scheme        peak I [N]  peak X_cmd [N]  recovery [s]
REF = { 'none',             0,   3438.2,      3480.0,         13.980
        'clamping',         1,    197.8,       355.9,          3.400
        'back-calculation', 2,    213.1,       356.2,          3.440 };

TOL_N = 0.05;   TOL_S = 0.0005;

V = W02_vars;
c = W02_cols;
V.u_d1 = 3.5;   V.u_d2 = 1.5;   V.t_up = 5;   V.t_dn = 40;   V.T_final = 90;

ok = true;

%% ===== 검증 1 : 회귀 / check 1: regression ==============================
fprintf('\n  W02 §2-6 — 안티와인드업 검증 / anti-windup verification\n\n');
fprintf('  1) 회귀 — 강의노트 §F 의 표를 다시 잰다\n');
fprintf('     regression: the section F table, re-measured\n\n');
fprintf('    %-18s %12s %12s %12s %12s %12s %12s\n', ...
        'scheme', 'peak I ref', 'peak I now', 'peak X ref', 'peak X now', ...
        'rec ref', 'rec now');
fprintf('    %s\n', repmat('-', 1, 94));

R = cell(1,3);
for i = 1:size(REF,1)
    R{i} = run_sim('W02_surge_control', V, 'aw_mode', REF{i,2});
    pI = max(R{i}.y(:, c.I));
    pX = max(R{i}.y(:, c.X_cmd));
    rc = local_recovery(R{i}.t, R{i}.y(:, c.u), V.u_d2, V.t_dn);

    good = abs(pI - REF{i,3}) < TOL_N && abs(pX - REF{i,4}) < TOL_N && ...
           abs(rc - REF{i,5}) < TOL_S;
    ok   = ok && good;
    if good, mark = ''; else, mark = '  <-- 불일치 MISMATCH'; end
    fprintf('    %-18s %12.1f %12.1f %12.1f %12.1f %12.3f %12.3f%s\n', ...
            REF{i,1}, REF{i,3}, pI, REF{i,4}, pX, REF{i,5}, rc, mark);
end

%% ===== 검증 2 : 독립 구현 / check 2: an independent implementation ======
%  Simulink 를 쓰지 않는다. 강의의 식만 보고 다시 짠다.
%     제어기   X_cmd = Kp e + I,            e = u_d - u          (§2-3, Kd = 0)
%     적분기   dI/dt = di,                  di 는 방식에 따라     (§2-6)
%     배분     T = X_cmd/2,  n = sign(T) sqrt(|T|/k),  자른 뒤
%              X_sat = 2 k n|n|                                   (§2-5)
%     플랜트   otter.m 을 그대로 부른다                            (§1-10)
%  적분은 모델과 같은 고정 스텝 RK4 이다.
%
%  No Simulink. The equations of the lecture are coded again from the notes,
%  and integrated with the same fixed-step RK4 the model uses.
fprintf('\n  2) 독립 구현 — Simulink 없이 강의의 식에서 고리를 다시 짠다\n');
fprintf('     independence: the loop rebuilt from the equations, without Simulink\n\n');
fprintf('    %-18s %14s %14s %14s\n', ...
        'scheme', 'max |du| [m/s]', 'max |dI| [N]', 'max |dX| [N]');
fprintf('    %s\n', repmat('-', 1, 64));

for i = 1:size(REF,1)
    S = local_replay(V, REF{i,2});
    t = R{i}.t;
    du = max(abs(interp1(S.t, S.u,     t) - R{i}.y(:, c.u)));
    dI = max(abs(interp1(S.t, S.I,     t) - R{i}.y(:, c.I)));
    dX = max(abs(interp1(S.t, S.X_cmd, t) - R{i}.y(:, c.X_cmd)));

    %  허용오차는 절대값이 아니라 그 신호의 크기에 맞춘다. I 는 수천 N 까지
    %  올라가고 u 는 몇 m/s 이므로 같은 잣대를 쓸 수 없다.
    %  The tolerances are scaled to each signal: I reaches thousands of newtons
    %  while u is a few m/s, so one absolute figure cannot serve both.
    good = du < 1e-6 && dI < 1e-6*max(abs(R{i}.y(:, c.I))) && ...
           dX < 1e-6*max(abs(R{i}.y(:, c.X_cmd)));
    ok   = ok && good;
    if good, mark = ''; else, mark = '  <-- 불일치 MISMATCH'; end
    fprintf('    %-18s %14.2e %14.2e %14.2e%s\n', REF{i,1}, du, dI, dX, mark);
end
fprintf(['\n    두 구현이 이 정도로 같다는 것은, 모델의 결과가 모델 자신의\n' ...
         '    배선이 아니라 강의에 적힌 식에서 나온다는 뜻이다.\n' ...
         '    Agreement at this level means the model''s results follow from the\n' ...
         '    equations printed in the lecture rather than from its own wiring.\n']);

%% ===== 검증 3 : Simulink 의 PID 블록과 대조 / check 3: against the block ==
%  Simulink 의 PID Controller 블록은 자체 출력 포화와 자체 안티와인드업을 갖고
%  있고, 이 모델에서 그 한계는 배분이 거는 한계와 같은 값이다. 그러므로 같은
%  방식을 고르면 두 경로가 같은 배를 몰아야 한다. 손으로 조립한 것이 옳은지를
%  **MathWorks 의 구현**에 물어보는 셈이다.
%
%  Simulink's PID Controller block has its own output saturation and its own
%  anti-windup, and in this model those limits are the same numbers the
%  allocation imposes. Selecting the same scheme on both paths must therefore
%  drive the same vessel: it asks MathWorks's implementation whether the
%  hand-built one is right.
%
%  Kd = 0 으로 둔다. Kd 가 0 이 아니면 두 경로는 §2-4 의 c_d 때문에 애초에
%  다른 제어기이고, 그 차이는 안티와인드업과 아무 상관이 없다.
%  Kd is held at zero: with Kd non-zero the two paths are different controllers
%  by the setpoint weight of §2-4, and that difference has nothing to do with
%  anti-windup.
%
%  두 방식을 같은 잣대로 재지 않는다. 그럴 이유가 있다.
%
%  역계산의 오른편은 연속이다 — 적분기 입력이 Ki e - K_aw sat 이고, 포화가
%  시작되는 순간에도 sat 은 0 에서 연속으로 자란다. 그래서 두 구현이 기계
%  정밀도까지 같아야 하고, 실제로 그렇다.
%
%  클램핑의 오른편은 불연속이다 — 적분기 입력이 Ki e 와 0 사이를 **뛴다**.
%  고정 스텝 솔버는 그 뜀을 스텝 안에서 해결하지 못하므로, 두 구현이 스위치가
%  뒤집히는 순간을 h 정도 다르게 잡는다. 그러므로 여기서 물어야 할 것은
%  "같은가" 가 아니라 "스텝을 줄이면 같아지는가" 이다. 규칙이 다르면 차이가
%  남고, 이산화 때문이면 차이가 h 와 함께 사라진다.
%
%  The two schemes are not held to the same standard, and there is a reason.
%  Back-calculation has a continuous right-hand side: the integrator input is
%  Ki e - K_aw sat, and sat grows continuously from zero as saturation begins,
%  so the two implementations must agree to machine precision, and they do.
%  Clamping has a discontinuous one: the integrator input jumps between Ki e
%  and zero. A fixed-step solver cannot place that jump inside a step, so two
%  implementations catch it up to about h apart. The question to ask here is
%  therefore not whether they agree but whether they converge: a difference of
%  rule would persist, whereas a difference of discretisation vanishes with h.
fprintf('\n  3) Simulink PID Controller 블록과의 대조\n');
fprintf('     cross-check against Simulink''s own PID Controller block\n\n');
fprintf('    %10s %24s %26s\n', 'h [s]', 'clamping max|du| [m/s]', 'back-calc max|du| [m/s]');
fprintf('    %s\n', repmat('-', 1, 64));

%  네 단계까지 줄인다. 두 단계로는 "줄어든다" 를 우연과 구별하기 어렵고,
%  강의 §2-6 의 표가 이 네 줄을 그대로 싣는다.
%  Four halvings: two would not distinguish a fall from a coincidence, and the
%  table in §2-6 reproduces these four rows.
HS = [V.h, V.h/2, V.h/4, V.h/8];
dc = zeros(size(HS));
for j = 1:numel(HS)
    Vh = V;  Vh.h = HS(j);
    Rc = run_sim('W02_surge_control', Vh, 'aw_mode', 1, 'Kd', 0, 'pid_mode', 0);
    Rb = run_sim('W02_surge_control', Vh, 'aw_mode', 2, 'Kd', 0, 'pid_mode', 0);
    Bc = local_pid_block(Vh, 'clamping');
    Bb = local_pid_block(Vh, 'back-calculation');
    dc(j) = max(abs(Rc.y(:, c.u) - Bc.y(:, c.u)));
    db    = max(abs(Rb.y(:, c.u) - Bb.y(:, c.u)));

    good = db < 1e-12;              % 역계산은 기계 정밀도여야 한다
    ok   = ok && good;
    if good, mark = ''; else, mark = '  <-- 불일치 MISMATCH'; end
    fprintf('    %10g %24.3e %26.3e%s\n', HS(j), dc(j), db, mark);
end

conv = all(dc(2:end) < 0.8*dc(1:end-1));
ok   = ok && conv;
if conv
    fprintf(['\n    역계산은 스텝과 무관하게 기계 정밀도로 같다. 클램핑의 차이는\n' ...
             '    스텝을 반으로 줄일 때마다 함께 줄어든다. 두 구현이 서로 다른\n' ...
             '    규칙을 쓰는 것이 아니라, 불연속을 이산화하는 방법이 다를 뿐이라는\n' ...
             '    뜻이다. 규칙이 달랐다면 차이가 h 와 무관하게 남았을 것이다.\n' ...
             '    (%.2e -> %.2e -> %.2e -> %.2e)\n' ...
             '    Back-calculation agrees to machine precision at every step size,\n' ...
             '    while the clamping difference falls with the step. The two\n' ...
             '    implement the same rule and differ only in how each discretises\n' ...
             '    the discontinuity; a difference of rule would not depend on h.\n'], dc);
else
    fprintf(['\n    ***** 클램핑의 차이가 스텝과 함께 줄지 않는다. 그렇다면 두\n' ...
             '    구현이 서로 다른 규칙을 쓰고 있다는 뜻이므로 다시 본다. *****\n']);
end

%% ===== 검증 4 : Ki = 0 경계 / check 4: the Ki = 0 boundary ==============
R0   = run_sim('W02_surge_control', V, 'Ki', 0, 'aw_mode', 2);
Imax = max(abs(R0.y(:, c.I)));
fprintf('\n  4) Ki = 0, aw_mode = 2 :  max|I| = %.3e   (0 이어야 한다 / must be zero)\n', Imax);
ok = ok && Imax < 1e-9;

%% ===== 검증 4 : 클램핑 조건의 등가성 / check 4: the clamping condition ==
%  도면은 |sat| > 1e-9 과 e*sat > 0 을 본다. 그 이전의 코드는 뒤의 것을
%  sign(e) == sign(sat) 으로 썼다. 0 과 허용오차 경계를 포함한 격자에서 비교한다.
%  The canvas tests |sat| > 1e-9 and e*sat > 0; the code it replaced wrote the
%  second as sign(e) == sign(sat). They are compared on a grid that includes
%  the zeros and the tolerance boundary.
g = [-3 -1 -1e-9 -1e-12 0 1e-12 1e-9 1 3];
agree = true;
for a = g
    for b = g
        agree = agree && ((abs(b) > 1e-9 && sign(a) == sign(b)) == ...
                          ((abs(b) > 1e-9) && (a*b > 0)));
    end
end
if agree, verdict = '일치한다 / agree'; else, verdict = '어긋난다 / DISAGREE'; end
fprintf('  5) 클램핑 조건 %d 가지 조합에서 두 표현이 %s\n', numel(g)^2, verdict);
ok = ok && agree;

%% ===== 검증 6 : 게인의 위치 / check 6: where the gain sits ================
%  §2-6 은 역계산이 두 가지 모양으로 그려진다고 말한다.
%      이 강의       dI/dt = Ki e - K_aw (u - u_sat)          게인이 바깥
%      Franklin      dI/dt = kI [ e - Ka (u - u_sat) ]        게인이 안쪽
%  그리고 둘이 K_aw = kI Ka 로 같은 법칙이라고 주장한다. 그 주장을 잰다.
%
%  Otter 와 무관한 예제로 잰다 — Franklin 8E 그림 9.22 의 구성 그대로,
%  플랜트 1/s, kp = 2, kI = 4, Ka = 10, |u| <= 1. 선체를 빼면 남는 것이
%  안티와인드업뿐이므로, 맞지 않으면 원인이 하나뿐이다.
%
%  §2-6 claims that back-calculation is drawn two ways, with the gain outside
%  the integral gain or inside it, and that the two are one law with
%  K_aw = kI Ka. That claim is measured here on an example that has nothing to
%  do with the Otter: the arrangement of Franklin 8E Fig. 9.22, with a plant of
%  1/s, kp = 2, kI = 4, Ka = 10 and |u| <= 1. With the hull removed, nothing
%  but the anti-windup is left to explain a disagreement.
F.kp = 2;  F.kI = 4;  F.Ka = 10;  F.lim = 1;  F.h = 1e-4;  F.T = 10;

yOut = local_franklin(F, 'outside');     % K_aw = kI*Ka
yIn  = local_franklin(F, 'inside');      % Ka inside kI
yOff = local_franklin(F, 'none');        % 보호 없음 / unprotected

dGain = max(abs(yOut - yIn));
ok    = ok && dGain < 1e-9;
if dGain < 1e-9, mk = ''; else, mk = '  <-- 불일치 MISMATCH'; end

fprintf('\n  6) 게인의 위치 — Franklin 8E 그림 9.22 의 예제로 (Otter 와 무관)\n');
fprintf('     where the gain sits, on the example of Franklin 8E Fig. 9.22\n\n');
fprintf('     바깥 형태와 안쪽 형태의 최대 차이 / largest difference between the\n');
fprintf('     two forms, with K_aw = kI Ka = %g :  %.3e%s\n', F.kI*F.Ka, dGain, mk);
fprintf('     보호 없음 오버슛 / overshoot without anti-windup : %.2f\n', max(yOff));
fprintf('     보호 있음 오버슛 / overshoot with anti-windup    : %.2f\n', max(yOut));
fprintf(['     Franklin 그림 9.23 이 싣는 값은 약 1.53 과 1.15 이다.\n' ...
         '     Figure 9.23 of the source shows approximately 1.53 and 1.15.\n']);

fprintf('\n');
if ok
    fprintf('  ALL CHECKS PASSED\n\n');
else
    fprintf('  ***** 불일치 있음. 위 표에서 표시된 줄을 본다. *****\n\n');
end
end

% =========================================================================
function y = local_franklin(F, form)
%LOCAL_FRANKLIN  Franklin 8E 그림 9.22 의 구성을 평범한 MATLAB 으로 적분한다.
%                The arrangement of Franklin 8E Fig. 9.22, integrated in plain
%                MATLAB.
%
%      plant 1/s,  r = 1 계단,  u = kp e + I,  u_sat = sat(u),  ydot = u_sat
%
%      'none'      dI/dt = kI e                          보호 없음
%      'outside'   dI/dt = kI e - (kI Ka)(u - u_sat)     이 강의의 모양
%      'inside'    dI/dt = kI [ e - Ka (u - u_sat) ]     Franklin 의 모양
%
%  'outside' 와 'inside' 가 같은 값을 내야 §2-6 의 주장이 참이다.
%  If 'outside' and 'inside' agree, the claim of §2-6 holds.
t = (0:F.h:F.T).';
y = zeros(numel(t),1);
Y = 0;  I = 0;
for k = 1:numel(t)
    y(k) = Y;
    if k == numel(t), break, end
    [k1Y,k1I] = fr(Y, I, F, form);
    [k2Y,k2I] = fr(Y+F.h/2*k1Y, I+F.h/2*k1I, F, form);
    [k3Y,k3I] = fr(Y+F.h/2*k2Y, I+F.h/2*k2I, F, form);
    [k4Y,k4I] = fr(Y+F.h*k3Y,   I+F.h*k3I,   F, form);
    Y = Y + F.h/6*(k1Y+2*k2Y+2*k3Y+k4Y);
    I = I + F.h/6*(k1I+2*k2I+2*k3I+k4I);
end
end

function [Ydot, Idot] = fr(Y, I, F, form)
e     = 1 - Y;                                   % 단위 계단 / a unit step
u     = F.kp*e + I;
u_sat = min(max(u, -F.lim), F.lim);
switch form
    case 'none',    Idot = F.kI*e;
    case 'outside', Idot = F.kI*e - (F.kI*F.Ka)*(u - u_sat);
    case 'inside',  Idot = F.kI*(e - F.Ka*(u - u_sat));
end
Ydot = u_sat;                                    % 플랜트 1/s / the plant 1/s
end

% -------------------------------------------------------------------------
function o = local_pid_block(V, awmode)
%LOCAL_PID_BLOCK  라이브러리 PID 블록 경로로 한 번 돌린다. 그 블록의 안티와인드업
%                 방식을 골라 주어야 하므로 run_sim 대신 여기서 직접 부른다.
%                 One run through the library PID block path. The block's own
%                 anti-windup mode has to be selected, which run_sim does not
%                 do, so the simulation is set up here.
in = Simulink.SimulationInput('W02_surge_control');
V.pid_mode = 1;   V.Kd = 0;
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
in = in.setBlockParameter('W02_surge_control/Surge controller/PID block', ...
                          'AntiWindupMode', awmode);
evalc('r = sim(in);');
names = r.who;
for i = 1:numel(names)
    s = r.(names{i});
    if isstruct(s) && isfield(s,'signals') && isfield(s,'time')
        y = squeeze(s.signals.values);
        if size(y,1) < size(y,2), y = y.'; end
        o.t = s.time;  o.y = y;  return
    end
end
error('local_pid_block:noLog', '로그를 찾지 못했다 / no logged structure found');
end

% -------------------------------------------------------------------------
function S = local_replay(V, aw_mode)
%LOCAL_REPLAY  W02 의 속도 고리를 Simulink 없이 다시 구현한다.
%              The Week 2 speed loop, reimplemented without Simulink.
%
%  상태는 otter.m 의 12 상태에 적분기 상태 I 를 더한 13 개이다. 적분은 모델과
%  같은 고정 스텝 RK4 이고, 스텝 크기도 V.h 로 같다.
%  The state is otter.m's twelve plus the integrator state I, thirteen in all,
%  advanced by the same fixed-step RK4 at the same step size V.h.
h  = V.h;
t  = (0:h:V.T_final).';
N  = numel(t);
x  = V.x0(:);          % otter.m 의 12 상태 / otter's twelve states
I  = 0;                % 적분기 상태 [N] / the integrator state

S.t = t;
S.u = zeros(N,1);  S.I = zeros(N,1);  S.X_cmd = zeros(N,1);

for k = 1:N
    S.u(k) = x(1);  S.I(k) = I;
    S.X_cmd(k) = V.Kp*(ref(t(k),V) - x(1)) + I;
    if k == N, break, end

    %  RK4. 두 상태 묶음을 함께 전진시킨다 — 고리가 닫혀 있으므로 따로 풀 수 없다.
    %  RK4, advancing both state groups together: the loop is closed, so they
    %  cannot be stepped separately.
    [k1x, k1I] = deriv(t(k),       x,           I,           V, aw_mode);
    [k2x, k2I] = deriv(t(k)+h/2, x+h/2*k1x, I+h/2*k1I, V, aw_mode);
    [k3x, k3I] = deriv(t(k)+h/2, x+h/2*k2x, I+h/2*k2I, V, aw_mode);
    [k4x, k4I] = deriv(t(k)+h,   x+h*k3x,   I+h*k3I,   V, aw_mode);
    x = x + h/6*(k1x + 2*k2x + 2*k3x + k4x);
    I = I + h/6*(k1I + 2*k2I + 2*k3I + k4I);
end
end

% -------------------------------------------------------------------------
function [xdot, Idot] = deriv(t, x, I, V, aw_mode)
%  제어기 / the controller (§2-3, Kd = 0 이므로 미분항은 없다)
e     = ref(t,V) - x(1);
X_cmd = V.Kp*e + I;

%  배분 / the allocation (§2-5)
T = X_cmd/2;
if T >= 0, n = sqrt(T/V.k_pos); else, n = -sqrt(-T/V.k_neg); end
n = min(max(n, V.n_min), V.n_max);
if n >= 0, X_sat = 2*V.k_pos*n*abs(n); else, X_sat = 2*V.k_neg*n*abs(n); end

%  안티와인드업 / the anti-windup (§2-6)
sat  = X_cmd - X_sat;
Idot = V.Ki*e;
if V.Ki ~= 0
    switch aw_mode
        case 1
            if abs(sat) > 1e-9 && sign(e) == sign(sat), Idot = 0; end
        case 2
            Idot = Idot - V.K_aw*sat;
    end
end

%  플랜트 / the plant (otter.m, 고치지 않고 그대로 / called unmodified)
xdot = otter(x, [n; n], V.mp, V.rp, V.V_c, V.beta_c);
end

% -------------------------------------------------------------------------
function r = ref(t, V)
%  두 계단의 합 / the sum of the two steps
r = V.u_d1*(t >= V.t_up) + (V.u_d2 - V.u_d1)*(t >= V.t_dn);
end

% -------------------------------------------------------------------------
function tr = local_recovery(t, y, yf, t0)
%  §F 가 쓰는 정의 그대로 : t0 이후, 2 퍼센트 띠를 마지막으로 벗어난 시각.
%  The definition section F uses: after t0, the last instant outside a 2 per
%  cent band on the new setpoint.
k = t >= t0;
t = t(k) - t0;  y = y(k);
out = find(abs(y - yf) > 0.02*abs(yf), 1, 'last');
if isempty(out), tr = 0; else, tr = t(min(out+1, numel(t))); end
end
