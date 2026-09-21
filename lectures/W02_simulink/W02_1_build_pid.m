function W02_1_build_pid(which)
%W02_1_BUILD_PID  2주차 실습 모델 열 개를 코드로 만든다 — 절 하나에 모델 하나.
%                 Generate the ten Week 2 models, one model per section.
%
%   실행 / to run
%       W02_1_build_pid                  열 개 전부 / all ten
%       W02_1_build_pid('W02_E_PID')     하나만 / one of them
%
%   강의에서의 위치 / place in the lecture
%       Part 2 절 A 이다. 절 B~I 가 각자 자기 모델을 연다. 모델을 열고 Run 을 누르면
%       캔버스의 Scope 하나에 위치(목표와 응답)와 힘(과 그 항들)이 함께 뜬다.
%       명령창에서 Kp 를 바꾸고 다시 Run 을 누르면 바뀐 응답이 바로 보인다.
%       Section A of Part 2. Sections B to I each open their own model. Opening
%       a model and pressing Run shows, in one Scope on the canvas, the position
%       (setpoint and response) and the force (with its terms). Changing Kp in
%       the Command Window and pressing Run again shows the new response at once.
%
%   모델 / the models
%       W02_B_three_ways    제어기 없는 플랜트, 미분방정식·전달함수·상태공간 세 줄
%                           the plant with no controller, as ODE, transfer function, state space
%       W02_B_second_order  표준 2차 시스템, zeta 와 wn 만 바꾼다
%                           the standard second-order system; only zeta and wn change
%       W02_G_derivative_bench  루프 없이 미분 두 가지 / two derivatives, no loop
%       W02_C_P             P 만                         / P only
%       W02_D_PD            P + D                        / P + D
%       W02_E_PID           P + I + D                    / P + I + D
%       W02_F_block_vs_hand 라이브러리 PID 블록과 손으로 만든 PID, 한계와 잡음 아래에서
%                           the library PID block against the hand-built law,
%                           with a force limit and sensor noise
%       W02_G_noise_kick    PID + 센서 잡음 + 부드러운 목표값 + 순수 미분 스위치
%                           PID with sensor noise, a smoothed setpoint and a
%                           pure-derivative switch
%       W02_H_antiwindup    PID + 힘의 한계 + 되감기 / PID with a limit and back-calculation
%       W02_I_tuning        PID + 부드러운 목표값 / PID with a smoothed setpoint
%
%   모든 블록이 최상위 캔버스에 있다. 서브시스템으로 감추지 않는다 — 블록 하나가
%   식의 기호 하나이므로, 캔버스를 읽으면 식을 읽는 것이다. 미분항은 전달함수
%   블록 하나, Kd Nf s/(s + Nf) 이다.
%   Every block is on the top-level canvas; nothing is hidden in a subsystem.
%   Each block is one symbol of the law, so reading the canvas is reading the
%   equation. The derivative is one Transfer Fcn block, Kd Nf s/(s + Nf).
%
%   기록할 신호는 Goto 태그로 오른쪽의 Scope 와 로그로 간다. 긴 선이 루프를
%   가로지르지 않게 하려는 것이다.
%   The logged signals travel by Goto tag to the Scope and the log on the
%   right, so that no long line has to cross the loop.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W02_0_setup');

M = struct( ...
  'name',  {'W02_C_P','W02_D_PD','W02_E_PID','W02_F_block_vs_hand','W02_G_noise_kick','W02_H_antiwindup','W02_I_tuning'}, ...
  'D',     {false, true,  true,  true,  true,  true,  true }, ...
  'I',     {false, false, true,  true,  true,  true,  true }, ...
  'limit', {false, false, false, true,  false, true,  false}, ...
  'noise', {false, false, false, true,  true,  false, false}, ...
  'smooth',{false, false, false, false, true,  false, true }, ...
  'pure',  {false, false, false, false, true,  false, false}, ...
  'block', {false, false, false, true,  false, true,  false}, ...
  'twostep',{false, false, false, false, false, true,  false}, ...
  'mode',  {'', '', '', 'back-calculation', '', 'clamping', ''}, ...
  'title', {'P ONLY', 'P + D', 'P + I + D', 'THE PID BLOCK AGAINST THE SAME LAW BY HAND', ...
            'NOISE, AND THE CORNER OF A STEP', 'A FORCE LIMIT, AND ANTI-WINDUP', ...
            'THE TUNING ORDER'}, ...
  'sec',   {'C','D','E','F','G','H','I'});
if nargin == 1, M = M(strcmp({M.name}, which)); end

for k = 1:numel(M)
    build_one(M(k), here);
end
if nargin == 0 || strcmp(which, 'W02_G_derivative_bench'), build_bench(here); end
if nargin == 0 || strcmp(which, 'W02_B_three_ways'),       build_three(here); end
if nargin == 0 || strcmp(which, 'W02_B_second_order'),     build_second(here); end
end

% =========================================================================
%  플랜트 하나를 세 가지로 (절 B) — 제어기 없이, 같은 힘을 세 줄에 넣는다
%  One plant written three ways (section B): no controller, one force, three rows
%
%      A  미분방정식 그대로: m x'' = F - b x' - k x 를 적분기 두 개로
%         the equation of motion itself, with two integrators
%      B  전달함수 1/(m s^2 + b s + k)          초기조건을 담지 못한다 / holds no initial condition
%      C  상태공간 x = [위치; 속도] / [position; velocity]
function build_three(here)
m = 'W02_B_three_ways';
m0 = new_model(m, here);
Y = 100;
blk(m, 'simulink/Sources/Step', 'force F', 50, 240, [30 30], ...
    {'Time','t_step', 'Before','0', 'After','F_step'});

% A: 적분기 두 개 / two integrators
add_sum(m, 'spring', '+-', [150 Y]);
add_sum(m, 'damper', '+-', [230 Y]);
blk(m, 'simulink/Math Operations/Gain', 'divide by m', 300, Y, [70 36], {'Gain','1/pid_m'});
blk(m, 'simulink/Continuous/Integrator', 'velocity', 400, Y, [30 30], {'InitialCondition','x0_vel'});
blk(m, 'simulink/Continuous/Integrator', 'position', 490, Y, [30 30], {'InitialCondition','x0_pos'});
blk(m, 'simulink/Math Operations/Gain', 'b', 320, 160, [50 30], {'Gain','pid_b', 'Orientation','left', 'ShowName','off'});
blk(m, 'simulink/Math Operations/Gain', 'k', 320, 205, [50 30], {'Gain','pid_k', 'Orientation','left', 'ShowName','off'});
set_param([m '/spring'], 'NamePlacement','alternate');
set_param([m '/damper'], 'NamePlacement','alternate');
route(m, 'force F', 1, 'spring', 1, [100 240; 100 Y]);
route(m, 'spring', 1, 'damper', 1, zeros(0,2));
route(m, 'damper', 1, 'divide by m', 1, zeros(0,2));
route(m, 'divide by m', 1, 'velocity', 1, zeros(0,2));
route(m, 'velocity', 1, 'position', 1, zeros(0,2));
route(m, 'velocity', 1, 'b', 1, [440 Y; 440 160]);
route(m, 'b', 1, 'damper', 2, [230 160]);
route(m, 'position', 1, 'k', 1, [530 Y; 530 205]);
route(m, 'k', 1, 'spring', 2, [150 205]);
goto_at(m, {'position', 1}, [550 Y], 'up', 'x_ode');

% B: 전달함수 / transfer function
blk(m, 'simulink/Continuous/Transfer Fcn', 'transfer function', 300, 240, [110 40], ...
    {'Numerator','[1]', 'Denominator','[pid_m pid_b pid_k]', 'BackgroundColor', gnc_colour('plant')});
route(m, 'force F', 1, 'transfer function', 1, zeros(0,2));

% C: 상태공간 / state space
blk(m, 'simulink/Continuous/State-Space', 'state space', 300, 320, [110 40], ...
    {'A','[0 1; -pid_k/pid_m -pid_b/pid_m]', 'B','[0; 1/pid_m]', 'C','[1 0]', 'D','0', ...
     'InitialCondition','[x0_pos; x0_vel]', 'BackgroundColor', gnc_colour('plant')});
route(m, 'force F', 1, 'state space', 1, [100 240; 100 320]);

add_block('simulink/Signal Routing/Mux', [m '/three'], 'Inputs','3', 'Position',[700 60 705 360]);
q = port_xy(m, 'three', 'Inport', 1);
add_block('simulink/Signal Routing/From', [m '/From x_ode'], 'GotoTag','x_ode', 'ShowName','off', ...
          'Position', [590 q(2)-10 640 q(2)+10]);
h1 = route(m, 'From x_ode', 1, 'three', 1, zeros(0,2));
set_param([m '/Goto x_ode'], 'ShowName','off');
q = port_xy(m, 'three', 'Inport', 2);  h2 = route(m, 'transfer function', 1, 'three', 2, [660 240; 660 q(2)]);
q = port_xy(m, 'three', 'Inport', 3);  h3 = route(m, 'state space', 1, 'three', 3, [670 320; 670 q(2)]);
set_param(h1, 'Name','A  ODE');  set_param(h2, 'Name','B  TF');  set_param(h3, 'Name','C  SS');
finish_scope(m, 'three', 780);
a = Simulink.Annotation([m '/note']);
a.Text = strjoin({'WEEK 2, SECTION B  -  ONE PLANT, WRITTEN THREE WAYS (no controller)', '', ...
  '   A   m x'''' = F - b x'' - k x         two integrators: acceleration -> velocity -> position', ...
  '   B   X(s)/F(s) = 1 / (m s^2 + b s + k)   one Transfer Fcn block', ...
  '   C   d/dt [x; v] = [0 1; -k/m -b/m] [x; v] + [0; 1/m] F,   x = [1 0] [x; v]', '', ...
  'Run: the three lines lie on top of each other and settle at F/k = 0.5 m.', ...
  'Then set F_step = 0; x0_pos = 0.5 and Run: A and C swing back from 0.5 m,', ...
  'B stays at zero - a transfer function has no place for an initial condition.'}, newline);
a.Position = [40 400 700 540];  a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
save_model(m, m0, here);
end

% =========================================================================
%  표준 2차 시스템 (절 B) — 두 숫자 zeta 와 wn 만 바꿔 본다
%  The standard second-order system (section B): only zeta and wn change
function build_second(here)
m = 'W02_B_second_order';
m0 = new_model(m, here);
blk(m, 'simulink/Sources/Step', 'step', 60, 150, [30 30], ...
    {'Time','t_step', 'Before','0', 'After','y_step'});
blk(m, 'simulink/Continuous/Transfer Fcn', 'standard form', 260, 150, [150 40], ...
    {'Numerator','[wn^2]', 'Denominator','[1 2*zeta*wn wn^2]', 'BackgroundColor', gnc_colour('plant')});
route(m, 'step', 1, 'standard form', 1, zeros(0,2));
add_block('simulink/Signal Routing/Mux', [m '/two'], 'Inputs','2', 'Position',[480 90 485 210]);
goto_at(m, {'step', 1}, [110 150], 'up', 'y_d');
set_param([m '/Goto y_d'], 'ShowName','off');
q = port_xy(m, 'two', 'Inport', 1);
add_block('simulink/Signal Routing/From', [m '/From y_d'], 'GotoTag','y_d', 'ShowName','off', ...
          'Position', [400 q(2)-10 450 q(2)+10]);
h1 = route(m, 'From y_d', 1, 'two', 1, zeros(0,2));
q = port_xy(m, 'two', 'Inport', 2);  h2 = route(m, 'standard form', 1, 'two', 2, [420 150; 420 q(2)]);
set_param(h1, 'Name','y_d');  set_param(h2, 'Name','y');
finish_scope(m, 'two', 560);
a = Simulink.Annotation([m '/note']);
a.Text = strjoin({'WEEK 2, SECTION B  -  THE STANDARD SECOND-ORDER SYSTEM', '', ...
  '   Y(s)/Y_d(s) = wn^2 / (s^2 + 2 zeta wn s + wn^2)', '', ...
  '   zeta  damping ratio      larger zeta   ->  less overshoot', ...
  '   wn    natural frequency  larger wn     ->  faster: shorter rise and peak time', '', ...
  'Change zeta (0.2, 0.5, 0.7, 1, 2) or wn (1, 2, 4) in the Command Window and press Run.'}, newline);
a.Position = [40 260 620 380];  a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
save_model(m, m0, here);
end

%  새 모델 하나 / one new model
function out = new_model(m, here)
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
end

%  Mux 하나를 Scope 와 로그 W02log 로 / one Mux to the Scope and the log W02log
function finish_scope(m, mux, X)
blk(m, 'simulink/Sinks/Scope', 'Scope', X, 150, [30 30], {});
q = port_xy(m, 'Scope', 'Inport', 1);  p = port_xy(m, mux, 'Outport', 1);
set_param([m '/Scope'], 'Position', [X-30 p(2)-30 X+30 p(2)+30]);
route(m, mux, 1, 'Scope', 1, zeros(0,2));
blk(m, 'simulink/Sinks/To Workspace', 'W02log', X, p(2)+90, [60 30], ...
    {'VariableName','W02log', 'SaveFormat','Structure With Time'});
route(m, mux, 1, 'W02log', 1, [p(1)+30 p(2); p(1)+30 p(2)+90]);
try, set_param([m '/Scope'], 'ShowLegend','on'); catch, end
set_param([m '/Scope'], 'Open','on');
end

function save_model(m, out, here)
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r100', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-22s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
%  미분 시험대 — 루프 없이, 잡음 섞인 사인파를 세 가지로 미분한다 (절 G)
%  The derivative bench: no loop; a noisy sine differentiated three ways (section G)
%
%      signal = sin(0.5 t) + noise
%      true      0.5 cos(0.5 t)          what the derivative should be
%      pure      d/dt (signal)           the textbook derivative
%      filtered  Nf s/(s + Nf) (signal)  the pseudo-derivative
function build_bench(here)
m = 'W02_G_derivative_bench';
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','bench_T', 'ReturnWorkspaceOutputs','off');
blk(m, 'simulink/Sources/Sine Wave', 'sin(0.5 t)', 60, 100, [30 30], ...
    {'Amplitude','1', 'Frequency','bench_w', 'Phase','0'});
blk(m, 'simulink/Sources/Random Number', 'sensor noise', 60, 180, [30 28], ...
    {'Mean','0', 'Variance','bench_noise^2', 'Seed','23341', 'SampleTime','noise_ts'});
add_sum(m, 'measured', '++', [140 100]);
route(m, 'sin(0.5 t)', 1, 'measured', 1, zeros(0,2));
route(m, 'sensor noise', 1, 'measured', 2, [140 180]);
add_block('simulink/Continuous/Derivative', [m '/pure derivative'], 'Position',[260 62 310 98]);
blk(m, 'simulink/Continuous/Transfer Fcn', 'pseudo-derivative', 285, 160, [60 36], ...
    {'Numerator','[Nf 0]', 'Denominator','[1 Nf]'});
blk(m, 'simulink/Sources/Sine Wave', 'true derivative', 285, 240, [30 30], ...
    {'Amplitude','bench_w', 'Frequency','bench_w', 'Phase','pi/2'});
route(m, 'measured', 1, 'pure derivative', 1, [200 100; 200 80]);
route(m, 'measured', 1, 'pseudo-derivative', 1, [200 100; 200 160]);
add_block('simulink/Signal Routing/Mux', [m '/three'], 'Inputs','3', 'Position',[420 20 425 260]);
q = port_xy(m, 'three', 'Inport', 1);  route(m, 'pure derivative', 1, 'three', 1, [360 80; 360 q(2)]);
q = port_xy(m, 'three', 'Inport', 2);  route(m, 'pseudo-derivative', 1, 'three', 2, [370 160; 370 q(2)]);
q = port_xy(m, 'three', 'Inport', 3);  route(m, 'true derivative', 1, 'three', 3, [380 240; 380 q(2)]);
blk(m, 'simulink/Sinks/Scope', 'Scope', 520, 140, [30 30], {});
set_param([m '/Scope'], 'Position',[490 110 550 170]);
route(m, 'three', 1, 'Scope', 1, zeros(0,2));
blk(m, 'simulink/Sinks/To Workspace', 'W02bench', 520, 260, [60 30], ...
    {'VariableName','W02bench', 'SaveFormat','Structure With Time'});
route(m, 'three', 1, 'W02bench', 1, [460 140; 460 260]);
L = get_param([m '/three'], 'LineHandles');
nm = {'pure','pseudo','true'};
for i = 1:3, set_param(L.Inport(i), 'Name', nm{i}); end
try, set_param([m '/Scope'], 'ShowLegend','on'); catch, end
set_param([m '/Scope'], 'Open','on');
a = Simulink.Annotation([m '/note']);
a.Text = strjoin({'WEEK 2, SECTION G  -  THE DERIVATIVE BENCH (no loop)', '', ...
  '   measured = sin(0.5 t) + noise of standard deviation bench_noise', ...
  '   pure     = d/dt (measured)                 the textbook derivative', ...
  '   pseudo   = Nf s / (s + Nf) (measured)      the filtered derivative', ...
  '   true     = 0.5 cos(0.5 t)                  what both should show', '', ...
  'The noise is tiny, yet the pure derivative is buried under spikes.', ...
  'Change Nf in the Command Window (5, 20, 200) and press Run.'}, newline);
a.Position = [40 300 620 440];  a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
mss_style(m);
set_param([m '/Scope'], 'Position',[490 110 550 170]);
save_system(m, out);
export_diagram(m, fullfile(here, 'img'));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-22s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
function build_one(o, here)
m = o.name;
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
             'ReturnWorkspaceOutputs','off');

Y0 = 200;                                        % 손으로 만든 줄의 D 행 / D row of the hand-built loop
yd_src = setpoint(m, o, Y0);                     % 목표값 / the setpoint
loop_hand(m, o, Y0, yd_src);
if o.block, loop_block(m, Y0 + 400, o.mode, o.noise); end
measure(m, o);
note(m, o);
for b = find_system(m, 'SearchDepth',1, 'Regexp','on', 'BlockType','Goto|From')'
    set_param(b{1}, 'ShowName','off');              % 태그가 블록 안에 이미 쓰여 있다
end

set_param(m, 'StopFcn', '');                     % 그림은 캔버스의 Scope 가 보인다
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r100', fullfile(here, 'img', [m '.png']));   % 캔버스가 넓어 100 dpi (2000 px 이하)
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-22s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
%  목표값: 계단, 또는 (smooth) 1/(ref_Tf s + 1) 로 부드럽게 한 계단
%  The setpoint: a step, or (smooth) the step through 1/(ref_Tf s + 1)
function src = setpoint(m, o, Y)
blk(m, 'simulink/Sources/Step', 'step', 55, Y, [30 30], ...
    {'Time','t_step', 'Before','0', 'After','y_step'});
if o.twostep
    %  두 번째 계단: t_step2 에 목표가 y_step2 로 바뀐다 (절 H — 닿을 수 없는 목표 뒤에 닿을 수 있는 목표)
    %  The second step: at t_step2 the target becomes y_step2 (section H)
    blk(m, 'simulink/Sources/Step', 'step 2', 55, Y+60, [30 30], ...
        {'Time','t_step2', 'Before','0', 'After','y_step2 - y_step'});
    add_sum(m, 'two steps', '++', [150 Y]);
    route(m, 'step', 1, 'two steps', 1, zeros(0,2));
    route(m, 'step 2', 1, 'two steps', 2, [150 Y+60]);
    set_param([m '/two steps'], 'NamePlacement','alternate');
    src = {'two steps', 1};
    return
end
if ~o.smooth
    src = {'step', 1};
    return
end
blk(m, 'simulink/Continuous/Transfer Fcn', 'smooth', 150, Y-50, [60 36], ...
    {'Numerator','[1]', 'Denominator','[ref_Tf 1]'});
blk(m, 'simulink/Sources/Constant', 'ref_filter', 188, Y+45, [55 30], {'Value','ref_filter'});
blk(m, 'simulink/Signal Routing/Switch', 'which setpoint', 245, Y, [30 30], ...
    {'Criteria','u2 > Threshold', 'Threshold','0.5'});
q1 = port_xy(m, 'which setpoint', 'Inport', 1);
q2 = port_xy(m, 'which setpoint', 'Inport', 2);
q3 = port_xy(m, 'which setpoint', 'Inport', 3);
route(m, 'step', 1, 'smooth', 1, [90 Y; 90 Y-50]);
route(m, 'smooth', 1, 'which setpoint', 1, [212 Y-50; 212 q1(2)]);
route(m, 'ref_filter', 1, 'which setpoint', 2, [220 Y+45; 220 q2(2)]);
route(m, 'step', 1, 'which setpoint', 3, [100 Y; 100 q3(2)]);
src = {'which setpoint', 1};
end

% =========================================================================
%  손으로 만든 PID 한 줄 / the hand-built loop
%     P 행 y = Y-80, D 행 y = Y, I 행 y = Y+100, 되감기 y = Y+160, 되먹임 y = Y+220
function loop_hand(m, o, Y, yd)
YP = Y - 80;  YI = Y + 100;  YB = Y + 160;  YF = Y + 220;

add_sum(m, 'e', '+-', [340 Y]);
route(m, yd{1}, yd{2}, 'e', 1, [290 Y]);
goto_at(m, yd, [290 Y], 'up', 'y_d');

% P
blk(m, 'simulink/Math Operations/Gain', 'Kp', 440, YP, [50 36], {'Gain','Kp'});
route(m, 'e', 1, 'Kp', 1, [380 Y; 380 YP]);
last = {'Kp', 1};                                % 지금까지의 합 / the running sum

% D : Kd Nf s / (s + Nf)
if o.D
    blk(m, 'simulink/Continuous/Transfer Fcn', 'D filter', 470, Y, [60 36], ...
        {'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]'});
    route(m, 'e', 1, 'D filter', 1, zeros(0,2));
    dsrc = {'D filter', 1};  dx = 520;
    if o.pure
        %  순수 미분: Kd 를 곱한 뒤 미분한다. d_filtered 로 고른다.
        %  The pure derivative, Kd times d/dt, selected by d_filtered.
        blk(m, 'simulink/Math Operations/Gain', 'Kd', 440, YB, [50 36], {'Gain','Kd'});
        add_block('simulink/Continuous/Derivative', [m '/pure derivative'], ...
                  'Position', [500 YB-18 550 YB+18]);
        blk(m, 'simulink/Sources/Constant', 'd_filtered', 560, Y-38, [55 30], {'Value','d_filtered'});
        blk(m, 'simulink/Signal Routing/Switch', 'which D', 630, Y, [30 30], ...
            {'Criteria','u2 > Threshold', 'Threshold','0.5'});
        q1 = port_xy(m, 'which D', 'Inport', 1);
        q2 = port_xy(m, 'which D', 'Inport', 2);
        q3 = port_xy(m, 'which D', 'Inport', 3);
        route(m, 'D filter', 1, 'which D', 1, [590 Y; 590 q1(2)]);
        route(m, 'd_filtered', 1, 'which D', 2, [597 Y-38; 597 q2(2)]);
        route(m, 'e', 1, 'Kd', 1, [380 Y; 380 YB]);
        route(m, 'Kd', 1, 'pure derivative', 1, zeros(0,2));
        route(m, 'pure derivative', 1, 'which D', 3, [604 YB; 604 q3(2)]);
        dsrc = {'which D', 1};  dx = 660;
    end
    add_sum(m, 'p+d', '++', [690 YP]);
    route(m, 'Kp', 1, 'p+d', 1, zeros(0,2));
    ds = port_xy(m, dsrc{1}, 'Outport', dsrc{2});
    route(m, dsrc{1}, dsrc{2}, 'p+d', 2, [690 ds(2)]);
    goto_at(m, dsrc, [dx ds(2)], 'down', 'D');
    last = {'p+d', 1};
end

% I : Ki e (+ Kb (tau - u)), integrated
if o.I
    blk(m, 'simulink/Math Operations/Gain', 'Ki', 445, YI, [50 36], {'Gain','Ki'});
    blk(m, 'simulink/Continuous/Integrator', 'I', 560, YI, [30 30], {'InitialCondition','0'});
    route(m, 'e', 1, 'Ki', 1, [380 Y; 380 YI]);
    if o.limit
        %  한계가 있을 때만 되감기 입력을 받는 합산점을 둔다 / the back-calculation junction, only with a limit
        add_sum(m, 'into I', '++', [510 YI]);
        route(m, 'Ki', 1, 'into I', 1, zeros(0,2));
        route(m, 'into I', 1, 'I', 1, zeros(0,2));
    else
        route(m, 'Ki', 1, 'I', 1, zeros(0,2));
    end
    add_sum(m, 'u', '++', [750 YP]);
    route(m, last{1}, last{2}, 'u', 1, zeros(0,2));
    route(m, 'I', 1, 'u', 2, [750 YI]);
    goto_at(m, {'I', 1}, [595 YI], 'down', 'I');
    last = {'u', 1};
end

% 힘의 한계와 되감기 / the force limit and back-calculation
if o.limit
    blk(m, 'simulink/Discontinuities/Saturation', 'limit', 800, YP, [30 30], ...
        {'UpperLimit','tau_max', 'LowerLimit','-tau_max'});
    route(m, last{1}, last{2}, 'limit', 1, zeros(0,2));
    add_sum(m, 'tau - u', '+-', [830 Y+40]);
    blk(m, 'simulink/Math Operations/Gain', 'Kb', 815, YB, [50 36], ...
        {'Gain','Kb', 'Orientation','left'});
    route(m, 'limit', 1, 'tau - u', 1, [860 YP; 860 Y; 805 Y; 805 Y+40]);
    route(m, last{1}, last{2}, 'tau - u', 2, [770 YP; 770 Y+70; 830 Y+70]);
    qk = port_xy(m, 'Kb', 'Inport', 1);
    route(m, 'tau - u', 1, 'Kb', 1, [880 Y+40; 880 qk(2)]);
    qk = port_xy(m, 'Kb', 'Outport', 1);
    route(m, 'Kb', 1, 'into I', 2, [510 qk(2)]);
    last = {'limit', 1};
    for nm = {'tau - u'}, set_param([m '/' nm{1}], 'NamePlacement','alternate'); end
end

% 플랜트 / the plant
blk(m, 'simulink/Continuous/Transfer Fcn', 'plant', 960, YP, [60 36], ...
    {'Numerator','[1]', 'Denominator','[pid_m pid_b pid_k]', ...
     'BackgroundColor', gnc_colour('plant')});
route(m, last{1}, last{2}, 'plant', 1, zeros(0,2));
lp = port_xy(m, last{1}, 'Outport', last{2});
goto_at(m, last, [lp(1)+(900-lp(1))/2 YP], 'up', 'tau');
goto_at(m, {'plant', 1}, [1020 YP], 'up', 'y');

% 되먹임, 잡음이 있으면 센서를 거쳐 / the feedback, through the sensor if noisy
if o.noise
    add_sum(m, 'sensor', '++', [960 YF]);
    set_param([m '/sensor'], 'Orientation','left');
    blk(m, 'simulink/Sources/Random Number', 'noise', 900, YF+60, [30 28], ...
        {'Mean','0', 'Variance','noise_std^2', 'Seed','23341', 'SampleTime','noise_ts'});
    route(m, 'plant', 1, 'sensor', 1, [1040 YP; 1040 YF]);
    qs = port_xy(m, 'sensor', 'Inport', 2);
    route(m, 'noise', 1, 'sensor', 2, [qs(1) YF+60]);
    route(m, 'sensor', 1, 'e', 2, [340 YF]);
else
    route(m, 'plant', 1, 'e', 2, [1040 YP; 1040 YF; 340 YF]);
end
for nm = {'e','p+d','u','into I'}
    if getSimulinkBlockHandle([m '/' nm{1}]) > 0
        set_param([m '/' nm{1}], 'NamePlacement','alternate');
    end
end
end

% =========================================================================
%  라이브러리 PID 블록 한 줄 (F 만) / one row with the library PID block (F only)
function loop_block(m, Y, mode, noisy)
add_sum(m, 'e ', '+-', [340 Y]);
set_param([m '/e '], 'NamePlacement','alternate');
add_block('simulink/Signal Routing/From', [m '/From y_d (block row)'], 'GotoTag','y_d', ...
          'Position', [255 Y-10 305 Y+10]);
route(m, 'From y_d (block row)', 1, 'e ', 1, zeros(0,2));
add_block('simulink/Continuous/PID Controller', [m '/PID block'], ...
          'Controller','PID', 'Form','Parallel', 'P','Kp', 'I','Ki', 'D','Kd', 'N','Nf_blk', ...
          'LimitOutput','on', 'UpperSaturationLimit','tau_max', 'LowerSaturationLimit','-tau_max', ...
          'AntiWindupMode',mode, 'Kb','Kb', 'Position',[430 Y-30 550 Y+30]);
route(m, 'e ', 1, 'PID block', 1, zeros(0,2));
blk(m, 'simulink/Continuous/Transfer Fcn', 'plant ', 960, Y, [60 36], ...
    {'Numerator','[1]', 'Denominator','[pid_m pid_b pid_k]', 'BackgroundColor', gnc_colour('plant')});
route(m, 'PID block', 1, 'plant ', 1, zeros(0,2));
goto_at(m, {'PID block', 1}, [720 Y], 'up', 'tau_blk');
goto_at(m, {'plant ', 1}, [1020 Y], 'up', 'y_blk');
if noisy
    add_sum(m, 'sensor ', '++', [960 Y+80]);
    set_param([m '/sensor '], 'Orientation','left');
    blk(m, 'simulink/Sources/Random Number', 'noise ', 900, Y+140, [30 28], ...
        {'Mean','0', 'Variance','noise_std^2', 'Seed','23341', 'SampleTime','noise_ts'});
    route(m, 'plant ', 1, 'sensor ', 1, [1040 Y; 1040 Y+80]);
    qs = port_xy(m, 'sensor ', 'Inport', 2);
    route(m, 'noise ', 1, 'sensor ', 2, [qs(1) Y+140]);
    route(m, 'sensor ', 1, 'e ', 2, [340 Y+80]);
else
    route(m, 'plant ', 1, 'e ', 2, [1040 Y; 1040 Y+80; 340 Y+80]);
end
for b = find_system(m, 'SearchDepth',1, 'Regexp','on', 'BlockType','Goto|From')'
    set_param(b{1}, 'ShowName','off');
end
a = Simulink.Annotation([m '/row A']);
a.Text = strjoin({sprintf('THE LIBRARY PID BLOCK, anti-windup = %s.', mode), ...
    'Same gains and limit (tau_max) as the row above, and its own noise source with the', ...
    'SAME seed, so both rows see the same noise. Its filter coefficient is Nf_blk (= Nf).'}, newline);
a.Position = [420 Y+170 900 Y+230];  a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';
end

% =========================================================================
%  Scope 하나와 로그 / one Scope and the log
%     Scope 위 칸: 위치 [y_d y (y_blk)],  아래 칸: 힘 [tau (tau_blk) (I) (D)]
%     로그 W02log = [위 칸, 아래 칸]  -> W02_read
function measure(m, o)
pos = {'y_d','y'};                    if o.block, pos{end+1} = 'y_blk'; end
frc = {'tau'};  if o.block, frc{end+1} = 'tau_blk'; end
if o.I, frc{end+1} = 'I'; end
if o.D, frc{end+1} = 'D'; end
X = 1180;
mux_of(m, 'position', pos, X, 40);
mux_of(m, 'force', frc, X, 280);
blk(m, 'simulink/Sinks/Scope', 'Scope', X+120, 200, [30 30], {});
set_param([m '/Scope'], 'NumInputPorts','2');
try, set_param([m '/Scope'], 'LayoutDimensionsString','[2 1]'); catch, end
try, set_param([m '/Scope'], 'ShowLegend','on'); catch, end
set_param([m '/Scope'], 'Position', [X+100 150 X+160 250]);
p1 = port_xy(m, 'Scope', 'Inport', 1);  p2 = port_xy(m, 'Scope', 'Inport', 2);
a = port_xy(m, 'position', 'Outport', 1);  b = port_xy(m, 'force', 'Outport', 1);
route(m, 'position', 1, 'Scope', 1, [X+40 a(2); X+40 p1(2)]);
route(m, 'force', 1, 'Scope', 2, [X+50 b(2); X+50 p2(2)]);
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','2', ...
          'Position', [X+100 360 X+105 440]);
route(m, 'position', 1, 'log', 1, [X+40 a(2); X+40 380]);
route(m, 'force', 1, 'log', 2, [X+50 b(2); X+50 420]);
blk(m, 'simulink/Sinks/To Workspace', 'W02log', X+190, 400, [60 30], ...
    {'VariableName','W02log', 'SaveFormat','Structure With Time'});
route(m, 'log', 1, 'W02log', 1, zeros(0,2));
set_param([m '/Scope'], 'Open','on');
end

function mux_of(m, name, tags, X, Y)
n = numel(tags);  H = 40*n;
if n == 1
    add_block('simulink/Signal Routing/Mux', [m '/' name], 'Inputs','1', ...
              'Position', [X Y X+5 Y+H]);
else
    add_block('simulink/Signal Routing/Mux', [m '/' name], 'Inputs',num2str(n), ...
              'Position', [X Y X+5 Y+H]);
end
for i = 1:n
    q = port_xy(m, name, 'Inport', i);
    f = ['From ' tags{i}];
    add_block('simulink/Signal Routing/From', [m '/' f], 'GotoTag',tags{i}, ...
              'Position', [X-90 q(2)-10 X-40 q(2)+10]);
    h = route(m, f, 1, name, i, zeros(0,2));
    set_param(h, 'Name', tags{i});
end
end

% =========================================================================
%  Goto 하나를 선의 한 점에서 위나 아래로 가지 쳐 단다
%  Hang one Goto from a point on a line, branching up or down
function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
at = round(at);                                  % 블록 좌표는 정수로 반올림된다 / block positions round
g = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag',tag, ...
          'TagVisibility','local', 'Position', [at(1)+12 at(2)+dy-9 at(1)+62 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

function blk(m, lib, name, cx, cy, wh, params)
add_block(lib, [m '/' name], 'Position', ...
          [cx-wh(1)/2 cy-wh(2)/2 cx+wh(1)/2 cy+wh(2)/2], params{:});
end

function h = route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
try
    h = add_line(sys, [a; via; b]);
catch e
    fprintf('route %s -> %s : a %s via %s b %s\n', src, dst, mat2str(size(a)), mat2str(size(via)), mat2str(size(b)));
    rethrow(e);
end
end

% =========================================================================
function note(m, o)
L = {sprintf('WEEK 2, SECTION %s  -  %s', o.sec, o.title), ''};
law = 'tau = Kp e';
if o.I, law = [law ' + Ki * integral(e)']; end
if o.D, law = [law ' + Kd (Nf s / (s + Nf)) e']; end
L{end+1} = ['    e = y_d - y,    ' law];
if o.limit, L{end+1} = '    tau limited to |tau| <= tau_max;  i_dot = Ki e + Kb (tau - u)'; end
if o.noise, L{end+1} = '    y is measured with noise of standard deviation noise_std'; end
if o.smooth, L{end+1} = '    ref_filter = 1 passes the step through 1/(ref_Tf s + 1)'; end
if o.pure,  L{end+1} = '    d_filtered = 0 replaces the filtered derivative by a pure one'; end
L = [L, {'', 'Change a gain in the Command Window (e.g. Kp = 20) and press Run:', ...
         'the Scope shows the position (top) and the force (bottom) at once.'}];
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
if o.block, a.Position = [40 820 900 960]; else, a.Position = [40 480 900 620]; end
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
