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
%   화면이 시뮬레이션을 따라가게 하는 것 셋 / the three things that keep up
%     1  **표본을 쌓는 자리를 미리 잡는다.** 매 스텝 `S.Y = [S.Y; y]` 로 이으면
%        그때마다 배열 전체가 새로 할당되어 복사된다 — 400 초 Run 이면 2 만 번,
%        옮기는 숫자가 30 억 개가 넘는다. 미리 잡아 둔 칸에 넣기만 하면 한 스텝의
%        비용이 표본 수와 무관해진다
%        preallocate: growing the buffer by concatenation reallocates the whole
%        array on every step, which is O(N^2) and the real reason the window
%        lagged. Writing into reserved rows makes one step cost the same at the
%        end of the run as at the start.
%     2  **그릴 때는 솎는다.** 2 만 점짜리 곡선을 선 열셋에 매번 밀어 넣어도
%        화면의 가로 픽셀은 600 개뿐이다. `MAXPTS` 개로 솎아 그려도 눈에
%        보이는 그림은 같고, 마지막 점은 **반드시** 넣는다
%        decimate for drawing: pushing 20 000 points into thirteen line objects
%        buys nothing on a 600-pixel axis. The last sample is always kept.
%     3  **그리는 간격을 사람이 고른다.** `animate_every` [s] — `W07_0_setup`
%        에서 고친다. 0.5 가 기본, 0.2 면 더 부드럽고 더 느리며, 2 면 Run 이
%        거의 방해받지 않는다
%        the redraw interval is a variable, animate_every, set in W07_0_setup
%
%   추진기 넷을 화살표로 / the four units as arrows
%       사용자 지시 (2026-11-24): "이 주차 강의자료처럼 네 추진기의 힘을
%       화살표 방향과 회전각도로도 표시해줘." `figures/w07-tilt-geometry.svg`
%       가 종이에 그리는 것과 **같은 규칙**이다 —
%         · 점선 토막이 그 유닛의 **0 도**다. 선수 둘은 $+x_b$, 선미 둘은
%           $-x_b$ 를 가리킨다 (거치 부호 `cfg.mount`)
%         · 화살표가 **그 순간의 추력 벡터**다. 0 도에서 화살표까지의 벌어짐이
%           곧 서보각 $\delta_i$ 이므로, 회전각이 그림에서 바로 읽힌다
%         · 길이는 $|T_i|$ 에 비례하고, 꽉 찬 화살표가 `o.thr.Tref` 다
%         · 역추력은 화살표가 **반대로** 돈다 — $T_i<0$ 이면 벡터가 뒤를 민다
%       The same rule the week's own figure uses on paper: a dotted stub is the
%       unit's servo zero, the arrow is the thrust vector at that instant, and
%       the opening between them IS the servo angle, so the tilt is read off the
%       picture. Length is proportional to |T_i|, a full arrow being Tref, and a
%       negative thrust turns the arrow round because the force pushes the other
%       way.
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
%           .T        이 Run 의 끝 시각 [s]. 제목이 `t / T` 로 찍어 **얼마나
%                     남았는지** 보인다. 400 초짜리 운항은 실제로 몇 분이
%                     걸리는데, 남은 양이 보이지 않으면 멎은 것으로 읽힌다
%                     (사용자 지시, 2026-11-24: "시뮬레이션 완료가 않되고 멈춰")
%                     the stop time of this run, so the title can show t / T:
%                     a run of a few minutes with no sense of how much is left
%                     reads as a hang
%           .thr      추진기 화살표. 없으면 그리지 않는다 / the arrows, or []
%                       .n     축회전수 네 열 [rad/s] / the four shaft columns
%                       .d     서보각 네 열 [rad]     / the four servo columns
%                       .pos   2 x 4 선체좌표 [x; y] [m] / stations in {b}
%                       .mount 1 x 4 거치 부호 s_i    / the mounting signs
%                       .kpos  정추력 계수 [N/(rad/s)^2] / ahead coefficient
%                       .kneg  역추력 계수             / astern coefficient
%                       .Tref  꽉 찬 화살표의 추력 [N] / thrust of a full arrow
%           .info     제목에 쓸 {이름, 열, 배율, 단위} 목록. 넷째 칸은 생략해도
%                     되지만, 쓰면 숫자 뒤에 그대로 찍힌다 (deg·m/s·m)
%                     the title readouts, {name, column, scale, unit}; the unit
%                     may be omitted, and prints after the number when given
%           .panels   오른쪽 칸들. 한 칸이 중괄호 하나다 / one brace per panel
%                       {ylabel, [열…], {선모양…}, {색이름…}, {범례…}, 0선}
%                     뒤에 셋을 더 붙일 수 있다 / three optional entries follow
%                       {7} 배율 — 열의 값에 곱한다 (rad 를 도로 등)
%                           a scale applied to the columns, e.g. rad to degrees
%                       {8} [lo hi] 한계 — 배율을 **곱한 뒤의** 단위로 쓴다.
%                           빨간 파선 둘로 그리고, 세로축이 언제나 그 둘을
%                           품으므로 여유가 얼마나 남았는지 한눈에 보인다
%                           the limits, in the scaled unit, drawn as two red
%                           dashed lines; the axis always contains them, so how
%                           much room is left is visible at a glance
%                       {9} {아래 이름, 위 이름} 한계선의 이름표 / their labels
%
%   색 이름 / the colour keys
%       'act' 실제 · 'cmd' 명령 · 'sway' 횡방향 · 'aux' 보조 · 'grey' 회색
%       'u1'…'u4' 네 단위. `W07_plot_sat` 과 **같은 색**이라 실시간에서 본
%       1 번 단위가 저장된 그림에서도 같은 색이다
%       the four units, in the same colours as W07_plot_sat
%
%   See also W07WPT_ANIMATE, W07POSE_ANIMATE, W07_PLOT_WPT, W07_PLOT_POSE.

persistent fig ax h S tLast tPrev every Lship G

CAP0   = 4096;                 % 처음 잡아 두는 줄 수 / rows reserved at the start
NMAX   = 32768;                % 그 이상은 한 칸 걸러 버린다 / then halve in place
MAXPTS = 1500;                 % 한 곡선에 그리는 점 수 / points drawn per curve

y = y(:).';

%  래퍼가 빠뜨린 칸을 채운다. 둘은 **나중에 생긴 칸**이라, 이것이 없으면 옛
%  래퍼를 그대로 둔 주차에서 필드 오류가 난다
%  fill the fields a wrapper may not set: both were added later, and without
%  this an older wrapper would stop at a missing-field error
if ~isfield(o, 'thr'), o.thr = []; end
if ~isfield(o, 'T'),   o.T   = []; end

%  새 Run 인가. 시각이 뒤로 갔거나 창이 닫혔으면 새 Run 이다
%  a new run: the clock went backwards, or the window is gone
newRun = isempty(tLast) || isempty(fig) || ~isvalid(fig) || t < tPrev;
tPrev  = t;

if newRun
    S     = struct('t', zeros(CAP0,1), 'Y', zeros(CAP0, numel(y)), ...
                   'n', 0, 'k', 0, 'dec', 1);
    tLast = -inf;
    every = base_var('animate_every', 0.5);

    %  **그려지는** 선체의 길이. 실제는 2.0 m 지만, 200 m 짜리 장면에서 2 m 는
    %  점 하나라 선수각이 보이지 않는다. 이전 주차(`_tools/live_track`,
    %  `_tools/live_guidance`)와 같은 규칙 — 넓은 쪽 축의 4.5 %, 실제 크기가
    %  그보다 크면 실제 크기
    %  the DRAWN hull length: 4.5 per cent of the wider axis span, never below
    %  the true 2.0 m. The same rule as the earlier weeks; at true size a 2 m
    %  boat is one dot in a 200 m scene and its heading cannot be read.
    if numel(o.lim) == 4
        Lship = max(0.045*max(o.lim(2)-o.lim(1), o.lim(4)-o.lim(3)), 2.00);
    else
        Lship = 2.00;
    end

    %  그려지는 선체의 **윤곽**. 거치점 넷을 품어야 한다 / it must hold the four
    G = hull_geom(o, Lship);

    [fig, ax, h] = build_window(o, y, Lship, G);
end

%  표본을 쌓는다 — 미리 잡아 둔 칸에 **넣기만** 한다 / append, no reallocation
S.k = S.k + 1;
if mod(S.k - 1, S.dec) == 0
    if S.n == size(S.t, 1)
        if size(S.t,1) < NMAX
            S.t = [S.t; zeros(size(S.t,1), 1)];       % 두 배로 / double
            S.Y = [S.Y; zeros(size(S.Y))];
        else
            %  가득 찼다. 한 칸 걸러 버리고 받는 간격을 두 배로 한다. Run 전체가
            %  계속 보이면서 자리는 더 늘지 않는다
            %  full: drop every other sample and halve the intake rate, so the
            %  whole run stays visible and the memory stops growing
            keep = 1:2:S.n;
            mkeep = numel(keep);
            S.t(1:mkeep)   = S.t(keep);
            S.Y(1:mkeep,:) = S.Y(keep,:);
            S.n   = mkeep;
            S.dec = S.dec*2;
        end
    end
    S.n          = S.n + 1;
    S.t(S.n)     = t;
    S.Y(S.n,:)   = y;
end

%  그리는 간격. 매 스텝 그리면 시뮬레이션보다 그림이 느려진다
%  the redraw interval: drawing every step makes the picture the bottleneck
%
%  **돌아가는 중에도 바꿀 수 있다** (사용자 지시, 2026-11-25). 매 **다시 그릴
%  때마다** 작업공간의 `animate_every` 를 새로 읽으므로, 운항이 지루하면
%  명령창에 `animate_every = 2` 를 치면 그 자리에서 빨라지고, 자세히 보고
%  싶으면 `animate_every = 0.1` 로 되돌린다. Run 을 다시 누를 필요가 없다.
%  읽기는 다시 그릴 때 한 번뿐이라 매 스텝 비용이 아니다
%  the interval is LIVE: animate_every is re-read at each redraw, so typing
%  `animate_every = 2` at the prompt speeds a running simulation up at once,
%  and 0.1 slows it back down. No need to stop and press Run again. The read
%  costs one evalin per redraw, not one per step
if t - tLast < every, return; end
tLast = t;
every = max(base_var('animate_every', 0.5), 0);

%  그릴 점만 고른다. 마지막 점은 언제나 들어간다 / the points to draw
idx = draw_idx(S.n, MAXPTS);
tt  = S.t(idx);

N = y(4);  E = y(5);  psi = y(6);          % psi 는 **도** / psi in degrees

%% ---- 왼쪽: 항적 / left: the track ------------------------------------
Yd = S.Y(idx,:);
set(h.trail, 'XData', Yd(:,5), 'YData', Yd(:,4));
[hE, hN] = hull_ned(N, E, psi*pi/180, G);
set(h.hull, 'XData', hE, 'YData', hN);
%  선수 방향선은 **뱃머리 바로 앞까지**만. 선체가 거치점을 품을 만큼 커졌으므로
%  긴 선은 그 자체가 또 하나의 물체처럼 보인다 (사용자 지시, 2026-11-25)
%  the heading line now stops just ahead of the bow: with a hull large enough to
%  hold the mounting points, a long line reads as another object of its own
set(h.head, 'XData', [E, E + 1.05*G.af*sind(psi)], ...
            'YData', [N, N + 1.05*G.af*cosd(psi)]);
set(h.dot,  'XData', E, 'YData', N);

%  추진기 넷의 힘과 서보각 / the thrust and the servo angle of each unit
if ~isempty(o.thr)
    [aE, aN, zE, zN, pE, pN, dE, dN] = ...
        thruster_arrows(y, psi*pi/180, N, E, o.thr, Lship);
    set(h.thr0, 'XData', zE, 'YData', zN);
    set(h.thr,  'XData', aE, 'YData', aN);
    set(h.thrH, 'XData', pE, 'YData', pN);
    set(h.thrP, 'XData', dE, 'YData', dN);
end
%  여백은 **윤곽과 꽉 찬 화살표**를 합친 것만큼 / pad by hull plus a full arrow
pad = max(3, 1.1*(G.af + 2.20*G.mag));
fit_lims(ax.xy, E, N, pad);

%  명령 위치가 있는 모델이면 그 자취도 함께 / the commanded position, if any
if ~isempty(o.cmdNE)
    set(h.cmd,  'XData', S.Y(idx,o.cmdNE(2)), 'YData', S.Y(idx,o.cmdNE(1)));
    set(h.mark, 'XData', y(o.cmdNE(2)),       'YData', y(o.cmdNE(1)));
    fit_lims(ax.xy, y(o.cmdNE(2)), y(o.cmdNE(1)), pad);
end

set(h.info, 'String', info_lines(t, y, o));

%% ---- 오른쪽: 명령 대 실제 / right: command against actual ------------
for k = 1:numel(o.panels)
    Q  = o.panels{k};
    c  = Q{2};
    sc = pan_scale(Q);
    D  = S.Y(idx, c)*sc;
    for j = 1:numel(c)
        set(h.p{k}(j), 'XData', tt, 'YData', D(:,j));
    end
    %  한계가 있는 칸은 세로축이 **한계를 품는다.** 곡선만 보고 "여유가 있다"
    %  고 말할 수 없게 하려는 것이다
    %  a panel with limits always shows them, so margin is never guessed
    pad_y(ax.p(k), [D(:); pan_lim(Q)'], leg_room(Q));
    set(ax.p(k), 'XLim', [0 max(t, 1)]);
end

drawnow limitrate
end

% =========================================================================
function [fig, ax, h] = build_window(o, y, Lship, G)
%  창 하나를 짓는다. 축과 핸들을 돌려주므로 매 스텝 `set` 만 한다
%  build the window once; every step afterwards is a set() on these handles

P  = palette();
np = numel(o.panels);

%  칸이 여섯을 넘으면 **두 열**로 세운다. 한 열에 일곱이면 한 칸이 90 px 밖에
%  안 되어 곡선이 선 하나로 보인다
%  beyond five panels the right-hand side becomes two columns: seven panels in
%  one column leave 90 px each, and a curve in 90 px is a line
%  항적 칸은 `axis equal` 이라 **정사각형**이다. 한 열만 주면 그 정사각형이
%  열 너비에 눌려, 남는 세로가 열 높이의 절반 가까이 빈다. 그래서 칸이 여섯을
%  넘으면 격자를 네 열로 하고 항적에 **두 열**을 준다 — 항적이 세로를 채우고,
%  그래프 열은 여전히 450 px 씩이다. `ncw` 가 항적이 차지하는 열 수다
%  the track is `axis equal`, hence square: given one column of the grid it is
%  squeezed to that column's width and leaves nearly half the column height
%  empty. So beyond five panels the grid is four columns wide and the track
%  takes TWO of them: the track then fills the height and each panel column is
%  still 450 px. `ncw` is how many columns the track spans.
if np <= 5
    ncg = 2;  ncw = 1;  nr = np;             W = 1340;
else
    ncg = 4;  ncw = 2;  nr = ceil(np/2);     W = 1800;
end

old = findall(0, 'Type','figure', 'Tag', o.tag);
if ~isempty(old), delete(old); end
fig = lab_fig(o.name, W, min(900, 180 + 170*nr));
set(fig, 'Tag', o.tag);

N = y(4);  E = y(5);

%% ---- 항적 / the track ------------------------------------------------
tcell = [];
for r = 1:nr
    tcell = [tcell, ncg*(r-1) + (1:ncw)];              %#ok<AGROW>
end
ax.xy = subplot(nr, ncg, tcell, 'Parent', fig);
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
    [gE, gN] = hull_ned(o.goal(1), o.goal(2), o.goal(3)*pi/180, G);
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

%  명령 위치가 없는 모델에서는 범례에서도 빼야 한다. 그리지 않는 선의 이름이
%  범례에 남으면 학생이 "저 선은 왜 안 보이나" 를 묻는다 — LOS 는 위치를
%  명령하지 않으므로 이 두 핸들은 끝까지 NaN 이다
%  a model that commands no position must not advertise one: a legend entry for
%  a line that never draws is read as a missing line, and LOS commands no
%  position, so these two handles stay NaN for the whole run
cmdVis = 'on';
if isempty(o.cmdNE), cmdVis = 'off'; end
h.cmd   = plot(ax.xy, nan, nan, '--', 'Color', P.cmd, 'LineWidth', 1.2, ...
               'DisplayName', 'commanded position', 'HandleVisibility', cmdVis);
h.mark  = plot(ax.xy, nan, nan, 's', 'MarkerSize', 8, 'LineWidth', 1.2, ...
               'MarkerEdgeColor', P.cmd, 'MarkerFaceColor','none', ...
               'DisplayName', 'command now', 'HandleVisibility', cmdVis);
%  **자취 위에 선체를 줄줄이 그리지 않는다** (사용자 지시, 2026-11-24).
%  한때 호길이 간격으로 지나간 선체 윤곽을 함께 그렸으나, 살아 있는 화면에서
%  그것은 "배가 여러 척" 으로 읽혔다. 선수방위는 **지금 자리의 선체 하나**와
%  추진기 화살표가 보이면 충분하고, 지나간 선수방위가 필요한 그림 —
%  강의자료에 실리는 저장된 항적도 — 은 `_tools/track_ships` 가 따로 그린다.
%  이전 주차(`W06_animate`)도 살아 있는 창에는 선체를 하나만 그린다.
%  No chain of hulls along the trail: it was read as several vessels. One hull
%  at the present position, with the thrust arrows, carries the heading; the
%  saved track figure that goes into the lecture still gets the chain, drawn by
%  `_tools/track_ships`, and the earlier weeks' live windows draw one hull too.
h.trail = plot(ax.xy, nan, nan, '-', 'Color', P.act, 'LineWidth', 1.4, ...
               'DisplayName', 'actual track');

%  이전 주차의 문구를 그대로 쓴다 — `W06_animate` 는 `hull (2.0 m, true size)`
%  다. 넓은 장면에서는 키워 그리므로 **몇 배인지**를 적는다
%  the earlier weeks' wording, with the magnification named when there is one
%  **윤곽은 폰툰과 거치 암을 함께 싼 것**이라 2.0 m 가 아니라 3.35 m 다 —
%  오픈루프 실습 그림(`_tools/quad_thrust_plan`)이 그리는 그 윤곽이다
%  the outline wraps the pontoons AND the mounting arms, 3.35 m rather than
%  2.0 m: the same outline the open-loop practice figure draws
if Lship > 2.001
    hullName = sprintf('hull and arms (%.2f m, drawn x%.1f)', G.len, G.mag);
else
    hullName = sprintf('hull and arms (%.2f m, true size)', G.len);
end
%  **반투명**이다. 거치점을 품을 만큼 커진 윤곽을 꽉 채워 칠하면 화살표가 그
%  안에 잠겨 보이지 않는다 — 오픈루프 그림도 폰툰을 옅게 칠하고 화살표를 그
%  위에 올린다 / translucent: a filled outline large enough to hold the stations
%  drowns the arrows, and the open-loop figure likewise draws pale pontoons
%  with the arrows over them
h.hull  = patch('Parent', ax.xy, 'XData', nan, 'YData', nan, ...
                'FaceColor', [0.96 0.72 0.50], 'FaceAlpha', 0.55, ...
                'EdgeColor', [0.40 0.15 0.05], 'LineWidth', 1.2, ...
                'DisplayName', hullName);
h.head  = plot(ax.xy, nan, nan, '-', 'Color', [0.40 0.15 0.05], ...
               'LineWidth', 1.2, 'HandleVisibility','off');
h.dot   = plot(ax.xy, nan, nan, 'k.', 'MarkerSize', 9, 'HandleVisibility','off');

%  추진기 넷. 점선 토막이 **그 유닛의 0 도**이고 화살표가 그 순간의 추력
%  벡터이므로, 둘 사이의 벌어짐이 곧 서보각 $\delta_i$ 다. 넷을 NaN 으로 끊어
%  line 두 개에 담으므로 매 스텝 `set` 두 번이면 끝난다.
%  두 line 의 그리기 순서는 점선 먼저다 — 화살표가 그 위에 올라와야 각이 보인다.
%  the four units: a dotted stub is that unit's servo zero and the arrow is the
%  thrust vector, so the opening between them IS the servo angle. All four go
%  into two line objects separated by NaN, two set() calls per step. The stubs
%  are created first so the arrows draw on top of them.
if ~isempty(o.thr)
    ARR = [0.78 0.10 0.12];        % 오픈루프 그림의 빨강보다 짙다 / deeper than the open-loop red
    h.thr0 = plot(ax.xy, nan, nan, ':', 'Color', [0.35 0.35 0.35], ...
                  'LineWidth', 1.0, ...
                  'DisplayName', 'servo zero of each unit');
    h.thr  = plot(ax.xy, nan, nan, '-', 'Color', ARR, ...
                  'LineWidth', 2.4, 'DisplayName', ...
                  sprintf('thrust of each unit (full arrow %.0f N, length \\propto \\surd|T|)', ...
                          o.thr.Tref));
    %  화살머리는 **채운 삼각형**이다. 선 두 토막으로 그린 머리는 넓은 장면에서
    %  보이지 않아 방향을 읽을 수 없었다 (사용자 지시, 2026-11-25). 넷을 한
    %  patch 의 **열 넷**으로 담으므로 매 스텝 `set` 한 번이면 끝난다.
    %  the head is a FILLED triangle: two short line segments vanished in a
    %  wide scene and the direction could not be read. All four heads are four
    %  COLUMNS of one patch, so one set() per step draws them.
    h.thrH = patch('Parent', ax.xy, 'XData', nan(3,1), 'YData', nan(3,1), ...
                   'FaceColor', ARR, 'EdgeColor', 'none', ...
                   'HandleVisibility', 'off');
    %  거치점. 오픈루프 그림의 검은 점과 같은 뜻이다 / the station, as there
    h.thrP = plot(ax.xy, nan, nan, 'o', 'MarkerSize', 4, ...
                  'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none', ...
                  'HandleVisibility', 'off');
else
    h.thr0 = gobjects(0);  h.thr  = gobjects(0);
    h.thrH = gobjects(0);  h.thrP = gobjects(0);
end

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
last = zeros(1, ncg-1);               % 열마다 맨 아래 칸 / bottom cell per column
for k = 1:np
    Q = o.panels{k};
    if ncg == 2
        cell_k = 2*k;  col = 1;
    else
        col    = 1 + mod(k-1, 2);        % 그래프 열 둘 가운데 어느 쪽인가
        cell_k = ncg*(ceil(k/2) - 1) + ncw + col;
    end
    last(col) = k;

    a = subplot(nr, ncg, cell_k, 'Parent', fig);
    hold(a, 'on');  grid(a, 'on');  set(a, 'FontSize', 8);
    ylabel(a, Q{1});
    if Q{6}, yline(a, 0, 'k:', 'HandleVisibility','off'); end

    %  한계선 먼저. 곡선 **아래**에 깔려야 곡선이 한계선을 가리지 않는다
    %  the limit lines first, so the curves are drawn on top of them
    L = pan_lim(Q);
    if ~isempty(L)
        nm = pan_names(Q);
        yline(a, L(1), 'r--', nm{1}, 'FontSize', 7, 'LineWidth', 1.0, ...
              'LabelHorizontalAlignment','left', ...
              'LabelVerticalAlignment','bottom', 'HandleVisibility','off');
        yline(a, L(2), 'r--', nm{2}, 'FontSize', 7, 'LineWidth', 1.0, ...
              'LabelHorizontalAlignment','left', ...
              'LabelVerticalAlignment','top', 'HandleVisibility','off');
    end

    hh = gobjects(1, numel(Q{2}));
    for j = 1:numel(Q{2})
        hh(j) = plot(a, nan, nan, Q{3}{j}, 'Color', P.(Q{4}{j}), ...
                     'LineWidth', 1.3, 'DisplayName', Q{5}{j});
    end
    %  범례는 **속이 비어** 있어야 한다. 흰 상자를 두면 그 아래의 곡선이
    %  가려지고, 가려지는 자리가 하필 정상상태다
    %  a filled legend box hides the curve beneath it, and that is exactly
    %  where the steady state is
    %  **이전 주차와 같은 범례다** (사용자 지시, 2026-11-24). `W06_animate` 는
    %  시간 칸의 범례를 `Orientation','horizontal'` 로 두어 **한 줄**로 세운다.
    %  `NumColumns` 를 쓰면 둘짜리 범례도 두 칸으로 벌어지고 넷짜리는 **두 줄**이
    %  되어, 그만큼 칸 아래를 비워 주어야 하므로 곡선이 위로 몰린다.
    %  the earlier weeks' legend: W06_animate lays the time panels' legends out
    %  horizontally, on ONE line. NumColumns widened a two-entry legend and made
    %  a four-entry one two lines deep, which then had to be paid for by opening
    %  the bottom of the panel, squashing the curves into the top.
    legend(a, 'Location','southeast', 'AutoUpdate','off', 'FontSize', 7, ...
           'Orientation','horizontal', 'Box','off', 'Color','none');
    p = get(a, 'Position');
    set(a, 'Position', [p(1) p(2) p(3)*0.92 p(4)]);
    ax.p(k) = a;
    h.p{k}  = hh;
end
for c = 1:numel(last)
    if last(c) > 0, xlabel(ax.p(last(c)), 'time [s]'); end
end
end

% =========================================================================
function s = pan_scale(Q)
%  칸의 배율. 없으면 1 / the panel scale, 1 when absent
if numel(Q) >= 7 && ~isempty(Q{7}), s = Q{7}; else, s = 1; end
end

% =========================================================================
function L = pan_lim(Q)
%  칸의 [아래 위] 한계. 없으면 [] / the panel limits or []
if numel(Q) >= 8 && numel(Q{8}) == 2, L = sort(Q{8}(:)).'; else, L = []; end
end

% =========================================================================
function nm = pan_names(Q)
%  한계선의 이름표 / the labels of the two limit lines
if numel(Q) >= 9 && numel(Q{9}) == 2, nm = Q{9}; else, nm = {'min','max'}; end
end

% =========================================================================
function idx = draw_idx(n, maxp)
%  그릴 점의 번호. 표본이 많으면 **솎는다** — 화면의 가로 픽셀보다 촘촘하게
%  그려도 보이는 그림은 같고, 마지막 점은 언제나 넣는다
%  which samples to draw: beyond maxp the series is thinned, and the last sample
%  is always included so the curve ends where the vessel is
if n <= 0, idx = []; return; end
if n <= maxp, idx = 1:n; return; end
s   = ceil(n/maxp);
idx = 1:s:n;
if idx(end) ~= n, idx(end+1) = n; end
end

% =========================================================================
function P = palette()
%  이 주차 두 창의 색 / the colours of both windows of this week
P = struct('act',  [0    0.45 0.74], ...   % 실제 / actual
           'cmd',  [0.75 0.10 0.10], ...   % 명령 / command
           'sway', [0.85 0.33 0.10], ...   % 횡방향 / sway
           'aux',  [0.49 0.18 0.56], ...   % 보조 / the third quantity
           'grey', [0.40 0.40 0.40], ...
           'u1',   [0    0.45 0.74], ...   % 네 단위 / the four units,
           'u2',   [0.85 0.33 0.10], ...   % `W07_plot_sat` 과 같은 색
           'u3',   [0.47 0.67 0.19], ...   % the same colours as W07_plot_sat
           'u4',   [0.49 0.18 0.56]);
end

% =========================================================================
function s = info_lines(t, y, o)
%  제목 두 줄. 그림에서 못 읽는 수치만 글자로 쓴다
%  two title lines, carrying only the numbers the picture cannot show
%  **얼마나 남았는지** 보인다. 400 초짜리 운항은 실제로 몇 분이 걸리는데,
%  남은 양이 보이지 않으면 멎은 것으로 읽힌다 (사용자 지시, 2026-11-24)
%  how much is left: a run of minutes with no sense of progress reads as a hang
%
%  다만 **`o.T` 는 상한이다.** 마지막 웨이포인트에 닿으면 Stop 블록이 시계보다
%  먼저 선다 — 다섯 점을 다 돈 운항이 274 s / 400 s 로 끝나므로, "t / T" 만
%  쓰면 멀쩡히 끝난 운항이 "68 % 에서 멎었다" 로 읽힌다 (사용자 지시, 2026-11-25)
%  o.T is a CAP, not the finish line: the Stop block fires on arrival, so a
%  route flown to its end stops at 274 s of 400 s. Showing t/T alone makes a
%  completed run read as one that quit at 68 % of the clock
if isfield(o, 'T') && ~isempty(o.T) && o.T > 0
    L = {sprintf('t = %6.2f s  (limit %g s)', t, o.T)};
else
    L = {sprintf('t = %6.2f s', t)};
end
%  끝났는지 아닌지는 시계가 아니라 **마지막 점까지의 거리**가 말한다.
%  그 거리가 전환 반지름 안에 들면 운항이 완주한 것이다
%  what says whether the run is done is the distance to the LAST waypoint,
%  not the clock: inside the switching circle, the route has been flown
if isfield(o, 'wp') && ~isempty(o.wp)
    dl = hypot(o.wp(end,1) - y(4), o.wp(end,2) - y(5));
    nw = size(o.wp, 1);
    if dl <= base_var('R_switch', 3)
        L{end+1} = sprintf('wp %d of %d  reached', nw, nw);
    else
        L{end+1} = sprintf('to wp %d  %5.1f m', nw, dl);
    end
end
%  **단위를 붙여 쓴다.** 숫자만 적으면 각이 deg 인지 rad 인지, 속도가 m/s
%  인지 kn 인지 화면에서 알 수 없다 (사용자 지시, 2026-11-25)
%  each readout carries its UNIT: a bare number leaves the reader guessing
%  whether an angle is deg or rad, a speed m/s or knots
hasU = size(o.info, 2) >= 4;
for i = 1:size(o.info, 1)
    v = y(o.info{i,2})*o.info{i,3};
    if hasU && ~isempty(o.info{i,4})
        L{end+1} = sprintf('%s %7.2f %s', o.info{i,1}, v, o.info{i,4}); %#ok<AGROW>
    else
        L{end+1} = sprintf('%s %7.2f', o.info{i,1}, v);                 %#ok<AGROW>
    end
end

%  세 토막씩 끊는다. 한 줄에 몰면 제목이 그림 폭을 넘어 잘린다
%  three readouts to a line: on one line the title runs past the edge
s = {};
for i = 1:3:numel(L)
    s{end+1} = strjoin(L(i:min(i+2, numel(L))), '      '); %#ok<AGROW>
end
end

% =========================================================================
function [aE, aN, zE, zN, pE, pN, dE, dN] = ...
                             thruster_arrows(y, psi, N, E, T, Lship)
%THRUSTER_ARROWS  추진기 넷의 힘과 서보각을, 강의자료와 **같은 규칙**으로
%                 the four units' thrust and tilt, by the week's own rule
%
%  규칙은 `figures/src/w07-tilt-geometry.tex` 이 종이에 쓰는 것과 같다 —
%    · 점선 토막: 그 유닛의 **0 도**. 선수 둘은 $+x_b$, 선미 둘은 $-x_b$
%      (거치 부호 `cfg.mount`, `_tools/otter_B.m` 의 열 규칙)
%    · 화살표: 그 순간의 추력 벡터 $s_i T_i [\cos\delta_i;\ \sin\delta_i]$.
%      0 도에서 화살표까지 벌어진 각이 그대로 $\delta_i$ 다
%    · 길이: $|T_i|$ 에 비례. 꽉 찬 화살표가 `T.Tref`
%    · 역추력($T_i<0$)이면 화살표가 **반대로** 돈다 — 힘이 뒤를 민다
%  The dotted stub is the unit's servo zero (+x_b forward pair, -x_b aft pair,
%  the mounting sign of otter_B's column rule); the arrow is the thrust vector
%  at that instant, so the opening between them is the servo angle itself.
%  Length is proportional to |T_i| with a full arrow at Tref, and a negative
%  thrust turns the arrow round because the force pushes the other way.
%
%  추력은 로그의 $n$ 에서 **모델과 같은 식**으로 낸다 — $T=k\,n|n|$ 이고
%  정·역의 $k$ 가 다르다 (`otter_tilt4`). 로그에 $T$ 를 따로 싣지 않고 여기서
%  내는 이유는, 열을 늘리면 모든 주차의 로그 규약이 흔들리기 때문이다.
%  The thrust comes from the logged n by the model's own law, T = k n|n| with
%  different coefficients ahead and astern, rather than from an extra log
%  column, because widening the log would disturb every week's contract.
aE = nan(0,1);  aN = nan(0,1);  zE = nan(0,1);  zN = nan(0,1);
pE = nan(3,0);  pN = nan(3,0);  dE = nan(0,1);  dN = nan(0,1);

%  길이는 **전부 `mag` 로 잰다** / every length is measured in mag
%      `mag` 은 "실제 1 m 가 화면에서 몇 m 로 그려지는가" 다. 거치점은 그것으로
%      키우고 화살표는 `Lship` 으로 키우면, 200 m 장면(`Lship` 9 m)에서 화살표가
%      선체보다 길어져 넷이 한 줄로 겹쳐 보인다. 그래서 화살표도, 0 도 토막도,
%      안 그리는 문턱도 모두 `mag` 배다 — 어느 배율에서도 그림이 같아 보인다.
%      mag is how long a real metre is drawn. Scaling the stations by mag but
%      the arrows by Lship made a full arrow longer than the hull in the 200 m
%      scene, and four of them read as one line. Arrow, stub and cut-off are
%      all in mag, so the picture looks the same at either scale.
%  길이 규칙은 **제곱근**이다 / the length rule is a SQUARE ROOT
%      $u_d=1$ m/s 로 항행하는 동안 유닛 하나가 내는 추력은 7 N 안팎이고
%      $T_{ref}=120$ N 이다. 길이를 $|T|$ 에 **비례**시키면 그 화살표가 꽉 찬
%      것의 6 % 라, 넓은 장면에서는 점이 되어 방향도 크기도 보이지 않았다
%      (사용자 지시, 2026-11-25). 그래서 $0.25+0.75\sqrt{|T|/T_{ref}}$ 로
%      그린다 — 단조이고, 꽉 찬 화살표는 여전히 $T_{ref}$ 이며, 작은 추력도
%      방향을 읽을 만큼 남는다. 범례가 그 규칙을 밝힌다.
%      At u_d = 1 m/s one unit gives about 7 N against a 120 N reference, so a
%      length proportional to |T| drew 6 per cent of a full arrow — a dot, with
%      neither direction nor size readable. The rule is 0.25 + 0.75*sqrt(ratio):
%      monotone, still exactly Tref at a full arrow, and small thrusts keep
%      enough length to show which way they point. The legend names the rule.
nU   = numel(T.n);
mag  = Lship/2.00;        % 선체를 키운 그 배율 / the hull's own magnification
Lmax = 2.20*mag;          % 꽉 찬 화살표 / a full arrow, in drawn metres
hfr  = 0.24;              % 화살머리의 몫 / the head, as a fraction of Lr
hmin = 0.32*mag;          % 화살머리의 최소 길이 / its floor, so it stays sharp
c    = cos(psi);  s = sin(psi);

for i = 1:nU
    %  거치점을 선체좌표에서 NED 로 / the station, from {b} into NED
    xb = T.pos(1,i)*mag;   yb = T.pos(2,i)*mag;
    sN = N + xb*c - yb*s;
    sE = E + xb*s + yb*c;

    %  거치점 하나에 점 하나. 화살표가 **어디서 나오는지**를 그것이 말한다
    %  one dot per station: it says where the arrow comes from
    dN = [dN; sN];                                               %#ok<AGROW>
    dE = [dE; sE];                                               %#ok<AGROW>

    %  0 도 토막. 거치 부호가 선미 쌍을 뒤로 돌린다 / the servo zero
    z0 = T.mount(i)*0.45*mag;
    zN = [zN; sN; sN + z0*c; nan];                               %#ok<AGROW>
    zE = [zE; sE; sE + z0*s; nan];                               %#ok<AGROW>

    %  추력. 정·역의 계수가 다르다 / the thrust, with two coefficients
    nn = y(T.n(i));
    if nn >= 0, Ti = T.kpos*nn*nn; else, Ti = -T.kneg*nn*nn; end
    if abs(Ti) < 0.5, continue; end     % 0.5 N 아래면 그리지 않는다 / skip
    Lr = (0.25 + 0.75*sqrt(min(abs(Ti)/T.Tref, 1)))*Lmax;

    %  추력 벡터. $\delta$ 는 그 쌍의 0 도에서 잰다 / delta from that zero
    d  = y(T.d(i));
    eb = sign(Ti)*T.mount(i)*[cos(d); sin(d)];
    vN = Lr*(eb(1)*c - eb(2)*s);
    vE = Lr*(eb(1)*s + eb(2)*c);
    tN = sN + vN;   tE = sE + vE;       % 화살표 끝 / the tip

    %  단위벡터와 그 수직 / the unit vector along the arrow, and its normal
    uN = vN/Lr;  uE = vE/Lr;
    qN = -uE;    qE = uN;

    %  채운 삼각형 하나. 끝점이 **뾰족한 꼭지**이고, 밑변은 축을 따라 `hl` 만큼
    %  물러난 자리에서 좌우로 `0.40*hl` 씩 벌어진다. 길이에 비례시키되 바닥을
    %  두어, 추력이 작아도 꼭지가 뭉개지지 않는다
    %  one filled triangle: the tip is the sharp apex, and the base sits hl back
    %  along the axis, 0.40*hl to each side. Proportional to the length but with
    %  a floor, so the point stays sharp at small thrust
    hl = max(hfr*Lr, hmin);
    hb = 0.40*hl;
    bN = tN - hl*uN;   bE = tE - hl*uE;
    pN = [pN, [tN; bN + hb*qN; bN - hb*qN]];                     %#ok<AGROW>
    pE = [pE, [tE; bE + hb*qE; bE - hb*qE]];                     %#ok<AGROW>

    %  자루는 머리 밑변까지만. 더 뻗으면 삼각형 안으로 선이 비친다
    %  the shaft stops at the base of the head, or it shows through it
    Ls = max(Lr - hl, 0);
    aN = [aN; sN; sN + Ls*uN; nan];                              %#ok<AGROW>
    aE = [aE; sE; sE + Ls*uE; nan];                              %#ok<AGROW>
end
end

% =========================================================================
function G = hull_geom(o, Lship)
%HULL_GEOM  그려지는 선체 윤곽의 치수. **거치점 넷을 품는다**
%           the drawn hull's extents: it must CONTAIN the four stations
%
%  왜 2.0 m 가 아닌가 / why not 2.0 m
%      Otter 의 폰툰 전장은 2.0 m 지만, 네 유닛은 $x_b=+1.5$ 와 $-1.0$ 에
%      달린다. 반길이 1.0 m 로 그리면 뱃머리 쪽 둘이 **윤곽 밖 1.5 m** 에 서고,
%      그래서 화살표가 선체에서 떨어져 나와 따로 떠 보였다 (사용자 지시,
%      2026-11-25). 오픈루프 실습 그림(`_tools/quad_thrust_plan`)은 폰툰을
%      $x\in[-1.45,\,1.90]$ 으로 그려 거치점을 품는다 — **같은 윤곽을 쓴다.**
%      The pontoons are 2.0 m, but the units sit at x_b = +1.5 and -1.0. Drawn
%      with a 1.0 m half-length the forward pair stood 1.5 m OUTSIDE the
%      outline, which is why the arrows looked detached. The open-loop practice
%      figure draws the pontoons over x in [-1.45, 1.90], holding the stations
%      inside; this is that same outline.
G.mag = Lship/2.00;               % 실제 1 m 가 화면에서 몇 m 인가 / the scale

af = 1.90;   aa = 1.45;           % 실제 치수 / in true metres
if ~isempty(o.thr) && isfield(o.thr, 'pos')
    %  거치점이 그보다 멀면 윤곽을 **그만큼 더** 늘린다 / grow to hold them
    af = max(af, max(o.thr.pos(1,:)) + 0.40);
    aa = max(aa, -min(o.thr.pos(1,:)) + 0.40);
end
G.len = af + aa;                  % 그려지는 전장 (실제 m) / drawn overall
G.af  = af*G.mag;                 % 화면 치수 / in drawn metres
G.aa  = aa*G.mag;
G.b   = 0.54*G.mag;               % 반폭 — 실제 1.08 m 그대로 / half beam
end

% =========================================================================
function [xe, yn] = hull_ned(N, E, psi, G)
%  선체 윤곽을 NED 로. `_tools/draw_ship` 과 **같은 모양**이고, 치수는
%  `hull_geom` 이 잰 **그려지는** 치수다 — 실제 전장은 2.0 m 로 바뀌지 않는다
%  the hull outline in NED: the shape of draw_ship, at the DRAWN extents
%  hull_geom measured. The true overall length stays 2.0 m whatever is drawn.
bx = [ -G.aa   -G.aa    0.25*G.af   G.af    0.25*G.af ];
by = [  G.b    -G.b    -G.b         0       G.b       ];
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
function pad_y(a, D, bot)
%  t = 0 에서는 값이 하나뿐이어서 위아래가 같다. 그때 ylim 을 그대로 주면
%  MATLAB 이 거부하므로 **반드시** 벌려 준다
%  at t = 0 the series holds one value and lo == hi, which ylim rejects, so the
%  range is always opened by a little
%
%  `bot` 은 **범례가 앉을 자리**다. 범례는 오른쪽 아래에 있으므로 그만큼
%  아래를 더 비워 두면 범례가 곡선도 한계선도 덮지 않는다
%  bot is the room the legend sits in: it hangs in the lower right corner, so
%  opening the bottom by that fraction keeps it off the curves and the limits
D = D(isfinite(D));
if isempty(D), return; end
lo = min(D);  hi = max(D);
dd = max((hi - lo)*0.10, max(abs([lo hi]))*0.05 + 1e-3);
lo = lo - dd;  hi = hi + dd;
set(a, 'YLim', [lo - bot*(hi - lo), hi]);
end

% =========================================================================
function b = leg_room(Q)   %#ok<INUSD>
%  범례 아래에 비워 둘 몫 / the room left under the legend
%      범례가 **한 줄**이 되었으므로 (`Orientation','horizontal'`) 칸마다
%      같은 몫이면 된다. 포화한 신호는 **한계선 위에 그대로 눕는다.** 그러니
%      범례가 그 선을 가리지 않을 만큼만 비운다.
%      the legend is now one line in every panel, so one value serves all. A
%      saturated signal lies exactly on its limit line, and this is the room
%      that keeps the legend from sitting on it.
b = 0.18;
end
