function W02_1_build_surge_control()
%BUILD_W02_MODELS  Generate W02_surge_control.slx from code.
%
%   >> W02_1_build_surge_control
%
%   THE SIGNAL CHAIN
%
%   Left to right, in the order used by the MSS demonstration models:
%
%     Speed command --> Surge controller --> Control allocation --> Otter USV --> Measurements
%          u_d                X_cmd                  n                  x
%
%   Two signals travel backwards, and only two:
%
%     x      from the plant to the controller — the measured speed
%     X_sat  from the allocation to the controller — what the propellers
%            actually delivered, which is what every anti-windup scheme needs
%
%   Each stage is a subsystem. The top level shows the chain and the two
%   feedback paths; everything else lives inside a stage.
%
%   Regenerating is safe: any existing W02_surge_control.slx is overwritten.

m    = 'W02_surge_control';
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
              'Height', struct('controller',130, 'allocation',110), 'Y', 120);

AW = {'aw_mode','Ki','K_aw'};
KK = {'k_pos','k_neg','n_max','n_min'};

%% =====================================================================
%  1. Speed command
%  =====================================================================
%  Two steps are summed, so one model covers a single step and the
%  up-then-down profile the windup experiment needs. Setting u_d2 = u_d1
%  turns the second step off.
s = add_subsys(m, 'Speed command', P.command, {}, {'u_d'}, gnc_colour('command'));
add_block('simulink/Sources/Step', [s '/step 1'], ...
          'Time','t_up', 'Before','0', 'After','u_d1', 'Position',[100 60 140 100]);
add_block('simulink/Sources/Step', [s '/step 2'], ...
          'Time','t_dn', 'Before','0', 'After','u_d2 - u_d1', 'Position',[100 140 140 180]);
add_sum(s, 'sum', '++', [262 120]);
set_param([s '/u_d'], 'Position',[400 110 430 130]);
add_line(s, 'step 1/1','sum/1','autorouting','on');
add_line(s, 'step 2/1','sum/2','autorouting','on');
add_line(s, 'sum/1','u_d/1','autorouting','on');

%% =====================================================================
%  2. Surge controller
%  =====================================================================
c = add_subsys(m, 'Surge controller', P.controller, ...
               {'u_d','x','X_sat'}, {'X_cmd','I'}, gnc_colour('controller'));

%  ---- LAYOUT -----------------------------------------------------------
%  The interior is laid out in columns, left to right, exactly like the top
%  level. Simulink.BlockDiagram.arrangeSystem was tried and rejected: it packs
%  the blocks more tightly but reorders them, and put the X_cmd OUTPORT at the
%  top left, ahead of the inports. Compactness is not the goal here; being
%  readable in a PDF at page width is.
%
%    50   150      260    380          600     690    790     950    1060
%    in   select   err    Kp / AW /    I       X_pid  hand    open   out
%         const    sum    D / PID      state   sum    or blk  or cls
%
%  One line runs right to left, from the switch output back into the
%  anti-windup block. That is the saturated command coming back to tell the
%  integrator the loop has been opened, and it is the whole subject of 2-6.
add_block('simulink/Signal Routing/Selector', [c '/u'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','1', ...
          'InputPortWidth','12', 'Position',[150 140 200 160]);
add_sum(c, 'error', '+-', [280 90]);
add_block('simulink/Math Operations/Gain', [c '/Kp'], 'Gain','Kp', ...
          'Position',[380 40 430 76]);

%  All three anti-windup schemes are the same block with a different mode, so
%  the comparison in section F changes one number and nothing else.
blk = [c '/anti-windup'];
%  Six inputs 52 px apart, so the three constants that feed it can sit on
%  their own rows with their names underneath: H = 5*52 + 40 = 300.
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[380 140 530 440]);
set_mlfcn(blk, { ...
'function di = antiwindup(e, X_cmd, X_sat, mode, Ki, K_aw)'
'%#codegen'
'% What reaches the integrator.'
'%'
'%   mode 0  none'
'%        1  clamping  - integration is frozen while the actuator is'
'%                       saturated AND the error drives it further in'
'%        2  back-calculation - the excess is fed back through K_aw'
'%'
'% Windup is not a fault of the integrator. It is what an integrator does'
'% when it is asked to close a loop that the actuator has already opened.'
'di = Ki * e;'
'sat = X_cmd - X_sat;'
'if Ki ~= 0'
'    if mode == 1'
'        if abs(sat) > 1e-9 && sign(e) == sign(sat)'
'            di = 0;'
'        end'
'    elseif mode == 2'
'        di = di - K_aw * sat;'
'    end'
'end'
'% With Ki = 0 there is no integrator to protect, and back-calculation would'
'% otherwise charge the integrator during a saturation it can never discharge.'
'end'}, 'di', '[1 1]');

for i = 1:3
    add_block('simulink/Sources/Constant', [c '/' AW{i}], ...
              'Value', AW{i}, 'Position', [150 265+60*i 205 295+60*i]);
end

%  The integrator on the row of the anti-windup output that feeds it.
q = port_xy(c, 'anti-windup', 'Outport', 1);
add_block('simulink/Continuous/Integrator', [c '/I state'], ...
          'InitialCondition','0', 'Position',[600 q(2)-15 630 q(2)+15]);

%  Derivative on the MEASUREMENT, not on the error. Differentiating the error
%  puts a step through the derivative at every setpoint change; a measurement
%  never steps.
add_block('simulink/Continuous/Transfer Fcn', [c '/D filter'], ...
          'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]', ...
          'Position',[380 490 440 526]);

add_sum(c, 'X_pid', '++-', [690 170]);

%  loop_closed = 0 disconnects the controller and applies a constant force, so
%  the same model performs the open-loop identification of section C.
add_block('simulink/Sources/Constant', [c '/loop_closed'], ...
          'Value','loop_closed', 'Position',[860 420 915 450]);
add_block('simulink/Sources/Constant', [c '/X_open'], ...
          'Value','X_open', 'Position',[860 480 915 510]);
%  ---- the same controller, written by Simulink ------------------------
%  Simulink ships a PID Controller block that does everything the blue blocks
%  above do: three terms, a filtered derivative, an output limit and the same
%  two anti-windup schemes. It is one block instead of nine.
%
%  Both are in the model and `pid_mode` chooses between them, because a
%  student who has only ever used the block does not know what is inside it,
%  and a student who has only ever built it by hand does not know that the
%  block exists. Section G runs both and compares them.
%
%  Two differences are real and are NOT hidden:
%    - the block differentiates its INPUT, which here is the error. The
%      hand-built path differentiates the measurement. With Kd = 0 the two
%      agree exactly; with Kd > 0 they do not, and section G measures it
%    - the block saturates its own output at [X_lo, X_hi], which are the same
%      limits the allocation imposes, so the two saturations coincide
add_block('simulink/Continuous/PID Controller', [c '/PID block'], ...
          'Controller','PID', 'P','Kp', 'I','Ki', 'D','Kd', 'N','Nf', ...
          'LimitOutput','on', ...
          'UpperSaturationLimit','X_hi', 'LowerSaturationLimit','X_lo', ...
          'AntiWindupMode','back-calculation', 'Kb','K_aw', ...
          'Position',[380 580 500 670]);
set_param([c '/PID block'], 'BackgroundColor', gnc_colour('controller'));

add_block('simulink/Sources/Constant', [c '/pid_mode'], ...
          'Value','pid_mode', 'Position',[690 700 745 730]);
add_block('simulink/Signal Routing/Switch', [c '/hand or block'], ...
          'Threshold','0.5', 'Position',[790 150 820 620]);

add_block('simulink/Signal Routing/Switch', [c '/open or closed'], ...
          'Threshold','0.5', 'Position',[950 160 980 500]);

set_param([c '/u_d'],   'Position',[ 50  83  80  97]);
set_param([c '/x'],     'Position',[ 50 143  80 157]);
set_param([c '/X_sat'], 'Position',[ 50 293  80 307]);
set_param([c '/X_cmd'], 'Position',[1060 293 1090 307]);
%  The integrator state is logged, not used, so it leaves along the top where
%  it crosses nothing. Taken straight across it would be drawn through both
%  switches.
set_param([c '/I'],     'Position',[1060  40 1090  54]);

Lc = @(x,y) add_line(c, x, y, 'autorouting','on');
Lc('x/1','u/1');
Lc('u_d/1','error/1');   Lc('u/1','error/2');
Lc('error/1','Kp/1');
Lc('error/1','anti-windup/1');

%  Ports 3 to 6 of the anti-windup block are fed from blocks that exist only
%  to feed them, so each is moved onto its own port's row and the connection
%  becomes one straight line. Ports 1 and 2 come from elsewhere in the diagram
%  and are wired above and below.
row_feed(c, 'anti-windup', [{'',''} {'X_sat'} AW]);

lane_line(c, 'anti-windup', 1, 'I state', 1, 570);
Lc('u/1','D filter/1');
lane_line(c, 'Kp',       1, 'X_pid', 1, 645);
lane_line(c, 'I state',  1, 'X_pid', 2, 660);
lane_line(c, 'D filter', 1, 'X_pid', 3, 480);

Lc('error/1','PID block/1');

%  The two switches choose between whole paths. Only their SELECTOR constants
%  may be moved onto a row - row_feed moves the blocks it is given, and moving
%  the PID block would drag it out of the column it belongs to and on top of
%  the hand-built path it is there to be compared with.
row_feed(c, 'hand or block',  {'','pid_mode',''});
lane_line(c, 'PID block', 1, 'hand or block', 1, 755);
lane_line(c, 'X_pid',     1, 'hand or block', 3, 770);
row_feed(c, 'open or closed', {'','loop_closed','X_open'});
lane_line(c, 'hand or block', 1, 'open or closed', 1, 930);
Lc('open or closed/1','X_cmd/1');
lane_line(c, 'I state', 1, 'I', 1, 745);

%  THE ONE LINE THAT RUNS RIGHT TO LEFT. The saturated command goes back to
%  the integrator to tell it the loop has been opened, and that is the whole
%  subject of 2-6. It is taken round the bottom of the subsystem on a height
%  of its own rather than back across the middle of it, where it would be
%  drawn along the lines it is meant to be distinguished from.
qa = port_xy(c, 'open or closed', 'Outport', 1);
qb = port_xy(c, 'anti-windup',    'Inport',  2);
add_line(c, [qa; 1020 qa(2); 1020 780; 350 780; 350 qb(2); qb]);

%% =====================================================================
%  3. Control allocation
%  =====================================================================
a = add_subsys(m, 'Control allocation', P.allocation, ...
               {'X_cmd'}, {'n','X_sat','n1'}, gnc_colour('allocation'));

blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[260 60 430 270]);
set_mlfcn(blk, { ...
'function [n, X_sat] = allocation(X_cmd, k_pos, k_neg, n_max, n_min)'
'%#codegen'
'% Demanded surge force to shaft speed, and back again.'
'%'
'% The demand is split equally between the two propellers, because nothing in'
'% a pure surge command distinguishes them. Inverting T = k n|n| gives'
'%'
'%     n = sign(T) sqrt(|T| / k)'
'%'
'% X_sat is what the propellers ACTUALLY produce after saturation. Without it'
'% the controller cannot know that the loop has been opened by the actuator,'
'% and no anti-windup scheme can work.'
'T = X_cmd / 2;'
'if T >= 0'
'    ni =  sqrt( T / k_pos);'
'else'
'    ni = -sqrt(-T / k_neg);'
'end'
'ni = min(max(ni, n_min), n_max);'
'n = [ni; ni];'
'if ni >= 0'
'    X_sat = 2 * k_pos * ni * abs(ni);'
'else'
'    X_sat = 2 * k_neg * ni * abs(ni);'
'end'
'end'}, 'n', '[2 1]');

for i = 1:4
    add_block('simulink/Sources/Constant', [a '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 95+50*i 165 121+50*i]);
end
add_block('simulink/Signal Routing/Selector', [a '/first shaft'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','1', ...
          'InputPortWidth','2', 'Position',[510 260 560 280]);

set_param([a '/X_cmd'], 'Position',[ 60  95  90 115]);
set_param([a '/n'],     'Position',[630 100 660 120]);
set_param([a '/X_sat'], 'Position',[630 185 660 205]);
set_param([a '/n1'],    'Position',[630 260 660 280]);

La = @(x,y) add_line(a, x, y, 'autorouting','on');
La('X_cmd/1','allocation/1');
for i = 1:4, La([KK{i} '/1'], sprintf('allocation/%d', i+1)); end
La('allocation/1','n/1');
La('allocation/1','first shaft/1');
La('first shaft/1','n1/1');
La('allocation/2','X_sat/1');

%% =====================================================================
%  4. Otter USV
%  =====================================================================
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% =====================================================================
%  5. Measurements
%  =====================================================================
add_measurement(m, P.measurement, 'W02', {'u_d','X_cmd','X_sat','I','n1'}, ...
                struct('dash', true, 'weekName', 'W02  command and force'));

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Speed command/1',     'Surge controller/1');
L('Otter USV/1',         'Surge controller/2');
L('Control allocation/2','Surge controller/3');

L('Surge controller/1',  'Control allocation/1');
L('Control allocation/1','Otter USV/1');

L('Otter USV/1',         'Measurements/1');
L('Speed command/1',     'Measurements/2');
L('Surge controller/1',  'Measurements/3');
L('Control allocation/2','Measurements/4');
L('Surge controller/2',  'Measurements/5');
L('Control allocation/3','Measurements/6');

%% ---- what the model is for ---------------------------------------------
note(m, [40 340 880 720], strjoin({ ...
'WEEK 2  -  SURGE SPEED CONTROL'
''
'The first closed loop of the course. The surge axis is a first-order,'
'TYPE 0 plant:  u/X = K_u / (tau_u s + 1),  K_u = 0.012894, tau_u = 1.1025 s.'
''
'FOUR THINGS TO TRY'
''
'1  IDENTIFY THE PLANT.  loop_closed = 0, X_open = 100. Read the settled u'
'   and the 63 per cent time. They are K_u X_open and tau_u.'
''
'2  PROPORTIONAL ONLY.  Ki = 0, Kd = 0. A type 0 plant under proportional'
'   control ALWAYS leaves a steady-state error:'
''
'        u_ss / u_d = K_p K_u / (1 + K_p K_u).'
''
'   Kp = 100 leaves 44 per cent. Kp = 2000 leaves 3.7 per cent and still'
'   does not arrive. Raising the gain does not remove the error.'
''
'3  ADD THE INTEGRATOR.  Ki = 192.38 with Kp = 102 places the closed-loop'
'   poles at zeta = 0.7, wn = 1.5 rad/s. The error goes to zero exactly.'
'   The overshoot does NOT match the textbook figure for zeta = 0.7,'
'   because a PI controller also adds a ZERO at s = -Ki/Kp.'
''
'4  SATURATE IT.  u_d1 = 3.5 m/s is not reachable: full ahead gives'
'   exactly 3.0864 m/s. Set t_dn = 40, u_d2 = 1.5, T_final = 90 and'
'   compare aw_mode = 0, 1, 2.'
''
'X_sat is the second feedback path, and it is the one that gets missed.'
'Without knowing what the propellers ACTUALLY delivered, no anti-windup'
'scheme can tell that the loop has been opened by the actuator.'}, newline));

%% ---- plot when the run finishes ----------------------------------------
set_param(m, 'StopFcn', 'W02_plot;');
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
