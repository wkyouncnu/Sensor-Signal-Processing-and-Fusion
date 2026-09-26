function pass = W06_check(problem, mdl)
%W06_CHECK  학생이 만든 6주차 모델을 돌려 강의의 측정값과 대조한다.
%           Run a student's Week 6 model and check it against the lecture.
%
%   W06_check(1)                W06_P1.slx 를 검사한다 / checks W06_P1.slx
%   W06_check(2, 'W06_P1_kim')  다른 모델을 검사한다 / checks another model
%   pass = W06_check(3, mdl)    모두 통과하면 true / true when every test passed
%
%   체커는 강의와 **같은 정의**로 재야 한다 (CLAUDE.md §2). 그래서 여기서는
%   전달된 힘을 로그의 추력에서 읽지 않고 **회전수에서 다시 계산한다** — 선체가
%   하는 것과 똑같이. 의도한 추력을 로그에 적어 두는 것으로는 잘못된 역곡선을
%   숨길 수 있기 때문이다.
%   The checker must measure by the lecture's definitions. Delivered force is
%   therefore recomputed from the logged SHAFT SPEEDS through the propeller
%   curve, exactly as the hull does: logging the intended thrust instead would
%   let a wrong inverse pass unseen.
%
%   무엇을 검사하는가 / what is being checked
%
%     Problem 1   the square rule: what is demanded is delivered, and the
%                 sum and difference of the thrusts are X and N       §6-2
%     Problem 2   the inverse uses the k that belongs to the sign of the
%                 thrust; a pure yaw demand produces no surge          §6-5
%     Problem 3   past the limits, clipping keeps the magnitude and loses the
%                 direction; scaling keeps the direction               §6-6
%
%   WHAT THE MODEL MUST CONTAIN
%
%     alog   To Workspace, 'Structure With Time', [X_cmd ; N_cmd ; n1 ; n2]
%            the command in N and N m, the shaft speeds in rad/s
%
%   See also W06_P1_START, W06_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W06_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W06 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W06_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  §6-2. 세 구간 모두 한계 안에 있으므로 자르기도 비율도 끼어들지 않는다.
%  All three legs fit, so neither limit rule can act. What is demanded is
%  delivered, exactly.
pass = true;
y = run_student(mdl, [0 15 30], [100 100 100], [0 20 -20], 45, 1);
s = sample(y, [10 25 40]);

fprintf('    t [s]   demanded X    N        delivered X    N        T1      T2\n');
for i = 1:3
    fprintf('    %5.0f    %9.2f %6.2f     %9.2f %6.2f  %7.2f %7.2f\n', ...
            s.t(i), s.Xc(i), s.Nc(i), s.X(i), s.N(i), s.T1(i), s.T2(i));
end
for i = 1:3
    pass = report(pass, sprintf('leg %d  delivered X', i), s.X(i), s.Xc(i), 0.05, 'N');
    pass = report(pass, sprintf('leg %d  delivered N', i), s.N(i), s.Nc(i), 0.02, 'N m');
end
pass = report(pass, 'leg 2  port thrust T1',      s.T1(2), 75.32, 0.05, 'N');
pass = report(pass, 'leg 2  starboard thrust T2', s.T2(2), 24.68, 0.05, 'N');
pass = report(pass, 'leg 2  the sum T1 + T2',     s.T1(2)+s.T2(2), 100, 0.05, 'N');
fprintf('\n     The sum of the two thrusts is X and their difference times\n');
fprintf('     y_pont is N. While the demand fits, allocation is an exact\n');
fprintf('     inverse and the vessel behaves as though force were commanded\n');
fprintf('     directly — which is what Weeks 3 to 5 assumed. (6-2)\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  §6-5. 후진과 순수 요. k_pos 를 양쪽에 쓰면 후진이 0.582 배로 짧아지고,
%  순수 요 요구가 surge 를 만든다.
pass = true;
cfg = otter_config('base');
y = run_student(mdl, [0 15 30 45], [100 -100 0 0], [0 0 20 -20], 60, 1);
s = sample(y, [10 25 40 55]);

fprintf('    t [s]   demanded X      N       delivered X      N\n');
for i = 1:4
    fprintf('    %5.0f    %9.1f %6.2f     %9.2f %6.2f\n', ...
            s.t(i), s.Xc(i), s.Nc(i), s.X(i), s.N(i));
end
pass = report(pass, 'ahead  100 N delivered',  s.X(1), 100, 0.05, 'N');
pass = report(pass, 'astern -100 N delivered', s.X(2), -100, 0.05, 'N');
pass = report(pass, 'pure yaw  +20 N m',       s.N(3),  20, 0.02, 'N m');
pass = report(pass, 'pure yaw  -20 N m',       s.N(4), -20, 0.02, 'N m');
%  진짜 시험은 이것이다: 아무도 요구하지 않은 surge 가 나오는가.
pass = report(pass, 'surge during +yaw (none asked for)', s.X(3), 0, 0.05, 'N');
pass = report(pass, 'surge during -yaw (none asked for)', s.X(4), 0, 0.05, 'N');
fprintf('\n     With k_pos used in both directions the astern leg would deliver\n');
fprintf('     %.2f N of the -100 asked for, a ratio of %.3f = k_neg/k_pos, and\n', ...
        -100*cfg.k_neg/cfg.k_pos, cfg.k_neg/cfg.k_pos);
fprintf('     each pure-yaw leg would produce 10.59 N of surge that nobody\n');
fprintf('     asked for: one propeller of the pair falls short, so the pair no\n');
fprintf('     longer sums to zero. A one-step error has become cross-coupling\n');
fprintf('     between axes. (6-5)\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  §6-6. 같은 요구를 두 규칙으로. 자르기는 크기를, 비율은 방향을 지킨다.
pass = true;
A = sample(run_student(mdl, [0 15 30 45], [220 220 100 -220], [0 50 50 0], 60, 0), ...
           [10 25 40 55]);                                    % fit_mode = 0, clip
B = sample(run_student(mdl, [0 15 30 45], [220 220 100 -220], [0 50 50 0], 60, 1), ...
           [10 25 40 55]);                                    % fit_mode = 1, scale

fprintf('    t [s]   demanded X      N    X/N      clip X      N    X/N     scale X      N    X/N\n');
for i = 1:4
    fprintf('    %5.0f    %8.1f %6.1f %6s   %8.1f %6.1f %6s    %8.1f %6.1f %6s\n', ...
            A.t(i), A.Xc(i), A.Nc(i), rat(A.Xc(i), A.Nc(i)), ...
            A.X(i), A.N(i), rat(A.X(i), A.N(i)), B.X(i), B.N(i), rat(B.X(i), B.N(i)));
end
%  1구간: 220 N 의 surge 뿐 — 110 N 씩이라 한계 안이다. 두 규칙이 같아야 한다.
pass = report(pass, 'leg 1  surge alone, clip',  A.X(1), 220, 0.5, 'N');
pass = report(pass, 'leg 1  surge alone, scale', B.X(1), 220, 0.5, 'N');
%  2구간: 여기가 갈라지는 자리다.
pass = report(pass, 'leg 2  clip  delivers X',  A.X(2), 166.4, 0.5, 'N');
pass = report(pass, 'leg 2  clip  delivers N',  A.N(2),  28.8, 0.3, 'N m');
pass = report(pass, 'leg 2  scale delivers X',  B.X(2), 151.9, 0.5, 'N');
pass = report(pass, 'leg 2  scale delivers N',  B.N(2),  34.5, 0.3, 'N m');
pass = report(pass, 'leg 2  clip  turns the force,  X/N', A.X(2)/A.N(2), 5.77, 0.08, '-');
pass = report(pass, 'leg 2  scale keeps it,         X/N', B.X(2)/B.N(2), 4.40, 0.05, '-');
%  3구간: (100, 50) 은 113.3 N 이므로 들어간다. 두 규칙과 요구가 모두 같아야 한다.
pass = report(pass, 'leg 3  it fits, clip  = demand',  A.X(3), 100, 0.5, 'N');
pass = report(pass, 'leg 3  it fits, scale = demand',  B.X(3), 100, 0.5, 'N');
%  4구간: 후진만. N = 0 이면 두 규칙이 일치한다.
pass = report(pass, 'leg 4  astern, clip',  A.X(4), -133.4, 0.5, 'N');
pass = report(pass, 'leg 4  astern, scale', B.X(4), -133.4, 0.5, 'N');
fprintf('\n     Saturation does not simply weaken a command; it TURNS it. On\n');
fprintf('     leg 2 clipping delivers more force (166.4 against 151.9 N) and\n');
fprintf('     less moment (28.8 against 34.5 N m), so the ratio moves from the\n');
fprintf('     4.40 that was asked for to 5.77. Scaling gives up 14.5 N and\n');
fprintf('     keeps the direction exactly. Neither is right in general, and\n');
fprintf('     the controller upstream is never told which was used. (6-6)\n');
end

% =========================================================================
function y = run_student(mdl, T_SW, X_SEQ, N_SEQ, T_final, fit_mode)
cfg = otter_config('base');
b = 'base';
assignin(b,'h',0.02);            assignin(b,'T_final',T_final);
assignin(b,'T_SW',T_SW(:));      assignin(b,'X_SEQ',X_SEQ(:));
assignin(b,'N_SEQ',N_SEQ(:));    assignin(b,'fit_mode',fit_mode);
assignin(b,'y_pont',cfg.y_pont);
assignin(b,'k_pos',cfg.k_pos);   assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max);   assignin(b,'n_min',cfg.n_min);
assignin(b,'T_max',cfg.k_pos*cfg.n_max^2);
assignin(b,'T_min',-cfg.k_neg*cfg.n_min^2);
assignin(b,'mp',25);             assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);             assignin(b,'beta_c',0);
assignin(b,'x0',zeros(12,1));

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
need(mdl,'alog');
evalin(b, sprintf('sim(''%s'');', mdl));

A = grab(evalin(b,'alog'), 4, 'alog');
S = evalin(b,'alog');
y.t  = S.time;
y.Xc = A(:,1);  y.Nc = A(:,2);  y.n1 = A(:,3);  y.n2 = A(:,4);
%  선체가 하는 것과 똑같이, 회전수에서 추력을 / the thrust, as the hull makes it
y.T1 = curve(y.n1, cfg);  y.T2 = curve(y.n2, cfg);
y.X  = y.T1 + y.T2;
y.N  = cfg.y_pont*(y.T1 - y.T2);
end

function T = curve(n, cfg)
k = cfg.k_pos*ones(size(n));   k(n < 0) = cfg.k_neg;
T = k .* n .* abs(n);
end

function s = sample(y, tq)
s.t = tq(:);
f = {'Xc','Nc','T1','T2','X','N'};
for j = 1:numel(f)
    s.(f{j}) = zeros(numel(tq),1);
    for i = 1:numel(tq)
        [~, k] = min(abs(y.t - tq(i)));
        s.(f{j})(i) = y.(f{j})(k);
    end
end
end

function r = rat(a, b)
if abs(b) < 1e-6, r = '--'; else, r = sprintf('%.2f', a/b); end
end

function need(mdl, name)
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName',name))
    error('W06_check:noLog', ...
      ['The model has no To Workspace block whose variable name is %s.\n' ...
       'It must carry [X_cmd ; N_cmd ; n1 ; n2] with Save format\n' ...
       '''Structure With Time''.'], name);
end
end

function M = grab(S, w, name)
M = squeeze(S.signals.values);
if size(M,1) == w, M = M.'; end
if size(M,2) ~= w
    error('W06_check:width', '%s has %d columns; %d were expected.', ...
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
