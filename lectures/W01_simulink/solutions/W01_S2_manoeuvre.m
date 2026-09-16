function W01_S2_manoeuvre(mdl)
%W01_S2_MANOEUVRE  1주차 문제 2 의 모범답안 — 명령이 시간표가 된다.
%                  Solution to Week 1, Problem 2: the command becomes a schedule.
%
%   >> W01_S2_manoeuvre       W01_S2.slx 를 만든다 / builds W01_S2.slx
%   >> W01_check(2,'W01_S2')  채점한다 / checks it
%
%   문제가 요구한 것 / what the problem asked
%       상수 명령을 시간표로 바꾸어, 직진 — 좌선회 — 직진 — 우선회 — 직진의
%       순서로 기동하게 할 것.
%       Replace the constant command by one that makes the vessel run
%       straight, turn to port, run straight, turn to starboard, and run
%       straight again.
%
%   답 전체를 좌우하는 한 가지 / the one thing that decides the whole answer
%       선회는 두 축 회전수의 차이로 만드는 것이지 한쪽을 역회전시키는 것이 아니다.
%       A turn is a difference between the two shaft speeds, not a reversal:
%
%       N = y_pont (T_left - T_right),      y_pont = 0.395 m
%
%       왼쪽에 추력을 더 주면 선수가 우현으로 돈다. 따라서 좌선회를 하려면 왼쪽
%       프로펠러를 느리게 해야 한다. 이 문제에서 가장 자주 나오는 실수가 이것을
%       거꾸로 하는 것이며, 결과에 곧바로 드러난다. 채점기가 -70 도를 기대하는
%       자리에 +70 도가 나온다.
%
%       More thrust on the left turns the bow to starboard, so a port turn
%       slows the left propeller. Reversing this is the commonest error in the
%       problem, and it shows at once: the heading change comes out at +70 deg
%       where the checker expects -70 deg.
%
%       직진        n = [n0    ; n0   ]
%       좌선회      n = [n0-dn ; n0+dn]
%       우선회      n = [n0+dn ; n0-dn]
%
%       어느 쪽도 후진하지 않는다. n0 = 60, dn = 3.5 일 때 느린 쪽도 여전히
%       35.37 N 으로 밀고 있고 빠른 쪽은 44.68 N 으로 민다.
%       Nothing ever goes astern: at n0 = 60 and dn = 3.5 the slower propeller
%       still pushes ahead at 35.37 N while the faster one pushes at 44.68 N.
%
%   왜 Signal Builder 가 아니라 MATLAB Function 인가
%   why a MATLAB Function block and not a Signal Builder
%       둘 다 동작한다. MATLAB Function 을 쓴 이유는 이 시간표가 그림이 아니라
%       규칙이기 때문이다. 준비 스크립트의 t_phase 를 고치면 모델을 열지 않고도
%       기동이 바뀐다. Signal Builder 였다면 다시 그려야 한다.
%
%       Either would work. The MATLAB Function block is used because the
%       schedule is a rule rather than a drawing: changing t_phase in the
%       setup script changes the manoeuvre without the model being opened,
%       whereas a Signal Builder would have to be redrawn.
%
%   reshape 이 왜 선택 사항이 아닌가 / the reshape, and why it is not optional
%       출력을 n = [nL; nR] 로 쓴 MATLAB Function 블록은 2 x 1 행렬 신호를 낸다.
%       플랜트는 개의치 않는다. 문제는 로그이다. 행렬 입력이 하나라도 있으면
%       To Workspace 기록 전체가 3 차원이 되고, 채점기는 열두 열을 기대한 자리에서
%       한 열을 발견한다. 1 차원 배열로 reshape 해 두어야 한다.
%
%       A MATLAB Function block whose output is written n = [nL; nR] produces
%       a 2-by-1 matrix signal. The plant does not care, but the log does: one
%       matrix input makes the whole To Workspace record three-dimensional,
%       and the checker then finds one column where it expects twelve.
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
