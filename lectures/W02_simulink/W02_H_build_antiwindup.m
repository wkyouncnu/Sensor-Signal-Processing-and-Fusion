function W02_H_build_antiwindup()
%BUILD_W02_ANTIWINDUP  Generate W02_H_antiwindup.slx — the principle, on its own.
%
%   >> W02_H_build_antiwindup
%
%   WHY A SECOND MODEL
%
%   W02_surge_control.slx shows windup on the vessel, where the plant is twelve states,
%   the saturation is a square-law propeller curve and the setpoint is a speed.
%   None of that is the point. The point is a first-order plant, a limit, and
%   an integrator that does not know about the limit.
%
%   This model removes everything else:
%
%       G(s) = 1 / (s + 1),      u in [-1, +1],      PI control
%
%   With a DC gain of 1 and |u| <= 1, the largest reachable output is y = 1.
%   The reference is stepped to 2, which cannot be reached, held, and then
%   dropped to 0.5, which can. Everything this week says about windup is
%   visible in that one profile.
%
%   FOUR CONTROLLERS, ONE PLANT EACH
%
%     1  Simulink PID block, anti-windup = none
%     2  Simulink PID block, anti-windup = clamping
%     3  Simulink PID block, anti-windup = back-calculation, gain Kb
%     4  the same back-calculation built by hand, so the integrator state is
%        a signal that can be plotted
%
%   Rows 3 and 4 must agree. That agreement is what licenses the claim that
%   the library block is doing what §2-6 says it does.
%
%   Regenerating is safe: any existing W02_H_antiwindup.slx is overwritten.

m    = 'W02_H_antiwindup';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);
addpath(fullfile(root,'_tools'), here);

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','aw_T');

P = gnc_chain({'command','controller','plant','measurement'}, ...
              'Height', struct('controller',150, 'plant',120, 'measurement',120), ...
              'Y', 110);

LBL = {'none','clamping','back-calculation','by hand'};

%% =====================================================================
%  1. Reference
%  =====================================================================
s = add_subsys(m, 'Reference', P.command, {}, {'r'}, gnc_colour('command'));
add_block('simulink/Sources/Step', [s '/up'], ...
          'Time','aw_t1', 'Before','0', 'After','aw_r1', 'Position',[100 60 140 100]);
add_block('simulink/Sources/Step', [s '/down'], ...
          'Time','aw_t2', 'Before','0', 'After','aw_r2 - aw_r1', ...
          'Position',[100 140 140 180]);
add_sum(s, 'sum', '++', [262 120]);
set_param([s '/r'], 'Position',[380 110 410 130]);
add_line(s, 'up/1','sum/1','autorouting','on');
add_line(s, 'down/1','sum/2','autorouting','on');
add_line(s, 'sum/1','r/1','autorouting','on');

%% =====================================================================
%  2. PID bank — the same gains four times, four anti-windup schemes
%  =====================================================================
c = add_subsys(m, 'PID bank', P.controller, {'r','y'}, {'u','I by hand'}, ...
               gnc_colour('controller'));
set_param([c '/r'], 'Position',[ 40  90  70 110]);
set_param([c '/y'], 'Position',[ 40 400  70 420]);
set_param([c '/u'],           'Position',[900 240 930 260]);
set_param([c '/I by hand'],   'Position',[900 640 930 660]);

%  The four rows are 170 px apart at y = 80, 250, 420 and 590. A Demux or Mux
%  with n ports spaces them H/n apart with the first half a pitch below the
%  top, so H = 680 puts four ports on those four rows.
%
%  The Demux is offset 60 px BELOW the rows on purpose. Its four lines end at
%  the bottom input of a summing junction, and the reference reaches the left
%  input of the same junction along the row itself: sharing the row would draw
%  the two on top of each other over the last hundred pixels.
add_block('simulink/Signal Routing/Demux', [c '/split y'], ...
          'Outputs','4', 'Position',[130 55 135 735]);
add_line(c, 'y/1','split y/1','autorouting','on');
q = port_xy(c, 'split y', 'Inport', 1);
set_param([c '/y'], 'Position',[40 q(2)-10 70 q(2)+10]);

add_block('simulink/Signal Routing/Mux', [c '/collect u'], ...
          'Inputs','4', 'Position',[820 -5 825 675]);
add_line(c, 'collect u/1','u/1','autorouting','on');
q = port_xy(c, 'collect u', 'Outport', 1);
set_param([c '/u'], 'Position',[900 q(2)-10 930 q(2)+10]);

MODES = {'none','clamping','back-calculation'};
for i = 1:3
    yb = 60 + 170*(i-1);
    add_sum(c, ['e' num2str(i)], '+-', [252 yb+20]);
    add_block('simulink/Continuous/PID Controller', [c '/PID ' MODES{i}], ...
              'Controller','PI', 'P','aw_Kp', 'I','aw_Ki', ...
              'LimitOutput','on', ...
              'UpperSaturationLimit','aw_umax', 'LowerSaturationLimit','aw_umin', ...
              'AntiWindupMode', MODES{i}, 'Kb','aw_Kb', ...
              'Position',[400 yb-25 520 yb+65]);
    add_line(c, 'r/1', sprintf('e%d/1', i), 'autorouting','on');
    add_line(c, sprintf('split y/%d', i), sprintf('e%d/2', i), 'autorouting','on');
    add_line(c, sprintf('e%d/1', i), ['PID ' MODES{i} '/1'], 'autorouting','on');
    add_line(c, ['PID ' MODES{i} '/1'], sprintf('collect u/%d', i), 'autorouting','on');
end

%  ---- the fourth, built by hand ---------------------------------------
%  Identical to row 3 in every respect except that the integrator is a block
%  and its state is therefore a signal that can be plotted. Everything §2-6
%  claims about back-calculation is visible in this one path.
add_sum(c, 'e4', '+-', [252 590]);
add_line(c, 'r/1','e4/1','autorouting','on');
add_line(c, 'split y/4','e4/2','autorouting','on');

add_block('simulink/Math Operations/Gain', [c '/Kp'], 'Gain','aw_Kp', ...
          'Position',[330 500 380 540]);
add_block('simulink/Math Operations/Gain', [c '/Ki'], 'Gain','aw_Ki', ...
          'Position',[330 620 380 660]);
add_block('simulink/Math Operations/Gain', [c '/Kb'], 'Gain','aw_Kb', ...
          'Position',[420 760 470 800]);
add_sum(c, 'into I', '+-', [512 660]);
add_block('simulink/Continuous/Integrator', [c '/I'], ...
          'InitialCondition','0', 'Position',[570 640 605 675]);
add_sum(c, 'u4', '++', [672 590]);
add_block('simulink/Discontinuities/Saturation', [c '/limit'], ...
          'UpperLimit','aw_umax', 'LowerLimit','aw_umin', ...
          'Position',[730 550 770 590]);
add_sum(c, 'excess', '+-', [632 780]);

add_line(c, 'e4/1','Kp/1','autorouting','on');
add_line(c, 'e4/1','Ki/1','autorouting','on');
add_line(c, 'Ki/1','into I/1','autorouting','on');
add_line(c, 'Kb/1','into I/2','autorouting','on');
add_line(c, 'into I/1','I/1','autorouting','on');
add_line(c, 'Kp/1','u4/1','autorouting','on');
add_line(c, 'I/1','u4/2','autorouting','on');
add_line(c, 'u4/1','limit/1','autorouting','on');
add_line(c, 'u4/1','excess/1','autorouting','on');
add_line(c, 'limit/1','excess/2','autorouting','on');
add_line(c, 'excess/1','Kb/1','autorouting','on');
add_line(c, 'limit/1','collect u/4','autorouting','on');
add_line(c, 'I/1','I by hand/1','autorouting','on');

note_in(c, [40 850 900 1010], strjoin({ ...
'THE HAND-BUILT PATH, ROW 4'
''
'    u     = Kp e + I                 what the controller wants'
'    u_sat = sat(u)                   what the actuator gives'
'    I_dot = Ki e - Kb (u - u_sat)    what the integrator is told'
''
'The last line is the whole of back-calculation. While the actuator is'
'not saturated, u = u_sat, the second term is zero, and the integrator'
'behaves as an integrator. The moment the actuator saturates, the term'
'switches on and pulls the integrator back in proportion to how far'
'outside the limit the demand has gone.'
''
'Rows 3 and 4 must agree. If they do not, one of them is wrong.'}, newline));

%% =====================================================================
%  3. Plant bank — four copies of the same first-order plant
%  =====================================================================
p = add_subsys(m, 'Plant bank', P.plant, {'u'}, {'y'}, gnc_colour('plant'));
set_param([p '/u'], 'Position',[ 40 240  70 260]);
set_param([p '/y'], 'Position',[600 240 630 260]);
add_block('simulink/Signal Routing/Demux', [p '/split'], ...
          'Outputs','4', 'Position',[140 170 145 330]);
add_block('simulink/Signal Routing/Mux', [p '/collect'], ...
          'Inputs','4', 'Position',[500 170 505 330]);
add_line(p, 'u/1','split/1','autorouting','on');
add_line(p, 'collect/1','y/1','autorouting','on');
for i = 1:4
    yb = 130 + 90*(i-1);
    add_block('simulink/Continuous/Transfer Fcn', [p '/G' num2str(i)], ...
              'Numerator','[1]', 'Denominator','[1 1]', ...
              'Position',[250 yb 370 yb+50]);
    add_line(p, sprintf('split/%d', i), sprintf('G%d/1', i), 'autorouting','on');
    add_line(p, sprintf('G%d/1', i), sprintf('collect/%d', i), 'autorouting','on');
end

%% =====================================================================
%  4. Measurements
%  =====================================================================
%  log = [r  u(1:4)  y(1:4)  I_by_hand]
q = add_subsys(m, 'Measurements', P.measurement, {'r','u','y','I'}, {}, ...
               gnc_colour('measurement'));
set_param([q '/r'], 'Position',[ 40  60  70  80]);
set_param([q '/u'], 'Position',[ 40 140  70 160]);
set_param([q '/y'], 'Position',[ 40 220  70 240]);
set_param([q '/I'], 'Position',[ 40 300  70 320]);
add_block('simulink/Signal Routing/Mux', [q '/log'], ...
          'Inputs','4', 'Position',[220 50 225 330]);
add_block('simulink/Sinks/To Workspace', [q '/W02aw'], ...
          'VariableName','W02aw', 'SaveFormat','Structure With Time', ...
          'Position',[300 175 400 210]);
add_block('simulink/Sinks/Scope', [q '/y and u'], 'Position',[300 60 340 100]);
add_block('simulink/Signal Routing/Mux', [q '/show'], ...
          'Inputs','2', 'Position',[220 -60 225 40]);
QIN = {'r','u','y','I'};
%  Each inport on the row of the Mux port it feeds; the two scope feeds get a
%  lane each, so they cannot be drawn on top of one another.
row_feed(q, 'log', QIN);
add_line(q, 'log/1','W02aw/1','autorouting','on');
lane_line(q, 'r', 1, 'show', 1, 140);
lane_line(q, 'y', 1, 'show', 2, 160);
add_line(q, 'show/1','y and u/1','autorouting','on');
set_param([q '/y and u'], 'Open', 'on');

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Reference/1',  'PID bank/1');
L('Plant bank/1', 'PID bank/2');
L('PID bank/1',   'Plant bank/1');
L('Reference/1',  'Measurements/1');
L('PID bank/1',   'Measurements/2');
L('Plant bank/1', 'Measurements/3');
L('PID bank/2',   'Measurements/4');

%% ---- what the model is for ---------------------------------------------
note(m, [40 300 900 690], strjoin({ ...
'WEEK 2, THE ANTI-WINDUP PRINCIPLE ON ITS OWN'
''
'No vessel, no propellers, no twelve states. A first-order plant, a'
'limit, and an integrator that does not know about the limit:'
''
'        G(s) = 1 / (s + 1),     u in [-1, +1],     PI control.'
''
'The DC gain is 1 and |u| <= 1, so the largest reachable output is'
'y = 1. The reference is stepped to 2, which CANNOT be reached, held,'
'and then dropped to 0.5, which can.'
''
'FOUR CONTROLLERS, IDENTICAL GAINS, ONE PLANT EACH'
''
'   1  Simulink PID block,  anti-windup = none'
'   2  Simulink PID block,  anti-windup = clamping'
'   3  Simulink PID block,  anti-windup = back-calculation, gain Kb'
'   4  the same back-calculation built by hand'
''
'Rows 3 and 4 must agree to machine precision. That agreement is what'
'licenses the claim that the library block does what the theory says.'
''
'WHAT TO WATCH'
''
'Not the rise to y = 1 - all four are identical there. Watch what'
'happens AFTER t = 15 s, when the reference becomes reachable again.'
'Row 1 sits at y = 1 for several seconds doing nothing, because the'
'integrator has to unwind a charge it should never have accumulated.'
''
'Then open PID bank and read the annotation on row 4.'}, newline));

set_param(m, 'StopFcn', 'W02_aw_plot;');
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
h.Text = txt;  h.Position = pos;
h.HorizontalAlignment = 'left';  h.BackgroundColor = 'lightBlue';
end

function note_in(sub, pos, txt)
h = Simulink.Annotation([sub '/how']);
h.Text = txt;  h.Position = pos;
h.HorizontalAlignment = 'left';  h.BackgroundColor = 'lightBlue';
end
