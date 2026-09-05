function p = port_xy(sys, blk, kind, k)
%PORT_XY  Screen position of one port, as [x y].
%
%   p = port_xy(sys, 'Animate', 'Inport', 3)
%   p = port_xy(sys, 'log', 'Outport', 1)
%
%   READ PORT HEIGHTS, DO NOT CALCULATE THEM. Simulink insets the first and
%   last port of a block by a margin of its own choosing and spreads the rest
%   evenly between them, so a formula that looks right leaves lines a few
%   pixels out of true and the diagram fills up with shallow diagonals. The
%   pitch that does hold, and that a builder may use to SIZE a block before
%   asking where its ports went, is
%
%       pitch = (height - 40) / (number of ports - 1)
%
%   Blocks are sized so that pitch is at least 52 px, which is what a 30 px
%   block plus its name underneath needs.

h = get_param([sys '/' blk], 'PortHandles');
p = get_param(h.(kind)(k), 'Position');
end
