function W04_S1_los(mdl)
%W04_S1_LOS  Solution to all three Week 4 problems in one model.
%
%   >> W04_S1_los             builds W04_S1.slx
%   >> W04_check(1,'W04_S1')  and 2, and 3
%
%   THE GUIDANCE LAYER, WHICH IS THE WHOLE EXERCISE
%
%       pi_p  = atan2(y_next - y_i,  x_next - x_i)
%       y_e^p = -(x - x_i) sin(pi_p) + (y - y_i) cos(pi_p)
%       psi_d = pi_p - atan(y_e^p / Delta)          law = 1, LOS
%       psi_d = atan2(y_next - y,  x_next - x)      law = 2, atan2
%
%   Both laws live in the same block, selected by `law`, for the same reason
%   Week 2's model held all three controllers: the plant, the autopilot and
%   the allocation must be bit-for-bit identical between the two runs, or the
%   comparison in Problem 2 measures something other than the guidance.
%
%   THE THREE DECISIONS
%
%   1  THE ERROR IS COMPUTED BY ONE ROTATION, not by a distance formula and a
%      sign test. x_e^p and y_e^p are the two components of the SAME vector in
%      the path frame, and taking them together is what makes the along-track
%      coordinate available for free — section F needs it for switching.
%
%   2  atan IS THE ONE-ARGUMENT FORM HERE, deliberately. Delta > 0 always, so
%      the aim-point vector never leaves the right half-plane of {p} and the
%      two-argument form would add nothing. The path angle pi_p, by contrast,
%      MUST be atan2: a leg can point into any quadrant.
%
%   3  psi_d IS NOT WRAPPED IN THE GUIDANCE. The autopilot wraps the ERROR,
%      which is the only place a wrap belongs. Wrapping the command as well
%      would be harmless here and wrong in general, because a wrapped command
%      differentiated for a feed-forward term has a spurious 2-pi jump in it.
%
%   See also W04_CHECK, W04_P1_START, W04_LAB_VESSEL.

if nargin < 1 || isempty(mdl), mdl = 'W04_S1'; end

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

%% ---- the guidance layer ------------------------------------------------
g = add_subsys(mdl, 'Guidance', [110 130 260 250], {'pos'}, {'psi_d','glog'}, ...
               gnc_colour('reference'));
blk = [g '/los'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[260 50 460 240]);
set_mlfcn(blk, { ...
'function [psi_d, glog] = los(pos, wp, Delta, law)'
'%#codegen'
'%LOS  Line-of-sight guidance on one straight leg.'
'%'
'%  pos   [x ; y] in {n} [m]'
'%  wp    [x_i ; y_i ; x_next ; y_next] — the active leg, in {n} [m]'
'%  law   1 = LOS, 2 = aim at the waypoint (atan2)'
'%'
'%  Returns psi_d [rad] and glog = [pi_p ; y_e_p ; psi_d].'
'x  = pos(1);      y  = pos(2);'
'xi = wp(1);       yi = wp(2);'
'xn = wp(3);       yn = wp(4);'
''
'%  The path-tangential angle MUST be atan2: a leg can point into any'
'%  quadrant, and the one-argument form folds two of them onto the others.'
'pi_p = atan2(yn - yi, xn - xi);'
''
'%  One rotation into the path frame gives BOTH errors. Only y_e is used'
'%  here; x_e is what the switching test of section F reads.'
'dx =  x - xi;   dy =  y - yi;'
'x_e =  dx*cos(pi_p) + dy*sin(pi_p);'   %#ok<NASGU>
'y_e = -dx*sin(pi_p) + dy*cos(pi_p);'
''
'if law < 1.5'
'    %  Delta > 0 always, so the aim-point vector stays in the right'
'    %  half-plane of {p} and the one-argument atan is exact here.'
'    psi_d = pi_p - atan(y_e / Delta);'
'else'
'    psi_d = atan2(yn - y, xn - x);'
'end'
'glog = [pi_p; y_e; psi_d];'}, {'psi_d','glog'}, {'[1 1]','[3 1]'});

add_block('simulink/Sources/Constant', [g '/wp'], ...
          'Value','[WP_N(1); WP_E(1); WP_N(2); WP_E(2)]', ...
          'Position',[70 96 210 130]);
add_block('simulink/Sources/Constant', [g '/Delta'], ...
          'Value','Delta', 'Position',[70 146 210 176]);
add_block('simulink/Sources/Constant', [g '/law'], ...
          'Value','law', 'Position',[70 196 210 226]);
add_line(g, 'pos/1',   'los/1', 'autorouting','smart');
add_line(g, 'wp/1',    'los/2', 'autorouting','smart');
add_line(g, 'Delta/1', 'los/3', 'autorouting','smart');
add_line(g, 'law/1',   'los/4', 'autorouting','smart');
add_line(g, 'los/1',   'psi_d/1', 'autorouting','smart');
add_line(g, 'los/2',   'glog/1',  'autorouting','smart');
set_param([g '/pos'],   'Position',[20  56  50  76]);
set_param([g '/psi_d'], 'Position',[520  90 550 110]);
set_param([g '/glog'],  'Position',[520 160 550 180]);

%% ---- the Week 3 vessel, unchanged --------------------------------------
w04_lab_vessel(mdl, 340);

add_block('simulink/Signal Routing/From', [mdl '/pos in'], ...
          'GotoTag','pos_fb', 'Position',[30 180 80 200]);
add_line(mdl, 'pos in/1',  'Guidance/1', 'autorouting','smart');
add_line(mdl, 'Guidance/1','Heading autopilot/1', 'autorouting','smart');

add_block('simulink/Sinks/To Workspace', [mdl '/glog'], ...
          'VariableName','glog', 'SaveFormat','Structure With Time', ...
          'Position',[300 300 370 340]);
add_line(mdl, 'Guidance/2', 'glog/1', 'autorouting','smart');

add_block('simulink/Sinks/Scope', [mdl '/guidance'], 'Position',[300 380 330 410]);
add_line(mdl, 'Guidance/2', 'guidance/1', 'autorouting','smart');
set_param([mdl '/guidance'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION  -  ALL THREE WEEK 4 PROBLEMS IN ONE MODEL'
''
'   pi_p  = atan2(y_next - y_i,  x_next - x_i)      <- atan2, any quadrant'
'   y_e^p = -(x - x_i) sin(pi_p) + (y - y_i) cos(pi_p)'
'   psi_d = pi_p - atan(y_e^p / Delta)              law = 1   LOS'
'   psi_d = atan2(y_next - y, x_next - x)           law = 2   aim at the point'
''
'Both laws share ONE plant, ONE autopilot and ONE allocation, so the'
'comparison in Problem 2 measures the guidance and nothing else.'
''
'PROBLEM 1   LOS on leg 1. The vessel joins the line and runs along it.'
''
'PROBLEM 2   atan2 reaches the waypoint but never the LINE: it regulates'
'            the distance to a POINT, and a point carries no information'
'            about the line it sits on.'
''
'PROBLEM 3   In a current LOS settles at Delta tan(beta_c) to one side and'
'            STAYS there, with the heading error already zero. That offset'
'            is what sections 4-8 and 4-9 exist to remove.'
''
'The command is NOT wrapped here. The autopilot wraps the ERROR, which is'
'the only place a wrap belongs.'}, newline);
a.Position = [40 470 900 780];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end
