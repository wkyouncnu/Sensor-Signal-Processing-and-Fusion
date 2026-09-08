function W02_S1_speed_loop(mdl)
%W02_S1_SPEED_LOOP  Solution to all three Week 2 problems in one model.
%
%   >> W02_S1_speed_loop      builds W02_S1.slx
%   >> W02_check(1,'W02_S1')  and 2, and 3
%
%   WHY ONE MODEL AND NOT THREE
%
%   The three problems differ only in which parts of the loop are switched on:
%
%       Problem 1   loop_closed = 0        X comes straight from X_open
%       Problem 2   loop_closed = 1, Ki=0  proportional only
%       Problem 3   loop_closed = 1, Ki>0  proportional plus integral
%
%   Building three models would hide that. Building one, with a switch, makes
%   the point of the week visible on the canvas: the plant never changed, the
%   thrust map never changed, and every difference in the result came from the
%   controller. That is also how the lecture's own W02_surge_control.slx is
%   arranged, and why its section scripts can sweep a gain without rebuilding.
%
%   THE THREE DECISIONS
%
%   1  THE INTEGRATOR IS DISCRETE, not continuous. The model is fixed-step,
%      and a continuous integrator inside a fixed-step loop invites a solver
%      order mismatch that shows up as a slow drift rather than as an error.
%
%   2  Ki MULTIPLIES THE INTEGRAL OF THE ERROR, not the error of the integral.
%      Written the other way the units are wrong and the gain that works at
%      one sample time fails at another.
%
%   3  THE ERROR IS u_d - u, AND u IS THE SURGE VELOCITY, state 1. It is not
%      the speed over ground sqrt(u^2+v^2): with no current and no steering
%      those agree here, but Week 4 has both, and a loop written against the
%      wrong signal keeps working until exactly the moment it matters.
%
%   THE NUMBER TO PREDICT BEFORE RUNNING PROBLEM 2
%
%       u_ss / u_d = Kp K_u / (1 + Kp K_u),      K_u = 0.012894 (m/s)/N
%
%   At Kp = 100 that is 0.5632, so u_ss = 0.8448 m/s against u_d = 1.5 — an
%   error of 44 per cent. Section D of the lecture measures 0.8448.
%
%   See also W02_CHECK, W02_P1_START.

if nargin < 1 || isempty(mdl), mdl = 'W02_S1'; end

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

%% ---- reference ---------------------------------------------------------
add_block('simulink/Sources/Step', [mdl '/u_d'], ...
          'Time','t_step', 'Before','0', 'After','u_d', ...
          'Position',[40 120 70 150]);

%% ---- error -------------------------------------------------------------
%  add_sum takes the CENTRE, not a corner: add_sum(sys, name, signs, centre).
add_sum(mdl, 'e', '+-', [130 132]);

%% ---- controller: Kp e + Ki * integral(e) -------------------------------
add_block('simulink/Math Operations/Gain', [mdl '/Kp'], ...
          'Gain','Kp', 'Position',[190 108 230 148]);
add_block('simulink/Math Operations/Gain', [mdl '/Ki'], ...
          'Gain','Ki', 'Position',[190 188 230 228]);
%  Discrete, because the model is fixed-step. See the header.
add_block('simulink/Discrete/Discrete-Time Integrator', [mdl '/I'], ...
          'SampleTime','h', 'Position',[260 188 300 228]);
add_sum(mdl, 'X_pi', '++', [350 162]);

add_line(mdl, 'u_d/1', 'e/1', 'autorouting','smart');
add_line(mdl, 'e/1',   'Kp/1', 'autorouting','smart');
add_line(mdl, 'e/1',   'Ki/1', 'autorouting','smart');
add_line(mdl, 'Ki/1',  'I/1',  'autorouting','smart');
add_line(mdl, 'Kp/1',  'X_pi/1', 'autorouting','smart');
add_line(mdl, 'I/1',   'X_pi/2', 'autorouting','smart');

%% ---- the switch that selects open or closed loop -----------------------
add_block('simulink/Sources/Constant', [mdl '/X_open'], ...
          'Value','X_open', 'Position',[340 240 400 280]);
add_block('simulink/Sources/Constant', [mdl '/loop_closed'], ...
          'Value','loop_closed', 'Position',[340 62 410 92]);
add_block('simulink/Signal Routing/Switch', [mdl '/loop'], ...
          'Criteria','u2 > Threshold', 'Threshold','0.5', ...
          'Position',[440 140 470 250]);
%  All three inputs of a Switch arrive on its LEFT edge, so autorouting gives
%  them the same vertical lane and two of them end up drawn on top of each
%  other — check_overlaps found exactly that at x = 425. lane_line puts each
%  on a lane of its own.
add_line(mdl, 'X_pi/1', 'loop/1', 'autorouting','smart');
lane_line(mdl, 'loop_closed', 1, 'loop', 2, 424);
lane_line(mdl, 'X_open',      1, 'loop', 3, 412);

%% ---- thrust map and hull ----------------------------------------------
sub = add_subsys(mdl, 'X to n', [530 175 660 245], {'X'}, {'n'}, gnc_colour('allocation'));
add_block('simulink/User-Defined Functions/MATLAB Function', [sub '/map'], ...
          'Position',[180 60 320 180]);
set_mlfcn([sub '/map'], { ...
'function n = map(X)'
'%#codegen'
'%MAP  Demanded surge force -> two equal shaft speeds. Appendix A1 section C.'
'k_pos = 0.02216/2;   k_neg = 0.01289/2;'
'n_max =  sqrt((0.5*24.4*9.81)/k_pos);'
'n_min = -sqrt((0.5*13.6*9.81)/k_neg);'
'T = X/2;'
'if T >= 0'
'    ni =  sqrt(  T  / k_pos);'
'else'
'    ni = -sqrt( -T  / k_neg);'
'end'
'ni = min(max(ni, n_min), n_max);'
'n  = [ni; ni];'}, 'n', '[2 1]');
add_block('simulink/Math Operations/Reshape', [sub '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[380 98 420 142]);
add_line(sub, 'X/1',         'map/1',       'autorouting','smart');
add_line(sub, 'map/1',       'as vector/1', 'autorouting','smart');
add_line(sub, 'as vector/1', 'n/1',         'autorouting','smart');

add_otter_plant(mdl, 'Otter USV', [720 170 900 260], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'loop/1',   'X to n/1',   'autorouting','smart');
add_line(mdl, 'X to n/1', 'Otter USV/1','autorouting','smart');

%% ---- logging and the surge feedback ------------------------------------
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[960 170 1030 210]);
add_block('simulink/Sinks/To Workspace', [mdl '/Xlog'], ...
          'VariableName','Xlog', 'SaveFormat','Structure With Time', ...
          'Position',[530 300 600 340]);
add_line(mdl, 'Otter USV/1', 'xlog/1', 'autorouting','smart');
add_line(mdl, 'loop/1',      'Xlog/1', 'autorouting','smart');

%  u is state 1. Selecting it here rather than muxing the whole vector back
%  keeps the feedback line carrying one signal, which is what it is.
add_block('simulink/Signal Routing/Selector', [mdl '/u'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','1', ...
          'InputPortWidth','12', 'Position',[900 360 950 400]);
add_line(mdl, 'Otter USV/1', 'u/1', 'autorouting','smart');

%  THE FEEDBACK IS A TAG, NOT A LINE.
%
%  Drawn as a line it has to travel the whole width of the model backwards,
%  and it lands on top of the forward path: check_overlaps reported exactly
%  one overlapping pair when it was a line. A Goto/From carries the same
%  signal and leaves the canvas readable. The rule is in
%  simulink-gnc-models/references/model-layout.md — feedback uses tags.
add_block('simulink/Signal Routing/Goto', [mdl '/u out'], ...
          'GotoTag','u_fb', 'Position',[980 368 1030 392]);
add_block('simulink/Signal Routing/From', [mdl '/u in'], ...
          'GotoTag','u_fb', 'Position',[ 60 200 110 224]);
add_line(mdl, 'u/1',    'u out/1', 'autorouting','smart');
add_line(mdl, 'u in/1', 'e/2',     'autorouting','smart');

add_block('simulink/Sinks/Scope', [mdl '/speed'], 'Position',[960 250 990 280]);
add_line(mdl, 'Otter USV/1', 'speed/1', 'autorouting','smart');
set_param([mdl '/speed'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION  -  ALL THREE WEEK 2 PROBLEMS IN ONE MODEL'
''
'   loop_closed = 0        X comes from X_open        Problem 1'
'   loop_closed = 1, Ki=0  proportional only          Problem 2'
'   loop_closed = 1, Ki>0  proportional plus integral Problem 3'
''
'The plant and the thrust map never change. Every difference in the'
'result comes from the controller, and that is the point of the week.'
''
'PROBLEM 2, PREDICTED BEFORE RUNNING'
''
'   u_ss / u_d = Kp K_u / (1 + Kp K_u),   K_u = 0.012894 (m/s)/N'
''
'   Kp = 100  ->  0.8448 m/s against u_d = 1.5, an error of 44 per cent.'
''
'The plant has no free integrator, so the loop is TYPE 0. The steady'
'force the damping demands can only be produced by a NON-ZERO error.'
'No value of Kp removes it.'
''
'PROBLEM 3'
''
'The integrator supplies that steady force instead, so the error goes'
'to zero. The price is a state that keeps acting after the error has'
'passed through zero: overshoot, and under saturation, windup.'}, newline);
a.Position = [40 440 900 720];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end
