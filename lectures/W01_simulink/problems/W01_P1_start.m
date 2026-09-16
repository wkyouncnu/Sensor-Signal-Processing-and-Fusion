function W01_P1_start(mdl)
%W01_P1_START  1주차 실습 문제의 출발 모델을 만든다.
%              Create the starting model for the Week 1 laboratory problems.
%
%   >> W01_P1_start                 W01_P1.slx 를 만든다 / creates W01_P1.slx
%   >> W01_P1_start('W01_P1_kim')   다른 이름으로 만든다 / another name
%
%   무엇을 주고 무엇을 일부러 주지 않는가
%   what this script gives, and what it deliberately withholds
%
%       블록 하나만 든 모델을 만든다. 그 하나는 Otter 선체이다. 명령, 배선, 로깅,
%       스코프 등 나머지 전부가 문제이다.
%
%       선체를 만들게 하지 않고 주는 이유는, otter.m 을 적분하는 일이 1주차의
%       교육 내용이 아니고 라이브러리 블록으로 한 시간 안에 조립할 수 있는 것도
%       아니기 때문이다. 반대로 1주차가 실제로 다루는 것들 — 명령이 무엇인지,
%       열두 개의 상태가 각각 무엇을 뜻하는지, 그중 수상정에 필요한 것이 무엇인지
%       — 은 모두 열어 둔다.
%
%       The model contains one block: the Otter hull. Everything else — the
%       command, the wiring, the logging, the scope — is the exercise. The
%       hull is given rather than built because integrating otter.m is not the
%       lesson of Week 1 and cannot be assembled from library blocks in an
%       hour, whereas everything Week 1 is about is left open.
%
%   주어지는 블록 / the block that is provided
%
%     Otter USV        입력 1 : n, 두 축의 회전수 [rad/s], 2 x 1
%                      출력 1 : x, 열두 개의 상태
%                      Inport  1 : n, the two shaft speeds [rad/s], 2 x 1
%                      Outport 1 : x, the twelve states
%
%                      x = [ u v w  p q r  x y z  phi theta psi ]'
%                          |_ 속도 _||_ 위치 _||_ 자세각 _|
%                          |_ velocities _||_ position _||_ angles _|
%
%   솔버 설정 / the solver
%       이번 주가 쓰는 값으로 이미 맞추어 두었다. 고정 스텝, ode4, h = 0.02 s 이며
%       W01_0_setup 에서 온 값이다. 채점기가 대조하는 수치들이 이 설정에서 측정된
%       것이므로 바꾸지 않는다.
%       Already set to the values this week uses — fixed step, ode4, h = 0.02 s
%       — taken from W01_0_setup. They must not be changed, because the numbers
%       the checker compares against were measured with them.
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
