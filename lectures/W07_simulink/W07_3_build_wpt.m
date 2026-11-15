%W07_3_BUILD_WPT  웨이포인트 추종 모델을 **코드로** 만든다. 배분은 법칙 4 하나다.
%                 Build the waypoint-following model from code; allocation is
%                 law 4 alone.
%
%   실행 / to run
%       cd lectures/W07_simulink
%       W07_3_build_wpt             % W07_wpt_los.slx 와 img/*.png 를 만든다
%       W07_0_setup                 % 값을 얹는다. 그 다음 Run 을 누른다
%
%   무엇을 만드는가 / what this builds
%       루프가 둘이다 — 바깥은 LOS 유도, 안은 서지 속도 제어와 선수각 제어.
%       The model has two loops: LOS guidance outside, surge-speed control and
%       heading control inside.
%
%       guidance        5주차의 LOS. 웨이포인트 열을 받아 선수각 명령 psi_d 와
%                       횡오차 y_e 를 내고, 마지막 점에 닿으면 gate 를 0 으로
%                       내린다 / the LOS of Week 5
%       speed loop      3주차의 PI. u_d x gate 를 받아 전진력 X 를 낸다
%       heading loop    4주차의 PD. psi_d 를 받아 요 모멘트 N 을 낸다
%       allocation      **법칙 4 하나**. 서보 한계와 추력 캡을 제약으로 들고
%                       풀어, 회전수 넷과 각 넷을 낸다
%       Otter USV       `otter_tilt4.m`. 깎인 n 과 delta 를 받고 실제로 가해진
%                       tau 를 둘째 출력으로 낸다
%       Measurements    로그 열다섯 열과 실시간 화면
%
%   왜 법칙 4 하나인가 / why one law and not four
%       Multiport Switch 는 **계산이 아니라 출력을 고른다** — 스위치를 두면 매
%       스텝마다 법칙 넷이 모두 풀린다. §7-8 … §7-11 의 비교 모델에서는 그것이
%       옳다 (네 답을 나란히 보려고 만든 모델이다). 닫힌 루프에서는 그 값을
%       치를 수 없고, 치를 이유도 없다 — §7-12 이 고른 하나로 돌린다. 법칙이
%       하나이므로 `add_allocation_tilt4` 는 스위치도 `law` 포트도 만들지 않는다.
%       A Multiport Switch selects an OUTPUT, not a computation: with it in
%       place all four laws are solved every step. That is right for the
%       comparison model of 7-8 to 7-11 and wrong here. Given a single law the
%       allocator builds neither switch nor `law` inport.
%
%   신호는 태그로 다닌다 / signals travel by tag
%       소비되면서 기록되는 신호는 **Goto/From** 으로 다닌다 (standing order
%       §15-71). psi_d 는 선수각 루프가 먹고 로그에도 들어가므로 선 하나와
%       분기가 아니라 태그 하나다. 그래서 유도와 제어기 사이의 통로가 비어 있고,
%       `check_overlaps` 가 0 으로 끝난다.
%       A signal that is both consumed and logged travels by tag, so the
%       corridor between the guidance and the controllers stays empty.
%
%   See also W07_0_SETUP, W07_WPT_RUN, W07_PLOT_WPT, W07WPT_ANIMATE,
%            ADD_GUIDANCE, ADD_SPEED_LOOP, ADD_HEADING_LOOP,
%            ADD_ALLOCATION_TILT4, ADD_OTTER_PLANT, ADD_MEASUREMENT.

m    = 'W07_wpt_los';
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
             'StartTime', '0', 'StopTime', 'T_wpt');

Y = 340;

% ---- guidance: 5주차의 LOS / the LOS of Week 5 ---------------------------
%  법칙 하나(LOS)만 싣는다. 적분 법칙이 없으므로 상태는 둘 — 다리 번호와
%  임무 종료 시각 / one law only, so the state is two components wide
[~, GIN] = add_guidance(m, [300 Y-30 520 Y+30], 2);

%  GIN 의 첫 칸은 x(되먹임), 마지막 칸은 state(기억) 이고 둘은 Constant 가 아니다.
%  그 사이가 캔버스에 세워지는 Constant 열이다 / what lies between becomes the
%  column of Constants on the canvas
q = port_xy(m, 'guidance', 'Inport', 1);
from_at(m, 'x', [150 q(2)], 'From x g');
route(m, 'From x g', 1, 'guidance', 1, zeros(0,2));
for i = 2:numel(GIN)-1
    q = port_xy(m, 'guidance', 'Inport', i);
    add_block('simulink/Sources/Constant', [m '/' GIN{i}], 'Value', GIN{i}, ...
              'Position', [150 q(2)-13 230 q(2)+13]);
    route(m, GIN{i}, 1, 'guidance', i, zeros(0,2));
end

% ---- 유도가 기억하는 것 / what the guidance remembers --------------------
%  persistent 이 아니라 Unit Delay 다 — 되먹임이 **선으로** 보여야 한다
%  a Unit Delay, not a persistent variable, so the memory is a visible line
ylane = Y + 320;
add_block('simulink/Discrete/Unit Delay', [m '/1 step'], ...
          'InitialCondition', '[1;0]', 'SampleTime', 'h', 'Orientation', 'left', ...
          'Position', [420 ylane-20 480 ylane+20]);
a = port_xy(m, 'guidance', 'Outport', 7);
b = port_xy(m, '1 step',   'Inport',  1);     % 왼쪽을 보므로 오른쪽 변 / right edge
add_line(m, [a; 660 a(2); 660 ylane; b]);
c = port_xy(m, '1 step',   'Outport', 1);
d = port_xy(m, 'guidance', 'Inport',  numel(GIN));
add_line(m, [c; 260 ylane; 260 d(2); d]);

% ---- 유도의 출력은 전부 태그로 / every guidance output leaves as a tag ----
TAG = {'psi_d', 'y_e', 'aux', 'wp', 'gate', 'stop'};
for i = 1:numel(TAG)
    p = port_xy(m, 'guidance', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' TAG{i}], ...
              'GotoTag', TAG{i}, 'TagVisibility', 'local', 'ShowName', 'off', ...
              'Position', [560 p(2)-9 620 p(2)+9]);
    route(m, 'guidance', i, ['Goto ' TAG{i}], 1, zeros(0,2));
end

% ---- 선수각 명령을 도로 / the heading command in degrees -----------------
%  로그의 여섯째 열(psi)은 도이므로 명령도 도로 기록한다. 그래야 둘을 바로
%  겹쳐 그릴 수 있다 / column 6 of the log is in degrees, so the command is too
from_at(m, 'psi_d', [640 760], 'From psi_d g');
add_block('simulink/Math Operations/Gain', [m '/psi_d deg'], ...
          'Gain', '180/pi', 'Position', [760 742 810 778]);
route(m, 'From psi_d g', 1, 'psi_d deg', 1, zeros(0,2));
add_block('simulink/Signal Routing/Goto', [m '/Goto psi_d_deg'], ...
          'GotoTag', 'psi_d_deg', 'TagVisibility', 'local', 'ShowName', 'off', ...
          'Position', [860 751 920 769]);
route(m, 'psi_d deg', 1, 'Goto psi_d_deg', 1, zeros(0,2));

% ---- 속도 루프 (3주차) / the speed loop of Week 3 ------------------------
%  명령 속도는 **gate 를 지나** 들어간다. 마지막 웨이포인트에 닿으면 유도가
%  gate 를 0 으로 내리고, 곱이 명령을 0 으로 만들어 배가 선다. 곱셈을 캔버스에
%  두는 이유는 그것이 임무의 끝이라는 사실이 그림에 보여야 하기 때문이다
%  The commanded speed passes through the gate, and the multiplication sits on
%  the canvas because the end of the mission should be visible there
add_speed_loop(m, [900 100 1100 220]);
add_block('simulink/Math Operations/Product', [m '/u_d x gate'], 'Inputs', '2', ...
          'Position', [770 120 800 160]);
add_block('simulink/Sources/Constant', [m '/u_d'], 'Value', 'u_d', ...
          'Position', [640 120 720 146]);
route(m, 'u_d', 1, 'u_d x gate', 1, zeros(0,2));
from_at(m, 'gate', [640 240], 'From gate sp');
q = port_xy(m, 'u_d x gate', 'Inport', 2);
route(m, 'From gate sp', 1, 'u_d x gate', 2, [745 240; 745 q(2)]);
%  곱의 결과도 태그로 보낸다 — 속도 루프가 먹고 로그에도 들어가므로 §15-71 이
%  태그를 요구하고, 그래야 긴 선 하나가 사라진다 / the product also leaves by
%  tag: the speed loop consumes it and the log records it
goto_at(m, {'u_d x gate', 1}, port_xy(m, 'u_d x gate', 'Outport', 1), 'up', 'u_d_eff');
q = port_xy(m, 'speed loop', 'Inport', 1);
from_at(m, 'u_d_eff', [810 q(2)], 'From u_d_eff');
route(m, 'From u_d_eff', 1, 'speed loop', 1, zeros(0,2));

q = port_xy(m, 'speed loop', 'Inport', 2);
from_at(m, 'x', [810 q(2)], 'From x sp');
route(m, 'From x sp', 1, 'speed loop', 2, zeros(0,2));

% ---- 선수각 오토파일럿 (4주차) / the heading autopilot of Week 4 ---------
%  한계는 `N_lim` 이다. 네 틸팅 추진기가 낼 수 있는 모멘트는 전진력 100 N 을
%  들고도 405 N m 이므로 (§7-12), 이 한계는 설계가 고른 값이고 구동장치가
%  강제한 값이 아니다 / the limit is a design choice, not a physical ceiling
add_heading_loop(m, [900 450 1100 570], 'N_lim');
q = port_xy(m, 'heading autopilot', 'Inport', 1);
from_at(m, 'psi_d', [810 q(2)], 'From psi_d hd');
route(m, 'From psi_d hd', 1, 'heading autopilot', 1, zeros(0,2));
q = port_xy(m, 'heading autopilot', 'Inport', 2);
from_at(m, 'x', [810 q(2)], 'From x hd');
route(m, 'From x hd', 1, 'heading autopilot', 2, zeros(0,2));

% ---- 요구한 힘 / the demanded force -------------------------------------
%  횡력은 요구하지 않는다. 웨이포인트 추종은 선수를 돌려 경로로 가므로 횡방향
%  명령이 없고, 그 자리가 0 이라는 것이 도면에 Constant 하나로 보인다. 위치
%  제어 모델(W07_4)에서는 바로 그 자리가 살아난다
%  No sway force is asked for here: the path is followed by turning the bow.
%  The zero is a Constant on the canvas so that the absence can be seen, and
%  in the pose model that same input comes alive
add_block('simulink/Sources/Constant', [m '/zero Y'], 'Value', '0', ...
          'Position', [960 327 1030 353]);
add_block('simulink/Signal Routing/Mux', [m '/tau mux'], ...
          'Inputs', '3', 'DisplayOption', 'bar', 'Position', [1160 300 1165 380]);
elbow(m, 'speed loop',        1, 'tau mux', 1, 1125);
route(m, 'zero Y',            1, 'tau mux', 2, zeros(0,2));
elbow(m, 'heading autopilot', 1, 'tau mux', 3, 1140);
goto_at(m, {'tau mux', 1}, port_xy(m, 'tau mux', 'Outport', 1), 'up', 'tau_cmd');

% ---- 배분과 플랜트 / allocation and plant --------------------------------
%  법칙이 하나이므로 배분기의 입력은 `tau d` 뿐이다 / with one law the
%  allocator has a single inport
add_allocation_tilt4(m, [1300 180 1470 500], 4, 'W07wpt_act');
route(m, 'tau mux', 1, 'allocation', 1, zeros(0,2));

add_otter_plant(m, 'Otter USV', [1550 259 1680 421], cfg);
lane_line(m, 'allocation', 1, 'Otter USV', 1, 1510);
lane_line(m, 'allocation', 2, 'Otter USV', 2, 1525);

%  상태와 실제로 가해진 힘은 둘 다 태그로 떠난다 / both plant outputs leave
%  as tags: the state feeds three places, the applied force only the log
goto_at(m, {'Otter USV', 1}, port_xy(m, 'Otter USV', 'Outport', 1), 'up',   'x');
goto_at(m, {'Otter USV', 2}, port_xy(m, 'Otter USV', 'Outport', 2), 'down', 'tau_act');

% ---- 임무가 끝나면 멈춘다 / stop when the mission is over ----------------
from_at(m, 'stop', [640 840], 'From stop');
add_block('simulink/Sinks/Stop Simulation', [m '/mission over'], ...
          'Position', [760 825 790 855]);
route(m, 'From stop', 1, 'mission over', 1, zeros(0,2));

% ---- 계측 / measurement --------------------------------------------------
%  열 스물셋 / twenty-three columns
%    1 u   2 v   3 r   4 N   5 E   6 psi [deg]
%    7 psi_d [deg]   8 u_d_eff   9 y_e
%   10-12 tau_cmd [X Y N]        13-15 tau_act [X Y N]
%   16-19 n [rad/s]              한계를 지난 뒤 / after clipping
%   20-23 delta [rad]            한계를 지난 뒤 / after clipping
%  마지막 여덟 열은 배분기가 전역 태그로 내보낸 것이다. 장부는 Run 이 끝난 뒤에야
%  읽히므로, 실시간 화면은 이 여덟 열을 한계선과 함께 그린다 / the last eight
%  columns arrive from the allocator's global tags. The record is readable only
%  after the run ends, so the live view draws these eight against their limits.
extra = {'psi_d_deg', 'u_d_eff', 'y_e', 'tau_cmd', 'tau_act', 'n_act', 'delta_act'};
add_measurement(m, [1900 Y-351 2060 Y+351], 'W07wpt', extra, ...
    struct('logFeed', true, ...
           'weekName', 'W07 wpt  this week:  psi_d, u_d gated, y_e, tau asked and applied, n, delta'));
tags = [{'x'} extra];
for i = 1:numel(tags)
    q  = port_xy(m, 'Measurements', 'Inport', i);
    nm = ['From meas ' tags{i}];
    from_at(m, tags{i}, [1800 q(2)], nm);
    route(m, nm, 1, 'Measurements', i, zeros(0,2));
end

% ---- 캔버스의 설명 / the note on the canvas ------------------------------
note = strjoin({ ...
    'Waypoint following with one allocation law.', ...
    '', ...
    'Outer loop   LOS guidance turns the waypoint list into a heading command', ...
    '             psi_d and a cross-track error y_e.  At the last waypoint it', ...
    '             drops gate to zero, which zeroes the speed command and then', ...
    '             stops the run.', ...
    'Inner loops  surge-speed PI  ->  X        (Week 3)', ...
    '             heading PD      ->  N        (Week 4)', ...
    'Allocation   law 4 of section 7-11: servo limits and the thruster cap as', ...
    '             constraints.  It returns four speeds and four angles already', ...
    '             inside their limits.', ...
    'Plant        otter_tilt4 applies the clipped commands and reports the', ...
    '             force it actually produced on its second output.', ...
    '', ...
    'No sway force is commanded: the path is followed by turning the bow.', ...
    'Signals travel by tag, so the corridor between guidance and control is', ...
    'empty and every logged signal is read where it is used.'}, newline);
add_block('built-in/Note', [m '/note'], 'Position', [150 900 1200 1050], ...
          'Text', note, 'HorizontalAlignment', 'left', ...
          'BackgroundColor', 'lightBlue', 'FontSize', 12);

% ---- 실행 설정 / run settings -------------------------------------------
set_param(m, 'StopFcn', 'W07_plot_wpt;');
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
print(['-s' m],                       '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
print(['-s' m '/guidance'],           '-dpng', '-r45', fullfile(here, 'img', [m '_guid.png']));
print(['-s' m '/speed loop'],         '-dpng', '-r45', fullfile(here, 'img', [m '_speed.png']));
print(['-s' m '/heading autopilot'],  '-dpng', '-r45', fullfile(here, 'img', [m '_head.png']));
print(['-s' m '/allocation'],         '-dpng', '-r45', fullfile(here, 'img', [m '_alloc.png']));
print(['-s' m '/Measurements'],       '-dpng', '-r45', fullfile(here, 'img', [m '_meas.png']));
close_system(m, 0);

%  디스크의 파일로 다시 센다 — save_system 이 가지선의 점을 다시 쓴다 (§15-31)
%  count again from the file on disk, because save_system rewrites branch points
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
