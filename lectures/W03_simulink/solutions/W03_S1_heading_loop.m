function W03_S1_heading_loop(mdl)
%W03_S1_HEADING_LOOP  Solution to all three Week 3 problems in one model.
%
%   >> W03_S1_heading_loop      builds W03_S1.slx
%   >> W03_check(1,'W03_S1')    and 2, and 3
%
%   THE LAW
%
%       tau_N = Kp * ssa(psi_d - psi) - Kd * r
%
%   THE THREE DECISIONS, AND WHY EACH ONE GOES THAT WAY
%
%   1  THE DERIVATIVE TERM FEEDS BACK THE YAW RATE r, NOT THE DERIVATIVE OF
%      THE ERROR. The two agree while psi_d is constant and disagree at every
%      step, where d(psi_d)/dt is an impulse. Differentiating the error puts
%      that impulse straight into the actuator; feeding back r does not.
%      The plant already measures r - it is state 6 - so nothing is
%      differentiated anywhere in this model.
%
%   2  THE ERROR IS WRAPPED BEFORE THE GAIN SEES IT. ssa maps any angle to
%      (-pi, pi], so a command 10 deg the other side of the +-180 deg seam is
%      answered by a 10 deg turn and not by a 350 deg one. Problem 3 removes
%      the wrap to show what it was doing.
%
%   3  Kd SITS BESIDE THE DAMPING, NOT BESIDE THE INERTIA. Substituting the
%      law into the yaw equation gives
%
%          M66 psi_ddot + (|Nr| + Kd) psi_dot + Kp psi = Kp psi_d
%
%      so raising Kd raises zeta and overshoot FALLS. In Week 2 the controlled
%      variable was a velocity, its derivative was an acceleration, the same
%      term sat beside the MASS, and the response got worse. The term did not
%      change; the axis did.
%
%   WHY THE STEADY ERROR IS ZERO AT EVERY GAIN
%
%   The heading is the integral of the yaw rate, psi = int r, so the plant
%   carries a free integrator and the loop is TYPE 1. Week 2's plant had none
%   and could not reach its setpoint at any gain. That difference is one
%   structural fact about the axis, not a better controller.
%
%   See also W03_CHECK, W03_P1_START.

if nargin < 1 || isempty(mdl), mdl = 'W03_S1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'));
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%% ---- command -----------------------------------------------------------
%  Two steps summed, so psi_2 = psi_1 turns the second one off. Degrees in,
%  radians out: every angle inside the loop is in radians because otter.m is.
add_block('simulink/Sources/Step', [mdl '/step 1'], ...
          'Time','t_up', 'Before','0', 'After','psi_1', 'Position',[40 100 70 130]);
add_block('simulink/Sources/Step', [mdl '/step 2'], ...
          'Time','t_dn', 'Before','0', 'After','psi_2-psi_1', 'Position',[40 160 70 190]);
add_sum(mdl, 'psi_cmd', '++', [110 145]);
add_block('simulink/Math Operations/Gain', [mdl '/deg2rad'], ...
          'Gain','pi/180', 'Position',[150 125 190 165]);
add_line(mdl, 'step 1/1',  'psi_cmd/1', 'autorouting','smart');
add_line(mdl, 'step 2/1',  'psi_cmd/2', 'autorouting','smart');
add_line(mdl, 'psi_cmd/1', 'deg2rad/1', 'autorouting','smart');

%% ---- the autopilot -----------------------------------------------------
c = add_subsys(mdl, 'Heading autopilot', [250 110 400 230], ...
               {'psi_d','psi','r'}, {'tau_N'}, gnc_colour('controller'));
blk = [c '/law'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[240 60 420 220]);
set_mlfcn(blk, { ...
'function tau_N = law(psi_d, psi, r, Kp, Kd, use_ssa)'
'%#codegen'
'%LAW  Heading autopilot:  tau_N = Kp ssa(psi_d - psi) - Kd r'
'%'
'%  ssa maps an angle to (-pi, pi], so a command just the other side of the'
'%  +-180 deg seam is answered by the SHORT turn. Setting use_ssa = 0 removes'
'%  the wrap, which is what Problem 3 asks for.'
'%'
'%  The damping term uses r, the measured yaw rate, and not d(error)/dt. The'
'%  two agree while psi_d is constant and disagree at every step, where the'
'%  derivative of the command is an impulse.'
'e = psi_d - psi;'
'if use_ssa > 0.5'
'    e = mod(e + pi, 2*pi) - pi;'
'end'
'tau_N = Kp*e - Kd*r;'}, 'tau_N', '[1 1]');

KK = {'Kp','Kd','use_ssa'};
for i = 1:numel(KK)
    add_block('simulink/Sources/Constant', [c '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 90+42*i 150 114+42*i]);
    add_line(c, [KK{i} '/1'], sprintf('law/%d', i+3), 'autorouting','smart');
end
add_line(c, 'psi_d/1', 'law/1', 'autorouting','smart');
add_line(c, 'psi/1',   'law/2', 'autorouting','smart');
add_line(c, 'r/1',     'law/3', 'autorouting','smart');
add_line(c, 'law/1',   'tau_N/1', 'autorouting','smart');
set_param([c '/psi_d'], 'Position',[40  70  70  90]);
set_param([c '/psi'],   'Position',[40 110  70 130]);
set_param([c '/r'],     'Position',[40 150  70 170]);

add_line(mdl, 'deg2rad/1', 'Heading autopilot/1', 'autorouting','smart');

%% ---- allocation and hull ----------------------------------------------
add_alloc(mdl, [460 130 620 230]);
add_block('simulink/Sources/Constant', [mdl '/X_ff'], ...
          'Value','X_ff', 'Position',[380 250 440 280]);
add_otter_plant(mdl, 'Otter USV', [690 130 890 240], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'Heading autopilot/1', 'Control allocation/1', 'autorouting','smart');
add_line(mdl, 'X_ff/1',              'Control allocation/2', 'autorouting','smart');
add_line(mdl, 'Control allocation/1','Otter USV/1',          'autorouting','smart');

%% ---- logging and the two feedback signals ------------------------------
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[960 140 1030 180]);
add_line(mdl, 'Otter USV/1', 'xlog/1', 'autorouting','smart');

%  psi is state 12, r is state 6.
add_block('simulink/Signal Routing/Selector', [mdl '/psi'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','12', ...
          'InputPortWidth','12', 'Position',[930 320 980 355]);
add_block('simulink/Signal Routing/Selector', [mdl '/r'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','6', ...
          'InputPortWidth','12', 'Position',[930 380 980 415]);
add_line(mdl, 'Otter USV/1', 'psi/1', 'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'r/1',   'autorouting','smart');

%  Two feedbacks, both as tags. Drawn as lines they would cross the whole
%  model backwards and land on the forward path; check_overlaps catches that.
add_block('simulink/Signal Routing/Goto', [mdl '/psi out'], ...
          'GotoTag','psi_fb', 'Position',[1010 328 1060 348]);
add_block('simulink/Signal Routing/Goto', [mdl '/r out'], ...
          'GotoTag','r_fb',   'Position',[1010 388 1060 408]);
add_block('simulink/Signal Routing/From', [mdl '/psi in'], ...
          'GotoTag','psi_fb', 'Position',[150 195 200 215]);
add_block('simulink/Signal Routing/From', [mdl '/r in'], ...
          'GotoTag','r_fb',   'Position',[150 235 200 255]);
add_line(mdl, 'psi/1',    'psi out/1', 'autorouting','smart');
add_line(mdl, 'r/1',      'r out/1',   'autorouting','smart');
add_line(mdl, 'psi in/1', 'Heading autopilot/2', 'autorouting','smart');
add_line(mdl, 'r in/1',   'Heading autopilot/3', 'autorouting','smart');

add_block('simulink/Sinks/Scope', [mdl '/heading'], 'Position',[960 210 990 240]);
add_line(mdl, 'Otter USV/1', 'heading/1', 'autorouting','smart');
set_param([mdl '/heading'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION  -  ALL THREE WEEK 3 PROBLEMS IN ONE MODEL'
''
'   tau_N = Kp ssa(psi_d - psi) - Kd r'
''
'PROBLEM 1   Kd = 0. The steady error is ZERO at every gain, because the'
'            heading is the integral of the yaw rate: psi = int r, so the'
'            plant carries a free integrator and the loop is TYPE 1.'
'            Week 2 could not reach its setpoint at any gain.'
''
'PROBLEM 2   Kd > 0. Substituting the law into the yaw equation gives'
''
'               M66 psi_ddot + (|Nr| + Kd) psi_dot + Kp psi = Kp psi_d'
''
'            so Kd sits beside the DAMPING and overshoot FALLS as it rises.'
'            In Week 2 the same term sat beside the MASS and made things'
'            worse. The term did not change; the axis did.'
''
'PROBLEM 3   use_ssa = 0 removes the wrap and the vessel turns the LONG'
'            way round the +-180 deg seam.'
''
'The damping term feeds back r, the MEASURED yaw rate, and not d(e)/dt.'
'Nothing in this model is differentiated.'}, newline);
a.Position = [40 470 900 760];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end

% =========================================================================
function add_alloc(mdl, pos)
a = add_subsys(mdl, 'Control allocation', pos, {'tau_N','X_ff'}, {'n'}, ...
               gnc_colour('allocation'));
blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[250 60 420 220]);
set_mlfcn(blk, { ...
'function n = allocation(tau_N, X_ff, k_pos, k_neg, n_max, n_min, y_pont)'
'%#codegen'
'% Demanded surge force and yaw moment to two shaft speeds.'
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
%  Constants at 60+34i put k_neg's centre on y = 140, which is exactly where
%  the X_ff inport feeds the block: check_overlaps found the two drawn on top
%  of each other. Offsetting the ladder moves every constant off both inport
%  rows (90 and 140).
KK = {'k_pos','k_neg','n_max','n_min','y_pont'};
for i = 1:numel(KK)
    add_block('simulink/Sources/Constant', [a '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 78+34*i 150 102+34*i]);
    add_line(a, [KK{i} '/1'], sprintf('allocation/%d', i+2), 'autorouting','smart');
end
add_block('simulink/Math Operations/Reshape', [a '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[470 118 510 162]);
add_line(a, 'tau_N/1',     'allocation/1', 'autorouting','smart');
add_line(a, 'X_ff/1',      'allocation/2', 'autorouting','smart');
add_line(a, 'allocation/1','as vector/1',  'autorouting','smart');
add_line(a, 'as vector/1', 'n/1',          'autorouting','smart');
set_param([a '/tau_N'], 'Position',[ 40  80  70 100]);
set_param([a '/X_ff'],  'Position',[ 40 130  70 150]);
end
