function pass = W02_check(problem, mdl)
%W02_CHECK  학생 모델을 돌려 강의에서 잰 수치와 대조하고 PASS/FAIL 을 낸다.
%           Run a student model, compare it with the lecture's measured numbers,
%           and report PASS or FAIL.
%
%   >> W02_check(1)                 W02_P1.slx 의 문제 1 / problem 1 on W02_P1.slx
%   >> W02_check(2, 'W02_P1_kim')   다른 모델 / another model
%
%   왜 수치로 채점하는가 / why the marking is numerical
%       정답 도면은 하나가 아니다. 블록을 어떻게 놓든, 같은 식을 구현했으면 같은
%       응답이 나온다. 그래서 모양이 아니라 응답을 강의의 절 스크립트가 잰 수와
%       대조한다. 재는 방법도 강의와 같다 — 오버슛은 _tools/step_metrics, 1 % 정착은
%       W02_I_tuning_by_hand 와 같은 정의.
%       There is no single correct drawing. However the blocks are placed, a
%       model implementing the same equations gives the same response, so the
%       response - not the layout - is compared with the numbers the lecture's
%       section scripts measured, by the same definitions: overshoot from
%       _tools/step_metrics, 1 % settling as in W02_I_tuning_by_hand.
%
%   문제별 합격선 / pass marks
%       1  Kp = 2 과 10 에서 정상상태값과 오버슛 (절 C)
%          steady value and overshoot at Kp = 2 and 10 (section C)
%       2  Kp = 10, Kd = 6, Ki = 8, Nf = 20 에서 오버슛, 1 % 정착, 가장 큰 힘 (절 I),
%          그리고 모델에 PID 블록과 Derivative 블록이 없을 것
%          overshoot, 1 % settling and peak force (section I), and no PID
%          Controller block and no Derivative block in the model
%       3  |tau| <= 2.5 에서 Kb = 0 과 2 의 오버슛과 정착 (절 H)
%          overshoot and settling with Kb = 0 and 2 at |tau| <= 2.5 (section H)

if nargin < 2 || isempty(mdl), mdl = 'W02_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);

fprintf('\n  W02 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W02_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
pass = true;
KP = [2 10];  YSS = [0.500 0.833];  MP = [16.3 38.8];
for i = 1:2
    y = run_student(mdl, struct('Kp',KP(i), 'Ki',0, 'Kd',0));
    yss = mean(y.y(y.t > 9));
    Mp  = step_metrics(y.t, y.y, yss, 1);
    pass = report(pass, sprintf('steady value at Kp = %g', KP(i)), yss, YSS(i), 0.005, 'm');
    pass = report(pass, sprintf('   overshoot at Kp = %g', KP(i)), Mp, MP(i), 0.5, '%');
end
fprintf(['\n     The steady value is Kp/(k + Kp), never 1: the spring needs a steady\n' ...
         '     force k y, and a proportional controller makes force only from\n' ...
         '     error. A larger Kp leaves less error and rings more.\n']);
end

function pass = check_p2(mdl)
pass = true;
nPID = numel(find_system(mdl, 'LookUnderMasks','all', 'MaskType','PID 1dof'));
nDer = numel(find_system(mdl, 'LookUnderMasks','all', 'BlockType','Derivative'));
okS  = nPID == 0 && nDer == 0;
fprintf('  %-38s %s   (PID blocks %d, Derivative blocks %d)\n', ...
        'built by hand, no PID or Derivative', verdict(okS), nPID, nDer);
pass = pass && okS;
y = run_student(mdl, struct('Kp',10, 'Ki',8, 'Kd',6));
pass = report(pass, 'overshoot', step_metrics(y.t, y.y, 1, 1), 0.16, 0.3, '%');
pass = report(pass, 'inside 1 % of the setpoint after', settle1(y), 2.77, 0.10, 's');
pass = report(pass, 'largest force', max(abs(y.tau)), 129.6, 1.5, 'N');
fprintf(['\n     These are the gains the tuning order of section I arrived at:\n' ...
         '     Kp from the units, Kd where the overshoot stopped falling, Ki\n' ...
         '     until the error was gone in time. The peak force is the\n' ...
         '     derivative kick, Kd Nf + Kp = 130 N at the corner of the step.\n']);
end

function pass = check_p3(mdl)
pass = true;
y0 = run_student(mdl, struct('Kp',10, 'Ki',8, 'Kd',4, 'tau_max',2.5, 'Kb',0));
y2 = run_student(mdl, struct('Kp',10, 'Ki',8, 'Kd',4, 'tau_max',2.5, 'Kb',2));
pass = report(pass, 'largest force', max(abs(y2.tau)), 2.5, 1e-6, 'N');
[M0, t0] = step_metrics(y0.t, y0.y, 1, 1);
[M2, t2] = step_metrics(y2.t, y2.y, 1, 1);
pass = report(pass, 'overshoot, Kb = 0', M0, 28.67, 0.5, '%');
pass = report(pass, 'overshoot, Kb = 2', M2, 0.03, 0.3, '%');
pass = report(pass, 'settling (2 %), Kb = 0', t0, 5.54, 0.10, 's');
pass = report(pass, 'settling (2 %), Kb = 2', t2, 3.56, 0.10, 's');
fprintf(['\n     Same gains, same limit. Without back-calculation the integrator\n' ...
         '     stores what the actuator could not deliver and pays it back as\n' ...
         '     overshoot. With it, the integrator is told how much was cut off.\n']);
end

% =========================================================================
function y = run_student(mdl, G)
b = 'base';
%  모든 이름을 강의 기본값으로. W02_0_setup 을 부르지 않는 것은 그 첫 줄의 clear 와
%  close all 이 학생의 작업공간과 그림을 지우기 때문이다.
%  Every name to the lecture default. Not via W02_0_setup, whose first line
%  (clear; close all) would wipe the student's workspace and figures.
D = W02_vars();  d = fieldnames(D);
for i = 1:numel(d), assignin(b, d{i}, D.(d{i})); end
f = fieldnames(G);
for i = 1:numel(f), assignin(b, f{i}, G.(f{i})); end
evalin(b, 'clear ylog');
evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl, 'StopTime','T_final', 'ReturnWorkspaceOutputs','off', 'StopFcn','');
if isempty(find_system(mdl, 'BlockType','ToWorkspace', 'VariableName','ylog'))
    error('W02_check:noLog', ['The model has no To Workspace block named ylog. ' ...
          'W02_P1_start creates one; do not delete it.']);
end
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b, 'ylog');
v = squeeze(S.signals.values);  if size(v,1) == 3 && size(v,2) ~= 3, v = v.'; end
if size(v,2) ~= 3
    error('W02_check:width', 'ylog must have three columns [y_d tau y]; it has %d.', size(v,2));
end
y.t = S.time;  y.y_d = v(:,1);  y.tau = v(:,2);  y.y = v(:,3);
end

function ts = settle1(y)
%  W02_I_tuning_by_hand 와 같은 정의 / the definition of section I
out = find(abs(y.y - 1) > 0.01 & y.t >= 1, 1, 'last');
if isempty(out), ts = 0; elseif out == numel(y.t), ts = inf; else, ts = y.t(out) - 1; end
end

function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
fprintf('  %-38s %9.4f  (expected %8.4f +- %.3g %s)  %s\n', what, got, want, tol, unit, verdict(good));
ok = ok && good;
end

function v = verdict(g)
if g, v = 'PASS'; else, v = 'FAIL'; end
end
