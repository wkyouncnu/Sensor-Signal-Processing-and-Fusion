function ok = verify_w02_pid()
%VERIFY_W02_PID  2주차 강의가 싣는 식을 모델과 독립적으로 다시 계산해 대조한다.
%                Recompute the equations of Week 2 independently and check them.
%
%   ok = verify_w02_pid()
%
%   강의에서의 위치 / place in the lecture
%       2주차 Part 1 의 식들(§2-3 ~ §2-10)이 옳은지 확인한다. 절 스크립트는 모델을
%       돌려 수를 잰다. 이 함수는 같은 수를 전달함수와 대수로 다시 구해, 두 길이
%       같은 답에 닿는지 본다.
%       Checks the equations of Part 1 of Week 2 (§2-3 to §2-10). The section
%       scripts measure numbers by running the model; this recomputes the same
%       numbers from transfer functions and algebra, to see whether the two
%       routes arrive at the same answer.
%
%   검사 / checks
%     1  W02_vars 와 W02_0_setup 의 값이 같다 / the two parameter files agree
%     2  P 제어: 정상상태값 Kp/(k+Kp), 감쇠비, 오버슛 공식이 전달함수의 계단응답과 같다
%        P control: steady value, damping ratio and overshoot formula match
%        the step response of the transfer function
%     3  오버슛에서 감쇠비를 되찾는 식이 정확한 역함수이다 (절 I 가 쓴다)
%        the formula recovering zeta from the overshoot is an exact inverse
%     4  Routh 한계 Ki = (b + Kd)(k + Kp)/m 에서 극점 한 쌍이 정확히 +-j sqrt(k + Kp) 에 있다
%        at the Routh limit a pole pair sits exactly at +-j sqrt(k + Kp)
%     5  미분 필터: 적분기를 되먹임에 둔 구현 Nf/(1 + Nf/s) 이 Nf s/(s + Nf) 와 같다
%        (MATLAB Tech Talk 3편), 높은 주파수에서 이득은 Nf 에서 멈춘다
%        the integrator-in-the-feedback realisation equals Nf s/(s + Nf)
%        (Tech Talk part 3), and its gain stops at Nf at high frequency
%     6  미분 킥: 거른 미분의 단위 계단 응답은 t = 0+ 에서 Kd Nf 이다
%        the derivative kick: the filtered derivative of a unit step starts at Kd Nf
%     7  샘플 시간: 불안정해지는 첫 Ts 를 촘촘한 격자로 다시 찾아 절 J 의 이분법과 대조
%        the first unstable sample time, found again on a fine grid
%     8  손으로 만든 PID 와 PID 블록이 포화와 잡음 아래에서도 반올림 오차 안에서 같다
%        the hand-built PID equals the PID block under saturation and noise

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W02_simulink');
addpath(wk);
ok = true;
fprintf('\n  verify_w02_pid\n\n');

%% 1 ----------------------------------------------------------------------
V = W02_vars();
S = setup_values(wk);
f = fieldnames(V);  bad = {};
for i = 1:numel(f)
    if ~isfield(S, f{i}) || ~isequal(S.(f{i}), V.(f{i})), bad{end+1} = f{i}; end %#ok<AGROW>
end
ok = report(ok, '1 W02_vars = W02_0_setup', isempty(bad), strjoin(bad, ', '));

%% 2 ----------------------------------------------------------------------
s = tf('s');  m = V.pid_m;  b = V.pid_b;  k = V.pid_k;
G = 1/(m*s^2 + b*s + k);
t = (0:1e-4:20)';
worst = 0;
for Kp = [2 10 50]
    y  = step(feedback(Kp*G, 1), t);
    ys = Kp/(k + Kp);
    z  = b/(2*sqrt(m*(k + Kp)));
    Mf = 100*exp(-pi*z/sqrt(1 - z^2));
    Mm = 100*(max(y) - ys)/ys;
    worst = max([worst, abs(y(end) - ys), abs(Mm - Mf)/100]);
end
ok = report(ok, '2 P-only steady value and overshoot formula', worst < 1e-5, sprintf('%.1e', worst));

%% 3 ----------------------------------------------------------------------
zz = linspace(0.05, 0.95, 19);
Mp = exp(-pi*zz./sqrt(1 - zz.^2));
zb = -log(Mp)./sqrt(pi^2 + log(Mp).^2);
ok = report(ok, '3 zeta from overshoot is the exact inverse', max(abs(zb - zz)) < 1e-12, ...
            sprintf('%.1e', max(abs(zb - zz))));

%% 4 ----------------------------------------------------------------------
Kp = 10;  Kd = 4;
KiR = (b + Kd)*(k + Kp)/m;
p = pole(feedback((Kp + KiR/s + Kd*s)*G, 1));
[~, j] = min(abs(real(p)));
okr = abs(real(p(j))) < 1e-9 && abs(abs(imag(p(j))) - sqrt((k + Kp)/m)) < 1e-9 && KiR == 72;
ok = report(ok, '4 Routh limit Ki = 72, poles at +-j sqrt(12)', okr, ...
            sprintf('Ki = %g, pole %.3g%+.6fj', KiR, real(p(j)), imag(p(j))));

%% 5 ----------------------------------------------------------------------
Nf  = V.Nf;
Df  = Nf*s/(s + Nf);
Dl  = feedback(tf(Nf), 1/s);                   % Nf forward, integrator in the feedback
dif = norm(minreal(Df - Dl, 1e-9), inf);
hi  = abs(freqresp(Df, 1e5));
lo  = abs(freqresp(Df, 1e-2));
ok5 = dif < 1e-9 && abs(hi - Nf)/Nf < 1e-3 && abs(lo - 1e-2)/1e-2 < 1e-3;
ok = report(ok, '5 integrator-feedback form = Nf s/(s+Nf); ceiling Nf', ok5, ...
            sprintf('diff %.1e, |D(j1e5)| = %.3f, |D(j0.01)| = %.5f', dif, hi, lo));

%% 6 ----------------------------------------------------------------------
yk = step(V.Kd*Df, [0 1e-9]);
ok = report(ok, '6 kick of a unit step = Kd Nf', abs(yk(1) - V.Kd*Nf) < 1e-6, ...
            sprintf('%.6f vs %g', yk(1), V.Kd*Nf));

%% 7 ----------------------------------------------------------------------
C  = V.Kp + V.Ki/s + V.Kd*Nf*s/(s + Nf);
TS = 0.01:0.0005:0.8;
pm = arrayfun(@(T) max(abs(pole(feedback(c2d(C,T,'tustin')*c2d(G,T,'zoh'), 1)))), TS);
Tfirst = TS(find(pm >= 1, 1));
ok = report(ok, '7 first unstable sample time (grid)', abs(Tfirst - 0.511) <= 0.001, ...
            sprintf('%.4f s (section J bisection: 0.511 s)', Tfirst));

%% 8 ----------------------------------------------------------------------
if ~isfile(fullfile(wk, 'W02_F_block_vs_hand.slx')), W02_1_build_pid('W02_F_block_vs_hand'); end
R = W02_read('W02_F_block_vs_hand', 'tau_max', 2.5, 'noise_std', 0.005);
d8 = max([abs(R.y - R.y_blk); abs(R.tau - R.tau_blk)]);
ok = report(ok, '8 hand-built = PID block (saturation, noise)', d8 < 1e-12, sprintf('%.1e', d8));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

% -------------------------------------------------------------------------
function S = setup_values(wk)
%  W02_0_setup 은 clear 로 시작하는 스크립트이다. 이 함수 안에서 돌리면 이 함수의
%  작업공간만 지워지므로 안전하다.
%  W02_0_setup starts with clear; run here, it clears only this function's workspace.
evalc('run(fullfile(wk, ''W02_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-52s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
