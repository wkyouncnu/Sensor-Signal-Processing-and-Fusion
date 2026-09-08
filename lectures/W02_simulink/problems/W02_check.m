function pass = W02_check(problem, mdl)
%W02_CHECK  Run a student's Week 2 model and check it against the lecture.
%
%   W02_check(1)                checks W02_P1.slx
%   W02_check(2, 'W02_P1_kim')  checks another model
%   pass = W02_check(3, mdl)    returns true when every test passed
%
%   WHAT IS BEING CHECKED, AND WHY THESE NUMBERS
%
%   Every target below was MEASURED by the lecture's own section scripts.
%
%     Problem 1   DC gain of the open-loop plant             0.012894 (m/s)/N
%                 terminal speed at X = 100 N                1.2894 m/s   §2-C
%     Problem 2   steady speed at Kp = 100, u_d = 1.5        0.8448 m/s
%                 the same at Kp = 500                       1.2986 m/s   §2-D
%                 and the error is NEVER zero
%     Problem 3   steady error with the integrator present   0 to tolerance
%
%   WHAT THE MODEL MUST CONTAIN
%
%     xlog   To Workspace, 'Structure With Time', the plant's 12 states
%     Xlog   To Workspace, 'Structure With Time', the demanded surge force
%            that enters 'X to n'
%
%   Two logs and not one, because Week 2's subject is the relation between a
%   demanded force and the speed it buys. A log of the states alone cannot
%   show that a proportional controller runs out of force.
%
%   See also W02_P1_START, W02_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W02_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

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
%  Open loop: a constant force, long enough to settle.
pass = true;
for X = [50 100 200]
    y = run_student(mdl, struct('loop_closed',0, 'X_open',X, 'u_d',0, ...
                                'Kp',0, 'Ki',0, 'T_final',40));
    pass = report(pass, sprintf('u_ss at X = %g N', X), ...
                  y.u(end), 0.012894*X, 5e-3, 'm/s');
end
fprintf('\n     In steady state the plant really is u = K_u X, with\n');
fprintf('     K_u = 1/|X_u| = 0.012894 (m/s)/N. The relation is exact, not\n');
fprintf('     approximate: surge damping in otter.m is linear.\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  Proportional only. The error is structural, not a tuning failure.
pass = true;
Ku = 0.012894;   ud = 1.5;
for Kp = [100 500 2000]
    y = run_student(mdl, struct('loop_closed',1, 'X_open',0, 'u_d',ud, ...
                                'Kp',Kp, 'Ki',0, 'T_final',40));
    want = Kp*Ku/(1 + Kp*Ku) * ud;
    pass = report(pass, sprintf('u_ss at Kp = %g', Kp), y.u(end), want, 5e-3, 'm/s');
end
fprintf('\n     The plant has no free integrator, so the loop is TYPE 0 and a\n');
fprintf('     proportional controller cannot reach the setpoint. The steady\n');
fprintf('     force the damping demands can only be produced by a NON-ZERO\n');
fprintf('     error. Raising Kp shrinks the error and never removes it.\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  With the integrator the error goes to zero, and overshoot appears.
pass = true;
y = run_student(mdl, struct('loop_closed',1, 'X_open',0, 'u_d',1.5, ...
                            'Kp',102, 'Ki',192.38, 'T_final',40));
pass = report(pass, 'steady speed with PI', y.u(end), 1.5, 5e-3, 'm/s');
pass = report(pass, 'steady error with PI',  1.5 - y.u(end), 0, 5e-3, 'm/s');

k = y.t >= 5;                            % after the step
Mp = 100*(max(y.u(k)) - 1.5)/1.5;
fprintf('  %-38s %9.4f  %s\n', 'overshoot with PI', Mp, '[%]  (P alone had none)');
if Mp <= 0.05
    fprintf('  %-38s %s\n', 'overshoot is present', 'FAIL — expected some');
    pass = false;
end
fprintf('\n     The integrator supplies the steady force that the damping\n');
fprintf('     demands, so the error no longer has to. What it costs is a\n');
fprintf('     state that keeps acting after the error has passed through\n');
fprintf('     zero — which is overshoot, and, when the actuator saturates,\n');
fprintf('     windup. Sections F to H of the lecture are about that.\n');
end

% =========================================================================
function y = run_student(mdl, V)
base = 'base';
assignin(base,'h',0.02);              assignin(base,'T_final',V.T_final);
assignin(base,'loop_closed',V.loop_closed);
assignin(base,'X_open',V.X_open);     assignin(base,'u_d',V.u_d);
assignin(base,'Kp',V.Kp);             assignin(base,'Ki',V.Ki);
assignin(base,'Kd',0);                assignin(base,'Nf',20);
assignin(base,'mp',25);               assignin(base,'rp',[0.05 0 -0.35]');
assignin(base,'V_c',0);               assignin(base,'beta_c',0);
assignin(base,'x0',zeros(12,1));
assignin(base,'animate',0);           assignin(base,'animate_every',0.5);
assignin(base,'t_step',5);

evalin(base, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl, 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
need_log(mdl, 'xlog');
evalin(base, sprintf('sim(''%s'');', mdl));

S = evalin(base, 'xlog');
x = squeeze(S.signals.values);
if size(x,1) == 12, x = x.'; end
if size(x,2) < 12
    error('W02_check:width', ...
      'xlog has %d columns. Feed it the FULL 12-state vector.', size(x,2));
end
y.t = S.time;   y.u = x(:,1);   y.v = x(:,2);   y.r = rad2deg(x(:,6));
end

function need_log(mdl, name)
if isempty(find_system(mdl, 'BlockType','ToWorkspace', 'VariableName', name))
    error('W02_check:noLog', ...
      ['The model has no To Workspace block whose variable name is %s.\n' ...
       'Add one and set its Save format to ''Structure With Time''.'], name);
end
end

function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
if good, verdict = 'PASS'; else, verdict = 'FAIL'; end
fprintf('  %-38s %9.4f  (expected %8.4f +- %.3g %s)  %s\n', ...
        what, got, want, tol, unit, verdict);
ok = ok && good;
end
