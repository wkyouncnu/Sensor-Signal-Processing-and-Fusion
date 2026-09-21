function W02_P1_start(mdl)
%W02_P1_START  2주차 실습 문제의 출발 모델을 만든다.
%              Create the starting model for the Week 2 laboratory problems.
%
%   >> W02_P1_start                 W02_P1.slx 를 만든다 / creates W02_P1.slx
%   >> W02_P1_start('W02_P1_kim')   다른 이름으로 만든다 / another name
%
%   무엇을 주고 무엇을 주지 않는가 / what this gives, and what it withholds
%       목표값(계단), 플랜트(질량-스프링-댐퍼), 그리고 로그(ylog)를 준다. 제어기는
%       주지 않는다. 오차를 만들고, 세 갈래를 조립하고, 힘을 플랜트에 넣는 것이
%       이 시간의 실습이다.
%       The setpoint (a step), the plant (the mass-spring-damper) and the log
%       (ylog) are given. The controller is not: forming the error, assembling
%       the three terms and driving the plant with the result is the exercise.
%
%   주어지는 블록 / the blocks provided
%       setpoint   Step, 0 -> y_step at t = t_step
%       plant      Transfer Fcn 1/(pid_m s^2 + pid_b s + pid_k). 입력은 힘 tau [N],
%                  출력은 위치 y [m] / input force tau, output position y
%       log        Mux 3 입력 -> To Workspace "ylog" (Structure With Time)
%                  입력 1 = y_d (연결됨), 입력 2 = tau (학생이 연결), 입력 3 = y (연결됨)
%                  input 1 = y_d (wired), 2 = tau (to be wired), 3 = y (wired)
%
%   블록 안의 값은 모두 변수 이름이다. W02_0_setup 이 값을 넣고, W02_check 는 같은
%   이름에 자기 값을 넣어 돌린다. 그러니 제어기의 게인도 숫자가 아니라 Kp, Ki, Kd,
%   Nf, tau_max, Kb 라는 이름으로 적어야 한다.
%   Every block holds a variable name. W02_0_setup fills them in, and
%   W02_check assigns its own values to the same names, so the controller's
%   gains must also be written as the names Kp, Ki, Kd, Nf, tau_max and Kb.
%
%   See also W02_CHECK, W02_0_SETUP.

if nargin < 1 || isempty(mdl), mdl = 'W02_P1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week);
evalin('base', 'W02_0_setup');

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end
new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

add_block('simulink/Sources/Step', [mdl '/setpoint'], ...
          'Time','t_step', 'Before','0', 'After','y_step', 'Position',[60 105 90 135]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/plant'], ...
          'Numerator','[1]', 'Denominator','[pid_m pid_b pid_k]', ...
          'Position',[560 102 620 138], 'BackgroundColor', gnc_colour('plant'));
add_block('simulink/Signal Routing/Mux', [mdl '/log'], ...
          'Inputs','3', 'Position',[760 0 765 300]);
add_block('simulink/Sinks/To Workspace', [mdl '/ylog'], ...
          'VariableName','ylog', 'SaveFormat','Structure With Time', ...
          'Position',[840 135 900 165]);
add_line(mdl, 'setpoint/1', 'log/1', 'autorouting','smart');
add_line(mdl, 'plant/1',    'log/3', 'autorouting','smart');
add_line(mdl, 'log/1',      'ylog/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 2 LABORATORY  -  BUILD THE PID YOURSELF'
''
'The setpoint, the plant and the log are given. The CONTROLLER is the exercise.'
''
'PROBLEM 1   Proportional only. Error, one gain Kp, into the plant.'
'            Measure the steady value and the overshoot at Kp = 2 and 10.'
''
'PROBLEM 2   Add I and D, with no PID Controller block and no Derivative'
'            block. D is one Transfer Fcn: numerator [Kd*Nf 0], denominator [1 Nf].'
''
'PROBLEM 3   Limit the force to |tau| <= tau_max and add back-calculation:'
'            the integrator input becomes Ki e + Kb (tau - u).'
''
'WIRE tau (the force into the plant) to input 2 of the Mux "log".'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W02_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 1 ms.'}, newline);
a.Position = [40 300 760 640];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('\n  created %s\n', out);
fprintf('  open it, build Problem 1, then run:  W02_check(1, ''%s'')\n\n', mdl);
end
