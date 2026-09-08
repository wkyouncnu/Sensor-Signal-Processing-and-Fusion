function pass = W03_check(problem, mdl)
%W03_CHECK  Run a student's Week 3 model and check it against the lecture.
%
%   W03_check(1)                checks W03_P1.slx
%   W03_check(2, 'W03_P1_kim')  checks another model
%   pass = W03_check(3, mdl)    returns true when every test passed
%
%   WHAT IS BEING CHECKED, AND WHY THESE NUMBERS
%
%     Problem 1   steady heading error, proportional only     0, at EVERY gain
%                 overshoot grows with Kp: 0.24 % at 100, 1.53 % at 300   §3-C
%     Problem 2   overshoot FALLS as Kd rises                 §3-D
%                 zeta = (|Nr| + Kd) / (2 sqrt(Kp M66))
%     Problem 3   with the wrap, a command across the seam is answered by the
%                 SHORT turn; without it, by the long way round
%
%   WHAT THE MODEL MUST CONTAIN
%
%     xlog   To Workspace, 'Structure With Time', the plant's 12 states
%
%   See also W03_P1_START, W03_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W03_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W03 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W03_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  Proportional only. The steady error is zero at every gain — that is the
%  whole contrast with Week 2, and it is structural.
%  The overshoot targets are section C's measured values. Comparing wn with
%  sqrt(Kp/M66) would be comparing a number with itself and would pass on a
%  model that does nothing at all.
pass = true;
G = [30 100 300];  MPWANT = [-0.01 0.24 1.53];
for i = 1:3
    y = run_student(mdl, struct('Kp',G(i), 'Kd',0, 'use_ssa',1, ...
                                'psi_1',60, 'psi_2',60, 'T_final',40));
    k = y.t >= 30;
    pass = report(pass, sprintf('steady error at Kp = %g', G(i)), ...
                  mean(60 - y.psi(k)), 0, 0.05, 'deg');
    kk = y.t >= 5;
    pass = report(pass, sprintf('   overshoot at Kp = %g', G(i)), ...
                  100*(max(y.psi(kk)) - 60)/60, MPWANT(i), 0.25, '%');
end
fprintf('\n     Zero at EVERY gain, and nothing was tuned to achieve it. The\n');
fprintf('     heading is the integral of the yaw rate, psi = int r, so the\n');
fprintf('     plant carries a free integrator and the loop is TYPE 1. Week 2\n');
fprintf('     could not reach its setpoint at any gain. The difference is one\n');
fprintf('     structural fact about the axis, not a better controller.\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  Derivative action. Overshoot falls as Kd rises — the opposite of Week 2.
pass = true;  M66 = 42.65;  Nr = -42.65;  Kp = 100;
Mp = zeros(1,3);  K = [0 25 74.9];
for i = 1:3
    y = run_student(mdl, struct('Kp',Kp, 'Kd',K(i), 'use_ssa',1, ...
                                'psi_1',5, 'psi_2',5, 'T_final',40));
    k = y.t >= 5;
    Mp(i) = 100*(max(y.psi(k)) - 5)/5;
    z = (abs(Nr) + K(i))/(2*sqrt(Kp*M66));
    fprintf('  %-38s %9.4f  (zeta = %.4f)\n', ...
            sprintf('overshoot at Kd = %g  [%%]', K(i)), Mp(i), z);
end
pass = report(pass, 'overshoot at Kd = 0', Mp(1), 11.74, 1.0, '%');
if ~(Mp(1) > Mp(2) && Mp(2) > Mp(3))
    fprintf('  %-38s %s\n', 'overshoot must FALL as Kd rises', 'FAIL');
    pass = false;
else
    fprintf('  %-38s %s\n', 'overshoot falls as Kd rises', 'PASS');
end
pass = report(pass, 'overshoot at Kd = 74.9 (zeta = 0.9)', Mp(3), 0, 0.5, '%');
fprintf('\n     Substituting the law into the yaw equation gives\n');
fprintf('        M66 psi_ddot + (|Nr| + Kd) psi_dot + Kp psi = Kp psi_d\n');
fprintf('     so Kd sits beside the DAMPING. In Week 2 the controlled variable\n');
fprintf('     was a velocity, its derivative was an acceleration, and the same\n');
fprintf('     term sat beside the MASS. The term did not change; the axis did.\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  The wrap. A command 20 deg the other side of the seam.
%
%  The vessel starts at psi = 170 deg and is asked for -170 deg. The short
%  way is +20 deg through the seam; the long way is -340 deg.
pass = true;
x0 = zeros(12,1);  x0(12) = deg2rad(170);

yOn  = run_student(mdl, struct('Kp',100,'Kd',74.9,'use_ssa',1, ...
                              'psi_1',-170,'psi_2',-170,'t_up',0,'T_final',60), x0);
yOff = run_student(mdl, struct('Kp',100,'Kd',74.9,'use_ssa',0, ...
                              'psi_1',-170,'psi_2',-170,'t_up',0,'T_final',60), x0);

swOn  = yOn.psi(end)  - 170;      % unwrapped: how far the hull actually turned
swOff = yOff.psi(end) - 170;
pass = report(pass, 'turn WITH the wrap',    swOn,  20,   3.0, 'deg');
pass = report(pass, 'turn WITHOUT the wrap', swOff, -340, 12.0, 'deg');
fprintf('\n     With the wrap the vessel takes the 20 deg turn through the seam.\n');
fprintf('     Without it the error is computed as -340 deg and the vessel goes\n');
fprintf('     the long way round — seventeen times further, for the same\n');
fprintf('     commanded heading. ssa is one line of code and it is not optional.\n');
end

% =========================================================================
function y = run_student(mdl, V, x0)
if nargin < 3, x0 = zeros(12,1); end
cfg = otter_config('base');
b = 'base';
assignin(b,'h',0.02);          assignin(b,'T_final',V.T_final);
assignin(b,'Kp',V.Kp);         assignin(b,'Kd',V.Kd);
assignin(b,'use_ssa',V.use_ssa);
assignin(b,'psi_1',V.psi_1);   assignin(b,'psi_2',V.psi_2);
%  Problem 3 commands from t = 0 so that both runs start with the SAME error
%  and differ only in how that error is computed. With a step at t = 5 the two
%  runs are already in different places when the step arrives, and the
%  comparison stops being about the wrap.
if isfield(V,'t_up'), t_up = V.t_up; else, t_up = 5; end
assignin(b,'t_up',t_up);       assignin(b,'t_dn',1e6);
assignin(b,'X_ff',60);
assignin(b,'M66',42.65);       assignin(b,'Nr',-42.65);
assignin(b,'k_pos',cfg.k_pos); assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max); assignin(b,'n_min',cfg.n_min);
assignin(b,'y_pont',0.395);
assignin(b,'mp',25);           assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);           assignin(b,'beta_c',0);
assignin(b,'x0',x0);
assignin(b,'animate',0);       assignin(b,'animate_every',0.5);

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName','xlog'))
    error('W03_check:noLog', ...
      ['The model has no To Workspace block whose variable name is xlog.\n' ...
       'Add one, feed it the plant''s 12-state output, and set its format\n' ...
       'to ''Structure With Time''.']);
end
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b,'xlog');
x = squeeze(S.signals.values);  if size(x,1)==12, x = x.'; end
if size(x,2) < 12
    error('W03_check:width', 'xlog has %d columns; feed it all 12 states.', size(x,2));
end
%  psi is NOT wrapped here. Problem 3 needs the accumulated turn, and a
%  wrapped angle cannot tell 20 deg from -340 deg.
y.t = S.time;  y.psi = rad2deg(x(:,12));  y.r = rad2deg(x(:,6));
end

function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
if good, verdict = 'PASS'; else, verdict = 'FAIL'; end
fprintf('  %-38s %9.4f  (expected %8.4f +- %.3g %s)  %s\n', ...
        what, got, want, tol, unit, verdict);
ok = ok && good;
end
