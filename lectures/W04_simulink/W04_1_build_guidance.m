function W04_1_build_guidance()
%W04_1_BUILD_GUIDANCE  Generate W04_guidance.slx from code.
%
%   >> W04_1_build_guidance
%
%   FOUR VESSELS, ONE MISSION
%
%   Four identical Otters run the same waypoint list at the same time, in the
%   same current, under the same heading autopilot. They differ in ONE thing:
%   which guidance law turns the waypoint list into a heading command.
%
%     row 1   atan2      aim straight at the next waypoint
%     row 2   LOS        aim at a point Delta ahead ON THE PATH
%     row 3   ILOS       LOS, plus an integral state that absorbs the current
%     row 4   ALOS       LOS, plus an ESTIMATE of the crab angle
%
%   Running them together is what makes the comparison honest: the same
%   realisation of everything else, so every difference in the tracks belongs
%   to the guidance law and to nothing else. The same principle as the four
%   rows of Week 2, section I.
%
%   THE SIGNAL CHAIN
%
%     Guidance bank --> Autopilot bank --> Allocation bank --> Plant bank --> Measurements
%       psi_d (4)          tau_N (4)           n (8)            x (48)
%          ^                                                       |
%          +-------------------------------------------------------+
%
%   The four state vectors travel as one 48-wide signal and are split inside
%   each bank, so the top level carries one line per stage.
%
%   WHY THE TUNING TRAVELS AS A VECTOR
%
%   Each row needs eight numbers. Wired as eight Constants to four blocks that
%   is thirty-two lines crossing one corridor, and no amount of routing makes
%   it readable - the first attempt at this model scored 572 overlapping line
%   pairs. Collecting them into one `par` vector makes it four lines, each a
%   fan-out from a single source, which is the one kind of shared trunk that
%   is correct. The block unpacks the vector on its first six lines.
%
%   Regenerating is safe: any existing W04_guidance.slx is overwritten.

m    = 'W04_guidance';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();

cfg  = otter_config('base');
NROW = 4;
LAW  = {'atan2','LOS','ILOS','ALOS'};

%  Every Constant in this model holds a NAME, and Simulink checks the name
%  against the base workspace as the block is created. In a fresh session
%  there is nothing there yet, so the defaults go in first. Anything the
%  student has already set is left alone.
ensure_base_vars(W04_vars);

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

P = gnc_chain({'reference','controller','allocation','plant','measurement'}, ...
              'Height', struct('reference',150, 'controller',130, ...
                               'allocation',130, 'plant',130), 'Y', 120);

%% =====================================================================
%  1. Guidance bank — the only stage where the four rows differ
%  =====================================================================
g = add_subsys(m, 'Guidance bank', P.reference, {'x'}, ...
               {'psi_d','y_e','wp','aux'}, gnc_colour('reference'));

%  The four collector Muxes, interleaved with the lanes that reach them so
%  that no two of the sixteen row outputs share a segment.
GOUT = {'psi_d','y_e','wp','aux'};
GMUX = cell(1,4);  GLANE = zeros(1,4);
for j = 1:4
    GMUX{j}  = [GOUT{j} ' mux'];
    GLANE(j) = 640 + 90*(j-1);
    add_block('simulink/Signal Routing/Mux', [g '/' GMUX{j}], 'Inputs', num2str(NROW), ...
              'Position',[680 + 90*(j-1), 60, 685 + 90*(j-1), 580]);
end

GROW = zeros(1,NROW);
for i = 1:NROW
    q = port_xy(g, GMUX{1}, 'Inport', i);
    GROW(i) = q(2);
end
dp = GROW(2) - GROW(1);

add_block('simulink/Signal Routing/Demux', [g '/split x'], 'Outputs', num2str(NROW), ...
          'Position',[190 GROW(1)-dp/2 195 GROW(1)-dp/2+NROW*dp]);
add_line(g, 'x/1','split x/1','autorouting','on');
q = port_xy(g, 'split x', 'Inport', 1);
set_param([g '/x'], 'Position',[40 q(2)-7 70 q(2)+7]);

%  The mission and the tuning: two waypoint columns, and one parameter vector.
KP = {'Delta','R_switch','sw_mode','kappa','gamma','h'};
add_block('simulink/Signal Routing/Mux', [g '/par'], 'Inputs', num2str(numel(KP)), ...
          'Position',[240 700 245 700+52*numel(KP)]);
for i = 1:numel(KP)
    add_block('simulink/Sources/Constant', [g '/' KP{i}], 'Value', KP{i}, ...
              'Position',[60 700 140 730]);
end
row_feed(g, 'par', KP);

for nm = {'WP_N','WP_E'}
    add_block('simulink/Sources/Constant', [g '/' nm{1}], 'Value', nm{1}, ...
              'Position',[60 620 140 650]);
end
set_param([g '/WP_N'], 'Position',[60 600 140 630]);
set_param([g '/WP_E'], 'Position',[60 660 140 690]);

for i = 1:NROW
    blk = sprintf('%s/%s', g, LAW{i});
    add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
              'Position',[300 GROW(i)-70 560 GROW(i)+70]);
    %  A guidance law with memory is a DISCRETE algorithm and has to say so.
    %  Left to inherit, the block picks up the plant's continuous rate and
    %  Simulink refuses the persistent variables. Declaring 'h' is also honest
    %  about what is implemented: the Euler updates inside already use h.
    set_mlfcn(blk, guidance_code(i), '', '', 'h');

    %  One lane per SOURCE. The four lines leaving WP_N share a lane, which is
    %  correct - they are one signal - and no two different sources share one.
    lane_line(g, 'split x', i, LAW{i}, 1, 205);
    lane_line(g, 'WP_N', 1, LAW{i}, 2, 215);
    lane_line(g, 'WP_E', 1, LAW{i}, 3, 235);
    lane_line(g, 'par',  1, LAW{i}, 4, 255);

    for j = 1:4
        lane_line(g, LAW{i}, j, GMUX{j}, i, GLANE(j));
    end
end

%  Each collector Mux leaves on its own row, turning down IMMEDIATELY to the
%  right of itself. Four Muxes of the same height put their outputs on the
%  same y, so a lane further away would put all four horizontals on one line.
for j = 1:4
    q = port_xy(g, GMUX{j}, 'Outport', 1);
    set_param([g '/' GOUT{j}], 'Position',[1080 q(2)+110+34*(j-1) 1110 q(2)+124+34*(j-1)]);
    lane_line(g, GMUX{j}, 1, GOUT{j}, 1, 700 + 90*(j-1));
end

note_in(g, [40 1180 1100 1440], strjoin({ ...
'FOUR LAWS, ONE MISSION'
''
'Every row gets the same waypoints, the same Delta, the same R_switch and'
'the same current. The only difference is the block in the middle.'
''
'   1  atan2   psi_d = atan2(E_next - E, N_next - N)'
'      Aims at the WAYPOINT. Regulates a distance to a point, so a vessel'
'      pushed off the line never returns to the line.'
''
'   2  LOS     psi_d = pi_p - atan(y_e / Delta)'
'      Aims at a point Delta ahead ON THE PATH. Regulates the distance to'
'      the LINE, which is what "follow a path" means.'
''
'   3  ILOS    psi_d = pi_p - atan(y_e/Delta + (kappa/Delta) y_int)'
'      Adds an integral state whose gain SHRINKS as y_e grows, so the'
'      anti-windup is part of the law and not an addition to it.'
''
'   4  ALOS    psi_d = pi_p - b_hat - atan(y_e / Delta)'
'      Estimates the crab angle itself. b_hat can be read off and compared'
'      with atan2(v, u); an ILOS integral state cannot.'
''
'Rows 3 and 4 do nothing that row 2 does not, until a current is switched'
'on. That is the experiment of section G.'}, newline));

%% =====================================================================
%  2. Autopilot bank — the SAME law and the SAME gains on all four rows
%  =====================================================================
c = add_subsys(m, 'Autopilot bank', P.controller, {'psi_d','x'}, {'tau_N'}, ...
               gnc_colour('controller'));
add_block('simulink/Signal Routing/Mux', [c '/tau mux'], 'Inputs', num2str(NROW), ...
          'Position',[780 60 785 580]);
CROW = zeros(1,NROW);
for i = 1:NROW
    q = port_xy(c, 'tau mux', 'Inport', i);
    CROW(i) = q(2);
end
cp = CROW(2) - CROW(1);
add_block('simulink/Signal Routing/Demux', [c '/split psi_d'], 'Outputs', num2str(NROW), ...
          'Position',[170 CROW(1)-cp/2 175 CROW(1)-cp/2+NROW*cp]);
%  Offset by half a row. The autopilot's second input sits at the centre of
%  its block, which is exactly the row height, so a Demux ON the rows would
%  send this line straight along the row and on top of the psi_d line that
%  arrives there too. Half a pitch down gives it a jog and a lane of its own.
add_block('simulink/Signal Routing/Demux', [c '/split x'], 'Outputs', num2str(NROW), ...
          'Position',[240 CROW(1)+cp/4 245 CROW(1)+cp/4+NROW*cp]);

KC = {'Kp','Kd'};
add_block('simulink/Signal Routing/Mux', [c '/gains'], 'Inputs', num2str(numel(KC)), ...
          'Position',[300 700 305 804]);
for i = 1:numel(KC)
    add_block('simulink/Sources/Constant', [c '/' KC{i}], 'Value', KC{i}, ...
              'Position',[120 700 200 730]);
end
row_feed(c, 'gains', KC);

for i = 1:NROW
    blk = sprintf('%s/autopilot %d', c, i);
    add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
              'Position',[380 CROW(i)-55 620 CROW(i)+55]);
    set_mlfcn(blk, { ...
'function tau_N = autopilot(psi_d, x, gains)'
'%#codegen'
'% The Week 3 heading autopilot, unchanged and untuned.'
'%'
'%   tau_N = Kp ssa(psi_d - psi) - Kd r'
'%'
'% P-D on the heading with the D term acting on the measured yaw RATE, not on'
'% the derivative of the error. All four rows carry an identical copy, so no'
'% difference in the results can come from the inner loop.'
'Kp = gains(1);'
'Kd = gains(2);'
''
'psi = x(12);'
'r   = x(6);'
'e   = psi_d - psi;'
'e   = atan2(sin(e), cos(e));        % ssa: the smallest signed angle'
'tau_N = Kp * e - Kd * r;'}, 'tau_N', '[1 1]');

    lane_line(c, 'split psi_d', i, sprintf('autopilot %d', i), 1, 300);
    lane_line(c, 'split x',     i, sprintf('autopilot %d', i), 2, 320);
    lane_line(c, 'gains',       1, sprintf('autopilot %d', i), 3, 340);
    add_line(c, sprintf('autopilot %d/1', i), sprintf('tau mux/%d', i));
end

%  Both inports sit on the row of the Demux they feed, so neither line bends.
%  The x Demux is offset a QUARTER of a row: that keeps both its outputs and
%  its input off the four autopilot rows, so nothing it carries ever runs
%  along a row that a psi_d line is already using.
for nm = {'psi_d','x'}
    q = port_xy(c, ['split ' nm{1}], 'Inport', 1);
    set_param([c '/' nm{1}], 'Position',[40 q(2)-7 70 q(2)+7]);
    add_line(c, [nm{1} '/1'], ['split ' nm{1} '/1']);
end
q = port_xy(c, 'tau mux', 'Outport', 1);
set_param([c '/tau_N'], 'Position',[860 q(2)-7 890 q(2)+7]);
add_line(c, 'tau mux/1','tau_N/1');

%% =====================================================================
%  3. Allocation bank — the exact inverse of Week 3
%  =====================================================================
a = add_subsys(m, 'Allocation bank', P.allocation, {'tau_N'}, {'n'}, ...
               gnc_colour('allocation'));
add_block('simulink/Signal Routing/Mux', [a '/n mux'], 'Inputs', num2str(NROW), ...
          'Position',[780 60 785 580]);
AROW = zeros(1,NROW);
for i = 1:NROW
    q = port_xy(a, 'n mux', 'Inport', i);
    AROW(i) = q(2);
end
ap = AROW(2) - AROW(1);
add_block('simulink/Signal Routing/Demux', [a '/split tau'], 'Outputs', num2str(NROW), ...
          'Position',[170 AROW(1)-ap/2 175 AROW(1)-ap/2+NROW*ap]);

KA = {'X_ff','k_pos','k_neg','n_max','n_min','y_pont'};
add_block('simulink/Signal Routing/Mux', [a '/apar'], 'Inputs', num2str(numel(KA)), ...
          'Position',[300 700 305 700+52*numel(KA)]);
for i = 1:numel(KA)
    add_block('simulink/Sources/Constant', [a '/' KA{i}], 'Value', KA{i}, ...
              'Position',[120 700 200 730]);
end
row_feed(a, 'apar', KA);

for i = 1:NROW
    blk = sprintf('%s/allocate %d', a, i);
    add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
              'Position',[380 AROW(i)-60 620 AROW(i)+60]);
    set_mlfcn(blk, { ...
'function n = allocate(tau_N, apar)'
'%#codegen'
'% Two demands, two propellers: the map is square and the inverse is unique.'
'%'
'%   X = T1 + T2,   N = y_pont (T1 - T2)'
'%     ==>  T1 = X/2 + N/(2 y_pont),   T2 = X/2 - N/(2 y_pont)'
'%'
'% Then the propeller curve is inverted one propeller at a time. Allocating'
'% THRUST and inverting afterwards is what makes the two shaft speeds come'
'% out unequal by themselves - see Appendix A1.'
'X_ff   = apar(1);  k_pos = apar(2);  k_neg  = apar(3);'
'n_max  = apar(4);  n_min = apar(5);  y_pont = apar(6);'
''
'T = [X_ff/2 + tau_N/(2*y_pont);'
'     X_ff/2 - tau_N/(2*y_pont)];'
'n = zeros(2,1);'
'for j = 1:2'
'    if T(j) >= 0'
'        nj =  sqrt( T(j) / k_pos);'
'    else'
'        nj = -sqrt(-T(j) / k_neg);'
'    end'
'    n(j) = min(max(nj, n_min), n_max);'
'end'}, 'n', '[2 1]');

    lane_line(a, 'split tau', i, sprintf('allocate %d', i), 1, 300);
    lane_line(a, 'apar',      1, sprintf('allocate %d', i), 2, 330);
    add_line(a, sprintf('allocate %d/1', i), sprintf('n mux/%d', i));
end

add_line(a, 'tau_N/1','split tau/1','autorouting','on');
q = port_xy(a, 'split tau', 'Inport', 1);
set_param([a '/tau_N'], 'Position',[40 q(2)-7 70 q(2)+7]);
q = port_xy(a, 'n mux', 'Outport', 1);
set_param([a '/n'], 'Position',[860 q(2)-7 890 q(2)+7]);
add_line(a, 'n mux/1','n/1');

%% =====================================================================
%  4. Plant bank — four copies of one hull
%  =====================================================================
%  Two outputs. `x` is all four vessels, 48 wide, for the guidance and the
%  autopilots. `x1` is the FIRST vessel alone, 12 wide, because the logging
%  contract of this course starts with one vessel's [u v r N E psi] and
%  add_measurement's selectors are built for twelve states, not forty-eight.
p = add_subsys(m, 'Plant bank', P.plant, {'n'}, {'x','x1'}, gnc_colour('plant'));
add_block('simulink/Signal Routing/Mux', [p '/x mux'], 'Inputs', num2str(NROW), ...
          'Position',[700 60 705 580]);
PROW = zeros(1,NROW);
for i = 1:NROW
    q = port_xy(p, 'x mux', 'Inport', i);
    PROW(i) = q(2);
end
pp = PROW(2) - PROW(1);
add_block('simulink/Signal Routing/Demux', [p '/split n'], 'Outputs', num2str(NROW), ...
          'Position',[150 PROW(1)-pp/2 155 PROW(1)-pp/2+NROW*pp]);
for i = 1:NROW
    add_otter_plant(p, sprintf('Otter %d', i), ...
                    [280 PROW(i)-55 560 PROW(i)+55], cfg);
    add_line(p, sprintf('split n/%d', i), sprintf('Otter %d/1', i), 'autorouting','on');
    add_line(p, sprintf('Otter %d/1', i), sprintf('x mux/%d', i));
end
add_line(p, 'n/1','split n/1','autorouting','on');
q = port_xy(p, 'split n', 'Inport', 1);
set_param([p '/n'], 'Position',[40 q(2)-7 70 q(2)+7]);
q = port_xy(p, 'x mux', 'Outport', 1);
set_param([p '/x'], 'Position',[780 q(2)-7 810 q(2)+7]);
add_line(p, 'x mux/1','x/1');

q = port_xy(p, 'Otter 1', 'Outport', 1);
set_param([p '/x1'], 'Position',[780 q(2)-7 810 q(2)+7]);
lane_line(p, 'Otter 1', 1, 'x1', 1, 640);

%% =====================================================================
%  5. Measurements
%  =====================================================================
%  log = [u v r N E psi | psi_d(4) y_e(4) wp(4) aux(4) | trk(48)]
%  The first six columns are the FIRST vessel's, by the course-wide contract.
%  `trk` is all four state vectors, because the figures of this week draw four
%  tracks and the contract's six columns describe only one vessel.
add_measurement(m, P.measurement, 'W04', {'psi_d','y_e','wp','aux','trk'});

%% ---- wiring, top level -------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Guidance bank/1',   'Autopilot bank/1');     % psi_d
L('Plant bank/1',      'Guidance bank/1');      % x, the one line that goes back
L('Plant bank/1',      'Autopilot bank/2');
L('Autopilot bank/1',  'Allocation bank/1');
L('Allocation bank/1', 'Plant bank/1');

L('Plant bank/2',    'Measurements/1');       % x1, one vessel, twelve states
L('Guidance bank/1', 'Measurements/2');
L('Guidance bank/2', 'Measurements/3');
L('Guidance bank/3', 'Measurements/4');
L('Guidance bank/4', 'Measurements/5');
L('Plant bank/1',    'Measurements/6');       % trk, all four vessels

%% ---- what the model is for ---------------------------------------------
note(m, [40 400 940 900], strjoin({ ...
'WEEK 4  -  WAYPOINT FOLLOWING AND LOS GUIDANCE'
''
'Weeks 1 to 3 were told what heading to hold. Nobody said where the'
'number came from. This week it comes from a list of waypoints, and'
'turning that list into psi_d is what GUIDANCE means.'
''
'FOUR VESSELS RUN THE SAME MISSION AT THE SAME TIME'
''
'   row 1  atan2   aim at the waypoint           - and never reach the path'
'   row 2  LOS     aim Delta ahead on the path   - and converge to it'
'   row 3  ILOS    LOS + an integral state       - and beat the current'
'   row 4  ALOS    LOS + an estimated crab angle - and beat it knowingly'
''
'Same waypoints, same current, same autopilot gains, same hull. The only'
'difference is the guidance block, so every difference in the tracks'
'belongs to the guidance law. Set guid_show = 1..4 to plot one of them.'
''
'THE ONE SIGNAL THAT TRAVELS BACKWARDS'
''
'x, from the plant bank to the guidance bank. Guidance is feedback: it'
'needs to know where the vessel IS before it can say where to point.'
''
'WHAT TO WATCH'
''
'1  WITH NO CURRENT, rows 2, 3 and 4 are nearly identical and row 1 is'
'   not. That is the difference between following a path and visiting'
'   points.'
''
'2  WITH A CURRENT, row 2 settles with a PERMANENT cross-track error of'
'   about Delta*tan(beta_c). Rows 3 and 4 remove it, by different means.'
''
'3  b_hat in row 4 converges to the crab angle itself. Read it off the'
'   scope and compare it with atan2(v, u).'}, newline));

%% ---- plot when the run finishes ----------------------------------------
set_param(m, 'StopFcn', 'W04_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

mss_style(m);
save_system(m, out);
export_diagram(m, fullfile(here, 'img'));
close_system(m, 0);

fprintf('  built  %s\n', out);
end


% =========================================================================
function C = guidance_code(law)
%GUIDANCE_CODE  The four laws, as the MATLAB Function block sees them.
%
%   ONE function with the law fixed at build time, so the four blocks share
%   every line except the handful that differ. Section 4-10 of the lecture
%   prints this code beside the equations it implements.

head = { ...
'function [psi_d, y_e, wp, aux] = guidance(x, WP_N, WP_E, par)'
'%#codegen'
'% One guidance law: waypoint list in, desired heading out.'
'%'
'% STATE. k is the active leg, y_int the ILOS integral, b_hat the ALOS'
'% estimate. They are persistent, which inside a Simulink block means the'
'% BLOCK owns them: Simulink resets them at the start of every run and two'
'% blocks never share a copy. That is the difference from calling MSS'
'% ILOSpsi.m from a script, where one copy is shared by the whole session'
'% and has to be cleared by hand with "clear ILOSpsi".'
'persistent k y_int b_hat'
'if isempty(k), k = 1; y_int = 0; b_hat = 0; end'
''
'Delta = par(1);  R_switch = par(2);  sw_mode = par(3);'
'kappa = par(4);  gamma    = par(5);  h       = par(6);'
''
'N = x(7);  E = x(8);'
'n = numel(WP_N);'
''
'% ---- the active leg, and the path-tangential angle -------------------'
'kn = min(k+1, n);'
'Nk = WP_N(k);   Ek = WP_E(k);'
'Nn = WP_N(kn);  En = WP_E(kn);'
'pi_p = atan2(En - Ek, Nn - Nk);'
''
'% ---- along-track and cross-track error, from ONE rotation ------------'
'%   [x_e]   [ cos pi_p   sin pi_p ] [N - Nk]'
'%   [y_e] = [-sin pi_p   cos pi_p ] [E - Ek]'
'dN = N - Nk;  dE = E - Ek;'
'x_e =  dN*cos(pi_p) + dE*sin(pi_p);'
'y_e = -dN*sin(pi_p) + dE*cos(pi_p);'
''
'% ---- waypoint switching ----------------------------------------------'
'd = sqrt((Nn-Nk)^2 + (En-Ek)^2);'
'if sw_mode == 1'
'    hit = (d - x_e) < R_switch;                   % along-track, as MSS does'
'else'
'    hit = sqrt((N-Nn)^2 + (E-En)^2) < R_switch;   % circle of acceptance'
'end'
'if hit && k < n-1'
'    k = k + 1;'
'end'
'wp = k;'
''};

switch law
    case 1
        body = { ...
'% ---- LAW 1: atan2 - aim straight at the next waypoint ----------------'
'% The obvious answer, and the wrong one. It regulates the DISTANCE TO A'
'% POINT, not the distance to the LINE, so a vessel pushed off the path'
'% never comes back to it: it simply approaches the waypoint from wherever'
'% it happens to be. y_e is still computed, so that the four rows are'
'% measured with the same yardstick.'
'psi_d = atan2(En - E, Nn - N);'
'aux   = 0;'};
    case 2
        body = { ...
'% ---- LAW 2: LOS - aim at a point Delta ahead ON THE PATH -------------'
'%   psi_d = pi_p - atan(y_e / Delta)'
'% Two pieces. pi_p says "line up with the path"; the arctan says "and lean'
'% towards it by an amount that grows with how far off you are". The'
'% correction saturates at 90 deg, so the vessel heads almost perpendicular'
'% to the path when far from it and never turns away from it.'
'psi_d = pi_p - atan(y_e / Delta);'
'aux   = 0;'};
    case 3
        body = { ...
'% ---- LAW 3: ILOS - an integral state absorbs the current -------------'
'%   psi_d      = pi_p - atan(Kp y_e + Ki y_int),  Kp = 1/Delta, Ki = kappa Kp'
'%   d/dt y_int = Delta y_e / (Delta^2 + (y_e + kappa y_int)^2)'
'% Borhaug, Pavlov and Pettersen (2008). Look at the denominator: the'
'% integrator gain SHRINKS as y_e grows, so it barely integrates while the'
'% vessel is still far from the path. That is anti-windup built into the law'
'% rather than bolted on afterwards - compare Week 2, section F.'
'Kp = 1 / Delta;'
'Ki = kappa * Kp;'
'psi_d = pi_p - atan(Kp*y_e + Ki*y_int);'
'y_int = y_int + h * Delta*y_e / (Delta^2 + (y_e + kappa*y_int)^2);'
'aux   = y_int;'};
    otherwise
        body = { ...
'% ---- LAW 4: ALOS - estimate the crab angle and subtract it -----------'
'%   psi_d      = pi_p - b_hat - atan(y_e / Delta)'
'%   d/dt b_hat = gamma Delta y_e / sqrt(Delta^2 + y_e^2)'
'% Fossen (2023). ILOS absorbs the current into an integral state whose'
'% value has no physical meaning. ALOS estimates the CRAB ANGLE itself, so'
'% b_hat converges to a number that can be read off and compared with'
'% atan2(v, u). Section H checks that it does, and plots the Lyapunov'
'% function whose derivative the adaptation law was chosen to make negative.'
'psi_d = pi_p - b_hat - atan(y_e / Delta);'
'b_hat = b_hat + h * gamma * Delta * y_e / sqrt(Delta^2 + y_e^2);'
'aux   = b_hat;'};
end

C = [head; body];
end

% -------------------------------------------------------------------------
function note(m, pos, txt)
h = Simulink.Annotation([m '/note']);
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end

function note_in(sub, pos, txt)
h = Simulink.Annotation([sub '/note']);
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end
