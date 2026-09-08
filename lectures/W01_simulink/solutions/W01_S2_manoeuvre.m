function W01_S2_manoeuvre(mdl)
%W01_S2_MANOEUVRE  Solution to Week 1, Problem 2 — the command becomes a schedule.
%
%   >> W01_S2_manoeuvre       builds W01_S2.slx
%   >> W01_check(2,'W01_S2')  checks it
%
%   WHAT THE PROBLEM ASKED
%
%   Replace the constant command by one that makes the vessel run straight,
%   turn to port, run straight, turn to starboard, and run straight again.
%
%   THE ONE THING THAT DECIDES THE WHOLE ANSWER
%
%   A turn is a DIFFERENCE between the two shaft speeds, not a reversal:
%
%       N = y_p (T_left - T_right),      y_p = 0.395 m
%
%   More thrust on the left turns the bow to STARBOARD. A port turn therefore
%   SLOWS the left propeller. Getting this backwards is the single most common
%   error in this problem, and it is visible immediately: the heading change
%   comes out +70 deg where the checker wants -70 deg.
%
%       straight       n = [n0    ; n0   ]
%       to port        n = [n0-dn ; n0+dn]
%       to starboard   n = [n0+dn ; n0-dn]
%
%   Nothing ever goes astern. At n0 = 60 and dn = 3.5 the slower propeller
%   still pushes ahead at 35.37 N while the faster one pushes at 44.68 N.
%
%   WHY A MATLAB FUNCTION AND NOT A SIGNAL BUILDER
%
%   Either would work. The MATLAB Function block is used because the schedule
%   is a rule and not a drawing: changing t_phase in the setup script changes
%   the manoeuvre without anyone opening the model. A Signal Builder would
%   have to be redrawn.
%
%   THE RESHAPE, AND WHY IT IS NOT OPTIONAL
%
%   A MATLAB Function block whose output is written n = [nL; nR] produces a
%   2-by-1 MATRIX signal. The plant does not care. The LOG does: one matrix
%   input makes the whole To Workspace record 3-dimensional, and the checker
%   then finds one column where it expects twelve. Reshape to a 1-D array.
%
%   See also W01_CHECK, W01_S1_OPENLOOP, W01_S3_CURRENT.

if nargin < 1 || isempty(mdl), mdl = 'W01_S2'; end

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

%% ---- the schedule ------------------------------------------------------
add_block('simulink/Sources/Clock', [mdl '/Clock'], 'Position',[60 196 80 216]);
add_block('simulink/User-Defined Functions/MATLAB Function', [mdl '/schedule'], ...
          'Position',[190 150 330 290]);

%  The tunable numbers arrive as Constant blocks. A MATLAB Function block
%  created from code does not pick up workspace variables on its own, and
%  wiring them in also puts them on the canvas where they can be seen.
K = {'n0','dn','t_phase'};
for i = 1:numel(K)
    add_block('simulink/Sources/Constant', [mdl '/' K{i}], ...
              'Value', K{i}, 'Position', [60 216+42*i 120 246+42*i]);
end

%  The script goes in BEFORE the wiring: schedule/2 does not exist until the
%  function signature says so.
set_mlfcn([mdl '/schedule'], { ...
'function n = schedule(t, n0, dn, t_phase)'
'%#codegen'
'%SCHEDULE  Propeller command as a function of time.'
'%'
'%    straight -> port -> straight -> starboard -> straight'
'%'
'%  A turn is a DIFFERENCE between the two shaft speeds, because the yaw'
'%  moment is N = y_p (T_left - T_right). More thrust on the left turns the'
'%  bow to starboard, so a PORT turn slows the LEFT propeller.'
''
'nL = n0;  nR = n0;'
'if t >= t_phase(1) && t < t_phase(2)'
'    nL = n0 - dn;   nR = n0 + dn;      % port      (bow swings to -psi)'
'elseif t >= t_phase(3) && t < t_phase(4)'
'    nL = n0 + dn;   nR = n0 - dn;      % starboard (bow swings to +psi)'
'end'
'n = [nL; nR];'}, 'n', '[2 1]');

add_block('simulink/Math Operations/Reshape', [mdl '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[380 198 420 242]);

add_line(mdl, 'Clock/1', 'schedule/1', 'autorouting','smart');
for i = 1:numel(K)
    add_line(mdl, [K{i} '/1'], sprintf('schedule/%d', i+1), 'autorouting','smart');
end
add_line(mdl, 'schedule/1', 'as vector/1', 'autorouting','smart');

%% ---- plant and log -----------------------------------------------------
add_otter_plant(mdl, 'Otter USV', [500 160 720 280], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[830 200 900 240]);
add_block('simulink/Sinks/Scope', [mdl '/states'], 'Position',[830 290 860 320]);

add_line(mdl, 'as vector/1', 'Otter USV/1', 'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'xlog/1',      'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'states/1',    'autorouting','smart');
set_param([mdl '/states'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION 2  -  THE MANOEUVRE'
''
'Clock -> schedule (MATLAB Function) -> Reshape -> Otter USV -> xlog'
''
'   straight       n = [n0    ; n0   ]'
'   to port        n = [n0-dn ; n0+dn]      slows the LEFT propeller'
'   to starboard   n = [n0+dn ; n0-dn]'
''
'because N = y_p (T_left - T_right) with y_p = 0.395 m. Nothing reverses.'
''
'WHAT TO LOOK FOR IN THE RESULT'
''
'v is non-zero in BOTH turns and changes SIGN between them, while Y is'
'exactly zero throughout. The sway comes from the hull rotating - the'
'Coriolis term - and not from any side force. That is the crab angle,'
'and Week 3 has to steer around it.'
''
'The Reshape is not decoration: without it the To Workspace record is'
'3-dimensional and the checker finds one column instead of twelve.'}, newline);
a.Position = [110 380 860 620];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end
