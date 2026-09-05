function tidy_layout(m, varargin)
% TIDY_LAYOUT  Simulink 모델을 읽기 좋게 정리한다. 선은 전부 직선이 된다.
%
%   tidy_layout('W07_0_offline')
%   tidy_layout('W07_0_offline','Recurse',false)     % 서브시스템은 두고
%
%   하는 일
%     1) 포트가 많은 블록을 세로로 늘려 포트 간격을 확보한다
%     2) 앞뒤로 이어지는 블록은 포트 간격까지 맞춰 나란히 놓는다
%     3) 겹친 블록을 떼어놓는다
%     4) 먹임 블록(Constant, From, Clock, Unit Delay)을 받는 쪽 포트 높이에 맞춘다
%     5) 그래도 높이가 안 맞는 연결은 **Goto/From 태그로 바꾼다**
%        -> 남는 선은 전부 짧은 수평 직선이 된다
%     6) 기능별로 배경색을 칠하고, 겹치기만 하는 블록 이름은 감춘다
%
%   색 규칙
%     유도(파랑) · 미션(보라) · 제어(주황) · 추진기(노랑)
%     운동모델(초록) · ROS(연보라) · 로깅(회색) · 설정(흰색)
%
%   되돌리려면 build_wXX_models 를 다시 실행하면 된다.

p = inputParser;
addParameter(p, 'Recurse',    true);
addParameter(p, 'MinPortGap', 46);
addParameter(p, 'Verbose',    false);
parse(p, varargin{:});
opt = p.Results;

wasOpen = bdIsLoaded(m);
if ~wasOpen, load_system(m); end

systems = {m};
if opt.Recurse
    ss = find_system(m, 'SearchDepth', 8, 'BlockType','SubSystem');
    if opt.Verbose, fprintf('  하위 서브시스템 후보 %d개\n', numel(ss)); end
    for k = 1:numel(ss)
        % 마스크 블록(PID 등)과 Stateflow · MATLAB Function 블록의 내부는 손대지 않는다.
        % MATLAB Function 블록도 속은 Stateflow 라서 SFBlockType 으로 걸러야 한다.
        % SFBlockType 은 보통 서브시스템에서 'NONE' 을 돌려준다.
        % MATLAB Function 이면 'MATLAB Function', 상태도면 'Chart' 다.
        mt = ''; sft = 'NONE';
        try, mt  = get_param(ss{k}, 'MaskType');    catch, end
        try, sft = get_param(ss{k}, 'SFBlockType'); catch, end
        if ~isempty(mt) || ~strcmp(sft, 'NONE'), continue; end
        systems{end+1} = ss{k}; %#ok<AGROW>
    end
end

% 최상위는 직접 배치한다. 신호 흐름이 한 방향이라 모든 선을 직선으로 만들 수 있다.
if opt.Verbose, disp(['  정리(직선): ' systems{1}]); end
tidyOne(systems{1}, opt);

% 서브시스템은 안쪽 연결이 촘촘해서 모두 직선으로 만들면 오히려 읽기 어렵다.
% Simulink 자체 배치 엔진을 쓰면 겹침 없이 직각으로 깔끔하게 정리된다.
for k = 2:numel(systems)
    if opt.Verbose, disp(['  정리(자동배치): ' systems{k}]); end
    try, Simulink.BlockDiagram.arrangeSystem(systems{k}); catch, end
    colorAll(systems{k});
end

save_system(m);
if ~wasOpen, close_system(m, 0); end
end

% =====================================================================
function tidyOne(sys, opt)

FEED = {'Constant','From','DigitalClock','UnitDelay','Inport'};   % 내보내기만 하는 것
SINK = {'Goto','Terminator','Display','Scope','ToWorkspace','Outport'};

conn = grabConnections(sys);
if isempty(conn), colorAll(sys); return; end
delAllLines(sys);

blks = localBlocks(sys);

% ---- 1. 포트 간격 확보 ----------------------------------------------
for i = 1:numel(blks)
    b = blks{i};
    if ismember(get_param(b,'BlockType'), [FEED SINK]), continue; end
    n = maxPorts(b);
    if n < 2, continue; end
    % 포트 간격은 블록 종류마다 계산식이 다르다. 재보면서 늘린다.
    for tries = 1:3
        gg = [portGapAbs(b,'in') portGapAbs(b,'out')];  gg = gg(gg > 0);
        if isempty(gg), break; end
        g = min(gg);
        if g <= 0 || g >= opt.MinPortGap, break; end
        pos = get_param(b,'Position');
        h   = round((pos(4)-pos(2)) * opt.MinPortGap / g);
        set_param(b,'Position',[pos(1) pos(2) pos(3) pos(2)+h]);
    end
end

% ---- 2. 이어지는 블록끼리 포트 간격 맞추기 ---------------------------
%      dst 의 입력 1..k 가 src 의 출력 1..k 에서 차례로 온다면
%      dst 높이를 조절해 간격을 같게 만든다. 그러면 k 개가 모두 직선이 된다.
pairs = chainPairs(sys, conn, FEED);
for i = 1:size(pairs,1)
    s = pairs{i,1}; d = pairs{i,2}; k = pairs{i,3};
    if k < 2, continue; end
    gs = portGap(sys, s, 'out');
    if gs <= 0, continue; end
    % 높이를 늘리면 포트 간격도 같은 비율로 늘어난다. 재보면서 맞춘다.
    for tries = 1:4
        gd = portGap(sys, d, 'in');
        if gd <= 0 || abs(gd - gs) <= 1, break; end
        pos = get_param([sys '/' d],'Position');
        h   = round((pos(4)-pos(2)) * gs / gd);
        set_param([sys '/' d],'Position',[pos(1) pos(2) pos(3) pos(2)+h]);
    end
end

% ---- 3~4. 겹침 정리와 본선 정렬을 번갈아 ------------------------------
%      마지막은 반드시 alignChain 으로 끝낸다.
%      뒤에 세로 이동을 하면 애써 맞춘 포트 높이가 다시 어긋난다.
for it = 1:6
    deOverlapVertical(sys, blks, FEED, SINK);
    alignChain(sys, conn, FEED);
end

% ---- 5. 먹임 블록을 받는 쪽 포트 높이에 맞춘다 -----------------------
for pass = 1:2
    for i = 1:numel(conn)
        c  = conn(i);
        sb = [sys '/' c.srcBlk];
        if ~ismember(get_param(sb,'BlockType'), FEED), continue; end
        if sum(strcmp({conn.srcBlk}, c.srcBlk)) > 1, continue; end   % 갈라지면 못 맞춤
        moveOutportTo(sys, c.srcBlk, 1, portY(sys, c.dstBlk,'in', c.dstPort));
    end
    % 받기만 하는 블록(Goto 등)도 보내는 쪽 높이에 맞춘다
    for i = 1:numel(conn)
        c  = conn(i);
        db = [sys '/' c.dstBlk];
        if ~ismember(get_param(db,'BlockType'), SINK), continue; end
        moveInportTo(sys, c.dstBlk, 1, portY(sys, c.srcBlk,'out', c.srcPort));
        pushRightOf(sys, c.dstBlk, c.srcBlk);
    end
end

% ---- 6. 겹침 해소 — 가로로만 옮긴다 -----------------------------------
%      가로 이동은 포트 높이를 바꾸지 않으므로 직선이 깨지지 않는다.
deOverlapHorizontal(sys, localBlocks(sys), FEED, SINK);

% ---- 6-2. 먹임 블록을 받는 블록 **바로 옆**으로 데려온다 ----------------
%      멀리 있으면 선이 중간의 큰 블록들을 가로질러 지나간다.
%      자리가 막혀 있으면 받는 블록부터 오른쪽으로 밀어 공간을 만든다.
placeFeeders(sys, conn, FEED);
deOverlapHorizontal(sys, localBlocks(sys), FEED, SINK);

% ---- 6-3. 설명글(주석)을 블록 위쪽 빈 자리로 옮긴다 --------------------
liftAnnotations(sys);

% ---- 7. 색과 이름 ------------------------------------------------------
colorAll(sys);

% ---- 8. 선 다시 그리기 -------------------------------------------------
%      포트 높이가 맞으면 곧은 선, 아니면 직각으로 꺾어 그린다.
%      대각선은 만들지 않는다.
for i = 1:numel(conn)
    c  = conn(i);
    sp = sprintf('%s/%d', c.srcBlk, c.srcPort);
    dp = sprintf('%s/%d', c.dstBlk, c.dstPort);
    sy = portY(sys, c.srcBlk, 'out', c.srcPort);
    dy = portY(sys, c.dstBlk, 'in',  c.dstPort);
    sx = portX(sys, c.srcBlk, 'out', c.srcPort);
    dx = portX(sys, c.dstBlk, 'in',  c.dstPort);
    if abs(sy - dy) <= 1 && sx < dx
        try, add_line(sys, sp, dp);
        catch, try, add_line(sys, sp, dp, 'autorouting','on'); catch, end
        end
    else
        try, add_line(sys, sp, dp, 'autorouting','on'); catch, end
    end
end
end

% =====================================================================
% 남은 꺾인 연결을 Goto/From 으로 대체
% =====================================================================
function conn = convertToTags(sys, conn, FEED, SINK, opt) %#ok<INUSD>
keep = true(1, numel(conn));
newC = conn([]);
made = containers.Map('KeyType','char','ValueType','char');

for i = 1:numel(conn)
    c  = conn(i);
    sy = portY(sys, c.srcBlk, 'out', c.srcPort);
    dy = portY(sys, c.dstBlk, 'in',  c.dstPort);
    if abs(sy - dy) <= 1, continue; end                 % 이미 직선

    key = sprintf('%s_%d', c.srcBlk, c.srcPort);
    tag = matlab.lang.makeValidName(key);
    if numel(tag) > 24, tag = tag(1:24); end

    % 이 출력 포트에 Goto 가 아직 없으면 만든다
    if ~isKey(made, key)
        gname = uniqueName(sys, ['Go_' tag]);
        sp    = get_param([sys '/' c.srcBlk],'Position');
        add_block('simulink/Signal Routing/Goto', [sys '/' gname], ...
                  'Position', [sp(3)+40 sy-12 sp(3)+120 sy+13], ...
                  'GotoTag', tag, 'ShowName','off');
        newC(end+1) = mkConn(c.srcBlk, c.srcPort, gname, 1); %#ok<AGROW>
        made(key) = gname;
    end

    % 받는 쪽 바로 앞에 From 을 놓는다
    fname = uniqueName(sys, ['Fr_' tag]);
    dp    = get_param([sys '/' c.dstBlk],'Position');
    add_block('simulink/Signal Routing/From', [sys '/' fname], ...
              'Position', [dp(1)-120 dy-12 dp(1)-40 dy+13], ...
              'GotoTag', tag, 'ShowName','off');
    newC(end+1) = mkConn(fname, 1, c.dstBlk, c.dstPort); %#ok<AGROW>
    keep(i) = false;
end

conn = [conn(keep) newC];
% 새로 놓은 태그가 다른 블록과 겹치면 가로로 떼어놓는다
deOverlapHorizontal(sys, localBlocks(sys), FEED, SINK);
end

function c = mkConn(sb, sp, db, dp)
c = struct('srcBlk',sb,'srcPort',sp,'dstBlk',db,'dstPort',dp,'srcIdx',0);
end

function n = uniqueName(sys, base)
n = base; k = 1;
while ~isempty(find_system(sys,'SearchDepth',1,'Name',n))
    k = k + 1; n = sprintf('%s_%d', base, k);
end
end

% =====================================================================
% 배치 도우미
% =====================================================================
function blks = localBlocks(sys)
blks = find_system(sys, 'SearchDepth',1, 'Type','Block');
blks = setdiff(blks, {sys});
end

function n = maxPorts(b)
ph = get_param(b,'PortHandles');
n  = max([numel(ph.Inport), numel(ph.Outport)]);
end

function g = portGap(sys, blk, dir)
ph = get_param([sys '/' blk],'PortHandles');
if strcmp(dir,'out'), h = ph.Outport; else, h = ph.Inport; end
if numel(h) < 2, g = 0; return; end
a = get_param(h(1),'Position');  b = get_param(h(2),'Position');
g = b(2) - a(2);
end

function g = portGapAbs(b, dir)
ph = get_param(b,'PortHandles');
if strcmp(dir,'out'), h = ph.Outport; else, h = ph.Inport; end
if numel(h) < 2, g = 0; return; end
a = get_param(h(1),'Position');  c = get_param(h(2),'Position');
g = c(2) - a(2);
end

function pairs = chainPairs(sys, conn, FEED)
% dst 의 입력 1..k 가 src 의 출력 1..k 에서 차례로 오는 쌍을 찾는다
pairs = {};
dsts = unique({conn.dstBlk});
for i = 1:numel(dsts)
    d   = dsts{i};
    sel = conn(strcmp({conn.dstBlk}, d));
    src = unique({sel.srcBlk});
    src = src(~cellfun(@(s) ismember(get_param([sys '/' s],'BlockType'), FEED), src));
    if numel(src) ~= 1, continue; end
    s  = src{1};
    ss = sel(strcmp({sel.srcBlk}, s));
    k  = 0;
    for j = 1:numel(ss)
        if any([ss.srcPort] == j & [ss.dstPort] == j), k = j; else, break; end
    end
    if k >= 2, pairs(end+1,:) = {s, d, k}; end %#ok<AGROW>
end
end

function alignChain(sys, conn, FEED)
% 먹임 블록을 뺀 소스가 하나뿐인 블록을 그 소스에 맞춘다
dsts = unique({conn.dstBlk});
for i = 1:numel(dsts)
    d = dsts{i};
    if ismember(get_param([sys '/' d],'BlockType'), FEED), continue; end
    sel = conn(strcmp({conn.dstBlk}, d));
    src = unique({sel.srcBlk});
    src = src(~cellfun(@(s) ismember(get_param([sys '/' s],'BlockType'), FEED), src));
    if numel(src) ~= 1, continue; end
    ss = sel(strcmp({sel.srcBlk}, src{1}));
    [~, o] = min([ss.dstPort]);
    dy = portY(sys, ss(o).srcBlk,'out',ss(o).srcPort) - portY(sys, d,'in',ss(o).dstPort);
    if dy ~= 0
        pos = get_param([sys '/' d],'Position');
        set_param([sys '/' d],'Position', pos + [0 dy 0 dy]);
    end
end
end

function deOverlapVertical(sys, blks, FEED, SINK)
big = {};
for i = 1:numel(blks)
    if ismember(get_param(blks{i},'BlockType'), [FEED SINK]), continue; end
    big{end+1} = blks{i}; %#ok<AGROW>
end
for iter = 1:12
    moved = false;
    for i = 1:numel(big)
        for j = i+1:numel(big)
            pa = get_param(big{i},'Position');
            pb = get_param(big{j},'Position');
            if ~boxesOverlap(pa,pb), continue; end
            if pa(2) <= pb(2), lo = big{j}; hi = pa; else, lo = big{i}; hi = pb; end
            p  = get_param(lo,'Position');
            dy = hi(4) + 50 - p(2);
            set_param(lo,'Position', p + [0 dy 0 dy]);
            moved = true;
        end
    end
    if ~moved, break; end
end
end

function deOverlapHorizontal(sys, blks, FEED, SINK) %#ok<INUSL>
% 겹친 블록을 가로로만 떼어놓는다.
% 먼저 작은 태그·상수를 옮기고, 그래도 남으면 큰 블록도 옮긴다.
for iter = 1:14
    moved = false;
    for i = 1:numel(blks)
        for j = i+1:numel(blks)
            if ~ishandle_ok(blks{i}) || ~ishandle_ok(blks{j}), continue; end
            pa = get_param(blks{i},'Position');
            pb = get_param(blks{j},'Position');
            if ~boxesOverlap(pa,pb), continue; end
            [t, other] = pickMovable(blks{i}, pa, blks{j}, pb, FEED, SINK);
            if isempty(t)
                % 둘 다 큰 블록이면 오른쪽 것을 더 오른쪽으로 민다
                if pa(1) <= pb(1), t = blks{j}; other = pa; else, t = blks{i}; other = pb; end
                p = get_param(t,'Position'); w = p(3)-p(1);
                x1 = other(3) + 60;  set_param(t,'Position',[x1 p(2) x1+w p(4)]);
                moved = true; continue;
            end
            p = get_param(t,'Position'); w = p(3)-p(1);
            if ismember(get_param(t,'BlockType'), FEED)
                x2 = other(1) - 30;  set_param(t,'Position',[x2-w p(2) x2 p(4)]);
            else
                x1 = other(3) + 30;  set_param(t,'Position',[x1 p(2) x1+w p(4)]);
            end
            moved = true;
        end
    end
    if ~moved, break; end
end
end

function tf = ishandle_ok(b)
tf = true;
try, get_param(b,'Position'); catch, tf = false; end
end

function tf = boxesOverlap(a,b)
tf = (a(1) < b(3)-2) && (b(1) < a(3)-2) && (a(2) < b(4)-2) && (b(2) < a(4)-2);
end

function [t, other] = pickMovable(ba, pa, bb, pb, FEED, SINK)
aL = ismember(get_param(ba,'BlockType'), FEED);
bL = ismember(get_param(bb,'BlockType'), FEED);
aR = ismember(get_param(ba,'BlockType'), SINK);
bR = ismember(get_param(bb,'BlockType'), SINK);
if     aL && ~bL, pick = 1;
elseif bL && ~aL, pick = 2;
elseif aL && bL,  if pa(1) <= pb(1), pick = 1; else, pick = 2; end
elseif aR && ~bR, pick = 1;
elseif bR && ~aR, pick = 2;
elseif aR && bR,  if pa(1) >= pb(1), pick = 1; else, pick = 2; end
else,  t = ''; other = []; return;
end
if pick == 1, t = ba; other = pb; else, t = bb; other = pa; end
end

function enforceFlow(sys, conn, FEED)
% 받는 포트가 보내는 포트보다 왼쪽이면 선이 뒤로 돈다. 받는 쪽을 오른쪽으로 민다.
for it = 1:8
    moved = false;
    for i = 1:numel(conn)
        c = conn(i);
        if ismember(get_param([sys '/' c.dstBlk],'BlockType'), FEED), continue; end  % 되먹임은 예외
        sx = portX(sys, c.srcBlk, 'out', c.srcPort);
        dx = portX(sys, c.dstBlk, 'in',  c.dstPort);
        if sx <= dx - 15, continue; end
        p  = get_param([sys '/' c.dstBlk],'Position');
        s  = sx - dx + 60;
        set_param([sys '/' c.dstBlk],'Position', p + [s 0 s 0]);
        moved = true;
    end
    if ~moved, break; end
end
end

function x = portX(sys, blk, dir, idx)
ph = get_param([sys '/' blk],'PortHandles');
if strcmp(dir,'in'), h = ph.Inport(idx); else, h = ph.Outport(idx); end
q = get_param(h,'Position');
x = q(1);
end

function y = portY(sys, blk, dir, idx)
ph = get_param([sys '/' blk],'PortHandles');
if strcmp(dir,'in'), h = ph.Inport(idx); else, h = ph.Outport(idx); end
q = get_param(h,'Position');
y = q(2);
end

function moveOutportTo(sys, blk, idx, targetY)
dy = targetY - portY(sys, blk, 'out', idx);
if dy == 0, return; end
p = get_param([sys '/' blk],'Position');
set_param([sys '/' blk],'Position', p + [0 dy 0 dy]);
end

function moveInportTo(sys, blk, idx, targetY)
dy = targetY - portY(sys, blk, 'in', idx);
if dy == 0, return; end
p = get_param([sys '/' blk],'Position');
set_param([sys '/' blk],'Position', p + [0 dy 0 dy]);
end

function liftAnnotations(sys)
% 주석 글상자가 블록 위에 겹쳐 있으면 읽을 수 없다. 도면 위쪽 빈 자리로 올린다.
anns = find_system(sys,'SearchDepth',1,'FindAll','on','Type','annotation');
if isempty(anns), return; end
blks = localBlocks(sys);
if isempty(blks), return; end
P = cell2mat(cellfun(@(b) get_param(b,'Position'), blks, 'UniformOutput',false));
x0 = min(P(:,1));  y0 = min(P(:,2));
yy = y0 - 40;
for i = numel(anns):-1:1
    p = get_param(anns(i),'Position');
    if numel(p) >= 4, w = p(3)-p(1); h = max(p(4)-p(2), 20); else, w = 300; h = 40; end
    yy = yy - h - 20;
    if numel(p) >= 4
        set_param(anns(i),'Position',[x0 yy x0+w yy+h]);
    else
        set_param(anns(i),'Position',[x0 yy]);
    end
end
end

function placeFeeders(sys, conn, FEED)
% 목적지가 하나뿐인 먹임 블록을 받는 블록 왼쪽 60px 자리에 붙인다.
for i = 1:numel(conn)
    c  = conn(i);
    sb = [sys '/' c.srcBlk];
    bt = get_param(sb,'BlockType');
    if ~ismember(bt, FEED) || strcmp(bt,'Inport'), continue; end
    if sum(strcmp({conn.srcBlk}, c.srcBlk)) > 1, continue; end   % 갈라지면 못 맞춤
    db = [sys '/' c.dstBlk];
    a  = get_param(sb,'Position');   w = a(3) - a(1);
    b  = get_param(db,'Position');
    gap = b(1) - a(3);
    if gap >= 20 && gap <= 200, continue; end                    % 이미 가깝다
    tgt = [b(1)-60-w a(2) b(1)-60 a(4)];
    for guard = 1:6
        blk = findBlocker(sys, sb, tgt);
        if isempty(blk), break; end
        pb   = get_param(blk,'Position');
        need = pb(3) + 40 - tgt(1);
        if need <= 0, break; end
        shiftRightFrom(sys, b(1)-1, need);
        b   = get_param(db,'Position');
        tgt = [b(1)-60-w a(2) b(1)-60 a(4)];
    end
    set_param(sb,'Position', tgt);
end
end

function blk = findBlocker(sys, self, box)
blk = '';
blks = localBlocks(sys);
for i = 1:numel(blks)
    if strcmp(blks{i}, self), continue; end
    if boxesOverlap(get_param(blks{i},'Position'), box), blk = blks{i}; return; end
end
end

function shiftRightFrom(sys, xThresh, dx)
% xThresh 오른쪽에 있는 블록을 전부 dx 만큼 민다. 세로 위치는 건드리지 않으므로
% 이미 맞춰 놓은 직선이 깨지지 않는다.
blks = localBlocks(sys);
for i = 1:numel(blks)
    p = get_param(blks{i},'Position');
    if p(1) > xThresh
        set_param(blks{i},'Position', p + [dx 0 dx 0]);
    end
end
end

function pushLeftOf(sys, blk, dstBlk) %#ok<DEFNU>
% 먹임 블록은 **받는 블록 바로 왼쪽**에 붙인다.
% 멀리 떨어져 있으면 선이 중간의 큰 블록들을 가로질러 지나간다.
if strcmp(get_param([sys '/' blk],'BlockType'), 'Inport'), return; end
a = get_param([sys '/' blk],'Position');
b = get_param([sys '/' dstBlk],'Position');
w = a(3) - a(1);
gap = b(1) - a(3);
if gap >= 20 && gap <= 200, return; end     % 이미 적당히 가깝다
x2 = b(1) - 60;
set_param([sys '/' blk],'Position',[x2-w a(2) x2 a(4)]);
end

function pushRightOf(sys, blk, srcBlk)
% 받기만 하는 블록(Goto, To Workspace 등)은 보내는 블록 바로 오른쪽에 붙인다.
if strcmp(get_param([sys '/' blk],'BlockType'), 'Outport'), return; end
a = get_param([sys '/' blk],'Position');
b = get_param([sys '/' srcBlk],'Position');
w = a(3) - a(1);
gap = a(1) - b(3);
if gap >= 20 && gap <= 200, return; end
x1 = b(3) + 40;
set_param([sys '/' blk],'Position',[x1 a(2) x1+w a(4)]);
end

% =====================================================================
% 연결 수집
% =====================================================================
function conn = grabConnections(sys)
conn = struct('srcBlk',{},'srcPort',{},'dstBlk',{},'dstPort',{},'srcIdx',{});
lines = find_system(sys,'SearchDepth',1,'FindAll','on','Type','line');
for i = 1:numel(lines)
    sp = get_param(lines(i),'SrcPortHandle');
    if sp < 0, continue; end
    dps = get_param(lines(i),'DstPortHandle');
    dps = dps(dps > 0);
    for j = 1:numel(dps)
        c.srcBlk  = shortName(get_param(get_param(sp,'Parent'),'Name'));
        c.srcPort = pnum(get_param(sp,'PortNumber'));
        c.dstBlk  = shortName(get_param(get_param(dps(j),'Parent'),'Name'));
        c.dstPort = pnum(get_param(dps(j),'PortNumber'));
        c.srcIdx  = i;
        conn(end+1) = c; %#ok<AGROW>
    end
end
if ~isempty(conn)
    key = arrayfun(@(c) sprintf('%s|%d', c.dstBlk, c.dstPort), conn, 'UniformOutput',false);
    [~, ia] = unique(key,'stable');
    conn = conn(ia);
end
end

function n = shortName(n), n = strrep(n, newline, ' '); end

function v = pnum(x)
if ischar(x) || isstring(x), v = str2double(x); else, v = double(x); end
end

function delAllLines(sys)
lines = find_system(sys,'SearchDepth',1,'FindAll','on','Type','line');
for i = numel(lines):-1:1
    try, delete_line(lines(i)); catch, end
end
end

% =====================================================================
% 색과 이름
% =====================================================================
function colorAll(sys)
blks = localBlocks(sys);
hide = {'Constant','From','Goto','UnitDelay','DigitalClock','Terminator'};
for i = 1:numel(blks)
    col = colorFor(blks{i});
    if ~isempty(col)
        try, set_param(blks{i},'BackgroundColor',col); catch, end
    end
    if ismember(get_param(blks{i},'BlockType'), hide)
        try, set_param(blks{i},'ShowName','off'); catch, end
    end
end
end

function col = colorFor(blk)
n  = lower(get_param(blk,'Name'));
bt = get_param(blk,'BlockType');

GUID  = '[0.80, 0.89, 0.98]';
ENV   = '[0.98, 0.85, 0.85]';
MISS  = '[0.90, 0.83, 0.96]';
CTRL  = '[1.00, 0.88, 0.72]';
THR   = '[1.00, 0.95, 0.70]';
PLANT = '[0.81, 0.93, 0.81]';
ROS   = '[0.87, 0.87, 0.96]';
LOG   = '[0.93, 0.93, 0.93]';
SET   = 'white';

col = '';
if     contains(n,{'guidance','loitervf','wpmanager','schedule','idxdly','idxdelay','dpref','rdly'})
    col = GUID;
elseif contains(n,{'env','wind','wave'}) && ~contains(n,{'wavefilter'})
    col = ENV;
elseif contains(n,{'wavefilter','filt','fdly'})
    col = ROS;
elseif contains(n,{'missionfsm','modeswitch','turncount','modedly','thdly','accdly','armdly'})
    col = MISS;
elseif contains(n,{'dpctrl','idly'})
    col = CTRL;
elseif contains(n,{'innerloop','pid','pi_u','kp_','kd_','sumn','satn','headingerr', ...
                   'courseerr','surgeerr','alloc','gate','dedt','dsel','urefgate'})
    col = CTRL;
elseif contains(n,{'thruster','f2n','n2f','motorlag'})
    col = THR;
elseif contains(n,{'motionmodel','eom','plant','integ','states','nav'})
    if contains(n,{'odomsub','sel','isnew'}), col = ROS; else, col = PLANT; end
elseif contains(n,{'odomsub','isnew','blank','asg','pub'}) || strcmp(n,'sel')
    col = ROS;
elseif contains(n,{'log_','scope','display','animate','animend','clk'})
    col = LOG;
elseif strcmp(bt,'Constant')
    col = SET;
elseif any(strcmp(bt,{'Goto','From'}))
    col = LOG;
elseif any(strcmp(bt,{'Inport','Outport'}))
    col = SET;
elseif strcmp(bt,'SubSystem')
    col = CTRL;
end
end
