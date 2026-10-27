function [p, layout] = mss_path()
%MSS_PATH  MSS 툴박스를 찾아 MATLAB 경로에 얹는다.
%          Find the vendored MSS toolbox and put it on the MATLAB path.
%
%   mss_path
%   p = mss_path()              더해진 폴더를 돌려준다 / returns the folder added
%   [p, layout] = mss_path()    'VESSELS' 또는 'CRAFT' / which release layout
%
%   왜 이 함수가 있는가 / why this exists
%       예전에는 이 강의의 모든 스크립트가 폴더를 위로 세어 올라가 MSS 에
%       닿았다.
%       Every script in this course used to reach MSS by counting folders
%       upwards:
%
%       proj = fileparts(fileparts(fileparts(here)));
%       addpath(genpath(fullfile(proj,'Tools','MSS')));
%
%   그 방법은 강의 폴더가 정확히 한 자리에 있을 때만 통한다. 폴더를 옮기거나
%   다른 컴퓨터로 복사하면 열두 개의 스크립트가 한꺼번에 깨지고, 저마다 다른
%   쓸모없는 오류 메시지를 낸다. 이 함수는 세지 않고 찾는다. 그래서 강의 폴더가
%   어디에 있어도 된다.
%
%   That works only while the course folder sits in exactly one place. Move it,
%   or copy it to another machine, and twelve scripts break at once, each with
%   a different unhelpful error. This function searches instead of counting, so
%   the course folder can live anywhere.
%
%   두 가지 구조 / two release layouts
%
%       MSS 는 2024 년 무렵 폴더 구조를 바꾸었다. otter.m 의 자리가 다르다.
%       MSS reorganised its folders around 2024, and otter.m moved.
%
%         'VESSELS'   <MSS>/VESSELS/otter.m                 (older releases)
%         'CRAFT'     <MSS>/CRAFT/USV/models/otter.m        (current master)
%
%       둘 다 찾는다. 다만 **둘이 함께 있으면 VESSELS 쪽을 고른다** — 강의
%       자료에 적힌 수치를 그 릴리스로 재었기 때문이다. 두 릴리스의 Otter 는
%       같은 배가 아니다. 같은 입력(n = 60 rpm, mp = 25 kg)으로 재면
%
%         terminal surge u      1.0286 m/s  ->  1.0286 m/s   (같다)
%         steady yaw rate r     0.1017 rad/s -> 0.1276 rad/s (25.5 % 높다)
%
%       Both are found, but when both are present the VESSELS layout wins,
%       because the figures printed in the course notes were measured with
%       that release. The two Otters are not the same vessel: the surge
%       numbers agree, while the steady yaw rate under differential thrust is
%       25.5 % higher in the current master. A fall-back to the CRAFT layout
%       therefore raises a warning once per session, so that a reader who
%       cannot reproduce the turning figures knows why.
%
%   찾는 순서 / where it looks, in order
%
%     1. the path already in force            (otter.m resolvable -> nothing to do)
%     2. GradCourse/Tools/MSS                 (a self-contained copy, if one is made)
%     3. every ancestor of GradCourse, at three depths each:
%           <ancestor>/Tools/MSS
%           <ancestor>/*/Tools/MSS
%           <ancestor>/*/*/Tools/MSS
%
%   Depth 3 is what reaches a sibling project. With the course at
%   .../센서신호처리및융합/00_GradCourse_2026 and the toolbox at
%   .../센서신호처리및융합/10_연구_USV_MILS/Proj_SHI_USV_MILS/Tools/MSS,
%   the third pattern finds it.
%
%   The search walks the tree once. A VESSELS hit is taken immediately; a
%   CRAFT hit is remembered and used only if the walk ends without one.
%
%   The answer is cached, so the search runs once per MATLAB session.

persistent found foundLayout

if ~isempty(found) && isfolder(found)
    addpath(genpath(found));
    p = found;
    layout = foundLayout;
    return
end

%  1. Already usable? Then do not disturb whatever the user has set up. The
%  root is recovered by stripping the layout's own suffix, not by looking for
%  a folder called MSS -- a release unzipped as MSS-master keeps its name.
w = which('otter');
if ~isempty(w)
    [root, lay] = root_of(w);
    if ~isempty(root)
        found = root;
        foundLayout = lay;
        addpath(genpath(found));
        warn_if_craft(lay);
        p = found;
        layout = lay;
        return
    end
end

here = fileparts(mfilename('fullpath'));       % .../GradCourse/_tools
grad = fileparts(here);                        % .../GradCourse

%  2 and 3. Search GradCourse and then each ancestor in turn. At every
%  ancestor, look for Tools/MSS directly beneath it and then one and two
%  folders further down, which is what reaches a toolbox kept in a sibling
%  project. otter.m is the marker: a folder called MSS without it is not it.
craft = '';                                    % first CRAFT-layout hit, if any
node = grad;
for up = 0:6
    level = {node};
    for depth = 0:2
        for j = 1:numel(level)
            cand = fullfile(level{j}, 'Tools', 'MSS');
            lay = layout_of(cand);
            if strcmp(lay, 'VESSELS')
                found = cand;                  % the release the notes were measured with
                foundLayout = lay;
                addpath(genpath(found));
                p = found;
                layout = lay;
                return
            elseif strcmp(lay, 'CRAFT') && isempty(craft)
                craft = cand;                  % keep looking for a VESSELS copy first
            end
        end
        level = children(level);
        if isempty(level), break; end
    end
    parent = fileparts(node);
    if strcmp(parent, node), break; end        % reached the drive root
    node = parent;
end

if ~isempty(craft)
    found = craft;
    foundLayout = 'CRAFT';
    addpath(genpath(found));
    warn_if_craft('CRAFT');
    p = found;
    layout = 'CRAFT';
    return
end

error('mss_path:notFound', ...
     ['The MSS toolbox could not be found.\n' ...
      'Searched GradCourse and its ancestors for Tools/MSS holding either\n' ...
      '    VESSELS/otter.m            (older releases)\n' ...
      '    CRAFT/USV/models/otter.m   (current master)\n' ...
      'starting from\n    %s\n' ...
      'Either put a copy at GradCourse/Tools/MSS, or add MSS to the path by\n' ...
      'hand once with addpath(genpath(...)) and run this again.'], grad);
end

% -------------------------------------------------------------------------
function lay = layout_of(root)
%LAYOUT_OF  Which release layout, if any, the folder ROOT holds.
if isfile(fullfile(root, 'VESSELS', 'otter.m'))
    lay = 'VESSELS';
elseif isfile(fullfile(root, 'CRAFT', 'USV', 'models', 'otter.m'))
    lay = 'CRAFT';
else
    lay = '';
end
end

% -------------------------------------------------------------------------
function [root, lay] = root_of(otterFile)
%ROOT_OF  The toolbox root that OTTERFILE belongs to, by stripping the
%         layout's own folders. Returns '' if the file is not in either
%         layout -- a stray otter.m somewhere else is not a toolbox.
root = '';
lay  = '';
d = fileparts(otterFile);                      % .../VESSELS or .../models
[up1, n1] = fileparts(d);
if strcmpi(n1, 'VESSELS')
    root = up1;
    lay  = 'VESSELS';
    return
end
[up2, n2] = fileparts(up1);
[up3, n3] = fileparts(up2);
if strcmpi(n1, 'models') && strcmpi(n2, 'USV') && strcmpi(n3, 'CRAFT')
    root = up3;
    lay  = 'CRAFT';
end
end

% -------------------------------------------------------------------------
function warn_if_craft(lay)
%WARN_IF_CRAFT  Say once that the turning figures will not reproduce.
if ~strcmp(lay, 'CRAFT'), return; end
warning('mss_path:newLayout', ...
    ['Using an MSS release with the CRAFT/USV/models layout. The course\n' ...
     'figures were measured with the older VESSELS release. Surge agrees,\n' ...
     'but the steady yaw rate under differential thrust is about 25 %%\n' ...
     'higher here, so the turning and heading numbers in the notes will not\n' ...
     'reproduce exactly. Put an older release at Tools/MSS to match them.']);
end

% -------------------------------------------------------------------------
function out = children(folders)
%CHILDREN  Every immediate subfolder of every folder given, '.' and '..' aside.
out = {};
for j = 1:numel(folders)
    d = dir(folders{j});
    for i = 1:numel(d)
        if d(i).isdir && ~any(strcmp(d(i).name, {'.','..'}))
            out{end+1} = fullfile(folders{j}, d(i).name);  %#ok<AGROW>
        end
    end
end
end
