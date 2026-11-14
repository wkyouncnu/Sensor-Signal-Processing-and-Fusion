function quad_thrust_plan(q, T, delta, tau_xy, ttl)
%QUAD_THRUST_PLAN  위에서 본 Otter 와 추진기 넷의 추력 화살표 — **지금 축에 그린다.**
%                  The Otter from above with the four thrust vectors, drawn on
%                  the current axes.
%
%   quad_thrust_plan(q, T, delta, tau_xy)
%   quad_thrust_plan(q, T, delta, tau_xy, ttl)
%
%   들어가는 것 / the arguments
%       q        4 x 4.  `W07_vars` 의 `quad` 그대로 —
%                행 1  x_i  [m]   선수 쪽이 양 / station, bow positive
%                행 2  y_i  [m]   우현 쪽이 양 / offset, starboard positive
%                행 3  서보 각 한계 [rad] (여기서는 쓰지 않는다 / unused here)
%                행 4  장착 부호 +-1 / mounting sign
%       T        4 x 1.  부호 있는 추력 [N]. 음수는 후진 / signed thrust, astern < 0
%       delta    4 x 1.  서보 각 [rad]
%       tau_xy   1 x 2.  요구한 [X Y] [N]. 비우면 그리지 않는다 / omit to skip
%       ttl      제목 한 줄 / one title line
%
%   왜 함수 하나인가 / why this is one function
%       `W07_plot_ca` (모델의 StopFcn) 와 `W07_alloc_run` (절 스크립트) 이 **같은**
%       그림을 그린다. 복사해 두면 한쪽만 고쳐진다 — CLAUDE.md §15-34.
%       Both W07_plot_ca and W07_alloc_run draw this panel. Copied, only one of
%       the two would ever get fixed.
%
%   눈금 / the scale
%       화살표는 **그 그림 안에서** 가장 큰 추력이 0.70 m 가 되도록 줄인다.
%       절대 길이가 아니므로, 길이끼리 견주는 것은 같은 그림 안에서만 옳다.
%       Arrows are scaled so the largest thrust in THIS panel is 0.70 m long, so
%       lengths may be compared within a panel and never across panels.
%
%   See also W07_PLOT_CA, W07_ALLOC_RUN, TRACK_SHIPS.

if nargin < 4, tau_xy = []; end
if nargin < 5, ttl    = ''; end

T     = T(:);
delta = delta(:);
xp    = q(1,:);
yp    = q(2,:);
sm    = q(4,:);

hold on; axis equal; grid on

% 선체 둘 — 길이 3.35 m, 폭 0.32 m, 중심이 +-0.395 m
% the two hulls: 3.35 m long, 0.32 m wide, centred at +-0.395 m
for sy = [-1 1]
    rectangle('Position', [sy*0.395 - 0.16, -1.45, 0.32, 3.35], ...
              'Curvature', 0.35, 'EdgeColor', [.65 .65 .65], ...
              'FaceColor', [.95 .95 .95]);
end

% 추력 화살표 / the thrust arrows
sc = 0.70 / max([abs(T) ; eps]);
for i = 1:4
    vx = sm(i) * T(i) * cos(delta(i));
    vy = sm(i) * T(i) * sin(delta(i));
    plot(yp(i), xp(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
    quiver(yp(i), xp(i), sc*vy, sc*vx, 0, 'LineWidth', 1.8, ...
           'Color', [.85 .2 .2], 'MaxHeadSize', 0.9);
end

% 요구한 힘 / the demand
if ~isempty(tau_xy) && norm(tau_xy) > 0
    sct = 0.70 / norm(tau_xy);
    quiver(0, 0, sct*tau_xy(2), sct*tau_xy(1), 0, 'LineWidth', 2.2, ...
           'Color', [.1 .3 .8], 'MaxHeadSize', 0.9);
end

xlabel('y_b  (starboard) [m]');
ylabel('x_b  (bow) [m]');
xlim([-1.7 1.7]);
ylim([-2.1 2.3]);
if ~isempty(ttl)
    title(ttl, 'FontSize', 9);
end
end
