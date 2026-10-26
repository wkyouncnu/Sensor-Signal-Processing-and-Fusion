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
%  `laws` 가 그 모델에 **들어가는** 법칙이고, `n` 이 그 절이 **재는** 법칙이다.
%  법칙 하나만 든 모델에는 law 플래그도 Multiport Switch 도 없다 — 절이 설명하지
%  않은 것은 모델에 없다 (사용자 지시, 2026-10-14).
%  `laws` is what the model contains, `n` what the section measures. A model
%  holding one law has no `law` flag and no switch: what the section has not
%  explained is not in its model.
M = struct( ...
  'name',  {'W05_C_atan2','W05_D_LOS','W05_E_switching','W05_F_LOS','W05_F_ILOS','W05_G_tuning','W05_H_speed_path'}, ...
  'n',     {1, 2, 2, 2, 3, 3, 3}, ...          % law: 1 atan2, 2 LOS, 3 ILOS, 4 ILOS(보통 적분)
  'laws',  {1, 2, 2, 2, [3 4], [1 2 3], 3}, ...
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
Y = 340;

%% 유도 / guidance
%  **법칙마다 MATLAB Function 하나, 그것들을 담은 서브시스템 하나**다 (사용자 지시,
%  2026-10-14). 두 번 누르면 그 주차가 쓰는 법칙의 식이 **한 블록에 하나씩** 보이고,
%  법칙이 둘 이상인 모델에서는 밖에서 들어온 law 플래그가 Multiport Switch 로 고른다.
%  법칙이 하나인 모델에는 스위치도 플래그도 없다 — 절이 설명하지 않은 것은 모델에 없다.
%  배선과 코드는 모두 `_tools/add_guidance.m` 에 있다.
%  One MATLAB Function per law, gathered into one subsystem. Double-clicking shows
%  each law as its own block; where a model holds more than one, the `law` flag
%  coming in from outside picks between them through a Multiport Switch. A model
%  holding a single law has neither switch nor flag.
%
%  샘플 시간 h 도 **포트로** 들어간다 (사용자 지시, 2026-10-14). 전에는 블록
%  파라미터였으므로 적분이 무엇으로 곱해지는지 도면에 없었다. 이제 적분 법칙의
%  블록에 h 포트가 보이고, 그 선이 캔버스의 Constant 까지 이어진다.
%  The step h enters through a port as well. As a block parameter it was invisible,
%  so the diagram did not say what the integral was multiplied by.
[~, GIN] = add_guidance(m, [300 Y-30 520 Y+30], o.laws);
%  GIN 의 첫 칸은 x(상태 되먹임), 마지막 칸은 state(기억) 이고 둘은 Constant 가
%  아니다. 그 사이가 캔버스에 세워지는 Constant 열이다.
%  The first entry of GIN is x and the last is state; neither is a Constant. What
%  lies between becomes the column of Constants on the canvas.
q = port_xy(m, 'guidance', 'Inport', 1);
from_at(m, 'x', [150 q(2)]);
route(m, 'From x', 1, 'guidance', 1, zeros(0,2));
for i = 2:numel(GIN)-1
    q = port_xy(m, 'guidance', 'Inport', i);
    add_block('simulink/Sources/Constant', [m '/' GIN{i}], 'Value', GIN{i}, ...
              'Position', [150 q(2)-13 230 q(2)+13]);
    route(m, GIN{i}, 1, 'guidance', i, zeros(0,2));
end

%% 유도가 기억하는 것 / what the guidance remembers
%  **persistent 이 아니라 Unit Delay 다** (사용자 지시, 2026-10-13). 적분 상태는
%  이 주차의 주제인데, 블록 안의 persistent 로 두면 도면에 전혀 보이지 않는다.
%  밖으로 꺼내면 초기값이 블록의 파라미터로 보이고, 되먹임이라는 것이 선으로 읽힌다 —
%  5주차가 제어기를 서브시스템으로 그리는 것과 같은 이유다.
%  A Unit Delay, not PERSISTENT: the integral state is what this week is about, and
%  inside the block it could not be seen. Outside, the initial condition is a
%  parameter one can read and the feedback is a line.
%
%  **묶고 푸는 일은 서브시스템 안에서 한다** (2026-10-14). 최상위에는 `state next`
%  하나가 나가고 `state` 하나가 들어오므로, 뒤로 가는 선은 **하나**다. 이름이 붙은
%  상태들은 서브시스템 안쪽 Demux 의 출력에서 보인다.
%  The packing and unpacking happen inside the subsystem, so the top level has one
%  backward line: `state next` out, `state` in. The named states appear on the
%  Demux inside.
%  적분 법칙이 없는 모델은 상태가 둘(다리 번호, 임무 종료 시각)이고, 있으면 셋이다.
%  Without an integral law the state is two long, with one it is three.
nSt = 2 + any(o.laws >= 3);
IC  = ['[1;' repmat('0;', 1, nSt-2) '0]'];
ylane = Y + 320;
add_block('simulink/Discrete/Unit Delay', [m '/1 step'], ...
          'InitialCondition', IC, 'SampleTime','h', 'Orientation','left', ...
          'Position', [420 ylane-20 480 ylane+20]);
a = port_xy(m, 'guidance', 'Outport', 7);
b = port_xy(m, '1 step', 'Inport', 1);      % 왼쪽을 보므로 오른쪽 변 / right edge
add_line(m, [a; 560 a(2); 560 ylane; b]);
c = port_xy(m, '1 step', 'Outport', 1);
d = port_xy(m, 'guidance', 'Inport', numel(GIN));   % state 가 마지막 / state is last
add_line(m, [c; 260 ylane; 260 d(2); d]);

%% 선수각 오토파일럿 / heading autopilot
%  **서브시스템이고, 안은 시뮬링크 블록이다** (사용자 지시, 2026-09-29). 4주차
%  모델과 같은 블록·같은 이름이다 — Fcn 'ssa' 하나, Gain 'Kp' 와 'Kd',
%  Saturation 'moment limit'. 두 번 누르면 4주차의 식이 그림으로 보인다.
%  빼는 것은 게인이 아니라 **합산점**이다 (build_autopilot 의 주석 참고).
%  A subsystem of Simulink blocks, with the same blocks and the same names as the
%  Week 4 model: one Fcn 'ssa', the gains Kp and Kd, and a Saturation. The D term
%  is subtracted at the summing junction rather than carried as a negative gain.
add_heading_loop(m, [680 Y-60 880 Y+60], ternary(o.speed, 'N_speed', 'N_max'));
p1 = port_xy(m, 'guidance', 'Outport', 1);  a1 = port_xy(m, 'heading autopilot', 'Inport', 1);
route(m, 'guidance', 1, 'heading autopilot', 1, [600 p1(2); 600 a1(2)]);
a2 = port_xy(m, 'heading autopilot', 'Inport', 2);
add_block('simulink/Signal Routing/From', [m '/From x '], 'GotoTag','x', 'ShowName','off', ...
          'Position', [615 a2(2)-10 655 a2(2)+10]);
route(m, 'From x ', 1, 'heading autopilot', 2, zeros(0,2));
goto_at(m, {'guidance', 1}, [550 p1(2)], 'up', 'psi_d');
%  y_e, aux, wp, gate, stop 는 전부 Goto 태그로 나간다. gate 와 stop 은 H 모델만
%  쓰지만, 출력 포트는 어느 모델에서나 연결되어 있어야 한다 (연결 안 된 출력은
%  컴파일 오류다) - 쓰지 않는 모델에서는 From 이 없는 Goto 로 남는다.
%  All five go out as Goto tags. gate and stop are read only by the H model, but
%  an output port has to be connected in every model, so elsewhere the Goto simply
%  has no From.
for i = 2:6
    p = port_xy(m, 'guidance', 'Outport', i);
    tag = {'','y_e','aux','wp','gate','stop'};  tag = tag{i};
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
    add_speed_loop(m, [680 Y+150 880 Y+270]);
    q = port_xy(m, 'speed loop', 'Inport', 2);
    add_block('simulink/Signal Routing/From', [m '/From x sp'], 'GotoTag','x', 'ShowName','off', ...
              'Position', [600 q(2)-10 645 q(2)+10]);
    route(m, 'From x sp', 1, 'speed loop', 2, zeros(0,2));
    %  명령 속도는 **밖의 Constant** 다 (사용자 지시, 2026-09-29: "u_d 도 외부로 나오게").
    %  게인은 서브시스템 안의 Gain 블록이 작업공간에서 읽는다 - MSS 데모가 Delta 와
    %  R_switch 를 캔버스에 두고 게인은 Gain 블록에 두는 것과 같다.
    %  The commanded speed is a Constant outside; the gains are read from the
    %  workspace by Gain blocks inside, as in the MSS demonstration model.
    %  명령 속도는 **gate 를 지나** 들어간다 (사용자 지시, 2026-10-13): 마지막
    %  웨이포인트에 닿으면 유도가 gate 를 0 으로 내리고, 곱이 명령을 0 으로 만들어
    %  배가 선다. 곱셈을 캔버스에 두는 이유는 그것이 **임무의 끝**이라는 사실이
    %  그림에 보여야 하기 때문이다 - 유도 블록 안에 숨기지 않는다.
    %  The commanded speed passes through the gate: on reaching the last waypoint
    %  the guidance takes gate to 0 and the product takes the command with it. The
    %  multiplication is on the canvas because the end of the mission is something
    %  the diagram should show rather than hide inside the guidance block.
    q = port_xy(m, 'speed loop', 'Inport', 1);
    add_block('simulink/Math Operations/Product', [m '/u_d x gate'], 'Inputs','2', ...
              'Position', [600 q(2)-18 630 q(2)+18]);
    add_block('simulink/Sources/Constant', [m '/u_d'], 'Value','u_d', ...
              'Position', [460 q(2)-33 540 q(2)-7]);
    route(m, 'u_d', 1, 'u_d x gate', 1, zeros(0,2));
    q2 = port_xy(m, 'u_d x gate', 'Inport', 2);
    from_at(m, 'gate', [470 q2(2)], 'From gate');
    route(m, 'From gate', 1, 'u_d x gate', 2, zeros(0,2));
    route(m, 'u_d x gate', 1, 'speed loop', 1, zeros(0,2));
    goto_at(m, {'u_d x gate', 1}, port_xy(m, 'u_d x gate', 'Outport', 1), 'up', 'u_d_eff');
    goto_at(m, {'speed loop', 1}, port_xy(m, 'speed loop', 'Outport', 1), 'down', 'X');

    %  임무가 끝나고 stop_hold 초 뒤에 실행을 끝낸다. 5주차에는 임무 상태기계가
    %  없으므로(그것은 9주차다) 블록 하나로 끝낸다 - 조건은 유도가 만든다.
    %  The run ends stop_hold seconds after the mission does. Week 5 has no mission
    %  state machine - that is Week 9 - so one block ends it, on a condition the
    %  guidance produced.
    add_block('simulink/Sinks/Stop Simulation', [m '/mission over'], ...
              'Position', [600 Y+400 630 Y+430]);  % 상태 통로 아래 / below the state lane
    q = port_xy(m, 'mission over', 'Inport', 1);
    from_at(m, 'stop', [480 q(2)], 'From stop');
    route(m, 'From stop', 1, 'mission over', 1, zeros(0,2));
end

%% 배분 / allocation
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [1040 Y-20 1220 Y+332]);
set_mlfcn([m '/allocation'], allocation_code(o), 'n', '[2 1]');
%  배분기가 받는 것은 **일곱 개 전부 포트**다 (사용자 지시, 2026-10-14). 전에는
%  선체 상수 다섯이 숨은 파라미터였으므로, 추력 곡선의 계수 k_pos·k_neg 와 폰툰
%  간격 y_pont 가 배분식에 들어간다는 사실이 도면에 없었다. 7주차가 다루는 것이
%  바로 그 다섯이므로, 5주차에서 이미 선으로 보여 둔다.
%  All seven inputs are ports now. As hidden parameters the five hull constants
%  did not appear, so the diagram did not say that the thrust-curve coefficients
%  and the pontoon separation enter the allocation. Week 7 is about those five.
ALLIN = {'y_pont','k_pos','k_neg','n_max','n_min'};
p = port_xy(m, 'heading autopilot', 'Outport', 1);  q = port_xy(m, 'allocation', 'Inport', 1);
set_param([m '/allocation'], 'Position', get_param([m '/allocation'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
route(m, 'heading autopilot', 1, 'allocation', 1, zeros(0,2));
goto_at(m, {'heading autopilot', 1}, [p(1)+20 p(2)], 'up', 'Nmom');
if o.speed
    %  속도 루프가 낸 힘 / the force the speed loop asked for
    add_block('simulink/Signal Routing/From', [m '/From X'], 'GotoTag','X', 'ShowName','off', ...
              'Position', [945 0 990 20]);
    xsrc = 'From X';
else
    %  속도 루프가 없는 모델에서는 전진력이 상수다. 그 상수도 캔버스에 둔다 -
    %  숨은 파라미터로 두면 5-7 절에서 무엇이 바뀌었는지 보이지 않는다.
    %  Without a speed loop the surge force is a constant, and the constant is put
    %  on the canvas too: hidden, it would not show what 5-7 changes.
    add_block('simulink/Sources/Constant', [m '/X_ff'], 'Value','X_ff', ...
              'Position', [900 0 990 26]);
    xsrc = 'X_ff';
end
for i = 1:numel(ALLIN)
    add_block('simulink/Sources/Constant', [m '/' ALLIN{i}], 'Value', ALLIN{i}, ...
              'Position', [900 0 990 26]);
end
%  row_feed 가 여섯 소스를 포트 높이에 맞춰 올려놓고 가로선으로 잇는다. 첫 포트는
%  오토파일럿에서 오므로 빈칸이다. / row_feed lifts each source onto its port's
%  height; the first port is blank because it comes from the autopilot.
row_feed(m, 'allocation', [{''} {xsrc} ALLIN]);
if ~o.speed
    p = port_xy(m, 'X_ff', 'Outport', 1);
    goto_at(m, {'X_ff', 1}, [p(1)+20 p(2)], 'down', 'X');
end

%% Otter
cfg = otter_config('base');
add_otter_plant(m, 'Otter', [1290 Y-30 1390 Y+30], cfg);
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

measure(m, 1540, o);
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
compact_layout(m, 60);                 % 빈 복도를 좁힌다 / narrow the empty corridors
straighten_lines(m);                   % 대각선 0 / no diagonal stretches (CLAUDE.md 5)
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
n = check_overlaps(m);  nd = check_diagonals(m);
for sb = {'guidance','heading autopilot','speed loop','moment limit'}
    if isempty(find_system(m, 'SearchDepth',1, 'Name',sb{1})), continue; end
    %  `print('-s<path>')` 는 창을 **열지 않고** 뽑는다. open_system 으로 먼저 열면
    %  일곱 모델을 연달아 지을 때 창이 쌓여 세션이 멈춘다 — 실제로 멈췄다.
    %  print('-s<path>') exports without opening a window. Opening each subsystem
    %  first piles up windows and hangs the session over seven models; it did.
    print(['-s' m '/' sb{1}], '-dpng', '-r70', ...
          fullfile(here, 'img', [m '_' strrep(sb{1},' ','_') '.png']));
end
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d, diagonals: %d)\n', [m '.slx'], n, nd);
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
%  psi_d_deg 가 네 번째다 (사용자 지시, 2026-10-13): 화면이 **두 루프 각각**에 대해
%  명령과 실제를 겹쳐 그리려면 선수각 명령도 들어와야 한다.
%  psi_d_deg is the fourth input: the view overlays command on response for
%  both loops, so the commanded heading has to arrive as well.
ANM = {'N','E','psi_deg','psi_d_deg','y_e','u'};   % 태그에서 오는 것 / from tags
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/Animate'], ...
          'Position', [A+120 yA A+270 yA+530]);
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
q = port_xy(m, 'Animate', 'Inport', 7);
if o.speed
    %  **gate 를 지난 뒤의 명령**을 보여 준다. 상수 u_d 를 그리면 임무가 끝난 뒤에도
    %  1.0 m/s 를 명령하고 있는 것처럼 보인다 - 화면이 거짓말을 한다.
    %  The command AFTER the gate: drawing the constant would show 1.0 m/s still
    %  being asked for after the mission is over.
    from_at(m, 'u_d_eff', [A q(2)], 'From an u_d');
    route(m, 'From an u_d', 1, 'Animate', 7, zeros(0,2));
else
    add_block('simulink/Sources/Constant', [m '/u_d shown'], ...
              'Value', 'NaN', 'Position', [A q(2)-13 A+80 q(2)+13]);
    route(m, 'u_d shown', 1, 'Animate', 7, zeros(0,2));
end
q = port_xy(m, 'Animate', 'Inport', 8);
from_at(m, 'n', [A q(2)], 'From an n');
route(m, 'From an n', 1, 'Animate', 8, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 9);
from_at(m, 'wp', [A q(2)], 'From an wp');
route(m, 'From an wp', 1, 'Animate', 9, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 10);
add_block('simulink/Sources/Clock', [m '/clock'], 'Position', [A+40 q(2)-10 A+60 q(2)+10]);
route(m, 'clock', 1, 'Animate', 10, zeros(0,2));
q = port_xy(m, 'Animate', 'Inport', 11);
add_block('simulink/Sources/Constant', [m '/live view'], 'Value','animate', ...
          'Position', [A q(2)-13 A+80 q(2)+13]);
route(m, 'live view', 1, 'Animate', 11, zeros(0,2));
p = port_xy(m, 'Animate', 'Outport', 1);
add_block('simulink/Sinks/Terminator', [m '/anim end'], ...
          'Position', [A+310 p(2)-8 A+326 p(2)+8]);
route(m, 'Animate', 1, 'anim end', 1, zeros(0,2));

%  로그 / the log
%  9 요 모멘트, 10 전진력, 11 축 회전수 둘 - 5-7 절의 배분 수식을 수치로 확인한다
%  9 the yaw moment, 10 the surge force, 11 the two shaft speeds: what 5-7 checks
%  the allocation equations against. Column 11 is a 2-vector, so the log has 12.
%  12 명령 속도 (gate 를 지난 뒤) - **속도 루프가 있는 모델만**. 임무가 끝나 명령이
%  0 으로 내려간 순간이 로그에 남아야, 절 스크립트가 "도는 동안" 만 재어 평균을
%  낼 수 있다 (2026-10-13).
%  Column 12 is the commanded speed after the gate, and only where there is a
%  speed loop: the instant the command goes to zero has to be in the log, so that
%  the section script can average over the part of the run that was under way.
tags = {'y_e','psi_d_deg','psi_deg','N','E','aux','wp','u','Nmom','X','n'};
if o.speed, tags{end+1} = 'u_d_eff'; end
nlog = numel(tags);
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs', num2str(nlog), ...
          'Position', [S+400 40 S+405 480]);
for i = 1:nlog
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
%  제어기 둘은 **_tools 에 있다** — `add_heading_loop` 과 `add_speed_loop` (2026-10-13).
%  4주차의 통합 모델(W04_J_both)이 같은 함수를 부르므로, 학생이 4주차에서 본 그림을
%  5주차에서 **블록 하나까지 그대로** 다시 본다. 여기에 복사해 두면 한쪽만 고쳐진다.
%  MATLAB Function 은 유도 법칙과 배분에만 남는다 — 그 둘은 강의가 코드를 줄 단위로
%  인용하는 곳이고, 나머지는 그림으로 읽는 편이 낫다.
%
%  The two controllers live in _tools: add_heading_loop and add_speed_loop. The
%  Week 4 combined model calls the same two functions, so the diagram a student
%  saw in Week 4 is the same one, block for block, here. The MATLAB Function
%  blocks that remain are the guidance law and the allocator, which are the two
%  the lecture quotes line by line.

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
'function ok = Animate(N, E, psi_deg, psi_d_deg, y_e, u, u_d, n, wp, t, en)'
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
'    W05_animate(N, E, psi_deg, psi_d_deg, y_e, u, u_d, n, wp, t);'
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
%  **이 모델에 든 법칙만** 적는다 (사용자 지시, 2026-10-14). 전에는 셋을 전부
%  적었으므로, 법칙 하나만 든 모델에서도 학생은 나머지 둘을 찾으려 들었다.
%  Only the laws the model holds are listed. Listing all three sent the reader
%  looking inside a model for two laws that were not there.
LAWS = {'1  atan2   psi_d = atan2(E_next - E, N_next - N)                   aims at a POINT', ...
        '2  LOS     psi_d = pi_p - atan(y_e / Delta)                        a P controller on y_e, Kp = 1/Delta', ...
        '3  ILOS    psi_d = pi_p - atan(y_e/Delta + (kappa/Delta) y_int)    a PI controller on y_e', ...
        '4  ILOS    the same psi_d, with y_int integrating y_e plainly      the comparison of 5-5c'};
if numel(o.laws) == 1
    L{end+1} = sprintf('   the guidance block holds one law: %s', strtrim(LAWS{o.laws}));
else
    L{end+1} = sprintf('   law chooses among the laws in the guidance block.  This section uses law = %d', o.n);
    for i = o.laws
        mark = '     ';  if i == o.n, mark = '  -> '; end
        L{end+1} = [mark LAWS{i}];
    end
end
TUNE = {'Delta, R_switch or V_c'};
if any(o.laws >= 3), TUNE = {'Delta, R_switch, kappa or V_c'}; end
if numel(o.laws) > 1, TUNE = {['law, ' TUNE{1}]}; end
L = [L, {'', ['Change ' TUNE{1} ' in the Command Window and press Run:'], ...
         'the Scope shows the cross-track error and the heading; the XY Graph draws the track.'}];
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
%  주석은 **모든 블록 아래**에 둔다. 예전에는 [40 330 …] 이라 guidance 열의 kappa
%  Constant 위에 겹쳐 찍혔다 — Animate 블록이 y = 520 까지 내려오므로 그 아래다.
%  The note goes below every block: at y = 330 it printed on top of the kappa
%  Constant, and the Animate block now reaches y = 520.
a.Position = [40 820 1100 1000];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
