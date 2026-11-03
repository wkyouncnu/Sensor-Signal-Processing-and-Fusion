function f = W12_plot_scenario(r, Srow, tau, cfg)
%W12_PLOT_SCENARIO  시나리오 **하나**를 한 장에 그린다.
%                   One scenario, one figure.
%
%   f = W12_plot_scenario(r, Srow, tau, cfg)
%
%     r      `W12_read` 가 돌려준 로그 하나 / one log struct from W12_read
%     Srow   `W12_cases` 의 한 줄 — {tag, n, delta, 지시 이름, 예상 기동}
%     tau    그 줄의 [X Y N] / the [X Y N] of that row
%     cfg    otter_config('quad_tilt')
%
%   왜 한 장에 하나인가 / why one scenario per figure
%       여덟을 한 칸에 겹쳐 그리면 곡선이 서로를 지우고, **어느 것이 예상대로
%       되었는지** 볼 수 없다. 그래서 절 스크립트는 여덟 장을 따로 저장하고,
%       겹쳐 그린 한 장은 비교용으로 따로 둔다.
%       Eight runs in one axes erase each other, so each scenario gets its own
%       sheet and the overlay stays a separate, comparison-only figure.
%
%   무엇이 한 장에 들어가는가 / what one sheet carries
%       왼쪽 3x2   상태량 여섯 — u, v, r, psi, N, E. MILS 스크립트와 같은 여섯이다
%       오른쪽 위  **지시한 추력 자체** — 선체 평면도에 추진기 넷과 그 힘 화살표
%       오른쪽 아래 궤적. 선체와 선수방위를 함께 그린다 (크랩각이 보여야 한다)
%
%       오른쪽 위 칸이 이 그림의 핵심이다. 상태량만 보면 "틀린 명령을 정확히
%       따른 것" 과 "맞는 명령을 틀리게 따른 것" 을 가를 수 없다. 힘 화살표가
%       지시를 그림으로 되읽어 준다 / the arrow panel reads the command back as
%       a picture, which the state traces alone cannot do.
%
%   See also W12_PLOT, W12_CASES, W12_V_OPENLOOP, TRACK_SHIPS, LAB_FIG.

tag = Srow{1};  nm = Srow{4};  exp_txt = Srow{5};
ncm = Srow{2};  dcm = Srow{3};

f = lab_fig(sprintf('W12  %s  %s', tag, nm), 1240, 820);

C1 = [0 0.45 0.74];

%  왼쪽 3x2 — 상태량 여섯 / the six states, left
P = { 1, r.u,            'u  surge [m/s]'
      2, r.v,            'v  sway [m/s]'
      4, rad2deg(r.r),   'r  yaw rate [deg/s]'
      5, r.psi,          '\psi  heading [deg]'
      7, r.N,            'x  North [m]'
      8, r.E,            'y  East [m]' };
for k = 1:size(P,1)
    subplot(3,3,P{k,1});
    plot(r.t, P{k,2}, 'Color', C1, 'LineWidth', 1.5);
    grid on; xlabel('time [s]'); ylabel(P{k,3});
    xlim([r.t(1) r.t(end)]);
end

%  오른쪽 위 — 지시한 추력 / the commanded thrust, top right
command_plan(subplot(3,3,3), cfg, Srow);

%  오른쪽 아래 둘 칸 — 궤적 / the track, lower right, two cells tall
ax = subplot(3,3,[6 9]); hold on; grid on;
plot(r.E, r.N, 'Color', C1, 'LineWidth', 1.5);
%  다섯 척이면 충분하다 — 제자리 선회는 같은 자리에 겹쳐 찍히므로, 일곱이면
%  선수선이 엉켜 방향이 읽히지 않는다 / five silhouettes, because a spot turn
%  stacks them on one point and seven heading lines tangle
track_ships({[r.N r.E r.psi]}, C1, 'Marks', 5, 'Heading', 1.0);
plot(0, 0, 'ks', 'MarkerFaceColor', 'w', 'HandleVisibility', 'off');
xlabel('y  East [m]'); ylabel('x  North [m]');
%  선체 글리프는 2 m 다. 제자리 선회(S3·S4)는 궤적이 0.1 m 밖에 안 되므로, 보이는
%  범위에 **바닥**을 두지 않으면 글리프가 칸을 가득 메워 아무것도 읽히지 않는다
%  / the hull glyph is 2 m long and a spot turn moves 0.1 m, so the view gets a
%  floor: without it the glyph fills the panel and nothing reads
cE = (max(r.E) + min(r.E))/2;   cN = (max(r.N) + min(r.N))/2;
span = max([max(r.E)-min(r.E), max(r.N)-min(r.N), 5]);
xlim(ax, cE + 0.58*span*[-1 1]);
ylim(ax, cN + 0.58*span*[-1 1]);
daspect(ax, [1 1 1]);
title('track, hull drawn every few metres');

%  제목 석 줄이 들어가도록 축 전체를 아래로 눌러 둔다. sgtitle 은 축을 비켜
%  주지 않아서, 누르지 않으면 윗줄 제목과 겹친다 / sgtitle does not make room,
%  so every axes is squeezed downward first
for a = findall(f, 'Type', 'axes')'
    p = get(a, 'Position');
    set(a, 'Position', [p(1), p(2)*0.88, p(3), p(4)*0.88]);
end

sgtitle({sprintf('%s   %s', tag, nm), ...
         sprintf(['n = [%.1f %.1f %.1f %.1f] rad/s,   ' ...
                  '\\delta = [%.0f %.0f %.0f %.0f] deg,   ' ...
                  '\\tau = [%.3f N, %.3f N, %.3f N m]'], ncm, dcm, tau), ...
         ['expected:  ' exp_txt]}, 'FontWeight', 'bold', 'FontSize', 11);
end

% =========================================================================
function command_plan(ax, cfg, Srow)
%COMMAND_PLAN  선체 평면도 위에 추진기 넷과 **지시한 힘**을 그린다.
%
%  평면도의 축 / the axes of the plan view
%      화면 가로가 y_b (우현이 오른쪽), 화면 세로가 x_b (선수가 위) 다. MILS
%      스크립트의 `plot(y,x)` 와 같은 약속이고, 그래서 N > 0 이 **시계방향**으로
%      보인다 / screen right is y_b and screen up is x_b, so a positive N reads
%      clockwise, as it does in the lecture's plan figures
%
%  화살표의 길이 / the arrow length
%      60 N 을 0.9 m 로 잡은 **고정** 축척이다. 시나리오마다 다시 맞추지 않으므로
%      S6 의 굵은 회전수가 긴 화살표로 보인다 / a fixed scale, so a scenario with
%      a higher shaft speed really does draw a longer arrow

axes(ax); hold on; grid off;

%  거치 부호를 입힌 추력. 깎기와 수식은 `W12_tau` 한 군데에서 온다 — 그래서
%  화살표가 표와 **같은 배**를 그린다 / the clip and the formula come from
%  W12_tau, so the arrows and the tables cannot drift apart
[~, ~, d, T] = W12_tau(Srow, cfg);
s  = cfg.mount;
Fx = s .* T .* cos(d);
Fy = s .* T .* sin(d);

%  폰툰 둘. 네 자리를 **품도록** 그린다 — l_f = 1.5 m 는 otter.m 의 2.0 m 선체보다
%  앞이고, 이 배치의 갑판은 그만큼 길다 / the pontoons are drawn long enough to
%  carry the stations: l_f reaches ahead of otter.m's 2.0 m waterline
xf = cfg.l_f + 0.25;  xa = -cfg.l_a - 0.25;  w = 0.145;
for yc = [-cfg.y_pont, cfg.y_pont]
    px = [xa      xa      xf-0.30  xf       xf-0.30];
    py = [yc-w    yc+w    yc+w     yc       yc-w   ];
    patch(py, px, [0.90 0.94 0.90], 'EdgeColor', [0.35 0.45 0.35]);
end
plot([-cfg.y_pont cfg.y_pont], [0 0], '-', 'Color', [0.35 0.45 0.35]);
plot([0 0], [xa xf], ':', 'Color', [0.6 0.6 0.6]);

sc = 0.9 / 60;                                   % 60 N -> 0.9 m
for i = 1:4
    x = cfg.pos(1,i);  y = cfg.pos(2,i);
    plot(y, x, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
    if hypot(Fx(i), Fy(i)) > 1e-6
        quiver(y, x, sc*Fy(i), sc*Fx(i), 0, 'Color', [0.85 0.33 0.10], ...
               'LineWidth', 1.6, 'MaxHeadSize', 2);
    end
    ha = 'left';  off = 0.26;
    if y < 0, ha = 'right';  off = -0.26; end
    text(y + off, x, sprintf('%d', i), 'FontSize', 9, ...
         'HorizontalAlignment', ha, 'VerticalAlignment', 'middle');
end
plot(0, 0, 'ks', 'MarkerFaceColor', 'w');

%  축척 설명은 **제목 쪽**에 둔다. 아래에 두면 바로 밑 궤적 칸의 제목과 맞붙어
%  어느 칸의 글인지 읽히지 않는다 / the scale note goes above, not below, where it
%  would sit against the track panel's own title
xlabel('y_b  starboard [m]');
ylabel('x_b  ahead [m]');
title({'the command, drawn', 'arrows are s_i T_i at \delta_i,   60 N = 0.9 m'}, ...
      'FontSize', 9);
axis equal;
xlim([-2.0 2.0]);  ylim([xa-0.9 xf+0.9]);
end
