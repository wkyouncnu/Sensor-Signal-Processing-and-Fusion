function live_track(N, E, psi, t, o)
%LIVE_TRACK  Draw the vessel, its heading and its track while a model runs.
%
%   live_track(N, E, psi, t, o)
%
%   Every week's WXX_animate.m is a thin wrapper around this function, so the
%   live view looks and behaves identically across the course and there is one
%   place to fix when it does not.
%
%   INPUTS
%     N, E   position in NED [m]
%     psi    heading [rad], from North, positive clockwise
%     t      simulation time [s]
%     o      options struct:
%              o.tag     short identifier, e.g. 'W03'. Changing it starts a new
%                        figure, which is what happens when a different week's
%                        model is run in the same MATLAB session
%              o.name    figure name
%              o.title   first title line
%              o.lim     [Emin Emax Nmin Nmax]
%              o.every   redraw interval in simulated seconds
%              o.psi_d   optional heading reference [rad], drawn as a dashed ray
%              o.wp      optional waypoint list, n-by-2 as [N E], drawn dashed
%
%   WHY THE HULL IS DRAWN AND NOT ONLY THE TRACK
%
%   A track shows where the vessel went. It does not show where the vessel was
%   POINTING while it went there, and for a marine vehicle those differ by the
%   crab angle beta = atan2(v, u). Weeks 1 and 4 both contain runs in which the
%   hull points one way and moves another, and no track drawn on its own can
%   show it.
%
%   PERFORMANCE
%
%   Redrawing at every solver step is far slower than the simulation itself, so
%   the figure is refreshed at most every o.every seconds of simulated time, and
%   the graphics handles are reused rather than recreated. Creating a patch per
%   step leaks graphics objects and the figure crawls to a stop.

persistent fig ax hTrail hHull hHead hRef hInfo trailN trailE tLast tPrev Lship tag

%% ---- defaults -----------------------------------------------------------
if ~isfield(o,'tag'),   o.tag   = 'GNC';                 end
if ~isfield(o,'name'),  o.name  = [o.tag ' live track'];  end
if ~isfield(o,'title'), o.title = o.name;                 end
if ~isfield(o,'lim'),   o.lim   = [-50 50 -50 50];        end
if ~isfield(o,'every'), o.every = 0.5;                    end
if ~isfield(o,'psi_d'), o.psi_d = [];                     end
if ~isfield(o,'wp'),    o.wp    = [];                     end

%% ---- a new run resets everything ---------------------------------------
%  t going backwards, a closed figure, or a different week are the three ways
%  a run can be new.
newRun = isempty(tLast) || isempty(fig) || ~isvalid(fig) ...
         || t < tPrev || ~strcmp(tag, o.tag);

if newRun
    if ~isempty(fig) && isvalid(fig), close(fig); end
    tag = o.tag;
    fig = figure('Name', o.name, 'NumberTitle','off', 'Color','w', ...
                 'Position',[80 80 720 700]);
    ax  = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); axis(ax,'equal');
    axis(ax, o.lim);

    %  The silhouette is scaled to the window, not to the true 2 m hull, but
    %  never below true size. See _tools/track_ships.m for why the floor
    %  matters.
    Lship = max(0.045*max(o.lim(2)-o.lim(1), o.lim(4)-o.lim(3)), 2.00);

    if ~isempty(o.wp)
        plot(ax, o.wp(:,2), o.wp(:,1), '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
        plot(ax, o.wp(:,2), o.wp(:,1), 's', 'MarkerEdgeColor',[0.75 0.10 0.10], ...
             'MarkerFaceColor','w', 'MarkerSize',10, 'LineWidth',1.6);
    end
    plot(ax, 0, 0, 'ks', 'MarkerFaceColor','w', 'MarkerSize',9, 'LineWidth',1.2);

    trailN = [];  trailE = [];
    hTrail = plot(ax, nan, nan, '-', 'Color',[0 0.45 0.74], 'LineWidth',1.5);
    hRef   = plot(ax, nan, nan, '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.4);
    hHull  = patch('Parent',ax, 'XData',nan, 'YData',nan, ...
                   'FaceColor',[0.95 0.45 0.20], 'FaceAlpha',0.9, ...
                   'EdgeColor',[0.40 0.15 0.05], 'LineWidth',1.2);
    hHead  = plot(ax, nan, nan, '-', 'Color',[0.40 0.15 0.05], 'LineWidth',1.6);

    xlabel(ax, 'East [m]');  ylabel(ax, 'North [m]');
    hInfo = title(ax, '', 'FontSize',11, 'FontWeight','normal', 'Interpreter','none');
    tLast = -inf;
end
tPrev = t;

if t - tLast < o.every, return; end
tLast = t;

%% ---- the track so far --------------------------------------------------
trailN(end+1) = N;  %#ok<AGROW>
trailE(end+1) = E;  %#ok<AGROW>
set(hTrail, 'XData', trailE, 'YData', trailN);

%% ---- the hull ----------------------------------------------------------
%  Same polygon and same rotation as _tools/draw_ship.m, repeated here so the
%  handles can be reused instead of recreated.
a  = Lship/2;
b  = Lship*(1.08/2.00)/2;
bx = [ -a   -a    0.25*a   a    0.25*a ];
by = [  b   -b   -b        0    b      ];

set(hHull, 'XData', E + bx*sin(psi) + by*cos(psi), ...
           'YData', N + bx*cos(psi) - by*sin(psi));

d = 1.8*Lship;
set(hHead, 'XData', [E, E + d*sin(psi)], ...
           'YData', [N, N + d*cos(psi)]);

%% ---- the heading reference, when there is one --------------------------
if isempty(o.psi_d)
    set(hRef, 'XData', nan, 'YData', nan);
    ref_txt = '';
else
    set(hRef, 'XData', [E, E + d*sin(o.psi_d)], ...
              'YData', [N, N + d*cos(o.psi_d)]);
    ref_txt = sprintf('     psi_d = %7.1f deg', atan2d(sin(o.psi_d), cos(o.psi_d)));
end

%% ---- read-out ----------------------------------------------------------
%  psi is not wrapped by any model in this course. It is wrapped here for
%  display only, so the number stays readable past one revolution.
set(hInfo, 'String', { ...
    o.title, ...
    sprintf('t = %6.1f s      N = %8.2f m      E = %8.2f m      psi = %7.1f deg%s', ...
            t, N, E, atan2d(sin(psi), cos(psi)), ref_txt)});

drawnow limitrate
end
