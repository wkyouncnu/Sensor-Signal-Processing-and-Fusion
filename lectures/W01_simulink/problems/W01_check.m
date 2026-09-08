function pass = W01_check(problem, mdl)
%W01_CHECK  Run a student's Week 1 model and check it against the lecture.
%
%   W01_check(1)                checks W01_P1.slx
%   W01_check(2, 'W01_P1_kim')  checks another model
%   pass = W01_check(3, mdl)    returns true when every test passed
%
%   WHAT IS BEING CHECKED, AND WHY THESE NUMBERS
%
%   Every target below was MEASURED by the lecture's own section scripts, not
%   chosen. A model that reproduces them is doing the same physics as the one
%   in the lecture, whatever it looks like on the canvas.
%
%     Problem 1   terminal surge speed at n = 60 rad/s          1.0286 m/s
%                 and the sway row: v stays at zero              §1-C, §1-D
%     Problem 2   yaw rate in the port turn                     -2.2942 deg/s
%                 heading change, port then starboard        -70.2 / +70.6 deg
%     Problem 3   drift of track from heading, beam current      25.81 deg
%                 ground speed in that current                  1.1091 m/s
%
%   WHAT THE MODEL MUST CONTAIN
%
%   One To Workspace block named  xlog , format 'Structure With Time', fed by
%   the plant's twelve-state output. Nothing else is prescribed: the wiring,
%   the block positions and any scopes are the student's own.
%
%   Requiring the raw twelve states rather than a tidy six-column log is
%   deliberate. Picking u, v, r, x, y and psi out of the vector is the part of
%   Week 1 worth being able to do from memory.
%
%   See also W01_P1_START, W01_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W01_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W01 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------\n');

switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W01_check:problem', 'problem must be 1, 2 or 3');
end

fprintf('  ------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  Constant command, both propellers at n0 = 60, long enough to settle.
V = struct('n0',60, 'dn',0, 't_phase',[1e9 1e9 1e9 1e9], ...
           'V_c',0, 'beta_c',0, 'T_final',60);
y = run_student(mdl, V);
pass = true;
pass = report(pass, 'terminal surge speed u', y.u(end), 1.0286, 5e-3, 'm/s');
pass = report(pass, 'sway velocity v (must stay zero)', max(abs(y.v)), 0, 1e-6, 'm/s');
pass = report(pass, 'yaw rate r (nothing steers)', max(abs(y.r)), 0, 1e-6, 'deg/s');
fprintf('\n     The vessel runs due north and never turns. Y is structurally\n');
fprintf('     zero because both propellers face forward, so no combination\n');
fprintf('     of them has a component across the hull.\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  The S-shape of section D, with the lecture's own numbers.
V = struct('n0',60, 'dn',3.5, 't_phase',[30 60 90 120], ...
           'V_c',0, 'beta_c',0, 'T_final',150);
y = run_student(mdl, V);
pass = true;

port = y.t >= 45 & y.t <= 58;          % well inside the port turn
stbd = y.t >= 105 & y.t <= 118;
pass = report(pass, 'yaw rate in the PORT turn',      mean(y.r(port)), -2.2942, 0.02, 'deg/s');
pass = report(pass, 'yaw rate in the STARBOARD turn', mean(y.r(stbd)), +2.2942, 0.02, 'deg/s');

iP = find(y.t>=30,1); jP = find(y.t>=60,1);
iS = find(y.t>=90,1); jS = find(y.t>=120,1);
pass = report(pass, 'heading change, port turn',      y.psi(jP)-y.psi(iP), -70.2, 0.5, 'deg');
pass = report(pass, 'heading change, starboard turn', y.psi(jS)-y.psi(iS), +70.6, 0.5, 'deg');
pass = report(pass, 'sway v in the port turn',        mean(y.v(port)), +0.1264, 5e-3, 'm/s');
pass = report(pass, 'sway v in the starboard turn',   mean(y.v(stbd)), -0.1264, 5e-3, 'm/s');
fprintf('\n     v changes SIGN between the two turns and Y is zero throughout.\n');
fprintf('     The sway comes from the hull rotating, through the Coriolis\n');
fprintf('     term, and not from any side force. That is the crab angle.\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  A beam current, no steering. Section E's third row.
V = struct('n0',60, 'dn',0, 't_phase',[1e9 1e9 1e9 1e9], ...
           'V_c',0.5, 'beta_c',pi/2, 'T_final',120);
y = run_student(mdl, V);
pass = true;

%  The three quantities are defined EXACTLY as section E defines them, so a
%  student who reproduces the lecture's number is not marked wrong by a
%  different convention:
%
%    track   the direction of the straight line from start to finish, not the
%            instantaneous heading of the velocity. The vessel weathervanes
%            about 4 deg during the run, so the two differ by half a degree
%    psi     averaged over the settled last fifth of the run
%    speed   from the mean step in position over that same fifth
%
%  The first of these cost half a degree and a FAIL when this checker was
%  first written with gradient() instead. Measure what the lecture measures.
k     = y.t >= 0.8*y.t(end);                 % settled fifth of the run
track = atan2d(y.E(end) - y.E(1), y.N(end) - y.N(1));
speed = hypot(mean(diff(y.N(k))), mean(diff(y.E(k)))) / (y.t(2) - y.t(1));
drift = track - mean(y.psi(k));

pass = report(pass, 'ground speed over the ground', speed, 1.1091, 0.02, 'm/s');
pass = report(pass, 'track direction from North',   track, 21.804, 0.30, 'deg');
pass = report(pass, 'drift, track minus heading',   drift, 25.809, 0.30, 'deg');
fprintf('\n     Nothing pushed the vessel sideways. The relative sway v_r is\n');
fprintf('     almost zero; the water itself is moving, and eta_dot = J(eta) nu\n');
fprintf('     carries the vessel with it.\n');
end

% =========================================================================
function y = run_student(mdl, V)
%RUN_STUDENT  Put the week's variables in the base workspace, run, read xlog.
%
%  The variables are assigned rather than passed, because the student's model
%  refers to them by name in its Constant blocks exactly as the lecture's does.
base = 'base';
assignin(base,'h',0.02);          assignin(base,'T_final',V.T_final);
assignin(base,'n0',V.n0);         assignin(base,'dn',V.dn);
assignin(base,'t_phase',V.t_phase);
assignin(base,'mp',25);           assignin(base,'rp',[0.05 0 -0.35]');
assignin(base,'V_c',V.V_c);       assignin(base,'beta_c',V.beta_c);
assignin(base,'x0',zeros(12,1));
assignin(base,'animate',0);       assignin(base,'animate_every',0.5);

evalin(base, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl, 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');

blk = find_system(mdl, 'BlockType','ToWorkspace', 'VariableName','xlog');
if isempty(blk)
    error('W01_check:noLog', ...
      ['The model has no To Workspace block whose variable name is xlog.\n' ...
       'Add one, feed it the plant''s 12-state output, and set its format\n' ...
       'to ''Structure With Time''.']);
end

evalin(base, sprintf('sim(''%s'');', mdl));
S = evalin(base, 'xlog');
if ~isstruct(S) || ~isfield(S,'signals')
    error('W01_check:format', ...
      'xlog is not a Structure With Time. Set the To Workspace Save format.');
end
x = squeeze(S.signals.values);
if size(x,1) == 12, x = x.'; end
if size(x,2) < 12
    error('W01_check:width', ...
      'xlog has %d columns. Feed the To Workspace the FULL 12-state vector.', size(x,2));
end

y.t   = S.time;
y.u   = x(:,1);   y.v = x(:,2);   y.r   = rad2deg(x(:,6));
y.N   = x(:,7);   y.E = x(:,8);   y.psi = rad2deg(x(:,12));
end

% =========================================================================
function ok = report(ok, what, got, want, tol, unit)
good = abs(got - want) <= tol;
if good, verdict = 'PASS'; else, verdict = 'FAIL'; end
fprintf('  %-38s %9.4f  (expected %8.4f +- %.3g %s)  %s\n', ...
        what, got, want, tol, unit, verdict);
ok = ok && good;
end
