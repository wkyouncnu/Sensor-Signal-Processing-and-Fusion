function W09_P1_start(mdl)
%W09_P1_START  9주차 실습 문제의 출발 모델을 만든다.
%              Create the starting model for the Week 9 laboratory problems.
%
%   >> W09_P1_start                 W09_P1.slx 를 만든다 / creates W09_P1.slx
%   >> W09_P1_start('W09_P1_kim')   다른 이름으로 만든다 / another name
%
%   이번 주는 거의 전부를 준다 / almost everything is given this week
%
%   9주차는 새 법칙을 만들지 않는다. 그러므로 실습도 제어기를 만들지 않는다.
%   2~8주차가 사슬로 다 얹혀 있고, 비어 있는 자리는 하나다 —
%   **어느 주차의 것도 아닌 조각, 임무 논리.**
%
%       wave -> measurement -> notch -> [ your mission ] -> controller
%                                    -> allocation -> Otter USV
%
%   Week 9 adds no new law, so the laboratory builds no controller. Weeks 2 to
%   8 are all on the chain already, and one place is empty: the piece that
%   belongs to no single week.
%
%   없는 것, 그래서 문제인 것 / what is missing, and is therefore the exercise
%
%     the mission block — [wp ; mode] from where the vessel is — and slog
%
%   빈 자리를 Constant 둘이 채우고 있어 모델은 처음부터 돈다: 배는 첫 지점을
%   향해 이동하고 영원히 거기 머문다. 지우고 자기 블록을 그 자리에 넣는다.
%   Two Constants hold the place so the model runs at once: the vessel transits
%   towards the first waypoint and stays in transit for ever. Replace them.
%
%   See also W09_CHECK, W09_0_SETUP, W09_S1_MISSION.

if nargin < 1 || isempty(mdl), mdl = 'W09_P1'; end

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

w09_lab_bench(mdl, 140);

%  모델이 처음부터 돌도록 자리를 채우는 상수 둘 / two placeholders
MT = {'wp','mode'};  MV = {'1','1'};
for i = 1:2
    add_block('simulink/Sources/Constant', [mdl '/' MT{i} ' placeholder'], ...
              'Value', MV{i}, 'Position', [240 760+60*(i-1) 380 800+60*(i-1)]);
    add_block('simulink/Signal Routing/Goto', [mdl '/' MT{i} ' out'], ...
              'GotoTag', MT{i}, 'Position', [430 770+60*(i-1) 500 790+60*(i-1)]);
    add_line(mdl, [MT{i} ' placeholder/1'], [MT{i} ' out/1'], 'autorouting','smart');
end

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 9 LABORATORY  -  BUILD THE MISSION, THEN MEASURE THE VESSEL'
''
'Weeks 2 to 8 are already on the chain. The empty place is the piece that'
'belongs to none of them: the logic that decides WHERE the vessel is going'
'and WHETHER it has arrived.'
''
'PROBLEM 1   The two rules of the mission. A block with memory, running at'
'            the fixed step h:'
''
'               in transit and reached          -> hold, and reset the clock'
'               in hold and T_hold has passed   -> the next waypoint, transit'
'               after the last one              -> done'
''
'            Use the acceptance circle for `reached`:   d < R_arrive'
''
'PROBLEM 2   That test is not safe. Add the along-track test of Week 5 --'
'            has the vessel gone PAST the waypoint? -- under the switch'
'            use_pass, and find the current at which the two part company:'
''
'               x_left = (p_k - p) . [cos(pi_p) ; sin(pi_p)]'
'               reached = d < R_arrive  ||  (use_pass && x_left < 0)'
''
'PROBLEM 3   No building. Set each of the nine switches to zero in turn and'
'            measure what that week was worth on this mission.'
''
'THE MODEL MUST CONTAIN'
''
'   xlog   To Workspace, Structure With Time, the plant''s 12 states  (given)'
'   plog   To Workspace, Structure With Time, [psi_d ; y_e ; X ; N]  (given)'
'   slog   To Workspace, Structure With Time, [wp ; mode]'
'          -- which waypoint is active, and 1 transit, 2 hold, 3 done'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W09_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [140 900 1200 1400];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);

fprintf('\n  created %s   (overlapping lines: %d)\n', out, n);
fprintf('  open it, build Problem 1, then run:  W09_check(1, ''%s'')\n\n', mdl);
end
