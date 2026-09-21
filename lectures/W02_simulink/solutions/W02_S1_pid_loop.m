function W02_S1_pid_loop(mdl)
%W02_S1_PID_LOOP  2주차 실습 세 문제의 모범답안 모델 W02_S1.slx 를 만든다.
%                 Build W02_S1.slx, the reference answer to all three problems.
%
%   >> W02_S1_pid_loop
%   >> W02_check(1,'W02_S1'), W02_check(2,'W02_S1'), W02_check(3,'W02_S1')
%
%   왜 모델 하나로 세 문제를 푸는가 / why one model answers all three
%       문제 1 은 Ki = Kd = 0 인 문제 3 이고, 문제 2 는 tau_max 를 크게 둔 문제 3 이다.
%       식 하나에 게인만 다르다. 채점기가 이름으로 값을 넣으므로 같은 모델이 세
%       문제를 모두 통과한다.
%       Problem 1 is problem 3 with Ki = Kd = 0, and problem 2 is problem 3
%       with a large tau_max: one law, different gains. The checker assigns
%       values by name, so the same model passes all three.
%
%   제어기 / the controller (subsystem "PID by hand")
%       e     = y_d - y
%       p     = Kp e
%       d     = Nf (Kd e - x),      x_dot = d          거른 미분 / filtered derivative
%       i_dot = Ki e + Kb (tau - u)                    되감기 / back-calculation
%       u     = p + i + d,          tau = sat(u)       |tau| <= tau_max
%
%   블록은 Gain, Sum, Integrator, Saturation 뿐이다. PID 블록도 Derivative 블록도
%   쓰지 않는다 — 문제 2 의 조건이며, 그래야 각 블록이 식의 어느 항인지 보인다.
%   Only Gain, Sum, Integrator and Saturation blocks: no PID block and no
%   Derivative block, as problem 2 requires, so that every block can be named
%   as a term of the law.

if nargin < 1 || isempty(mdl), mdl = 'W02_S1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'));
evalin('base', 'W02_0_setup');

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end
new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%% ---- 문제에서 주어진 것 / what the problem gives ---------------------------
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

%% ---- 답 / the answer ---------------------------------------------------
c = add_subsys(mdl, 'PID by hand', [250 90 400 170], {'y_d','y'}, {'tau'}, ...
               gnc_colour('controller'));
build_law(c);
q = port_xy(mdl, 'PID by hand', 'Inport', 1);
p = get_param([mdl '/PID by hand'], 'Position');
set_param([mdl '/PID by hand'], 'Position', p + [0 120-q(2) 0 120-q(2)]);

%  플랜트를 제어기 출력의 높이로 옮긴다 — tau 가 곧은 한 도막으로 들어간다.
%  The plant moves to the height of the controller's output, so tau enters it
%  on one straight segment.
po = port_xy(mdl, 'PID by hand', 'Outport', 1);
p  = get_param([mdl '/plant'], 'Position');
set_param([mdl '/plant'], 'Position', [p(1) po(2)-18 p(3) po(2)+18]);

route(mdl, 'setpoint', 1, 'PID by hand', 1, zeros(0,2));
route(mdl, 'PID by hand', 1, 'plant', 1, zeros(0,2));
qt = port_xy(mdl, 'log', 'Inport', 2);
%  로그로 가는 tau 는 플랜트 아래로 돌아간다 — 곧장 가면 플랜트 블록을 가로지른다.
%  tau goes to the log underneath the plant; straight across it would run
%  through the plant block.
route(mdl, 'PID by hand', 1, 'log', 2, [480 po(2); 480 po(2)+45; 720 po(2)+45; 720 qt(2)]);
q1 = port_xy(mdl, 'log', 'Inport', 1);
route(mdl, 'setpoint', 1, 'log', 1, [180 120; 180 q1(2)]);
q3 = port_xy(mdl, 'log', 'Inport', 3);
route(mdl, 'plant', 1, 'log', 3, [680 po(2); 680 q3(2)]);
q2 = port_xy(mdl, 'PID by hand', 'Inport', 2);
route(mdl, 'plant', 1, 'PID by hand', 2, [680 po(2); 680 330; 210 330; 210 q2(2)]);
route(mdl, 'log', 1, 'ylog', 1, zeros(0,2));

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION  -  ALL THREE WEEK 2 PROBLEMS IN ONE MODEL'
''
'Problem 1 is this model with Ki = Kd = 0. Problem 2 is this model with'
'tau_max large. Problem 3 is this model. W02_check sets the gains by name.'
''
'Open "PID by hand": every block is one term of'
'    u = Kp e + i + d,   d = Nf (Kd e - x), x_dot = d,'
'    i_dot = Ki e + Kb (tau - u),   tau = sat(u).'}, newline);
a.Position = [40 360 760 520];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);
fprintf('  built  %s   (overlapping lines: %d)\n', out, n);
end

% =========================================================================
function build_law(c)
%  세 줄: 위에서부터 P, D, I. I 를 맨 아래에 두면 되감기 선이 아래에서 곧장
%  적분기 합산점으로 올라와 다른 선을 건너지 않는다.
%  Three rows, P, D and I from the top. With I at the bottom the
%  back-calculation line comes up into the integrator's junction from below
%  without crossing anything.
YP = 80;  YD = 200;  YI = 320;
set_param([c '/y_d'], 'Position',[40 YD-7 70 YD+7]);
set_param([c '/y'],   'Position',[40 YD+53 70 YD+67]);
add_sum(c, 'e', '+-', [120 YD]);
route(c, 'y_d', 1, 'e', 1, zeros(0,2));
route(c, 'y', 1, 'e', 2, [120 YD+60]);

%  P
add_block('simulink/Math Operations/Gain', [c '/Kp'], 'Gain','Kp', ...
          'Position',[250 YP-18 300 YP+18]);
route(c, 'e', 1, 'Kp', 1, [170 YD; 170 YP]);

%  D, filtered: d = Nf (Kd e - x), x_dot = d
add_block('simulink/Math Operations/Gain', [c '/Kd'], 'Gain','Kd', ...
          'Position',[200 YD-18 250 YD+18]);
add_sum(c, 'Kd e - x', '+-', [290 YD]);
add_block('simulink/Math Operations/Gain', [c '/Nf'], 'Gain','Nf', ...
          'Position',[330 YD-18 380 YD+18]);
add_block('simulink/Continuous/Integrator', [c '/x'], 'InitialCondition','0', ...
          'Orientation','left', 'Position',[330 YD+45 360 YD+75]);
route(c, 'e', 1, 'Kd', 1, zeros(0,2));
route(c, 'Kd', 1, 'Kd e - x', 1, zeros(0,2));
route(c, 'Kd e - x', 1, 'Nf', 1, zeros(0,2));
qx = port_xy(c, 'x', 'Inport', 1);
route(c, 'Nf', 1, 'x', 1, [400 YD; 400 qx(2)]);
qo = port_xy(c, 'x', 'Outport', 1);
route(c, 'x', 1, 'Kd e - x', 2, [290 qo(2)]);

%  I with back-calculation
add_block('simulink/Math Operations/Gain', [c '/Ki'], 'Gain','Ki', ...
          'Position',[200 YI-18 250 YI+18]);
add_sum(c, 'into I', '++', [300 YI]);
add_block('simulink/Continuous/Integrator', [c '/I'], 'InitialCondition','0', ...
          'Position',[340 YI-15 370 YI+15]);
route(c, 'e', 1, 'Ki', 1, [170 YD; 170 YI]);
route(c, 'Ki', 1, 'into I', 1, zeros(0,2));
route(c, 'into I', 1, 'I', 1, zeros(0,2));

%  u = p + d + i, tau = sat(u)
add_sum(c, 'p+d', '++', [460 YP]);
add_sum(c, 'u', '++', [520 YP]);
add_block('simulink/Discontinuities/Saturation', [c '/limit'], ...
          'UpperLimit','tau_max', 'LowerLimit','-tau_max', ...
          'Position',[570 YP-15 600 YP+15]);
set_param([c '/tau'], 'Position',[720 YP-7 750 YP+7]);
route(c, 'Kp', 1, 'p+d', 1, zeros(0,2));
route(c, 'Nf', 1, 'p+d', 2, [460 YD]);
route(c, 'I', 1, 'u', 2, [520 YI]);
route(c, 'p+d', 1, 'u', 1, zeros(0,2));
route(c, 'u', 1, 'limit', 1, zeros(0,2));
route(c, 'limit', 1, 'tau', 1, zeros(0,2));

%  back-calculation: i_dot gets Kb (tau - u)
add_sum(c, 'tau - u', '+-', [620 250]);
add_block('simulink/Math Operations/Gain', [c '/Kb'], 'Gain','Kb', ...
          'Orientation','left', 'Position',[560 402 610 438]);
route(c, 'limit', 1, 'tau - u', 1, [640 YP; 640 210; 590 210; 590 250]);
route(c, 'u', 1, 'tau - u', 2, [545 YP; 545 280; 620 280]);
qk = port_xy(c, 'Kb', 'Inport', 1);
route(c, 'tau - u', 1, 'Kb', 1, [660 250; 660 qk(2)]);
qk = port_xy(c, 'Kb', 'Outport', 1);
route(c, 'Kb', 1, 'into I', 2, [300 qk(2)]);

for nm = {'e','into I','Kd e - x','p+d','u','tau - u'}
    set_param([c '/' nm{1}], 'NamePlacement','alternate');
end
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end
