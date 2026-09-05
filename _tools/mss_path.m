function p = mss_path()
%MSS_PATH  Find the vendored MSS toolbox and put it on the MATLAB path.
%
%   mss_path
%   p = mss_path()          returns the folder that was added
%
%   WHY THIS EXISTS
%
%   Every script in this course used to reach MSS by counting folders upwards:
%
%       proj = fileparts(fileparts(fileparts(here)));
%       addpath(genpath(fullfile(proj,'Tools','MSS')));
%
%   That works only while GradCourse sits in exactly one place. Move the
%   course folder - or copy it to another machine - and twelve scripts break
%   at once, each with a different unhelpful error. This function searches
%   instead of counting, so the course folder can live anywhere.
%
%   WHERE IT LOOKS, in order
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
%   The answer is cached, so the search runs once per MATLAB session.

persistent found

if ~isempty(found) && isfolder(found)
    addpath(genpath(found));
    p = found;
    return
end

%  1. Already usable? Then do not disturb whatever the user has set up.
w = which('otter');
if ~isempty(w) && contains(w, ['MSS' filesep])
    k = strfind(w, [filesep 'MSS' filesep]);
    found = w(1:k(end)+3);                     % ends at MSS, no trailing separator
    addpath(genpath(found));
    p = found;
    return
end

here = fileparts(mfilename('fullpath'));       % .../GradCourse/_tools
grad = fileparts(here);                        % .../GradCourse

%  2 and 3. Search GradCourse and then each ancestor in turn. At every
%  ancestor, look for Tools/MSS directly beneath it and then one and two
%  folders further down, which is what reaches a toolbox kept in a sibling
%  project. otter.m is the marker: a folder called MSS without it is not it.
node = grad;
for up = 0:6
    level = {node};
    for depth = 0:2
        for j = 1:numel(level)
            cand = fullfile(level{j}, 'Tools', 'MSS');
            if isfile(fullfile(cand, 'VESSELS', 'otter.m'))
                found = cand;
                addpath(genpath(found));
                p = found;
                return
            end
        end
        level = children(level);
        if isempty(level), break; end
    end
    parent = fileparts(node);
    if strcmp(parent, node), break; end        % reached the drive root
    node = parent;
end

error('mss_path:notFound', ...
     ['The MSS toolbox could not be found.\n' ...
      'Searched GradCourse and its ancestors for Tools/MSS/VESSELS/otter.m,\n' ...
      'starting from\n    %s\n' ...
      'Either put a copy at GradCourse/Tools/MSS, or add MSS to the path by\n' ...
      'hand once with addpath(genpath(...)) and run this again.'], grad);
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
