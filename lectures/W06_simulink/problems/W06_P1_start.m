function W06_P1_start(mdl)
%W06_P1_START  6주차 실습 문제의 출발 모델을 만든다.
%              Create the starting model for the Week 6 laboratory problems.
%
%   >> W06_P1_start                 W06_P1.slx 를 만든다 / creates W06_P1.slx
%   >> W06_P1_start('W06_P1_kim')   다른 이름으로 만든다 / another name
%
%   무엇을 주고 무엇을 주지 않는가
%   what this script gives, and what it withholds
%
%   요구를 내는 시간표와 선체를 준다. 그 둘 사이가 비어 있다 —
%   **요구한 힘을 두 축의 회전수로 바꾸는 일**, 그것이 배분이고 이번 주의 전부다.
%
%       demand --> [ your allocator ] --> n --> Otter USV
%
%   It provides the demand timetable and the hull, with the space between them
%   empty. Turning a demanded force into two shaft speeds is allocation, and it
%   is the whole of this week.
%
%   주어지는 블록 / the blocks that are provided
%
%     demand       t -> [X_cmd ; N_cmd], tags X_cmd and N_cmd
%     Otter USV    n -> twelve states
%     xlog         the twelve states
%
%   없는 것, 그래서 문제인 것 / what is missing, and is therefore the exercise
%
%     the allocator, and the log alog
%
%   빈 자리를 Constant [0;0] 이 채우고 있어 모델은 처음부터 돈다. 지우고 자기
%   블록을 그 자리에 넣는다 / a Constant [0;0] holds the place so the model runs
%   from the start; delete it and put the allocator there.
%
%   See also W06_CHECK, W06_0_SETUP, W06_S1_ALLOCATION.

if nargin < 1 || isempty(mdl), mdl = 'W06_P1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

w06_lab_bench(mdl, 120);

%  모델이 처음부터 돌도록 자리를 채우는 상수 / a placeholder so it runs at once
add_block('simulink/Sources/Constant', [mdl '/n placeholder'], ...
          'Value','[0;0]', 'Position', [560 180 700 220]);
add_line(mdl, 'n placeholder/1', 'Otter USV/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 6 LABORATORY  -  BUILD THE ALLOCATOR YOURSELF'
''
'The demand and the hull are given. Only what turns one into the other is'
'missing. Delete the placeholder and put your own allocator in its place.'
''
'PROBLEM 1   The square rule, and the propeller curve. From the demanded'
'            surge force and yaw moment, produce two shaft speeds:'
''
'               T1 = X/2 + N/(2 y_pont)      T2 = X/2 - N/(2 y_pont)'
'               n_i = sign(T_i) sqrt(|T_i| / k)'
''
'PROBLEM 2   Astern is a different curve. k_pos ahead, k_neg astern, chosen'
'            by the SIGN OF THE THRUST. Getting this wrong turns a pure yaw'
'            demand into surge that nobody asked for.'
''
'PROBLEM 3   The demand does not always fit. Put the thrust limits in FRONT'
'            of the curve and choose between the two rules with fit_mode:'
''
'               fit_mode = 0   clip each thrust into [T_min, T_max]'
'               fit_mode = 1   scale BOTH by the one factor s <= 1 that fits'
''
'THE MODEL MUST CONTAIN'
''
'   xlog   To Workspace, Structure With Time, the plant''s 12 states  (given)'
'   alog   To Workspace, Structure With Time, [X_cmd ; N_cmd ; n1 ; n2]'
'          -- the COMMAND and the SHAFT SPEEDS, in that order'
''
'The thrusts are deliberately not logged. The checker recovers them from the'
'shaft speeds through the propeller curve, which is what the hull does, so a'
'wrong curve cannot be hidden by logging the thrust that was intended.'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W06_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [120 430 1040 810];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);

fprintf('\n  created %s   (overlapping lines: %d)\n', out, n);
fprintf('  open it, build Problem 1, then run:  W06_check(1, ''%s'')\n\n', mdl);
end
