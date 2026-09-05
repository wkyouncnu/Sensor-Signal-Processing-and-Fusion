function n = mss_style(mdl, verbose)
%MSS_STYLE  Resize every block in a model to the sizes MSS uses.
%
%   mss_style(mdl)              apply, silently
%   n = mss_style(mdl, true)    apply, list what changed, return the count
%
%   Call it once at the end of a builder, just before save_system.
%
%   WHERE THE NUMBERS COME FROM
%
%   Not invented. Measured across every demo model in
%   Tools/MSS/SIMULINK/mssSimulinkDemos - 211 Sum blocks, 242 Gains, 354
%   Inports and so on - and the median of each block type taken. The table
%   below is that measurement. Regenerate it with the survey at the bottom of
%   this file if MSS is ever updated.
%
%   WHY IT MATTERS
%
%   Simulink's defaults are larger than MSS's in almost every case: a default
%   Gain is 40 wide against 50 x 36, a default Sum is a 25 x 40 rectangle
%   against a 20 x 20 circle, a default Transfer Fcn sprawls. On a diagram
%   that has to be read at page width in a PDF, oversized blocks push the
%   chain apart, and the reader loses the line of the signal. Matching MSS
%   also means a student who opens an MSS demo next to one of these models
%   sees the same drawing conventions in both.
%
%   THE CENTRE IS PRESERVED
%
%   Blocks are resized about their own centre, so a block that was lined up
%   with the signal passing through it stays lined up. Simulink keeps the
%   lines attached and redraws them.
%
%   WHAT IS LEFT ALONE
%
%   SubSystem blocks. Those are the six stages of the signal chain and their
%   sizes come from gnc_chain, which places them deliberately. Mux and Demux
%   keep their height too - the height is how many signals they carry, and
%   forcing it would misrepresent the model.

if nargin < 2, verbose = false; end

%  block type -> [width height], median over the MSS demo models
S = { 'Sum',           20  20
      'Gain',          50  36
      'Constant',      55  30
      'Integrator',    30  30
      'TransferFcn',   60  36
      'Saturate',      30  30
      'Scope',         30  30
      'Step',          30  30
      'Clock',         20  20
      'Inport',        30  14
      'Outport',       30  14
      'ToWorkspace',   60  30
      'Product',       45  35
      'Terminator',    20  20
      'Math',          30  30
      'Trigonometry',  30  30
      'Signum',        30  30
      'Switch',        30  30
      'Rounding',      30  30
      'RandomNumber',  30  28
      'Fcn',           60  22 };

want = containers.Map(S(:,1), num2cell(cell2mat(S(:,2:3)), 2));

blocks = find_system(mdl, 'LookUnderMasks','all', 'Type','Block');
n = 0;
for i = 1:numel(blocks)
    b = blocks{i};
    try, t = get_param(b, 'BlockType'); catch, continue; end
    if ~isKey(want, t), continue; end

    wh = want(t);
    p  = get_param(b, 'Position');
    if (p(3)-p(1)) == wh(1) && (p(4)-p(2)) == wh(2), continue; end

    cx = (p(1)+p(3))/2;  cy = (p(2)+p(4))/2;
    q  = round([cx-wh(1)/2, cy-wh(2)/2, cx+wh(1)/2, cy+wh(2)/2]);
    set_param(b, 'Position', q);
    n = n + 1;
    if verbose
        fprintf('    %-38s %s  %dx%d -> %dx%d\n', get_param(b,'Name'), t, ...
                p(3)-p(1), p(4)-p(2), wh(1), wh(2));
    end
end

%  A round summing junction is the MSS signature. Any Sum still drawn as a
%  rectangle is one a builder created without add_sum; fix it here rather than
%  leaving one slab in an otherwise consistent diagram.
sums = find_system(mdl, 'LookUnderMasks','all', 'BlockType','Sum');
for i = 1:numel(sums)
    if ~strcmp(get_param(sums{i}, 'IconShape'), 'round')
        set_param(sums{i}, 'IconShape', 'round');
        sg = strrep(get_param(sums{i}, 'Inputs'), '|', '');
        set_param(sums{i}, 'Inputs', ['|' sg]);
        n = n + 1;
    end
end

if verbose, fprintf('    %d blocks restyled in %s\n', n, mdl); end
end

% =========================================================================
%  The survey that produced the table above. Kept so the numbers can be
%  checked rather than trusted.
%
%   root = <...>/Tools/MSS;  addpath(genpath(root));
%   dd = dir(fullfile(root,'SIMULINK','mssSimulinkDemos','demo*.slx'));
%   S = containers.Map('KeyType','char','ValueType','any');
%   for k = 1:numel(dd)
%       [~,m] = fileparts(dd(k).name);
%       evalc(sprintf('load_system(''%s'')', fullfile(dd(k).folder, dd(k).name)));
%       b = find_system(m,'LookUnderMasks','all','FollowLinks','on','Type','Block');
%       for i = 1:numel(b)
%           t = get_param(b{i},'BlockType');  p = get_param(b{i},'Position');
%           if ~isKey(S,t), S(t) = []; end
%           S(t) = [S(t); p(3)-p(1) p(4)-p(2)];
%       end
%       evalc(sprintf('close_system(''%s'',0)', m));
%   end
%   for k = sort(S.keys), v = S(k{1});
%       fprintf('%-16s %4d  %dx%d\n', k{1}, size(v,1), median(v(:,1)), median(v(:,2)));
%   end
