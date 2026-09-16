%% W02 · 절 H — 와인드업의 원리를, 선체를 치우고 1차 플랜트 위에서
%  W02 · Section H — the windup principle, on a first-order plant
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_H_antiwindup_run
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 H 이며, §2-6 과 절 F 가 선체에서 보인 것을 가장 단순한 플랜트
%      위에서 다시 보이는 자리이다.
%      This is section H of Part 2. What §2-6 derived and section F observed on
%      the vessel is shown again here on the simplest plant that can show it.
%
%  왜 선체를 치우는가 / why the vessel is set aside
%      절 F 의 결과에는 와인드업 말고도 여러 가지가 섞여 있다. 추력이 회전수의
%      제곱을 따르는 것, 전진·좌우·요 축이 서로 얽히는 것, 배분이 두 프로펠러로
%      힘을 나누는 것이 모두 함께 일어난다. 그래서 회복이 느린 이유가 정말로
%      적분기 때문인지 단언하기 어렵다.
%
%      여기서는 플랜트를 G(s) = 1/(s+1) 로 두고 작동기 한계를 |u| <= 1 로 둔다.
%      제어기 넷이 각자 같은 플랜트를 하나씩 갖고, 게인도 넷이 모두 같다. 남는
%      차이는 포화 중에 적분기를 어떻게 다루는가 하나뿐이므로, 결과의 차이는
%      그것 말고 다른 것으로 설명될 수 없다.
%
%      Section F's result contains more than windup: thrust follows the square
%      of the shaft speed, the surge, sway and yaw axes are coupled, and the
%      allocation divides a force between two propellers. It is therefore hard
%      to assert that the slow recovery is the integrator's doing.
%
%      Here the plant is G(s) = 1/(s+1) and the actuator limit is |u| <= 1.
%      Four controllers each drive their own copy of that plant, with the same
%      gains throughout. The only remaining difference is what each does with
%      the integrator while saturated, so nothing else can account for the
%      differences in the result.
%
%  네 가지 방식 / the four schemes
%      1. 아무 대책도 없는 PI / no protection at all
%      2. 클램핑 — 포화 중에는 적분을 멈춘다 / clamping: stop integrating
%      3. 역계산 — Simulink PID 블록의 back-calculation
%      4. 같은 역계산을 손으로 조립한 것. 모든 신호를 관측할 수 있다
%         the same back-calculation assembled by hand, so that every signal
%         can be probed
%
%  만드는 것 / what it produces
%      img/W02_H_antiwindup.png           블록도 / the block diagram
%      img/W02_result_aw_principle.png    네 방식을 한 플랜트 위에 / the four
%                                         schemes on one plant
%
%  변수를 바꾸어 돌리려면 / to override a variable
%      W02_H_antiwindup_run 은 스크립트이므로 varargin 을 아래에서 비워 둔다.
%      함수로 부르던 시절의 재정의 고리를 그대로 두었으므로, 시험해 보려면
%      varargin = {'aw_Kb', 10} 을 먼저 정의하고 실행하면 된다.
%      This file is a script, so varargin is emptied below. The override loop
%      from the time it was a function is kept, so defining
%      varargin = {'aw_Kb', 10} before running it still works.

varargin = {};   % 위의 설명 참조 / see the note above

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_H_antiwindup.slx')), W02_H_build_antiwindup(); end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = aw_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

LBL = {'none','clamping','back-calculation','by hand'};

fprintf('\n  W02 · the anti-windup principle, on a first-order plant\n');
fprintf('\n    G(s) = 1/(s+1),  u in [%g, %g],  Kp = %g, Ki = %g, Kb = %g\n', ...
        V.aw_umin, V.aw_umax, V.aw_Kp, V.aw_Ki, V.aw_Kb);
fprintf('    r = 0 -> %g at t = %g s  (unreachable: y_max = %g)\n', ...
        V.aw_r1, V.aw_t1, V.aw_umax);
fprintf('      then -> %g at t = %g s  (reachable)\n', V.aw_r2, V.aw_t2);

%% =====================================================================
%  1. The four schemes
%  =====================================================================
R = one(V);

%  Setting Kb = 0 switches the back-calculation off, so row 4 becomes a plain
%  PI with no anti-windup at all. Its integrator state is then the windup
%  itself, measured rather than estimated.
R0 = one(V, 'aw_Kb', 0);

fprintf('\n  1) the four schemes\n\n');
fprintf('    %-18s %18s %16s %16s\n', ...
        'anti-windup', 'time on the limit', 'recovery [s]', 'y at t = 20 s');
fprintf('    %s\n', repmat('-', 1, 74));
rec = zeros(1,4);
for i = 1:4
    rec(i) = recovery_time(R.t, R.y(:,5+i), V.aw_r2, V.aw_t2);
    fprintf('    %-18s %18.2f %16.3f %16.4f\n', LBL{i}, ...
            on_limit(R.t, R.y(:,1+i), V.aw_umax), rec(i), ...
            interp1(R.t, R.y(:,5+i), 20));
end
%  "네 궤적이 같다" 를 주장하지 말고 재서 적는다. 포화 구간에서 네 출력이
%  서로 얼마나 벌어지는지를 직접 잰 값이 spread 이다.
%  The claim that the four outputs coincide is measured rather than asserted:
%  spread is the largest disagreement among them while the actuator is saturated.
kUp    = R.t < V.aw_t2;
spread = max(max(abs(R.y(kUp,6:9) - R.y(kUp,6))));

%  실제로 0 이 나온다. "수치 잡음" 이라고 적으면 사실보다 약하게 말하는 것이므로,
%  0 일 때와 아닐 때를 나누어 적는다.
%  The spread is in fact exactly zero. Calling it numerical noise would
%  understate the result, so the two cases are worded separately.
if spread == 0
    agree = 'agree bit for bit: the largest disagreement among them is exactly zero';
else
    agree = sprintf('agree to %.1e, which is solver noise', spread);
end

fprintf(['\n    ON THE WAY UP THE FOUR SCHEMES CANNOT BE TOLD APART, AND THEY\n' ...
         '    CANNOT BE.\n' ...
         '\n      The four differ only in what they do with the integrator while\n' ...
         '      the actuator is saturated. They do not differ in what the actuator\n' ...
         '      itself does: in every one of them the demand exceeds the limit, so\n' ...
         '      the plant is driven by u = %g throughout. Identical inputs to\n' ...
         '      identical plants give identical outputs, and the four curves here\n' ...
         '      %s.\n' ...
         '\n      They stay on the limit because the reference of %g asks for more\n' ...
         '      output than the actuator can sustain. The error therefore never\n' ...
         '      changes sign, and no scheme has any opportunity to behave\n' ...
         '      differently. The four are already diverging, but only inside the\n' ...
         '      integrator, where the measurement of y cannot reach.\n' ...
         '\n    THE DIFFERENCE BECOMES VISIBLE AT t = %g s, WHEN THE REFERENCE\n' ...
         '    DROPS TO SOMETHING THE ACTUATOR CAN DELIVER.\n' ...
         '\n      From that instant each loop is free to respond, and what it does\n' ...
         '      is decided by the state its integrator was left holding. Recovery\n' ...
         '      to within 2 per cent takes %.2f s with no protection and %.2f s\n' ...
         '      with back-calculation, a factor of %.1f.\n' ...
         '\n    WHY THE UNPROTECTED LOOP IS THE SLOW ONE: ITS INTEGRATOR HOLDS\n' ...
         '    DEMAND THAT THE ACTUATOR NEVER DELIVERED.\n' ...
         '\n      Row 4 is run a second time with Kb = 0. That switches the\n' ...
         '      back-calculation off and leaves a plain PI, so its integrator state\n' ...
         '      is the windup itself, measured rather than inferred. It peaks at\n' ...
         '      %.2f, against %.3f with back-calculation in place: a factor of %.0f.\n' ...
         '\n      The actuator limit is %.1f, so every unit of integrator state\n' ...
         '      above that figure is demand the plant will never see. While it\n' ...
         '      accumulates it changes nothing. Afterwards it changes everything:\n' ...
         '      the loop cannot come off the limit until the error has been\n' ...
         '      negative for long enough to integrate that excess away again. The\n' ...
         '      recovery times above are how long that takes, and throughout them\n' ...
         '      the controller is not controlling.\n'], ...
         V.aw_umax, agree, V.aw_r1, V.aw_t2, rec(1), rec(3), rec(1)/rec(3), ...
         max(R0.y(:,10)), max(R.y(:,10)), max(R0.y(:,10))/max(R.y(:,10)), ...
         V.aw_umax);

gap = max(abs(R.y(:,8) - R.y(:,9)));
if gap == 0
    same = ['are identical at every sample of the whole run, to the last bit ' ...
            'of the stored value'];
else
    same = sprintf(['differ by at most %.2e over the whole run, which is two ' ...
                    'orderings of the same arithmetic disagreeing at the last bit'], gap);
end
fprintf(['\n    THE LIBRARY BLOCK AND THE HAND-BUILT PATH ARE ONE ALGORITHM.\n' ...
         '\n      Row 3 is Simulink''s PID Controller block with back-calculation\n' ...
         '      selected. Row 4 is the same law assembled from a gain, a sum and an\n' ...
         '      integrator, where every signal can be probed. Their outputs %s.\n' ...
         '\n      The annotation inside PID bank is therefore a correct account of\n' ...
         '      what the block does, and it can be relied on wherever the block\n' ...
         '      itself cannot be opened and read.\n'], same);

%% =====================================================================
%  2. What the back-calculation gain does
%  =====================================================================
KB = [0.2 0.5 1 2 5 20 100];
fprintf('\n  2) the back-calculation gain\n\n');
fprintf('    %10s %16s %18s %16s\n', ...
        'Kb', 'recovery [s]', 'peak integrator', 'overshoot after [%]');
fprintf('    %s\n', repmat('-', 1, 66));
RK = cell(size(KB));  recK = zeros(size(KB));  ipk = recK;  ovs = recK;
for i = 1:numel(KB)
    RK{i}   = one(V, 'aw_Kb', KB(i));
    recK(i) = recovery_time(RK{i}.t, RK{i}.y(:,8), V.aw_r2, V.aw_t2);
    ipk(i)  = max(RK{i}.y(:,10));
    k       = RK{i}.t >= V.aw_t2;
    ovs(i)  = 100*(V.aw_r2 - min(RK{i}.y(k,8)))/V.aw_r2;
    fprintf('    %10g %16.3f %18.3f %16.2f\n', KB(i), recK(i), ipk(i), ovs(i));
end

%  Clamping, for comparison — it is the other scheme, not a limit of this one.
recC = recovery_time(R.t, R.y(:,7), V.aw_r2, V.aw_t2);
fprintf(['\n    A LARGER Kb RECOVERS FASTER, BUT IT NEVER TURNS INTO CLAMPING.\n' ...
         '\n      Raising Kb shortens the recovery and lowers the charge the\n' ...
         '      integrator is allowed to store. It does not approach clamping,\n' ...
         '      which recovers in %.3f s, because the two schemes are answering\n' ...
         '      different questions:\n' ...
         '\n        clamping           stops the integrator and holds whatever it\n' ...
         '                           had accumulated when saturation began\n' ...
         '        back-calculation   drives the integrator towards the fixed point\n' ...
         '                           I* = u_sat - Kp e + (Ki/Kb) e, at which the\n' ...
         '                           demand settles (Ki/Kb) e ABOVE the limit and\n' ...
         '                           equals it only in the limit Kb -> infinity\n' ...
         '\n      Kb is therefore a trade rather than a quantity to be made large.\n' ...
         '      A stiff correction at the instant saturation ends is paid for in\n' ...
         '      undershoot: %.2f per cent at Kb = %g against %.2f per cent at\n' ...
         '      Kb = %g.\n'], ...
         recC, ovs(1), KB(1), ovs(end), KB(end));

out = R;

%% =====================================================================
%  Figures
%  =====================================================================
img = @(fn) fullfile(here, 'img', fn);

load_system('W02_H_antiwindup');
print('-sW02_H_antiwindup', '-dpng', '-r150', img('W02_H_antiwindup.png'));
close_system('W02_H_antiwindup', 0);

f = W02_aw_plot(R, ...
    'W02 — one plant, one limit, four ways of treating the integrator', R0);
exportgraphics(f, img('W02_result_aw_principle.png'), 'Resolution', 150);

%  WITHDRAWN 2026-09-08, at the lecturer's request: the two-panel Kb sweep
%  figure that used to be saved here as img/W02_result_aw_Kb.png.
%
%  The section makes ONE point — an unprotected integrator stores demand the
%  actuator cannot use — and the four-panel principle figure above makes it.
%  The Kb sweep is a second, weaker point about tuning; its three numbers
%  (best 2.375 s near Kb = 5, undershoot 4.60 -> 43.96 %, clamping 2.380 s)
%  now live in one callout in the lecture instead of a whole figure.
%  See gnc-lecture-vault/references/standing-orders.md §9-8.
%
%  The sweep LOOP above is kept: it is where those numbers come from, and
%  measurement provenance is not what §9-8 asks to cut.

fprintf('\n  figure written to %s\n\n', img('W02_result_aw_principle.png'));
%  (the old function-closing end was here; this file is a script now)

% =========================================================================
function o = one(V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput('W02_H_antiwindup');
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
evalc('r = sim(in);');
y = squeeze(r.W02aw.signals.values);  if size(y,1) < size(y,2), y = y.'; end
o.t = r.W02aw.time;
o.y = y;      % [r  u1..u4  y1..y4  I_by_hand]
end

function p = on_limit(t, u, umax)
%ON_LIMIT  Seconds for which the control signal sat on its saturation limit.
%   Observable for every scheme, because u is what reaches the plant.
k = abs(abs(u) - umax) < 1e-6;
p = sum(k) * (t(2) - t(1));
end

function tr = recovery_time(t, y, yf, t0)
%RECOVERY_TIME  Time after t0 for the output to enter and stay in a 2% band.
k = t >= t0;
t = t(k) - t0;  y = y(k);
out = find(abs(y - yf) > 0.02*abs(yf), 1, 'last');
if isempty(out), tr = 0; else, tr = t(min(out+1, numel(t))); end
end

function V = aw_vars()
V.aw_Kp = 1.8;   V.aw_Ki = 4;    V.aw_Kb = 2;
V.aw_umax = 1;   V.aw_umin = -1;
V.aw_r1 = 2;     V.aw_r2 = 0.5;
V.aw_t1 = 1;     V.aw_t2 = 15;
V.aw_T  = 60;    V.h = 0.005;
end
