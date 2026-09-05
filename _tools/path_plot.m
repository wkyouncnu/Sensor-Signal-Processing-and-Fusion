function path_plot(WP, R, N, E, PSI, COL, LBL, V)
%PATH_PLOT  The standard track figure of the guidance weeks.
%
%   path_plot(WP, R, N, E, PSI, COL, LBL, V)
%
%     WP    n-by-2 waypoint list, [N E] per row
%     R     switching parameter [m]; the circles drawn around each waypoint
%     N,E   position, one COLUMN per vessel
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
