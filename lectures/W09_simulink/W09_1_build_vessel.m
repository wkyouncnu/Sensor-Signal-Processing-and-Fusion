function W09_1_build_vessel(which)
%W09_1_BUILD_VESSEL  9주차 모델을 코드로 만든다 — 여덟 주차가 한 배 위에.
%                    Generate the Week 9 models: eight weeks on one vessel.
%
%   모델 넷 / the four models — 구조는 같고 시나리오가 다르다
%       W09_C_full      기준이 되는 임무 / the reference mission
%       W09_D_ablation  주차를 하나씩 빼고 같은 임무 / the same mission, one week at a time removed
%       W09_E_weather   거친 바다와 센 조류 / a rougher sea and a stronger current
%       W09_F_limits    어디에서 무너지는가 / where it breaks
%
%   사슬 / the chain — 각 블록이 한 주차다
%       mission (8주차 상태기계) -> guidance (5주차 LOS/ILOS) -> controller
%       (3주차 속도 루프 · 4주차 선수각 · 8주차 위치 루프) -> allocation (6주차)
%       -> Otter (1주차);  계측에 7주차의 바다와 노치가 붙는다.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W09_0_setup');

M = struct('name', {'W09_C_full','W09_D_ablation','W09_E_weather','W09_F_limits'}, ...
           'sec',  {'9-2','9-3','9-4','9-5'}, ...
           'title',{'THE REFERENCE MISSION', 'ONE WEEK AT A TIME, REMOVED', ...
                    'A ROUGHER DAY', 'WHERE IT BREAKS'});
if nargin == 1, M = M(strcmp({M.name}, which)); end
for k = 1:numel(M), build_one(M(k), here); end
end

% =========================================================================
function build_one(o, here)
m = o.name;
out = fullfile(here, [m '.slx']);
bdclose(m);  if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
Y = 440;

%% 7주차 · 바다 / the sea
add_block('simulink/Sources/Clock', [m '/clock'], 'Position', [70 Y-190 90 Y-170]);
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/wave'], ...
          'Position', [150 Y-230 330 Y-130]);
set_mlfcn([m '/wave'], wave_code(), 'psi_w', '[1 1]');
mlfcn_params([m '/wave'], {'w_i','a_i','phi_i','k_w','wave_on'});
route(m, 'clock', 1, 'wave', 1, zeros(0,2));
for i = 1:2
    tag = {'psi_w','r_w'};  tag = tag{i};
    q = port_xy(m, 'wave', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [370 q(2)-9 430 q(2)+9]);
    route(m, 'wave', i, ['Goto ' tag], 1, zeros(0,2));
end

%% 계측과 7주차의 노치 / the measurement, and the notch of Week 7
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/measurement'], ...
          'Position', [150 Y-60 330 Y+60]);
set_mlfcn([m '/measurement'], measurement_code(), 'psi_m', '[1 1]');
for i = 1:3
    tag = {'x','psi_w','r_w'};  tag = tag{i};
    q = port_xy(m, 'measurement', 'Inport', i);
    from_at(m, tag, [60 q(2)], ['From ms ' tag]);
    route(m, ['From ms ' tag], 1, 'measurement', i, zeros(0,2));
end
NM = {'notch heading','notch rate'};  OUT = {'psi_f','r_f'};
for i = 1:2
    p = port_xy(m, 'measurement', 'Outport', i);
    add_block('simulink/Continuous/Transfer Fcn', [m '/' NM{i}], ...
              'Numerator','[1 2*zeta_n*w0 w0^2]', 'Denominator','[1 2*zeta_d*w0 w0^2]', ...
              'Position', [380 p(2)-22 470 p(2)+22]);
    route(m, 'measurement', i, NM{i}, 1, zeros(0,2));
    %  태그는 노치 **아래쪽**으로 내린다. 옆에 두면 임무 블록이 읽어 가는 x 태그와
    %  자리가 겹친다 / take the tags below the notch, clear of the mission's From block
    q = port_xy(m, NM{i}, 'Outport', 1);  yg = Y + 120 + 50*i;  xv = 476 + 12*i;
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' OUT{i}], 'GotoTag',OUT{i}, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [500 yg-9 570 yg+9]);
    route(m, NM{i}, 1, ['Goto ' OUT{i}], 1, [xv q(2); xv yg]);
end

%% 8주차 · 임무 상태기계 / the mission state machine
XM = 540;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/mission'], ...
          'Position', [XM Y-60 XM+190 Y+60]);
set_mlfcn([m '/mission'], mission_code(), 'wp', '[1 1]', 'h');
mlfcn_params([m '/mission'], {'WP_N','WP_E','R_arrive','T_hold','use_pass','h'});
q = port_xy(m, 'mission', 'Inport', 1);
from_at(m, 'x', [XM-90 q(2)], 'From mi x');
route(m, 'From mi x', 1, 'mission', 1, zeros(0,2));
for i = 1:2
    tag = {'wp','mode'};  tag = tag{i};
    q = port_xy(m, 'mission', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [XM+230 q(2)-9 XM+295 q(2)+9]);
    route(m, 'mission', i, ['Goto ' tag], 1, zeros(0,2));
end

%% 3~5·8주차 · 제어기 / the controller: the speed, heading, guidance and position loops
XC = XM + 330;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/controller'], ...
          'Position', [XC Y-90 XC+220 Y+90]);
set_mlfcn([m '/controller'], controller_code(), 'tau', '[2 1]', 'h');
mlfcn_params([m '/controller'], {'WP_N','WP_E','Delta','kappa','u_d','Kp_u','Ki_u', ...
                                 'Kp','Kd','Kp_x','Ki_x','Kd_x','e_min','X_max','N_max','N_open', ...
                                 'use_Ki_u','use_ssa','use_Kd','use_ilos','use_scale','use_vane','hand_over','h'});
for i = 1:5
    tag = {'x','psi_f','r_f','wp','mode'};  tag = tag{i};
    q = port_xy(m, 'controller', 'Inport', i);
    from_at(m, tag, [XC-90 q(2)], ['From co ' tag]);
    route(m, ['From co ' tag], 1, 'controller', i, zeros(0,2));
end
goto_at(m, {'controller', 1}, port_xy(m, 'controller', 'Outport', 1), 'down', 'tau');
for i = 2:3
    tag = {'','psi_d','y_e'};  tag = tag{i};
    q = port_xy(m, 'controller', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [XC+260 q(2)-9 XC+325 q(2)+9]);
    route(m, 'controller', i, ['Goto ' tag], 1, zeros(0,2));
end

%% 6주차 · 배분 / the allocation
XB = XC + 370;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [XB Y-40 XB+180 Y+40]);
set_mlfcn([m '/allocation'], allocation_code(), 'n', '[2 1]');
mlfcn_params([m '/allocation'], {'y_pont','k_pos','k_neg','T_max','T_min','use_scale'});
route(m, 'controller', 1, 'allocation', 1, zeros(0,2));

%% 1주차 · Otter
cfg = otter_config('base');
XO = XB + 250;
add_otter_plant(m, 'Otter', [XO Y-30 XO+100 Y+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
p = port_xy(m, 'allocation', 'Outport', 1);  q = port_xy(m, 'Otter', 'Inport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2)-q(2)));
add_line(m, [p; port_xy(m, 'Otter', 'Inport', 1)]);
p = port_xy(m, 'Otter', 'Outport', 1);
goto_at(m, {'Otter', 1}, [p(1)+30 p(2)], 'down', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [p(1)+70 p(2)-8 p(1)+86 p(2)+8]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

measure(m, XO + 230, Y);
note(m, o);
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r50', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-18s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
function measure(m, X, Y)
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], ...
          'Position', [X Y-90 X+180 Y+90]);
set_mlfcn([m '/readouts'], readouts_code(), 'N_now', '[1 1]');
for i = 1:3
    tag = {'x','psi_d','tau'};  tag = tag{i};
    q = port_xy(m, 'readouts', 'Inport', i);
    from_at(m, tag, [X-90 q(2)], ['From ro ' tag]);
    route(m, ['From ro ' tag], 1, 'readouts', i, zeros(0,2));
end
out = {'N_now','E_now','psi_now','psi_set','u_now','X_now','Nm_now'};
for i = 1:7
    q = port_xy(m, 'readouts', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' out{i}], 'GotoTag',out{i}, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [X+210 q(2)-9 X+285 q(2)+9]);
    route(m, 'readouts', i, ['Goto ' out{i}], 1, zeros(0,2));
end

S = X + 330;
add_block('simulink/Sinks/XY Graph', [m '/track'], 'Position', [S+120 Y-90 S+170 Y-20]);
set_param([m '/track'], 'xmin','-20', 'xmax','90', 'ymin','-20', 'ymax','90');
from_at(m, 'E_now', [S port_xy(m,'track','Inport',1)*[0;1]], 'From tr E');
from_at(m, 'N_now', [S port_xy(m,'track','Inport',2)*[0;1]], 'From tr N');
route(m, 'From tr E', 1, 'track', 1, zeros(0,2));
route(m, 'From tr N', 1, 'track', 2, zeros(0,2));

add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','3', 'Position', [S+190 Y+20 S+240 Y+140]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[3 1]', 'ShowLegend','on'); catch, end
for i = 1:3
    tag = {'y_e','u_now','Nm_now'};  tag = tag{i};
    q = port_xy(m, 'Scope', 'Inport', i);
    from_at(m, tag, [S q(2)], ['From sc ' tag]);
    route(m, ['From sc ' tag], 1, 'Scope', i, zeros(0,2));
end
set_param([m '/Scope'], 'Open','on');

tags = {'mode','N_now','E_now','psi_now','psi_set','y_e','u_now','X_now','Nm_now','wp'};
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','10', 'Position', [S+420 Y-180 S+425 Y+260]);
for i = 1:10
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [S+330 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W09log'], 'VariableName','W09log', ...
          'SaveFormat','Structure With Time', 'Position', [S+470 p(2)-15 S+540 p(2)+15]);
route(m, 'log', 1, 'W09log', 1, zeros(0,2));
end

% =========================================================================
function C = wave_code()
C = {
'function [psi_w, r_w] = wave(t, w_i, a_i, phi_i, k_w, wave_on)'
'%#codegen'
'%  7주차의 바다 그대로 / the sea of Week 7, unchanged'
'psi_w = 0;  r_w = 0;'
'if wave_on ~= 0'
'    for i = 1:numel(w_i)'
'        psi_w = psi_w + k_w*a_i(i)*sin(w_i(i)*t + phi_i(i));'
'        r_w   = r_w   + k_w*a_i(i)*w_i(i)*cos(w_i(i)*t + phi_i(i));'
'    end'
'end'
};
end

function C = measurement_code()
C = {
'function [psi_m, r_m] = measurement(x, psi_w, r_w)'
'%#codegen'
'%  제어기가 보는 것 = 배가 하는 것 + 1차 파랑 (7주차 §7-2)'
'psi_m = x(12)*180/pi + psi_w;'
'r_m   = x(6)*180/pi  + r_w;'
};
end

function C = mission_code()
C = {
'function [wp, mode] = mission(x, WP_N, WP_E, R_arrive, T_hold, use_pass, h)'
'%#codegen'
'%  8주차 §8-5 의 상태기계. 규칙은 둘뿐이다.'
'%  The state machine of Week 8 §8-5: two rules only.'
'persistent k mode_ held'
'if isempty(k), k = 1; mode_ = 1; held = 0; end'
'd = hypot(WP_N(k) - x(7), WP_E(k) - x(8));'
'%  도착 판정 / the arrival test'
'%    원 안에 들어왔는가 — 빠르게 지나가면 놓칠 수 있다 (§9-5)'
'%    그리고 5주차의 판정: 다리 방향으로 남은 거리가 음수가 되었는가, 즉 지나갔는가'
'%    the acceptance circle, which a fast pass can miss, and the along-track test'
'%    of Week 5: the distance still to run along the leg has gone negative'
'if k > 1, N0 = WP_N(k-1);  E0 = WP_E(k-1);  else, N0 = 0;  E0 = 0;  end'
'pi_p   = atan2(WP_E(k) - E0, WP_N(k) - N0);'
'x_left = (WP_N(k) - x(7))*cos(pi_p) + (WP_E(k) - x(8))*sin(pi_p);'
'reached = d < R_arrive || (use_pass ~= 0 && x_left < 0);'
'if mode_ == 1 && reached'
'    mode_ = 2;  held = 0;'
'elseif mode_ == 2'
'    held = held + h;'
'    if held >= T_hold'
'        if k < numel(WP_N), k = k + 1;  mode_ = 1;  else, mode_ = 3; end'
'    end'
'end'
'wp = k;  mode = mode_;'
};
end

function C = controller_code()
C = {
'function [tau, psi_d_out, y_e_out] = controller(x, psi_f, r_f, wp, mode, WP_N, WP_E, Delta, kappa, u_d, Kp_u, Ki_u, Kp, Kd, Kp_x, Ki_x, Kd_x, e_min, X_max, N_max, N_open, use_Ki_u, use_ssa, use_Kd, use_ilos, use_scale, use_vane, hand_over, h)'
'%#codegen'
'%  여덟 주차가 한 블록에 들어 있다. 모드에 따라 어느 줄이 도는지가 달라질 뿐이다.'
'%  Eight weeks in one block; the mode decides which lines run.'
'psi = x(12);  u = x(1);  v = x(2);'
'psi_m = psi_f*pi/180;  r_m = r_f*pi/180;      % 노치를 지난 계측 (7주차)'
'k = wp;  y_e = 0;'
'persistent I_u y_int In Ie psi_last'
'if isempty(I_u), I_u = 0; y_int = 0; In = 0; Ie = 0; psi_last = psi; end'
'if mode == 1'
'    %  ── 이동 / transit ────────────────────────────────────────────────'
'    %  5주차: 앞 지점에서 이 지점으로 가는 다리 위의 횡방향 오차와 LOS/ILOS'
'    %  Week 5: the cross-track error of the active leg, and the LOS or ILOS law'
'    if k > 1, N0 = WP_N(k-1);  E0 = WP_E(k-1);  else, N0 = 0;  E0 = 0;  end'
'    pi_p = atan2(WP_E(k) - E0, WP_N(k) - N0);'
'    y_e  = -(x(7) - N0)*sin(pi_p) + (x(8) - E0)*cos(pi_p);'
'    if use_ilos ~= 0'
'        psi_d = pi_p - atan((y_e + kappa*y_int)/Delta);'
'        y_int = y_int + h*Delta*y_e/(Delta^2 + (y_e + kappa*y_int)^2);'
'    else'
'        psi_d = pi_p - atan(y_e/Delta);'
'    end'
'    %  3주차: 속도 루프 / Week 3: the speed loop'
'    eu = u_d - u;'
'    X  = Kp_u*eu + I_u;'
'    X  = min(max(X, -X_max), X_max);'
'    if use_Ki_u ~= 0 && abs(X) < X_max - 1e-9, I_u = I_u + h*Ki_u*eu; end'
'    if hand_over ~= 0, In = 0;  Ie = 0; end   % 8주차: 유지를 깨끗하게 시작하도록'
'    psi_last = psi_d;                         % 유지가 이어받는 선수각 / the heading a hold inherits'
'else'
'    %  ── 유지 / hold ──────────────────────────────────────────────────'
'    %  8주차: 위치 PID 를 NED 에서 풀고, 그 힘의 방향으로 뱃머리를 둔다'
'    e_n = WP_N(k) - x(7);  e_e = WP_E(k) - x(8);'
'    v_n = u*cos(psi) - v*sin(psi);  v_e = u*sin(psi) + v*cos(psi);'
'    f_n = Kp_x*e_n + In - Kd_x*v_n;'
'    f_e = Kp_x*e_e + Ie - Kd_x*v_e;'
'    if use_vane ~= 0'
'        if hypot(f_n, f_e) > e_min, psi_last = atan2(f_e, f_n); end'
'        psi_d = psi_last;'
'    else'
'        psi_d = psi_last;                      % 도착했을 때의 선수각을 그대로'
'    end'
'    X = f_n*cos(psi) + f_e*sin(psi);'
'    X = min(max(X, -X_max), X_max);'
'    if abs(X) < X_max - 1e-9'
'        In = In + h*Ki_x*e_n;  Ie = Ie + h*Ki_x*e_e;'
'    end'
'    I_u = 0;'
'end'
'%  ── 4주차: 선수각 / Week 4: the heading loop ─────────────────────────'
'%  4주차 §4-6 의 ssa. 끄면 이음매에서 오차가 한 바퀴만큼 뛴다.'
'%  The ssa of Week 4 §4-6. Switched off, the error jumps by a whole turn at the seam.'
'if use_ssa ~= 0'
'    ee = atan2(sin(psi_d - psi_m), cos(psi_d - psi_m));'
'else'
'    ee = psi_d - psi_m;'
'end'
'N  = Kp*ee;'
'if use_Kd ~= 0, N = N - Kd*r_m; end'
'%  6주차: 요 한계는 **이미 쓰고 있는 전진력에 달려 있다**. use_scale = 0 은 그 결합을'
'%  잊은 설계다 — 전진력이 0 일 때의 한계 N_open 을 그대로 쓴다.'
'%  Week 6: the yaw limit depends on the surge already spent. use_scale = 0 is the'
'%  design that forgets the coupling and keeps N_open, the limit at zero surge.'
'N_lim = N_max;'
'if use_scale == 0, N_lim = N_open; end'
'N  = min(max(N, -N_lim), N_lim);'
'if mode == 3, X = 0;  N = 0; end'
'tau = [X; N];  psi_d_out = psi_d;  y_e_out = y_e;'
};
end

function C = allocation_code()
C = {
'function n = allocation(tau, y_pont, k_pos, k_neg, T_max, T_min, use_scale)'
'%#codegen'
'%  6주차의 배분. use_scale = 0 이면 §6-6 의 자르기로 돌아간다.'
'T1 = tau(1)/2 + tau(2)/(2*y_pont);'
'T2 = tau(1)/2 - tau(2)/(2*y_pont);'
'if use_scale ~= 0'
'    %  6주차 §6-6: 둘을 같은 비율로 줄이면 방향이 지켜진다 / scale, and the direction survives'
'    s = 1;'
'    if T1 > T_max, s = min(s, T_max/T1); end'
'    if T2 > T_max, s = min(s, T_max/T2); end'
'    if T1 < T_min, s = min(s, T_min/T1); end'
'    if T2 < T_min, s = min(s, T_min/T2); end'
'    T1 = s*T1;  T2 = s*T2;'
'else'
'    %  각각 따로 자른다. 한쪽만 잘리면 두 추진기의 차가 달라지고,'
'    %  그래서 **명령한 모멘트가 나오지 않는다** (6주차 §6-6).'
'    %  Clip each on its own: when only one is clipped the difference changes,'
'    %  so the moment that comes out is not the moment that was asked for.'
'    T1 = min(max(T1, T_min), T_max);'
'    T2 = min(max(T2, T_min), T_max);'
'end'
'k1 = k_pos;  if T1 < 0, k1 = k_neg; end'
'k2 = k_pos;  if T2 < 0, k2 = k_neg; end'
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'
};
end

function C = readouts_code()
C = {
'function [N_now, E_now, psi_now, psi_set, u_now, X_now, Nm_now] = readouts(x, psi_d, tau)'
'%#codegen'
'N_now = x(7);  E_now = x(8);  psi_now = x(12)*180/pi;  psi_set = psi_d*180/pi;'
'u_now = x(1);  X_now = tau(1);  Nm_now = tau(2);'
};
end

% =========================================================================
function from_at(m, tag, at, name)
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -60; else, dy = 60; end
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
L = {sprintf('WEEK 9, SECTION %s  -  %s', o.sec, o.title), '', ...
     '   wave (W7) -> measurement -> notch (W7) -> mission (W8) -> controller -> allocation (W6) -> Otter (W1)', ...
     '   inside the controller:  guidance (W5) | speed loop (W3) | heading loop (W4) | position loop (W8)', '', ...
     '   every week has a switch in W09_0_setup. Set one to 0 and fly the same mission without it:', ...
     '     use_Ki_u (W3)   use_ssa, use_Kd (W4)   use_ilos, use_pass (W5)', ...
     '     use_scale (W6)   use_notch (W7)   use_vane, hand_over (W8)'};
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
a.Position = [70 40 1000 180];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
