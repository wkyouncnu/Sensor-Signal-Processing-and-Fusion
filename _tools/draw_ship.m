function h = draw_ship(ax, N, E, psi, Lship, col, varargin)
%DRAW_SHIP  Draw a vessel silhouette and its heading at one point of a track.
%
%   h = draw_ship(ax, N, E, psi, Lship, col)
%   h = draw_ship(..., 'FaceAlpha', 0.85, 'Heading', 1.6, 'LineWidth', 1.0)
%
%   A track alone shows where the vessel went. It does not show which way the
%   vessel was POINTING while it went there, and for a marine vehicle those are
%   two different things: the hull carries a sway velocity, so the heading and
%   the course over ground differ by the crab angle. Every figure in this course
%   that draws a track therefore also draws the hull.
%
%   INPUTS
%     ax      axes to draw into (must already be `hold on`)
%     N, E    position in NED [m].   East is plotted on x, North on y
%     psi     heading [rad], measured from North, positive clockwise
%     Lship   overall length of the drawn silhouette [m]. This is a DRAWING
%             length, not the true hull length: on a 200 m track a 2 m Otter
%             is invisible, so the callers scale it to the axis span
%     col     1x3 RGB
%
%   NAME/VALUE
%     'FaceAlpha'   patch transparency                     default 0.85
%     'Heading'     heading line length, in units of Lship  default 1.6
%                   0 suppresses the line
%     'LineWidth'   outline and heading line width          default 1.0
%
%   OUTPUT
%     h.hull  patch handle
%     h.head  line handle, empty when 'Heading' is 0
%
%   HULL SHAPE
%
%   The polygon is the one used throughout the laboratory's teaching code,
%   shipModel.m (J. Hong, KRISO, 2022): a rectangular stern closed by a
%   triangular bow, so the silhouette reads as an arrow even when it is only a
%   few pixels wide.
%
%       stern                bow
%         +------------+
%         |             \
%         |              >     ---->  heading
%         |             /
%         +------------+
%
%   The beam is taken from the Otter, 1.08 m on a 2.00 m hull, rather than from
%   shipModel.m's generic 2:1.
%
%   ROTATION
%
%   The silhouette is expressed in {b} and rotated into {n} by the planar part
%   of R_b^n(psi). With x_b forward and y_b to starboard,
%
%       N = N_0 + x_b cos(psi) - y_b sin(psi)
%       E = E_0 + x_b sin(psi) + y_b cos(psi)
%
%   which is the first 2x2 block of the rotation matrix of Week 1. Getting the
%   two signs wrong draws a vessel that turns the wrong way, and that is the
%   usual reason an animation looks mirrored.

p = inputParser;
p.addParameter('FaceAlpha', 0.85);
p.addParameter('Heading',   1.6);
p.addParameter('LineWidth', 1.0);
p.parse(varargin{:});
o = p.Results;

BEAM_RATIO = 1.08/2.00;              % Otter: 1.08 m beam on a 2.00 m hull

a = Lship/2;                         % half length
b = Lship*BEAM_RATIO/2;              % half beam

%  stern port -> stern starboard -> shoulder -> bow -> shoulder
bx = [ -a   -a    0.25*a   a    0.25*a ];
by = [  b   -b   -b        0    b      ];

hullN = N + bx*cos(psi) - by*sin(psi);
hullE = E + bx*sin(psi) + by*cos(psi);

h.hull = patch('Parent', ax, 'XData', hullE, 'YData', hullN, ...
               'FaceColor', col, 'FaceAlpha', o.FaceAlpha, ...
               'EdgeColor', 0.45*col, 'LineWidth', o.LineWidth, ...
               'HandleVisibility', 'off');

if o.Heading > 0
    d = o.Heading*Lship;
    h.head = plot(ax, [E, E + d*sin(psi)], [N, N + d*cos(psi)], '-', ...
                  'Color', 0.45*col, 'LineWidth', o.LineWidth, ...
                  'HandleVisibility', 'off');
else
    h.head = gobjects(0);
end
end
