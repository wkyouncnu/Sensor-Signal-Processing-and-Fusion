function pass = W09_check(problem, mdl)
%W09_CHECK  학생이 만든 9주차 모델을 돌려 강의의 측정값과 대조한다.
%           Run a student's Week 9 model and check it against the lecture.
%
%   W09_check(1)                W09_P1.slx 를 검사한다 / checks W09_P1.slx
%   W09_check(2, 'W09_P1_kim')  다른 모델을 검사한다 / checks another model
%   pass = W09_check(3, mdl)    모두 통과하면 true / true when every test passed
%
%   체커는 강의와 **같은 정의**로 잰다. 여기서는 그것이 특히 중요하다 — 3번
%   문제는 아홉 번의 실행을 한 표에 나란히 놓고 읽는 것이고, 절마다 다르게
%   재면 그 표는 아무 말도 하지 않는다. 그래서 모든 수를 `W09_metrics` 하나가
%   낸다 (§15-16).
%   The checker measures by the lecture's definitions, which matters most in
%   Problem 3: nine runs read side by side in one table say nothing unless
%   every column was measured the same way. Every number comes from the single
%   function `W09_metrics`.
%
%   무엇을 검사하는가 / what is being checked
%
%     Problem 1   the two rules: the mission runs transit-hold-...-done and
%                 completes at 277.7 s, with the three holds of 9-2   §9-2
%     Problem 2   the acceptance circle is missed at 1.3 m/s by 0.67 m, and
%                 the along-track test of Week 5 flies it in 291.2 s  §9-5
%     Problem 3   one week at a time removed: two of the nine switches stop
%                 the mission, and they fail for opposite reasons     §9-3
%
%   WHAT THE MODEL MUST CONTAIN
%
%     slog   To Workspace, 'Structure With Time', [wp ; mode]
%            the active waypoint index, and 1 transit, 2 hold, 3 done
%
%   See also W09_P1_START, W09_METRICS, W09_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W09_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W09 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W09_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  §9-2. 두 규칙만으로 임무가 돈다. 게인은 하나도 건드리지 않는다.
pass = true;
R = run_student(mdl);  M = W09_metrics(R);  V = R.V;

fprintf('    leg   transit [s]   speed [m/s]   cross-track at the end [m]   hold [m]\n');
for k = 1:3
    a = (R.wp == k) & (R.mode == 1);  b = (R.wp == k) & (R.mode == 2);
    if ~any(a) || ~any(b), fprintf('     %d       (not reached)\n', k); continue; end
    t = R.t(a);  tb = R.t(b);
    fprintf('     %d       %6.1f        %6.3f            %8.2f            %6.3f\n', k, ...
        t(end)-t(1), mean(R.u(a & R.t >= t(1)+15)), ...
        mean(abs(R.y_e(a & R.t >= t(end)-10))), mean(R.e(b & R.t >= tb(end)-20)));
end
ch  = find(diff(R.mode) ~= 0) + 1;
seq = R.mode(ch)';
fprintf('    the modes ran %s\n', mat2str(seq));
pass = report(pass, 'transit, hold, transit, ... , done', ...
              double(isequal(seq, [2 1 2 1 2 3])), 1, 0.5, '-');
pass = report(pass, 'three holds were completed', M.legs, 3, 0.5, '-');
pass = report(pass, 'the mission finishes',       M.T, 277.7, 3.0, 's');
pass = report(pass, 'each hold lasts T_hold', max(abs(holds(R, V) - V.T_hold)), 0, 0.5, 's');
pass = report(pass, 'the holds keep station',     M.hold, 0.746, 0.20, 'm');
pass = report(pass, 'the legs are followed',      M.ye,   0.14,  0.15, 'm');
fprintf('\n     Two rules, and nothing else, produced a mission. Every number in\n');
fprintf('     the table belongs to a week: the speed is Week 3''s integral, the\n');
fprintf('     cross-track is Week 5''s ILOS, the hold is Week 8''s weathervane.\n');
fprintf('     What is this week''s is that all of them happen at once. (9-2)\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  §9-5. 두 종류의 한계. 판정의 한계가 먼저 막고, 그것은 서서히 나빠지지 않는다.
pass = true;
A = run_student(mdl, 'V_c', 1.3, 'use_pass', 0, 'T_final', 600);
B = run_student(mdl, 'V_c', 1.3, 'use_pass', 1, 'T_final', 600);
MA = W09_metrics(A);  MB = W09_metrics(B);
near = min(hypot(A.V.WP_N(1) - A.N, A.V.WP_E(1) - A.E));

fprintf('    at V_c = 1.3 m/s:\n');
fprintf('      with the acceptance circle alone   closest pass to waypoint 1  %.2f m\n', near);
fprintf('                                         the circle has a radius of  %.2f m\n', A.V.R_arrive);
fprintf('                                         the mission finishes at     %s\n', tstr(MA.T));
fprintf('      with the along-track test of W5    the mission finishes at     %s\n', tstr(MB.T));
pass = report(pass, 'the circle is missed', near, 3.67, 0.40, 'm');
pass = report(pass, 'and it is missed by only', near - A.V.R_arrive, 0.67, 0.40, 'm');
pass = report(pass, 'so the circle alone loses the mission', double(isnan(MA.T)), 1, 0.5, '-');
pass = report(pass, 'the along-track test flies it', MB.T, 291.2, 6.0, 's');
%  낮은 조류에서는 둘이 **같아야** 한다 — 원을 놓치지 않기 때문이다
C = run_student(mdl, 'use_pass', 0);
D = run_student(mdl, 'use_pass', 1);
pass = report(pass, 'at 0.3 m/s the two rules agree', ...
              W09_metrics(C).T - W09_metrics(D).T, 0, 0.5, 's');
fprintf('\n     There are two kinds of limit in a mission and they look nothing\n');
fprintf('     alike. A FORCE limit degrades: the numbers get worse continuously.\n');
fprintf('     A DECISION limit does not degrade at all until it fails entirely.\n');
fprintf('     Here the decision limit binds first, and it is off by %.2f m. The\n', near - A.V.R_arrive);
fprintf('     cheaper of the two to fix is the one that binds first: changing\n');
fprintf('     one comparison bought 0.2 m/s of operating envelope. (9-5)\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  §9-3. 한 주차씩 빼 본다. 모든 수를 W09_metrics 하나가 낸다.
pass = true;
S = {'none','use_Ki_u','use_ssa','use_Kd','use_ilos','use_pass','use_scale', ...
     'use_notch','use_vane','hand_over'};
W = {'-','W3','W4','W4','W5','W5','W6','W7','W8','W8'};
fprintf('    switch off   week   T [s]   u [m/s]   y_e [m]   dN [N m]   hold [m]\n');
for i = 1:numel(S)
    if i == 1, R = run_student(mdl); else, R = run_student(mdl, S{i}, 0); end
    M(i) = W09_metrics(R);                                            %#ok<AGROW>
    fprintf('    %-12s  %-4s  %5s    %6.3f    %6.2f     %6.2f     %6.3f\n', ...
            S{i}, W{i}, tstr(M(i).T), M(i).u, M(i).ye, M(i).Nerr, M(i).hold);
end
%  임무를 끝내지 못하는 둘, 그리고 그 둘이 갈라지는 이유
pass = report(pass, 'without W3''s integral it is too slow', M(2).u, 0.725, 0.05, 'm/s');
pass = report(pass, 'and does not finish', double(isnan(M(2).T)), 1, 0.5, '-');
pass = report(pass, 'without W4''s ssa it does not finish', double(isnan(M(3).T)), 1, 0.5, '-');
pass = report(pass, 'but its speed was never the problem', M(3).u, 1.000, 0.05, 'm/s');
pass = report(pass, 'without W5''s ILOS the legs are off by', M(5).ye, 0.97, 0.25, 'm');
pass = report(pass, 'without W6''s coupling the moment is lost', M(7).Nerr, 37.64, 4.0, 'N m');
pass = report(pass, 'without W8''s weathervane the hold is', M(9).hold, 3.681, 0.50, 'm');
%  이 조건에서는 아무것도 바꾸지 않는 행 — 그것도 측정이다
pass = report(pass, 'use_pass changes nothing here', M(6).hold - M(1).hold, 0, 0.02, 'm');
fprintf('\n     Two removals stop the mission rather than degrade it, and they\n');
fprintf('     fail for opposite reasons: without Week 3''s integral the vessel\n');
fprintf('     is merely too slow and the clock runs out; without Week 4''s ssa\n');
fprintf('     it is fast enough and spends a whole revolution at the seam of\n');
fprintf('     leg 3, which runs due south at psi = 180 deg.\n');
fprintf('     A row that does not move is not a wasted week. use_pass changes\n');
fprintf('     nothing at 0.3 m/s and decides the mission at 1.3 — Problem 2. (9-3)\n');
end

% =========================================================================
function s = tstr(T)
if isnan(T), s = '  --'; else, s = sprintf('%5.1f', T); end
end

function L = holds(R, V)
L = zeros(1,0);
for k = 1:numel(V.WP_N)
    j = (R.wp == k) & (R.mode == 2);
    if any(j), L(end+1) = sum(j)*V.h; end   %#ok<AGROW>
end
end

% =========================================================================
function R = run_student(mdl, varargin)
V = W09_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
V.w0 = 2*pi/V.T0;
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
V.phi_i = mod(V.phi_i + V.phase_shift, 2*pi);
if V.use_notch == 0, V.zeta_n = V.zeta_d; end

b = 'base';
f = fieldnames(V);
for i = 1:numel(f), assignin(b, f{i}, V.(f{i})); end

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
need(mdl,'slog');
evalin(b, sprintf('sim(''%s'');', mdl));

P = grab(evalin(b,'plog'),  4, 'plog');
S = grab(evalin(b,'slog'),  2, 'slog');
X = grab(evalin(b,'xlog'), 12, 'xlog');
L = evalin(b,'plog');
R.t = L.time;  R.V = V;
R.psi_d = P(:,1);  R.y_e = P(:,2);  R.X = P(:,3);  R.Nm = P(:,4);
R.wp = S(:,1);     R.mode = S(:,2);
R.N = X(:,7);      R.E = X(:,8);    R.psi = X(:,12)*180/pi;  R.u = X(:,1);
R.e = zeros(size(R.t));
for k = 1:numel(V.WP_N)
    j = R.wp == k;
    R.e(j) = hypot(V.WP_N(k) - R.N(j), V.WP_E(k) - R.E(j));
end
end

function need(mdl, name)
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName',name))
    error('W09_check:noLog', ...
      ['The model has no To Workspace block whose variable name is %s.\n' ...
       'It must carry [wp ; mode] with Save format ''Structure With Time''.'], name);
end
end

function M = grab(S, w, name)
M = squeeze(S.signals.values);
if size(M,1) == w, M = M.'; end
if size(M,2) ~= w
    error('W09_check:width', '%s has %d columns; %d were expected.', ...
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
