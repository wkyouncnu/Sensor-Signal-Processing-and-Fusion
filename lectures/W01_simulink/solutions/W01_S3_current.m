function W01_S3_current(mdl)
%W01_S3_CURRENT  Solution to Week 1, Problem 3 — the vessel in a current.
%
%   >> W01_S3_current         builds W01_S3.slx
%   >> W01_check(3,'W01_S3')  checks it
%
%   WHAT THE PROBLEM ASKED
%
%   Put the vessel in a beam current and measure how far its track leaves its
%   heading. The problem statement says no new blocks are needed, and that is
%   the point of it: the current is already inside otter.m.
%
%   WHY THERE IS NOTHING TO ADD TO THE MODEL
%
%   A current is a VELOCITY, not a force. Nothing is added to the right-hand
%   side of the equation of motion. otter.m rotates the current into the body
%   frame and SUBTRACTS it (lines 79 to 81):
%
%       u_c  = V_c cos(beta_c - psi)
%       v_c  = V_c sin(beta_c - psi)
%       nu_r = nu - [u_c v_c 0 0 0 0]'
%
%   Every hydrodynamic term is then computed from nu_r, the velocity THROUGH
%   THE WATER. The kinematics on line 204 are the exception:
%
%       eta_dot = J(eta) nu          <- nu, not nu_r
%
%   That single asymmetry is the whole phenomenon. The hull feels nu_r, so the
%   forces on it do not change; the position integrates nu, so the vessel is
%   carried along by the water. A current moves a vessel without pushing it.
%
%   THE NUMBERS TO PREDICT BEFORE RUNNING
%
%   With V_c = 0.5 m/s on the beam and the vessel making 1.0286 m/s through
%   the water, the velocity over the ground is the vector sum:
%
%       ground speed  ~  sqrt(1.0286^2 + 0.5^2)  =  1.144 m/s
%       drift         ~  atan(0.5 / 1.0286)      =  25.9 deg
%
%   Section E measures 1.1091 m/s and 25.81 deg. The drift agrees closely; the
%   speed is a little lower than the naive sum because the hull also
%   weathervanes about 4 deg into the flow, which turns part of the current
%   from beam-on to head-on. Cross-flow drag acts on v_r and its line of
%   action does not pass through the origin, so it makes a yaw moment even
%   though no one commanded one.
%
%   See also W01_CHECK, W01_S1_OPENLOOP, W01_S2_MANOEUVRE.

if nargin < 1 || isempty(mdl), mdl = 'W01_S3'; end

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

%  Identical to Solution 1. The current enters through V_c and beta_c, which
%  the plant subsystem already reads as Constant blocks, so the canvas does
%  not change at all between still water and a 0.5 m/s beam current.
add_block('simulink/Sources/Constant', [mdl '/n command'], ...
          'Value','[n0 ; n0]', 'Position',[120 200 200 240]);
add_otter_plant(mdl, 'Otter USV', [320 160 540 280], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[660 200 730 240]);
add_block('simulink/Sinks/Scope', [mdl '/states'], 'Position',[660 290 690 320]);

add_line(mdl, 'n command/1', 'Otter USV/1', 'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'xlog/1',      'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'states/1',    'autorouting','smart');
set_param([mdl '/states'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION 3  -  THE VESSEL IN A CURRENT'
''
'The canvas is IDENTICAL to Solution 1. Nothing was added, because a'
'current is a velocity and not a force.'
''
'   otter.m 79-81   nu_r = nu - [u_c v_c 0 0 0 0]''      forces use nu_r'
'   otter.m 204     eta_dot = J(eta) nu                 position uses nu'
''
'That one asymmetry is the entire phenomenon: the hull feels the water'
'flowing past it, and the ground sees the vessel carried along by it.'
''
'   V_c = 0.5 m/s on the beam   ->   drift  25.81 deg'
'                                    ground speed  1.1091 m/s'
''
'The heading also drifts about 4 deg with no yaw command at all: cross-'
'flow drag acts on v_r and its line of action misses the origin, so it'
'makes a moment. The vessel weathervanes into the flow.'}, newline);
a.Position = [110 380 700 620];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end
