function moved = compact_layout(mdl, want, dim)
%COMPACT_LAYOUT  도면의 **빈 복도**를 좁혀 블록을 한곳으로 모은다.
%                Narrow the empty corridors of a diagram so the blocks gather.
%
%   compact_layout(mdl)            가로 복도를 60 px 로 / horizontal, to 60 px
%   compact_layout(mdl, 80)        가로 복도를 80 px 로
%   compact_layout(mdl, 80, 2)     세로 복도를 80 px 로 / vertical instead
%
%   빌더의 끝에서 **mss_style 다음, straighten_lines 앞**에 부른다.
%   Call it at the end of a builder, after mss_style and before straighten_lines.
%
%   WHY
%
%   페이지 폭은 정해져 있다. 도면이 옆으로 길면 PDF 에서 그만큼 줄어들어 블록
%   이름이 읽히지 않는다. 빈 복도는 아무것도 말하지 않으면서 그 폭을 먹는다.
%   The page width is fixed. A diagram that sprawls sideways is shrunk to fit it,
%   and the block names shrink with it. An empty corridor says nothing and eats
%   that width.
%
%   HOW
%
%   블록과 주석이 **차지하지 않은 구간**이 복도다. 복도 하나를 want 로 좁히고,
%   그 오른쪽에 있는 것을 전부 같은 거리만큼 왼쪽으로 옮긴다.
%   A corridor is a span that no block and no annotation occupies. Each corridor
%   is narrowed to want, and everything to the right of it moves left by the
%   same amount.
%
%   복도 **안을 세로 선이 지나면 그 복도는 건드리지 않는다**. 되먹임선이 빈 곳을
%   타고 내려가는 일이 많고, 그 복도를 좁히면 나란히 내려가던 선들이 서로 겹친다 -
%   실제로 한 번 겹침 29 쌍을 만들고 되돌렸다 (2026-10-13).
%   A corridor with a vertical line running down it is left alone. Feedback
%   lines use empty columns, and narrowing such a corridor pushes neighbouring
%   risers onto one another: doing it cost 29 overlapping pairs once, and the
%   rule above is what replaced it.
%
%   거리가 모두 같으므로 **직각이 유지된다**: 복도를 가로지르던 가로 선분은
%   짧아질 뿐이고, 세로 선분은 x 가 하나뿐이라 통째로 옮겨진다.
%   Right angles survive: a horizontal stretch crossing a corridor merely gets
%   shorter, and a vertical stretch has a single x, so it moves as one.
%
%   그래도 끝나고 **check_overlaps 와 check_diagonals 를 다시 센다.**

if nargin < 2 || isempty(want), want = 60; end
if nargin < 3, dim = 1; end                 % 1 = 가로 / horizontal, 2 = 세로

pad  = 14;                                  % 이름표가 블록 밖으로 나가는 만큼 / name labels
tol  = 0.5;
room = 20;                                  % 복도 안 세로선 하나가 쓰는 폭 / air per line
lo   = dim;  hi = dim + 2;

blocks = find_system(mdl, 'SearchDepth',1, 'Type','Block');
notes  = find_system(mdl, 'FindAll','on', 'SearchDepth',1, 'Type','annotation');
lines  = find_system(mdl, 'FindAll','on', 'SearchDepth',1, 'Type','line');

%  블록과 주석이 차지한 구간 / the spans blocks and annotations occupy
span = zeros(0,2);
for i = 1:numel(blocks)
    p = get_param(blocks{i}, 'Position');
    span(end+1,:) = [p(lo)-pad p(hi)+pad];                       %#ok<AGROW>
end
for i = 1:numel(notes)
    p = get_param(notes(i), 'Position');
    if numel(p) == 4, span(end+1,:) = [p(lo)-pad p(hi)+pad]; end %#ok<AGROW>
end
if isempty(span), moved = 0; return; end

span = sortrows(span);
merged = span(1,:);
for i = 2:size(span,1)
    if span(i,1) <= merged(end,2)
        merged(end,2) = max(merged(end,2), span(i,2));
    else
        merged(end+1,:) = span(i,:);                             %#ok<AGROW>
    end
end

%  오른쪽 복도부터 좁힌다 / narrow from the far side inwards.
%  좁힐 때마다 겹침을 다시 센다. 늘어나면 **그 복도만 되돌린다** - 블록이 가까워지면
%  멀리 떨어져 있던 선 둘이 같은 자리에 올 수 있다.
%  Overlaps are counted again after each corridor and a corridor that made them
%  worse is put back: pulling blocks together can bring two distant lines onto
%  the same track.
moved = 0;
n0 = overlaps(mdl);
for i = size(merged,1):-1:2
    a = merged(i-1,2);  b = merged(i,1);
    if ~isempty(lines_in(lines, a, b, dim, tol)), continue; end   % 선이 지나는 복도는 둔다
    shift = round((b - a) - want);
    if shift <= 0, continue; end
    squeeze_at(blocks, notes, lines, a, b, want, shift, dim, tol);
    n1 = overlaps(mdl);
    if n1 > n0
        squeeze_at(blocks, notes, lines, a, b - shift, want, -shift, dim, tol);
    else
        n0 = n1;  moved = moved + 1;
    end
end
end

% =========================================================================
function n = overlaps(mdl)
n = 0;
try, [~, n] = evalc('check_overlaps(mdl)'); catch, end
end

% =========================================================================
function xs = lines_in(lines, a, b, dim, tol)
xs = [];
for i = 1:numel(lines)
    p = get_param(lines(i), 'Points');
    for k = 1:size(p,1)-1
        if abs(p(k,dim) - p(k+1,dim)) <= tol && p(k,dim) > a && p(k,dim) < b
            xs(end+1) = p(k,dim);                                %#ok<AGROW>
        end
    end
end
xs = unique(round(xs));
end

% =========================================================================
function squeeze_at(blocks, notes, lines, ~, b, ~, shift, dim, ~)
lo = dim;  hi = dim + 2;                    % 복도는 비어 있다 / the corridor is empty
for i = 1:numel(blocks)
    p = get_param(blocks{i}, 'Position');
    if p(lo) >= b - 0.5
        p([lo hi]) = p([lo hi]) - shift;
        set_param(blocks{i}, 'Position', round(p));
    end
end
for i = 1:numel(notes)
    p = get_param(notes(i), 'Position');
    if numel(p) == 4 && p(lo) >= b - 0.5
        p([lo hi]) = p([lo hi]) - shift;
        set_param(notes(i), 'Position', round(p));
    end
end
for i = 1:numel(lines)
    p = get_param(lines(i), 'Points');
    v = p(:,dim);
    right = v >= b - 0.5;
    if ~any(right), continue; end
    v(right) = v(right) - shift;
    p(:,dim) = v;
    try, set_param(lines(i), 'Points', round(p)); catch, end
end
end
