function ok = verify_w03_derivative()
%VERIFY_W03_DERIVATIVE  §3-4 의 미분항 부호 주장을 수치로 확인한다.
%                       Check, numerically, every claim §3-4 makes about the
%                       sign in front of the derivative term.
%
%      ok = verify_w03_derivative
%
%  ── 왜 이 파일이 있는가 / why this file exists ──────────────────────────
%  2026-09-16 검토 전까지 §3-4 는 "미분을 측정값에서 받는 형태의 마이너스는
%  교과서 PID 의 플러스를 다시 쓴 것일 뿐" 이라고 적고 있었다. 그 문장은
%  설정값이 계단처럼 구간마다 일정할 때만 참이다. u_d 가 시간에 따라 변하면
%  두 식은 서로 다른 제어기다.
%
%  Until the 2026-09-16 review §3-4 claimed that the minus sign of the
%  derivative-on-measurement form was merely the textbook plus rewritten.
%  That is true only while the setpoint is held constant. Once u_d moves,
%  the two forms are different controllers, and this file measures how.
%
%  ── 확인하는 것 셋 / the three claims checked here ─────────────────────
%    1. 두 형태의 차이는 정확히  K_d F(s) u_d  하나뿐이다 (측정값과 무관).
%       The two forms differ by exactly K_d F(s) u_d and nothing else.
%    2. 그래서 특성방정식이 같다 — 극점도, 감쇠도, 안정성도 같다.
%       Hence the characteristic polynomial, and so the poles, are identical.
%    3. 부호를 +K_d 로 쓰면 실제로 불안정해지는지 — 강의가 쓰는 K_d 값에서.
%       Whether +K_d really destabilises the loop, at the gains this week uses.

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(fileparts(here), 'lectures', 'W03_simulink'));
V = W03_vars;   % 게인을 여기서 다시 적지 않는다 / the gains have one home

s  = tf('s');
P  = V.K_u/(V.T_u*s + 1);                 % 서지 플랜트 / the surge plant
F  = V.Nf*s/(s + V.Nf);                   % 유사미분 / the pseudo-derivative
Kp = V.Kp_d;   Ki = V.Ki_d;

KDS = [2 20 60 150];                      % §3-4·§E·§I 가 실제로 쓰는 값들
ok  = true;

fprintf('\n  W03 §3-4 — 미분항 부호 검증 / the sign of the derivative term\n');
fprintf('  플랜트 K_u = %.6g, T_u = %.6g,  K_p = %.4f, K_i = %.4f, N = %g\n\n', ...
        V.K_u, V.T_u, Kp, Ki, V.Nf);

%% ---- 1) 두 형태의 차이가 K_d F u_d 하나뿐인가 --------------------------
%  X_A = (Kp + Ki/s + Kd F) e            교과서형 / textbook
%  X_B = (Kp + Ki/s) e  -  Kd F u        측정미분형 / derivative on measurement
%  e = u_d - u 를 넣으면  X_A - X_B = Kd F (e + u) = Kd F u_d.
%  대수로 정리하면 X_A - X_B = Kd F u_d 이지만, 정리를 믿지 말고 신호로 재
%  본다. u_d 와 u 에 서로 아무 관계 없는 신호를 넣고 두 지령을 각각 만든 뒤,
%  그 차이가 u_d 하나만으로 예측되는지 본다. 되먹임을 닫지 않는 것이 요점이다
%  — 닫으면 u 가 u_d 를 따라가서 둘이 같아 보일 수 있다.
%  The algebra says X_A - X_B = Kd F u_d. Rather than trust the algebra, feed
%  u_d and u two unrelated signals, form both commands, and check that their
%  difference is predicted by u_d alone. The loop is deliberately left OPEN:
%  closing it would let u follow u_d and hide the distinction.
t  = 0:0.005:40;
ud = 1.5*(t >= 5) + 0.05*t;                       % 계단 + 경사 / step + ramp
uu = 0.8*sin(0.7*t) + 0.3*sin(3.1*t + 1);         % u_d 와 무관한 신호
ee = ud - uu;
fprintf('  1) 두 형태의 차이 / the difference between the two forms\n');
fprintf('     %6s %26s %20s\n', 'K_d', '예측 = K_d F(s) u_d', 'max|측정-예측| [N]');
fprintf('     %s\n', repmat('-', 1, 56));
for Kd = KDS
    XA   = lsim(Kp + Ki/s + Kd*F, ee, t);         % 교과서형
    XB   = lsim(Kp + Ki/s, ee, t) - lsim(Kd*F, uu, t);
    pred = lsim(Kd*F, ud, t);
    res  = max(abs((XA - XB) - pred));
    fprintf('     %6g %26s %20.3e\n', Kd, 'K_d F(s) u_d', res);
    ok   = ok && res < 1e-6*max(1, Kd);
end

%% ---- 2) 특성방정식이 같은가 = 극점이 같은가 ----------------------------
%  A:  u (1 + P C_A) = P C_A u_d
%  B:  u (1 + P C_A) = P (Kp + Ki/s) u_d          <- 분모가 같다
fprintf('\n  2) 극점 / closed-loop poles\n');
fprintf('     %6s %34s %16s\n', 'K_d', '극점 / poles (A 와 B 공통)', 'max|차이|');
fprintf('     %s\n', repmat('-', 1, 60));
for Kd = KDS
    CA  = Kp + Ki/s + Kd*F;
    TA  = minreal(feedback(P*CA, 1), 1e-8);
    TB  = minreal(P*(Kp + Ki/s)/(1 + P*CA), 1e-8);
    pA  = sort(pole(TA));   pB = sort(pole(TB));
    d   = max(abs(pA - pB));
    fprintf('     %6g %34s %16.3e\n', Kd, mat2str(round(pA.', 3)), d);
    ok  = ok && d < 1e-6;
end

%% ---- 2b) 영점은 다르다 — 그래서 응답이 다르다 --------------------------
fprintf('\n  2b) 영점 / zeros — 여기서 갈린다\n');
fprintf('     %6s %30s %30s\n', 'K_d', 'A 교과서형 / textbook', 'B 측정미분형 / on measurement');
fprintf('     %s\n', repmat('-', 1, 70));
for Kd = KDS
    CA = Kp + Ki/s + Kd*F;
    TA = minreal(feedback(P*CA, 1), 1e-8);
    TB = minreal(P*(Kp + Ki/s)/(1 + P*CA), 1e-8);
    fprintf('     %6g %30s %30s\n', Kd, ...
            mat2str(round(sort(zero(TA)).', 3)), mat2str(round(sort(zero(TB)).', 3)));
end

%% ---- 3) 설정값이 움직이면 얼마나 벌어지는가 ----------------------------
%  u_d 를 기울기 a 로 올린다. 저주파에서 F(s) -> s 이므로 두 지령의 차이는
%  정상상태에서 K_d * a 로 간다. 계단(a = 0)에서는 0 이다.
%  Ramp the setpoint at a m/s^2. Since F(s) -> s at low frequency the two
%  commands differ by K_d*a in steady state, and by nothing at all when a = 0.
a  = 0.1;                                  % 설정값 기울기 [m/s^2]
t  = 0:0.01:40;
fprintf('\n  3) 설정값이 %g m/s^2 로 변할 때 두 지령의 차이 [N]\n', a);
fprintf('     %6s %22s %22s\n', 'K_d', '측정 / measured', '예측 K_d a / predicted');
fprintf('     %s\n', repmat('-', 1, 52));
for Kd = KDS
    dX   = lsim(Kd*F, a*t, t);             % 차이는 u_d 에만 걸린다
    meas = dX(end);
    fprintf('     %6g %22.4f %22.4f\n', Kd, meas, Kd*a);
    ok   = ok && abs(meas - Kd*a) < 1e-3*max(1, Kd*a);
end

%% ---- 4) 부호를 뒤집으면 정말 불안정한가 --------------------------------
%  +K_d F u 로 쓰면 되먹임 경로가  Kp + Ki/s - Kd F  가 된다. 강의는 이것을
%  "무조건 불안정해진다" 고 적고 있었는데, 그렇지 않다. §E-2 가 보였듯 이 축에서
%  K_d 는 질량 자리에 앉으므로 (M11 + K_d) 가 (M11 - K_d) 가 되고, 뺄셈이 선체
%  질량을 다 먹어 치우기 전까지는 살아 있다. 그 문턱을 실제로 찾는다.
%
%  The lecture used to claim the wrong sign always destabilises the loop. It
%  does not. On this axis K_d sits where the mass sits (§E-2), so the wrong
%  sign turns (M11 + K_d) into (M11 - K_d): the loop survives until the
%  subtraction has eaten the hull's own mass. The threshold is found here.
wrongStable = @(Kd) all(real(pole(minreal( ...
        P*(Kp + Ki/s)/(1 + P*(Kp + Ki/s - Kd*F)), 1e-8))) < 0);

fprintf('\n  4) 부호를 +K_d 로 잘못 쓰면 / if the sign is written as +K_d\n');
fprintf('     %6s %42s %18s\n', 'K_d', '극점 / poles', '판정 / verdict');
fprintf('     %s\n', repmat('-', 1, 68));
for Kd = KDS
    pw = pole(minreal(P*(Kp + Ki/s)/(1 + P*(Kp + Ki/s - Kd*F)), 1e-8));
    if any(real(pw) > 0), verdict = '불안정 UNSTABLE'; else, verdict = '안정 stable'; end
    fprintf('     %6s %42s %18s\n', num2str(Kd), mat2str(round(pw.', 3)), verdict);
end

%  이분법으로 문턱을 찾는다 / bisect for the threshold
lo = 1;  hi = 400;
assert(wrongStable(lo) && ~wrongStable(hi), '문턱이 [1, 400] 밖에 있다');
while hi - lo > 1e-6
    mid = 0.5*(lo + hi);
    if wrongStable(mid), lo = mid; else, hi = mid; end
end
fprintf('\n     불안정해지는 문턱 / threshold   K_d = %.4f kg\n', 0.5*(lo+hi));
fprintf('     선체의 서지 질량 / the hull''s own surge mass  M11 = %.4f kg\n', V.M11);
fprintf('     차이 / difference = %.4f kg  (%.2f %%)\n', ...
        abs(0.5*(lo+hi) - V.M11), 100*abs(0.5*(lo+hi) - V.M11)/V.M11);
fprintf(['     뺀 질량이 선체 질량을 넘어서면 유효질량이 음수가 되고, 그때\n' ...
         '     비로소 불안정해진다. 필터 N = %g 때문에 문턱이 M11 과 정확히\n' ...
         '     같지는 않다 / the filter moves the threshold slightly off M11.\n'], V.Nf);

fprintf('\n');
if ok
    fprintf('  ALL CHECKS PASSED — §3-4 의 주장이 수치와 맞는다.\n\n');
else
    fprintf('  ***** 불일치 있음. §3-4 를 다시 본다. *****\n\n');
end
end
