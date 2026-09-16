function path_plot(WP, R, N, E, PSI, COL, LBL, V)
%PATH_PLOT  유도 주차의 표준 궤적 그림.
%           The standard track figure of the guidance weeks.
%
%   path_plot(WP, R, N, E, PSI, COL, LBL, V)
%
%     WP    웨이포인트 목록, 한 행이 [N E]
%           the waypoint list, [N E] per row
%     R     전환 파라미터 [m]. 각 웨이포인트 둘레에 그려지는 원의 반지름이다
%           the switching parameter [m], drawn as a circle about each waypoint
%     N,E   위치. 배 한 척이 한 **열**이다
%           position, one column per vessel
%
%   경로선·웨이포인트·수락반경·선체·조류 화살표를 한 함수가 모두 그린다. 절마다
%   따로 그리면 같은 그림이 절마다 조금씩 달라지고, 그 차이에는 아무 뜻이 없다.
%   One function draws the path, the waypoints, the acceptance radii, the hulls
%   and the current arrow. Drawn separately in each section, the same figure
%   would differ slightly from section to section, and the differences would
%   mean nothing.
%     PSI   heading [deg], one column per vessel
%     COL   m-by-3 RGB, one row per vessel
%     LBL   cell array of legend labels
%     V     optional struct with V_c and beta_c, to draw the current
%
%   WHAT IS DRAWN, AND WHY EACH PIECE IS THERE
%
%     the planned path      dashed grey - the thing being followed, so that
%                           "did it follow the path" is a question the reader
%                           can answer by looking
%     the waypoints         open circles, numbered
%     the acceptance radii  dotted circles of radius R, because half of what
%                           section F is about is where those circles are
%     the tracks            one colour per vessel
%     the hulls             drawn along each track by track_ships, so the
%                           reader can see where the vessel POINTED while it
%                           went there. A bare line cannot show a crab angle
%     the current           a few arrows, if V is given
%
%   The hulls are the reason this is a shared function rather than four lines
%   in each script: getting them, their spacing and the equal axes right is
%   fiddly, and a figure that leaves them out is a figure that hides the crab
%   angle this course spends three weeks measuring.

if nargin < 8, V = []; end

hold on; axis equal;

%  ---- the path, and the waypoints ---------------------------------------
plot(WP(:,2), WP(:,1), '--', 'Color',[0.6 0.6 0.6], 'LineWidth',1.2, ...
     'DisplayName','planned path');
th = linspace(0, 2*pi, 60);
for k = 1:size(WP,1)
    plot(WP(k,2) + R*cos(th), WP(k,1) + R*sin(th), ':', ...
         'Color',[0.6 0.6 0.6], 'HandleVisibility','off');
    plot(WP(k,2), WP(k,1), 'o', 'Color',[0.4 0.4 0.4], ...
         'MarkerFaceColor','w', 'MarkerSize',7, 'HandleVisibility','off');
    text(WP(k,2)+2, WP(k,1)+3, sprintf('%d', k), 'Color',[0.4 0.4 0.4]);
end

%  ---- the tracks, with the hull and heading on each ----------------------
nv = size(N,2);
for i = 1:nv
    plot(E(:,i), N(:,i), 'Color', COL(i,:), 'LineWidth',1.5, 'DisplayName', LBL{i});
end
for i = 1:nv
    track_ships({[N(:,i) E(:,i) PSI(:,i)]}, COL(i,:), 'Marks', 5, 'Heading', 0.9);
end

%  ---- the frame is the MISSION, not the track ---------------------------
%  A vessel that runs past the last waypoint keeps going, and auto-ranged axes
%  then squeeze the whole waypoint pattern into a corner. The mission is what
%  the figure is about, so the mission sets the frame and anything beyond it
%  simply leaves the picture. This happens BEFORE the current is drawn,
%  because the arrows are placed relative to the frame.
mN = [min(WP(:,1)) max(WP(:,1))];
mE = [min(WP(:,2)) max(WP(:,2))];
pad = 0.18 * max(diff(mN), diff(mE)) + 2*R;
xlim(mE + [-pad pad]);
ylim(mN + [-pad pad]);

%  ---- the current, if there is one ---------------------------------------
%  Six arrows, not sixty: the reader needs the DIRECTION, and a dense field
%  hides the tracks it is drawn over.
if ~isempty(V) && isfield(V,'V_c') && V.V_c > 0
    xl = xlim; yl = ylim;
    xl = xl + [0.10 -0.10]*diff(xl);
    yl = yl + [0.10 -0.10]*diff(yl);
    [ax, ay] = meshgrid(linspace(xl(1), xl(2), 3), linspace(yl(1), yl(2), 2));
    L = 0.06 * max(diff(xl), diff(yl));
    dN = L*cos(V.beta_c);  dE = L*sin(V.beta_c);
    quiver(ax(:), ay(:), repmat(dE,numel(ax),1), repmat(dN,numel(ax),1), 0, ...
           'Color',[0.35 0.55 0.85], 'LineWidth',1.1, 'MaxHeadSize',0.6, ...
           'DisplayName', sprintf('current %.2f m/s at %.0f deg', ...
                                   V.V_c, rad2deg(V.beta_c)));
end

xlabel('East [m]'); ylabel('North [m]');
end
