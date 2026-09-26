function pass = W08_check(problem, mdl)
%W08_CHECK  학생이 만든 8주차 모델을 돌려 강의의 측정값과 대조한다.
%           Run a student's Week 8 model and check it against the lecture.
%
%   W08_check(1)                W08_P1.slx 를 검사한다 / checks W08_P1.slx
%   W08_check(2, 'W08_P1_kim')  다른 모델을 검사한다 / checks another model
%   pass = W08_check(3, mdl)    모두 통과하면 true / true when every test passed
%
%   체커는 강의와 **같은 정의**로 잰다 (CLAUDE.md §2): 유지 성능은 마지막 50 s,
%   넘겨받기는 두 번째 유지가 시작하고 10 s 안의 최대 |X| 다.
%   The checker measures by the lecture's definitions: station-keeping over the
%   last 50 s, and the handover as the peak |X| in the first 10 s of the second
%   hold.
%
%   무엇을 검사하는가 / what is being checked
%
%     Problem 1   a fixed heading cannot hold station against a beam current,
%                 and the surge force stays at ZERO while it fails     §8-2
%     Problem 2   the bow set free holds it, settles into the flow, and the
%                 force it holds is the drag at that speed             §8-3
%     Problem 3   the mission runs by its two rules, and the integral is
%                 handed over rather than carried across               §8-5
%
%   WHAT THE MODEL MUST CONTAIN
%
%     dlog   To Workspace, 'Structure With Time', [psi_d ; X ; N]
%            the commanded heading in deg, the surge force in N, the yaw
%            moment in N m
%
%   See also W08_P1_START, W08_0_SETUP.

if nargin < 2 || isempty(mdl), mdl = 'W08_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

fprintf('\n  W08 problem %d  —  checking model %s\n', problem, mdl);
fprintf('  ------------------------------------------------------------------\n');
switch problem
    case 1, pass = check_p1(mdl);
    case 2, pass = check_p2(mdl);
    case 3, pass = check_p3(mdl);
    otherwise, error('W08_check:problem', 'problem must be 1, 2 or 3');
end
fprintf('  ------------------------------------------------------------------\n');
if pass, fprintf('  RESULT   all tests passed\n\n');
else,    fprintf('  RESULT   not yet — see the FAIL lines above\n\n');
end
end

% =========================================================================
function pass = check_p1(mdl)
%  §8-2. 선수각을 북쪽에 고정한 채 동쪽으로 흐르는 조류에 맞선다 — 맞설 수 없다.
%  이 문제의 요점은 **제어기가 잘못한 것이 없다**는 것이다.
pass = true;
V = base_setup();  V.vane = 0;
y = run_student(mdl, V);

fprintf('    after %.0f s on a fixed heading of %.0f deg, in a %.2f m/s current:\n', ...
        V.T_final, V.psi_fix, V.V_c);
fprintf('      the vessel is %7.2f m from the station\n', y.e(end));
fprintf('      it has been carried %7.2f m to the east\n', y.E(end));
fprintf('      the largest surge force ever asked of it was %.2f N\n', max(abs(y.X)));
pass = report(pass, 'it drifts away from the station', y.e(end), 56.64, 3.0, 'm');
pass = report(pass, 'and the surge force stays at zero', max(abs(y.X)), 0, 1.0, 'N');
pass = report(pass, 'the heading never moves',  std(y.psi), 0, 1.0, 'deg');
fprintf('\n     Nothing here is a fault of the controller. The position loop is\n');
fprintf('     asking for a force to the west, correctly and the whole time; the\n');
fprintf('     projection of that force on a bow pointing north is zero, and the\n');
fprintf('     sway row of B is zero (Week 6 §6-3), so no pair of shaft speeds\n');
fprintf('     can produce it. This is underactuation, not bad tuning. (8-2)\n');
end

% =========================================================================
function pass = check_p2(mdl)
%  §8-3. 선수각을 놓아 준다. 적분이 상류 쪽 힘을 배우고 뱃머리가 그것을 따라간다.
pass = true;
V = base_setup();  V.vane = 1;
y = run_student(mdl, V);
j = y.t > 150;                                % 마지막 50 s / the last 50 s
X_drag = V.V_c/0.012894;                      % 0.3 m/s 에서의 항력 / the drag there

fprintf('    over the last 50 s, with the bow free:\n');
fprintf('      |e| mean %.3f m, max %.3f m\n', mean(y.e(j)), max(y.e(j)));
fprintf('      the bow settles at %.1f deg;  the current runs towards %.0f deg\n', ...
        mean(y.psi(j)), V.beta_c*180/pi);
fprintf('      surge force %.1f N;  the drag at %.2f m/s is %.1f N\n', ...
        mean(y.X(j)), V.V_c, X_drag);
pass = report(pass, 'the station is held', mean(y.e(j)), 0.193, 0.25, 'm');
pass = report(pass, 'the bow turns into the flow', mean(y.psi(j)), -90.6, 6.0, 'deg');
pass = report(pass, 'the force it holds is the drag', mean(y.X(j)), X_drag, 2.5, 'N');
%  명령한 선수각을 실제로 따라갔는가 — 오토파일럿이 연결되어 있는가
he = mean(atan2d(sind(y.psi_d(j) - y.psi(j)), cosd(y.psi_d(j) - y.psi(j))));
pass = report(pass, 'the bow follows the command', he, 0, 2.0, 'deg');
fprintf('\n     The same current, the same gains, and now the station is held.\n');
fprintf('     Nothing was added to the position loop: the integral learned an\n');
fprintf('     upstream force, and the bow was allowed to follow it. That the\n');
fprintf('     force it settles on equals the drag at %.2f m/s is the check\n', V.V_c);
fprintf('     that the vessel is doing physics rather than holding still. (8-3)\n');
end

% =========================================================================
function pass = check_p3(mdl)
%  §8-5. 세 지점을 차례로. 그리고 모드가 바뀔 때 적분을 넘겨받는가.
pass = true;
%  1·2번 문제는 지점 하나를 영원히 붙잡았다. 여기서는 세 지점을 40 s 씩.
%  Problems 1 and 2 held one station for ever; here there are three, 40 s each.
V = base_setup();  V.vane = 1;  V.T_final = 400;
V.WP_N = [0 40 40]';  V.WP_E = [0 0 40]';  V.T_hold = 40;
A = run_student(mdl, V, 'hand_over', 1);
B = run_student(mdl, V, 'hand_over', 0);

ch = find(diff(A.mode) ~= 0) + 1;
fprintf('    the mission, with the integral handed over:\n');
for i = 1:numel(ch)
    k = ch(i);
    fprintf('      t = %6.1f s   %-7s -> %-7s   at (N %6.2f, E %6.2f)\n', ...
            A.t(k), name(A.mode(k-1)), name(A.mode(k)), A.N(k), A.E(k));
end
%  배는 첫 지점 위에서 출발하므로 시작하자마자 유지로 들어간다. 그 뒤로 기록되는
%  변화는 다섯이고, 번갈아 가다 끝난다 — 강의 §8-5 의 표와 같은 다섯 시각이다.
%  The vessel starts on the first waypoint and enters hold at once, so the five
%  recorded changes alternate and end in done, at the five instants of §8-5.
seq = A.mode(ch)';
pass = report(pass, 'five changes of mode, alternating', ...
              double(isequal(seq, [1 2 1 2 3])), 1, 0.5, '-');
holds = hold_lengths(A, V);
pass = report(pass, 'each hold lasts T_hold', max(abs(holds - V.T_hold)), 0, 0.5, 's');

%  넘겨받기 / the handover, measured in the first 10 s of the second hold
[pA, eA] = second_hold(A, V);
[pB, eB] = second_hold(B, V);
fprintf('\n    %-12s  peak |X| in the first 10 s of the second hold   |e| over that hold\n', 'hand_over');
fprintf('    %-12d %38.1f N %20.3f m\n', 1, pA, eA);
fprintf('    %-12d %38.1f N %20.3f m\n', 0, pB, eB);
pass = report(pass, 'handed over: the hold begins calmly', pA, 43.3, 12.0, 'N');
pass = report(pass, 'handed over: and holds',              eA, 0.420, 0.35, 'm');
pass = report(pass, 'not handed over: it saturates',       pB, 120.0, 1.0, 'N');
if eB > 10*max(eA, 0.05)
    fprintf('  %-42s %9s  %s\n', 'not handed over: and is thrown clear', '', 'PASS');
else
    fprintf('  %-42s %9.3f  %s\n', 'without the handover it should be far worse', eB, 'FAIL');
    pass = false;
end
fprintf('\n     In transit the position error is tens of metres, and an integrator\n');
fprintf('     left running accumulates all of it. When the hold begins it demands\n');
fprintf('     what it has stored — the limit — and throws the vessel past the\n');
fprintf('     station before it unwinds. A controller that is not in charge must\n');
fprintf('     not integrate. Integration is where a controller that works and a\n');
fprintf('     mission that works stop being the same thing. (8-5)\n');
end

% =========================================================================
function s = name(m)
N = {'transit','hold','done'};  s = N{max(1, min(3, round(m)))};
end

function L = hold_lengths(y, V)
L = zeros(1,0);
for k = 1:numel(V.WP_N)
    j = y.mode == 2 & y.N_d == V.WP_N(k) & y.E_d == V.WP_E(k);
    if any(j), L(end+1) = sum(j)*V.h; end   %#ok<AGROW>
end
end

function [pk, er] = second_hold(y, V)
%  두 번째 유지 = 두 번째 웨이포인트에서 붙잡는 구간 / the hold at waypoint 2
j = y.mode == 2 & y.N_d == V.WP_N(2) & y.E_d == V.WP_E(2);
if ~any(j), pk = NaN;  er = NaN;  return; end
t = y.t(j);
q = j & y.t <= t(1) + 10;
pk = max(abs(y.X(q)));
er = mean(y.e(j));
end

% =========================================================================
function V = base_setup()
cfg = otter_config('base');
V.WP_N = 0;  V.WP_E = 0;                      % 한 지점 = 처음부터 유지 / one station
V.R_arrive = 2;  V.T_hold = 1e9;              % 영원히 붙잡는다 / hold for ever
V.psi_fix = 0;   V.vane = 1;
V.Kp_x = 30;  V.Ki_x = 3;  V.Kd_x = 60;  V.e_min = 0.3;  V.X_max = 120;
V.Kp = 300;   V.Kd = 100;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_max/2), ...
              2*cfg.y_pont*(V.X_max/2 + cfg.k_neg*cfg.n_min^2));
V.X_ff = 60;  V.Delta = 5;  V.hand_over = 1;
V.V_c = 0.3;  V.beta_c = pi/2;
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.x0 = zeros(12,1);
V.h = 0.02;  V.T_final = 200;
end

function y = run_student(mdl, V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
b = 'base';
f = fieldnames(V);
for i = 1:numel(f), assignin(b, f{i}, V.(f{i})); end

evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
need(mdl,'dlog');
evalin(b, sprintf('sim(''%s'');', mdl));

D = grab(evalin(b,'dlog'),  3, 'dlog');
M = grab(evalin(b,'mlog'),  3, 'mlog');
X = grab(evalin(b,'xlog'), 12, 'xlog');
S = evalin(b,'dlog');
y.t = S.time;
y.psi_d = D(:,1);  y.X = D(:,2);  y.Nm = D(:,3);
y.N_d = M(:,1);    y.E_d = M(:,2);  y.mode = M(:,3);
y.N = X(:,7);      y.E = X(:,8);    y.psi = X(:,12)*180/pi;
y.e = hypot(y.N_d - y.N, y.E_d - y.E);
end

function need(mdl, name)
if isempty(find_system(mdl,'BlockType','ToWorkspace','VariableName',name))
    error('W08_check:noLog', ...
      ['The model has no To Workspace block whose variable name is %s.\n' ...
       'It must carry [psi_d ; X ; N] with Save format\n' ...
       '''Structure With Time''.'], name);
end
end

function M = grab(S, w, name)
M = squeeze(S.signals.values);
if size(M,1) == w, M = M.'; end
if size(M,2) ~= w
    error('W08_check:width', '%s has %d columns; %d were expected.', ...
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
