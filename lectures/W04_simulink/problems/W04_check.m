function pass = W04_check(problem, mdl)
%W04_CHECK  학생이 만든 4주차 모델을 돌려 강의의 측정값과 대조한다.
%           Run a student's Week 4 model and check it against the lecture.
%
%   W04_check(1)                W04_P1.slx 를 검사한다 / checks W04_P1.slx
%   W04_check(2, 'W04_P1_kim')  다른 모델을 검사한다 / checks another model
%   pass = W04_check(3, mdl)    모두 통과하면 true / true when every test passed
%
%   목표값은 모두 강의 절 스크립트가 잰 것이다 (10 도 선회, t_step = 5 s).
%   Every target was measured by the lecture's section scripts (a 10 deg turn at 5 s).
%
%     Problem 1   P only: steady error 0 at every gain;
%                 overshoot 5.8 % at Kp = 100, 12.2 % at Kp = 300          §D
%     Problem 2   filtered D on the error, Kp = 300:
%                 overshoot 12.18 / 4.10 / 0.39 % at Kd = 0 / 50 / 100     §E
%     Problem 3   the wrap: from 170 deg, command -170 deg:
%                 a 20 deg turn with ssa, 340 deg the other way without     §G
%
%   모델에 필요한 것 / what the model must contain
%     xlog   To Workspace, 'Structure With Time', the plant's 12 states
%     변수 이름 / variable names: Kp, Ki, Kd, Nf, use_ssa, psi_step, t_step
%
%   See also W04_P1_START, W04_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W04_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W04 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W04_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  P 만. 모든 게인에서 정상상태 오차가 0 이다 — 3주차와의 차이 / P only: no error at any gain
pass = true;
G = [100 300];  WANT = [5.8 12.2];
for i = 1:2
    y = run_student(mdl, struct('Kp',G(i), 'Kd',0));
    pass = report(pass, sprintf('steady error at Kp = %g', G(i)), 10 - y.psi(end), 0, 0.05, 'deg');
    [Mp, ~] = step_metrics(y.t, y.psi, 10, 5);
    pass = report(pass, sprintf('   overshoot at Kp = %g', G(i)), Mp, WANT(i), 0.5, '%');
end
fprintf('\n     No error at any gain: the heading is the sum of the turn rate, so\n');
fprintf('     the plant already contains an integrator. Week 3 left an error at\n');
fprintf('     every gain. And unlike Week 3, a larger gain rings more.\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  거른 미분 Kd Nf s/(s + Nf) 를 오차에 / the filtered derivative on the error
pass = true;
K = [0 50 100];  WANT = [12.18 4.10 0.39];
for i = 1:3
    y = run_student(mdl, struct('Kp',300, 'Kd',K(i)));
    [Mp, ~] = step_metrics(y.t, y.psi, 10, 5);
    pass = report(pass, sprintf('overshoot at Kd = %g', K(i)), max(Mp,0), WANT(i), 0.5, '%');
end
fprintf('\n     On the heading the derivative damps, as on the mass of Week 2 —\n');
fprintf('     and unlike the speed loop of Week 3, where it made things worse.\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  감김: 170 도에서 -170 도로. 두 실행 모두 t = 0 에 같은 오차로 시작한다
%  The wrap: from 170 deg to -170 deg; both runs start at t = 0 with the same error
pass = true;
x0 = zeros(12,1);  x0(12) = deg2rad(170);
V = struct('Kp',300, 'Kd',100, 'psi_step',-170, 't_step',0, 'T_final',60);
V.use_ssa = 1;  yOn  = run_student(mdl, V, x0);
V.use_ssa = 0;  yOff = run_student(mdl, V, x0);
pass = report(pass, 'turn WITH the wrap',    yOn.psi(end)  - 170,   20,  3.0, 'deg');
pass = report(pass, 'turn WITHOUT the wrap', yOff.psi(end) - 170, -340, 12.0, 'deg');
fprintf('\n     With ssa the vessel turns 20 deg through the seam; without it,\n');
fprintf('     340 deg the other way for the same commanded heading.\n');
end

% =========================================================================
function y = run_student(mdl, V, x0)
if nargin < 3, x0 = zeros(12,1); end
D = struct('Kp',300, 'Ki',0, 'Kd',0, 'Nf',20, 'use_ssa',1, 'psi_step',10, 't_step',5, 'T_final',40);
f = fieldnames(V);
for i = 1:numel(f), D.(f{i}) = V.(f{i}); end
cfg = otter_config('base');
b = 'base';
f = fieldnames(D);
for i = 1:numel(f), assignin(b, f{i}, D.(f{i})); end
assignin(b,'h',0.02);          assignin(b,'X_ff',60);
assignin(b,'k_pos',cfg.k_pos); assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max); assignin(b,'n_min',cfg.n_min);
assignin(b,'y_pont',cfg.y_pont);
assignin(b,'mp',25);           assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);           assignin(b,'beta_c',0);
assignin(b,'x0',x0);

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName','xlog'))
    error('W04_check:noLog', ...
      ['The model has no To Workspace block whose variable name is xlog.\n' ...
       'Add one, feed it the plant''s 12-state output, and set its format\n' ...
       'to ''Structure With Time''.']);
end
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b,'xlog');
x = squeeze(S.signals.values);  if size(x,1)==12, x = x.'; end
if size(x,2) < 12
    error('W04_check:width', 'xlog has %d columns; feed it all 12 states.', size(x,2));
end
%  psi 를 감지 않는다 — 문제 3 은 실제로 돈 각이 필요하다
%  psi is not wrapped: problem 3 needs the accumulated turn
y.t = S.time;  y.psi = rad2deg(x(:,12));
end

function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
if good, verdict = 'PASS'; else, verdict = 'FAIL'; end
fprintf('  %-38s %9.4f  (expected %8.4f +- %.3g %s)  %s\n', what, got, want, tol, unit, verdict);
ok = ok && good;
end
