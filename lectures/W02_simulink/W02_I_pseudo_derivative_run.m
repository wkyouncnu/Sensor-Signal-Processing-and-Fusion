%% W02 · 절 I — 유사미분
%  W02 · Section I — the pseudo-derivative
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_I_pseudo_derivative_run
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 I 이며 §2-4 의 "유사미분" 절을 받는다. 이번 주의 서지 축은
%      미분이 도움이 되지 않는 축이었으므로, 절 A 부터 G 까지의 어디에서도
%      미분 필터가 무엇을 위한 것인지 드러나지 않았다. 이 절이 그 자리를 채운다.
%
%      This is section I of Part 2, and it answers the pseudo-derivative part
%      of §2-4. The surge axis of this week is one on which derivative action
%      does not help, so nothing in sections A to G showed what the derivative
%      filter is for. This section supplies that.
%
%  실험의 구성 / how the experiment is arranged
%      미분이 실제로 필요한 플랜트 하나를 가져와, 미분을 취하는 네 가지 방법을
%      같은 측정 잡음 아래에서 비교한다.
%        1. 미분 없음
%        2. 이상적인 미분  K_d s
%        3. 유사미분, N = 100 (거의 이상적인 것에 가깝다)
%        4. 유사미분, N = 10  (더 느리게 거른다)
%
%      A plant that genuinely wants derivative action, and four ways of taking
%      it, compared under the same measurement noise: no derivative, the ideal
%      K_d s, and the pseudo-derivative at N = 100 and at N = 10.
%
%      그다음 잡음을 끄고 같은 네 행을 다시 돌린다. 이것이 대조 실험이다.
%      잡음이 없는데도 행들이 갈라진다면 그 차이는 필터의 위상 지연이지 잡음
%      증폭이 아니며, 그러면 이 절의 논지 전체가 다른 이야기가 된다.
%
%      The four rows are then run again with the noise switched off. That is
%      the control experiment: if the rows still differed, the difference would
%      be the filter's phase lag rather than noise amplification, and the whole
%      argument of the section would be about something else.
%
%  만드는 것 / what it produces
%      표 셋, 블록도, 그리고 img/W02_result_pd.png
%      Three tables, the block diagram, and img/W02_result_pd.png

varargin = {};   % kept so the override loop below still works unchanged
%W02_PD_RUN  Run W02_I_pseudo_derivative.slx and report what the derivative filter buys.
%
%   W02_I_pseudo_derivative                      the four rows of section I
%   W02_I_pseudo_derivative('pd_noise', 0)       override any variable
%   out = W02_I_pseudo_derivative(...)           out.t, out.y
%
%   THE QUESTION
%
%   Derivative action is genuinely wanted on this plant. So how should the
%   derivative be taken? Four answers are run side by side against the same
%   noise, and the price of each is measured rather than asserted.
%
%   Produces
%     img/W02_I_pseudo_derivative.png              the block diagram
%     img/W02_result_pd.png           the four rows: output, actuator, D term
%     (the N sweep prints a table; its figure was withdrawn — see below)

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_I_pseudo_derivative.slx')), W02_I_build_pseudo_derivative(); end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = base_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

LBL = {'P only', 'ideal  K_d s', ...
       sprintf('pseudo  N = %g', V.pd_N1), ...
       sprintf('pseudo  N = %g', V.pd_N2)};

fprintf('\n  W02 · section I — the pseudo-derivative\n');
fprintf('\n    plant        G(s) = 1/(s^2 + 0.4 s)\n');
fprintf('    controller   Kp = %g, Kd = %g, derivative on the measurement\n', V.pd_Kp, V.pd_Kd);
fprintf('    sensor noise power %g at Ts = %g s  ->  std = %.4f\n', ...
        V.pd_noise, V.pd_ts, sqrt(V.pd_noise/V.pd_ts));

%% =====================================================================
%  1. The four rows, with noise
%  =====================================================================
R = one(V);
out = R;

fprintf('\n  1) the four rows, with the same measurement noise\n\n');
fprintf('    %-20s %11s %11s %13s %13s\n', ...
        'derivative', 'overshoot', 'settling', 'RMS(u) quiet', 'max |u|');
fprintf('    %s\n', repmat('-', 1, 74));

M = zeros(4,4);
for i = 1:4
    y = R.y(:,5+i);  u = R.y(:,1+i);
    M(i,1) = overshoot(R.t, y, V.pd_r, V.pd_t1);
    M(i,2) = settling(R.t, y, V.pd_r, V.pd_t1);
    M(i,3) = rms_after(R.t, u, V.pd_quiet);
    M(i,4) = max(abs(u));
    fprintf('    %-20s %10.2f%% %10.2fs %13.4f %13.2f\n', LBL{i}, M(i,:));
end

fprintf(['\n    RMS(u) quiet is measured after t = %g s, when the transient is\n' ...
         '    over and everything left in the actuator signal is noise.\n'], V.pd_quiet);

fprintf(['\n    THE DERIVATIVE IS WORTH HAVING ON THIS PLANT, AND THE IDEAL ONE\n' ...
         '    COSTS MORE THAN IT IS WORTH.\n' ...
         '\n      Row 1 has no derivative at all and overshoots %.1f per cent.\n' ...
         '      Row 2 adds an ideal derivative and cures that, bringing the\n' ...
         '      overshoot to %.1f per cent. Unlike the surge axis of section E,\n' ...
         '      this plant genuinely wants derivative action.\n' ...
         '\n      The price is paid by the actuator. Once the transient is over\n' ...
         '      and the loop should be sitting still, the RMS of row 2''s actuator\n' ...
         '      signal is %.0f times row 1''s, and it peaks at %.0f. An actuator\n' ...
         '      driven like that wears out, heats up, and on a real vessel is\n' ...
         '      audible from the bank.\n' ...
         '\n      Rows 3 and 4 filter the derivative. They keep the damping and\n' ...
         '      return the actuator to something a machine could survive.\n' ...
         '\n    WHY THE IDEAL DERIVATIVE BEHAVES THIS WAY.\n' ...
         '\n      An ideal differentiator is not a more accurate derivative. It is\n' ...
         '      the same operator with no upper bound on its gain: |j omega| = omega\n' ...
         '      grows without limit. Presented with a measurement, it finds the\n' ...
         '      fastest thing in it, which is the sensor noise and not the vessel,\n' ...
         '      and multiplies that by the largest number available. The signal it\n' ...
         '      amplifies most is the one carrying the least information.\n'], ...
         M(1,1), M(2,1), M(2,3)/M(1,3), M(2,4));

%% =====================================================================
%  2. Without noise, all four are nearly the same
%  =====================================================================
%  This is the control experiment. If the rows differed with the noise
%  switched off, the difference would be the filter's phase lag and not the
%  noise amplification, and the whole argument would be about something else.
Rq = one(setfield(V, 'pd_noise', 0));   %#ok<SFLD>
fprintf('\n  2) the same four rows with the noise switched off\n\n');
fprintf('    %-20s %11s %11s %13s\n', 'derivative', 'overshoot', 'settling', 'RMS(u) quiet');
fprintf('    %s\n', repmat('-', 1, 60));
Mq = zeros(4,3);
for i = 1:4
    y = Rq.y(:,5+i);  u = Rq.y(:,1+i);
    Mq(i,:) = [overshoot(Rq.t, y, V.pd_r, V.pd_t1), ...
               settling(Rq.t, y, V.pd_r, V.pd_t1), ...
               rms_after(Rq.t, u, V.pd_quiet)];
    fprintf('    %-20s %10.2f%% %10.2fs %13.6f\n', LBL{i}, Mq(i,:));
end
fprintf(['\n    THIS IS THE CONTROL EXPERIMENT, AND IT IDENTIFIES WHAT WAS BEING\n' ...
         '    MEASURED IN THE FIRST TABLE.\n' ...
         '\n      Every RMS in this table is essentially zero. With the noise\n' ...
         '      switched off there is nothing left for a derivative to amplify,\n' ...
         '      so the factor of %.0f separating rows 2 and 4 in experiment 1 was\n' ...
         '      noise amplification and nothing else. Had the rows still differed\n' ...
         '      here, the difference would have been the filter''s phase lag, and\n' ...
         '      the whole argument would have been about something else.\n' ...
         '\n    FILTERING THE DERIVATIVE IS NOT A CONCESSION.\n' ...
         '\n      Across rows 2 to 4 the overshoot changes by only %.1f points,\n' ...
         '      and the slower filter is the better of the three here rather than\n' ...
         '      the worse. At this value of N the filter costs nothing measurable\n' ...
         '      in the response and removes almost all of the noise, so there is\n' ...
         '      nothing to trade.\n'], ...
         M(2,3)/M(4,3), max(Mq(2:4,1)) - min(Mq(2:4,1)));

%% =====================================================================
%  3. Sweeping N — the trade, in one table
%  =====================================================================
NS  = [2 5 10 20 50 100 200 500];
sw  = zeros(numel(NS), 3);
fprintf('\n  3) sweeping the filter coefficient N\n\n');
fprintf('    %8s %13s %12s %13s\n', 'N', 'overshoot', 'settling', 'RMS(u) quiet');
fprintf('    %s\n', repmat('-', 1, 50));
for k = 1:numel(NS)
    Rk = one(V, 'pd_N2', NS(k));
    y  = Rk.y(:,9);  u = Rk.y(:,5);          % row 4 is the swept one
    sw(k,:) = [overshoot(Rk.t, y, V.pd_r, V.pd_t1), ...
               settling(Rk.t, y, V.pd_r, V.pd_t1), ...
               rms_after(Rk.t, u, V.pd_quiet)];
    fprintf('    %8g %12.2f%% %11.2fs %13.4f\n', NS(k), sw(k,:));
end
[~, kb] = min(sw(:,1));
fprintf(['\n    The two columns do NOT trade off across the whole range. Overshoot\n' ...
         '    is worst at N = %g, best at N = %g, and then creeps back up and\n' ...
         '    FLATTENS -- from N = %g to N = %g it changes by %.1f points while\n' ...
         '    RMS(u) grows by a factor of %.0f.\n'], ...
         NS(1), NS(kb), NS(end-2), NS(end), ...
         sw(end,1)-sw(end-2,1), sw(end,3)/sw(end-2,3));
fprintf(['\n    So there are two regimes, not one trade:\n' ...
         '      N below about %g   the derivative arrives late, damping is lost\n' ...
         '      N above about %g   the response stops improving, the noise does not\n' ...
         '\n    Large N is not a safe default. It buys nothing and charges for it.\n' ...
         '    Choose N just above the closed-loop bandwidth -- here wn = %.1f rad/s\n' ...
         '    -- and no higher.\n'], NS(kb), NS(kb), sqrt(V.pd_Kp));

%% =====================================================================
%  Figures
%  =====================================================================
img = @(f) fullfile(here, 'img', f);
COL = [0.47 0.67 0.19; 0.85 0.33 0.10; 0.00 0.45 0.74; 0.49 0.18 0.56];

load_system('W02_I_pseudo_derivative');
print('-sW02_I_pseudo_derivative', '-dpng', '-r150', img('W02_I_pseudo_derivative.png'));
close_system('W02_I_pseudo_derivative', 0);

f = W02_pd_plot({R}, LBL, V, ...
    'W02 section I — one derivative, taken four ways, against the same noise');
exportgraphics(f, img('W02_result_pd.png'), 'Resolution', 150);

%  WITHDRAWN 2026-09-08, at the lecturer's request: the two-panel N sweep
%  figure that used to be saved here as img/W02_result_pd_N.png.
%
%  The section makes ONE point — an ideal derivative amplifies measurement
%  noise without bound, a filtered one does not — and the figure above makes
%  it. Where to put N is a rule, not a second picture; the lecture now states
%  it in one callout backed by the sweep TABLE printed above.
%  See gnc-lecture-vault/references/standing-orders.md §9-8.
%
%  The sweep LOOP is kept: it is where the numbers in that callout come from,
%  and measurement provenance is not what §9-8 asks to cut.

fprintf('\n  figure written to %s\n\n', img('W02_result_pd.png'));
%  (the old function-closing end was here; this file is a script now)

% =========================================================================
function o = one(V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput('W02_I_pseudo_derivative');
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
evalc('r = sim(in);');
y = squeeze(r.W02pd.signals.values);
if size(y,1) < size(y,2), y = y.'; end
o.t = r.W02pd.time;
o.y = y;              % [r  u1..u4  y1..y4  d1..d4]
end

function p = overshoot(t, y, r, t0)
k = t >= t0;
p = 100*(max(y(k)) - r)/r;
if p < 0, p = 0; end
end

function ts = settling(t, y, r, t0)
%SETTLING  First time after t0 from which y stays inside a 2% band on r.
k    = find(t >= t0);
band = 0.02*abs(r);
out  = find(abs(y(k) - r) > band, 1, 'last');
if isempty(out), ts = 0; else, ts = t(k(min(out+1, numel(k)))) - t0; end
end

function v = rms_after(t, u, t0)
%RMS_AFTER  RMS of the actuator signal about its own mean, after t0.
%   The mean is removed because it is the steady demand, not activity.
k = t >= t0;
v = sqrt(mean((u(k) - mean(u(k))).^2));
end

function V = base_vars()
V.pd_Kp    = 4;          % proportional gain
V.pd_Kd    = 2;          % derivative gain, same in all four rows
V.pd_N1    = 100;        % fast filter
V.pd_N2    = 10;         % slower filter
V.pd_r     = 1;          % step height
V.pd_t1    = 1;          % step time [s]
V.pd_T     = 20;         % run length [s]
V.pd_quiet = 12;         % after this, the transient is over [s]
V.pd_noise = 1e-6;       % noise power  -> std = sqrt(Cov/Ts) = 0.01
V.pd_ts    = 0.01;       % noise sample time [s]
V.h        = 0.001;      % solver step [s] — small, the ideal derivative needs it
end
