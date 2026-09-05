function n = check_overlaps(mdl, verbose)
%CHECK_OVERLAPS  Report signal lines drawn on top of each other.
%
%   n = check_overlaps('W03_heading_control')
%   check_overlaps('W03_heading_control', true)      list every finding
%
%   Two lines that share a stretch of the same vertical or horizontal run are
%   indistinguishable in the printed diagram: the reader cannot tell which
%   source reaches which destination, and a diagram that cannot be read is not
%   documentation. This walks the model and every subsystem in it and counts
%   the collinear overlaps.
%
%   BRANCHES OF ONE SIGNAL ARE NOT A FINDING. A fan-out is drawn as a shared
%   trunk on purpose, and that is correct, so segments whose lines come from
%   the same source port are skipped.
%
%   Returns the number of overlapping pairs. Zero is the pass mark.

if nargin < 2, verbose = false; end

opened = false;
if ~bdIsLoaded(mdl), load_system(mdl); opened = true; end

sys = [{mdl}; find_system(mdl, 'LookUnderMasks','all', 'BlockType','SubSystem')];
n   = 0;

for s = 1:numel(sys)
    n = n + check_one(sys{s}, verbose);
end

if opened, close_system(mdl, 0); end

if verbose || n > 0
    fprintf('  %-40s %d overlapping line pairs\n', mdl, n);
end
end

% -------------------------------------------------------------------------
function n = check_one(sys, verbose)
lines = find_system(sys, 'FindAll','on', 'SearchDepth',1, 'Type','line');
seg   = [];                       % [horizontal? coord lo hi srcPortHandle]

for i = 1:numel(lines)
    p  = get_param(lines(i), 'Points');
    sp = get_param(lines(i), 'SrcPortHandle');
    for k = 1:size(p,1)-1
        a = p(k,:);  b = p(k+1,:);
        if abs(a(1)-b(1)) < 1e-6 && abs(a(2)-b(2)) > 1e-6
            seg(end+1,:) = [0 a(1) min(a(2),b(2)) max(a(2),b(2)) sp lines(i)]; %#ok<AGROW>
        elseif abs(a(2)-b(2)) < 1e-6 && abs(a(1)-b(1)) > 1e-6
            seg(end+1,:) = [1 a(2) min(a(1),b(1)) max(a(1),b(1)) sp lines(i)]; %#ok<AGROW>
        end
    end
end

n = 0;
for a = 1:size(seg,1)
    for b = a+1:size(seg,1)
        if seg(a,1) ~= seg(b,1),            continue, end   % different direction
        if abs(seg(a,2)-seg(b,2)) > 1e-6,   continue, end   % different line
        if seg(a,5) == seg(b,5),            continue, end   % same signal: a branch
        ov = min(seg(a,4),seg(b,4)) - max(seg(a,3),seg(b,3));
        if ov > 1
            n = n + 1;
            if verbose
                if seg(a,1), what = 'y'; else, what = 'x'; end
                fprintf('    %s : %s = %g, overlap %g px   %s  vs  %s\n', ...
                        strrep(sys, newline, ' '), what, seg(a,2), ov, ...
                        line_name(seg(a,6)), line_name(seg(b,6)));
            end
        end
    end
end
end

% -------------------------------------------------------------------------
function s = line_name(h)
%LINE_NAME  "source -> destination", for a finding a reader can act on.
try
    a = get_param(get_param(h,'SrcBlockHandle'), 'Name');
catch
    a = '?';
end
try
    d = get_param(h, 'DstBlockHandle');
    if ~isempty(d) && d(1) > 0, b = get_param(d(1), 'Name'); else, b = '(branch)'; end
catch
    b = '?';
end
s = strrep(sprintf('%s -> %s', a, b), newline, ' ');
end
