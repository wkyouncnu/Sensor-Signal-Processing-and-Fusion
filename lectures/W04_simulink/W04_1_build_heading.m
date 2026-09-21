function W04_1_build_heading(which)
%W04_1_BUILD_HEADING  4주차 실습 모델 여섯 개를 코드로 만든다 — 절 하나에 모델 하나.
%                     Generate the six Week 4 models, one model per section.
%
%   실행 / to run
%       W04_1_build_heading                 여섯 개 전부 / all six
%       W04_1_build_heading('W04_E_PD')     하나만 / one of them
%
%   모델 / the models
%       W04_C_open_loop   요 모멘트를 계단으로 주고 선수각을 본다 (제어기 없음)
%                         a step yaw moment, and the heading it produces (no controller)
%       W04_D_P           P 만 / P only
%       W04_E_PD          P + D
%       W04_F_PID         P + I + D, 좌현 프로펠러가 약할 때 / with a weak port propeller
%       W04_G_wrap        +-180 도를 넘는 명령, ssa 스위치 / a command across +-180 deg, ssa switch
%       W04_H_tuning      큰 선회, 모멘트 한계, 되감기 / a big turn, the moment limit, back-calculation
%
%   3주차 모델과 같은 모양이다. 바뀐 것은 둘뿐이다.
%   ① 앞: 목표를 도로 받아 rad 로 바꾸고, 오차를 ssa 로 (-pi, pi] 에 감는다.
%   ② 뒤: 요 모멘트 N 을 두 프로펠러의 추력 차이로 만든다
%         T1 = X_ff/2 + N/(2 y_pont) (좌현),  T2 = X_ff/2 - N/(2 y_pont) (우현).
%   The same layout as Week 3, with two changes: ① in front, the command in
%   degrees is converted to rad and the error wrapped by ssa into (-pi, pi];
%   ② behind, the yaw moment N becomes a thrust difference between the two
%   propellers, T1 = X_ff/2 + N/(2 y_pont) (port), T2 = X_ff/2 - N/(2 y_pont).

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W04_0_setup');

M = struct( ...
  'name',   {'W04_C_open_loop','W04_D_P','W04_E_PD','W04_F_PID','W04_G_wrap','W04_H_tuning'}, ...
  'open',   {true,  false, false, false, false, false}, ...
  'D',      {false, false, true,  true,  true,  true }, ...
  'I',      {false, false, false, true,  false, true }, ...
  'aw',     {false, false, false, false, false, true }, ...
  'twostep',{false, false, false, false, true,  false}, ...
  'wrap',   {false, false, false, false, true,  false}, ...
  'title',  {'THE PLANT, SEEN FROM OUTSIDE (no controller)', 'P ONLY', 'P + D', ...
             'P + I + D, WITH A WEAK PORT PROPELLER', 'THE WRAP AT +-180 DEG', ...
             'A BIG TURN, THE MOMENT LIMIT, AND THE TUNING ORDER'}, ...
  'sec',    {'C','D','E','F','G','H'});
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
    blk(m, 'simulink/Sources/Step', 'yaw moment N', 800, YP, [30 30], ...
        {'Time','t_step', 'Before','0', 'After','N_open'});
    goto_at(m, {'yaw moment N', 1}, [850 YP], 'up', 'N');
    plant(m, {'yaw moment N', 1}, YP, []);
else
    yd = setpoint(m, o, Y);
    last = loop(m, o, Y, yd);
    plant(m, last, YP, Y + 220);
end
measure(m, o);
note(m, o);
for b = find_system(m, 'SearchDepth',1, 'Regexp','on', 'BlockType','Goto|From')'
    set_param(b{1}, 'ShowName','off');
end
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r60', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
%  목표 선수각 [deg]: 계단 하나, 또는 두 계단(G) -> rad
%  The heading command [deg]: one step, or two steps (G) -> rad
function src = setpoint(m, o, Y)
blk(m, 'simulink/Sources/Step', 'step', 55, Y, [30 30], ...
    {'Time','t_step', 'Before','0', 'After','psi_step'});
src = {'step', 1};
if o.twostep
    blk(m, 'simulink/Sources/Step', 'step 2', 55, Y+60, [30 30], ...
        {'Time','t_step2', 'Before','0', 'After','psi_step2 - psi_step'});
    add_sum(m, 'two steps', '++', [150 Y]);
    route(m, 'step', 1, 'two steps', 1, zeros(0,2));
    route(m, 'step 2', 1, 'two steps', 2, [150 Y+60]);
    set_param([m '/two steps'], 'NamePlacement','alternate');
    src = {'two steps', 1};
end
goto_at(m, src, [185 Y], 'up', 'psi_d');
blk(m, 'simulink/Math Operations/Gain', 'deg to rad', 250, Y, [50 36], {'Gain','pi/180'});
route(m, src{1}, src{2}, 'deg to rad', 1, zeros(0,2));
src = {'deg to rad', 1};
end

% =========================================================================
%  PID 한 줄. 3주차와 같은 배치를 오른쪽으로 DX 만큼 민다 (ssa 자리)
%  One PID row: the Week 3 layout shifted right by DX to make room for ssa
function last = loop(m, o, Y, yd)
DX = 90;
YP = Y - 80;  YI = Y + 100;  YB = Y + 160;
add_sum(m, 'e', '+-', [340 Y]);
route(m, yd{1}, yd{2}, 'e', 1, zeros(0,2));
blk(m, 'simulink/User-Defined Functions/Fcn', 'ssa', 410, Y, [60 30], ...
    {'Expr','atan2(sin(u), cos(u))'});
route(m, 'e', 1, 'ssa', 1, zeros(0,2));
src = {'ssa', 1};
if o.wrap
    %  use_ssa = 0 이면 감지 않은 오차 / use_ssa = 0 passes the raw error
    blk(m, 'simulink/Sources/Constant', 'use_ssa', 430, Y+50, [50 26], {'Value','use_ssa'});
    blk(m, 'simulink/Signal Routing/Switch', 'which error', 500, Y, [30 30], ...
        {'Criteria','u2 > Threshold', 'Threshold','0.5'});
    q1 = port_xy(m, 'which error', 'Inport', 1);
    q2 = port_xy(m, 'which error', 'Inport', 2);
    q3 = port_xy(m, 'which error', 'Inport', 3);
    route(m, 'ssa', 1, 'which error', 1, [455 Y; 455 q1(2)]);
    route(m, 'use_ssa', 1, 'which error', 2, [465 Y+50; 465 q2(2)]);
    route(m, 'e', 1, 'which error', 3, [370 Y; 370 Y+90; 475 Y+90; 475 q3(2)]);
    src = {'which error', 1};
    DX = 170;
end
X = @(x) x + DX;

blk(m, 'simulink/Math Operations/Gain', 'Kp', X(440), YP, [50 36], {'Gain','Kp'});
route(m, src{1}, src{2}, 'Kp', 1, [X(380) Y; X(380) YP]);
last = {'Kp', 1};
if o.D
    blk(m, 'simulink/Continuous/Transfer Fcn', 'D filter', X(470), Y, [60 36], ...
        {'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]'});
    route(m, src{1}, src{2}, 'D filter', 1, zeros(0,2));
    add_sum(m, 'p+d', '++', [X(690) YP]);
    route(m, 'Kp', 1, 'p+d', 1, zeros(0,2));
    route(m, 'D filter', 1, 'p+d', 2, [X(690) Y]);
    goto_at(m, {'D filter', 1}, [X(520) Y], 'down', 'D');
    last = {'p+d', 1};
end
if o.I
    blk(m, 'simulink/Math Operations/Gain', 'Ki', X(445), YI, [50 36], {'Gain','Ki'});
    blk(m, 'simulink/Continuous/Integrator', 'I', X(560), YI, [30 30], {'InitialCondition','0'});
    route(m, src{1}, src{2}, 'Ki', 1, [X(380) Y; X(380) YI]);
    if o.aw
        add_sum(m, 'into I', '++', [X(510) YI]);
        route(m, 'Ki', 1, 'into I', 1, zeros(0,2));
        route(m, 'into I', 1, 'I', 1, zeros(0,2));
    else
        route(m, 'Ki', 1, 'I', 1, zeros(0,2));
    end
    add_sum(m, 'u', '++', [X(750) YP]);
    route(m, last{1}, last{2}, 'u', 1, zeros(0,2));
    route(m, 'I', 1, 'u', 2, [X(750) YI]);
    goto_at(m, {'I', 1}, [X(595) YI], 'down', 'I');
    last = {'u', 1};
end

%  낼 수 있는 요 모멘트는 언제나 한계가 있다 / the yaw moment always has a limit
blk(m, 'simulink/Discontinuities/Saturation', 'moment limit', X(800), YP, [30 30], ...
    {'UpperLimit','N_max', 'LowerLimit','-N_max'});
route(m, last{1}, last{2}, 'moment limit', 1, zeros(0,2));
if o.aw
    add_sum(m, 'N - u', '+-', [X(830) Y+40]);
    blk(m, 'simulink/Math Operations/Gain', 'Kb', X(815), YB, [50 36], {'Gain','Kb', 'Orientation','left'});
    route(m, 'moment limit', 1, 'N - u', 1, [X(860) YP; X(860) Y; X(805) Y; X(805) Y+40]);
    route(m, last{1}, last{2}, 'N - u', 2, [X(770) YP; X(770) Y+70; X(830) Y+70]);
    qk = port_xy(m, 'Kb', 'Inport', 1);
    route(m, 'N - u', 1, 'Kb', 1, [X(880) Y+40; X(880) qk(2)]);
    qk = port_xy(m, 'Kb', 'Outport', 1);
    route(m, 'Kb', 1, 'into I', 2, [X(510) qk(2)]);
    set_param([m '/N - u'], 'NamePlacement','alternate');
end
for nm = {'e','p+d','u','into I'}
    if getSimulinkBlockHandle([m '/' nm{1}]) > 0
        set_param([m '/' nm{1}], 'NamePlacement','alternate');
    end
end
lp = port_xy(m, 'moment limit', 'Outport', 1);
goto_at(m, {'moment limit', 1}, [lp(1) + 40 YP], 'up', 'N');
last = {'moment limit', 1};
end

% =========================================================================
%  배분과 Otter: N -> 두 프로펠러의 추력 -> 축 회전수 -> Otter -> psi, 그리고 되먹임
%  Allocation and the Otter: N -> two thrusts -> shaft speeds -> Otter -> psi, and the feedback
function plant(m, src, YP, YF)
s = port_xy(m, src{1}, 'Outport', src{2});
X0 = round(s(1)) + 90;                        % 가지점 / the branch point
YA = YP - 50;  YB = YP + 50;                  % 좌현 줄, 우현 줄 / port row, starboard row
blk(m, 'simulink/Math Operations/Gain', 'port share', X0+60, YA, [60 36], {'Gain','1/(2*y_pont)'});
blk(m, 'simulink/Math Operations/Gain', 'starboard share', X0+60, YB, [60 36], {'Gain','-1/(2*y_pont)'});
route(m, src{1}, src{2}, 'port share', 1, [X0 YP; X0 YA]);
route(m, src{1}, src{2}, 'starboard share', 1, [X0 YP; X0 YB]);
blk(m, 'simulink/Math Operations/Bias', 'plus half surge', X0+170, YA, [60 30], {'Bias','X_ff/2'});
blk(m, 'simulink/Math Operations/Bias', 'plus half surge ', X0+170, YB, [60 30], {'Bias','X_ff/2'});
route(m, 'port share', 1, 'plus half surge', 1, zeros(0,2));
route(m, 'starboard share', 1, 'plus half surge ', 1, zeros(0,2));
blk(m, 'simulink/Math Operations/Gain', 'port health', X0+270, YA, [60 36], {'Gain','port_eff'});
route(m, 'plus half surge', 1, 'port health', 1, zeros(0,2));
fx = '(sgn(u)*sqrt(abs(u)/(k_pos*(1 + sgn(u))/2 + k_neg*(1 - sgn(u))/2)))';
blk(m, 'simulink/User-Defined Functions/Fcn', 'port shaft', X0+390, YA, [110 36], {'Expr',fx});
blk(m, 'simulink/User-Defined Functions/Fcn', 'starboard shaft', X0+390, YB, [110 36], {'Expr',fx});
route(m, 'port health', 1, 'port shaft', 1, zeros(0,2));
route(m, 'plus half surge ', 1, 'starboard shaft', 1, zeros(0,2));
add_block('simulink/Signal Routing/Mux', [m '/two shafts'], 'Inputs','2', ...
          'Position', [X0+480 YA-10 X0+485 YB+10]);
q1 = port_xy(m, 'two shafts', 'Inport', 1);  q2 = port_xy(m, 'two shafts', 'Inport', 2);
route(m, 'port shaft', 1, 'two shafts', 1, [X0+460 YA; X0+460 q1(2)]);
route(m, 'starboard shaft', 1, 'two shafts', 2, [X0+460 YB; X0+460 q2(2)]);
cfg = otter_config('base');
add_otter_plant(m, 'Otter', [X0+530 YP-30 X0+630 YP+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
q = port_xy(m, 'Otter', 'Inport', 1);  p = port_xy(m, 'two shafts', 'Outport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
add_block('simulink/Signal Routing/Selector', [m '/heading psi'], 'InputPortWidth','12', ...
          'Indices','12', 'Position', [X0+680 YP-15 X0+710 YP+15]);
p = port_xy(m, 'Otter', 'Outport', 1);  q = port_xy(m, 'heading psi', 'Inport', 1);
set_param([m '/heading psi'], 'Position', get_param([m '/heading psi'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
q = port_xy(m, 'heading psi', 'Inport', 1);
add_line(m, [p; q]);
ys = port_xy(m, 'heading psi', 'Outport', 1);  ys = ys(2);
blk(m, 'simulink/Math Operations/Gain', 'in degrees', X0+800, ys, [50 36], {'Gain','180/pi'});
route(m, 'heading psi', 1, 'in degrees', 1, zeros(0,2));
goto_at(m, {'in degrees', 1}, [X0+845 ys], 'up', 'psi');
if ~isempty(YF)
    route(m, 'heading psi', 1, 'e', 2, [X0+745 ys; X0+745 YF; 340 YF]);
end
end

% =========================================================================
%  Scope 하나와 로그 / one Scope and the log
%     위 칸: 선수각 [psi_d psi] deg,  아래 칸: 요 모멘트 [N (I) (D)] N m;  W04log = [위, 아래]
function measure(m, o)
if o.open, hdg = {'psi'}; frc = {'N'};
else,      hdg = {'psi_d','psi'}; frc = {'N'};
    if o.I, frc{end+1} = 'I'; end
    if o.D, frc{end+1} = 'D'; end
end
s = port_xy(m, 'Goto psi', 'Inport', 1);  X = round(s(1)) + 200;
mux_of(m, 'heading', hdg, X, 40);
mux_of(m, 'moment', frc, X, 280);
blk(m, 'simulink/Sinks/Scope', 'Scope', X+120, 200, [30 30], {});
set_param([m '/Scope'], 'NumInputPorts','2');
try, set_param([m '/Scope'], 'LayoutDimensionsString','[2 1]'); catch, end
try, set_param([m '/Scope'], 'ShowLegend','on'); catch, end
set_param([m '/Scope'], 'Position', [X+100 150 X+160 250]);
p1 = port_xy(m, 'Scope', 'Inport', 1);  p2 = port_xy(m, 'Scope', 'Inport', 2);
a = port_xy(m, 'heading', 'Outport', 1);  b = port_xy(m, 'moment', 'Outport', 1);
route(m, 'heading', 1, 'Scope', 1, [X+40 a(2); X+40 p1(2)]);
route(m, 'moment', 1, 'Scope', 2, [X+50 b(2); X+50 p2(2)]);
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','2', 'Position', [X+100 360 X+105 440]);
route(m, 'heading', 1, 'log', 1, [X+40 a(2); X+40 380]);
route(m, 'moment', 1, 'log', 2, [X+50 b(2); X+50 420]);
blk(m, 'simulink/Sinks/To Workspace', 'W04log', X+190, 400, [60 30], ...
    {'VariableName','W04log', 'SaveFormat','Structure With Time'});
route(m, 'log', 1, 'W04log', 1, zeros(0,2));
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
          round([cx-wh(1)/2 cy-wh(2)/2 cx+wh(1)/2 cy+wh(2)/2]), params{:});
end

function h = route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
h = add_line(sys, [a; via; b]);
end

% =========================================================================
function note(m, o)
L = {sprintf('WEEK 4, SECTION %s  -  %s', o.sec, o.title), ''};
if o.open
    L = [L, {'    N_open newton-metres of yaw moment from t = t_step, with X_ff newtons ahead.', ...
             '    Change N_open (5, 10, 20) and press Run: does the heading ever stop?'}];
else
    law = 'N = Kp e';
    if o.I, law = [law ' + Ki * integral(e)']; end
    if o.D, law = [law ' + Kd (Nf s / (s + Nf)) e']; end
    L{end+1} = ['    e = ssa(psi_d - psi) in rad,    ' law];
    L{end+1} = '    N is limited to +-N_max, what the propellers can give while pushing X_ff ahead';
    if o.I && ~o.aw, L{end+1} = '    port_eff = 0.7 makes the port propeller 30 % weak'; end
    if o.aw,     L{end+1} = '    anti-windup: i_dot = Ki e + Kb (N - u),  Kb = 0 switches it off'; end
    if o.wrap,   L{end+1} = '    psi_step = 170; psi_step2 = -170; t_step2 = 20;  then use_ssa = 0 and Run again'; end
    L = [L, {'', 'Change a gain in the Command Window (e.g. Kp = 300) and press Run:', ...
             'the Scope shows the heading in degrees (top) and the yaw moment (bottom).'}];
end
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
if o.open, a.Position = [40 60 700 170]; else, a.Position = [40 480 900 620]; end
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
