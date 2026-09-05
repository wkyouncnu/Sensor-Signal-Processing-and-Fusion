function W02_I_build_pseudo_derivative()
%BUILD_W02_PSEUDO  Generate W02_I_pseudo_derivative.slx — why a PID never differentiates directly.
%
%   >> W02_I_build_pseudo_derivative
%
%   WHY A THIRD MODEL
%
%   Section 2-4 writes the derivative term as
%
%       D(s) = -Kd * N s / (s + N)   acting on the measurement,
%
%   and calls the filter a detail. It is not a detail. On the surge axis the
%   derivative term is harmful anyway (it adds mass), so nothing there shows
%   what the filter is FOR. This model uses a plant where derivative action is
%   genuinely wanted, and then shows what happens when the derivative is taken
%   honestly.
%
%       G(s) = 1 / (s^2 + 0.4 s)
%
%   A position output with almost no damping. Proportional control alone gives
%   zeta = 0.2/sqrt(Kp) - at Kp = 4 that is zeta = 0.1, which rings for a long
%   time. Derivative action is the cure, so the question "how do we take the
%   derivative" becomes a real question rather than an academic one.
%
%   FOUR CONTROLLERS, ONE PLANT EACH, ONE SHARED NOISE SOURCE
%
%     1  P only                        no derivative at all - the disease
%     2  ideal derivative,  du/dt      the naive cure
%     3  pseudo-derivative, N = pd_N1  a fast filter
%     4  pseudo-derivative, N = pd_N2  a slower filter
%
%   All four see THE SAME measurement noise. That is what makes the comparison
%   honest: any difference in the control signal is caused by the derivative
%   implementation and by nothing else.
%
%   WHAT THE MODEL IS MEANT TO SHOW
%
%   Row 2 damps the response beautifully and produces a control signal that is
%   unusable. Differentiation has gain |jw| - it grows without bound with
%   frequency - so it takes the smallest, fastest component of the measurement,
%   the noise, and multiplies it by the largest number in the problem. Rows 3
%   and 4 replace s by the pseudo-derivative N s /(s + N), whose gain levels
%   off at N, and buy back a usable actuator signal for a little phase lag.
%
%   Regenerating is safe: any existing W02_I_pseudo_derivative.slx is overwritten.

m    = 'W02_I_pseudo_derivative';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);
addpath(fullfile(root,'_tools'), here);

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','pd_T');

P = gnc_chain({'command','controller','plant','measurement'}, ...
              'Height', struct('controller',170, 'plant',150, 'measurement',130), ...
              'Y', 110);

%% =====================================================================
%  1. Reference — one step, nothing more
%  =====================================================================
s = add_subsys(m, 'Reference', P.command, {}, {'r'}, gnc_colour('command'));
add_block('simulink/Sources/Step', [s '/step'], ...
          'Time','pd_t1', 'Before','0', 'After','pd_r', ...
          'Position',[120 100 160 140]);
set_param([s '/r'], 'Position',[300 110 330 130]);
add_line(s, 'step/1','r/1','autorouting','on');

%% =====================================================================
%  2. Controller bank — four ways of taking one derivative
%  =====================================================================
%  Every row is  u = Kp e - (derivative term acting on y).
%  The derivative acts on the MEASUREMENT, never on the error, for the reason
%  given in 2-4: a step in r would otherwise be differentiated into an impulse.
c = add_subsys(m, 'Controller bank', P.controller, {'r','y'}, {'u','d term'}, ...
               gnc_colour('controller'));
set_param([c '/r'],      'Position',[ 40  90  70 110]);
set_param([c '/y'],      'Position',[ 40 310  70 330]);
set_param([c '/u'],      'Position',[980 310 1010 330]);
set_param([c '/d term'], 'Position',[980 708 1010 728]);

%  The four rows sit at y = 80, 240, 400 and 560. The Demux that feeds them
%  and the two Muxes that collect them are sized so that THEIR ports land on
%  those same four heights: four ports on a block of height H are (H-40)/3
%  apart, so H = 520 gives 160, which is the row pitch. Every one of those
%  twelve connections is then a single straight segment.
add_block('simulink/Signal Routing/Mux', [c '/collect u'], ...
          'Inputs','4', 'Position',[900 60 905 580]);
add_line(c, 'collect u/1','u/1','autorouting','on');

%  The derivative terms cannot be collected on the rows as well - a horizontal
%  along a row would be drawn straight through that row's summing junction -
%  so they are taken below the bank, each down a lane of its own.
add_block('simulink/Signal Routing/Mux', [c '/collect d'], ...
          'Inputs','4', 'Position',[900 620 905 816]);
add_line(c, 'collect d/1','d term/1','autorouting','on');
DL = [700 720 740 760];                 % one lane per derivative term

%  The rows are READ from the Mux, not calculated. A Mux insets its first and
%  last port by 21 px and spreads the rest evenly, so a height chosen to give a
%  round pitch gives a fractional one instead and every row line comes out as a
%  shallow diagonal. Reading the ports makes the arithmetic the block's problem.
%
%  Two heights per row. The proportional path runs along the row itself; the
%  derivative path runs 70 px below it and comes back up into the bottom input
%  of the summing junction. Putting both on the row would draw the derivative
%  blocks on top of the proportional line, which is what a diagram must never
%  do: one line, one meaning.
ROW = zeros(1,4);
for i = 1:4
    q      = port_xy(c, 'collect u', 'Inport', i);
    ROW(i) = q(2);
end
YR = @(i) ROW(i);                       % proportional row
YD = @(i) ROW(i) + 70;                  % derivative row

%  The Demux is put on the DERIVATIVE rows and not on the proportional ones.
%  Its four outputs each feed two places - the summing junction on the row
%  above and the derivative block on the row itself - and a source sitting on
%  the proportional row would have to run along it, on top of the line from
%  that row's Kp gain. On the derivative row nothing else is in the way.
%
%  Its port rule is its own: n ports at top + H(2k-1)/(2n), so the pitch is
%  H/n and the first port is half a pitch below the top.
dp = ROW(2) - ROW(1);
add_block('simulink/Signal Routing/Demux', [c '/split y'], 'Outputs','4', ...
          'Position',[130 YD(1)-dp/2 135 YD(1)-dp/2+4*dp]);
add_line(c, 'y/1','split y/1','autorouting','on');
q = port_xy(c, 'split y', 'Inport', 1);
set_param([c '/y'], 'Position', [40 q(2)-10 70 q(2)+10]);

for i = 1:4
    add_sum(c, ['e' num2str(i)], '+-', [242 YR(i)]);
    add_block('simulink/Math Operations/Gain', [c '/Kp' num2str(i)], ...
              'Gain','pd_Kp', 'Position',[320 YR(i)-20 370 YR(i)+20]);
    add_sum(c, ['u' num2str(i)], '+-', [812 YR(i)]);
    add_line(c, 'r/1', sprintf('e%d/1', i), 'autorouting','on');
    lane_line(c, 'split y', i, sprintf('e%d', i), 2, 0);
    add_line(c, sprintf('e%d/1', i), sprintf('Kp%d/1', i));
    add_line(c, sprintf('Kp%d/1', i), sprintf('u%d/1', i));
    add_line(c, sprintf('u%d/1', i), sprintf('collect u/%d', i));
end

%  ---- row 1: no derivative at all --------------------------------------
%  A zero keeps the four rows structurally identical, so the only difference
%  between them is the block sitting in the derivative slot.
add_block('simulink/Sources/Constant', [c '/no D'], ...
          'Value','0', 'Position',[630 YD(1)-20 690 YD(1)+20]);
lane_line(c, 'no D', 1, 'u1', 2, 0);
lane_line(c, 'no D', 1, 'collect d', 1, DL(1));

%  ---- row 2: the ideal derivative --------------------------------------
add_block('simulink/Continuous/Derivative', [c '/du_dt'], ...
          'Position',[490 YD(2)-20 550 YD(2)+20]);
add_block('simulink/Math Operations/Gain', [c '/Kd2'], ...
          'Gain','pd_Kd', 'Position',[630 YD(2)-20 690 YD(2)+20]);
add_line(c, 'split y/2','du_dt/1');
add_line(c, 'du_dt/1','Kd2/1');
lane_line(c, 'Kd2', 1, 'u2', 2, 0);
lane_line(c, 'Kd2', 1, 'collect d', 2, DL(2));

%  ---- rows 3 and 4: the pseudo-derivative ------------------------------
%  Kd N s / (s + N). Numerator [N 0], denominator [1 N]. As N goes to
%  infinity this becomes Kd s, so the ideal derivative is the limiting case
%  of the filter and not a different animal.
NAMES = {'N1','N2'};
for k = 1:2
    i  = k + 2;
    add_block('simulink/Continuous/Transfer Fcn', [c '/pseudo ' NAMES{k}], ...
              'Numerator',['[pd_' NAMES{k} ' 0]'], 'Denominator',['[1 pd_' NAMES{k} ']'], ...
              'Position',[490 YD(i)-30 550 YD(i)+30]);
    add_block('simulink/Math Operations/Gain', [c '/Kd' num2str(i)], ...
              'Gain','pd_Kd', 'Position',[630 YD(i)-20 690 YD(i)+20]);
    add_line(c, sprintf('split y/%d', i), ['pseudo ' NAMES{k} '/1']);
    add_line(c, ['pseudo ' NAMES{k} '/1'], sprintf('Kd%d/1', i));
    lane_line(c, sprintf('Kd%d', i), 1, sprintf('u%d', i), 2, 0);
    lane_line(c, sprintf('Kd%d', i), 1, 'collect d', i, DL(i));
end

note_in(c, [40 880 960 1090], strjoin({ ...
'FOUR WAYS TO TAKE ONE DERIVATIVE'
''
'   row 1   u = Kp e                          no derivative'
'   row 2   u = Kp e - Kd  s        y         ideal'
'   row 3   u = Kp e - Kd  N1 s/(s+N1)  y     pseudo, fast filter'
'   row 4   u = Kp e - Kd  N2 s/(s+N2)  y     pseudo, slower filter'
''
'The derivative acts on y and not on e, so a step in r is never'
'differentiated. That is a separate question from the filter and is'
'settled the same way in all four rows.'
''
'GAIN AGAINST FREQUENCY'
''
'   ideal        |Kd jw|            grows without bound'
'   pseudo       |Kd N jw/(jw+N)|   rises, then levels off at Kd N'
''
'Below N the two agree. Above N the ideal keeps climbing and the pseudo'
'stops. Measurement noise lives above N, which is the whole point:'
'N chooses how much of the noise reaches the actuator.'}, newline));

%% =====================================================================
%  3. Plant bank — four identical plants, ONE shared noise source
%  =====================================================================
%  The noise must be shared. Four independent noise sources would make the
%  four control signals differ for two reasons at once, and the comparison
%  would prove nothing.
p = add_subsys(m, 'Plant bank', P.plant, {'u'}, {'y','y clean'}, gnc_colour('plant'));
%  Same rule as the controller bank: the Mux defines the four rows, the Demux
%  is sized to match them, and the clean outputs are taken away below.
set_param([p '/u'],       'Position',[ 40 270  70 290]);
set_param([p '/y'],       'Position',[800 270 830 290]);
set_param([p '/y clean'], 'Position',[800 588 830 608]);

add_block('simulink/Signal Routing/Mux', [p '/collect'], ...
          'Inputs','4', 'Position',[680 125 685 435]);
%  The clean outputs are taken BELOW the bank, each down a lane of its own,
%  for the same reason as the derivative terms: a second line along a row
%  would run through that row's summing junction.
add_block('simulink/Signal Routing/Mux', [p '/collect clean'], ...
          'Inputs','4', 'Position',[740 500 745 696]);
CL = [395 410 425 440];                 % one lane per clean output
add_line(p, 'collect/1','y/1');
add_line(p, 'collect clean/1','y clean/1');

add_block('simulink/Sources/Band-Limited White Noise', [p '/sensor noise'], ...
          'Cov','pd_noise', 'Ts','pd_ts', 'seed','[23341]', ...
          'Position',[180 620 240 670]);

%  Rows read from the Mux, and the Demux sized to match, exactly as in the
%  controller bank.
PROW = zeros(1,4);
for i = 1:4
    q       = port_xy(p, 'collect', 'Inport', i);
    PROW(i) = q(2);
end
pp = PROW(2) - PROW(1);
add_block('simulink/Signal Routing/Demux', [p '/split'], 'Outputs','4', ...
          'Position',[130 PROW(1)-pp/2 135 PROW(1)-pp/2+4*pp]);
add_line(p, 'u/1','split/1');

%  The two ports of this subsystem sit on the rows of the blocks they touch.
q = port_xy(p, 'split',   'Inport',  1);  set_param([p '/u'], 'Position',[ 40 q(2)-10  70 q(2)+10]);
q = port_xy(p, 'collect', 'Outport', 1);  set_param([p '/y'], 'Position',[800 q(2)-10 830 q(2)+10]);
q = port_xy(p, 'collect clean', 'Outport', 1);
set_param([p '/y clean'], 'Position',[800 q(2)-10 830 q(2)+10]);

for i = 1:4
    yb = PROW(i) - 25;
    add_block('simulink/Continuous/Transfer Fcn', [p '/G' num2str(i)], ...
              'Numerator','[1]', 'Denominator','[1 0.4 0]', ...
              'Position',[250 yb 370 yb+50]);
    add_sum(p, ['n' num2str(i)], '++', [482 PROW(i)]);
    add_line(p, sprintf('split/%d', i), sprintf('G%d/1', i));
    add_line(p, sprintf('G%d/1', i), sprintf('n%d/1', i));
    add_line(p, 'sensor noise/1', sprintf('n%d/2', i), 'autorouting','on');
    add_line(p, sprintf('n%d/1', i), sprintf('collect/%d', i));
    lane_line(p, sprintf('G%d', i), 1, 'collect clean', i, CL(i));
end

note_in(p, [130 720 700 860], strjoin({ ...
'G(s) = 1 / (s^2 + 0.4 s)'
''
'Almost no damping of its own. With proportional control alone the'
'closed loop is s^2 + 0.4 s + Kp, so zeta = 0.2/sqrt(Kp), which is'
'0.1 at Kp = 4. Derivative action is genuinely needed here, unlike'
'on the surge axis of 2-4 where it only added mass.'
''
'The noise is added to the OUTPUT, where a sensor would add it, and'
'the same realisation goes to all four rows.'}, newline));

%% =====================================================================
%  4. Measurements
%  =====================================================================
%  log = [r  u(1:4)  y_clean(1:4)  d_term(1:4)]   -> 13 columns
q = add_subsys(m, 'Measurements', P.measurement, {'r','u','y','d'}, {}, ...
               gnc_colour('measurement'));
QIN = {'r','u','y','d'};
add_block('simulink/Signal Routing/Mux', [q '/log'], ...
          'Inputs','4', 'Position',[220 100 225 380]);
add_block('simulink/Sinks/To Workspace', [q '/W02pd'], ...
          'VariableName','W02pd', 'SaveFormat','Structure With Time', ...
          'Position',[300 220 400 255]);
add_block('simulink/Sinks/Scope', [q '/y and u'], 'Position',[300 100 340 140]);
add_block('simulink/Signal Routing/Mux', [q '/show'], ...
          'Inputs','2', 'Position',[220 -20 225 80]);
%  Each logged inport on the row of the Mux port it feeds.
row_feed(q, 'log', QIN);
add_line(q, 'log/1','W02pd/1','autorouting','on');
lane_line(q, 'r', 1, 'show', 1, 140);
lane_line(q, 'u', 1, 'show', 2, 160);
add_line(q, 'show/1','y and u/1','autorouting','on');
set_param([q '/y and u'], 'Open', 'on');

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Reference/1',        'Controller bank/1');
L('Controller bank/1',  'Plant bank/1');
L('Plant bank/1',       'Controller bank/2');      % measured y, with noise
L('Reference/1',        'Measurements/1');
L('Controller bank/1',  'Measurements/2');
L('Plant bank/2',       'Measurements/3');         % clean y, for the plots
L('Controller bank/2',  'Measurements/4');

%% ---- what the model is for ---------------------------------------------
note(m, [40 330 900 700], strjoin({ ...
'WEEK 2, SECTION I  -  THE PSEUDO-DERIVATIVE'
''
'A PID controller never contains a differentiator. This model shows why,'
'on a plant where derivative action is actually wanted.'
''
'   G(s) = 1 / (s^2 + 0.4 s)      zeta = 0.1 under P control alone'
''
'FOUR ROWS, SAME GAINS, SAME NOISE'
''
'   1  P only                     rings, but the actuator is quiet'
'   2  Kd s          ideal        damps well, actuator unusable'
'   3  Kd N1 s/(s+N1)  pseudo     N1 large - still noisy'
'   4  Kd N2 s/(s+N2)  pseudo     N2 small - quiet, slightly slower'
''
'THE MECHANISM'
''
'Differentiation has gain |w|: it multiplies every component of the'
'signal by its own frequency. Noise is the fastest thing in the'
'measurement, so differentiation finds it and amplifies it more than'
'anything else. The pseudo-derivative is the same operator with its'
'gain capped at N, so N is the knob that decides how much of the'
'noise reaches the actuator.'
''
'The cost is phase lag below N. Choosing N is therefore a trade, and'
'the runner measures both sides of it.'
''
'Edit pd_Kp, pd_Kd, pd_N1, pd_N2 and pd_noise in W02_0_setup.m.'}, newline));

set_param(m, 'StopFcn', 'W02_pd_plot;');
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
h = Simulink.Annotation([sub '/note']);
h.Text = txt;  h.Position = pos;
h.HorizontalAlignment = 'left';  h.BackgroundColor = 'white';
end
