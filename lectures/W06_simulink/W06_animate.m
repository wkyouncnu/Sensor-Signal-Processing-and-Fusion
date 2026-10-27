function f = W06_animate(y, t)
%W06_ANIMATE  모델이 도는 동안 **명령 대비 실제**를 그린다.
%             The live view: what was commanded against what the vessel did.
%
%   W06_animate(y, t)      Animate 블록이 매 스텝 부른다 / called every step
%   f = W06_animate()      그 창의 핸들 / the handle of that window
%
%   무엇을 보여야 하는가 / what has to be visible
%
%   이 주차의 모델은 **고리 둘**이다. 바깥 위치 고리가 속도 명령 `u_d`, `v_d` 를
%   내고 안쪽 속도 고리가 그것을 추종한다. 그래서 화면이 상태만 보여 주면 정작
%   물어야 할 것 — **명령을 따라갔는가** — 을 볼 수 없다. 이 창의 오른쪽 넷은
%   모두 **점선이 명령, 실선이 실제**다:
%
%       north      N_set 대 N          바깥 고리의 위치 명령
%       east       E_set 대 E
%       heading    psi_set 대 psi      [deg]
%       u , v      u_d 대 u , v_d 대 v  **바깥 고리의 출력을 안쪽이 따라가는가**
%
%   The model has two loops: the outer position loop issues a velocity command
%   and the inner loop follows it. A view of the states alone cannot answer the
%   question that matters -- was the command followed -- so in every panel on
%   the right the DASHED line is the command and the SOLID line is the actual.
%   The u, v panel is the cascade itself: the outer loop's output against what
%   the inner loop achieved.
%
%   왜 로그 벡터 하나를 받는가 / why it takes the whole log vector
%
%   `add_measurement` 의 `opts.logFeed` 가 켜져 있으므로 이 함수는 상태 여섯이
%   아니라 **기록되는 19 열 전부**를 받는다. 명령은 주차마다 다르고 6주차만 해도
%   열셋이 더 붙으므로, 포트를 열셋 더 내는 대신 이미 Mux 로 묶인 벡터를 그대로
%   보낸다. 열 이름은 `W06_read` 가 붙이는 것과 **같은 순서**다.
%   With opts.logFeed the block hands this function all 19 logged columns rather
%   than the six vessel states, so every command the week logs is available
%   without cutting thirteen more lanes on the canvas. The column order is the
%   one W06_read names.
%
%   단위 / units
%       psi 와 psi_set 은 **도**로 들어온다 (로그의 6·9 열). r 은 rad/s 다.
%       u_d 와 v_d 는 늘 **몸체 축**이다 — 7 절의 NED 고리도 기록 직전에 한 번
%       돌려 몸체로 맞춘다. 그래서 u 와 u_d 를 그대로 한 축에 놓을 수 있다.
%       psi and psi_set arrive in DEGREES; r is in rad/s. u_d and v_d are always
%       in body axes, the NED rung included, so they may share an axis with u, v.
%
%   부두 설비는 **접안하는 단에만** 그린다 / the berthing furniture is drawn
%   ONLY on a rung that berths
%
%       일곱 단 가운데 접안하는 것은 둘(5·7)뿐이다. 나머지 다섯에 접근점과
%       접안점을 그려 두면 화면에 **아무 의미 없는 점 둘**이 남고, 학생은 그것이
%       무엇인지 묻게 된다 — 실제로 그렇게 물었다. 판정은 `phase` 열이다:
%       임무 상태기계가 있는 단은 첫 표본부터 `phase >= 1` 이고 (TRANSIT),
%       없는 단은 Constant 0 을 기록한다. 그래서 첫 표본 하나로 갈린다.
%       Only two of the seven rungs berth. Drawing the approach point and the
%       berth on the other five leaves two markers that mean nothing, and the
%       reader asks what they are. The test is the phase column: a rung with the
%       mission state machine logs phase >= 1 from the first sample, and every
%       other rung logs a constant 0.
%
%   선체는 **실제 크기**로 그린다 / the hull is drawn at TRUE SIZE
%       2.00 m 다. 늘리면 R_berth = 0.40 m 판정 반경과의 관계가 거짓이 된다 —
%       선수가 접안점 원 안에 들어왔는지가 이 그림에서 읽혀야 한다.
%       Two metres, not scaled up: the relation between the hull and the 0.40 m
%       berth radius has to be readable, and a magnified hull would lie about it.
%
%   See also W06_READ, W06_PLOT, ADD_MEASUREMENT, W06_1_BUILD_BOW.

persistent fig ax h S tLast tPrev mission every

%  창 핸들만 묻는 호출 / a call that only asks for the window
if nargin == 0
    if ~isempty(fig) && isvalid(fig)
        f = fig;
    else
        f = getappdata(0, 'W06_anim_fig');
    end
    return
end
f = [];

NMAX = 40000;                 % 기록을 무한히 늘리지 않는다 / cap the series

%  열 순서는 add_measurement 이 정하고 W06_read 가 이름 붙인 것과 같다
%  the column order add_measurement fixes and W06_read names
u    = y(1);   v    = y(2);   r     = y(3);
N    = y(4);   E    = y(5);   psi   = y(6);      % [deg]
Ns   = y(7);   Es   = y(8);   psis  = y(9);      % [deg]
nL   = y(13);  nR   = y(14);  FB    = y(15);
d    = y(16);  ph   = y(17);
ud   = y(18);  vd   = y(19);                     % 몸체 / body axes

%  새 Run 인가. 시각이 뒤로 갔거나 창이 닫혔으면 새 Run 이다
%  a new run: the clock went backwards, or the window is gone
newRun = isempty(tLast) || isempty(fig) || ~isvalid(fig) || t < tPrev;
tPrev  = t;

SER = {'t','N','E','Ns','Es','psi','psis','u','ud','v','vd','FB','nL','nR'};

if newRun
    S = struct();
    for k = 1:numel(SER), S.(SER{k}) = zeros(0,1); end
    tLast   = -inf;
    every   = base_var('animate_every', 0.5);
    mission = isfinite(ph) && ph >= 1;
    [fig, ax, h] = build_window(N, E, Ns, Es, mission);
end

%  표본을 쌓는다 / append this sample
NEW = {t, N, E, Ns, Es, psi, psis, u, ud, v, vd, FB, nL, nR};
for k = 1:numel(SER)
    S.(SER{k}) = [S.(SER{k}); NEW{k}];
    if numel(S.(SER{k})) > NMAX
        S.(SER{k}) = S.(SER{k})(end-NMAX+1:end);
    end
end

%  그리는 간격. 매 스텝 그리면 시뮬레이션보다 그림이 느려진다
%  the redraw interval: drawing every step makes the picture the bottleneck
if t - tLast < every, return; end
tLast = t;

%% ---- 왼쪽: 항적 / left: the track ------------------------------------
set(h.trail, 'XData', S.E,   'YData', S.N);
set(h.cmd,   'XData', S.Es,  'YData', S.Ns);

[hE, hN] = hull_ned(N, E, psi*pi/180);
set(h.hull, 'XData', hE, 'YData', hN);
set(h.head, 'XData', [E, E + 3.2*sin(psi*pi/180)], ...
            'YData', [N, N + 3.2*cos(psi*pi/180)]);
set(h.dot,  'XData', E, 'YData', N);

%  명령 자세를 **점선 선체**로. 점이 아니라 선체라야 선수각 명령까지 보인다
%  the commanded POSE as a dashed hull: a marker alone cannot show a heading
if isfinite(Ns) && isfinite(Es)
    pg = psis;  if ~isfinite(pg), pg = psi; end
    [gE, gN] = hull_ned(Ns, Es, pg*pi/180);
    set(h.ghost, 'XData', gE, 'YData', gN);
    set(h.mark,  'XData', Es, 'YData', Ns);
end

fit_lims(ax.xy, E, N, 3);
if isfinite(Es), fit_lims(ax.xy, Es, Ns, 3); end

set(h.info, 'String', info_lines(t, ph, mission, N, E, psi, Ns, Es, psis, d, r));

%% ---- 오른쪽: 명령 대 실제 / right: command against actual ------------
set(h.Ns,  'XData', S.t, 'YData', S.Ns);
set(h.N,   'XData', S.t, 'YData', S.N);
set(h.Es,  'XData', S.t, 'YData', S.Es);
set(h.E,   'XData', S.t, 'YData', S.E);
set(h.pss, 'XData', S.t, 'YData', S.psis);
set(h.ps,  'XData', S.t, 'YData', S.psi);
set(h.ud,  'XData', S.t, 'YData', S.ud);
set(h.u,   'XData', S.t, 'YData', S.u);
set(h.vd,  'XData', S.t, 'YData', S.vd);
set(h.v,   'XData', S.t, 'YData', S.v);
set(h.FB,  'XData', S.t, 'YData', S.FB);
set(h.nL,  'XData', S.t, 'YData', S.nL);
set(h.nR,  'XData', S.t, 'YData', S.nR);

pad_y(ax.N, [S.N;   S.Ns]);
pad_y(ax.E, [S.E;   S.Es]);
pad_y(ax.H, [S.psi; S.psis]);
pad_y(ax.V, [S.u; S.ud; S.v; S.vd]);
for a = [ax.N ax.E ax.H ax.V ax.T]
    set(a, 'XLim', [0 max(t, 1)]);
end

drawnow limitrate
end

% =========================================================================
function [fig, ax, h] = build_window(N, E, Ns, Es, mission)
%  창 하나를 짓는다. 축과 핸들을 struct 로 돌려주므로 매 스텝 `set` 만 한다
%  build the window once; every step afterwards is a set() on these handles

COL = struct('act',  [0    0.45 0.74], ...   % 실제 / actual
             'cmd',  [0.75 0.10 0.10], ...   % 명령 / command
             'sway', [0.85 0.33 0.10], ...   % v / sway
             'bow',  [0.49 0.18 0.56], ...   % 선수추진기 / bow thruster
             'quay', [0.35 0.25 0.15], ...   % 부두 / the quay
             'dock', [0.82 0.76 0.66]);

old = findall(0, 'Type','figure', 'Tag','W06_anim');
if ~isempty(old), delete(old); end
fig = lab_fig('W06 live view  -  command against actual', 1340, 880);
set(fig, 'Tag', 'W06_anim');
setappdata(0, 'W06_anim_fig', fig);

qE = base_var('quay_E', 0);

%% ---- 항적 / the track ------------------------------------------------
ax.xy = subplot(5, 2, [1 3 5 7 9], 'Parent', fig);
hold(ax.xy, 'on');  grid(ax.xy, 'on');  axis(ax.xy, 'equal');
xlabel(ax.xy, 'east [m]');  ylabel(ax.xy, 'north [m]');

%  장면에서 한계를 잡는다. 모자라면 매 스텝 늘어난다 / from the scene, then grown
sE = E;  sN = N;
if isfinite(Es), sE(end+1) = Es;  sN(end+1) = Ns;  end

if mission
    %  접안하는 단에만 / only on a rung that berths. **부두 벽도 여기 든다** —
    %  접안하지 않는 단에 벽만 서 있으면 그 선이 무엇인지 또 묻게 된다
    %  the quay wall belongs inside this test too: a wall with no berth beside
    %  it is one more mark that means nothing on a rung which never docks
    %  xline 이므로 축이 커져도 끝까지 간다 / an xline follows the limits
    xline(ax.xy, qE, 'Color', COL.quay, 'LineWidth', 3, 'HandleVisibility','off');
    sE(end+1) = qE;   sN(end+1) = N;

    bN = base_var('berth_N', 40);   bE = base_var('berth_E', 1.2);
    so = base_var('stand_off', 7);
    aN = bN;                        aE = bE + so;
    Ra = base_var('R_app', 1.5);    Rb = base_var('R_berth', 0.40);

    [sx, sy] = slip(qE, bN, bE);
    patch('Parent', ax.xy, 'XData', sx, 'YData', sy, ...
          'FaceColor', COL.dock, 'EdgeColor', 0.55*COL.dock, ...
          'LineWidth', 1.0, 'HandleVisibility','off');
    %  이름표는 슬립 **아래**로. 위에 두면 선수 방향선과 겹친다
    %  the label goes BELOW the slip: above it, the heading whisker crosses it
    text(ax.xy, qE + 0.3, bN - 5.0, 'docking station', ...
         'FontSize', 8, 'Color', 0.55*COL.dock);

    circle(ax.xy, aE, aN, Ra, [0.35 0.35 0.35]);
    plot(ax.xy, aE, aN, 'o', 'MarkerSize', 6, 'LineWidth', 1.1, ...
         'MarkerEdgeColor', [0.35 0.35 0.35], 'MarkerFaceColor', 'w', ...
         'HandleVisibility','off');
    text(ax.xy, aE + 1.1, aN + 1.4, ...
         sprintf('approach point  (R_{app} = %.1f m)', Ra), ...
         'FontSize', 8, 'Color', [0.35 0.35 0.35]);

    circle(ax.xy, bE, bN, Rb, COL.cmd);
    plot(ax.xy, bE, bN, 'p', 'MarkerSize', 11, ...
         'MarkerEdgeColor', COL.cmd, 'MarkerFaceColor', [0.95 0.75 0.75], ...
         'HandleVisibility','off');
    text(ax.xy, bE + 1.1, bN - 1.6, ...
         sprintf('berth  (R_{berth} = %.2f m)', Rb), ...
         'FontSize', 8, 'Color', COL.cmd);

    sE = [sE qE aE bE];   sN = [sN aN bN bN-5 bN+5];
end

%  출발점. 어디서 시작했는지가 항적의 절반이다 / where the run began
plot(ax.xy, E, N, 'x', 'MarkerSize', 9, 'LineWidth', 1.4, ...
     'Color', [0.35 0.35 0.35], 'HandleVisibility','off');
text(ax.xy, E + 1.0, N - 1.2, 'start', 'FontSize', 8, 'Color', [0.35 0.35 0.35]);

%  명령 — 점선, 실제 — 실선. 이 창 전체가 같은 규칙이다
%  dashed is the command, solid is the actual, in every panel of this window
h.cmd   = plot(ax.xy, nan, nan, '--', 'Color', COL.cmd, 'LineWidth', 1.2, ...
               'DisplayName', 'commanded position');
h.mark  = plot(ax.xy, nan, nan, 's', 'MarkerSize', 8, 'LineWidth', 1.2, ...
               'MarkerEdgeColor', COL.cmd, 'MarkerFaceColor','none', ...
               'DisplayName', 'command now');
h.ghost = patch('Parent', ax.xy, 'XData', nan, 'YData', nan, ...
                'FaceColor','none', 'EdgeColor', COL.cmd, ...
                'LineStyle','--', 'LineWidth', 1.0, ...
                'DisplayName', 'commanded pose');
h.trail = plot(ax.xy, nan, nan, '-', 'Color', COL.act, 'LineWidth', 1.4, ...
               'DisplayName', 'actual track');
h.hull  = patch('Parent', ax.xy, 'XData', nan, 'YData', nan, ...
                'FaceColor', [0.95 0.45 0.20], 'FaceAlpha', 0.90, ...
                'EdgeColor', [0.40 0.15 0.05], 'LineWidth', 1.1, ...
                'DisplayName', 'hull (2.0 m, true size)');
h.head  = plot(ax.xy, nan, nan, '-', 'Color', [0.40 0.15 0.05], ...
               'LineWidth', 1.5, 'HandleVisibility','off');
h.dot   = plot(ax.xy, nan, nan, 'k.', 'MarkerSize', 9, 'HandleVisibility','off');

pad = max(5, 0.18*max([max(sE)-min(sE), max(sN)-min(sN), 12]));
set(ax.xy, 'XLim', [min(sE)-pad, max(sE)+pad], ...
           'YLim', [min(sN)-pad, max(sN)+pad]);
legend(ax.xy, 'Location','southeast', 'AutoUpdate','off', 'FontSize', 7);
h.info = title(ax.xy, '', 'Interpreter','tex', 'FontSize', 9);

%% ---- 명령 대 실제, 넷 / command against actual, four panels ----------
%  축 하나에 명령과 실제를 함께 둔다. 따로 두면 저마다 축이 늘어나 오차가
%  보이지 않는다 / on one axis each: separate axes rescale and hide the error
P = {'N', 'north  [m]';  'E', 'east  [m]';  'H', '\psi  [deg]'};
for k = 1:3
    ax.(P{k,1}) = subplot(5, 2, 2*k, 'Parent', fig);
    hold(ax.(P{k,1}), 'on');  grid(ax.(P{k,1}), 'on');
    ylabel(ax.(P{k,1}), P{k,2});
    set(ax.(P{k,1}), 'FontSize', 8);
end
%  **실선을 먼저, 점선을 나중에** 만든다. 나중에 만든 선이 위에 놓이므로, 잘
%  따라간 구간에서 점선이 실선 위에 올라타 둘이 함께 보인다. 반대로 두면 명령이
%  실선 아래로 사라지고, 그 구간이 하필 **가장 잘 된** 구간이다
%  the solid is created FIRST and the dashed command LAST, so the command rides
%  on top: created the other way round it vanishes under the solid line exactly
%  where the tracking is best
h.N   = plot(ax.N, nan, nan, '-',  'Color', COL.act, 'LineWidth', 1.3, ...
             'DisplayName', 'N  actual');
h.Ns  = plot(ax.N, nan, nan, '--', 'Color', COL.cmd, 'LineWidth', 1.3, ...
             'DisplayName', 'N_{set}  commanded');
h.E   = plot(ax.E, nan, nan, '-',  'Color', COL.act, 'LineWidth', 1.3, ...
             'DisplayName', 'E  actual');
h.Es  = plot(ax.E, nan, nan, '--', 'Color', COL.cmd, 'LineWidth', 1.3, ...
             'DisplayName', 'E_{set}  commanded');
h.ps  = plot(ax.H, nan, nan, '-',  'Color', COL.act, 'LineWidth', 1.3, ...
             'DisplayName', '\psi  actual');
h.pss = plot(ax.H, nan, nan, '--', 'Color', COL.cmd, 'LineWidth', 1.3, ...
             'DisplayName', '\psi_{set}  commanded');
%  범례는 **속이 비어** 있어야 한다. 흰 상자를 두면 그 아래의 곡선이 가려지고,
%  가려지는 자리가 하필 정상상태다 / a filled legend box hides the curve beneath
%  it, and that is exactly where the steady state is
for a = [ax.N ax.E ax.H]
    legend(a, 'Location','southeast', 'AutoUpdate','off', 'FontSize', 7, ...
           'Orientation','horizontal', 'Box','off', 'Color','none');
end

%  바깥 고리의 출력을 안쪽 고리가 따라가는가 — 이 주차의 종속 연결 그 자체다
%  the cascade itself: does the inner loop follow what the outer loop asked for
ax.V = subplot(5, 2, 8, 'Parent', fig);
hold(ax.V, 'on');  grid(ax.V, 'on');  set(ax.V, 'FontSize', 8);
ylabel(ax.V, 'u , v  [m/s]');
yline(ax.V, 0, 'k:', 'HandleVisibility','off');
%  이 칸은 쌍이 둘이라 명령을 붉게 둘 수 없다 — 쌍마다 한 색이고 점선이 명령이다.
%  여기서도 점선이 **나중**이라 실선 위에 놓인다
%  two pairs here, so the command cannot be red: each pair takes one colour and
%  the dash marks the command, again created last so it lies on top
h.u  = plot(ax.V, nan, nan, '-',  'Color', COL.act,  'LineWidth', 1.3, ...
            'DisplayName', 'u  actual');
h.v  = plot(ax.V, nan, nan, '-',  'Color', COL.sway, 'LineWidth', 1.3, ...
            'DisplayName', 'v  actual');
h.ud = plot(ax.V, nan, nan, '--', 'Color', COL.act,  'LineWidth', 1.2, ...
            'DisplayName', 'u_d  outer loop');
h.vd = plot(ax.V, nan, nan, '--', 'Color', COL.sway, 'LineWidth', 1.2, ...
            'DisplayName', 'v_d  outer loop');
legend(ax.V, 'Location','southeast', 'AutoUpdate','off', 'FontSize', 7, ...
       'Orientation','horizontal', 'Box','off', 'Color','none');

%% ---- 세 추진기 / the three thrusters ---------------------------------
%  완전구동이라는 말이 그림 한 자리에서 보이는 곳이다 — 축 둘과 선수추진기 하나
%  where "fully actuated" is visible in one place: two shafts and the bow unit
ax.T = subplot(5, 2, 10, 'Parent', fig);
hold(ax.T, 'on');  grid(ax.T, 'on');  set(ax.T, 'FontSize', 8);
yyaxis(ax.T, 'left');
h.nL = plot(ax.T, nan, nan, '-', 'Color', [0.20 0.20 0.20], 'LineWidth', 1.1, ...
            'DisplayName', 'n_L');
h.nR = plot(ax.T, nan, nan, '-', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.1, ...
            'DisplayName', 'n_R');
ylabel(ax.T, 'n_L , n_R  [rad/s]');
ax.T.YAxis(1).Color = [0.25 0.25 0.25];
yyaxis(ax.T, 'right');
h.FB = plot(ax.T, nan, nan, '-', 'Color', COL.bow, 'LineWidth', 1.3, ...
            'DisplayName', 'F_B  bow');
ylabel(ax.T, 'F_B  [N]');
ax.T.YAxis(2).Color = COL.bow;
xlabel(ax.T, 'time [s]');
legend(ax.T, [h.nL h.nR h.FB], 'Location','southeast', 'AutoUpdate','off', ...
       'FontSize', 7, 'Orientation','horizontal', 'Box','off', 'Color','none');

%  오른쪽 다섯은 범례를 안에 들고 있으므로 조금 좁혀 겹치지 않게 한다
%  the five panels carry their legends inside, so they are narrowed a little
for a = [ax.N ax.E ax.H ax.V ax.T]
    p = get(a, 'Position');
    set(a, 'Position', [p(1) p(2) p(3)*0.92 p(4)]);
end
end

% =========================================================================
function s = info_lines(t, ph, mission, N, E, psi, Ns, Es, psis, d, r)
%  제목 두 줄. 그림에서 못 읽는 수치만 글자로 쓴다
%  two title lines, carrying only the numbers the picture cannot show
if mission
    L1 = sprintf('%s        t = %6.2f s', phase_name(ph), t);
else
    L1 = sprintf('t = %6.2f s', t);
end

%  두 줄로 나눈다. 한 줄에 몰면 제목이 그림 폭을 넘어 잘린다
%  split in two: on one line the title runs past the edge of the panel
if isfinite(Ns) && isfinite(Es)
    dist = hypot(Ns - N, Es - E);
    if isfinite(d), dist = d; end          % 모델이 잰 값이 있으면 그것 / the model's own
    L2 = sprintf('N %7.2f / cmd %7.2f      E %7.2f / cmd %7.2f', N, Ns, E, Es);
    L3 = sprintf(['\\psi %6.1f / cmd %6.1f deg      d %5.2f m' ...
                  '      r %5.2f deg/s'], psi, psis, dist, r*180/pi);
else
    %  열린 루프 — 명령 위치가 없다 / the open-loop rung has no commanded position
    L2 = sprintf('N %7.2f      E %7.2f      (open loop: no position command)', N, E);
    L3 = sprintf('\\psi %6.1f deg      r %5.2f deg/s', psi, r*180/pi);
end
s = {L1, L2, L3};
end

% =========================================================================
function nm = phase_name(ph)
%  mission_code 의 네 단계와 **같은 이름**이다 / the names mission_code uses
NM = {'1  TRANSIT', '2  ALIGN', '3  BERTH', '4  MOORED'};
k  = min(max(round(ph), 1), numel(NM));
nm = ['phase ' NM{k}];
end

% =========================================================================
function [xe, yn] = hull_ned(N, E, psi)
%  선체 윤곽을 NED 로. `_tools/draw_ship` 과 **같은 다각형**이고 실제 크기다
%  the hull outline in NED: the same polygon as draw_ship, at true size.
%  동쪽이 x, 북쪽이 y 인 축으로 돌려준다 / returned for an east-x, north-y axis
L = 2.00;                          % Otter 전장 / overall length [m]
a = L/2;
b = L*(1.08/2.00)/2;               % 반폭 / half beam
bx = [ -a   -a    0.25*a   a    0.25*a ];
by = [  b   -b   -b        0    b      ];
yn = N + bx*cos(psi) - by*sin(psi);
xe = E + bx*sin(psi) + by*cos(psi);
end

% =========================================================================
function [xe, yn] = slip(qE, bN, bE)
%  ㄷ 자 도크. 부두(E = qE)를 등지고 **동쪽으로 열린다** — 배가 동쪽에서 온다
%  a U-shaped slip, backed onto the quay at E = qE and open to the EAST,
%  which is the side the vessel approaches from in both berthing rungs.
H  = 3.4;                          % 슬립 반폭 / half width, along north
w  = 1.0;                          % 방축 폭 / finger width
Lf = (bE - qE) + 2.6;              % 방축이 동쪽으로 뻗는 길이 / finger length
xe = qE + [0  Lf  Lf   w    w     Lf    Lf  0];
yn = bN + [-H -H  -H+w -H+w  H-w   H-w   H  H];
end

% =========================================================================
function circle(a, xc, yc, R, col)
%  판정 반경 하나 / one acceptance radius
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
