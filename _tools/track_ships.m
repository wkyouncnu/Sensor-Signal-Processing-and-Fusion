function Lship = track_ships(tracks, COL, varargin)
%TRACK_SHIPS  Draw the hull and heading along every track, into the current axes.
%
%   Lship = track_ships(tracks, COL)
%   Lship = track_ships(tracks, COL, 'Marks', 7, 'MinLength', 2.00)
%
%   INPUTS
%     tracks    cell array. Each element is an n-by-3 matrix whose columns are
%               [N  E  psi], with N and E in metres and psi in DEGREES. Passing
%               psi in radians draws a vessel that barely turns at all, which is
%               the usual symptom
%     COL       m-by-3 RGB, one row per track, reused cyclically
%
%   NAME/VALUE
%     'Marks'      silhouettes per track                       default 7
%     'MinLength'  smallest silhouette to draw [m]             default 2.00
%     'Heading'    heading line length in units of Lship       default 1.3
%
%   OUTPUT
%     Lship     the drawing length that was used [m]
%
%   HOW THE SIZE IS CHOSEN
%
%   The silhouette is scaled to the extent of the figure, not to the true hull.
%   Drawn at true size on a 160 m track, the 2.00 m Otter is under one pixel.
%
%       Lship = max( 0.045 * (largest axis span), MinLength )
%
%   The floor matters. A vessel turning on the spot traces a circle a metre or
%   two across, which is SMALLER than the vessel itself: the hull is rotating
%   about a point inside its own waterline. Scaling purely to the extent would
%   shrink the silhouette below the real hull and hide that fact, so the floor
%   is set to the true overall length and the drawing stays honest.
%
%   Positions are spaced by arc length, not by time — see ship_marks.

p = inputParser;
p.addParameter('Marks',     7);
p.addParameter('MinLength', 2.00);      % Otter overall length [m]
p.addParameter('Heading',   1.3);
p.parse(varargin{:});
o = p.Results;

if ~iscell(tracks), tracks = {tracks}; end

allN = []; allE = [];
for i = 1:numel(tracks)
    allN = [allN; tracks{i}(:,1)];  %#ok<AGROW>
    allE = [allE; tracks{i}(:,2)];  %#ok<AGROW>
end
span  = max([max(allN)-min(allN), max(allE)-min(allE), 0]);
Lship = max(0.045*span, o.MinLength);

ax = gca;
for i = 1:numel(tracks)
    N = tracks{i}(:,1);  E = tracks{i}(:,2);  psi = deg2rad(tracks{i}(:,3));
    c = COL(1+mod(i-1, size(COL,1)), :);
    idx = ship_marks(N, E, o.Marks);
    for k = 1:numel(idx)
        j = idx(k);
        %  The last silhouette is opaque so the end of the run is unambiguous.
        fa = 0.55 + 0.35*(k == numel(idx));
        draw_ship(ax, N(j), E(j), psi(j), Lship, c, ...
                  'FaceAlpha', fa, 'Heading', o.Heading);
    end
end
end
