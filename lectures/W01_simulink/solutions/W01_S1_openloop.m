function W01_S1_openloop(mdl)
%W01_S1_OPENLOOP  1주차 문제 1 의 모범답안 — 개루프 모델을 손으로 배선한다.
%                 Solution to Week 1, Problem 1: the open loop, wired by hand.
%
%   >> W01_S1_openloop        W01_S1.slx 를 만든다 / builds W01_S1.slx
%   >> W01_check(1,'W01_S1')  채점한다 / checks it
%
%   문제가 요구한 것 / what the problem asked
%       선체에 상수 명령을 주어 구동하고 열두 개의 상태를 기록할 것.
%       Drive the hull with a constant command and log the twelve states.
%
%   세 가지 판단과 그 근거 / the three decisions, and why each goes that way
%
%   1  명령은 스칼라가 아니라 2 차원 벡터이다.
%      Otter 는 프로펠러가 둘이고 otter.m 은 n = [n_left ; n_right] 를 기대한다.
%      스칼라를 주면 Constant 블록은 받아 주지만 플랜트가 거절하며, 그때 나오는
%      오류 메시지는 차원을 말할 뿐 무엇을 잘못했는지는 말해 주지 않는다.
%
%      The command is a 2-vector, not a scalar. The Otter has two propellers
%      and otter.m expects n = [n_left ; n_right]. A scalar is accepted by the
%      Constant block and rejected by the plant, and the resulting message
%      names a dimension rather than the mistake.
%
%   2  두 성분이 같다.
%      요 모멘트가 N = y_pont (T_left - T_right) 이므로 두 회전수가 같으면
%      선회가 생기지 않는다. 그래서 문제 1 은 전진축만의 시험이 된다. 예측할
%      숫자 하나와 측정할 숫자 하나가 있을 뿐이다.
%
%      Both entries are equal. The yaw moment is N = y_pont (T_left - T_right),
%      so equal shaft speeds produce no turn, which is what makes Problem 1 a
%      test of surge alone: one number to predict and one to measure.
%
%   3  로그가 열두 상태를 모두 담는다.
%      모델 안에서 u, v, psi 만 골라내도 동작은 한다. 그러나 어느 자리가 어느
%      상태인지 아는 것도 1주차의 내용이고, 전체를 기록해 두면 같은 모델로
%      문제 2 와 문제 3 을 배선을 바꾸지 않고 풀 수 있다.
%
%      The log carries all twelve states. Selecting u, v and psi inside the
%      model would work, but knowing which index is which is itself part of
%      Week 1, and a full log lets the same model answer Problems 2 and 3
%      without being rewired.
%
%   돌리기 전에 예측할 숫자 / the number to predict before running
%       정상상태에서는 추력과 선형 전진감쇠가 균형을 이룬다.
%       At steady state thrust balances linear surge damping,
%
%       2 k_pos n |n| = X_u u        ->  u = 2 (0.01108)(60)(60) / 77.554
%                                          = 1.0286 m/s
%
%       강의 절 C 의 측정값도 1.0286 m/s 이다. 소수 넷째 자리까지 맞는 것은
%       otter.m 의 전진감쇠가 실제로 선형이기 때문이다.
%       Section C of the lecture measures 1.0286 m/s. The agreement is exact
%       to four decimals because surge damping in otter.m really is linear.
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
