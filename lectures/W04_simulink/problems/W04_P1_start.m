function W04_P1_start(mdl)
%W04_P1_START  Create the starting model for the Week 4 laboratory problems.
%
%   >> W04_P1_start                 creates W04_P1.slx
%   >> W04_P1_start('W04_P1_kim')   creates a model under another name
%
%   WHAT THIS SCRIPT GIVES, AND WHAT IT WITHHOLDS
%
%   It creates a complete Week 3 vessel — heading autopilot, control
%   allocation, hull — with ONE input left dangling: the commanded heading.
%   Producing that command is guidance, and it is the whole exercise.
%
%       [ your Guidance ] --> psi_d --> Heading autopilot --> allocation --> hull
%
%   That split is the point of the week. Guidance and control are separate
%   layers, and this model makes the seam visible: nothing inside the
%   autopilot changes between Week 3 and Week 4.
%
%   THE BLOCKS THAT ARE PROVIDED
%
%     Heading autopilot    tau_N = Kp ssa(psi_d - psi) - Kd r      (Week 3)
%     Control allocation   tau_N, X_ff -> two shaft speeds         (A1)
%     Otter USV            n -> twelve states
%
%   WHAT IS MISSING, AND THEREFORE WHAT THE PROBLEMS ARE
%
%     the guidance block, and the log
%
%   The waypoints are already in the workspace as WP_N and WP_E, five of them,
%   from W04_vars.m. The starting model wires a Constant of zero into the
%   autopilot so that it compiles before anything is built; replace it.
%
%   See also W04_CHECK, W04_0_SETUP.

if nargin < 1 || isempty(mdl), mdl = 'W04_P1'; end

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

%  A placeholder so the model compiles before the guidance exists.
add_block('simulink/Sources/Constant', [mdl '/psi_d placeholder'], ...
          'Value','0', 'Position',[60 150 180 190]);

w04_lab_vessel(mdl, 260);
add_line(mdl, 'psi_d placeholder/1', 'Heading autopilot/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 4 LABORATORY  -  BUILD THE GUIDANCE LAYER YOURSELF'
''
'A complete Week 3 vessel is given. Only the COMMAND is missing.'
'Delete the placeholder and put your own guidance block in its place.'
''
'PROBLEM 1   The LOS law. From the vessel position and the two waypoints of'
'            the active leg, compute'
''
'               pi_p  = atan2(y_{i+1} - y_i,  x_{i+1} - x_i)'
'               y_e^p = -(x - x_i) sin(pi_p) + (y - y_i) cos(pi_p)'
'               psi_d = pi_p - atan(y_e^p / Delta)'
''
'            Use leg 1 only (waypoint 1 to waypoint 2). No switching yet.'
''
'PROBLEM 2   atan2 against LOS. Replace the law by psi_d = atan2 aimed at the'
'            waypoint and show it cannot hold the LINE, only reach the POINT.'
''
'PROBLEM 3   A current. Turn on V_c and measure the offset LOS is left'
'            holding. Compare it with Delta tan(beta_c).'
''
'THE MODEL MUST CONTAIN'
''
'   xlog   To Workspace, Structure With Time, the plant''s 12 states'
'   glog   To Workspace, Structure With Time, [pi_p ; y_e^p ; psi_d]'
'          -- all three in RADIANS and metres, in that order'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W04_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [40 420 900 800];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);

fprintf('\n  created %s\n', out);
fprintf('  open it, build Problem 1, then run:  W04_check(1, ''%s'')\n\n', mdl);
end
