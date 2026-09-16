function Lship = track_ships(tracks, COL, varargin)
%TRACK_SHIPS  궤적을 따라가며 선체와 선수방위를 함께 그린다.
%             Draw the hull and heading along every track, into the current axes.
%
%   Lship = track_ships(tracks, COL)
%   Lship = track_ships(tracks, COL, 'Marks', 7, 'MinLength', 2.00)
%
%   왜 궤적선만으로는 부족한가 / why a track line alone is not enough
%       궤적만 그리면 배가 그때 어디를 향하고 있었는지 알 수 없다. 그런데 이
%       강의에서 반복해서 다루는 양 — 크랩각 — 이 바로 그 둘의 차이다. 선체를
%       함께 그려야 "가는 방향" 과 "향한 방향" 이 눈에 같이 들어온다.
%
%       A track line does not say where the vessel was pointing while it drew
%       it, and the difference between where it goes and where it points is
%       the crab angle, which this course returns to again and again. Drawing
%       the hull puts both in the same picture.
%
%   입력 / inputs
%     tracks    셀 배열. 각 원소는 n x 3 행렬이고 열은 [N  E  psi] 이다.
%               N 과 E 는 미터, psi 는 **도** 단위이다. psi 를 라디안으로 주면
%               거의 돌지 않는 배가 그려진다. 단위를 틀렸을 때 나타나는 흔한 증상이다
%               a cell array; each element is an n-by-3 matrix whose columns
%               are [N  E  psi], with N and E in metres and psi in DEGREES.
%               Passing psi in radians draws a vessel that barely turns, which
%               is the usual symptom of the wrong unit
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
