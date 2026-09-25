function W06_1_build_allocation(which)
%W06_1_BUILD_ALLOCATION  6주차 모델을 코드로 만든다 — 실험 하나에 모델 하나.
%                        Generate the Week 6 models, one model per experiment.
%
%   W06_1_build_allocation              전부 / all of them
%   W06_1_build_allocation('W06_F_limits')   하나만 / just one
%
%   모델 넷 / the four models
%       W06_C_square    두 요구(X, N)를 두 추진기로 — 3~5주차가 쓰던 정사각 배분
%                       two demands on two propellers: the square rule of Weeks 3 to 5
%       W06_D_pseudo    요구가 셋(X, Y, N) — 최소자승이 못 내는 것을 버린다
%                       three demands: least squares drops what the hull cannot make
%       W06_E_curve     추력에서 회전수로 — 역곡선을 틀리면 어떻게 되는가
%                       thrust to shaft speed, and what a wrong inverse costs
%       W06_F_limits    요구가 한계를 넘을 때 — 자르기와 비율 줄이기
%                       past the limits: clipping against scaling
%
%   모든 모델의 사슬은 같다 / every model is the same chain
%       demand (시간표) -> allocation -> Otter -> readouts -> Scope 와 로그
%       네 블록 모두 주석 달린 MATLAB Function 이다. 더블클릭하면 이 주차의 식이 나온다.
%       All four are commented MATLAB Function blocks: double-click one to read
%       the equations of this week.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W06_0_setup');

M = struct( ...
  'name',  {'W06_C_square','W06_D_pseudo','W06_E_curve','W06_F_limits'}, ...
  'case',  {1, 2, 3, 4}, ...
  'limits',{false, false, false, true}, ...
  'title', {'TWO DEMANDS, TWO PROPELLERS: THE SQUARE RULE', ...
            'THREE DEMANDS: WHAT LEAST SQUARES DROPS', ...
            'THRUST TO SHAFT SPEED: THE INVERSE OF THE CURVE', ...
            'PAST THE LIMITS: CLIPPING AGAINST SCALING'}, ...
  'sec',   {'6-2','6-3','6-5','6-6'});
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
Y = 200;

%% 요구 / the demand — 시간의 함수, 절마다 다른 시간표
add_block('simulink/Sources/Clock', [m '/clock'], 'Position', [120 Y-10 140 Y+10]);
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/demand'], ...
          'Position', [210 Y-60 390 Y+60]);
set_mlfcn([m '/demand'], demand_code(o.case), 'tau_d', '[3 1]');
mlfcn_params([m '/demand'], {'X_cmd','Y_cmd','N_cmd','X_big','N_big'});
route(m, 'clock', 1, 'demand', 1, zeros(0,2));
goto_at(m, {'demand', 1}, port_xy(m, 'demand', 'Outport', 1), 'up', 'tau_d');

%% 배분 / the allocation — 이 주차의 본론
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [480 Y-60 700 Y+60]);
set_mlfcn([m '/allocation'], allocation_code(o), 'n', '[2 1]');
p = {'y_pont','k_pos','k_neg','use_kneg'};
if o.limits, p = [p {'T_max','T_min','fit_mode'}]; end
mlfcn_params([m '/allocation'], p);
route(m, 'demand', 1, 'allocation', 1, zeros(0,2));
for i = 2:3                                  % tau_a, T -> Goto 태그 / to Goto tags
    tag = {'','tau_a','T'};  tag = tag{i};
    q = port_xy(m, 'allocation', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [740 q(2)-9 800 q(2)+9]);
    route(m, 'allocation', i, ['Goto ' tag], 1, zeros(0,2));
end

%% Otter
cfg = otter_config('base');
add_otter_plant(m, 'Otter', [880 Y-30 980 Y+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
p = port_xy(m, 'allocation', 'Outport', 1);  q = port_xy(m, 'Otter', 'Inport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2)-q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
p = port_xy(m, 'Otter', 'Outport', 1);
goto_at(m, {'Otter', 1}, [p(1)+30 p(2)], 'up', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [p(1)+70 p(2)-8 p(1)+86 p(2)+8]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

measure(m, 1010);
note(m, o);
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r60', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-18s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
function measure(m, X)
%  readouts: 상태에서 전진속도와 회두율만 꺼낸다 / surge speed and yaw rate from the state
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], ...
          'Position', [X+80 70 X+250 150]);
set_mlfcn([m '/readouts'], readouts_code(), 'u', '[1 1]');
from_at(m, 'x', [X port_xy(m, 'readouts', 'Inport', 1)*[0;1]]);
route(m, 'From x', 1, 'readouts', 1, zeros(0,2));
for i = 1:2
    tag = {'u','r_deg'};  tag = tag{i};
    q = port_xy(m, 'readouts', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [X+290 q(2)-9 X+350 q(2)+9]);
    route(m, 'readouts', i, ['Goto ' tag], 1, zeros(0,2));
end

%  Scope 셋: 요구한 힘, 전달된 힘, 추진기 추력 / demanded, delivered, and the two thrusts
S = X + 370;
add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','3', 'Position', [S+120 60 S+170 200]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[3 1]', 'ShowLegend','on'); catch, end
for i = 1:3
    tag = {'tau_d','tau_a','T'};  tag = tag{i};
    s = port_xy(m, 'Scope', 'Inport', i);
    from_at(m, tag, [S s(2)], ['From sc ' tag]);
    route(m, ['From sc ' tag], 1, 'Scope', i, zeros(0,2));
end
set_param([m '/Scope'], 'Open','on');

%  로그: [tau_d; tau_a; T; u; r] = 10 열 / ten columns
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','5', 'Position', [S+280 60 S+285 300]);
tags = {'tau_d','tau_a','T','u','r_deg'};
for i = 1:5
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [S+195 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W06log'], 'VariableName','W06log', ...
          'SaveFormat','Structure With Time', 'Position', [S+330 p(2)-15 S+400 p(2)+15]);
route(m, 'log', 1, 'W06log', 1, zeros(0,2));
end

% =========================================================================
function C = readouts_code()
C = {
'function [u, r_deg] = readouts(x)'
'%#codegen'
'%  상태에서 보고 싶은 둘만 꺼낸다 / the two states this week watches'
'%     x = [u v w p q r  N E z  phi theta psi]'
'u     = x(1);           % 전진속도 / surge speed   [m/s]'
'r_deg = x(6)*180/pi;    % 회두율 / yaw rate        [deg/s]'
};
end

% =========================================================================
function C = demand_code(c)
%  요구하는 일반화 힘의 시간표. 절마다 다르다 / the demand timetable, one per section
head = {
'function tau_d = demand(t, X_cmd, Y_cmd, N_cmd, X_big, N_big)'
'%#codegen'
'%  이 블록은 제어기를 대신한다. 3~5주차에서는 속도·선수각 제어기가 이 세 수를 냈다.'
'%  이번 주가 묻는 것은 그 다음이다: 이 요구를 추진기 둘에 어떻게 나누는가?'
'%  This block stands in for the controllers of Weeks 3 to 5, which produced'
'%  these three numbers. This week asks what happens next: how are they shared'
'%  between two propellers?'
'%'
'%     tau_d = [X ; Y ; N]   전진력 [N], 횡력 [N], 요 모멘트 [N m]'
'tau_d = [0; 0; 0];'
};
switch c
    case 1
        body = {
'%  6-2 의 시간표: 전진력만, 그 다음 요 모멘트를 좌우로 / surge alone, then yaw both ways'
'if     t >=  5 && t < 15, tau_d = [X_cmd; 0;  0    ];'
'elseif t >= 15 && t < 25, tau_d = [X_cmd; 0;  N_cmd];'
'elseif t >= 25 && t < 35, tau_d = [X_cmd; 0; -N_cmd];'
'end'
        };
    case 2
        body = {
'%  6-3 의 시간표: 횡력을 요구해 본다 — 이 선체에는 옆으로 미는 추진기가 없다'
'%  the timetable of 6-3: a sway force is demanded, from a hull that has no'
'%  thruster able to push sideways'
'if     t >=  5 && t < 15, tau_d = [X_cmd; 0;     0    ];'
'elseif t >= 15 && t < 25, tau_d = [X_cmd; Y_cmd; 0    ];'
'elseif t >= 25 && t < 35, tau_d = [0;     Y_cmd; 0    ];'
'elseif t >= 35,           tau_d = [X_cmd; Y_cmd; N_cmd];'
'end'
        };
    case 3
        body = {
'%  6-5 의 시간표: 앞으로, 뒤로, 그리고 좌우 선회 / ahead, astern, then yaw both ways'
'%  후진 구간이 핵심이다 — 추력계수가 전진과 다르기 때문이다'
'%  the astern leg is the point: the thrust coefficient is not the same backwards'
'if     t >=  5 && t < 15, tau_d = [ X_cmd; 0;  0    ];'
'elseif t >= 15 && t < 25, tau_d = [-X_cmd; 0;  0    ];'
'elseif t >= 25 && t < 35, tau_d = [ 0;     0;  N_cmd];'
'elseif t >= 35,           tau_d = [ 0;     0; -N_cmd];'
'end'
        };
    otherwise
        body = {
'%  6-6 의 시간표: 추진기가 낼 수 있는 것보다 큰 요구 / demands past what the propellers have'
'if     t >=  5 && t < 15, tau_d = [ X_big; 0; 0    ];'
'elseif t >= 15 && t < 25, tau_d = [ X_big; 0; N_big];'
'elseif t >= 25 && t < 35, tau_d = [ X_cmd; 0; N_big];'
'elseif t >= 35,           tau_d = [-X_big; 0; 0    ];'
'end'
        };
end
C = [head; body];
end

% =========================================================================
function C = allocation_code(o)
%  이 주차의 본론. 네 단계이고, 한계 처리는 6-6 의 모델에만 있다.
%  The subject of the week, in four steps; the limit step is only in the 6-6 model.
if o.limits
    sig = 'function [n, tau_a, T] = allocation(tau_d, y_pont, k_pos, k_neg, use_kneg, T_max, T_min, fit_mode)';
else
    sig = 'function [n, tau_a, T] = allocation(tau_d, y_pont, k_pos, k_neg, use_kneg)';
end
C = {
sig
'%#codegen'
'%  ────────────────────────────────────────────────────────────────────────'
'%  1) 일반화 힘 -> 추력 둘 / from the demanded force to two thrusts'
'%'
'%     이 선체의 제어 유효행렬은 (부록 A1 의 열 규칙에서)'
'%     The control effectiveness matrix of this hull, from the column rule of A1:'
'%'
'%         tau = B T,   B = [ 1        1      ;'
'%                            0        0      ;'
'%                            y_pont  -y_pont ]'
'%'
'%     B 의 둘째 행이 0 이다 — 두 추진기 모두 옆으로 밀지 못한다. 그래서 Y 는'
'%     어떤 T 로도 만들 수 없고, 최소자승해는 그것을 조용히 버린다 (§6-3).'
'%     The second row is zero: neither propeller pushes sideways, so no T can'
'%     produce Y, and the least-squares solution simply drops it (§6-3).'
'%'
'%     남은 두 행은 정사각이고 가역이다 / the remaining two rows are square and invertible:'
'%'
'%         T1 = X/2 + N/(2 y_pont),   T2 = X/2 - N/(2 y_pont)'
'T1 = tau_d(1)/2 + tau_d(3)/(2*y_pont);'
'T2 = tau_d(1)/2 - tau_d(3)/(2*y_pont);'
};
if o.limits
C = [C; {
'%  ────────────────────────────────────────────────────────────────────────'
'%  2) 한계 안으로 / into the limits'
'%     fit_mode = 0  자른다. 각 추력을 따로 한계에 맞춘다 — 비율이 깨져'
'%                   전달되는 힘의 **방향**이 달라진다 (§6-6).'
'%     fit_mode = 1  비율로 줄인다. 둘 다 같은 s 로 곱해 방향을 지킨다.'
'%     0 clips each thrust on its own, which changes the direction of the'
'%       delivered force; 1 scales both by one factor s and keeps it.'
'if fit_mode == 0'
'    T1 = min(max(T1, T_min), T_max);'
'    T2 = min(max(T2, T_min), T_max);'
'else'
'    s = 1;'
'    if T1 > T_max, s = min(s, T_max/T1); end'
'    if T2 > T_max, s = min(s, T_max/T2); end'
'    if T1 < T_min, s = min(s, T_min/T1); end'
'    if T2 < T_min, s = min(s, T_min/T2); end'
'    T1 = s*T1;  T2 = s*T2;'
'end'
}];
end
C = [C; {
'%  ────────────────────────────────────────────────────────────────────────'
'%  3) 추력 -> 회전수 / thrust to shaft speed'
'%     프로펠러 곡선은 T = k n|n| 이고, k 가 전진과 후진에서 다르다 (1주차).'
'%     따라서 역함수도 방향에 따라 다른 k 를 써야 한다 — use_kneg = 0 으로 두면'
'%     후진에도 k_pos 를 써서 요구보다 적은 힘이 나온다 (§6-5).'
'%     The propeller curve is T = k n|n| with a different k astern (Week 1), so'
'%     the inverse must use the same k. With use_kneg = 0 it uses k_pos both'
'%     ways, and the vessel gets less than it asked for going astern.'
'k1 = k_pos;  if T1 < 0 && use_kneg == 1, k1 = k_neg; end'
'k2 = k_pos;  if T2 < 0 && use_kneg == 1, k2 = k_neg; end'
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'
'%  ────────────────────────────────────────────────────────────────────────'
'%  4) 실제로 전달된 힘 / the force actually delivered'
'%     축이 그 회전수로 돌 때 프로펠러가 내는 추력을 다시 곡선으로 계산하고,'
'%     그것을 B 로 곱한다. 요구와 다르면 그 차이가 이 주차의 관찰 대상이다.'
'%     The thrust those shafts really produce, put back through B. Any gap'
'%     between this and the demand is what this week is about.'
'T1a = k_pos*n(1)*abs(n(1));  if n(1) < 0, T1a = k_neg*n(1)*abs(n(1)); end'
'T2a = k_pos*n(2)*abs(n(2));  if n(2) < 0, T2a = k_neg*n(2)*abs(n(2)); end'
'tau_a = [T1a + T2a; 0; y_pont*(T1a - T2a)];'
'T = [T1a; T2a];'
}];
end

% =========================================================================
function from_at(m, tag, at, name)
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -46; else, dy = 46; end
at = round(at);
g = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag',tag, 'ShowName','off', ...
          'TagVisibility','local', 'Position', [at(1)+12 at(2)+dy-9 at(1)+72 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

function h = route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
h = add_line(sys, [a; via; b]);
end

function note(m, o)
L = {sprintf('WEEK 6, SECTION %s  -  %s', o.sec, o.title), '', ...
     '   demand (a controller would produce this) -> allocation -> Otter', ...
     '   double-click a block to read its code and comments', '', ...
     '   tau = B T,   B = [1 1 ; 0 0 ; y_pont -y_pont]        the column rule of Appendix A1', ...
     '   T1 = X/2 + N/(2 y_pont),   T2 = X/2 - N/(2 y_pont)   the square rule inverted', ...
     '   n  = sign(T) sqrt(|T|/k)                             the propeller curve inverted', ''};
if o.limits
    L{end+1} = '   fit_mode = 1 scales both thrusts by one factor; 0 clips them one at a time.';
end
L = [L, {'The Scope shows the force demanded (top), the force delivered (middle)', ...
         'and the two thrusts (bottom). Change a value in the Command Window and press Run.'}];
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
a.Position = [120 330 860 480];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
