function W01_S1_openloop(mdl)
%W01_S1_OPENLOOP  Solution to Week 1, Problem 1 — the open loop, wired by hand.
%
%   >> W01_S1_openloop        builds W01_S1.slx
%   >> W01_check(1,'W01_S1')  checks it
%
%   WHAT THE PROBLEM ASKED
%
%   Drive the hull with a constant command and log the twelve states.
%
%   THE THREE DECISIONS, AND WHY EACH ONE GOES THAT WAY
%
%   1  THE COMMAND IS A 2-VECTOR, NOT A SCALAR. The Otter has two propellers
%      and otter.m expects n = [n_left ; n_right]. A scalar would be accepted
%      by the Constant block and rejected by the plant, and the error message
%      names a dimension rather than the mistake.
%
%   2  BOTH ENTRIES ARE EQUAL. The yaw moment is N = y_p (T_left - T_right),
%      so equal shaft speeds produce no turn. That is what makes Problem 1 a
%      test of surge alone: one number to predict, one to measure.
%
%   3  THE LOG CARRIES ALL TWELVE STATES. Selecting u, v and psi in the model
%      would work, but Week 1 is partly about knowing which index is which,
%      and a full log lets the same model answer Problems 2 and 3 without
%      being rewired.
%
%   THE NUMBER TO PREDICT BEFORE RUNNING
%
%   At steady state thrust balances linear surge damping,
%
%       2 k_pos n |n| = X_u u        ->  u = 2 (0.01108)(60)(60) / 77.554
%                                          = 1.0286 m/s
%
%   Section C of the lecture measures 1.0286 m/s. The agreement is exact to
%   four decimals because surge damping in otter.m really is linear.
%
%   See also W01_CHECK, W01_S2_MANOEUVRE, W01_S3_CURRENT.

if nargin < 1 || isempty(mdl), mdl = 'W01_S1'; end

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
add_block('simulink/Sources/Constant', [mdl '/n command'], ...
          'Value','[n0 ; n0]', 'Position',[120 200 200 240]);

%% ---- plant -------------------------------------------------------------
add_otter_plant(mdl, 'Otter USV', [320 160 540 280], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% ---- log ---------------------------------------------------------------
%  The name matters: W01_check looks for a To Workspace block called xlog.
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[660 200 730 240]);

%  A scope on the whole state vector is the cheapest way to see whether the
%  run did anything at all before reading numbers off it.
add_block('simulink/Sinks/Scope', [mdl '/states'], ...
          'Position',[660 290 690 320]);

add_line(mdl, 'n command/1', 'Otter USV/1', 'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'xlog/1',      'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'states/1',    'autorouting','smart');
set_param([mdl '/states'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION 1  -  THE OPEN LOOP'
''
'Constant [n0 ; n0]  ->  Otter USV  ->  To Workspace (xlog)'
''
'Both entries equal, so N = y_p (T_left - T_right) = 0 and nothing turns.'
'The whole run is a test of surge alone.'
''
'   2 k_pos n|n| = X_u u   ->   u = 1.0286 m/s at n = 60 rad/s'
''
'The log carries all twelve states so that Problems 2 and 3 can reuse'
'this model without rewiring it.'}, newline);
a.Position = [110 380 700 560];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end
