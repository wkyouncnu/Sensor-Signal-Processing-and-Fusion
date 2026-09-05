function add_measurement(mdl, pos, tag, extra)
%ADD_MEASUREMENT  The last stage of the chain: selectors, logging, live view.
%
%   add_measurement(mdl, pos, tag)
%   add_measurement(mdl, pos, tag, {'u_d','X_cmd'})
%
%     mdl    model name
%     pos    [x1 y1 x2 y2], normally gnc_chain('measurement')
%     tag    week tag, e.g. 'W01'. Names the logged variable and the live-view
%            function <tag>_animate
%     extra  cell array of extra inport names to log after the vessel states
%
%   THE LOGGING CONTRACT
%
%   Every week logs the same first six columns, in the same order, so a plotting
%   function written for one week reads the next one without modification:
%
%       1  u        surge velocity      [m/s]
%       2  v        sway velocity       [m/s]
%       3  r        yaw rate            [rad/s]
%       4  N        north position      [m]
%       5  E        east position       [m]
%       6  psi      heading             [deg]     already converted
%       7..        the week's extra signals, in the order given
%
%   The variable in the base workspace is named after the tag, so `W01` holds
%   Week 1's log and `W03` holds Week 3's.
%
%   THE LAYOUT: ONE ROW PER LOGGED CHANNEL
%
%   The Mux and the live-view block are created FIRST and their port heights
%   are then read back with get_param. Every block that feeds a port is placed
%   with its own centre on that port's row, which makes the connection a single
%   straight horizontal segment. Nothing is left to autorouting, and because no
%   two channels share a vertical run, no two signals can be drawn on top of
%   each other.
%
%   The port heights are READ and not calculated. Simulink insets the first and
%   last port of a Mux by a margin of its own choosing, so a formula that looks
%   right gives lines a few pixels out of true, and the diagram fills up with
%   shallow diagonals.
%
%   The four lines that cannot be straight - the three velocities going up to
%   the scope and the heading going down to the live view - are each given a
%   vertical lane of their own by _tools/lane_line.m. _tools/check_overlaps.m
%   is the check that no two of them were given the same one.
%
%   THE LIVE VIEW
%
%   A MATLAB Function block cannot plot. Declaring the drawing function
%   extrinsic makes Simulink hand the call back to MATLAB instead of generating
%   code for it. The drawing itself is in _tools/live_track.m, wrapped by
%   <tag>_animate. It is fed psi in RADIANS, from the selector and not from the
%   rad2deg gain, because that is what live_track documents as its input.

if nargin < 4 || isempty(extra), extra = {}; end

sub = add_subsys(mdl, 'Measurements', pos, [{'x'} extra], {}, gnc_colour('measurement'));

nx   = 1 + numel(extra);
nlog = 6 + numel(extra);

%% ---- the three blocks whose ports define every row ----------------------
%  52 px per channel leaves room under each 30 px block for its name.
add_block('simulink/Signal Routing/Mux', [sub '/log'], ...
          'Inputs', num2str(nlog), 'Position',[420 90 425 90+52*nlog]);

add_block('simulink/Signal Routing/Mux', [sub '/vel'], ...
          'Inputs','3', 'Position',[340 -60 345 48]);

%  Simulink puts the first and last port 20 px inside a block and spreads the
%  rest evenly, so five ports on a block of height H are (H-40)/4 apart. 260
%  gives 55, which is enough for the clock and the switch to sit on their own
%  rows with their names underneath them.
add_block('simulink/User-Defined Functions/MATLAB Function', [sub '/Animate'], ...
          'Position',[420 560 540 820]);
set_mlfcn([sub '/Animate'], { ...
'function ok = Animate(N, E, psi, t, en)'
'%#codegen'
'% Live view of the hull, its heading and its track while the model runs.'
'%'
'% A MATLAB Function block cannot plot, so the drawing function is declared'
'% extrinsic: Simulink calls plain MATLAB rather than generating code for it.'
'% Set animate = 0 in the setup script to switch the live view off.'
sprintf('coder.extrinsic(''%s_animate'');', tag)
'ok = 1;'
'if en > 0.5'
sprintf('    %s_animate(N, E, psi, t);', tag)
'end'
'end'});

logy = arrayfun(@(k) port_xy(sub,'log','Inport',k), 1:nlog, 'UniformOutput', false);
logy = cellfun(@(p) p(2), logy);                       % row of each log channel
anmy = arrayfun(@(k) port_xy(sub,'Animate','Inport',k), 1:5, 'UniformOutput', false);
anmy = cellfun(@(p) p(2), anmy);                       % row of each live-view input

%% ---- one state out of the twelve ---------------------------------------
%  Each selector sits on the row of the Mux input it feeds.
S = {'u',1; 'v',2; 'r',6; 'N',7; 'E',8; 'psi',12};
for i = 1:size(S,1)
    add_block('simulink/Signal Routing/Selector', [sub '/' S{i,1}], ...
              'IndexOptions','Index vector (dialog)', 'Indices', num2str(S{i,2}), ...
              'InputPortWidth','12', 'Position',[200 logy(i)-15 250 logy(i)+15]);
    add_line(sub, 'x/1', [S{i,1} '/1'], 'autorouting','on');
end
set_param([sub '/x'], 'Position', [60 mean(logy([1 6]))-7 90 mean(logy([1 6]))+7]);

%  On the psi row, and therefore in line with both its source and its
%  destination: selector -> gain -> Mux is one straight segment.
add_block('simulink/Math Operations/Gain', [sub '/rad2deg'], ...
          'Gain','180/pi', 'Position',[298 logy(6)-18 348 logy(6)+18]);

%% ---- the log ------------------------------------------------------------
yo = port_xy(sub, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [sub '/' tag], ...
          'VariableName', tag, 'SaveFormat','Structure With Time', ...
          'Position',[490 yo(2)-15 550 yo(2)+15]);
add_line(sub, 'log/1', [tag '/1']);

L = {'u','v','r','N','E','rad2deg'};
add_line(sub, 'psi/1', 'rad2deg/1');
for i = 1:6, add_line(sub, [L{i} '/1'], sprintf('log/%d', i)); end

%  The extra inports continue the same ladder below the six vessel states, so
%  each of them also reaches the Mux along one straight line.
for i = 1:numel(extra)
    set_param([sub '/' extra{i}], 'Position', [60 logy(6+i)-7 90 logy(6+i)+7]);
    add_line(sub, [extra{i} '/1'], sprintf('log/%d', 6+i));
end

%% ---- a scope that opens with the model ---------------------------------
yv = port_xy(sub, 'vel', 'Outport', 1);
add_block('simulink/Sinks/Scope', [sub '/vessel  u v r'], ...
          'Position',[420 yv(2)-15 450 yv(2)+15]);
VL = [265 280 295];                   % one vertical lane per velocity
for i = 1:3, lane_line(sub, L{i}, 1, 'vel', i, VL(i)); end
add_line(sub, 'vel/1', 'vessel  u v r/1');

%% ---- the live view ------------------------------------------------------
%  The clock and the enable switch are placed on the rows of the ports they
%  feed, so only the three state feeds need a lane.
add_block('simulink/Sources/Digital Clock', [sub '/clock'], ...
          'SampleTime','h', 'Position',[200 anmy(4)-15 250 anmy(4)+15]);
add_block('simulink/Sources/Constant', [sub '/live view'], ...
          'Value','animate', 'Position',[198 anmy(5)-15 253 anmy(5)+15]);
ya = port_xy(sub, 'Animate', 'Outport', 1);
add_block('simulink/Sinks/Terminator', [sub '/anim end'], ...
          'Position',[600 ya(2)-10 620 ya(2)+10]);

lane_line(sub, 'N',   1, 'Animate', 1, 360);
lane_line(sub, 'E',   1, 'Animate', 2, 372);
lane_line(sub, 'psi', 1, 'Animate', 3, 258);
add_line(sub, 'clock/1',     'Animate/4');
add_line(sub, 'live view/1', 'Animate/5');
add_line(sub, 'Animate/1',   'anim end/1');

%% ---- open the scope with the model -------------------------------------
set_param([sub '/vessel  u v r'], 'Open', 'on');

assert(nx == 1 + numel(extra));   % the interface the caller must wire
end
