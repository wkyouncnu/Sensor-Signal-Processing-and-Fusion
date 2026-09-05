function row_feed(sys, dst, srcs)
%ROW_FEED  Put every source block on the row of the port it feeds, and wire it.
%
%   row_feed(a, 'allocation', {'tau_N','X_ff','k_pos','k_neg','n_max','n_min','y_pont'})
%
%   A block with many inputs - a MATLAB Function taking its parameters as
%   signals - is the usual source of unreadable wiring: seven Constants stacked
%   on the left, seven lines jogging into seven ports, and autorouting merging
%   several of them into one vertical run. Moving each Constant onto the height
%   of its own port turns every one of those lines into a single straight
%   segment, and lines that are straight cannot overlap.
%
%   Each source must have exactly one output port, which is true of Constants,
%   Inports, Gains and Selectors. Sources are moved vertically only; their x
%   stays where the builder put it. An empty entry in SRCS leaves that port
%   alone, for a port fed from somewhere else.
%
%   A warning is issued when the destination block is too short for the number
%   of ports it carries, because that is the one thing this function cannot
%   fix: the block must be made taller in the builder.

h = get_param([sys '/' dst], 'PortHandles');
n = numel(h.Inport);

if n > 1
    p     = get_param([sys '/' dst], 'Position');
    pitch = (p(4) - p(2) - 40) / (n - 1);
    if pitch < 52
        warning('row_feed:tight', ...
            ['%s/%s has %d ports %.1f px apart. Make it %d px tall so the ' ...
             'feeding blocks clear each other''s names.'], ...
            sys, dst, n, pitch, 52*(n-1) + 40);
    end
end

for k = 1:min(numel(srcs), n)
    if isempty(srcs{k}), continue, end
    y = port_xy(sys, dst, 'Inport', k);
    b = [sys '/' srcs{k}];
    q = get_param(b, 'Position');
    dy = round(y(2) - (q(2) + q(4))/2);
    set_param(b, 'Position', q + [0 dy 0 dy]);
    add_line(sys, [srcs{k} '/1'], sprintf('%s/%d', dst, k));
end
end
