function W03_1_build_speed(which)
%W03_1_BUILD_SPEED  3주차 실습 모델 다섯 개를 코드로 만든다 — 절 하나에 모델 하나.
%                   Generate the five Week 3 models, one model per section.
%
%   실행 / to run
%       W03_1_build_speed                 다섯 개 전부 / all five
%       W03_1_build_speed('W03_E_PID')    하나만 / one of them
%
%   모델 / the models
%       W03_C_open_loop   힘을 계단으로 주고 속도를 본다 (제어기 없음)
%                         a step force, and the speed it produces (no controller)
%       W03_D_P           P 만 / P only
%       W03_E_PID         P + I + D  (Kd = 0 이 기본 / Kd = 0 by default)
%       W03_F_windup      닿을 수 없는 속도, 그다음 닿을 수 있는 속도 + 되감기
%                         an unreachable speed, then a reachable one, with back-calculation
%       W03_G_tuning      튜닝 순서 + 부드러운 목표 / the tuning order, with a smoothed command
%
%   2주차 모델과 같은 모양이다. 제어기는 최상위에 블록 하나씩, 미분은 Transfer Fcn
%   하나, 오른쪽에 Scope 하나 (위: 속도, 아래: 힘). 바뀐 것은 플랜트뿐이다:
%   힘 X -> 추진기 둘에 반씩 -> 축 회전수 n -> Otter (MSS otter.m) -> 전진 속도 u.
%   The same layout as the Week 2 models: one block per term on the top level,
%   the derivative as one Transfer Fcn, one Scope on the right (speed on top,
%   force below). Only the plant changes: force X -> half to each thruster ->
%   shaft speed n -> the Otter (MSS otter.m) -> surge speed u.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W03_0_setup');

M = struct( ...
  'name',   {'W03_C_open_loop','W03_D_P','W03_E_PID','W03_F_windup','W03_G_tuning'}, ...
  'open',   {true,  false, false, false, false}, ...
  'D',      {false, false, true,  true,  true }, ...
  'I',      {false, false, true,  true,  true }, ...
  'aw',     {false, false, false, true,  true }, ...
  'twostep',{false, false, false, true,  false}, ...
  'smooth', {false, false, false, false, true }, ...
  'title',  {'THE PLANT, SEEN FROM OUTSIDE (no controller)', 'P ONLY', 'P + I + D', ...
             'AN UNREACHABLE SPEED, AND ANTI-WINDUP', 'THE TUNING ORDER'}, ...
  'sec',    {'C','D','E','F','G'});
if nargin == 1, M = M(strcmp({M.name}, which)); end
for k = 1:numel(M), build_one(M(k), here); end
end

% =========================================================================
function build_one(o, here)
m = o.name;
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
Y = 200;  YP = Y - 80;
if o.open
    blk(m, 'simulink/Sources/Step', 'force X', 700, YP, [30 30], ...
        {'Time','t_step', 'Before','0', 'After','X_open'});
    goto_at(m, {'force X', 1}, [760 YP], 'up', 'X');
    plant(m, {'force X', 1}, YP, [], []);
else
    yd = setpoint(m, o, Y);
    last = loop(m, o, Y, yd);
    plant(m, last, YP, Y + 220, o);
end
measure(m, o);
note(m, o);
for b = find_system(m, 'SearchDepth',1, 'Regexp','on', 'BlockType','Goto|From')'
    set_param(b{1}, 'ShowName','off');
end
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r80', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
%  목표 속도: 계단, 두 계단(F), 또는 부드럽게 한 계단(G)
%  The command: a step, two steps (F), or a smoothed step (G)
function src = setpoint(m, o, Y)
blk(m, 'simulink/Sources/Step', 'step', 55, Y, [30 30], ...
    {'Time','t_step', 'Before','0', 'After','u_step'});
src = {'step', 1};
if o.twostep
    blk(m, 'simulink/Sources/Step', 'step 2', 55, Y+60, [30 30], ...
        {'Time','t_step2', 'Before','0', 'After','u_step2 - u_step'});
    add_sum(m, 'two steps', '++', [150 Y]);
    route(m, 'step', 1, 'two steps', 1, zeros(0,2));
    route(m, 'step 2', 1, 'two steps', 2, [150 Y+60]);
    set_param([m '/two steps'], 'NamePlacement','alternate');
    src = {'two steps', 1};
elseif o.smooth
    blk(m, 'simulink/Continuous/Transfer Fcn', 'smooth', 150, Y-50, [60 36], ...
        {'Numerator','[1]', 'Denominator','[ref_Tf 1]'});
    blk(m, 'simulink/Sources/Constant', 'ref_filter', 188, Y+45, [55 30], {'Value','ref_filter'});
    blk(m, 'simulink/Signal Routing/Switch', 'which command', 245, Y, [30 30], ...
        {'Criteria','u2 > Threshold', 'Threshold','0.5'});
    q1 = port_xy(m, 'which command', 'Inport', 1);
    q2 = port_xy(m, 'which command', 'Inport', 2);
    q3 = port_xy(m, 'which command', 'Inport', 3);
    route(m, 'step', 1, 'smooth', 1, [90 Y; 90 Y-50]);
    route(m, 'smooth', 1, 'which command', 1, [212 Y-50; 212 q1(2)]);
    route(m, 'ref_filter', 1, 'which command', 2, [220 Y+45; 220 q2(2)]);
    route(m, 'step', 1, 'which command', 3, [100 Y; 100 q3(2)]);
    src = {'which command', 1};
end
end

% =========================================================================
%  PID 한 줄 (2주차와 같은 배치) / one PID row, laid out as in Week 2
%     P 행 Y-80, D 행 Y, I 행 Y+100, 되감기 Y+160, 되먹임 Y+220
function last = loop(m, o, Y, yd)
YP = Y - 80;  YI = Y + 100;  YB = Y + 160;
add_sum(m, 'e', '+-', [340 Y]);
route(m, yd{1}, yd{2}, 'e', 1, [290 Y]);
goto_at(m, yd, [290 Y], 'up', 'u_d');

blk(m, 'simulink/Math Operations/Gain', 'Kp', 440, YP, [50 36], {'Gain','Kp'});
route(m, 'e', 1, 'Kp', 1, [380 Y; 380 YP]);
last = {'Kp', 1};
if o.D
    blk(m, 'simulink/Continuous/Transfer Fcn', 'D filter', 470, Y, [60 36], ...
        {'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]'});
    route(m, 'e', 1, 'D filter', 1, zeros(0,2));
    add_sum(m, 'p+d', '++', [690 YP]);
    route(m, 'Kp', 1, 'p+d', 1, zeros(0,2));
    route(m, 'D filter', 1, 'p+d', 2, [690 Y]);
    goto_at(m, {'D filter', 1}, [520 Y], 'down', 'D');
    last = {'p+d', 1};
end
if o.I
    blk(m, 'simulink/Math Operations/Gain', 'Ki', 445, YI, [50 36], {'Gain','Ki'});
    blk(m, 'simulink/Continuous/Integrator', 'I', 560, YI, [30 30], {'InitialCondition','0'});
    route(m, 'e', 1, 'Ki', 1, [380 Y; 380 YI]);
    if o.aw
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

%  추진기의 한계는 언제나 있다 / the thrusters always have a limit
blk(m, 'simulink/Discontinuities/Saturation', 'thrust limit', 800, YP, [30 30], ...
    {'UpperLimit','X_hi', 'LowerLimit','X_lo'});
route(m, last{1}, last{2}, 'thrust limit', 1, zeros(0,2));
if o.aw
    add_sum(m, 'X - u', '+-', [830 Y+40]);
    blk(m, 'simulink/Math Operations/Gain', 'Kb', 815, YB, [50 36], {'Gain','Kb', 'Orientation','left'});
    route(m, 'thrust limit', 1, 'X - u', 1, [860 YP; 860 Y; 805 Y; 805 Y+40]);
    route(m, last{1}, last{2}, 'X - u', 2, [770 YP; 770 Y+70; 830 Y+70]);
    qk = port_xy(m, 'Kb', 'Inport', 1);
    route(m, 'X - u', 1, 'Kb', 1, [880 Y+40; 880 qk(2)]);
    qk = port_xy(m, 'Kb', 'Outport', 1);
    route(m, 'Kb', 1, 'into I', 2, [510 qk(2)]);
    set_param([m '/X - u'], 'NamePlacement','alternate');
end
for nm = {'e','p+d','u','into I'}
    if getSimulinkBlockHandle([m '/' nm{1}]) > 0
        set_param([m '/' nm{1}], 'NamePlacement','alternate');
    end
end
lp = port_xy(m, 'thrust limit', 'Outport', 1);
goto_at(m, {'thrust limit', 1}, [lp(1) + 40 YP], 'up', 'X');
last = {'thrust limit', 1};
end

% =========================================================================
%  배분과 Otter: X -> 반씩 -> 축 회전수 -> Otter -> u, 그리고 되먹임
%  Allocation and the Otter: X -> half each -> shaft speed -> Otter -> u, and the feedback
function plant(m, src, YP, YF, o)
X0 = 930;
%  배분: 힘 X -> 두 축 회전수 n. 주석이 달린 MATLAB Function 하나로 둔다 (열어서 읽으면 된다).
%  Allocation: force X -> two shaft speeds n, as one commented MATLAB Function
%  (open it and read it).
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', round([X0-40 YP-30 X0+140 YP+30]));
set_mlfcn([m '/allocation'], { ...
'function n = allocation(X, k_pos, k_neg)'
'%#codegen'
'%ALLOCATION  전진력 X [N] 를 두 프로펠러의 축 회전수 n [rad/s] 로 바꾼다.'
'%            Turn the surge force X [N] into the shaft speeds n [rad/s] of the two propellers.'
'%'
'%   k_pos, k_neg 는 작업공간 변수 (W03_0_setup) 에서 온다 — 블록의 포트가 아니다.'
'%   k_pos and k_neg come from the workspace (W03_0_setup), not from ports.'
''
'% 1) 똑바로 갈 때 두 프로펠러는 같은 일을 한다: 각자 X 의 절반.'
'%    Going straight, both propellers do the same work: half of X each.'
'T = X/2;'
''
'% 2) 프로펠러 곡선 T = k n|n| (1주차) 을 n 에 대해 푼다.'
'%    앞으로 밀 때와 뒤로 당길 때 계수가 다르다 (k_pos > k_neg).'
'%    Solve the propeller curve T = k n|n| (Week 1) for n; the coefficient'
'%    differs ahead and astern (k_pos > k_neg).'
'if T >= 0'
'    n1 =  sqrt( T / k_pos);      % 앞으로 / ahead'
'else'
'    n1 = -sqrt(-T / k_neg);      % 뒤로 / astern'
'end'
''
'% 3) 두 축에 같은 회전수. Otter 는 [좌현; 우현] 순서로 받는다.'
'%    The same speed on both shafts; the Otter takes [port; starboard].'
'n = [n1; n1];'
'end'}, 'n', '[2 1]');
mlfcn_params([m '/allocation'], {'k_pos','k_neg'});
route(m, src{1}, src{2}, 'allocation', 1, zeros(0,2));
cfg = otter_config('base');
add_otter_plant(m, 'Otter', [X0+260 YP-30 X0+360 YP+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
q = port_xy(m, 'Otter', 'Inport', 1);  p = port_xy(m, 'allocation', 'Outport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
add_block('simulink/Signal Routing/Selector', [m '/surge speed u'], 'InputPortWidth','12', ...
          'Indices','1', 'Position', [X0+410 YP-15 X0+440 YP+15]);
p = port_xy(m, 'Otter', 'Outport', 1);  q = port_xy(m, 'surge speed u', 'Inport', 1);
set_param([m '/surge speed u'], 'Position', get_param([m '/surge speed u'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
q = port_xy(m, 'surge speed u', 'Inport', 1);
add_line(m, [p; q]);
ys = port_xy(m, 'surge speed u', 'Outport', 1);  ys = ys(2);
goto_at(m, {'surge speed u', 1}, [X0+470 ys], 'up', 'u');
if ~isempty(YF)
    route(m, 'surge speed u', 1, 'e', 2, [X0+490 ys; X0+490 YF; 340 YF]);
end
end

% =========================================================================
%  Scope 하나와 로그 / one Scope and the log
%     위 칸: 속도 [u_d u],  아래 칸: 힘 [X (I) (D)];  W03log = [위, 아래]
function measure(m, o)
if o.open, spd = {'u'}; frc = {'X'};
else,      spd = {'u_d','u'}; frc = {'X'};
    if o.I, frc{end+1} = 'I'; end
    if o.D, frc{end+1} = 'D'; end
end
X = 1560;
mux_of(m, 'speed', spd, X, 40);
mux_of(m, 'force', frc, X, 280);
blk(m, 'simulink/Sinks/Scope', 'Scope', X+120, 200, [30 30], {});
set_param([m '/Scope'], 'NumInputPorts','2');
try, set_param([m '/Scope'], 'LayoutDimensionsString','[2 1]'); catch, end
try, set_param([m '/Scope'], 'ShowLegend','on'); catch, end
set_param([m '/Scope'], 'Position', [X+100 150 X+160 250]);
p1 = port_xy(m, 'Scope', 'Inport', 1);  p2 = port_xy(m, 'Scope', 'Inport', 2);
a = port_xy(m, 'speed', 'Outport', 1);  b = port_xy(m, 'force', 'Outport', 1);
route(m, 'speed', 1, 'Scope', 1, [X+40 a(2); X+40 p1(2)]);
route(m, 'force', 1, 'Scope', 2, [X+50 b(2); X+50 p2(2)]);
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','2', 'Position', [X+100 360 X+105 440]);
route(m, 'speed', 1, 'log', 1, [X+40 a(2); X+40 380]);
route(m, 'force', 1, 'log', 2, [X+50 b(2); X+50 420]);
blk(m, 'simulink/Sinks/To Workspace', 'W03log', X+190, 400, [60 30], ...
    {'VariableName','W03log', 'SaveFormat','Structure With Time'});
route(m, 'log', 1, 'W03log', 1, zeros(0,2));
set_param([m '/Scope'], 'Open','on');
end

function mux_of(m, name, tags, X, Y)
n = numel(tags);
add_block('simulink/Signal Routing/Mux', [m '/' name], 'Inputs',num2str(n), ...
          'Position', [X Y X+5 Y+40*n]);
for i = 1:n
    q = port_xy(m, name, 'Inport', i);
    f = ['From ' tags{i}];
    add_block('simulink/Signal Routing/From', [m '/' f], 'GotoTag',tags{i}, ...
              'Position', [X-90 q(2)-10 X-40 q(2)+10]);
    h = route(m, f, 1, name, i, zeros(0,2));
    set_param(h, 'Name', tags{i});
end
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
at = round(at);
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
h = add_line(sys, [a; via; b]);
end

% =========================================================================
function note(m, o)
L = {sprintf('WEEK 3, SECTION %s  -  %s', o.sec, o.title), ''};
if o.open
    L = [L, {'    X_open newtons from both thrusters at t = t_step; the Scope shows the surge speed u.', ...
             '    Change X_open (50, 100, 200) and press Run: how fast, and how far, does u go?'}];
else
    law = 'X = Kp e';
    if o.I, law = [law ' + Ki * integral(e)']; end
    if o.D, law = [law ' + Kd (Nf s / (s + Nf)) e']; end
    L{end+1} = ['    e = u_d - u,    ' law];
    L{end+1} = '    X is limited to [X_lo, X_hi] by the thrusters (about -133 N to 239 N)';
    if o.aw,     L{end+1} = '    anti-windup: i_dot = Ki e + Kb (X - u),  Kb = 0 switches it off'; end
    if o.twostep, L{end+1} = '    u_step = 3.5 is faster than the Otter can go; at t_step2 the command drops to u_step2'; end
    if o.smooth, L{end+1} = '    ref_filter = 1 passes the command through 1/(ref_Tf s + 1)'; end
    L = [L, {'', 'Change a gain in the Command Window (e.g. Kp = 400) and press Run:', ...
             'the Scope shows the speed (top) and the force (bottom) at once.'}];
end
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
if o.open, a.Position = [40 60 640 170]; else, a.Position = [40 480 900 620]; end
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
