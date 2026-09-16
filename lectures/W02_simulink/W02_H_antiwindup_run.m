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
%      여기서는 플랜트를 G(s) = 1/s 로 두고 작동기 한계를 |u| <= 1 로 둔다.
%      제어기 넷이 각자 같은 플랜트를 하나씩 갖고, 게인도 넷이 모두 같다. 남는
%      차이는 포화 중에 적분기를 어떻게 다루는가 하나뿐이므로, 결과의 차이는
%      그것 말고 다른 것으로 설명될 수 없다.
%
%      Section F's result contains more than windup: thrust follows the square
%      of the shaft speed, the surge, sway and yaw axes are coupled, and the
%      allocation divides a force between two propellers. It is therefore hard
%      to assert that the slow recovery is the integrator's doing.
%
%      Here the plant is G(s) = 1/s and the actuator limit is |u| <= 1. Four
%      controllers each drive their own copy of that plant, with the same gains
%      throughout. The only remaining difference is what each does with the
%      integrator while saturated, so nothing else can account for the
%      differences in the result.
%
%  왜 하필 이 구성인가 / why this particular arrangement
%      임의로 고른 값이 아니다. Franklin, *Feedback Control of Dynamic Systems*,
%      8판, 2019, 그림 9.22 의 구성 그대로이다 — 플랜트 1/s, kp = 2, kI = 4,
%      Ka = 10, |u| <= 1, 단위 계단. 그림 9.23 과 9.24 가 그 응답을 싣는다.
%
%      출판된 예제를 쓰면 이 절의 결과를 강의 밖의 것과 대조할 수 있다. 스스로와
%      일치하는 것보다 출판된 그림을 재현하는 것이 강한 진술이다 — 플랜트, 게인,
%      포화, 안티와인드업을 한꺼번에, 이 강의가 쓰지 않은 구현에 대고 검사한다.
%
%      These are not values chosen at random. They are the arrangement of
%      Franklin, *Feedback Control of Dynamic Systems*, 8th ed., 2019, Fig. 9.22
%      — a plant of 1/s with kp = 2, kI = 4, Ka = 10, |u| <= 1 and a unit step —
%      whose response is printed in Figs. 9.23 and 9.24. Using a published
%      example lets this section be compared with something from outside the
%      course, and reproducing a published figure is a stronger statement than
%      agreeing with oneself: it checks the plant, the gains, the saturation and
%      the anti-windup at once, against an implementation nobody here wrote.
%
%      주의 — 출처의 Ka 와 이 모델의 Kb 는 같은 수가 아니다. Franklin 은 게인을
%      적분게인 안쪽에 두므로 K_aw = kI Ka = 40 이다. §2-6 이 그 관계를 다룬다.
%      Note that the source's Ka and this model's Kb are not the same number:
%      Franklin places the gain inside the integral gain, so K_aw = kI Ka = 40.
%      §2-6 works through the relation.
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

fprintf('\n  W02 · the anti-windup principle, on the example of Franklin 8E Fig. 9.22\n');
fprintf('\n    G(s) = 1/s,  u in [%g, %g],  kp = %g, kI = %g\n', ...
        V.aw_umin, V.aw_umax, V.aw_Kp, V.aw_Ki);
fprintf('    Ka = %g in the source, which is K_aw = kI Ka = %g here  (see 2-6)\n', ...
        V.aw_Ka, V.aw_Kb);
fprintf('    r = 0 -> %g at t = %g s, and the actuator saturates on the way\n', ...
        V.aw_r1, V.aw_t1);

%% =====================================================================
%  1. The four schemes
%  =====================================================================
R = one(V);

%  Kb = 0 은 역계산을 꺼서 4행을 보호 없는 PI 로 만든다. 그러면 그 적분기 상태가
%  와인드업 그 자체이고, 추정이 아니라 측정이 된다.
%  Setting Kb = 0 switches the back-calculation off, so row 4 becomes a plain PI
%  and its integrator state is the windup itself, measured rather than inferred.
R0 = one(V, 'aw_Kb', 0);

fprintf('\n  1) the four schemes\n\n');
fprintf('    %-18s %18s %16s %16s\n', ...
        'anti-windup', 'time on the limit', 'overshoot [%]', 'settling [s]');
fprintf('    %s\n', repmat('-', 1, 74));
ovs = zeros(1,4);  set2 = zeros(1,4);
for i = 1:4
    y        = R.y(:, 5+i);
    ovs(i)   = 100*(max(y) - V.aw_r1)/V.aw_r1;
    set2(i)  = settle2(R.t, y, V.aw_r1);
    fprintf('    %-18s %18.2f %16.2f %16.3f\n', LBL{i}, ...
            on_limit(R.t, R.y(:,1+i), V.aw_umax), ovs(i), set2(i));
end

%  출처의 그림 9.23 이 싣는 값과 나란히 놓는다. 인용이 장식이 아니라 대조가 되게.
%  Placed beside the values of Fig. 9.23 in the source, so that the citation is
%  a comparison rather than an ornament.
fprintf(['\n    AGAINST THE PUBLISHED FIGURE.\n' ...
         '\n      Figure 9.23 of Franklin 8E shows the output of this system\n' ...
         '      overshooting to about 1.53 without anti-windup and to about\n' ...
         '      1.15 with it. Measured here: %.2f and %.2f.\n' ...
         '\n      Reproducing a published result is worth more than agreeing\n' ...
         '      with oneself. It checks the plant, the gains, the saturation\n' ...
         '      and the anti-windup at once, against an implementation nobody\n' ...
         '      in this course wrote.\n'], ...
         1 + ovs(1)/100, 1 + ovs(3)/100);

%  창을 "네 방식이 **모두** 한계에 앉아 있는 동안" 으로 잡는다. 임의로 1 s 를
%  잡았더니 그 안에서 이미 클램핑이 한계를 떠나 있어서, 실재하는 차이 6.3e-02 를
%  "솔버 잡음" 이라고 적을 뻔했다. 창은 주장에 맞추어 정한다.
%  The window is the interval over which all four are still on the limit. Fixed
%  at one second it already contained the instant clamping came off, and a real
%  difference of 6.3e-02 was about to be described as solver noise. The window
%  has to follow the claim.
satAll = all(abs(abs(R.y(:,2:5)) - V.aw_umax) < 1e-9, 2);
kOff   = find(~satAll, 1);
kUp    = false(size(satAll));  kUp(1:kOff-1) = true;
spread = max(max(abs(R.y(kUp,6:9) - R.y(kUp,6))));
if spread == 0
    agree = sprintf(['agree bit for bit over the %.2f s for which all four are ' ...
                     'still on the limit'], R.t(kOff-1));
else
    agree = sprintf(['agree to %.1e over the %.2f s for which all four are ' ...
                     'still on the limit'], spread, R.t(kOff-1));
end

fprintf(['\n    WHILE THE ACTUATOR IS SATURATED THE FOUR CANNOT BE TOLD APART,\n' ...
         '    AND THEY CANNOT BE.\n' ...
         '\n      The four differ only in what they do with the integrator while\n' ...
         '      the actuator is saturated. They do not differ in what the actuator\n' ...
         '      itself does: in every one of them the demand exceeds the limit, so\n' ...
         '      the plant is driven by u = %g throughout. Identical inputs to\n' ...
         '      identical plants give identical outputs, and the four curves %s.\n' ...
         '\n      They stay on the limit because kp e alone is %g at t = 0, already\n' ...
         '      above the limit of %g, and the integrator only adds to it. The four\n' ...
         '      are already diverging, but inside the integrator, where the\n' ...
         '      measurement of y cannot reach.\n' ...
         '\n    THE DIFFERENCE BECOMES VISIBLE WHEN THE DEMAND FALLS BACK THROUGH\n' ...
         '    THE LIMIT.\n' ...
         '\n      From that instant each loop is free to respond, and what it does\n' ...
         '      is decided by the state its integrator was left holding. The\n' ...
         '      unprotected loop overshoots to %.2f and settles in %.2f s; with\n' ...
         '      back-calculation, %.2f and %.2f s.\n' ...
         '\n    WHY THE UNPROTECTED LOOP IS THE WORSE ONE: ITS INTEGRATOR HOLDS\n' ...
         '    DEMAND THAT THE ACTUATOR NEVER DELIVERED.\n' ...
         '\n      Row 4 is run a second time with Kb = 0, which leaves a plain PI,\n' ...
         '      so its integrator state is the windup itself. It peaks at %.2f,\n' ...
         '      against %.3f with back-calculation in place: a factor of %.1f.\n' ...
         '\n      The actuator limit is %g, so every unit of integrator state above\n' ...
         '      that figure is demand the plant will never see. While it\n' ...
         '      accumulates it changes nothing. Afterwards it changes everything:\n' ...
         '      the loop cannot come off the limit until the error has been\n' ...
         '      negative long enough to integrate that excess away, and the\n' ...
         '      overshoot above is how far the output travels meanwhile.\n'], ...
         V.aw_umax, agree, V.aw_Kp*V.aw_r1, V.aw_umax, ...
         1 + ovs(1)/100, set2(1), 1 + ovs(3)/100, set2(3), ...
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
%  Franklin 의 Ka = 10 은 여기서 Kb = 40 이다. 그 값을 가운데 두고 쓸어 본다.
%  Franklin's Ka = 10 is Kb = 40 here; the sweep is centred on it.
KB = [1 4 10 40 100 400];
fprintf('\n  2) the back-calculation gain\n\n');
fprintf('    %10s %12s %16s %18s %14s\n', ...
        'Kb', 'T_t = 1/Kb', 'overshoot [%]', 'peak integrator', 'settling [s]');
fprintf('    %s\n', repmat('-', 1, 76));
recK = zeros(size(KB));  ipk = recK;  ovsK = recK;
for i = 1:numel(KB)
    Rk      = one(V, 'aw_Kb', KB(i));
    y       = Rk.y(:,8);                    % 3행, 라이브러리 블록의 역계산
    ovsK(i) = 100*(max(y) - V.aw_r1)/V.aw_r1;
    ipk(i)  = max(Rk.y(:,10));
    recK(i) = settle2(Rk.t, y, V.aw_r1);
    fprintf('    %10g %12.4f %16.2f %18.3f %14.3f\n', ...
            KB(i), 1/KB(i), ovsK(i), ipk(i), recK(i));
end

%  클램핑을 옆에 둔다 — 이 방식의 극한이 아니라 다른 방식이다.
%  Clamping, for comparison: it is the other scheme, not a limit of this one.
ovsC = 100*(max(R.y(:,7)) - V.aw_r1)/V.aw_r1;
fprintf(['\n    A LARGER Kb OVERSHOOTS LESS, BUT IT NEVER TURNS INTO CLAMPING.\n' ...
         '\n      Raising Kb shortens the tracking time constant T_t = 1/Kb and\n' ...
         '      lowers the charge the integrator is allowed to store. It does not\n' ...
         '      approach clamping, which overshoots %.2f per cent, because the two\n' ...
         '      schemes are answering different questions:\n' ...
         '\n        clamping           stops the integrator and holds whatever it\n' ...
         '                           had accumulated when saturation began\n' ...
         '        back-calculation   drives the integrator towards the fixed point\n' ...
         '                           I* = u_sat - kp e + (kI/Kb) e, at which the\n' ...
         '                           demand still stands (kI/Kb) e ABOVE the limit\n' ...
         '                           and equals it only in the limit Kb -> infinity\n' ...
         '\n      The two therefore settle at different integrator values, which is\n' ...
         '      why raising the back-calculation gain never turns one scheme into\n' ...
         '      the other.\n' ...
         '\n      The source''s choice, Kb = %g, overshoots %.2f per cent. Going ten\n' ...
         '      times further to Kb = %g buys %.2f per cent more, which is the\n' ...
         '      shape of every gain in this course: the first order of magnitude\n' ...
         '      does the work and the next one does not.\n'], ...
         ovsC, V.aw_Kb, ovsK(KB == V.aw_Kb), KB(end), ...
         ovsK(KB == V.aw_Kb) - ovsK(end));

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
%  The Kb sweep is a second, weaker point about tuning, and its numbers now
%  live in one table in the lecture instead of a whole figure.
%  See gnc-lecture-vault/references/standing-orders.md §9-8.
%
%  2026-09-16 에 이 절의 구성을 Franklin 8E 그림 9.22 로 바꾸었으므로, 그 표의
%  수도 함께 바뀌었다. 여기에 옛 수를 적어 두지 않는다 — 스크립트가 찍는 값이
%  강의의 값이고, 손으로 옮겨 적은 수는 언젠가 그것과 갈라진다.
%  The arrangement of this section became that of Franklin 8E Fig. 9.22 on
%  2026-09-16, so the numbers in that table changed with it. None are repeated
%  here: what the script prints is what the lecture carries, and a number
%  transcribed by hand eventually parts company with it.
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

function ts = settle2(t, y, yf)
%SETTLE2  출력이 yf 의 2 퍼센트 띠 안에 들어가 **머무르기** 시작한 시각.
%         The instant after which the output stays inside a 2 per cent band.
%
%  처음 들어간 시각이 아니라 마지막으로 벗어난 시각을 쓴다. 지나가는 길에 띠를
%  가로지른 응답은 정착한 것이 아니기 때문이며, _tools/recovery_time.m 과 같은
%  정의이다. 여기서는 계단이 t = 0 에 있으므로 기준 시각이 없다.
%
%  The last exit from the band is taken rather than the first entry, because a
%  response that crosses the band on its way past has not settled. It is the
%  definition used by _tools/recovery_time.m; here the step is at t = 0, so
%  there is no reference instant to measure from.
out = find(abs(y - yf) > 0.02*abs(yf), 1, 'last');
if isempty(out), ts = 0; else, ts = t(min(out+1, numel(t))); end
end

function V = aw_vars()
%AW_VARS  Franklin 8E 그림 9.22 의 구성 그대로.
%         The arrangement of Franklin 8E, Fig. 9.22, unchanged.
%
%  플랜트 1/s, kp = 2, kI = 4, Ka = 10, |u| <= 1, 단위 계단.
%  A plant of 1/s, kp = 2, kI = 4, Ka = 10, |u| <= 1, and a unit step.
%
%  Ka 를 그대로 Kb 로 쓰지 않는다. Franklin 은 게인을 적분게인 **안쪽**에 두므로
%  그의 Ka 는 이 강의의 K_aw 와 같은 수가 아니다 (§2-4 · §2-6):
%      dI/dt = kI [ e - Ka (u - u_sat) ]  =  kI e - (kI Ka)(u - u_sat)
%  따라서 K_aw = kI Ka = 40 이다. 10 을 그대로 옮겨 적으면 추종 시상수가 네 배
%  느려진다.
%
%  Ka is not carried across as Kb. Franklin places the gain inside the integral
%  gain, so his Ka is not the same number as this course's K_aw: expanding his
%  form gives K_aw = kI Ka = 40. Copying the 10 across would make the tracking
%  time constant four times slower than the source intended.
V.aw_Kp = 2;     V.aw_Ki = 4;     V.aw_Ka = 10;
V.aw_Kb = V.aw_Ki * V.aw_Ka;      % = 40, 바깥 형태의 게인 / the outside gain

V.aw_umax = 1;   V.aw_umin = -1;

%  단위 계단 하나. 두 번째 계단은 꺼 둔다 (r2 = r1).
%  One unit step; the second is switched off by setting r2 = r1.
V.aw_r1 = 1;     V.aw_r2 = 1;
V.aw_t1 = 0;     V.aw_t2 = 1e6;

%  그림 9.23 과 9.24 가 0 에서 10 s 를 싣는다.
%  Figures 9.23 and 9.24 of the source run from 0 to 10 s.
V.aw_T  = 10;    V.h = 0.001;
end
