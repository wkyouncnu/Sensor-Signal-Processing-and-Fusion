function W02_S1_pid_loop(mdl)
%W02_S1_PID_LOOP  2주차 실습 세 문제의 모범답안 모델 W02_S1.slx 를 만든다.
%                 Build W02_S1.slx, the reference answer to all three problems.
%
%   >> W02_S1_pid_loop
%   >> W02_check(1,'W02_S1'), W02_check(2,'W02_S1'), W02_check(3,'W02_S1')
%
%   모델 하나가 세 문제를 모두 푼다: 문제 1 은 Ki = Kd = 0, 문제 2 는 tau_max 가 큰 경우이다.
%   One model answers all three: problem 1 is Ki = Kd = 0, problem 2 a large tau_max.
%
%       e = y_d - y,   u = Kp e + I + Kd Nf s/(s + Nf) e,   tau = sat(u),
%       I_dot = Ki e + Kb (tau - u)
%
%   모든 블록이 최상위에 있다. 블록 하나가 식의 기호 하나이다.
%   Every block is on the top level; each block is one symbol of the law.

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
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
               'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
YP = 80;  YD = 200;  YI = 320;  YB = 380;  YF = 440;

%  문제가 준 것 / given: setpoint, plant, log
blk(mdl, 'simulink/Sources/Step', 'setpoint', 55, YD, [30 30], {'Time','t_step','Before','0','After','y_step'});
blk(mdl, 'simulink/Continuous/Transfer Fcn', 'plant', 760, YP, [60 36], ...
    {'Numerator','[1]', 'Denominator','[pid_m pid_b pid_k]', 'BackgroundColor', gnc_colour('plant')});
add_block('simulink/Signal Routing/Mux', [mdl '/log'], 'Inputs','3', 'Position',[900 -150 905 150]);
blk(mdl, 'simulink/Sinks/To Workspace', 'ylog', 990, 0, [60 30], ...
    {'VariableName','ylog', 'SaveFormat','Structure With Time'});

%  답 / the answer
add_sum(mdl, 'e', '+-', [140 YD]);
blk(mdl, 'simulink/Math Operations/Gain', 'Kp', 250, YP, [50 36], {'Gain','Kp'});
blk(mdl, 'simulink/Continuous/Transfer Fcn', 'D filter', 260, YD, [60 36], ...
    {'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]'});
blk(mdl, 'simulink/Math Operations/Gain', 'Ki', 225, YI, [50 36], {'Gain','Ki'});
add_sum(mdl, 'into I', '++', [300 YI]);
blk(mdl, 'simulink/Continuous/Integrator', 'I', 355, YI, [30 30], {'InitialCondition','0'});
add_sum(mdl, 'p+d', '++', [460 YP]);
add_sum(mdl, 'u', '++', [520 YP]);
blk(mdl, 'simulink/Discontinuities/Saturation', 'limit', 585, YP, [30 30], ...
    {'UpperLimit','tau_max', 'LowerLimit','-tau_max'});
add_sum(mdl, 'tau - u', '+-', [640 250]);
blk(mdl, 'simulink/Math Operations/Gain', 'Kb', 585, YB, [50 36], {'Gain','Kb', 'Orientation','left'});

route(mdl, 'setpoint', 1, 'e', 1, zeros(0,2));
route(mdl, 'e', 1, 'Kp', 1, [180 YD; 180 YP]);
route(mdl, 'e', 1, 'D filter', 1, zeros(0,2));
route(mdl, 'e', 1, 'Ki', 1, [180 YD; 180 YI]);
route(mdl, 'Ki', 1, 'into I', 1, zeros(0,2));
route(mdl, 'into I', 1, 'I', 1, zeros(0,2));
route(mdl, 'Kp', 1, 'p+d', 1, zeros(0,2));
route(mdl, 'D filter', 1, 'p+d', 2, [460 YD]);
route(mdl, 'p+d', 1, 'u', 1, zeros(0,2));
route(mdl, 'I', 1, 'u', 2, [520 YI]);
route(mdl, 'u', 1, 'limit', 1, zeros(0,2));
route(mdl, 'limit', 1, 'plant', 1, zeros(0,2));
route(mdl, 'limit', 1, 'tau - u', 1, [660 YP; 660 215; 615 215; 615 250]);
route(mdl, 'u', 1, 'tau - u', 2, [545 YP; 545 280; 640 280]);
qk = port_xy(mdl, 'Kb', 'Inport', 1);
route(mdl, 'tau - u', 1, 'Kb', 1, [680 250; 680 qk(2)]);
qk = port_xy(mdl, 'Kb', 'Outport', 1);
route(mdl, 'Kb', 1, 'into I', 2, [300 qk(2)]);
route(mdl, 'plant', 1, 'e', 2, [820 YP; 820 YF; 140 YF]);

%  로그 [y_d tau y] / the log
q = port_xy(mdl, 'log', 'Inport', 1);  route(mdl, 'setpoint', 1, 'log', 1, [100 YD; 100 q(2)]);
q = port_xy(mdl, 'log', 'Inport', 2);  route(mdl, 'limit', 1, 'log', 2, [700 YP; 700 q(2)]);
q = port_xy(mdl, 'log', 'Inport', 3);  route(mdl, 'plant', 1, 'log', 3, [840 YP; 840 q(2)]);
route(mdl, 'log', 1, 'ylog', 1, zeros(0,2));
for nm = {'e','into I','p+d','u','tau - u'}, set_param([mdl '/' nm{1}], 'NamePlacement','alternate'); end

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({'SOLUTION  -  ALL THREE WEEK 2 PROBLEMS IN ONE MODEL', '', ...
  '   u = Kp e + I + Kd Nf s/(s + Nf) e,   tau = sat(u),   I_dot = Ki e + Kb (tau - u)', '', ...
  'Problem 1: Ki = Kd = 0.  Problem 2: tau_max large.  Problem 3: as built.', ...
  'W02_check sets the gains by name.'}, newline);
a.Position = [40 490 760 590];  a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);
fprintf('  built  %s   (overlapping lines: %d)\n', out, n);
end

function blk(m, lib, name, cx, cy, wh, params)
add_block(lib, [m '/' name], 'Position', [cx-wh(1)/2 cy-wh(2)/2 cx+wh(1)/2 cy+wh(2)/2], params{:});
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; round(via); b]);
end
