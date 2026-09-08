function W03_P1_start(mdl)
%W03_P1_START  Create the starting model for the Week 3 laboratory problems.
%
%   >> W03_P1_start                 creates W03_P1.slx
%   >> W03_P1_start('W03_P1_kim')   creates a model under another name
%
%   WHAT THIS SCRIPT GIVES, AND WHAT IT WITHHOLDS
%
%   It creates a model containing the hull and the control allocation, wired
%   together. The AUTOPILOT is the exercise.
%
%   The allocation is provided because turning a demanded yaw moment into two
%   shaft speeds is Appendix A1's subject. Week 3 is about the loop that
%   decides what that moment should be.
%
%   THE BLOCKS THAT ARE PROVIDED
%
%     Control allocation   Inport  1 : tau_N, demanded yaw moment [N m]
%                          Inport  2 : X_ff,  feed-forward surge force [N]
%                          Outport 1 : n, the two shaft speeds [rad/s]
%
%                          T1 = X/2 + N/(2 y_pont),  T2 = X/2 - N/(2 y_pont)
%                          then n = sign(T) sqrt(|T|/k) per propeller.
%
%     Otter USV            Inport  1 : n
%                          Outport 1 : x, the twelve states
%
%   WHAT IS MISSING, AND THEREFORE WHAT THE PROBLEMS ARE
%
%     the heading command, the error, the wrap, the proportional gain,
%     the rate feedback, and the log
%
%   The solver is already set to fixed step, ode4, h = 0.02 s, from
%   W03_0_setup.m. The checker's numbers were measured with those settings.
%
%   See also W03_CHECK, W03_0_SETUP.

if nargin < 1 || isempty(mdl), mdl = 'W03_P1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

add_alloc(mdl, [430 180 590 280]);
add_otter_plant(mdl, 'Otter USV', [670 180 880 290], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'Control allocation/1', 'Otter USV/1', 'autorouting','smart');

add_block('simulink/Sources/Constant', [mdl '/X_ff'], ...
          'Value','X_ff', 'Position',[300 250 360 280]);
add_line(mdl, 'X_ff/1', 'Control allocation/2', 'autorouting','smart');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 3 LABORATORY  -  BUILD THE HEADING AUTOPILOT YOURSELF'
''
'The hull and the allocation are given. The AUTOPILOT is the exercise.'
''
'PROBLEM 1   Proportional only. Step the command to 60 deg and measure the'
'            steady-state error at Kp = 30, 100 and 300. Compare with'
'            Week 2, where the error was 44 per cent at Kp = 100.'
''
'PROBLEM 2   Add rate feedback. Feed back the YAW RATE r, not the'
'            derivative of the error, and show overshoot FALLS as Kd rises.'
''
'PROBLEM 3   The wrap. Command a heading across the +-180 deg seam with and'
'            without the smallest-signed-angle wrap, and watch the vessel'
'            turn the long way round without it.'
''
'THE MODEL MUST CONTAIN'
''
'   xlog   To Workspace, Structure With Time, the plant''s 12 states'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W03_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [40 340 860 700];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);

fprintf('\n  created %s\n', out);
fprintf('  open it, build Problem 1, then run:  W03_check(1, ''%s'')\n\n', mdl);
end

% =========================================================================
function add_alloc(mdl, pos)
%ADD_ALLOC  The control allocation of W03_1_build_heading, given to the student.
%
%  Identical to the lecture's own, so a model built here behaves exactly like
%  W03_heading_control.slx once the autopilot around it is right.
a = add_subsys(mdl, 'Control allocation', pos, {'tau_N','X_ff'}, {'n'}, ...
               gnc_colour('allocation'));
blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[250 60 420 220]);
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

%  Offset so that no constant's centre lands on an inport row (90 or 140).
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
