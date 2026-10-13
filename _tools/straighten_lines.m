function n = straighten_lines(mdl, verbose)
%STRAIGHTEN_LINES  모델의 모든 선을 가로·세로만으로 다시 놓는다. 대각선을 0 으로.
%                  Re-lay every line in a model with horizontal and vertical
%                  stretches only; drive check_diagonals to 0.
%
%   straighten_lines(mdl)              조용히 / silently
%   n = straighten_lines(mdl, true)    무엇을 고쳤는지 찍고 고친 수를 돌려준다
%
%   빌더의 끝, **mss_style 바로 다음, save_system 직전**에 부른다. 순서가 중요하다 —
%   mss_style 이 블록 크기를 바꾸면 포트가 2~5 px 움직이고, 이미 그려진 선의 끝이
%   포트를 비껴가면서 **짧은 대각선 꺾임**이 생긴다. 도면 전체에 그 꺾임이 하나씩
%   붙는 원인이 그것이다.
%   Call it at the end of a builder, right after mss_style and before
%   save_system. The order matters: mss_style resizes blocks, the ports move a
%   few pixels, and the ends of lines that were drawn earlier no longer meet
%   them - which is where the little diagonal jogs come from.
%
%   두 가지를 한다 / it does two things:
%     1) 포트에 닿는 끝을 **당겨 붙인다**. 어긋남이 작으면(<= snap px) 이웃 점의
%        좌표를 포트에 맞춰 옮긴다. 계단을 새로 만들지 않고 꺾임만 없앤다.
%        Snap the ends. A small mismatch is removed by moving the neighbouring
%        point onto the port, which removes the kink without adding a step.
%     2) 남은 대각선 구간마다 **직각 모서리 하나**를 끼워 넣는다. 출력 포트에서는
%        가로로 나가고 입력 포트로는 가로로 들어가도록 모서리의 방향을 정한다.
%        Every diagonal stretch that remains gets one right-angled corner, laid
%        so that a line leaves an output port horizontally and enters an input
%        port horizontally.
%
%   겹침은 check_overlaps 가, 대각선은 check_diagonals 가 센다. 이 함수는 두 번째만
%   고친다 — 고친 뒤에 **둘 다** 다시 세어야 한다.

if nargin < 2, verbose = false; end
snap = 8;                                   % 당겨 붙이는 한계 / snap tolerance [px]
stub = 20;                                  % 포트에서 떠나는 가로 토막 / the stub at a port
tol  = 0.5;

L = find_system(mdl, 'FindAll','on', 'SearchDepth',99, 'Type','line');
n = 0;
for i = 1:numel(L)
    h = L(i);
    p = get_param(h, 'Points');
    if size(p,1) < 2, continue; end
    q = p;

    %  1) 끝을 포트에 당겨 붙인다 / pull the ends onto their ports
    %  가지가 달린 어미 선은 끝이 여럿이다. 그 끝들은 가지 쪽에서 손본다.
    %  A line with branches has several ends; those are handled on the branches.
    %  포트가 어느 쪽을 보고 있는지에 맞춘다. 둥근 합산점의 두 번째 입력은 **아래쪽**에
    %  달리므로(MSS 식 '|++'), 그 포트로는 세로로 들어가야 한다. 가로로 들여보냈더니
    %  W07 의 느린 외란이 본선과 같은 줄을 15 px 타고 갔다 (2026-10-13).
    %  Follow the direction the port faces. The second input of a round summing
    %  junction sits on its underside (the MSS '|++' shape), so a line must enter
    %  it vertically; entering horizontally made W07's slow disturbance ride 15 px
    %  along the main row.
    dst = get_param(h, 'DstPortHandle');
    if numel(dst) == 1 && dst > 0
        b = get_param(dst, 'Position');
        dh = port_is_horizontal(dst);
        q(end,:) = b;
        k = size(q,1) - 1;
        if dh
            if abs(q(k,2) - b(2)) <= snap && (k == 1 || abs(q(k-1,1) - q(k,1)) <= tol)
                q(k,2) = b(2);
            end
        else
            if abs(q(k,1) - b(1)) <= snap && (k == 1 || abs(q(k-1,2) - q(k,2)) <= tol)
                q(k,1) = b(1);
            end
        end
    else
        dh = true;
    end
    src = get_param(h, 'SrcPortHandle');
    sh = true;
    if numel(src) == 1 && src > 0
        a = get_param(src, 'Position');
        sh = port_is_horizontal(src);
        q(1,:) = a;
        if sh && size(q,1) > 2 && abs(q(2,2) - a(2)) <= snap && abs(q(3,1) - q(2,1)) <= tol
            q(2,2) = a(2);                  % 첫 구간은 가로로 나간다 / leave horizontally
        end
        %  포트에서 **곧장 위아래로** 떠나는 선은 짧은 가로 토막을 먼저 붙인다.
        %  가지가 달린 선이 그러면 Simulink 가 저장할 때 분기점을 포트 위에 적고,
        %  가지마다 첫 구간이 비스듬해진다 - A1 의 x 분배가 그랬다 (2026-10-13).
        %  A line that leaves its port straight up or down gets a short
        %  horizontal stub first. When such a line has branches, Simulink writes
        %  the branch point above the port on save and every branch starts with
        %  a slanted stretch, which is what A1's x fan-out did.
        if sh && size(q,1) >= 2 && abs(q(2,1) - a(1)) <= tol && abs(q(2,2) - a(2)) > tol
            bx = branch_x(h, a(1) + stub);  % 가지들이 갈라지는 x / where the branches leave
            k = 2;
            while k <= size(q,1) && abs(q(k,1) - a(1)) <= tol
                q(k,1) = bx;  k = k + 1;
            end
            q = [q(1,:); bx a(2); q(2:end,:)];
        end
    end

    %  1b) 빼면 곧아지는 가운데 점은 **뺀다**. 가지선의 첫 점 뒤에 어미선의 분기점이
    %      남아 있는 일이 흔하고(Simulink 가 그렇게 적어 둔다), 그 점 하나가 첫 구간을
    %      비스듬하게 만든다.
    %      Drop an interior point whose neighbours are already in line. A branch
    %      often carries the parent's branch point right after its first point,
    %      and that one point is what tilts the first stretch.
    q = prune(q, tol);

    %  2) 남은 대각선마다 모서리 하나 / one corner for each remaining diagonal
    q = elbow(q, numel(src) == 1 && src > 0, sh, numel(dst) == 1 && dst > 0, dh, tol);

    if size(q,1) ~= size(p,1) || any(abs(q(:) - p(:)) > tol)
        try
            set_param(h, 'Points', q);
            n = n + 1;
            if verbose
                fprintf('    바로잡음 / straightened  %s\n', line_name(h));
            end
        catch e
            if verbose
                fprintf('    못 고침 / left alone     %s  (%s)\n', line_name(h), e.message);
            end
        end
    end
end

if verbose, fprintf('    %d lines straightened in %s\n', n, mdl); end
end

% =========================================================================
function tf = port_is_horizontal(h)
%  포트가 좌우를 보면 선은 가로로 드나든다. 위아래를 보면 세로다.
%  A port facing left or right takes the line horizontally; one facing up or
%  down takes it vertically.
%  포트에는 Orientation 파라미터가 없다. 포트의 자리를 **블록의 네 변과 견주어**
%  어느 변에 달렸는지 본다 - 좌우 변이면 가로, 위아래 변이면 세로다.
%  A port has no Orientation parameter, so its position is compared with the
%  four edges of its block: on a side edge it is horizontal, on the top or
%  bottom edge it is vertical.
tf = true;
try
    p = get_param(h, 'Position');
    r = get_param(get_param(h, 'Parent'), 'Position');
    dx = min(abs(p(1) - r(1)), abs(p(1) - r(3)));
    dy = min(abs(p(2) - r(2)), abs(p(2) - r(4)));
    tf = dx <= dy;
catch
end
end

% =========================================================================
function x = branch_x(h, dflt)
%  가지선들이 어미선을 떠나는 x. Simulink 는 저장할 때 **가지마다 그 점**을 다시
%  적으므로, 어미선의 모서리를 거기에 맞춰야 가지의 첫 구간이 곧아진다.
%  Where the branches leave the trunk. Simulink rewrites that point into every
%  branch on save, so the trunk's corner has to sit on it.
x = dflt;
ch = get_param(h, 'LineChildren');
if isempty(ch), return; end
v = [];
for i = 1:numel(ch)
    p = get_param(ch(i), 'Points');
    if size(p,1) >= 2, v(end+1) = p(2,1); end                    %#ok<AGROW>
end
if ~isempty(v), x = round(median(v)); end
end

% =========================================================================
function q = prune(p, tol)
q = p;
i = 2;
while i < size(q,1)
    a = q(i-1,:);  b = q(i+1,:);
    if abs(a(1)-b(1)) <= tol || abs(a(2)-b(2)) <= tol
        q(i,:) = [];                        % 이웃끼리 이미 나란하다 / already in line
    else
        i = i + 1;
    end
end
end

% =========================================================================
function q = elbow(p, hasSrc, srcHoriz, hasDst, dstHoriz, tol)
%  대각선 구간 하나를 두 구간으로 쪼갠다. 방향은 앞 구간을 이어받되, 포트에
%  붙은 구간은 가로가 되도록 한다.
%  Split each diagonal stretch in two. The corner follows the previous
%  stretch, except next to a port, where the stretch must be horizontal.
q = p(1,:);
for i = 1:size(p,1)-1
    a = q(end,:);  b = p(i+1,:);
    if abs(a(1)-b(1)) <= tol || abs(a(2)-b(2)) <= tol
        q(end+1,:) = b;  continue;                               %#ok<AGROW>
    end
    first = (i == 1) && hasSrc;
    last  = (i == size(p,1)-1) && hasDst;
    if last && dstHoriz
        c = [a(1) b(2)];            % 세로로 올라간 뒤 가로로 들어간다 / vertical, then in
    elseif last
        c = [b(1) a(2)];            % 가로로 간 뒤 세로로 들어간다 / across, then in from below
    elseif first && srcHoriz
        c = [b(1) a(2)];            % 가로로 나간 뒤 세로로 / out, then vertical
    elseif first
        c = [a(1) b(2)];            % 세로로 나간 뒤 가로로 / down, then across
    elseif size(q,1) >= 2 && abs(q(end,2) - q(end-1,2)) <= tol
        c = [a(1) b(2)];            % 앞이 가로였으면 이번은 세로부터 / was horizontal
    else
        c = [b(1) a(2)];
    end
    q(end+1,:) = c;  q(end+1,:) = b;                             %#ok<AGROW>
end
q = round(q);
end

% =========================================================================
function s = line_name(h)
b = get_param(h, 'SrcBlockHandle');
if b > 0, s = get_param(b, 'Name'); else, s = '(branch)'; end
end
