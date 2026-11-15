function W07_anim(y, t, o)
%W07_ANIM  닫힌 루프 두 모델의 실시간 화면 하나 / the live view, shared by both
%          closed-loop models of Week 7.
%
%   W07_anim(y, t, o)      래퍼가 매 스텝 부른다 / called by the wrapper
%
%   왜 함수 하나인가 / why one function
%       `W07_wpt_los` 와 `W07_pose_dp` 는 고리 구성이 다르지만 화면에서 묻는
%       것은 같다 — **명령을 따라갔는가**, 그리고 **배가 어디를 향했는가**.
%       그래서 그리는 쪽은 하나로 두고, 주차가 아니라 **모델마다** 다른 것만
%       래퍼가 `o` 로 넘긴다. 복사해 두면 한쪽만 고쳐진다 (§15-34).
%       The two models have different loop structures but the live view asks the
%       same two questions: was the command followed, and where was the bow
%       pointing. The drawing therefore lives here once and each wrapper passes
%       only what differs. A copy would drift.
%
%   이 창의 규칙 하나 / the one rule of this window
%       **점선이 명령, 실선이 실제**다. 모든 칸이 같다. 실선을 먼저 만들고
%       점선을 나중에 만들므로, 잘 따라간 구간에서 점선이 실선 위에 올라타
%       둘이 함께 보인다. 반대로 두면 명령이 실선 아래로 사라지고, 그 구간이
%       하필 **가장 잘 된** 구간이다.
%       Dashed is the command and solid is the actual, in every panel. The solid
%       line is created first so the dashed command rides on top: the other way
%       round the command vanishes exactly where the tracking is best.
%
%   입력 / inputs
%     y   그 스텝의 **로그 벡터 전부**. `add_measurement` 의 `opts.logFeed` 가
%         켜져 있어 상태 여섯이 아니라 기록되는 열 전부가 들어온다. 앞 여섯은
%         모든 주차가 같다 — `[u v r N E psi]` 이고 **psi 는 도**다
%         the whole log vector of this step; with opts.logFeed the block hands
%         over every logged column, not the six states. The first six are the
%         same in every week, and psi arrives in DEGREES
%     t   시각 [s] / the clock
%     o   모델마다 다른 것 / what differs between the two models
%           .tag      창의 Tag / the figure Tag
%           .name     창 제목 / the window title
%           .lim      [Emin Emax Nmin Nmax] 처음 축 / the opening limits
%           .wp       웨이포인트 n x 2 = [N E], 없으면 [] / the waypoints or []
%           .goal     [N E psi_deg] 목표 자세, 없으면 [] / the target pose or []
%           .cmdNE    명령 위치의 열 둘 [cN cE], 없으면 [] / columns or []
%           .info     제목에 쓸 {이름, 열, 배율} 목록 / the title readouts
%           .panels   오른쪽 칸들. 한 칸이 중괄호 하나다 / one brace per panel
%                       {ylabel, [열…], {선모양…}, {색이름…}, {범례…}, 0선}
%
%   색 이름 / the colour keys
%       'act' 실제 · 'cmd' 명령 · 'sway' 횡방향 · 'aux' 보조 · 'grey' 회색
%
%   See also W07WPT_ANIMATE, W07POSE_ANIMATE, W07_PLOT_WPT, W07_PLOT_POSE.

persistent fig ax h S tLast tPrev every

NMAX = 40000;                      % 기록을 무한히 늘리지 않는다 / cap the series
y    = y(:).';

%  새 Run 인가. 시각이 뒤로 갔거나 창이 닫혔으면 새 Run 이다
%  a new run: the clock went backwards, or the window is gone
newRun = isempty(tLast) || isempty(fig) || ~isvalid(fig) || t < tPrev;
tPrev  = t;

if newRun
    S     = struct('t', zeros(0,1), 'Y', zeros(0, numel(y)));
    tLast = -inf;
    every = base_var('animate_every', 0.5);
    [fig, ax, h] = build_window(o, y);
end

%  표본을 쌓는다 / append this sample
S.t = [S.t; t];
S.Y = [S.Y; y];
if numel(S.t) > NMAX
    S.t = S.t(end-NMAX+1:end);
    S.Y = S.Y(end-NMAX+1:end, :);
end

%  그리는 간격. 매 스텝 그리면 시뮬레이션보다 그림이 느려진다
%  the redraw interval: drawing every step makes the picture the bottleneck
if t - tLast < every, return; end
tLast = t;

N = y(4);  E = y(5);  psi = y(6);          % psi 는 **도** / psi in degrees

%% ---- 왼쪽: 항적 / left: the track ------------------------------------
set(h.trail, 'XData', S.Y(:,5), 'YData', S.Y(:,4));
[hE, hN] = hull_ned(N, E, psi*pi/180);
set(h.hull, 'XData', hE, 'YData', hN);
set(h.head, 'XData', [E, E + 3.2*sind(psi)], ...
            'YData', [N, N + 3.2*cosd(psi)]);
set(h.dot,  'XData', E, 'YData', N);
fit_lims(ax.xy, E, N, 3);

%  명령 위치가 있는 모델이면 그 자취도 함께 / the commanded position, if any
if ~isempty(o.cmdNE)
    set(h.cmd,  'XData', S.Y(:,o.cmdNE(2)), 'YData', S.Y(:,o.cmdNE(1)));
    set(h.mark, 'XData', y(o.cmdNE(2)),     'YData', y(o.cmdNE(1)));
    fit_lims(ax.xy, y(o.cmdNE(2)), y(o.cmdNE(1)), 3);
end

set(h.info, 'String', info_lines(t, y, o));

%% ---- 오른쪽: 명령 대 실제 / right: command against actual ------------
for k = 1:numel(o.panels)
    c = o.panels{k}{2};
    for j = 1:numel(c)
        set(h.p{k}(j), 'XData', S.t, 'YData', S.Y(:,c(j)));
    end
    pad_y(ax.p(k), reshape(S.Y(:,c), [], 1));
    set(ax.p(k), 'XLim', [0 max(t, 1)]);
end

drawnow limitrate
end

% =========================================================================
function [fig, ax, h] = build_window(o, y)
%  창 하나를 짓는다. 축과 핸들을 돌려주므로 매 스텝 `set` 만 한다
%  build the window once; every step afterwards is a set() on these handles

P   = palette();
np  = numel(o.panels);

old = findall(0, 'Type','figure', 'Tag', o.tag);
if ~isempty(old), delete(old); end
fig = lab_fig(o.name, 1340, min(900, 180 + 170*np));
set(fig, 'Tag', o.tag);

N = y(4);  E = y(5);

%% ---- 항적 / the track ------------------------------------------------
ax.xy = subplot(np, 2, 1:2:(2*np-1), 'Parent', fig);
hold(ax.xy, 'on');  grid(ax.xy, 'on');  axis(ax.xy, 'equal');
xlabel(ax.xy, 'east [m]');  ylabel(ax.xy, 'north [m]');

%  웨이포인트와 다리, 그리고 전환 반지름 / the waypoints, the legs, the circles
if ~isempty(o.wp)
    R = base_var('R_switch', 3);
    plot(ax.xy, o.wp(:,2), o.wp(:,1), '-', 'Color', P.grey, ...
         'LineWidth', 1.1, 'DisplayName', 'the legs');
    plot(ax.xy, o.wp(:,2), o.wp(:,1), 'o', 'MarkerSize', 6, ...
         'MarkerEdgeColor', P.grey, 'MarkerFaceColor', 'w', ...
         'DisplayName', 'waypoints');
    for i = 1:size(o.wp, 1)
        circle(ax.xy, o.wp(i,2), o.wp(i,1), R, P.grey);
        text(ax.xy, o.wp(i,2) + 2.0, o.wp(i,1) + 2.0, sprintf('%d', i), ...
             'FontSize', 8, 'Color', P.grey);
    end
end

%  목표 자세는 **점선 선체**로. 점 하나로는 선수각 명령이 보이지 않는다
%  the target pose as a dashed hull: a marker alone cannot show a heading
if ~isempty(o.goal)
    [gE, gN] = hull_ned(o.goal(1), o.goal(2), o.goal(3)*pi/180);
    patch('Parent', ax.xy, 'XData', gE, 'YData', gN, 'FaceColor','none', ...
          'EdgeColor', P.cmd, 'LineStyle','--', 'LineWidth', 1.1, ...
          'DisplayName', 'target pose');
    plot(ax.xy, o.goal(2), o.goal(1), 'p', 'MarkerSize', 11, ...
         'MarkerEdgeColor', P.cmd, 'MarkerFaceColor', [0.95 0.75 0.75], ...
         'HandleVisibility','off');
end

%  출발점. 어디서 시작했는지가 항적의 절반이다 / where the run began
plot(ax.xy, E, N, 'x', 'MarkerSize', 9, 'LineWidth', 1.4, ...
     'Color', P.grey, 'HandleVisibility','off');
text(ax.xy, E + 1.0, N - 1.6, 'start', 'FontSize', 8, 'Color', P.grey);

h.cmd   = plot(ax.xy, nan, nan, '--', 'Color', P.cmd, 'LineWidth', 1.2, ...
               'DisplayName', 'commanded position');
h.mark  = plot(ax.xy, nan, nan, 's', 'MarkerSize', 8, 'LineWidth', 1.2, ...
               'MarkerEdgeColor', P.cmd, 'MarkerFaceColor','none', ...
               'DisplayName', 'command now');
h.trail = plot(ax.xy, nan, nan, '-', 'Color', P.act, 'LineWidth', 1.4, ...
               'DisplayName', 'actual track');
h.hull  = patch('Parent', ax.xy, 'XData', nan, 'YData', nan, ...
                'FaceColor', [0.95 0.45 0.20], 'FaceAlpha', 0.90, ...
                'EdgeColor', [0.40 0.15 0.05], 'LineWidth', 1.1, ...
                'DisplayName', 'hull (2.0 m, true size)');
h.head  = plot(ax.xy, nan, nan, '-', 'Color', [0.40 0.15 0.05], ...
               'LineWidth', 1.5, 'HandleVisibility','off');
h.dot   = plot(ax.xy, nan, nan, 'k.', 'MarkerSize', 9, 'HandleVisibility','off');

if numel(o.lim) == 4
    set(ax.xy, 'XLim', o.lim(1:2), 'YLim', o.lim(3:4));
end
legend(ax.xy, 'Location','southeast', 'AutoUpdate','off', 'FontSize', 7);
h.info = title(ax.xy, '', 'Interpreter','tex', 'FontSize', 9);

%% ---- 명령 대 실제 / command against actual ---------------------------
%  축 하나에 명령과 실제를 함께 둔다. 따로 두면 저마다 축이 늘어나 오차가
%  보이지 않는다 / on one axis each: separate axes rescale and hide the error
ax.p = gobjects(1, np);
h.p  = cell(1, np);
for k = 1:np
    Q = o.panels{k};
    a = subplot(np, 2, 2*k, 'Parent', fig);
    hold(a, 'on');  grid(a, 'on');  set(a, 'FontSize', 8);
    ylabel(a, Q{1});
    if Q{6}, yline(a, 0, 'k:', 'HandleVisibility','off'); end
    hh = gobjects(1, numel(Q{2}));
    for j = 1:numel(Q{2})
        hh(j) = plot(a, nan, nan, Q{3}{j}, 'Color', P.(Q{4}{j}), ...
                     'LineWidth', 1.3, 'DisplayName', Q{5}{j});
    end
    %  범례는 **속이 비어** 있어야 한다. 흰 상자를 두면 그 아래의 곡선이
    %  가려지고, 가려지는 자리가 하필 정상상태다
    %  a filled legend box hides the curve beneath it, and that is exactly
    %  where the steady state is
    legend(a, 'Location','southeast', 'AutoUpdate','off', 'FontSize', 7, ...
           'Orientation','horizontal', 'Box','off', 'Color','none');
    p = get(a, 'Position');
    set(a, 'Position', [p(1) p(2) p(3)*0.92 p(4)]);
    ax.p(k) = a;
    h.p{k}  = hh;
end
xlabel(ax.p(np), 'time [s]');
end

% =========================================================================
function P = palette()
%  이 주차 두 창의 색 / the colours of both windows of this week
P = struct('act',  [0    0.45 0.74], ...   % 실제 / actual
           'cmd',  [0.75 0.10 0.10], ...   % 명령 / command
           'sway', [0.85 0.33 0.10], ...   % 횡방향 / sway
           'aux',  [0.49 0.18 0.56], ...   % 보조 / the third quantity
           'grey', [0.40 0.40 0.40]);
end

% =========================================================================
function s = info_lines(t, y, o)
%  제목 두 줄. 그림에서 못 읽는 수치만 글자로 쓴다
%  two title lines, carrying only the numbers the picture cannot show
L = {sprintf('t = %6.2f s', t)};
for i = 1:size(o.info, 1)
    L{end+1} = sprintf('%s %7.2f', o.info{i,1}, y(o.info{i,2})*o.info{i,3});
end

%  세 토막씩 끊는다. 한 줄에 몰면 제목이 그림 폭을 넘어 잘린다
%  three readouts to a line: on one line the title runs past the edge
s = {};
for i = 1:3:numel(L)
    s{end+1} = strjoin(L(i:min(i+2, numel(L))), '      ');
end
end

% =========================================================================
function [xe, yn] = hull_ned(N, E, psi)
%  선체 윤곽을 NED 로. `_tools/draw_ship` 과 **같은 다각형**이고 실제 크기다
%  the hull outline in NED: the same polygon as draw_ship, at true size
L = 2.00;                          % Otter 전장 / overall length [m]
a = L/2;
b = L*(1.08/2.00)/2;               % 반폭 / half beam
bx = [ -a   -a    0.25*a   a    0.25*a ];
by = [  b   -b   -b        0    b      ];
yn = N + bx*cos(psi) - by*sin(psi);
xe = E + bx*sin(psi) + by*cos(psi);
end

% =========================================================================
function circle(a, xc, yc, R, col)
%  전환 반지름 하나 / one switching radius
th = linspace(0, 2*pi, 73);
plot(a, xc + R*cos(th), yc + R*sin(th), ':', 'Color', col, ...
     'LineWidth', 1.0, 'HandleVisibility','off');
end

% =========================================================================
function fit_lims(a, x, y, pad)
%  축을 **넓히기만** 한다. 좁히면 항적이 그림에서 잘려 나간다
%  limits only ever grow: shrinking them would cut the track already drawn
xl = get(a, 'XLim');  yl = get(a, 'YLim');
nx = [min(xl(1), x-pad), max(xl(2), x+pad)];
ny = [min(yl(1), y-pad), max(yl(2), y+pad)];
if ~isequal(nx, xl), set(a, 'XLim', nx); end
if ~isequal(ny, yl), set(a, 'YLim', ny); end
end

% =========================================================================
function pad_y(a, D)
%  t = 0 에서는 값이 하나뿐이어서 위아래가 같다. 그때 ylim 을 그대로 주면
%  MATLAB 이 거부하므로 **반드시** 벌려 준다
%  at t = 0 the series holds one value and lo == hi, which ylim rejects, so the
%  range is always opened by a little
D = D(isfinite(D));
if isempty(D), return; end
lo = min(D);  hi = max(D);
dd = max((hi - lo)*0.10, max(abs([lo hi]))*0.05 + 1e-3);
set(a, 'YLim', [lo - dd, hi + dd]);
end
