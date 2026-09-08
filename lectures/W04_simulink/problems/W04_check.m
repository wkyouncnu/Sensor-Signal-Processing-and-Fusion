function pass = W04_check(problem, mdl)
%W04_CHECK  Run a student's Week 4 model and check it against the lecture.
%
%   W04_check(1)                checks W04_P1.slx
%   W04_check(2, 'W04_P1_kim')  checks another model
%   pass = W04_check(3, mdl)    returns true when every test passed
%
%   WHAT IS BEING CHECKED
%
%     Problem 1   the LOS law itself. pi_p on leg 1 is exactly 0 rad, and the
%                 vessel joins the line and stays on it              §4-4
%     Problem 2   atan2 reaches the waypoint and never the LINE      §4-1, §4-C
%     Problem 3   in a current LOS settles at Delta tan(beta_c)      §4-7
%
%   WHAT THE MODEL MUST CONTAIN
%
%     xlog   To Workspace, 'Structure With Time', the plant's 12 states
%     glog   To Workspace, 'Structure With Time', [pi_p ; y_e_p ; psi_d]
%            in radians and metres, in that order
%
%   The guidance log is required because Problems 1 and 3 are about quantities
%   that never appear in the state vector. A model can put the vessel in the
%   right place with the wrong y_e, and only glog can tell.
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
%  Leg 1 runs from (0,0) to (60,0): due north, so pi_p is exactly zero.
%  The vessel starts 18 m to the east of it and has to join the line.
pass = true;
y = run_student(mdl, struct('law',1, 'V_c',0, 'beta_c',0, 'T_final',120, 'y0',18));

pass = report(pass, 'pi_p on leg 1', mean(y.pi_p), 0, 1e-9, 'rad');
k = y.t >= 90;
pass = report(pass, 'settled cross-track error', mean(y.y_e(k)), 0, 0.05, 'm');
pass = report(pass, 'settled heading command',   mean(y.psi_d(k)), 0, 0.01, 'rad');
pass = report(pass, 'it started 18 m off the line', y.y_e(1), 18, 0.05, 'm');
fprintf('\n     The correction fades to zero exactly as the vessel reaches the\n');
fprintf('     path, so psi_d ends on pi_p and the rest of the leg is run along\n');
fprintf('     it. That is the whole of the LOS law.\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  The same run under both laws. atan2 reaches the waypoint; LOS reaches the
%  LINE. The gap is measured as the largest cross-track error after the
%  vessel has had time to settle.
pass = true;
yL = run_student(mdl, struct('law',1, 'V_c',0, 'beta_c',0, 'T_final',120, 'y0',18));
yA = run_student(mdl, struct('law',2, 'V_c',0, 'beta_c',0, 'T_final',120, 'y0',18));
%  From 90 s, the same window Problem 1 uses. At 60 s the LOS vessel is still
%  finishing its approach, and measuring there compares a transient with a
%  steady state — which flatters atan2 rather than the other way round.
k  = yL.t >= 90;

eL = max(abs(yL.y_e(k)));
eA = max(abs(yA.y_e(k)));
fprintf('  %-38s %9.4f m\n', 'LOS   worst |y_e| after 90 s', eL);
fprintf('  %-38s %9.4f m\n', 'atan2 worst |y_e| after 90 s', eA);
pass = report(pass, 'LOS holds the line', eL, 0, 0.20, 'm');
if eA > 5*max(eL, 0.05)
    fprintf('  %-38s %s\n', 'atan2 does NOT hold the line', 'PASS');
else
    fprintf('  %-38s %s\n', 'atan2 should be far worse than LOS', 'FAIL');
    pass = false;
end
%  Both must still arrive: the point of the comparison is that atan2 is not
%  broken, it is answering a different question.
pass = report(pass, 'atan2 still reaches the waypoint', ...
              hypot(60 - yA.x(end), 0 - yA.y(end)), 0, 6.0, 'm');
fprintf('\n     atan2 regulates the distance to a POINT, and a point carries no\n');
fprintf('     information about the line it sits on. It is not badly tuned; it\n');
fprintf('     is answering a different question.\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  A beam current. LOS settles beside the path and stays there.
pass = true;
Delta = 8;
y = run_student(mdl, struct('law',1, 'V_c',0.3, 'beta_c',pi/2, ...
                            'T_final',200, 'y0',0));
k = y.t >= 150;

beta = mean(atan2(y.v(k), y.u(k)));           % the crab angle, measured
off  = mean(y.y_e(k));
pred = Delta*tan(beta);

fprintf('  %-38s %9.4f deg\n', 'measured crab angle beta_c', rad2deg(beta));
pass = report(pass, 'settled offset y_e', off,  pred, 0.15, 'm');
pass = report(pass, 'the prediction Delta tan(beta_c)', pred, off, 0.15, 'm');

%  And the heading error is already zero while that offset persists.
he = mean(mod(y.psi_d(k) - y.psi(k) + pi, 2*pi) - pi);
pass = report(pass, 'heading error while offset persists', rad2deg(he), 0, 0.5, 'deg');
fprintf('\n     The vessel settles BESIDE the path and stays there, with the\n');
fprintf('     heading error already at zero. There is nothing left for a\n');
fprintf('     larger autopilot gain to act on. Sections 4-8 and 4-9 exist to\n');
fprintf('     remove this offset, and neither of them does it with gain.\n');
end

% =========================================================================
function y = run_student(mdl, V)
cfg = otter_config('base');
W   = [0 0; 60 0; 60 60; 0 60; 60 120];
b   = 'base';
assignin(b,'h',0.02);          assignin(b,'T_final',V.T_final);
assignin(b,'WP_N',W(:,1));     assignin(b,'WP_E',W(:,2));
assignin(b,'Delta',8);         assignin(b,'law',V.law);
assignin(b,'Kp',100);          assignin(b,'Kd',74.9);
assignin(b,'X_ff',60);
assignin(b,'k_pos',cfg.k_pos); assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max); assignin(b,'n_min',cfg.n_min);
assignin(b,'y_pont',0.395);
assignin(b,'mp',25);           assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',V.V_c);       assignin(b,'beta_c',V.beta_c);
x0 = zeros(12,1);  x0(8) = V.y0;               % start east of the leg
assignin(b,'x0',x0);
assignin(b,'animate',0);       assignin(b,'animate_every',0.5);

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
need(mdl,'xlog');  need(mdl,'glog');
evalin(b, sprintf('sim(''%s'');', mdl));

X = grab(evalin(b,'xlog'), 12, 'xlog');
G = grab(evalin(b,'glog'),  3, 'glog');
S = evalin(b,'xlog');
y.t = S.time;
y.u = X(:,1);  y.v = X(:,2);  y.x = X(:,7);  y.y = X(:,8);  y.psi = X(:,12);
y.pi_p = G(:,1);  y.y_e = G(:,2);  y.psi_d = G(:,3);
end

function need(mdl, name)
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName',name))
    error('W04_check:noLog', ...
      ['The model has no To Workspace block whose variable name is %s.\n' ...
       'Set its Save format to ''Structure With Time''.'], name);
end
end

function M = grab(S, w, name)
M = squeeze(S.signals.values);
if size(M,1) == w, M = M.'; end
if size(M,2) ~= w
    error('W04_check:width', '%s has %d columns; %d were expected.', ...
          name, size(M,2), w);
end
end

function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
if good, verdict = 'PASS'; else, verdict = 'FAIL'; end
fprintf('  %-38s %9.4f  (expected %8.4f +- %.3g %s)  %s\n', ...
        what, got, want, tol, unit, verdict);
ok = ok && good;
end
