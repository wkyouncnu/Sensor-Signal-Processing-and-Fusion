%W07_4_BUILD_POSE  위치·선수각 제어 모델을 **코드로** 만든다. 배분은 법칙 4 하나다.
%                  Build the pose-control model from code; allocation is law 4
%                  alone.
%
%   실행 / to run
%       cd lectures/W07_simulink
%       W07_4_build_pose            % W07_pose_dp.slx 와 img/*.png 를 만든다
%       W07_0_setup                 % 값을 얹는다. 그 다음 Run 을 누른다
%
%   무엇을 만드는가 / what this builds
%       (0 m, 0 m, 0 deg) 에서 (10 m, 10 m, 45 deg) 로 가서 **그 자리에 머문다.**
%       Go from (0 m, 0 m, 0 deg) to (10 m, 10 m, 45 deg) and hold there.
%
%       position loop   위치 오차를 선체 좌표로 돌려 속도 명령 nu_d = [u_d; v_d]
%                       를 낸다. 6주차와 같은 블록이다 / the same block as Week 6
%       velocity loop   그 속도 명령을 전진력 X 와 횡력 Y 로 바꾼다. 안쪽에
%                       3주차의 PI 둘이 나란히 있다
%       heading loop    4주차의 PD. psi_set 을 받아 요 모멘트 N 을 낸다
%       allocation      법칙 4 하나
%       Otter USV       `otter_tilt4.m`
%       Measurements    로그 열일곱 열과 실시간 화면
%
%   6주차와 무엇이 다른가 / what differs from Week 6
%       6주차의 선체는 횡방향으로 **선수 추진기 하나**밖에 없어서 횡력이 귀했고,
%       그래서 임무 상태기계가 "먼저 돌고, 그 다음 옆으로" 를 시켰다. 네 틸팅
%       추진기는 횡력을 순수하게 295 N 까지 낸다 (§7-12 의 측정). 그러므로 이
%       주차의 위치 제어는 상태기계가 없다 — 세 자유도를 **동시에** 명령하고,
%       배분기가 그것을 나눠 준다. gate 는 상수 1 로 켜 둔다.
%       Week 6 had a single bow thruster, so sway was scarce and a mission
%       state machine ordered turn-then-translate. Four tilting thrusters
%       deliver up to 295 N of pure sway, so here all three degrees of freedom
%       are commanded at once and the gate is simply held open.
%
%   신호는 태그로 다닌다 / signals travel by tag
%       소비되면서 기록되는 신호는 Goto/From 으로 다닌다 (standing order
%       §15-71). 명령 상수도 태그를 지나는데, 로그가 그 값을 적어야 하기
%       때문이다 / even the command Constants pass through a tag, because the
%       log has to record them
%
%   See also W07_0_SETUP, W07_POSE_RUN, W07_PLOT_POSE, W07POSE_ANIMATE,
%            ADD_POSITION_LOOP, ADD_VELOCITY_LOOP, ADD_HEADING_LOOP,
%            ADD_ALLOCATION_TILT4, ADD_OTTER_PLANT, ADD_MEASUREMENT.

m    = 'W07_pose_dp';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

cfg = otter_config('quad_tilt');
out = fullfile(here, [m '.slx']);

bdclose(m);
if isfile(out), delete(out); end
new_system(m);

set_param(m, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', 'h', ...
             'StartTime', '0', 'StopTime', 'T_pose');

Y = 340;

% ---- 명령 / the commands -------------------------------------------------
%  상수 하나에 태그 하나다. 명령은 캔버스의 Constant 이고 (CLAUDE.md §5), 그
%  값이 로그에 들어가야 하므로 태그를 지난다
%  one Constant, one tag: the command is on the canvas and the log reads it
add_block('simulink/Sources/Constant', [m '/p_d'], 'Value', 'p_d', ...
          'Position', [150 252 230 278]);
add_block('simulink/Signal Routing/Goto', [m '/Goto p_d'], 'GotoTag', 'p_d', ...
          'TagVisibility', 'local', 'ShowName', 'off', 'Position', [260 256 320 274]);
route(m, 'p_d', 1, 'Goto p_d', 1, zeros(0,2));

add_block('simulink/Sources/Constant', [m '/psi_set'], 'Value', 'psi_set', ...
          'Position', [150 570 230 596]);
add_block('simulink/Signal Routing/Goto', [m '/Goto psi_d'], 'GotoTag', 'psi_d', ...
          'TagVisibility', 'local', 'ShowName', 'off', 'Position', [260 574 320 592]);
route(m, 'psi_set', 1, 'Goto psi_d', 1, zeros(0,2));

% ---- 선수각 명령을 도로 / the heading command in degrees -----------------
%  로그의 여섯째 열(psi)은 도이므로 명령도 도로 적는다
from_at(m, 'psi_d', [360 760], 'From psi_d g');
add_block('simulink/Math Operations/Gain', [m '/psi_d deg'], ...
          'Gain', '180/pi', 'Position', [480 742 530 778]);
route(m, 'From psi_d g', 1, 'psi_d deg', 1, zeros(0,2));
add_block('simulink/Signal Routing/Goto', [m '/Goto psi_d_deg'], ...
          'GotoTag', 'psi_d_deg', 'TagVisibility', 'local', 'ShowName', 'off', ...
          'Position', [580 751 640 769]);
route(m, 'psi_d deg', 1, 'Goto psi_d_deg', 1, zeros(0,2));

% ---- 위치 루프 (6주차) / the position loop of Week 6 ---------------------
%  오차를 선체 좌표로 돌려서 속도 명령을 낸다. `_ned` 변형이 아니라 이것을
%  쓰는 이유는, 뒤따르는 속도 루프가 선체 좌표의 u 와 v 를 제어하기 때문이다
%  the body-axis variant, because the velocity loop downstream controls u and v
add_position_loop(m, [470 190 630 490]);
q = port_xy(m, 'position loop', 'Inport', 1);
from_at(m, 'p_d', [360 q(2)], 'From p_d');
route(m, 'From p_d', 1, 'position loop', 1, zeros(0,2));
q = port_xy(m, 'position loop', 'Inport', 2);
from_at(m, 'x', [360 q(2)], 'From x pos');
route(m, 'From x pos', 1, 'position loop', 2, zeros(0,2));
q = port_xy(m, 'position loop', 'Inport', 3);
add_block('simulink/Sources/Constant', [m '/gate on'], 'Value', '1', ...
          'Position', [355 q(2)-13 435 q(2)+13]);
route(m, 'gate on', 1, 'position loop', 3, zeros(0,2));

goto_at(m, {'position loop', 1}, port_xy(m, 'position loop', 'Outport', 1), ...
        'up',   'nu_d');
goto_at(m, {'position loop', 2}, port_xy(m, 'position loop', 'Outport', 2), ...
        'down', 'dist');

% ---- 속도 루프 (3주차 둘) / the velocity loop, two Week-3 PIs -----------
add_velocity_loop(m, [860 250 1020 430]);
q = port_xy(m, 'velocity loop', 'Inport', 1);
from_at(m, 'nu_d', [750 q(2)], 'From nu_d');
route(m, 'From nu_d', 1, 'velocity loop', 1, zeros(0,2));
q = port_xy(m, 'velocity loop', 'Inport', 2);
from_at(m, 'x', [750 q(2)], 'From x vel');
route(m, 'From x vel', 1, 'velocity loop', 2, zeros(0,2));

% ---- 선수각 오토파일럿 (4주차) / the heading autopilot of Week 4 ---------
add_heading_loop(m, [860 540 1020 660], 'N_lim');
q = port_xy(m, 'heading autopilot', 'Inport', 1);
from_at(m, 'psi_d', [750 q(2)], 'From psi_d hd');
route(m, 'From psi_d hd', 1, 'heading autopilot', 1, zeros(0,2));
q = port_xy(m, 'heading autopilot', 'Inport', 2);
from_at(m, 'x', [750 q(2)], 'From x hd');
route(m, 'From x hd', 1, 'heading autopilot', 2, zeros(0,2));

% ---- 요구한 힘 / the demanded force -------------------------------------
%  속도 루프가 [X; Y] 둘을 함께 내므로 Mux 는 입력 둘이다. 웨이포인트 모델의
%  `zero Y` 상수가 서 있던 자리가 여기서는 살아 있는 신호다
%  the velocity loop delivers X and Y together, so the Mux takes two inputs:
%  where the waypoint model had a zero Constant, this model has a live signal
add_block('simulink/Signal Routing/Mux', [m '/tau mux'], ...
          'Inputs', '2', 'DisplayOption', 'bar', 'Position', [1120 300 1125 380]);
elbow(m, 'velocity loop',     1, 'tau mux', 1, 1070);
elbow(m, 'heading autopilot', 1, 'tau mux', 2, 1085);
goto_at(m, {'tau mux', 1}, port_xy(m, 'tau mux', 'Outport', 1), 'up', 'tau_cmd');

% ---- 배분과 플랜트 / allocation and plant --------------------------------
add_allocation_tilt4(m, [1260 180 1430 500], 4, 'W07pose_act');
route(m, 'tau mux', 1, 'allocation', 1, zeros(0,2));

add_otter_plant(m, 'Otter USV', [1510 259 1640 421], cfg);
lane_line(m, 'allocation', 1, 'Otter USV', 1, 1470);
lane_line(m, 'allocation', 2, 'Otter USV', 2, 1485);

goto_at(m, {'Otter USV', 1}, port_xy(m, 'Otter USV', 'Outport', 1), 'up',   'x');
goto_at(m, {'Otter USV', 2}, port_xy(m, 'Otter USV', 'Outport', 2), 'down', 'tau_act');

% ---- 계측 / measurement --------------------------------------------------
%  열 스물다섯 / twenty-five columns
%    1 u   2 v   3 r   4 N   5 E   6 psi [deg]
%    7-8 p_d [N_d E_d]   9 psi_d [deg]   10-11 nu_d [u_d v_d]
%   12-14 tau_cmd [X Y N]               15-17 tau_act [X Y N]
%   18-21 n [rad/s]              한계를 지난 뒤 / after clipping
%   22-25 delta [rad]            한계를 지난 뒤 / after clipping
%  마지막 여덟 열은 배분기가 전역 태그로 내보낸 것이다. 장부는 Run 이 끝난 뒤에야
%  읽히므로, 실시간 화면은 이 여덟 열을 한계선과 함께 그린다 / the last eight
%  columns arrive from the allocator's global tags. The record is readable only
%  after the run ends, so the live view draws these eight against their limits.
extra = {'p_d', 'psi_d_deg', 'nu_d', 'tau_cmd', 'tau_act', 'n_act', 'delta_act'};
add_measurement(m, [1860 Y-351 2020 Y+351], 'W07pose', extra, ...
    struct('logFeed', true, ...
           'weekName', 'W07 pose  this week:  p_d, psi_d, nu_d, tau asked and applied, n, delta'));
tags = [{'x'} extra];
for i = 1:numel(tags)
    q  = port_xy(m, 'Measurements', 'Inport', i);
    nm = ['From meas ' tags{i}];
    from_at(m, tags{i}, [1760 q(2)], nm);
    route(m, nm, 1, 'Measurements', i, zeros(0,2));
end

% ---- 캔버스의 설명 / the note on the canvas ------------------------------
note = strjoin({ ...
    'Pose control with one allocation law: hold a position and a heading.', ...
    '', ...
    'Commands     p_d = [N_d; E_d] metres and psi_set radians, both Constants', ...
    '             on the canvas.  The run starts at the origin with zero', ...
    '             heading, so the demand is the whole manoeuvre.', ...
    'Outer loop   position loop turns the position error into a body-axis', ...
    '             velocity command nu_d = [u_d; v_d], saturated at u_lim and', ...
    '             v_lim.  The gate is held open: there is no mission state', ...
    '             machine this week.', ...
    'Inner loops  velocity loop  ->  X and Y   (two Week-3 PIs side by side)', ...
    '             heading PD     ->  N         (Week 4)', ...
    'Allocation   law 4 of section 7-11.  All three degrees of freedom are', ...
    '             commanded at once, which Week 6 could not afford: its single', ...
    '             bow thruster made sway scarce.  Four tilting thrusters', ...
    '             deliver up to 295 N of pure sway.', ...
    '', ...
    'Signals travel by tag, so each logged signal is read where it is used.'}, newline);
add_block('built-in/Note', [m '/note'], 'Position', [150 900 1200 1050], ...
          'Text', note, 'HorizontalAlignment', 'left', ...
          'BackgroundColor', 'lightBlue', 'FontSize', 12);

% ---- 실행 설정 / run settings -------------------------------------------
set_param(m, 'StopFcn', 'W07_plot_pose;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');
set_param(m, 'InitFcn', [ ...
    'addpath(fullfile(fileparts(fileparts(fileparts(' ...
        'get_param(bdroot, ''FileName'')))), ''_tools''), ' ...
        'fileparts(get_param(bdroot, ''FileName''))); ' ...
    'run_alone(''W07'', bdroot);']);

% ---- 마무리 / finish -----------------------------------------------------
mss_style(m);
compact_layout(m, 60);
straighten_lines(m);
save_system(m, out);

if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end
print(['-s' m],                      '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
print(['-s' m '/position loop'],     '-dpng', '-r45', fullfile(here, 'img', [m '_pos.png']));
print(['-s' m '/velocity loop'],     '-dpng', '-r45', fullfile(here, 'img', [m '_vel.png']));
print(['-s' m '/heading autopilot'], '-dpng', '-r45', fullfile(here, 'img', [m '_head.png']));
print(['-s' m '/allocation'],        '-dpng', '-r45', fullfile(here, 'img', [m '_alloc.png']));
print(['-s' m '/Measurements'],      '-dpng', '-r45', fullfile(here, 'img', [m '_meas.png']));
close_system(m, 0);

%  디스크의 파일로 다시 센다 (§15-31) / count again from the file on disk
load_system(out);
nov = check_overlaps(m);
ndg = check_diagonals(m);
fprintf('\n  %s   overlaps %d   diagonals %d\n\n', m, nov, ndg);
close_system(m, 0);

% =========================================================================
function from_at(m, tag, at, name)
%FROM_AT  태그를 주어진 높이에 세운다 / place a From at a given height
if nargin < 4, name = ['From ' tag]; end
at = round(at);
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag', tag, ...
          'ShowName', 'off', 'Position', [at(1) at(2)-10 at(1)+75 at(2)+10]);
end

% =========================================================================
function goto_at(m, src, at, dirn, tag)
%GOTO_AT  출력 바로 옆에 태그를 세우고 짧은 선으로 잇는다
%         place a Goto beside an outport and join it with a short line
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
at = round(at);
g  = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag', tag, ...
          'ShowName', 'off', 'TagVisibility', 'local', ...
          'Position', [at(1)+12 at(2)+dy-9 at(1)+72 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

% =========================================================================
function h = route(sys, src, sp, dst, dp, via)
%ROUTE  포트 높이를 읽어 선을 긋는다 / draw a line from read port heights
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
h = add_line(sys, [a; via; b]);
end

% =========================================================================
function elbow(sys, src, sp, dst, dp, x)
%ELBOW  통로 하나를 써서 꺾는다 / one vertical lane, two corners
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; x a(2); x b(2); b]);
end
