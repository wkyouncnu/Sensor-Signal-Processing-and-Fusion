function W05_1_build_guidance(which)
%W05_1_BUILD_GUIDANCE  5주차 실습 모델 일곱 개를 코드로 만든다 — 절 하나에 모델 하나.
%                      Generate the seven Week 5 models, one model per section.
%
%   실행 / to run
%       W05_1_build_guidance                 일곱 개 전부 / all seven
%       W05_1_build_guidance('W05_D_LOS')    하나만 / one of them
%
%   모델 / the models
%       W05_C_atan2       다음 웨이포인트를 곧장 겨냥한다 / aim straight at the next waypoint
%       W05_D_LOS         LOS: 경로 위 Delta 앞의 점을 겨냥한다 / aim at a point Delta ahead on the path
%       W05_E_switching   LOS, 다섯 웨이포인트 임무 / LOS on the five-waypoint mission
%       W05_F_ILOS        ILOS: LOS + 적분 (조류에 맞선다) / LOS plus an integral, against a current
%       W05_F_LOS         LOS, 조류 속에서 남는 오차 / the offset LOS leaves in a current
%       W05_G_tuning      ILOS, 임무 + 조류, 튜닝 순서 / ILOS, mission and current, the tuning order
%       W05_H_speed_path  ILOS + **3주차 속도 루프**. 전진력이 상수가 아니다
%                         ILOS with the Week 3 speed loop: the surge force is no longer a constant
%
%   모든 모델이 같은 모양이다 / every model has the same shape
%       guidance -> heading autopilot -> allocation -> Otter
%
%   **제어기는 서브시스템이고, 안은 시뮬링크 블록이다** (사용자 지시, 2026-09-29).
%   두 번 누르면 합산점·삼각함수·곱셈·적분기·포화가 그대로 보인다 — 코드가 아니라
%   그림으로 읽는다. 명령과 게인은 전부 **캔버스의 Constant** 이고 값은 작업공간에서
%   온다: Constant 의 Value 가 변수 이름이다. 바꾸고 Run 만 누르면 된다.
%     heading autopilot   psi_d, x   ->  N          (모든 모델 / every model)
%     speed loop          x, u_d     ->  X          (H 모델만 / H only)
%   MATLAB Function 으로 남은 것은 **유도 법칙과 배분** 둘뿐이다. 강의가 그 둘의
%   코드를 줄 단위로 인용하기 때문이다 (5-3·5-5·5-7 절).
%   The controllers are subsystems drawn in Simulink blocks: double-click one and
%   the sums, trigonometry, products, integrator and saturation are all there to
%   be read as a diagram. Every command and gain is a Constant block whose value
%   is a workspace variable's name. Only the guidance law and the allocator are
%   still MATLAB Functions, because the lecture quotes those two line by line.
%
%   오른쪽에 넷 / four things on the right
%       Scope      횡방향 오차 · 명령 선수각과 선수각 · 웨이포인트 번호
%       XY Graph   항적 (동쪽 대 북쪽) / the track, east against north
%       Display    지금 몇 번째 다리인가 / the active leg, as a number
%       Animate    실시간 화면. animate = 0 이면 아무것도 하지 않는다 (5-7 절)
%                  the live view; with animate = 0 it does nothing
%   끝나면 StopFcn 이 W05_plot 을 불러 절 스크립트와 같은 그림을 그린다.
%   pace = 1 이면 현실 시간에 맞춰 돈다 (InitFcn 이 매 Run 마다 읽는다).
%   When a run ends the StopFcn calls W05_plot; pace = 1 runs it at wall-clock
%   speed, and the InitFcn reads that on every Run.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W05_0_setup');

%  실험 하나에 모델 하나 (standing-orders §15-15). W05_F_LOS 는 W05_D_LOS 와 같은
%  LOS 법칙이지만 실험 5-5a 의 것이다 — 조류 속에서 LOS 가 남기는 오차를 재는 데 쓴다.
%  One model per experiment: W05_F_LOS carries the same LOS law as W05_D_LOS and
%  belongs to Experiment 5-5a, where the offset a current leaves is measured.
M = struct( ...
  'name',  {'W05_C_atan2','W05_D_LOS','W05_E_switching','W05_F_LOS','W05_F_ILOS','W05_G_tuning','W05_H_speed_path'}, ...
  'law',   {'atan2','LOS','LOS','LOS','ILOS','ILOS','ILOS'}, ...
  'speed', {false, false, false, false, false, false, true}, ...
  'title', {'AIM AT THE NEXT WAYPOINT', 'LINE OF SIGHT, AND THE LOOK-AHEAD DISTANCE', ...
            'WAYPOINT SWITCHING ON A MISSION', 'LOS IN A CURRENT: THE OFFSET IT LEAVES', ...
            'A CURRENT, AND THE INTEGRAL (ILOS)', 'THE TUNING ORDER', ...
            'BOTH LOOPS AT ONCE: THE SPEED OF WEEK 3 AND THE PATH OF WEEK 5'}, ...
  'sec',   {'C','D','E','5-5a','F','G','H'});
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

%% 유도 / guidance
%  웨이포인트 목록과 튜닝 값들은 **캔버스에 보이는 Constant 블록**으로 들어간다
%  (사용자 지시, 2026-09-29). 파라미터로 숨기면 포트가 사라져서, 이 주차가 고르는
%  값 — Delta, R_switch, kappa — 이 어디로 들어가는지 그림만 보고는 알 수 없다.
%  값 자체는 여전히 작업공간에서 온다: Constant 의 Value 가 변수 이름이다.
%  The waypoint list and the tuning values enter as Constant blocks that can be
%  seen. As hidden parameters they had no ports, so the canvas did not show where
%  the numbers this week chooses go in. The values still come from the workspace:
%  each Constant's Value is the variable's name.
GIN = {'WP_N','WP_E','Delta','R_switch','kappa'};
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/guidance'], ...
          'Position', [300 Y-160 520 Y+160]);
set_mlfcn([m '/guidance'], guidance_code(o.law), 'psi_d', '[1 1]', 'h');
mlfcn_params([m '/guidance'], {'h'});     % 고정 스텝만 숨긴다 / only the step stays hidden
q = port_xy(m, 'guidance', 'Inport', 1);
from_at(m, 'x', [150 q(2)]);
route(m, 'From x', 1, 'guidance', 1, zeros(0,2));
for i = 1:numel(GIN)
    q = port_xy(m, 'guidance', 'Inport', i+1);
    add_block('simulink/Sources/Constant', [m '/' GIN{i}], 'Value', GIN{i}, ...
              'Position', [150 q(2)-13 230 q(2)+13]);
    route(m, GIN{i}, 1, 'guidance', i+1, zeros(0,2));
end

%% 선수각 오토파일럿 / heading autopilot
%  **서브시스템이고, 안은 시뮬링크 블록이다** (사용자 지시, 2026-09-29). 4주차
%  모델과 같은 블록·같은 이름이다 — Fcn 'ssa' 하나, Gain 'Kp' 와 'Kd',
%  Saturation 'moment limit'. 두 번 누르면 4주차의 식이 그림으로 보인다.
%  빼는 것은 게인이 아니라 **합산점**이다 (build_autopilot 의 주석 참고).
%  A subsystem of Simulink blocks, with the same blocks and the same names as the
%  Week 4 model: one Fcn 'ssa', the gains Kp and Kd, and a Saturation. The D term
%  is subtracted at the summing junction rather than carried as a negative gain.
build_autopilot(m, [680 Y-60 880 Y+60], o);
p1 = port_xy(m, 'guidance', 'Outport', 1);  a1 = port_xy(m, 'heading autopilot', 'Inport', 1);
route(m, 'guidance', 1, 'heading autopilot', 1, [600 p1(2); 600 a1(2)]);
a2 = port_xy(m, 'heading autopilot', 'Inport', 2);
add_block('simulink/Signal Routing/From', [m '/From x '], 'GotoTag','x', 'ShowName','off', ...
          'Position', [615 a2(2)-10 655 a2(2)+10]);
route(m, 'From x ', 1, 'heading autopilot', 2, zeros(0,2));
goto_at(m, {'guidance', 1}, [550 p1(2)], 'up', 'psi_d');
for i = 2:4                                   % y_e, aux, wp -> Goto 태그 / to Goto tags
    p = port_xy(m, 'guidance', 'Outport', i);
    tag = {'','y_e','aux','wp'};  tag = tag{i};
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [540 p(2)-9 585 p(2)+9]);
    route(m, 'guidance', i, ['Goto ' tag], 1, zeros(0,2));
end

%% 속도 루프 (3주차) / the speed loop of Week 3 — H 모델에만
%  다른 모델은 전진력이 상수 X_ff 다. 여기서만 그것이 제어기의 출력이 된다.
%  Everywhere else the surge force is the constant X_ff; here alone it is the
%  output of a controller.
%  오토파일럿과 같다 — 서브시스템이고 안은 3주차와 같은 한 줄이며, **명령 u_d 만**
%  밖의 Constant 로 들어온다 (사용자 지시, 2026-09-29).
%  Like the autopilot: a subsystem holding the same single row as Week 3, with only
%  the command u_d arriving from a Constant outside it.
if o.speed
    build_speed_loop(m, [680 Y+150 880 Y+270]);
    q = port_xy(m, 'speed loop', 'Inport', 2);
    add_block('simulink/Signal Routing/From', [m '/From x sp'], 'GotoTag','x', 'ShowName','off', ...
              'Position', [600 q(2)-10 645 q(2)+10]);
    route(m, 'From x sp', 1, 'speed loop', 2, zeros(0,2));
    %  명령 속도는 **밖의 Constant** 다 (사용자 지시, 2026-09-29: "u_d 도 외부로 나오게").
    %  게인은 서브시스템 안의 Gain 블록이 작업공간에서 읽는다 - MSS 데모가 Delta 와
    %  R_switch 를 캔버스에 두고 게인은 Gain 블록에 두는 것과 같다.
    %  The commanded speed is a Constant outside; the gains are read from the
    %  workspace by Gain blocks inside, as in the MSS demonstration model.
    q = port_xy(m, 'speed loop', 'Inport', 1);
    add_block('simulink/Sources/Constant', [m '/u_d'], 'Value','u_d', ...
              'Position', [575 q(2)-13 655 q(2)+13]);
    route(m, 'u_d', 1, 'speed loop', 1, zeros(0,2));
    goto_at(m, {'speed loop', 1}, port_xy(m, 'speed loop', 'Outport', 1), 'down', 'X');
end

%% 배분 / allocation
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [930 Y-30 1110 Y+30]);
set_mlfcn([m '/allocation'], allocation_code(o), 'n', '[2 1]');
%  배분기가 받는 것은 둘이다 - 요 모멘트 N 과 **전진력 X**. 선체 상수 셋만 숨은
%  파라미터이고, 두 힘은 **캔버스에서 보이는 입력**이다 (사용자 지시, 2026-09-29).
%  The allocator takes two things: the yaw moment N and the surge force X. Only
%  the three hull constants are parameters; both forces are visible inputs.
mlfcn_params([m '/allocation'], {'y_pont','k_pos','k_neg','n_max','n_min'});
p = port_xy(m, 'heading autopilot', 'Outport', 1);  q = port_xy(m, 'allocation', 'Inport', 1);
set_param([m '/allocation'], 'Position', get_param([m '/allocation'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
route(m, 'heading autopilot', 1, 'allocation', 1, zeros(0,2));
goto_at(m, {'heading autopilot', 1}, [p(1)+20 p(2)], 'up', 'Nmom');
q = port_xy(m, 'allocation', 'Inport', 2);
if o.speed
    %  속도 루프가 낸 힘 / the force the speed loop asked for
    add_block('simulink/Signal Routing/From', [m '/From X'], 'GotoTag','X', 'ShowName','off', ...
              'Position', [870 q(2)-10 915 q(2)+10]);
    route(m, 'From X', 1, 'allocation', 2, zeros(0,2));
else
    %  속도 루프가 없는 모델에서는 전진력이 상수다. 그 상수도 캔버스에 둔다 -
    %  숨은 파라미터로 두면 5-7 절에서 무엇이 바뀌었는지 보이지 않는다.
    %  Without a speed loop the surge force is a constant, and the constant is put
    %  on the canvas too: hidden, it would not show what 5-7 changes.
    add_block('simulink/Sources/Constant', [m '/X_ff'], 'Value','X_ff', ...
              'Position', [845 q(2)-13 915 q(2)+13]);
    route(m, 'X_ff', 1, 'allocation', 2, zeros(0,2));
    goto_at(m, {'X_ff', 1}, [q(1)-20 q(2)], 'down', 'X');
end

%% Otter
cfg = otter_config('base');
add_otter_plant(m, 'Otter', [1180 Y-30 1280 Y+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
p = port_xy(m, 'allocation', 'Outport', 1);  q = port_xy(m, 'Otter', 'Inport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
goto_at(m, {'allocation', 1}, port_xy(m, 'allocation', 'Outport', 1), 'down', 'n');
p = port_xy(m, 'Otter', 'Outport', 1);
goto_at(m, {'Otter', 1}, [p(1)+30 p(2)], 'up', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [p(1)+70 p(2)-8 p(1)+86 p(2)+8]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

measure(m, 1430, o);
note(m, o);
%  Run 만 눌러도 절 스크립트와 **같은 그림**이 뜬다 (CLAUDE.md §5, 사용자 지시)
%  Pressing Run alone draws the same figure the section script draws.
set_param(m, 'StopFcn', 'W05_plot;');
%  현실 시간으로 돌릴 것인가 — 선택사항 / real time, optionally.
%  InitFcn 이 매 Run 마다 pace 를 읽으므로, 작업공간에서 pace 를 바꾸고 Run 만
%  누르면 된다. 모델을 다시 만들 필요가 없다.
%  The InitFcn reads pace on every Run, so changing it in the workspace and
%  pressing Run is enough; the model does not have to be rebuilt.
set_param(m, 'InitFcn', ['if base_var(''pace'', 0) > 0, ' ...
    'set_param(bdroot, ''EnablePacing'', ''on'', ''PacingRate'', ''1''); else, ' ...
    'set_param(bdroot, ''EnablePacing'', ''off''); end']);
mss_style(m);
save_system(m, out);
%  -r45 로 뽑는다. 5주차 캔버스는 Animate 와 로그 열 때문에 폭이 넓어서 -r60 에서
%  2346 px 가 되고, vault_check 7 절의 2000 px 한계를 넘는다.
%  Exported at -r45: the Week 5 canvas is wide because of the Animate and log
%  columns, and at -r60 it comes to 2346 px, past vault_check's 2000 px limit.
print(['-s' m], '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
%  최상위만 보면 부족하다 — 제어기가 서브시스템이 된 뒤로 선의 대부분이 그 안에 있다.
%  서브시스템도 PNG 로 뽑아 눈으로 보고, 겹침도 함께 센다 (CLAUDE.md §5).
%  Checking the top level alone is not enough now that most of the lines live
%  inside the controllers. Each subsystem is exported and counted as well.
%  check_overlaps 는 서브시스템까지 스스로 들어간다. 여기서 도는 것은 **그림을 뽑기
%  위해서**다 — 제어기가 서브시스템이 된 뒤로 볼 것의 대부분이 그 안에 있다 (CLAUDE.md §5).
%  check_overlaps already descends into subsystems; this loop is for the pictures,
%  since most of what there is to look at now lives inside the controllers.
n = check_overlaps(m);
for sb = {'heading autopilot','speed loop','moment limit'}
    if isempty(find_system(m, 'SearchDepth',1, 'Name',sb{1})), continue; end
    %  `print('-s<path>')` 는 창을 **열지 않고** 뽑는다. open_system 으로 먼저 열면
    %  일곱 모델을 연달아 지을 때 창이 쌓여 세션이 멈춘다 — 실제로 멈췄다.
    %  print('-s<path>') exports without opening a window. Opening each subsystem
    %  first piles up windows and hangs the session over seven models; it did.
    print(['-s' m '/' sb{1}], '-dpng', '-r70', ...
          fullfile(here, 'img', [m '_' strrep(sb{1},' ','_') '.png']));
end
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
%  기록과 표시 / logging and display
%    readouts (MATLAB Function): psi_d, x -> 도 단위 선수각 둘, 북, 동 / two headings in degrees, north, east
%    Scope 위: 횡방향 오차 y_e,  아래: [psi_d psi] [deg];  XY Graph: 동쪽(가로) 대 북쪽(세로)
%    Scope top: cross-track error; bottom: [psi_d psi] [deg]; XY Graph: east (x) against north (y)
%    W05log = [y_e psi_d psi N E aux wp]  -> W05_read
function measure(m, X, o)
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], ...
          'Position', [X+80 60 X+260 180]);
set_mlfcn([m '/readouts'], readouts_code(), 'psi_d_deg', '[1 1]');
q1 = port_xy(m, 'readouts', 'Inport', 1);  q2 = port_xy(m, 'readouts', 'Inport', 2);
from_at(m, 'psi_d', [X q1(2)], 'From psi_d');
from_at(m, 'x', [X q2(2)], 'From x r');
route(m, 'From psi_d', 1, 'readouts', 1, zeros(0,2));
route(m, 'From x r', 1, 'readouts', 2, zeros(0,2));
out = {'psi_d_deg','psi_deg','N','E','u'};
for i = 1:5
    p = port_xy(m, 'readouts', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' out{i}], 'GotoTag',out{i}, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [X+290 p(2)-9 X+370 p(2)+9]);
    route(m, 'readouts', i, ['Goto ' out{i}], 1, zeros(0,2));
end

%  Scope: 위 y_e, 가운데 [psi_d psi], 아래 **웨이포인트 번호** / top y_e, middle the
%  two headings, bottom the WAYPOINT INDEX — 실행 중에 1, 2, 3 으로 한 칸씩 올라간다
%  (사용자 지시, 2026-09-29). 계단이 올라가는 순간이 §5-4 의 전환 판정이 참이 된 순간이다.
%  The bottom trace steps 1, 2, 3 as the mission runs; each step is the instant
%  §5-4's switching test became true.
S = X + 450;
add_block('simulink/Signal Routing/Mux', [m '/heading pair'], 'Inputs','2', 'Position', [S+120 110 S+125 170]);
add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','3', 'Position', [S+180 30 S+230 230]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[3 1]', 'ShowLegend','on'); catch, end
s1 = port_xy(m, 'Scope', 'Inport', 1);
from_at(m, 'y_e', [S s1(2)], 'From y_e');
route(m, 'From y_e', 1, 'Scope', 1, zeros(0,2));
h1 = port_xy(m, 'heading pair', 'Inport', 1);  h2 = port_xy(m, 'heading pair', 'Inport', 2);
from_at(m, 'psi_d_deg', [S h1(2)], 'From psi_d_deg');
from_at(m, 'psi_deg', [S h2(2)], 'From psi_deg');
l1 = route(m, 'From psi_d_deg', 1, 'heading pair', 1, zeros(0,2));
l2 = route(m, 'From psi_deg', 1, 'heading pair', 2, zeros(0,2));
set_param(l1, 'Name','psi_d');  set_param(l2, 'Name','psi');
p = port_xy(m, 'heading pair', 'Outport', 1);  s2 = port_xy(m, 'Scope', 'Inport', 2);
route(m, 'heading pair', 1, 'Scope', 2, [S+150 p(2); S+150 s2(2)]);
s3 = port_xy(m, 'Scope', 'Inport', 3);
from_at(m, 'wp', [S s3(2)], 'From wp sc');
route(m, 'From wp sc', 1, 'Scope', 3, zeros(0,2));
set_param([m '/Scope'], 'Open','on');

%  XY Graph: 항적 / the track
add_block('simulink/Sinks/XY Graph', [m '/track'], 'Position', [S+180 260 S+230 320]);
set_param([m '/track'], 'xmin','-20', 'xmax','140', 'ymin','-20', 'ymax','140');
t1 = port_xy(m, 'track', 'Inport', 1);  t2 = port_xy(m, 'track', 'Inport', 2);
from_at(m, 'E', [S+60 t1(2)], 'From E');
from_at(m, 'N', [S+60 t2(2)], 'From N');
route(m, 'From E', 1, 'track', 1, zeros(0,2));
route(m, 'From N', 1, 'track', 2, zeros(0,2));

%  Display: 지금 몇 번 웨이포인트인가 — 숫자가 실행 중에 1 -> 2 -> 3 으로 바뀐다
%  Display: which waypoint is active. The number changes as the mission runs.
add_block('simulink/Sinks/Display', [m '/waypoint k'], 'Position', [S+180 355 S+250 385]);
q = port_xy(m, 'waypoint k', 'Inport', 1);
from_at(m, 'wp', [S+60 q(2)], 'From wp d');
route(m, 'From wp d', 1, 'waypoint k', 1, zeros(0,2));

%  실시간 화면 / the live view — 도는 동안 보이는 것 (사용자 지시, 2026-09-29)
%    왼쪽 경로·웨이포인트·궤적·선체,  오른쪽 y_e · u 와 명령 · n_L 과 n_R · 다리 번호
%    left: the path, the waypoints, the track and the hull; right: the four traces
%  블록을 빼서 끄지 않는다. animate = 0 이면 이 블록이 아무것도 하지 않는다.
%  It is not switched off by removing the block: with animate = 0 it does nothing.
A = S + 630;  yA = 40;
ANM = {'N','E','psi_deg','y_e','u'};          % 태그에서 오는 것 / these come from tags
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/Animate'], ...
          'Position', [A+120 yA A+270 yA+480]);
set_mlfcn([m '/Animate'], animate_code(), 'ok', '[1 1]');
for i = 1:numel(ANM)
    q = port_xy(m, 'Animate', 'Inport', i);
    from_at(m, ANM{i}, [A q(2)], ['From an ' ANM{i}]);
    route(m, ['From an ' ANM{i}], 1, 'Animate', i, zeros(0,2));
end
%  u_d: 속도 루프가 있는 모델만 값을 준다. 없으면 NaN 이고, 화면은 그 선을 그리지
%  않는다 — 따라가지도 않는 점선을 그리는 것은 거짓말이기 때문이다.
%  u_d is a number only where there is a speed loop; elsewhere NaN, and the view
%  does not draw the line. An unfollowed dashed line would be a lie.
q = port_xy(m, 'Animate', 'Inport', 6);
add_block('simulink/Sources/Constant', [m '/u_d shown'], ...
          'Value', ternary(o.speed, 'u_d', 'NaN'), 'Position', [A q(2)-13 A+80 q(2)+13]);
route(m, 'u_d shown', 1, 'Animate', 6, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 7);
from_at(m, 'n', [A q(2)], 'From an n');
route(m, 'From an n', 1, 'Animate', 7, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 8);
from_at(m, 'wp', [A q(2)], 'From an wp');
route(m, 'From an wp', 1, 'Animate', 8, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 9);
add_block('simulink/Sources/Clock', [m '/clock'], 'Position', [A+40 q(2)-10 A+60 q(2)+10]);
route(m, 'clock', 1, 'Animate', 9, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 10);
add_block('simulink/Sources/Constant', [m '/live view'], 'Value','animate', ...
          'Position', [A q(2)-13 A+80 q(2)+13]);
route(m, 'live view', 1, 'Animate', 10, zeros(0,2));
p = port_xy(m, 'Animate', 'Outport', 1);
add_block('simulink/Sinks/Terminator', [m '/anim end'], ...
          'Position', [A+310 p(2)-8 A+326 p(2)+8]);
route(m, 'Animate', 1, 'anim end', 1, zeros(0,2));

%  로그 / the log
%  9 요 모멘트, 10 전진력, 11 축 회전수 둘 - 5-7 절의 배분 수식을 수치로 확인한다
%  9 the yaw moment, 10 the surge force, 11 the two shaft speeds: what 5-7 checks
%  the allocation equations against. Column 11 is a 2-vector, so the log has 12.
tags = {'y_e','psi_d_deg','psi_deg','N','E','aux','wp','u','Nmom','X','n'};
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','11', 'Position', [S+400 40 S+405 480]);
for i = 1:11
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [S+300 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W05log'], 'VariableName','W05log', ...
          'SaveFormat','Structure With Time', 'Position', [S+450 p(2)-15 S+520 p(2)+15]);
route(m, 'log', 1, 'W05log', 1, zeros(0,2));
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end

% =========================================================================
%  제어기 셋 — 전부 **시뮬링크 블록**으로 그린 서브시스템이다 (사용자 지시, 2026-09-29:
%  "제어기는 subsystem 으로 만들고 ... 제어기 내부는 시뮬링크로 ... W05 주차 모두 동일해").
%  MATLAB Function 은 유도 법칙과 배분에만 남는다 — 그 둘은 강의가 코드를 줄 단위로
%  인용하는 곳이고, 나머지는 그림으로 읽는 편이 낫다.
%
%  The three controllers, each a subsystem drawn in Simulink blocks. The MATLAB
%  Function blocks that remain are the guidance law and the allocator, which are
%  the two the lecture quotes line by line.
% =========================================================================

function build_autopilot(m, pos, o)
%BUILD_AUTOPILOT  4주차의 선수각 오토파일럿을 블록으로 / the Week 4 autopilot, in blocks.
%
%     e = ssa(psi_d - psi),   ssa(u) = atan2(sin(u), cos(u))
%     N = Kp e - Kd r,        |N| <= 한계 / the limit
%
%   **4주차 모델과 같은 블록, 같은 이름이다** (W04_1_build_heading 참조): 오차를 감는
%   것은 Fcn 블록 하나 'ssa', 게인은 Gain 블록의 값이 변수 이름, 자르는 것은 평범한
%   Saturation 이다. 학생이 4주차에서 본 그림을 그대로 다시 본다.
%   The same blocks with the same names as Week 4 (see W04_1_build_heading): one
%   Fcn block wraps the error, the gains are Gain blocks whose value is a variable
%   name, and the clamp is an ordinary Saturation.
%
%   D 항이 오차의 미분이 아니라 **측정한 요각속도**인 것이 4주차의 결론이다. 그래서
%   psi_d 가 계단으로 뛰어도 N 이 튀지 않는다 - 미분 블록 자체가 이 그림에 없다.
%   The D term is the measured yaw rate, not the derivative of the error, which is
%   why a step in psi_d produces no kick: there is no derivative block here at all.
%
%   한계는 그 모델이 요구할 수 있는 **가장 큰** 전진력에서 계산해 둔 상수다 (5-7 절).
%   전진력이 상수인 모델은 N_max, 속도 루프가 붙은 모델은 더 작은 N_speed.
%   The limit was worked out at the largest surge force that model can ask for:
%   N_max where the force is constant, N_speed where a speed loop can push harder.
s = add_subsys(m, 'heading autopilot', pos, {'psi_d','x'}, {'N'}, gnc_colour('controller'));
set_param([s '/psi_d'], 'Position', [ 60  90  90 110]);
set_param([s '/x'],     'Position', [ 60 190  90 210]);
set_param([s '/N'],     'Position', [700 120 730 140]);

%  x 에서 필요한 둘만 꺼낸다 / take the two states this law uses
sel(s, 'psi = x(12)', 12, [140 182 240 218]);
sel(s, 'r = x(6)',     6, [140 262 240 298]);
route(s, 'x', 1, 'psi = x(12)', 1, zeros(0,2));
route(s, 'x', 1, 'r = x(6)',    1, [115 200; 115 280]);

%  1) 오차, 그리고 (-pi, pi] 로 감기 / the error, wrapped into (-pi, pi]
add_sum(s, 'e', '+-', [300 100]);
route(s, 'psi_d',       1, 'e', 1, zeros(0,2));
route(s, 'psi = x(12)', 1, 'e', 2, [300 200]);
add_block('simulink/User-Defined Functions/Fcn', [s '/ssa'], ...
          'Expr','atan2(sin(u), cos(u))', 'Position', [360 82 440 118]);
route(s, 'e', 1, 'ssa', 1, zeros(0,2));

%  2) P 는 오차에, D 는 요각속도에 / P on the error, D on the yaw rate
gain(s, 'Kp',       'Kp',  [480  82 540 118]);
%  게인은 `Kd` 이고 **빼는 것은 합산점**이다 (사용자 지시, 2026-09-29). 게인에 -Kd 를
%  넣으면 부호가 블록 이름·블록 값·합산점 셋에 흩어져, 그림을 보고 부호를 세어야 한다.
%  한 군데에만 두면 "Kp e 에서 Kd r 을 뺀다" 가 그림 그대로 읽힌다.
%  4주차 4-3e 절만 게인 쪽에 부호를 둔다 — 거기서는 **부호 자체가 실험의 주제**라
%  'minus Kd' 와 'plus Kd' 를 나란히 놓고 고르기 때문이다.
%  The gain is Kd and the subtraction is at the summing junction. With -Kd in the
%  gain the sign is spread over the block name, the block value and the junction,
%  and the reader has to count them. Week 4 section 4-3e is the one place that
%  keeps the sign in the gain, because there the sign is the experiment.
gain(s, 'Kd', 'Kd', [480 262 540 298]);
route(s, 'ssa',      1, 'Kp', 1, zeros(0,2));
route(s, 'r = x(6)', 1, 'Kd', 1, zeros(0,2));
add_sum(s, 'N raw', '+-', [580 100]);
route(s, 'Kp', 1, 'N raw', 1, zeros(0,2));
route(s, 'Kd', 1, 'N raw', 2, [580 280]);

%  3) 두 프로펠러가 낼 수 있는 만큼으로 자른다 / limit to what the propellers give
lim = ternary(o.speed, 'N_speed', 'N_max');
add_block('simulink/Discontinuities/Saturation', [s '/moment limit'], ...
          'UpperLimit', lim, 'LowerLimit', ['-' lim], 'Position', [620 82 670 118]);
route(s, 'N raw',        1, 'moment limit', 1, zeros(0,2));
route(s, 'moment limit', 1, 'N', 1, [690 100; 690 130]);
end

% =========================================================================
function build_speed_loop(m, pos)
%BUILD_SPEED_LOOP  3주차의 속도 루프를 블록으로 / the Week 3 speed loop, in blocks.
%
%     e = u_d - u
%     X_raw = Kp_u e + I,        I' = Ki_u e + Kb (X - X_raw)
%     X     = sat(X_raw),        |X| <= X_max
%
%   **3주차 모델과 같은 블록, 같은 이름, 같은 게인이다** (W03_1_build_speed 참조).
%   합산점 `e`, 게인 `Kp_u` 와 `Ki_u`, **연속 적분기** `I`, 합산점 `u`, `Saturation`
%   `thrust limit`, 그리고 되감기 게인 `Kb`. 다른 것은 명령 u_d 가 밖에서 들어온다는 것뿐.
%   The same blocks, names and gains as Week 3: the error junction, Kp_u and Ki_u,
%   a continuous Integrator, the addition, a Saturation, and the back-calculation
%   gain Kb. The only change is that u_d arrives from outside.
%
%   적분기는 **연속**이다 (사용자 지시, 2026-09-29). 이산 적분기를 쓰면 제어기가
%   솔버와 다른 시간축에서 돌아 모델이 두 개의 시간을 갖게 된다 - 이 강의의 모델은
%   전부 연속시간 플랜트에 연속시간 제어기다.
%   The integrator is continuous: a discrete one would put the controller on a
%   different time base from the plant, and every model in this course is a
%   continuous plant with a continuous controller.
%
%   안티와인드업 / the anti-windup
%       **back-calculation** 이다 (3주차 F 절). 포화가 잘라 낸 양 X - X_raw 를 Kb 배
%       하여 적분기 입력에 되돌린다. 한계에 걸려 있는 동안 그 항이 음수라 적분이
%       스스로 물러나고, 오차의 부호가 바뀌기 전에 풀린다.
%       Kb = 0 이면 안티와인드업이 없는 것이다 - 두 값으로 돌려 비교할 수 있다.
%       Back-calculation, as in Week 3 section F: the amount the saturation removed,
%       X - X_raw, is fed back through Kb into the integrator's input. While the
%       limit is active that term is negative, so the integral backs off by itself
%       instead of waiting for the error to change sign. Kb = 0 switches it off.
s = add_subsys(m, 'speed loop', pos, {'u_d','x'}, {'X'}, gnc_colour('controller'));
set_param([s '/u_d'], 'Position', [ 60 190  90 210]);
set_param([s '/x'],   'Position', [ 60 290  90 310]);
set_param([s '/X'],   'Position', [860 190 890 210]);

sel(s, 'u = x(1)', 1, [140 282 240 318]);
route(s, 'x', 1, 'u = x(1)', 1, zeros(0,2));

%  1) 속도 오차. 명령이 왼쪽, 측정이 아래에서 - MSS 데모의 되먹임 합산점 모양이다.
%     The command on the left edge and the measurement from below, the shape a
%     feedback junction has in the MSS demonstration models.
add_sum(s, 'e', '+-', [300 200]);
route(s, 'u_d',       1, 'e', 1, zeros(0,2));
route(s, 'u = x(1)',  1, 'e', 2, [300 300]);

%  2) P 와 I / the two terms
gain(s, 'Kp_u', 'Kp_u', [380 182 440 218]);
gain(s, 'Ki_u', 'Ki_u', [380 302 440 338]);
route(s, 'e', 1, 'Kp_u', 1, zeros(0,2));
route(s, 'e', 1, 'Ki_u', 1, [350 200; 350 320]);
add_sum(s, 'into I', '++', [500 320]);
add_block('simulink/Continuous/Integrator', [s '/I'], ...
          'InitialCondition','0', 'Position', [560 302 600 338]);
route(s, 'Ki_u',   1, 'into I', 1, zeros(0,2));
route(s, 'into I', 1, 'I', 1, zeros(0,2));

%  3) 더하고 자른다 / add them and clamp
add_sum(s, 'X raw', '++', [660 200]);
route(s, 'Kp_u', 1, 'X raw', 1, zeros(0,2));
route(s, 'I',    1, 'X raw', 2, [660 320]);
add_block('simulink/Discontinuities/Saturation', [s '/thrust limit'], ...
          'UpperLimit','X_max', 'LowerLimit','-X_max', 'Position', [710 182 760 218]);
route(s, 'X raw',        1, 'thrust limit', 1, zeros(0,2));
route(s, 'thrust limit', 1, 'X', 1, zeros(0,2));

%  4) 안티와인드업: 잘려 나간 만큼을 적분기로 되돌린다 (3주차 F 절과 같은 배선)
%     The anti-windup: what the saturation removed, returned to the integrator.
%     뺄셈을 **두 입력 바로 아래**에 둔다 (사용자 수정, 2026-09-29). 처음에는 합산점을
%     왼쪽에 두고 포화 출력을 가로질러 끌어왔더니 긴 가로선 둘이 도면을 덮었다. 지금은
%     X raw 와 X 가 각자 **바로 아래로 떨어져** 만나고, 돌아가는 선은 Kb 하나뿐이다.
%     The subtraction sits directly below the two signals it takes. Placed to the
%     left it needed two long horizontal runs across the diagram; now each signal
%     drops straight down and only the Kb line travels back.
add_sum(s, 'X - X raw', '-+', [740 440]);
gain(s, 'Kb', 'Kb', [820 522 870 558]);
set_param([s '/Kb'], 'Orientation','left');
route(s, 'X raw',        1, 'X - X raw', 1, [690 200; 690 440]);
route(s, 'thrust limit', 1, 'X - X raw', 2, [800 200; 800 500; 740 500]);
route(s, 'X - X raw',    1, 'Kb',        1, [880 440; 880 540]);
route(s, 'Kb',           1, 'into I',    2, [500 540]);
for nm = {'e','into I','X raw','X - X raw'}
    set_param([s '/' nm{1}], 'NamePlacement','alternate');
end
end

% -------------------------------------------------------------------------
%  작은 블록 헬퍼들 / small block helpers
function sel(s, name, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], 'InputPortWidth','12', ...
          'IndexOptions','Index vector (dialog)', 'Indices', num2str(idx), 'Position', pos);
end

function gain(s, name, val, pos)
add_block('simulink/Math Operations/Gain', [s '/' name], 'Gain', val, 'Position', pos);
end


% =========================================================================
function C = animate_code()
C = { ...
'function ok = Animate(N, E, psi_deg, y_e, u, u_d, n, wp, t, en)'
'%#codegen'
'%ANIMATE  도는 동안의 실시간 화면 / the live view, while the model runs.'
'%'
'%  MATLAB Function 블록은 그림을 그릴 수 없다. 그래서 그리는 함수를 extrinsic 으로'
'%  선언한다 — Simulink 가 코드를 생성하지 않고 평범한 MATLAB 을 부른다.'
'%  A MATLAB Function block cannot plot, so the drawing function is declared'
'%  extrinsic: Simulink calls plain MATLAB instead of generating code for it.'
'%'
'%  en = animate (작업공간). 0 이면 이 블록은 아무것도 하지 않는다.'
'%  en is the workspace variable animate; at 0 this block does nothing.'
'coder.extrinsic(''W05_animate'');'
'ok = 1;'
'if en > 0.5'
'    W05_animate(N, E, psi_deg, y_e, u, u_d, n, wp, t);'
'end'
'end'};
end

% =========================================================================
function C = readouts_code()
C = { ...
'function [psi_d_deg, psi_deg, N, E, u] = readouts(psi_d, x)'
'%#codegen'
'%READOUTS  Scope 와 XY Graph 에 보낼 값을 꺼낸다. 제어에는 쓰지 않는다.'
'%          Pick out what the Scope and the XY Graph show; not used for control.'
''
'% 1) 명령 선수각을 도로 / the commanded heading in degrees'
'psi_d_deg = psi_d * 180/pi;'
''
'% 2) 선수각은 x(12). 여러 번 돌면 360 도를 넘으므로 (-180, 180] 로 감아 psi_d 와 같은 범위로.'
'%    The heading is x(12); after turns it passes 360 deg, so it is wrapped into'
'%    (-180, 180], the range of psi_d.'
'psi_deg = atan2(sin(x(12)), cos(x(12))) * 180/pi;'
''
'% 3) 위치: 북 x(7), 동 x(8) / position: north x(7), east x(8)'
'N = x(7);  E = x(8);'
''
'% 4) 전진속도 x(1). 대부분의 모델에서는 X_ff 가 정한 값이 그대로 나오고,'
'%    §5-7 의 W05_H_speed_path 에서만 속도 루프가 이것을 붙든다.'
'%    Surge speed, state 1. In most models it is whatever X_ff produces; only in'
'%    W05_H_speed_path of §5-7 is it held by a controller.'
'u = x(1);'
'end'};
end

% =========================================================================
%  MATLAB Function 코드 / the code of the MATLAB Function blocks
function C = guidance_code(law)
head = { ...
'function [psi_d, y_e, aux, wp] = guidance(x, WP_N, WP_E, Delta, R_switch, kappa, h)'
'%#codegen'
'%GUIDANCE  웨이포인트 목록과 배의 위치에서 명령 선수각 psi_d 를 만든다.'
'%          Make the commanded heading psi_d from the waypoint list and the position.'
'%'
'%   입력 x 는 Otter 의 12 상태 (위치 N = x(7), E = x(8)). 나머지는 작업공간 변수.'
'%   The input x is the Otter''s 12 states (position N = x(7), E = x(8));'
'%   the rest are workspace variables (W05_0_setup).'
'%'
'%   출력 / outputs'
'%     psi_d  명령 선수각 [rad] -> 선수각 오토파일럿 / commanded heading -> the autopilot'
'%     y_e    횡방향 오차 [m], 경로 오른쪽이 + / cross-track error, right of the path +'
'%     aux    ILOS 의 적분 상태 (다른 법칙은 0) / the ILOS integral (0 for other laws)'
'%     wp     지금 따라가는 다리 번호 / the leg being followed'
''
'% 0) 기억하는 값: 지금 다리 k, 적분 y_int. 블록이 가지고 있다가 실행마다 처음으로 돌아간다.'
'%    Remembered values: the leg k and the integral y_int. The block owns them,'
'%    and they start afresh on every run.'
'persistent k y_int'
'if isempty(k), k = 1; y_int = 0; end'
'N = x(7);  E = x(8);'
'n = numel(WP_N);'
''
'% 1) 지금 다리: 웨이포인트 k 에서 k+1 로. 그 방향이 경로 각 pi_p 다.'
'%    The active leg runs from waypoint k to k+1; its direction is the path angle pi_p.'
'kn = min(k+1, n);'
'Nk = WP_N(k);   Ek = WP_E(k);'
'Nn = WP_N(kn);  En = WP_E(kn);'
'pi_p = atan2(En - Ek, Nn - Nk);'
''
'% 2) 배의 위치를 경로 좌표로 돌린다: x_e = 다리를 따라 간 거리, y_e = 다리에서 옆으로 벗어난 거리.'
'%    Rotate the position into path coordinates: x_e = distance along the leg,'
'%    y_e = distance off it, to the side.'
'dN = N - Nk;  dE = E - Ek;'
'x_e =  dN*cos(pi_p) + dE*sin(pi_p);'
'y_e = -dN*sin(pi_p) + dE*cos(pi_p);'
''
'% 3) 다리 끝까지 R_switch 보다 적게 남으면 다음 다리로 (MSS 와 같은 판정).'
'%    With less than R_switch left to the end of the leg, move to the next leg'
'%    (the same test as MSS).'
'd = sqrt((Nn - Nk)^2 + (En - Ek)^2);'
'if (d - x_e) < R_switch && k < n-1'
'    k = k + 1;'
'end'
'wp = k;'
'aux = y_int;'
''};
switch law
    case 'atan2'
        body = { ...
'% 4) 법칙: 다음 웨이포인트를 곧장 겨냥한다. 점까지의 방향이지 선까지가 아니다.'
'%    The law: aim straight at the next waypoint. It points at a POINT, not at the LINE.'
'psi_d = atan2(En - E, Nn - N);'
'end'};
    case 'LOS'
        body = { ...
'% 4) 법칙 LOS: 경로 위에서 Delta 만큼 앞의 점을 겨냥한다.'
'%        psi_d = pi_p - atan(y_e / Delta)'
'%    pi_p 는 "경로와 나란히", atan 은 "벗어난 만큼 경로 쪽으로 기울여라".'
'%    y_e 가 작으면 atan(y_e/Delta) ~ y_e/Delta: 횡방향 오차에 대한 P 제어기, Kp = 1/Delta.'
'%    The law LOS: aim at the point Delta ahead on the path.'
'%    pi_p says "line up with the path"; the atan says "lean towards it by how'
'%    far off you are". For small y_e, atan(y_e/Delta) ~ y_e/Delta: a P'
'%    controller on the cross-track error with Kp = 1/Delta.'
'psi_d = pi_p - atan(y_e / Delta);'
'end'};
    case 'ILOS'
        body = { ...
'% 4) 법칙 ILOS: LOS 에 적분을 더한다 — 횡방향 오차에 대한 PI 제어기.'
'%        psi_d = pi_p - atan(y_e/Delta + (kappa/Delta) y_int)'
'%    조류가 배를 계속 밀면 LOS 는 오차를 남긴다 (P 가 남기는 오차와 같다). 적분이 그만큼을 맡는다.'
'%    The law ILOS: LOS plus an integral — a PI controller on the cross-track'
'%    error. A current that keeps pushing leaves an error with LOS alone (the'
'%    error P leaves); the integral takes it over.'
'psi_d = pi_p - atan(y_e/Delta + (kappa/Delta)*y_int);'
''
'% 5) 적분 갱신. 분모가 y_e 와 함께 커지므로 멀리 벗어나 있을 때는 거의 적분하지 않는다:'
'%    법칙 안에 들어 있는 안티와인드업이다 (Borhaug, Pavlov, Pettersen 2008).'
'%    Update the integral. The denominator grows with y_e, so it barely'
'%    integrates while far off the path: anti-windup built into the law.'
'y_int = y_int + h * Delta*y_e / (Delta^2 + (y_e + kappa*y_int)^2);'
'end'};
end
C = [head; body];
end
% =========================================================================
function C = allocation_code(o)
sig = 'function n = allocation(N, X, y_pont, k_pos, k_neg, n_max, n_min)';
if o.speed
    src = {'%  X 는 **속도 루프의 출력**이다 (3주차). 상수가 아니라는 것 하나만 다르다.', ...
           '%  X is the output of the speed loop of Week 3, not a constant. That is the', ...
           '%  only difference; the two equations below are unchanged.'};
else
    src = {'%  X 는 상수 X_ff 다 - 캔버스의 Constant 블록이 넣어 준다.', ...
           '%  X is the constant X_ff, put in by a Constant block on the canvas.'};
end
hdr = [{'%ALLOCATION  전진력 X 와 요 모멘트 N 을 두 축의 회전수 n = [n_L; n_R] 로.', ...
        '%            The surge force X and the yaw moment N to the two shaft speeds.'}, src];
push = {'% 1) 두 힘을 두 추력으로. 배치행렬 B 를 세우고 **풀면** 된다 - 손으로 푼', ...
        '%    T = X/2 +- N/(2 y_pont) 와 같은 것이고, 이 쪽이 5-7 절의 유도와 같은', ...
        '%    모양이다. MSS 데모도 이렇게 한다: demoOtterUSVPathFollowingHeadingControl', ...
        '%    의 Allocation 안에 Constant [1 1; 0.395 -0.395] 와 행렬 나눗셈이 있다.', ...
        '%    B is square and nonsingular here, so the two forces are shared by solving', ...
        '%    rather than by two hand-written expressions. The MSS demonstration model', ...
        '%    does the same: its Allocation holds the constant [1 1; 0.395 -0.395] and', ...
        '%    a matrix division.', ...
        'B = [1        1;              % 전진력  X = T_L + T_R        / surge force', ...
        '     y_pont  -y_pont];        % 요 모멘트 N = y_pont(T_L-T_R) / yaw moment', ...
        'T = B \ [X; N];               % 좌현, 우현 / port, starboard'};
C = [{sig; '%#codegen'}; hdr(:); {''}; push(:); {''}];
C = [C; { ...
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
'% 3) 프로펠러가 낼 수 있는 범위로 자른다. **otter.m 이 안에서 이미 자르기 때문에**'
'%    (MSS otter.m 167-170 행) 여기서 자르지 않으면 로그에 적히는 n 이 플랜트가'
'%    실제로 받은 n 과 달라진다 - 기록은 플랜트가 받은 것이어야 한다.'
'%    Clamp to what the propellers can do. otter.m clamps internally (lines'
'%    167-170), so without this the logged n would not be the n the plant got,'
'%    and a log must record what the plant received.'
'n(1) = min(max(n(1), n_min), n_max);'
'n(2) = min(max(n(2), n_min), n_max);'
'end'}];
end

% =========================================================================
function from_at(m, tag, at, name)
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
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
L = {sprintf('WEEK 5, SECTION %s  -  %s', o.sec, o.title), '', ...
     '   guidance -> heading autopilot (Week 4) -> allocation -> Otter', ...
     '   double-click a block to read its code and comments', ''};
switch o.law
    case 'atan2', L{end+1} = '   psi_d = atan2(E_next - E, N_next - N)';
    case 'LOS',   L{end+1} = '   psi_d = pi_p - atan(y_e / Delta)            a P controller on y_e, Kp = 1/Delta';
    case 'ILOS',  L{end+1} = '   psi_d = pi_p - atan(y_e/Delta + (kappa/Delta) y_int)   a PI controller on y_e';
end
L = [L, {'', 'Change Delta, R_switch, kappa or V_c in the Command Window and press Run:', ...
         'the Scope shows the cross-track error and the heading; the XY Graph draws the track.'}];
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
%  주석은 **모든 블록 아래**에 둔다. 예전에는 [40 330 …] 이라 guidance 열의 kappa
%  Constant 위에 겹쳐 찍혔다 — Animate 블록이 y = 520 까지 내려오므로 그 아래다.
%  The note goes below every block: at y = 330 it printed on top of the kappa
%  Constant, and the Animate block now reaches y = 520.
a.Position = [40 560 900 700];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
