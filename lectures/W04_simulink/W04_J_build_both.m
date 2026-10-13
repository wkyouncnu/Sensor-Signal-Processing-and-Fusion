function W04_J_build_both()
%W04_J_BUILD_BOTH  4-8 절의 모델 하나 — 속도 루프와 선수각 루프를 **같은 배에**.
%                  The model of section 4-8: the speed loop and the heading loop
%                  on one hull.
%
%   실행 / to run
%       W04_0_setup
%       W04_J_build_both
%       open_system('W04_J_both')     그리고 Run / then press Run
%
%   무엇이 새로운가 / what is new
%       4주차의 모델 일곱은 전진력이 **상수** X_ff 였다. 선수각만 제어했고, 배가
%       얼마나 빨리 가는지는 항력이 정했다. 이 모델은 3주차의 속도 루프를 그 자리에
%       넣는다. 이제 두 제어기가 **같은 두 프로펠러**를 나눠 쓴다.
%       The seven Week 4 models drove the hull with a constant surge force: only
%       the heading was controlled, and how fast the vessel went was settled by
%       drag. This model puts the Week 3 speed loop in that place, and the two
%       controllers then share the same two propellers.
%
%   왜 이 모델이 필요한가 / why it is here
%       5주차의 유도는 **두 명령을 동시에** 낸다 - 목표 선수각과 목표 속도. 그 두
%       명령을 받는 쪽이 이 모델이고, 유도를 붙이기 전에 **안쪽이 먼저 맞는지**
%       확인하는 자리다. 명령을 계단으로 조금씩 움직여 둘 다 따라가는지 본다.
%       The guidance of Week 5 issues two commands at once. This model is what
%       receives them, and it is where the inner pair is checked before any
%       guidance is attached: both commands move in small steps and both loops
%       are watched following them.
%
%   제어기 둘은 **_tools 의 함수**가 만든다 / the two controllers come from _tools
%       add_heading_loop   4주차의 P-D 와 Saturation      (W05 도 이 함수를 부른다)
%       add_speed_loop     3주차의 PI 와 back-calculation (W05 도 이 함수를 부른다)
%       그래서 5주차에서 같은 그림을 **블록 하나까지 그대로** 다시 보게 된다.
%       Week 5 calls the same two functions, so the diagrams are identical there.
%
%   한계 / the limit
%       전진력이 X_max 까지 갈 수 있으므로 선수각 루프의 Saturation 은 N_max 가
%       아니라 **N_speed** 를 든다 (5-7 절의 규칙을 그대로). 그러지 않으면 배분기가
%       낼 수 없는 회전수를 요구한다.
%       The heading Saturation holds N_speed, not N_max, because the surge force
%       can reach X_max; section 5-7 is where that rule is derived.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W04_0_setup');

m   = 'W04_J_both';
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','T_both', 'ReturnWorkspaceOutputs','off', ...
             'StopFcn','W04_J_plot;');

Y = 200;                                   % 선수각 줄 / the heading row
YU = Y + 260;                              % 속도 줄 / the speed row

%% 1) 명령 둘 — 계단으로 조금씩 / the two commands, in small steps
%     Repeating Sequence Stair 하나가 계단 하나를 cmd_hold 초씩 낸다. 값은 캔버스의
%     블록이 아니라 작업공간 벡터이므로, 명령을 바꾸는 것은 W04_0_setup 한 줄이다.
%     One Repeating Sequence Stair holds each value for cmd_hold seconds. The
%     values are a workspace vector, so changing the mission is one line of setup.
add_block('simulink/Sources/Repeating Sequence Stair', [m '/psi_d steps'], ...
          'OutValues','psi_d_steps', 'tsamp','cmd_hold', 'Position',[60 Y-25 120 Y+25]);
add_block('simulink/Math Operations/Gain', [m '/deg to rad'], 'Gain','pi/180', ...
          'Position',[200 Y-18 250 Y+18]);
route(m, 'psi_d steps', 1, 'deg to rad', 1, zeros(0,2));
goto_at(m, {'psi_d steps', 1}, [160 Y], 'up', 'psi_d_deg');
goto_at(m, {'deg to rad',  1}, [280 Y], 'up', 'psi_d');

add_block('simulink/Sources/Repeating Sequence Stair', [m '/u_d steps'], ...
          'OutValues','u_d_steps', 'tsamp','cmd_hold', 'Position',[60 YU-25 120 YU+25]);
goto_at(m, {'u_d steps', 1}, [160 YU], 'down', 'u_d');

%% 2) 제어기 둘 / the two controllers — 둘 다 _tools 의 함수가 만든다
add_heading_loop(m, [420 Y-60 620 Y+60], 'N_speed');
add_speed_loop(  m, [420 YU-60 620 YU+60], 'Kb_u');
feed(m, 'psi_d', 'heading autopilot', 1, 360);
feed(m, 'x',     'heading autopilot', 2, 380);
feed(m, 'u_d',   'speed loop',        1, 360);
feed(m, 'x',     'speed loop',        2, 380);
goto_at(m, {'heading autopilot', 1}, port_xy(m, 'heading autopilot', 'Outport', 1), 'up',   'N');
goto_at(m, {'speed loop',        1}, port_xy(m, 'speed loop',        'Outport', 1), 'down', 'X');

%% 3) 배분과 선체 / the allocation and the hull
%     5주차와 **같은 배분기**다: B 를 세우고 풀어 두 추력을 얻고, 프로펠러 곡선을
%     뒤집어 회전수로 바꾸고, 낼 수 있는 범위로 자른다.
%     The same allocator as Week 5: solve B for the two thrusts, invert the
%     propeller curve, clamp to what the propellers can do.
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position',[760 Y+70 860 Y+170]);
set_mlfcn([m '/allocation'], allocation_code(), 'n', '[2 1]');
mlfcn_params([m '/allocation'], {'y_pont','k_pos','k_neg','n_max','n_min'});
feed(m, 'N', 'allocation', 1, 700);
feed(m, 'X', 'allocation', 2, 720);

cfg = otter_config('base');
add_otter_plant(m, 'Otter', [960 Y+70 1060 Y+170], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
route(m, 'allocation', 1, 'Otter', 1, zeros(0,2));
goto_at(m, {'Otter', 1}, port_xy(m, 'Otter', 'Outport', 1), 'down', 'x');

%% 4) 보이는 것 / what is shown — Scope 둘과 로그 하나
%     로그는 [psi_d psi u_d u N X] 여섯 열이다. W04_J_plot 이 StopFcn 에서 그린다.
%     The log is six columns and W04_J_plot draws it from the StopFcn.
readouts(m, [1140 Y-40 1260 Y+120]);
tags = {'psi_d_deg','psi_deg','u_d','u','N','X'};
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','6', ...
          'Position',[1510 Y-60 1515 Y+200]);
for i = 1:numel(tags)
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [1410 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W04Jlog'], 'VariableName','W04Jlog', ...
          'SaveFormat','Structure With Time', 'Position',[1570 p(2)-15 1640 p(2)+15]);
route(m, 'log', 1, 'W04Jlog', 1, zeros(0,2));

%  Scope 이름에 '/' 를 쓸 수 없다 (m/s). 단위는 이름이 아니라 신호에 붙인다.
%  A block name cannot contain a slash, so the units stay out of it.
scope2(m, 'heading psi_d , psi', {'psi_d_deg','psi_deg'}, [1570 Y-200 1600 Y-170], 1410);
scope2(m, 'speed u_d , u',       {'u_d','u'}, [1570 Y+280 1600 Y+310], 1410);

note(m);
for b = find_system(m, 'SearchDepth',1, 'Regexp','on', 'BlockType','Goto|From')'
    set_param(b{1}, 'ShowName','off');
end
mss_style(m);
compact_layout(m, 60);                 % 빈 복도를 좁힌다 / narrow the empty corridors
straighten_lines(m);                   % 대각선 0 / no diagonal stretches (CLAUDE.md 5)
save_system(m, out);
print(['-s' m], '-dpng', '-r60', fullfile(here, 'img', [m '.png']));
for sb = {'heading autopilot','speed loop'}
    print(['-s' m '/' sb{1}], '-dpng', '-r70', ...
          fullfile(here, 'img', [m '_' strrep(sb{1},' ','_') '.png']));
end
n = check_overlaps(m);  nd = check_diagonals(m);
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d, diagonals: %d)\n', [m '.slx'], n, nd);
end

% =========================================================================
%  태그에서 블록의 입력으로 / from a tag into a block's input
function feed(m, tag, dst, port, x)
q = port_xy(m, dst, 'Inport', port);
from_at(m, tag, [x q(2)], ['From ' dst ' ' tag]);
route(m, ['From ' dst ' ' tag], 1, dst, port, zeros(0,2));
end

% =========================================================================
%  선체 상태에서 보여 줄 넷을 꺼낸다 / the four readouts taken from the state
function readouts(m, pos)
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], 'Position', pos);
set_mlfcn([m '/readouts'], { ...
'function [psi_deg, u] = readouts(x)'
'%#codegen'
'%READOUTS  로그와 Scope 가 쓰는 두 값 / the two values the log and the Scopes use.'
'%'
'%  선수각은 **도** 로, 그리고 (-180, 180] 로 감아서 낸다. 감지 않으면 선회가'
'%  누적되어 360, 720 처럼 커지고, 명령과 겹쳐 그릴 수 없다.'
'%  The heading is given in degrees and wrapped into (-180, 180]; unwrapped it'
'%  would accumulate past 360 and could not be drawn against its command.'
'psi_deg = atan2(sin(x(12)), cos(x(12))) * 180/pi;'
'u       = x(1);'
'end'}, 'psi_deg', '[1 1]');
feed(m, 'x', 'readouts', 1, pos(1)-110);
goto_at(m, {'readouts', 1}, port_xy(m, 'readouts', 'Outport', 1), 'up',   'psi_deg');
goto_at(m, {'readouts', 2}, port_xy(m, 'readouts', 'Outport', 2), 'down', 'u');
end

% =========================================================================
%  명령과 응답을 **한 Scope 에 겹쳐서** / command and response in one Scope
function scope2(m, name, tags, pos, x)
add_block('simulink/Signal Routing/Mux', [m '/' name ' mux'], 'Inputs','2', ...
          'Position',[pos(1)-60 pos(2)-25 pos(1)-55 pos(2)+25], 'ShowName','off');
for i = 1:2
    q = port_xy(m, [name ' mux'], 'Inport', i);
    from_at(m, tags{i}, [x q(2)], ['From ' name ' ' tags{i}]);
    route(m, ['From ' name ' ' tags{i}], 1, [name ' mux'], i, zeros(0,2));
end
add_block('simulink/Sinks/Scope', [m '/' name], 'Position', pos);
set_param([m '/' name], 'BackgroundColor', gnc_colour('measurement'));
route(m, [name ' mux'], 1, name, 1, zeros(0,2));
end

% =========================================================================
function C = allocation_code()
C = { ...
'function n = allocation(N, X, y_pont, k_pos, k_neg, n_max, n_min)'
'%#codegen'
'%ALLOCATION  전진력 X 와 요 모멘트 N 을 두 축의 회전수 n = [n_L; n_R] 로.'
'%            The surge force X and the yaw moment N to the two shaft speeds.'
'%  **두 입력 모두 제어기의 출력이다**: N 은 선수각 루프, X 는 속도 루프.'
'%  Both inputs are outputs of controllers: N from the heading loop, X from the'
'%  speed loop. In the other Week 4 models X was a constant.'
''
'% 1) 두 힘을 두 추력으로. 배치행렬 B 를 세우고 **풀면** 된다.'
'%    Solve B T = [X; N] rather than writing the two expressions out.'
'B = [1        1;              % 전진력  X = T_L + T_R        / surge force'
'     y_pont  -y_pont];        % 요 모멘트 N = y_pont(T_L-T_R) / yaw moment'
'T = B \ [X; N];               % 좌현, 우현 / port, starboard'
''
'% 2) 프로펠러 곡선 T = k n|n| 을 n 에 대해 푼다 (앞 k_pos, 뒤 k_neg).'
'%    Solve the propeller curve T = k n|n| for n (k_pos ahead, k_neg astern).'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        n(i) =  sqrt( T(i) / k_pos);'
'    else'
'        n(i) = -sqrt(-T(i) / k_neg);'
'    end'
'end'
''
'% 3) 프로펠러가 낼 수 있는 범위로 자른다 (otter.m 167-170 행이 안에서 이미 자른다).'
'%    Clamp to what the propellers can do; otter.m clamps internally too.'
'n(1) = min(max(n(1), n_min), n_max);'
'n(2) = min(max(n(2), n_min), n_max);'
'end'};
end

% =========================================================================
function note(m)
L = {'WEEK 4, SECTION J  -  BOTH INNER LOOPS AT ONCE', '', ...
     '    heading:  e = ssa(psi_d - psi) in rad,   N = Kp e - Kd r,   |N| <= N_speed', ...
     '    speed:    e = u_d - u,                   X = Kp_u e + I,    |X| <= X_max', ...
     '              I_dot = Ki_u e + Kb_u (X - X_raw)   the back-calculation of Week 3', ...
     '', ...
     '    The allocation takes BOTH of them: [X; N] -> two thrusts -> two shaft speeds.', ...
     '    N is limited to N_speed, not N_max, because X can now reach X_max (section 5-7).', ...
     '', ...
     '    Both commands are staircases from W04_0_setup: u_d_steps and psi_d_steps,', ...
     '    each value held for cmd_hold seconds. Change them and press Run.', ...
     '    The two Scopes show the command and the response together.'};
add_block('built-in/Note', [m '/note'], 'Position',[80 700], ...
          'Text', strjoin(L, newline), 'HorizontalAlignment','left', ...
          'BackgroundColor','cyan', 'FontSize','9');
end

% =========================================================================
function from_at(m, tag, at, name)
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
at = round(at);
g = ['Goto ' tag];
%  태그가 길면 블록을 넓힌다. 좁으면 Simulink 가 '-T-' 로 줄여 그려서 어느 신호인지
%  그림에서 읽을 수 없다 (psi_d_deg 가 그랬다).
%  A long tag needs a wider block: Simulink shrinks it to '-T-' otherwise, and the
%  diagram stops saying which signal it is.
w = max(50, 9*numel(tag) + 16);
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag',tag, ...
          'TagVisibility','local', 'Position', [at(1)+12 at(2)+dy-9 at(1)+12+w at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end
