function W03_1_build_heading()
%BUILD_W03_MODELS  Generate W03_heading_control.slx from code.
%
%   >> W03_1_build_heading
%
%   THE SIGNAL CHAIN
%
%   Left to right, in the order used by the MSS demonstration models:
%
%     Heading command --> Heading autopilot --> Control allocation --> Otter USV --> Measurements
%       psi_d, X_ff             tau_N                   n                  x
%
%   One signal travels backwards: the state x, from which the autopilot takes
%   the heading psi and the yaw rate r.
%
%   Each stage is a subsystem. The top level shows the chain and the one
%   feedback path; everything else lives inside a stage.
%
%   Regenerating is safe: any existing W03_heading_control.slx is overwritten.

m    = 'W03_heading_control';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

P = gnc_chain({'command','controller','allocation','plant','measurement'}, ...
              'Height', struct('command',110, 'controller',110), 'Y', 120);

KK = {'k_pos','k_neg','n_max','n_min','y_pont'};

%% =====================================================================
%  1. Heading command
%  =====================================================================
%  Two steps in degrees, summed, then converted to radians once. Every angle
%  after this point is in radians; every angle a human types is in degrees.
s = add_subsys(m, 'Heading command', P.command, {}, {'psi_d','X_ff'}, ...
               gnc_colour('command'));
add_block('simulink/Sources/Step', [s '/step 1'], ...
          'Time','t_up', 'Before','0', 'After','psi_1', 'Position',[90 60 130 100]);
add_block('simulink/Sources/Step', [s '/step 2'], ...
          'Time','t_dn', 'Before','0', 'After','psi_2 - psi_1', 'Position',[90 140 130 180]);
add_sum(s, 'sum', '++', [232 120]);
add_block('simulink/Math Operations/Gain', [s '/deg2rad'], ...
          'Gain','pi/180', 'Position',[310 100 365 140]);
add_block('simulink/Sources/Constant', [s '/forward force'], ...
          'Value','X_ff', 'Position',[310 220 400 250]);
set_param([s '/psi_d'], 'Position',[440 110 470 130]);
set_param([s '/X_ff'],  'Position',[440 225 470 245]);
add_line(s, 'step 1/1','sum/1','autorouting','on');
add_line(s, 'step 2/1','sum/2','autorouting','on');
add_line(s, 'sum/1','deg2rad/1','autorouting','on');
add_line(s, 'deg2rad/1','psi_d/1','autorouting','on');
add_line(s, 'forward force/1','X_ff/1','autorouting','on');

%% =====================================================================
%  2. Heading autopilot
%  =====================================================================
c = add_subsys(m, 'Heading autopilot', P.controller, ...
               {'psi_d','x'}, {'tau_N','psi_d out'}, gnc_colour('controller'));

add_block('simulink/Signal Routing/Selector', [c '/psi'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','12', ...
          'InputPortWidth','12', 'Position',[170 150 220 170]);
add_block('simulink/Signal Routing/Selector', [c '/r'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','6', ...
          'InputPortWidth','12', 'Position',[170 250 220 270]);

%  The heading error, wrapped. This is the only place in the model where an
%  angle is subtracted from an angle, and it is the only place a wrap is
%  needed.
blk = [c '/heading error'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[300 50 470 194]);
set_mlfcn(blk, { ...
'function e = headingerror(psi_d, psi, use_ssa)'
'%#codegen'
'% Smallest signed angle between two headings.'
'%'
'%   ssa(a) maps any angle into (-pi, pi], so the controller always turns the'
'%   SHORT way round. Without it, a command of -170 deg while heading +170 deg'
'%   reads as an error of -340 deg and the vessel turns almost all the way'
'%   round to reach a heading 20 deg away.'
'%'
'% use_ssa = 0 removes the wrap, which is the experiment of section E.'
'e = psi_d - psi;'
'if use_ssa > 0.5'
'    e = atan2(sin(e), cos(e));'
'end'
'end'}, 'e', '[1 1]');
add_block('simulink/Sources/Constant', [c '/use_ssa'], ...
          'Value','use_ssa', 'Position',[170 60 240 90]);

add_block('simulink/Math Operations/Gain', [c '/Kp'], 'Gain','Kp', ...
          'Position',[540 100 590 140]);
add_block('simulink/Math Operations/Gain', [c '/Kd'], 'Gain','Kd', ...
          'Position',[540 240 590 280]);
add_sum(c, 'tau', '+-', [692 190]);

set_param([c '/psi_d'],     'Position',[ 60 110  90 130]);
set_param([c '/x'],         'Position',[ 60 200  90 220]);
set_param([c '/tau_N'],     'Position',[770 180 800 200]);
%  The pass-through of psi_d runs ABOVE the heading error block. Sent straight
%  across it would be drawn through the block, and left to autorouting it is
%  drawn on top of whichever other line was routed around the same corner.
set_param([c '/psi_d out'], 'Position',[770  10 800  30]);

%  Each of the three inputs of the heading error block gets its own row, so
%  each of those connections is one straight segment. See _tools/row_feed.m.
row_feed(c, 'heading error', {'psi_d','psi','use_ssa'});

Lc = @(x,y) add_line(c, x, y, 'autorouting','on');
Lc('x/1','psi/1');   Lc('x/1','r/1');
Lc('heading error/1','Kp/1');
Lc('r/1','Kd/1');
lane_line(c, 'Kp', 1, 'tau', 1, 640);
lane_line(c, 'Kd', 1, 'tau', 2, 660);
Lc('tau/1','tau_N/1');
lane_line(c, 'psi_d', 1, 'psi_d out', 1, 130);

%% =====================================================================
%  3. Control allocation
%  =====================================================================
%  Two propellers, two demands. The map tau = B f of Appendix A1 is square in
%  the (X, N) plane and therefore has exactly one inverse:
%
%     X = T1 + T2,   N = y_pont (T1 - T2)
%       ==>  T1 = X/2 + N/(2 y_pont),   T2 = X/2 - N/(2 y_pont)
%
%  Nothing is optimised and nothing is chosen. Week 4 meets the case where
%  there are more thrusters than demands and the inverse is no longer unique.
a = add_subsys(m, 'Control allocation', P.allocation, ...
               {'tau_N','X_ff'}, {'n','n1','n2'}, gnc_colour('allocation'));

blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[280 50 460 402]);
set_mlfcn(blk, { ...
'function n = allocation(tau_N, X_ff, k_pos, k_neg, n_max, n_min, y_pont)'
'%#codegen'
'% Demanded surge force and yaw moment to two shaft speeds.'
'%'
'% Step 1, the exact inverse of tau = B f:'
'%     T1 = X/2 + N/(2 y_pont)'
'%     T2 = X/2 - N/(2 y_pont)'
'%'
'% Step 2, the propeller curve inverted one propeller at a time:'
'%     n = sign(T) sqrt(|T| / k),  with k_pos ahead and k_neg astern.'
'%'
'% Allocating THRUST and inverting afterwards is what makes the two shaft'
'% speeds come out unequal by themselves. A pure yaw moment gives T2 = -T1,'
'% and because k_neg < k_pos the reverse shaft must turn faster. Appendix A1'
'% derives that pair by hand; here it falls out of the arithmetic.'
'T = [X_ff/2 + tau_N/(2*y_pont);'
'     X_ff/2 - tau_N/(2*y_pont)];'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        ni =  sqrt( T(i) / k_pos);'
'    else'
'        ni = -sqrt(-T(i) / k_neg);'
'    end'
'    n(i) = min(max(ni, n_min), n_max);'
'end'
'end'}, 'n', '[2 1]');

for i = 1:numel(KK)
    add_block('simulink/Sources/Constant', [a '/' KK{i}], ...
              'Value', KK{i}, 'Position', [110 95+50*i 185 121+50*i]);
end
add_block('simulink/Signal Routing/Demux', [a '/split'], ...
          'Outputs','2', 'Position',[540 148 545 268]);

set_param([a '/tau_N'], 'Position',[ 70  70 100  90]);
set_param([a '/X_ff'],  'Position',[ 70 120 100 140]);

%  Seven inputs, one row each: row_feed moves every source onto the height of
%  the port it feeds, and each of those seven lines becomes one straight
%  segment. The block is 352 px tall for that reason and no other - seven
%  ports 52 px apart is what the Constants and their names need.
row_feed(a, 'allocation', [{'tau_N','X_ff'} KK]);

%  The three outputs, each on the row of the port that produces it. The Demux
%  is centred on the allocation block's output so that the pair is one straight
%  line, and the two shaft speeds then leave on the Demux's own rows.
yo = port_xy(a, 'allocation', 'Outport', 1);
set_param([a '/split'], 'Position', [540 yo(2)-60 545 yo(2)+60]);
y1 = port_xy(a, 'split', 'Outport', 1);
y2 = port_xy(a, 'split', 'Outport', 2);
set_param([a '/n'],  'Position',[620  60 650  80]);
set_param([a '/n1'], 'Position',[620 y1(2)-10 650 y1(2)+10]);
set_param([a '/n2'], 'Position',[620 y2(2)-10 650 y2(2)+10]);

La = @(x,y) add_line(a, x, y, 'autorouting','on');
add_line(a, [yo; 500 yo(2); 500 70; port_xy(a,'n','Inport',1)]);   % over the Demux
La('allocation/1','split/1');
La('split/1','n1/1');
La('split/2','n2/1');

%% =====================================================================
%  4. Otter USV
%  =====================================================================
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% =====================================================================
%  5. Measurements
%  =====================================================================
add_measurement(m, P.measurement, 'W03', {'psi_d','tau_N','n1','n2'}, ...
                struct('dash', true, 'weekName', 'W03  command and moment'));

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Heading command/1',   'Heading autopilot/1');
L('Otter USV/1',         'Heading autopilot/2');

L('Heading autopilot/1', 'Control allocation/1');
L('Heading command/2',   'Control allocation/2');
L('Control allocation/1','Otter USV/1');

L('Otter USV/1',         'Measurements/1');
L('Heading autopilot/2', 'Measurements/2');
L('Heading autopilot/1', 'Measurements/3');
L('Control allocation/2','Measurements/4');
L('Control allocation/3','Measurements/5');

%% ---- what the model is for ---------------------------------------------
note(m, [40 320 880 680], strjoin({ ...
'WEEK 3  -  HEADING CONTROL'
''
'The same chain as Week 2 with one axis changed, and every conclusion of'
'Week 2 reversed by that one change.'
''
'The heading is the INTEGRAL of the yaw rate, psi = int r, so the plant'
'carries a free integrator and the loop is TYPE 1:'
''
'        M66 psi_ddot = tau_N + Nr psi_dot,   M66 = 42.65, Nr = -42.65.'
''
'FOUR THINGS TO TRY'
''
'1  PROPORTIONAL ONLY.  Kd = 0. The steady-state error is ZERO, at every'
'   gain. Week 2 could not do this at any gain. Nothing was tuned; the'
'   plant simply has an integrator that the surge axis did not have.'
''
'2  ADD THE DERIVATIVE.  Kd acts on the YAW RATE r, which is the'
'   derivative of the controlled variable. Here it is a DAMPER:'
''
'        zeta = (|Nr| + Kd) / (2 sqrt(Kp M66)).'
''
'   In Week 2 the same term was a MASS and made things worse. Substitute'
'   the control law into the equation of motion before assuming.'
''
'3  THE WRAP.  psi_1 = 170, psi_2 = -170, t_dn = 20. With use_ssa = 1'
'   the vessel turns 20 deg. With use_ssa = 0 it turns 340 deg the'
'   other way, to reach the same heading.'
''
'4  BIG TURNS OVERSHOOT LESS.  Kd = 0, psi_1 = 5, 20, 60, 120. The yaw'
'   damping in otter.m is Nh = Nr (1 + 10|r|) r, so a fast turn is'
'   damped harder than a slow one. No linear model can do this.'}, newline));

%% ---- plot when the run finishes ----------------------------------------
set_param(m, 'StopFcn', 'W03_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

%  Every block gets the size MSS uses. Measured from the MSS demo models, not
%  invented - see _tools/mss_style.m. Applied last so it catches every block
%  regardless of which helper created it.
mss_style(m);

save_system(m, out);

%  The block diagram belongs to the builder: it changes when the model changes
%  and not when a gain does. Exporting it here keeps it in step with the model.
export_diagram(m, fullfile(here, 'img'));
close_system(m, 0);

fprintf('  built  %s\n', out);
end

% -------------------------------------------------------------------------
function note(m, pos, txt)
h = Simulink.Annotation([m '/note']);
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end
