function [f, R] = W07_plot_wpt(pf)
%W07_PLOT_WPT  웨이포인트 추종 한 번의 결과 — 명령과 실제를 나란히.
%              One waypoint-following run: every command beside what happened.
%
%   W07_plot_wpt            모델의 StopFcn 이 이렇게 부른다 / the StopFcn path
%   W07_plot_wpt(prefix)    PNG 까지 저장한다. 러너가 이렇게 부른다 / with PNGs
%   [f, R] = W07_plot_wpt(…)  그림 핸들들과 수치 한 벌 / the handles and numbers
%
%   함수인 이유 / why this is a function and not a script
%       StopFcn 은 **기본 작업공간**에서 돈다. 스크립트로 두면 이 파일이 만드는
%       변수가 모델이 읽는 이름들(`h`·`u_d`·`Kp`·`T_wpt`) 과 같은 공간에 쌓이고,
%       한 번이라도 이름이 겹치면 다음 Run 의 물리가 조용히 달라진다. 함수는
%       자기 작업공간을 쓰므로 그 일이 일어날 수 없다. `W07_plot` 도 같다.
%       The StopFcn runs in the base workspace, where the model's own variables
%       live. A script would pile its working variables there, and one name
%       collision would silently change the physics of the next run. A function
%       has its own workspace, so it cannot happen.
%
%   읽는 로그 둘 / the two logs it reads
%       `W07wpt`      상태와 명령, 23 열 (`add_measurement`)
%       `W07wpt_act`  배분기의 24 열 기록 (`add_allocation_tilt4`)
%     로그 열 / the columns
%       1 u   2 v   3 r   4 N   5 E   6 psi [deg]
%       7 psi_d [deg]   8 u_d gated   9 y_e
%       10-12 tau asked [X Y N]       13-15 tau applied [X Y N]
%
%   그림 둘 / the two figures
%       (1) 명령 대 실제 — 속도·선수각·횡방향 오차·요구한 힘과 가해진 힘
%       (2) `W07_plot_sat` — rpm·추력·틸팅각이 한계 안에 있었는가
%     둘째 그림을 여기서 부르는 이유는, 첫째 그림이 "명령을 따라갔다" 를 말할 때
%     그것이 **한계를 넘지 않고** 된 것인지 바로 옆에서 보여야 하기 때문이다.
%
%   See also W07_PLOT_SAT, W07_WPT_RUN, W07WPT_ANIMATE, W07_3_BUILD_WPT.

if nargin < 1, pf = ''; end

%  러너가 돌리는 중이면 StopFcn 으로 온 호출은 그린다고 해 봐야 러너가 곧
%  같은 그림을 다시 그린다 / in batch the runner draws, so the StopFcn path
%  would only draw the same figure twice
if isempty(pf) && base_var('W07quiet', false)
    f = [];  R = struct();
    return
end

[t, y] = log_xy('W07wpt', 23);
if isempty(t)
    fprintf('  W07_plot_wpt: W07wpt 로그가 없다. 먼저 모델을 돌린다.\n');
    f = [];  R = struct();
    return
end

u      = y(:,1);
N      = y(:,4);   E   = y(:,5);   psi = y(:,6);
psi_d  = y(:,7);   u_c = y(:,8);   y_e = y(:,9);
tau_a  = y(:,10:12);               tau = y(:,13:15);

WP_N = base_var('WP_N', [0;60;60;0;60]);
WP_E = base_var('WP_E', [0;0;60;60;120]);
Rsw  = base_var('R_switch', 3);
Dl   = base_var('Delta', 5);
ud   = base_var('u_d', 1.0);

%  수치를 내는 구간을 **명시한다** / the window every statistic is taken over
%      첫 다리를 잡는 동안의 과도는 추종 성능이 아니다. 그래서 통계는 배가
%      첫 다리에 올라선 뒤부터 센다 — `|y_e|` 가 처음으로 Delta 아래로
%      내려간 시각부터 끝까지다 (§4-8: 평균·RMS 는 구간을 밝힌다).
%      The transient while the first leg is acquired is not tracking, so the
%      statistics start when |y_e| first falls below Delta.
k0 = find(abs(y_e) < Dl, 1, 'first');
if isempty(k0), k0 = 1; end
w  = k0:numel(t);

e_psi = wrap180(psi(w) - psi_d(w));

R = struct();
R.t_end   = t(end);
R.t_stat  = [t(k0), t(end)];
R.ye_max  = max(abs(y_e(w)));
R.ye_rms  = sqrt(mean(y_e(w).^2));
R.u_mean  = mean(u(w));
R.u_d     = ud;
R.psi_max = max(abs(e_psi));
R.psi_rms = sqrt(mean(e_psi.^2));
R.d_last  = hypot(N(end) - WP_N(end), E(end) - WP_E(end));
R.tau_max = [max(abs(tau(:,1))), max(abs(tau(:,2))), max(abs(tau(:,3)))];
%  요구가 의미 있는 표본에서만 센다 / only where a real demand was made:
%       0.5 N 아래의 요구는 배분기가 0 으로 세운다 (서보 떨림을 막는다).
%       below 0.5 N a unit the allocator holds the unit still, by design.
big     = max(abs(tau_a), [], 2) > 2.0;
R.short = 0;
if any(big), R.short = max(max(abs(tau_a(big,:) - tau(big,:)))); end

fprintf('\n  W07 waypoint following with allocation law 4\n');
fprintf('   run length                %8.2f s\n', R.t_end);
fprintf('   statistics window         %8.2f .. %.2f s  (from |y_e| < Delta)\n', R.t_stat);
fprintf('   cross-track |y_e|           max %6.3f m    rms %6.3f m\n', R.ye_max, R.ye_rms);
fprintf('   surge speed u             mean %6.3f m/s   command %5.3f m/s\n', R.u_mean, R.u_d);
fprintf('   heading error               max %6.3f deg  rms %6.3f deg\n', R.psi_max, R.psi_rms);
fprintf('   distance to last waypoint %8.3f m\n', R.d_last);
fprintf('   peak force on the hull    X %6.2f N   Y %6.2f N   N %6.2f N m\n', R.tau_max);
fprintf('   worst |asked - applied|   %8.4f  N, over the samples asking above 2 N\n', R.short);

%% ---- 그림 1 — 명령 대 실제 / figure 1, command against actual ---------
C = palette();
f = lab_fig('W07  waypoint following  -  command against actual', 1250, 780);

%  왼쪽 두 열에 여섯 칸, 오른쪽 한 열 전체가 궤적 / six panels left, track right
pan(f, 1, t, {u, u_c}, {'-','--'}, {C.act, C.cmd}, ...
    {'u  actual','u_d  command (gated)'}, 'u  [m/s]', ...
    'Surge speed: the inner loop against its command', false);

pan(f, 2, t, {psi, psi_d}, {'-','--'}, {C.act, C.cmd}, ...
    {'\psi  actual','\psi_d  from LOS'}, '\psi  [deg]', ...
    'Heading: the autopilot against the LOS command', false);

a4 = pan(f, 4, t, {y_e}, {'-'}, {C.aux}, {'y_e'}, 'y_e  [m]', ...
    sprintf('Cross-track error, the quantity LOS drives to zero (\\Delta = %g m)', Dl), true);
%  0 을 가운데 두고 양쪽을 같은 폭으로 — 자동 눈금은 음의 꼭짓점을 축선에
%  붙여 잘라 놓는다 / centre the zero line and leave a margin, or the negative
%  peak sits on the axis and reads as if it were cut off
ym = max(abs(y_e)) * 1.15;
if ym > 0, ylim(a4, [-ym ym]); end

pan(f, 5, t, {tau(:,1), tau_a(:,1)}, {'-','--'}, {C.act, C.cmd}, ...
    {'X applied','X asked'}, '\tau_X  [N]', ...
    'Surge force: asked by the loop, delivered by the four units', true);

a7 = pan(f, 7, t, {tau(:,2), tau_a(:,2)}, {'-','--'}, {C.sway, C.cmd}, ...
    {'Y applied','Y asked'}, '\tau_Y  [N]', ...
    'Sway force: this run asks for none, and gets none', true);
%  요구가 0 에 가까우면 눈금을 억지로 벌린다 — 안 그러면 반올림 오차가
%  신호처럼 보인다 / force a readable span, or rounding noise looks like signal
if max(abs([tau(:,2); tau_a(:,2)])) < 1, ylim(a7, [-1 1]); end

pan(f, 8, t, {tau(:,3), tau_a(:,3)}, {'-','--'}, {C.act, C.cmd}, ...
    {'N applied','N asked'}, '\tau_N  [N m]', ...
    'Yaw moment: asked and delivered', true);

ax = subplot(3, 3, [3 6 9], 'Parent', f);  hold(ax, 'on');
leg_marks(ax, WP_N, WP_E, Rsw);
plot(ax, E, N, '-', 'Color', C.act, 'LineWidth', 1.6, 'DisplayName', 'track');
track_ships({[N E psi]}, C.act, 'Marks', 9, 'MinLength', 2.00);
plot(ax, E(1), N(1), 'ks', 'MarkerFaceColor', 'w', 'MarkerSize', 7, ...
     'HandleVisibility', 'off');
xlabel(ax, 'East [m]');  ylabel(ax, 'North [m]');
pad = 0.08 * max([max(E)-min(E), max(N)-min(N), 8]);
xlim(ax, [min([E; WP_E])-pad, max([E; WP_E])+pad]);
ylim(ax, [min([N; WP_N])-pad, max([N; WP_N])+pad]);
daspect(ax, [1 1 1]);
title(ax, {'Track, with the hull drawn every few metres', ...
           'the line leaving the bow is the heading'}, 'FontSize', 9);
legend(ax, 'Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

sgtitle(f, sprintf(['W07 waypoint following, LOS outer loop and allocation law 4   ' ...
                    '|   \\Delta = %g m,  R = %g m,  u_d = %g m/s'], Dl, Rsw, ud), ...
        'FontSize', 11, 'FontWeight', 'bold');

savepng(f, pf, '_cmd');

%% ---- 그림 2 — 한계 / figure 2, the limits -----------------------------
A = base_var('W07wpt_act', []);
if isempty(A)
    fprintf('   W07wpt_act 가 없어 포화 그림은 건너뛴다.\n');
else
    [f2, Rs] = W07_plot_sat(A, t, 'waypoint following: are the four units inside their limits?', ...
                            sat_path(pf));
    f = [f, f2];
    R.sat = Rs;
end
end

% =========================================================================
function [t, y] = log_xy(nm, ncol)
%  Structure-With-Time 로그 하나를 시각과 행렬로 / one log as time and matrix
t = [];  y = [];
if ~evalin('base', sprintf('exist(''%s'',''var'')', nm)), return; end
W = evalin('base', nm);
if ~isstruct(W) || ~isfield(W, 'signals'), return; end
y = squeeze(W.signals.values);
if size(y,1) < size(y,2), y = y.'; end
if size(y,2) < ncol, y = [];  return; end
t = W.time(:);
end

% -------------------------------------------------------------------------
function C = palette()
%  `W07_anim` 과 **같은 색**이다. 실시간 화면에서 본 곡선과 저장된 그림의 곡선이
%  색까지 같아야 학생이 둘을 같은 것으로 읽는다
%  the same colours as W07_anim, so the live view and the saved figure match
C = struct('act',  [0    0.45 0.74], ...
           'cmd',  [0.75 0.10 0.10], ...
           'sway', [0.85 0.33 0.10], ...
           'aux',  [0.49 0.18 0.56], ...
           'grey', [0.40 0.40 0.40]);
end

% -------------------------------------------------------------------------
function a = pan(f, k, t, D, S, CL, NM, yl, ttl, zero)
%  3x3 격자의 왼쪽 두 열 한 칸 / one cell of the left two columns
a = subplot(3, 3, k, 'Parent', f);  hold(a, 'on');  grid(a, 'on');
for i = 1:numel(D)
    plot(a, t, D{i}, S{i}, 'Color', CL{i}, 'LineWidth', 1.4 + 0.3*(S{i}(1) == '-' && numel(S{i}) > 1), ...
         'DisplayName', NM{i});
end
if zero, yline(a, 0, 'k:', 'HandleVisibility', 'off'); end
xlabel(a, 'time [s]');  ylabel(a, yl);
xlim(a, [0 t(end)]);
title(a, ttl, 'FontSize', 9);
legend(a, 'Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');
end

% -------------------------------------------------------------------------
function leg_marks(a, WN, WE, Rsw)
%  다리와 전환 반지름을 **궤적보다 먼저** 그린다 / the legs go under the track
plot(a, WE, WN, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.1, ...
     'DisplayName', 'legs');
th = linspace(0, 2*pi, 73);
for k = 1:numel(WN)
    plot(a, WE(k) + Rsw*cos(th), WN(k) + Rsw*sin(th), '-', ...
         'Color', [0.70 0.70 0.70], 'LineWidth', 0.8, 'HandleVisibility', 'off');
    text(a, WE(k), WN(k) - 2.2, sprintf('%d', k), 'FontSize', 8, ...
         'HorizontalAlignment', 'center', 'Color', [0.30 0.30 0.30]);
end
plot(a, WE, WN, 'o', 'Color', [0.30 0.30 0.30], 'MarkerFaceColor', 'w', ...
     'MarkerSize', 5, 'DisplayName', 'waypoints');
end

% -------------------------------------------------------------------------
function e = wrap180(d)
e = mod(d + 180, 360) - 180;
end

% -------------------------------------------------------------------------
function p = sat_path(pf)
if isempty(pf), p = '';  else, p = [pf '_sat.png']; end
end

% -------------------------------------------------------------------------
function savepng(f, pf, suf)
if isempty(pf), return; end
p = [pf suf '.png'];
try
    exportgraphics(f, p, 'Resolution', 150);
catch
    print(f, p, '-dpng', '-r150');
end
fprintf('    saved %s\n', p);
end
