function add_measurement(mdl, pos, tag, extra, opts)
%ADD_MEASUREMENT  The last stage of the chain: selectors, logging, live view.
%
%   add_measurement(mdl, pos, tag)
%   add_measurement(mdl, pos, tag, {'u_d','X_cmd'})
%   add_measurement(mdl, pos, tag, {'n'}, struct('dash',true))
%
%     mdl    model name
%     pos    [x1 y1 x2 y2], normally gnc_chain('measurement')
%     tag    week tag, e.g. 'W01'. Names the logged variable and the live-view
%            function <tag>_animate
%     extra  cell array of extra inport names to log after the vessel states
%     opts   optional struct
%              .dash      false (default) — the live view receives
%                         (N, E, psi, t, en) and draws the track alone.
%                         true — it receives (u, v, r, N, E, psi, t, en) and
%                         draws the track AND the six states in one window,
%                         through _tools/live_dash.m
%              .weekName  name of the scope carrying the extra signals.
%                         Default '<tag>  this week'. Give it something the
%                         reader can act on, e.g. 'input  n  [rad/s]'
%
%   WHY .dash IS OPT-IN AND NOT THE DEFAULT
%
%   Turning it on changes the Animate block's signature, so every week that
%   uses it must have its <tag>_animate wrapper widened to match on the same
%   day. Weeks migrate one at a time and each one is rebuilt and run before
%   the next; a flag makes that safe, a silent change of default does not.
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
if nargin < 5, opts = struct(); end
if ~isfield(opts,'dash'),     opts.dash     = false;                    end
if ~isfield(opts,'weekName'), opts.weekName = [tag '  this week'];      end

%  The live view's inputs. The dashboard needs the three velocities as well,
%  so the port list — and therefore the block's height and every lane that
%  reaches it — is derived from this one cell array rather than written twice.
if opts.dash
    anmIn = {'u','v','r','N','E','psi'};
else
    anmIn = {'N','E','psi'};
end
nAnm = numel(anmIn) + 2;                       % + clock + enable

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
%
%  It is placed BELOW the log ladder, whose height grows with the number of
%  logged channels. A fixed y would be overrun by any week that logs more than
%  eight, and the two blocks would be drawn on top of each other.
%  55 px per port keeps each name legible under its own row, so the height
%  follows the port count instead of being a fixed 260.
yA = 90 + 52*nlog + 80;
add_block('simulink/User-Defined Functions/MATLAB Function', [sub '/Animate'], ...
          'Position',[420 yA 540 yA+55*nAnm]);
sig = strjoin(anmIn, ', ');
set_mlfcn([sub '/Animate'], { ...
sprintf('function ok = Animate(%s, t, en)', sig)
'%#codegen'
'% Live view of the vessel while the model runs.'
'%'
'% A MATLAB Function block cannot plot, so the drawing function is declared'
'% extrinsic: Simulink calls plain MATLAB rather than generating code for it.'
'% Set animate = 0 in the setup script to switch the live view off.'
'%'
'% psi arrives in RADIANS and r in rad/s - the units otter.m works in. The'
'% wrapper converts them for display, in one place, so no two figures in the'
'% course can disagree about what a degree is.'
sprintf('coder.extrinsic(''%s_animate'');', tag)
'ok = 1;'
'if en > 0.5'
sprintf('    %s_animate(%s, t);', tag, sig)
'end'
'end'});

logy = arrayfun(@(k) port_xy(sub,'log','Inport',k), 1:nlog, 'UniformOutput', false);
logy = cellfun(@(p) p(2), logy);                       % row of each log channel
anmy = arrayfun(@(k) port_xy(sub,'Animate','Inport',k), 1:nAnm, 'UniformOutput', false);
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

%% ---- and a second scope, showing THIS WEEK'S signals -------------------
%  The three velocities are the same in every week of the course, so a scope
%  on them alone cannot show what a particular week is about. The extra
%  signals are exactly what the week added - the command it follows, the
%  force it demands, the state it stores - so a second scope on those makes
%  pressing Run in Simulink produce the week's own picture and not a generic
%  one. Both open with the model.
%
%  It sits to the LEFT of the log ladder, below it, so its lines never have to
%  cross the log Mux. One lane per signal, 8 px apart, in the empty corridor
%  between the inports at x = 90 and the selectors at x = 200.
if ~isempty(extra)
    y0 = logy(end) + 80;
    add_block('simulink/Signal Routing/Mux', [sub '/week'], ...
              'Inputs', num2str(numel(extra)), ...
              'Position',[155 y0 160 y0+52*numel(extra)]);
    for i = 1:numel(extra)
        lane_line(sub, extra{i}, 1, 'week', i, 100 + 8*i);
    end
    yw = port_xy(sub, 'week', 'Outport', 1);
    add_block('simulink/Sinks/Scope', [sub '/' opts.weekName], ...
              'Position',[220 yw(2)-15 250 yw(2)+15]);
    add_line(sub, 'week/1', [opts.weekName '/1']);
    set_param([sub '/' opts.weekName], 'Open', 'on');
end

%% ---- the live view ------------------------------------------------------
%  The clock and the enable switch are placed on the rows of the ports they
%  feed, so only the three state feeds need a lane.
%  At x = 300 rather than 200: the corridor left of that belongs to the
%  week's own scope, which shares these rows.
kClock = nAnm - 1;   kEnable = nAnm;
add_block('simulink/Sources/Digital Clock', [sub '/clock'], ...
          'SampleTime','h', 'Position',[300 anmy(kClock)-15 350 anmy(kClock)+15]);
add_block('simulink/Sources/Constant', [sub '/live view'], ...
          'Value','animate', 'Position',[298 anmy(kEnable)-15 353 anmy(kEnable)+15]);
ya = port_xy(sub, 'Animate', 'Outport', 1);
add_block('simulink/Sinks/Terminator', [sub '/anim end'], ...
          'Position',[600 ya(2)-10 620 ya(2)+10]);

%  One vertical lane per state feed, all of them in the corridor between the
%  selectors (x = 250) and the live-view block (x = 420). The three lanes at
%  265..295 belong to the velocity Mux and 258 to psi, so the dashboard's
%  extra feeds take 384, 396 and 408 and no two signals share a run.
%  _tools/check_overlaps.m is the check that this is still true.
LANE = struct('psi',258, 'N',360, 'E',372, 'u',384, 'v',396, 'r',408);
for k = 1:numel(anmIn)
    lane_line(sub, anmIn{k}, 1, 'Animate', k, LANE.(anmIn{k}));
end
add_line(sub, 'clock/1',     sprintf('Animate/%d', kClock));
add_line(sub, 'live view/1', sprintf('Animate/%d', kEnable));
add_line(sub, 'Animate/1',   'anim end/1');

%% ---- open the scope with the model -------------------------------------
set_param([sub '/vessel  u v r'], 'Open', 'on');

assert(nx == 1 + numel(extra));   % the interface the caller must wire
end
