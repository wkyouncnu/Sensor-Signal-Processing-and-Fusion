function W08_1_build_dp(which)
%W08_1_BUILD_DP  8주차 모델을 코드로 만든다 — 실험 하나에 모델 하나.
%                Generate the Week 8 models, one model per experiment.
%
%   모델 넷 / the four models
%       W08_C_fixed        선수각을 고정한 채 자리를 지키려 한다 / holding station on a fixed heading
%       W08_D_weathervane  선수각을 조류 쪽으로 돌린다 / letting the bow turn into the flow
%       W08_E_cascade      게인을 고르는 실험 8-4 의 모델 / the model of Experiment 8-4
%       W08_F_mission      이동과 유지를 오가는 임무 / the mission: transit and hold
%
%   사슬 / the chain
%       mission (모드와 설정값) -> controller (X 와 N) -> allocation -> Otter
%       네 블록 모두 주석 달린 MATLAB Function 이다.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W08_0_setup');

M = struct( ...
  'name',   {'W08_C_fixed','W08_D_weathervane','W08_E_cascade','W08_F_mission'}, ...
  'vane',   {false, true, true, true}, ...
  'mission',{false, false, false, true}, ...
  'title',  {'HOLDING STATION ON A FIXED HEADING', 'LETTING THE BOW TURN INTO THE FLOW', ...
             'CHOOSING THE GAINS OF THE POSITION LOOP', 'A MISSION: TRANSIT, HOLD, TRANSIT'}, ...
  'sec',    {'8-2','8-3','8-4','8-5'});
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
Y = 220;

%% 임무 / the mission — 모드와 설정값
add_block('simulink/Sources/Clock', [m '/clock'], 'Position', [80 Y-10 100 Y+10]);
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/mission'], ...
          'Position', [170 Y-70 380 Y+70]);
set_mlfcn([m '/mission'], mission_code(o), 'p_d', '[2 1]', 'h');
p = {'N_hold','E_hold'};
if o.mission, p = [p {'WP_N','WP_E','R_arrive','T_hold','h'}]; end
mlfcn_params([m '/mission'], p);
route(m, 'clock', 1, 'mission', 1, zeros(0,2));
q = port_xy(m, 'mission', 'Inport', 2);
from_at(m, 'x', [80 q(2)], 'From ms x');
route(m, 'From ms x', 1, 'mission', 2, zeros(0,2));
goto_at(m, {'mission', 1}, port_xy(m, 'mission', 'Outport', 1), 'up', 'p_d');
q = port_xy(m, 'mission', 'Outport', 2);
add_block('simulink/Signal Routing/Goto', [m '/Goto mode'], 'GotoTag','mode', ...
          'TagVisibility','local', 'ShowName','off', 'Position', [420 q(2)-9 480 q(2)+9]);
route(m, 'mission', 2, 'Goto mode', 1, zeros(0,2));

%% 제어기 / the controller — 위치 루프와 4주차의 선수각 루프
XC = 530;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/controller'], ...
          'Position', [XC Y-70 XC+210 Y+70]);
set_mlfcn([m '/controller'], controller_code(o), 'tau', '[2 1]', 'h');
p = {'Kp_x','Ki_x','Kd_x','e_min','X_max','Kp','Kd','N_max','h'};
if o.mission, p = [p {'X_ff','Delta','hand_over'}]; end
if ~o.vane,   p = [p {'psi_fix'}]; end
mlfcn_params([m '/controller'], p);
for i = 1:3
    tag = {'p_d','x','mode'};  tag = tag{i};
    q = port_xy(m, 'controller', 'Inport', i);
    from_at(m, tag, [XC-100 q(2)], ['From c ' tag]);
    route(m, ['From c ' tag], 1, 'controller', i, zeros(0,2));
end
goto_at(m, {'controller', 1}, port_xy(m, 'controller', 'Outport', 1), 'down', 'tau');
q = port_xy(m, 'controller', 'Outport', 2);
add_block('simulink/Signal Routing/Goto', [m '/Goto psi_d'], 'GotoTag','psi_d', ...
          'TagVisibility','local', 'ShowName','off', 'Position', [XC+250 q(2)-9 XC+320 q(2)+9]);
route(m, 'controller', 2, 'Goto psi_d', 1, zeros(0,2));

%% 배분 / the allocation — 6주차의 것, 이번에는 X 와 N 을 함께 받는다
XB = XC + 360;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [XB Y-40 XB+180 Y+40]);
set_mlfcn([m '/allocation'], allocation_code(), 'n', '[2 1]');
mlfcn_params([m '/allocation'], {'y_pont','k_pos','k_neg','T_max','T_min'});
route(m, 'controller', 1, 'allocation', 1, zeros(0,2));

%% Otter
cfg = otter_config('base');
XO = XB + 250;
add_otter_plant(m, 'Otter', [XO Y-30 XO+100 Y+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
p = port_xy(m, 'allocation', 'Outport', 1);  q = port_xy(m, 'Otter', 'Inport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2)-q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
p = port_xy(m, 'Otter', 'Outport', 1);
goto_at(m, {'Otter', 1}, [p(1)+30 p(2)], 'down', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [p(1)+70 p(2)-8 p(1)+86 p(2)+8]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

measure(m, XO + 220, Y);
note(m, o);
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r60', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
function measure(m, X, Y)
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], ...
          'Position', [X Y-80 X+180 Y+80]);
set_mlfcn([m '/readouts'], readouts_code(), 'N_now', '[1 1]');
for i = 1:4
    tag = {'x','p_d','psi_d','tau'};  tag = tag{i};
    q = port_xy(m, 'readouts', 'Inport', i);
    from_at(m, tag, [X-90 q(2)], ['From ro ' tag]);
    route(m, ['From ro ' tag], 1, 'readouts', i, zeros(0,2));
end
out = {'N_now','E_now','psi_now','N_set','E_set','psi_set','X_now','Nm_now'};
for i = 1:8
    q = port_xy(m, 'readouts', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' out{i}], 'GotoTag',out{i}, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [X+210 q(2)-9 X+290 q(2)+9]);
    route(m, 'readouts', i, ['Goto ' out{i}], 1, zeros(0,2));
end

%  XY Graph 로 항적을, Scope 로 오차와 힘을 / the track, the error and the forces
S = X + 330;
add_block('simulink/Sinks/XY Graph', [m '/track'], 'Position', [S+120 Y-60 S+170 Y+10]);
set_param([m '/track'], 'xmin','-20', 'xmax','60', 'ymin','-20', 'ymax','60');
q1 = port_xy(m, 'track', 'Inport', 1);  q2 = port_xy(m, 'track', 'Inport', 2);
from_at(m, 'E_now', [S q1(2)], 'From tr E');
from_at(m, 'N_now', [S q2(2)], 'From tr N');
route(m, 'From tr E', 1, 'track', 1, zeros(0,2));
route(m, 'From tr N', 1, 'track', 2, zeros(0,2));

add_block('simulink/Signal Routing/Mux', [m '/pair'], 'Inputs','2', 'Position', [S+120 Y+80 S+125 Y+140]);
add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','2', 'Position', [S+190 Y+80 S+240 Y+180]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[2 1]', 'ShowLegend','on'); catch, end
for i = 1:2
    tag = {'psi_set','psi_now'};  tag = tag{i};
    q = port_xy(m, 'pair', 'Inport', i);
    from_at(m, tag, [S q(2)], ['From pr ' tag]);
    route(m, ['From pr ' tag], 1, 'pair', i, zeros(0,2));
end
route(m, 'pair', 1, 'Scope', 1, [S+160 port_xy(m,'pair','Outport',1)*[0;1]; ...
                                 S+160 port_xy(m,'Scope','Inport',1)*[0;1]]);
q = port_xy(m, 'Scope', 'Inport', 2);
from_at(m, 'X_now', [S q(2)], 'From sc X');
route(m, 'From sc X', 1, 'Scope', 2, zeros(0,2));
set_param([m '/Scope'], 'Open','on');

%  로그: [N_d E_d N E psi_d psi X Nm mode] / nine columns
tags = {'N_set','E_set','N_now','E_now','psi_set','psi_now','X_now','Nm_now','mode'};
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','9', 'Position', [S+420 Y-160 S+425 Y+240]);
for i = 1:9
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [S+330 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W08log'], 'VariableName','W08log', ...
          'SaveFormat','Structure With Time', 'Position', [S+470 p(2)-15 S+540 p(2)+15]);
route(m, 'log', 1, 'W08log', 1, zeros(0,2));
end

% =========================================================================
function C = mission_code(o)
if o.mission
C = {
'function [p_d, mode] = mission(t, x, N_hold, E_hold, WP_N, WP_E, R_arrive, T_hold, h)'
'%#codegen'
'%  임무 논리: 이동(1) -> 유지(2) -> 다음 지점 -> ... -> 끝(3)'
'%  The mission: transit (1) -> hold (2) -> the next waypoint -> ... -> done (3)'
'%'
'%  상태를 가진 블록이므로 이산 실행이다 (set_mlfcn 의 h). 규칙은 두 줄뿐이다:'
'%    이동 중이고 목표에 R_arrive 안으로 들어오면 유지로 바꾸고 시계를 0 으로.'
'%    유지 중이고 T_hold 가 지나면 다음 지점으로 가며 이동으로 바꾼다.'
'%  A block with memory, so it runs at a fixed rate. Two rules only:'
'%    in transit and inside R_arrive  -> hold, and reset the clock'
'%    in hold and T_hold has passed   -> the next waypoint, and transit'
'persistent k mode_ held'
'if isempty(k), k = 1; mode_ = 1; held = 0; end'
'd = hypot(WP_N(k) - x(7), WP_E(k) - x(8));'
'if mode_ == 1 && d < R_arrive'
'    mode_ = 2;  held = 0;'
'elseif mode_ == 2'
'    held = held + h;'
'    if held >= T_hold'
'        if k < numel(WP_N), k = k + 1;  mode_ = 1;  else, mode_ = 3; end'
'    end'
'end'
'p_d  = [WP_N(k); WP_E(k)];'
'mode = mode_;'
};
else
C = {
'function [p_d, mode] = mission(t, x, N_hold, E_hold)'
'%#codegen'
'%  이 모델의 임무는 하나뿐이다: 한 자리를 계속 붙잡는다.'
'%  This model has one task: hold one station, for ever.'
'p_d  = [N_hold; E_hold];'
'mode = 2;                    % 2 = 유지 / hold'
};
end
end

% =========================================================================
function C = controller_code(o)
args = 'p_d, x, mode, Kp_x, Ki_x, Kd_x, e_min, X_max, Kp, Kd, N_max, h';
if o.mission, args = [args ', X_ff, Delta, hand_over']; end
if ~o.vane,   args = [args ', psi_fix']; end
C = {
['function [tau, psi_d_out] = controller(' args ')']
'%#codegen'
'%  ────────────────────────────────────────────────────────────────────────'
'%  1) 얼마의 힘이 필요한가 — NED 에서 / how much force is needed, in NED'
'%'
'%     위치 오차에 대한 PID 를 **북·동 두 방향 모두**에 대해 쓴다. 나오는 것은'
'%     "이만큼의 힘이 이 방향으로 필요하다" 는 벡터 f 다. 아직 추진기 이야기가 아니다.'
'%     A PID on the position error, in both north and east: the result is a vector'
'%     saying how much force is wanted and in which direction. Not yet a thruster.'
'psi = x(12);  u = x(1);  v = x(2);  r = x(6);'
'e_n = p_d(1) - x(7);  e_e = p_d(2) - x(8);'
'v_n = u*cos(psi) - v*sin(psi);        % 속도를 NED 로 / the velocity in NED'
'v_e = u*sin(psi) + v*cos(psi);'
'persistent In Ie'
'if isempty(In), In = 0;  Ie = 0; end'
'f_n = Kp_x*e_n + In - Kd_x*v_n;'
'f_e = Kp_x*e_e + Ie - Kd_x*v_e;'
'%  ────────────────────────────────────────────────────────────────────────'
'%  2) 그 힘의 방향으로 뱃머리를 / point the bow along that force'
'%'
'%     이 선체가 낼 수 있는 힘은 **뱃머리 방향뿐**이다 (6주차 §6-3: B 의 둘째 행이 0).'
'%     그러므로 필요한 힘 f 를 내려면 뱃머리가 f 를 향해야 한다.'
'%     조류가 밀면 적분이 상류 쪽 힘을 배우고, 뱃머리는 그것을 따라 조류에 맞선다.'
'%     The only force this hull can make points along its bow (Week 6 §6-3), so to'
'%     deliver f the bow must point along f. Under a current the integral learns an'
'%     upstream force, and the bow follows it into the flow.'
'f  = hypot(f_n, f_e);'
};
if o.vane
C = [C; {
'persistent psi_last'
'if isempty(psi_last), psi_last = psi; end'
'if f > e_min, psi_last = atan2(f_e, f_n); end   % 힘이 작으면 방향이 뜻을 잃는다 / too small to point by'
'psi_d = psi_last;'
}];
else
C = [C; {
'%     이 모델은 선수각을 고정한다. f 가 뱃머리와 직각이면 한 뉴턴도 낼 수 없다 (§8-2).'
'%     This model fixes the heading: when f is across the bow, none of it can be made.'
'psi_d = psi_fix*pi/180;'
}];
end
if o.mission
C = [C; {
'%  ────────────────────────────────────────────────────────────────────────'
'%  2b) 이동 중이면 목표를 향해 / in transit, point at the waypoint'
'if mode == 1, psi_d = atan2(e_e, e_n); end'
}];
end
C = [C; {
'%  ────────────────────────────────────────────────────────────────────────'
'%  3) 뱃머리 방향의 성분만 추진기로 / only the along-bow part reaches the propellers'
'%     X = f 를 뱃머리에 정사영한 것. 옆 성분 f_y 는 아무도 낼 수 없다 —'
'%     그것이 이 주차가 재는 양이다.'
'%     X is f projected on the bow; the part across it, f_y, nobody can make.'
'X = f_n*cos(psi) + f_e*sin(psi);'
}];
if o.mission
C = [C; {
'if mode == 1'
'    X = X_ff;                                  % 이동 중에는 일정한 추진력 / a constant push'
'    if hand_over ~= 0, In = 0;  Ie = 0; end    % 유지를 깨끗한 적분으로 시작 / a clean integral for the hold'
'end'
}];
end
C = [C; {
'X = min(max(X, -X_max), X_max);'
'%  적분은 힘이 한계에 있지 않을 때만 쌓는다 (2주차 §2-11) / integrate only while there is room'
'if abs(X) < X_max - 1e-9'
'    In = In + h*Ki_x*e_n;'
'    Ie = Ie + h*Ki_x*e_e;'
'end'
'%  ────────────────────────────────────────────────────────────────────────'
'%  4) 요 모멘트: 4주차의 오토파일럿 그대로 / the yaw moment: the Week 4 autopilot'
'ee = atan2(sin(psi_d - psi), cos(psi_d - psi));'
'N  = Kp*ee - Kd*r;'
'N  = min(max(N, -N_max), N_max);'
}];
if o.mission
C = [C; {
'if mode == 3, X = 0;  N = 0; end                % 끝 / done'
}];
end
C = [C; {
'tau = [X; N];'
'psi_d_out = psi_d;'
}];
end

% =========================================================================
function C = allocation_code()
C = {
'function n = allocation(tau, y_pont, k_pos, k_neg, T_max, T_min)'
'%#codegen'
'%  6주차의 배분 그대로. 이번에는 X 가 상수가 아니라 위치 루프의 출력이다.'
'%  The allocation of Week 6, with X now coming from the position loop.'
'T1 = tau(1)/2 + tau(2)/(2*y_pont);'
'T2 = tau(1)/2 - tau(2)/(2*y_pont);'
's = 1;'
'if T1 > T_max, s = min(s, T_max/T1); end'
'if T2 > T_max, s = min(s, T_max/T2); end'
'if T1 < T_min, s = min(s, T_min/T1); end'
'if T2 < T_min, s = min(s, T_min/T2); end'
'T1 = s*T1;  T2 = s*T2;'
'k1 = k_pos;  if T1 < 0, k1 = k_neg; end'
'k2 = k_pos;  if T2 < 0, k2 = k_neg; end'
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'
};
end

% =========================================================================
function C = readouts_code()
C = {
'function [N_now, E_now, psi_now, N_set, E_set, psi_set, X_now, Nm_now] = readouts(x, p_d, psi_d, tau)'
'%#codegen'
'%  표시와 기록만 한다 / display and logging only'
'N_now = x(7);  E_now = x(8);  psi_now = x(12)*180/pi;'
'N_set = p_d(1);  E_set = p_d(2);  psi_set = psi_d*180/pi;'
'X_now = tau(1);  Nm_now = tau(2);'
};
end

% =========================================================================
function from_at(m, tag, at, name)
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -56; else, dy = 56; end
at = round(at);
g = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag',tag, 'ShowName','off', ...
          'TagVisibility','local', 'Position', [at(1)+12 at(2)+dy-9 at(1)+82 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

function h = route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
h = add_line(sys, [a; via; b]);
end

function note(m, o)
L = {sprintf('WEEK 8, SECTION %s  -  %s', o.sec, o.title), '', ...
     '   mission (mode and setpoint) -> controller (X and N) -> allocation -> Otter', ...
     '   double-click a block to read its code and comments', '', ...
     '   the position error is rotated into the body frame and split:', ...
     '     e_x  along the bow   - the propellers can answer this', ...
     '     e_y  to starboard    - only a turn can (Week 6: the sway row of B is zero)'};
if o.vane
    L{end+1} = '   psi_d = atan2(e_E, e_N): the bow turns towards the error, hence into the flow';
else
    L{end+1} = '   psi_d = psi_fix: the heading is held, and the sideways error is not answered';
end
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
a.Position = [90 40 900 170];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
