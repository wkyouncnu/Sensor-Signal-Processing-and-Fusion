function W08_P1_start(mdl)
%W08_P1_START  8주차 실습 문제의 출발 모델을 만든다.
%              Create the starting model for the Week 8 laboratory problems.
%
%   >> W08_P1_start                 W08_P1.slx 를 만든다 / creates W08_P1.slx
%   >> W08_P1_start('W08_P1_kim')   다른 이름으로 만든다 / another name
%
%   무엇을 주고 무엇을 주지 않는가
%   what this script gives, and what it withholds
%
%   임무 논리와 6주차의 배분과 선체를 준다. 그 사이가 비어 있다 — **어디로
%   얼마의 힘이 필요한가**, 그리고 이 선체가 낼 수 없는 방향을 어떻게 할 것인가.
%
%       mission --> [ your controller ] --> X, N --> allocation --> Otter USV
%
%   The mission logic, Week 6's allocation and the hull are given, with the
%   space between them empty: how much force is needed and in which direction,
%   and what to do about the direction this hull cannot push.
%
%   없는 것, 그래서 문제인 것 / what is missing, and is therefore the exercise
%
%     the controller, and the log dlog
%
%   빈 자리를 Constant 0 둘이 채우고 있어 모델은 처음부터 돈다 — 배는 아무것도
%   하지 않고 조류에 떠내려간다. 지우고 자기 블록을 그 자리에 넣는다.
%   Two Constants hold the place so the model runs at once: the vessel does
%   nothing and is carried away by the current. Delete them and build there.
%
%   See also W08_CHECK, W08_0_SETUP, W08_S1_DP.

if nargin < 1 || isempty(mdl), mdl = 'W08_P1'; end

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

w08_lab_bench(mdl, 120);

%  모델이 처음부터 돌도록 자리를 채우는 상수 둘 / two placeholders
CT = {'X_ctrl','N_ctrl'};
for i = 1:2
    add_block('simulink/Sources/Constant', [mdl '/' CT{i} ' placeholder'], ...
              'Value','0', 'Position', [420 620+60*(i-1) 560 660+60*(i-1)]);
    add_block('simulink/Signal Routing/Goto', [mdl '/' CT{i} ' out'], ...
              'GotoTag', CT{i}, 'Position', [610 630+60*(i-1) 680 650+60*(i-1)]);
    add_line(mdl, [CT{i} ' placeholder/1'], [CT{i} ' out/1'], 'autorouting','smart');
end

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 8 LABORATORY  -  BUILD THE POSITION CONTROLLER YOURSELF'
''
'The mission, the allocation and the hull are given. What decides how much'
'force is needed, and in which direction, is not.'
''
'PROBLEM 1   How much force, and how much of it can be delivered. A PID on'
'            the position error in BOTH north and east:'
''
'               f_n = Kp_x e_n + I_n - Kd_x v_n'
'               f_e = Kp_x e_e + I_e - Kd_x v_e'
''
'            Only the along-bow part can reach the propellers:'
''
'               X = f_n cos(psi) + f_e sin(psi)'
''
'            Hold the heading FIXED at psi_fix and watch what happens.'
''
'PROBLEM 2   Point the bow along the force that is needed:'
''
'               psi_d = atan2(f_e, f_n)      while |f| > e_min'
''
'            Then Week 4''s autopilot, gains unchanged:'
''
'               N = Kp ssa(psi_d - psi) - Kd r,   |N| <= N_max'
''
'PROBLEM 3   Three waypoints. Add the transit branch -- a constant push X_ff'
'            and the bow towards the waypoint -- and hand the integral over'
'            at a change of mode, so that a hold does not begin with the'
'            transit''s accumulated demand.'
''
'THE MODEL MUST CONTAIN'
''
'   xlog   To Workspace, Structure With Time, the plant''s 12 states  (given)'
'   mlog   To Workspace, Structure With Time, [N_d ; E_d ; mode]     (given)'
'   dlog   To Workspace, Structure With Time, [psi_d ; X ; N]'
'          -- the heading YOU command, in deg, and the two demands, in N and N m'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W08_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [120 760 1180 1300];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);

fprintf('\n  created %s   (overlapping lines: %d)\n', out, n);
fprintf('  open it, build Problem 1, then run:  W08_check(1, ''%s'')\n\n', mdl);
end
