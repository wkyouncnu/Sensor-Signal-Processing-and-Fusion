function pass = W07_check(problem, mdl)
%W07_CHECK  학생이 만든 7주차 모델을 돌려 강의의 측정값과 대조한다.
%           Run a student's Week 7 model and check it against the lecture.
%
%   W07_check(1)                W07_P1.slx 를 검사한다 / checks W07_P1.slx
%   W07_check(2, 'W07_P1_kim')  다른 모델을 검사한다 / checks another model
%   pass = W07_check(3, mdl)    모두 통과하면 true / true when every test passed
%
%   체커는 강의와 **같은 정의**로 잰다 (CLAUDE.md §2): 표준편차는 모두 t > 20 s
%   구간이고, 계단 지표는 `step_metrics` 가 강의와 같은 시종점 정의로 낸다.
%   The checker measures by the lecture's definitions: every standard deviation
%   is taken over t > 20 s, and the step metrics come from `step_metrics`, the
%   same function and the same endpoint definition the lecture used.
%
%   필터를 **끄는 방법** / how the filter is switched off
%       블록을 빼지 않는다. zeta_n = zeta_d 로 두면 H(s) = 1 이 되어 같은 모델이
%       필터 없는 모델을 정확히 재현한다 (§7-4 줄 4). 그래야 비교가 정직하다.
%       No block is removed. Setting zeta_n = zeta_d makes H(s) = 1 identically,
%       so one model reproduces the unfiltered one exactly — which is what keeps
%       the comparison honest.
%
%   무엇을 검사하는가 / what is being checked
%
%     Problem 1   the notch: heading std 1.551 -> 1.042 deg and moment std
%                 18.85 -> 13.41 N m, on the same sea and the same gains  §7-4
%     Problem 2   what it costs: with the sea off, overshoot 0.93 -> 9.07 %
%                 and settling 1.72 -> 7.76 s                             §7-5
%     Problem 3   the slow part is passed, and the integral removes it:
%                 3.071 -> 0.084 deg against the same -15.13 N m          §7-6
%
%   WHAT THE MODEL MUST CONTAIN
%
%     flog   To Workspace, 'Structure With Time', [psi_m ; psi_f ; N]
%            the measurement and what the controller uses, both in deg,
%            and the moment it asks for, in N m
%
%   See also W07_P1_START, W07_0_SETUP, STEP_METRICS.

if nargin < 2 || isempty(mdl), mdl = 'W07_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W07 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W07_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  §7-4. 같은 바다, 같은 게인. 달라지는 것은 두 수 zeta_n, zeta_d 뿐이다.
pass = true;
V = base_setup();
A = run_student(mdl, V, 'zeta_n', V.zeta_d);      % 필터 없음 / H(s) = 1
B = run_student(mdl, V, 'zeta_n', 0.05);          % 노치 / the notch

fprintf('    %-12s  heading std   moment std   moment max   what it filters\n', 'filter');
NM = {'none','notch'};  RUN = {A, B};
for i = 1:2
    R = RUN{i};
    fprintf('    %-12s %9.3f deg %11.2f Nm %10.2f Nm %12.3f deg\n', NM{i}, ...
            R.psi_std, R.N_std, R.N_max, R.cut);
end
%  ① 파랑이 실제로 섞여 있는가. 이 구간에서 잰 값이므로 sigma_psi = 3 도의
%     유한표본 추정이다 — 정확히 3.008 이 나오는 것은 전체 구간이다 (§7-2).
%     The wave really is in the measurement. Measured over this window it is a
%     finite-sample estimate of sigma_psi = 3 deg; the 3.008 of §7-2 is the
%     whole run.
pass = report(pass, 'the wave is in the measurement', A.wave_std, 3.0, 0.30, 'deg');
%  ② 필터를 끄면 psi_f 가 psi_m 과 **정확히** 같아야 한다 (H(s) = 1)
pass = report(pass, 'zeta_n = zeta_d leaves it untouched', A.cut, 0, 1e-6, 'deg');
%  ③ 필터를 넣으면 무언가를 실제로 덜어 내야 한다
if B.cut > 0.5
    fprintf('  %-42s %9s  %s\n', 'the notch is actually in the loop', '', 'PASS');
else
    fprintf('  %-42s %9.4f  %s\n', 'the notch removes nothing — is it wired?', B.cut, 'FAIL');
    pass = false;
end
%  ④ 그리고 강의가 잰 네 수
pass = report(pass, 'no filter   heading std', A.psi_std, 1.551, 0.03, 'deg');
pass = report(pass, 'notch       heading std', B.psi_std, 1.042, 0.03, 'deg');
pass = report(pass, 'no filter   moment std',  A.N_std,  18.85, 0.40, 'N m');
pass = report(pass, 'notch       moment std',  B.N_std,  13.41, 0.40, 'N m');
fprintf('\n     |H(j w0)| = zeta_n/zeta_d = %.3f, which is %.1f dB, and every\n', ...
        0.05/V.zeta_d, 20*log10(0.05/V.zeta_d));
fprintf('     column of the table improves at once. Nothing was retuned: the\n');
fprintf('     vessel steers better because it is no longer being shaken. (7-4)\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  §7-5. 바다를 끄고 같은 10 도 계단. 감쇠를 사서 위상으로 갚는다.
pass = true;
V = base_setup();  V.wave_on = 0;  V.T_final = 40;  V.N_slow = 0;
A = run_student(mdl, V, 'zeta_n', V.zeta_d);
B = run_student(mdl, V, 'zeta_n', 0.05);

s = tf('s');
fprintf('    %-12s  overshoot   rise [s]   settle [s]   phase of H at 1.6 rad/s\n', 'filter');
NM = {'none','notch'};  RUN = {A, B};  ZN = [V.zeta_d 0.05];
for i = 1:2
    H = (s^2 + 2*ZN(i)*V.w0*s + V.w0^2)/(s^2 + 2*V.zeta_d*V.w0*s + V.w0^2);
    [~, ph] = bode(H, 1.6);
    fprintf('    %-12s %9.2f %% %9.2f %11.2f %17.1f deg\n', NM{i}, ...
            RUN{i}.Mp, RUN{i}.tr, RUN{i}.ts, ph);
end
pass = report(pass, 'no filter   overshoot', A.Mp, 0.93, 0.35, '%');
pass = report(pass, 'no filter   settling',  A.ts, 1.72, 0.30, 's');
pass = report(pass, 'notch       overshoot', B.Mp, 9.07, 1.20, '%');
pass = report(pass, 'notch       settling',  B.ts, 7.76, 1.20, 's');
if B.Mp > 4*A.Mp
    fprintf('  %-42s %9s  %s\n', 'the filter makes this manoeuvre worse', '', 'PASS');
else
    fprintf('  %-42s %9s  %s\n', 'the filter should cost a visible overshoot', '', 'FAIL');
    pass = false;
end
fprintf('\n     The filter that improved every column of Problem 1 makes this\n');
fprintf('     manoeuvre visibly worse, and both are true at once. The notch\n');
fprintf('     buys its attenuation with phase, and phase is what damping is\n');
fprintf('     made of — Week 2 §2-10, paid a second time. (7-5)\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  §7-6. 느린 외란 15 N m. 노치가 그것을 통과시키므로 적분이 없앨 수 있다.
pass = true;
%  구간은 t > 60 s — 강의 §7-6 과 같다. 느린 외란이 60 s 로 변하므로 한 주기를
%  다 본 뒤라야 "평균" 이 뜻을 가진다 / the lecture's window: the disturbance
%  varies over 60 s, so a mean means nothing before one period has passed.
V = base_setup();  V.N_slow = 15;  V.T_final = 120;
A = run_student(mdl, V, 'zeta_n', 0.05, 'Ki', 0,  'win', 60);   % P-D
B = run_student(mdl, V, 'zeta_n', 0.05, 'Ki', 20, 'win', 60);   % PI-D

fprintf('    %-22s  mean heading error   mean moment   heading std\n', 'controller');
fprintf('    %-22s %13.3f deg %13.2f Nm %10.3f deg\n', 'P-D  (Ki = 0)', A.err, A.N_mean, A.psi_std);
fprintf('    %-22s %13.3f deg %13.2f Nm %10.3f deg\n', 'PI-D', B.err, B.N_mean, B.psi_std);
pass = report(pass, 'P-D  settles off the command',  A.err,  3.071, 0.30, 'deg');
pass = report(pass, 'PI-D settles on it',            B.err,  0.084, 0.25, 'deg');
pass = report(pass, 'P-D  mean moment',              A.N_mean, -15.13, 0.60, 'N m');
pass = report(pass, 'PI-D mean moment',              B.N_mean, -15.13, 0.60, 'N m');
%  적분이 파랑을 쌓지 않는다는 것 — 잔물결이 양쪽에서 같아야 한다
pass = report(pass, 'the ripple is the same on both', B.psi_std - A.psi_std, 0, 0.06, 'deg');
fprintf('\n     The notch is unity two decades below w0, so it PASSES the slow\n');
fprintf('     push and the loop can oppose it. The wave has zero mean, so the\n');
fprintf('     integral does not accumulate it — which is why a notch and an\n');
fprintf('     integral can be used together. The two halves of the sea leave\n');
fprintf('     by two different doors. (7-6)\n');
end

% =========================================================================
function V = base_setup()
cfg = otter_config('base');
V.Hs = 0.3;  V.T0 = 2.0;  V.gamma_j = 3.3;  V.N_comp = 20;  V.sigma_psi = 3;
V.w0 = 2*pi/V.T0;  V.wave_on = 1;
V.zeta_n = 0.05;  V.zeta_d = 0.3;
V.Kp = 300;  V.Kd = 100;  V.Ki = 0;  V.Kb = 0.1;
V.X_ff = 60;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_ff/2), ...
              2*cfg.y_pont*(V.X_ff/2 + cfg.k_neg*cfg.n_min^2));
V.psi_step = 10;  V.t_step = 5;
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.x0 = zeros(12,1);
V.N_slow = 0;  V.T_slow = 60;  V.V_c = 0;  V.beta_c = pi/2;
V.h = 0.02;  V.T_final = 60;
end

function y = run_student(mdl, V, varargin)
win = 20;                                     % 기본 구간 / the default window
for i = 1:2:numel(varargin)
    if strcmp(varargin{i}, 'win'), win = varargin{i+1};
    else, V.(varargin{i}) = varargin{i+1}; end
end
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
b = 'base';
f = fieldnames(V);
for i = 1:numel(f), assignin(b, f{i}, V.(f{i})); end

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
need(mdl,'flog');
evalin(b, sprintf('sim(''%s'');', mdl));

F = grab(evalin(b,'flog'), 3, 'flog');
X = grab(evalin(b,'xlog'), 12, 'xlog');
S = evalin(b,'flog');
t = S.time;
psi = X(:,12)*180/pi;
y.t = t;  y.psi = psi;  y.psi_m = F(:,1);  y.psi_f = F(:,2);  y.N = F(:,3);

j = t > win;                                  % 강의와 같은 구간 / the lecture's window
y.psi_std  = std(psi(j));
y.N_std    = std(y.N(j));
y.N_max    = max(abs(y.N(j)));
y.wave_std = std(y.psi_m(j) - psi(j));        % 계측에 섞인 파랑 / the wave in the measurement
y.cut      = std(y.psi_m(j) - y.psi_f(j));    % 필터가 덜어 낸 것 / what the filter removed
%  강의 §7-6 과 같은 부호: 명령보다 **얼마나 위에** 앉는가
%  The lecture's sign: how far ABOVE the command it settles.
y.err      = mean(psi(j)) - V.psi_step;
y.N_mean   = mean(y.N(j));
[y.Mp, y.ts, y.tr] = step_metrics(t, psi, V.psi_step, V.t_step);
end

function need(mdl, name)
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName',name))
    error('W07_check:noLog', ...
      ['The model has no To Workspace block whose variable name is %s.\n' ...
       'It must carry [psi_m ; psi_f ; N] with Save format\n' ...
       '''Structure With Time''.'], name);
end
end

function M = grab(S, w, name)
M = squeeze(S.signals.values);
if size(M,1) == w, M = M.'; end
if size(M,2) ~= w
    error('W07_check:width', '%s has %d columns; %d were expected.', ...
          name, size(M,2), w);
end
end

function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
if good, verdict = 'PASS'; else, verdict = 'FAIL'; end
fprintf('  %-42s %9.3f  (expected %8.3f +- %.3g %s)  %s\n', ...
        what, got, want, tol, unit, verdict);
ok = ok && good;
end
