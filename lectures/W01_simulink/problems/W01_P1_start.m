function W01_P1_start(mdl)
%W01_P1_START  Create the starting model for the Week 1 laboratory problems.
%
%   >> W01_P1_start                 creates W01_P1.slx
%   >> W01_P1_start('W01_P1_kim')   creates a model under another name
%
%   WHAT THIS SCRIPT GIVES, AND WHAT IT DELIBERATELY WITHHOLDS
%
%   It creates a model containing ONE block: the Otter hull. Everything else —
%   the command, the wiring, the logging, the scope — is the exercise.
%
%   The hull is given rather than built because integrating otter.m is not the
%   lesson of Week 1 and cannot be assembled from library blocks in an hour.
%   Everything that Week 1 IS about — what the command is, what the twelve
%   states mean, which of them matter for a surface craft — is left open.
%
%   THE BLOCK THAT IS PROVIDED
%
%     Otter USV        Inport  1 : n, the two shaft speeds [rad/s], 2 x 1
%                      Outport 1 : x, the twelve states
%
%                      x = [ u v w  p q r  x y z  phi theta psi ]'
%                          |_ velocities _||_ position _||_ angles _|
%
%   The solver is already set to the values the week uses: fixed step, ode4,
%   h = 0.02 s. Those come from W01_0_setup.m and must not be changed, because
%   the numbers the checker compares against were measured with them.
%
%   See also W01_CHECK, W01_0_SETUP.

if nargin < 1 || isempty(mdl), mdl = 'W01_P1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);                       % ...\W01_simulink
root = fileparts(fileparts(week));            % ...\00_GradCourse_2026
addpath(fullfile(root,'_tools'), week);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

add_otter_plant(mdl, 'Otter USV', [400 160 620 300], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 1 LABORATORY  -  BUILD THE OPEN LOOP YOURSELF'
''
'The hull is given. Everything to its left and right is the exercise.'
''
'PROBLEM 1   Drive the hull with a constant command and log the states.'
'            Add:  Constant [n0 ; n0]  ->  Otter USV  ->  To Workspace'
'            The To Workspace block MUST be named  xlog  and its format'
'            MUST be  Structure With Time. The checker reads that name.'
''
'PROBLEM 2   Replace the Constant by a schedule that makes the vessel run'
'            straight, turn to port, run straight, turn to starboard, and'
'            run straight again. Use a Clock and a MATLAB Function block.'
''
'PROBLEM 3   Put the vessel in a current and measure how far its track'
'            leaves its heading. No new blocks are needed for this one.'
''
'CHECK YOUR WORK AT ANY TIME'
''
%  대괄호로 묶어야 한 칸이 된다. 중괄호 안에서는 빈칸이 원소를 가른다.
['   >> W01_check(1, ''' mdl ''')      and 2, and 3']
''
'The checker runs your model and compares it with the numbers measured in'
'sections C, D and E of the lecture. It prints PASS or FAIL for each test'
'and says what it expected.'
''
'DO NOT CHANGE the solver settings. The numbers were measured with'
'fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [40 40 760 400];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);

fprintf('\n  created %s\n', out);
fprintf('  open it, build Problem 1, then run:  W01_check(1, ''%s'')\n\n', mdl);
end
