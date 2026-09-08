function W02_P1_start(mdl)
%W02_P1_START  Create the starting model for the Week 2 laboratory problems.
%
%   >> W02_P1_start                 creates W02_P1.slx
%   >> W02_P1_start('W02_P1_kim')   creates a model under another name
%
%   WHAT THIS SCRIPT GIVES, AND WHAT IT WITHHOLDS
%
%   It creates a model containing the hull and the thrust map, wired together
%   and nothing else. The loop is the exercise.
%
%   The thrust map is provided because Week 2 is about the CONTROLLER, not
%   about propellers: turning a demanded surge force into two shaft speeds is
%   Appendix A1's subject, and repeating it here would spend the hour on the
%   wrong thing.
%
%   THE BLOCKS THAT ARE PROVIDED
%
%     X to n           Inport  1 : X, demanded surge force [N]
%                      Outport 1 : n, the two shaft speeds [rad/s]
%
%                      n = sign(X/2/k_pos) sqrt(|X| / (2 k_pos)) on both
%                      shafts, saturated at the Otter's limits. Section A1-C
%                      derives it.
%
%     Otter USV        Inport  1 : n
%                      Outport 1 : x, the twelve states
%
%   WHAT IS MISSING, AND THEREFORE WHAT THE PROBLEMS ARE
%
%     the reference u_d, the summing junction, the controller, the log
%
%   The solver is already set to the values the week uses: fixed step, ode4,
%   h = 0.02 s. Those come from W02_0_setup.m and must not be changed, because
%   the numbers the checker compares against were measured with them.
%
%   See also W02_CHECK, W02_0_SETUP, PROP_THRUST.

if nargin < 1 || isempty(mdl), mdl = 'W02_P1'; end

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

%% ---- the thrust map, given ---------------------------------------------
sub = add_subsys(mdl, 'X to n', [420 180 560 260], {'X'}, {'n'}, gnc_colour('allocation'));
add_block('simulink/User-Defined Functions/MATLAB Function', [sub '/map'], ...
          'Position',[180 60 320 180]);
set_mlfcn([sub '/map'], { ...
'function n = map(X)'
'%#codegen'
'%MAP  Demanded surge force -> two equal shaft speeds.'
'%'
'%  Both propellers share the load, so each provides X/2, and the thrust of'
'%  one propeller is T = k_pos n|n| ahead, k_neg n|n| astern. Inverting that'
'%  and saturating at the Otter''s shaft limits gives the command.'
'%'
'%  Derived in Appendix A1 section C. Provided here so that Week 2 spends'
'%  its hour on the controller.'
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

%% ---- the hull, given ---------------------------------------------------
add_otter_plant(mdl, 'Otter USV', [640 180 860 300], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'X to n/1', 'Otter USV/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 2 LABORATORY  -  CLOSE THE SPEED LOOP YOURSELF'
''
'The hull and the thrust map are given. The LOOP is the exercise.'
''
'PROBLEM 1   Open loop. Drive X directly with a Constant and confirm the'
'            plant really is first order:  u_ss = K_u X  with'
'            K_u = 0.012894 (m/s)/N. Add a To Workspace named  xlog  and'
'            a second one named  Xlog  carrying the demanded force.'
''
'PROBLEM 2   Proportional control. Add u_d, a summing junction and a gain.'
'            Predict the steady-state error from Kp K_u / (1 + Kp K_u)'
'            BEFORE running, then measure it. It is never zero.'
''
'PROBLEM 3   Add the integrator. Show that the error goes to zero, and'
'            that the price is overshoot the P controller did not have.'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W02_check(1, ''' mdl ''')      and 2, and 3']
''
'The checker runs your model and compares it with the numbers measured in'
'sections C, D and E of the lecture.'
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [40 340 840 680];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);

fprintf('\n  created %s\n', out);
fprintf('  open it, build Problem 1, then run:  W02_check(1, ''%s'')\n\n', mdl);
end
