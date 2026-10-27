function W06_1_build_bow(which)
%W06_1_BUILD_BOW  6주차 모델 넷을 **코드로** 만든다. 손으로 그리지 않는다.
%                 Builds the four Week 6 models in code; none is drawn by hand.
%
%   W06_1_build_bow()                      넷 다 / all four
%   W06_1_build_bow('W06_F_position')      하나만 / one of them
%
%   네 모델이 **같은 모양**이다 / every model has the same shape
%
%       set point -> controller -> allocation -> Otter -> measurement
%
%   다른 것은 **설정값을 무엇이 만드는가** 하나뿐이다. 그래서 학생이 열린 루프에서
%   닫힌 루프로, 닫힌 루프에서 임무 상태기계로 넘어갈 때 **배분기와 플랜트는 한
%   블록도 달라지지 않는다** — 달라진 자리가 왼쪽 끝 하나뿐임이 그림에 보인다.
%   The only difference is WHAT PRODUCES THE SET POINTS. Going from open loop to
%   closed loop to a mission state machine therefore changes not one block of
%   the allocation or the plant, and the diagram shows that the change is
%   confined to the left-hand end.
%
%       모델                   루프  임무  좌표계  강의 절
%       W06_C_actuation         -     -     -     6-1  the allocation, in open loop
%       W06_F_position          O     -   body    6-3  holding a point with three loops
%       W06_H_berth             O     O   body    6-5  berthing, phase by phase
%       W06_I_position_ned      O     -   NED     6-7  the same point, held in NED
%
%   마지막 둘이 **같은 과제를 두 좌표계로** 푼다 (6-7 절). 바깥 고리가 오차를 선체
%   고정으로 돌려 놓고 전진·횡 속도를 요구하는가, 아니면 오차를 NED 에 그대로
%   두고 북·동 속도를 요구하고 **안쪽 고리**가 회전을 두 번 하는가. 배분기와
%   플랜트와 선수각 제어기는 네 모델이 **한 블록도 다르지 않다.**
%   The last two solve the same task in two frames. Either the outer loop
%   rotates the error into the hull and asks for surge and sway, or it leaves
%   the error in NED and asks for north and east while the INNER loop rotates
%   twice. The allocation, the plant and the heading autopilot are identical.
%
%   **제어기는 서브시스템이고, 안은 시뮬링크 블록이다** (사용자 지시, 2026-09-29).
%   두 번 누르면 합산점·게인·적분기·포화가 그대로 보인다 — 코드가 아니라 그림으로
%   읽는다. 세 제어기는 `_tools` 에 있다: `add_position_loop` · `add_velocity_loop` ·
%   `add_heading_loop`. 뒤의 것은 **4주차와 같은 함수**이므로 학생이 4주차에서 본
%   선수각 제어기를 블록 하나까지 그대로 다시 본다. 여기에 복사해 두면 한쪽만
%   고쳐진다 (§15-34).
%   The controllers are subsystems of ordinary Simulink blocks, and all three
%   live in _tools. The heading autopilot is the SAME FUNCTION Week 4 calls, so
%   the student sees block for block the autopilot already read. A copy here
%   would be the copy that goes stale.
%
%   선은 가로·세로만 / every line is horizontal or vertical
%
%   떠돌아다니는 신호는 전부 Goto/From 짝으로 보낸다. From 을 **받는 포트의 높이에**
%   놓으므로 (`from_at` + `route(..., zeros(0,2))`) 그 선은 짧은 가로 한 조각이다.
%   직접 잇는 선은 이웃한 단계 사이에만 두고, 그때는 두 블록의 높이를 포트 높이에서
%   거꾸로 계산해 **처음부터 맞춰 둔다**. 그래서 `check_diagonals` 가 0 이다.
%   Signals that travel go through Goto/From pairs, with each From placed at the
%   height of the port it feeds, so that line is one short horizontal run.
%   Direct lines join adjacent stages only, and then the two block heights are
%   derived FROM the port heights so they agree from the start.
%
%   **포트 높이는 계산하지 않고 읽는다** / port heights are READ, not predicted
%
%   시뮬링크는 포트를 `top + H*k/(n+1)` 에 놓지 않는다. 간격을 5 px 격자에 맞추고
%   띠 전체를 블록 **중심**에 모은다 — 서브시스템·Mux·MATLAB Function·플랜트가
%   모두 같은 규칙이고, 세 모델의 포트 337 개로 확인했다 (§15-52):
%
%       pitch = round(H/n/5)*5,   y_k = 중심 - (n-1)*pitch/2 + (k-1)*pitch
%
%   그래서 이 파일은 블록을 먼저 만들고 `port_xy` 로 **읽어서** From/Goto 를 놓는다.
%   식은 **거꾸로**만 쓴다 — 포트를 주어진 줄에 떨어뜨리는 블록 높이를 고를 때
%   (H = 160, n = 2 이면 pitch 80, 1 번 포트는 top+40).
%   Simulink does not place ports at top + H*k/(n+1): it snaps the pitch to the
%   5 px grid and centres the band on the block, the same way for subsystems,
%   Mux, MATLAB Function and the plant alike. So blocks are created first and
%   their port heights read with port_xy; the formula is used only backwards, to
%   pick a height that lands a port on a given line.
%
%   **수식이 캔버스 위에 있다** / the governing equations sit on the canvas
%
%   주석이 둘이다. 하나는 평범한 글자로 모델이 무엇을 들고 있는지 적고, 다른
%   하나는 `Interpreter = 'tex'` 로 **그 절의 수식을 그대로** 조판한다. 하나에
%   둘을 담을 수 없다 — `'tex'` 주석은 글 전체를 수식으로 읽는다.
%   Two annotations: one in plain text saying what the model holds, one with
%   Interpreter = 'tex' typesetting the section's equations. One annotation
%   cannot do both, because a 'tex' annotation reads all of its text as maths.
%
%   See also W06_0_SETUP, W06_PLOT, W06_READ, ADD_POSITION_LOOP,
%            ADD_VELOCITY_LOOP, ADD_POSITION_LOOP_NED, ADD_VELOCITY_LOOP_NED,
%            ADD_HEADING_LOOP, ADD_ALLOCATION3.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

%  모델이 컴파일되려면 작업공간에 값이 있어야 한다 (h · T_final · x0 · 게인들)
%  the workspace must hold the values before a model can compile
evalin('base', 'W06_0_setup');

M = struct( ...
    'name',    {'W06_C_actuation',             'W06_F_position',                    'W06_H_berth',              'W06_I_position_ned'}, ...
    'loops',   {false,                          true,                               true,                       true}, ...
    'mission', {false,                          false,                              true,                       false}, ...
    'frame',   {'-',                            'body',                             'body',                     'ned'}, ...
    'sec',     {'6-1',                          '6-3',                              '6-5',                      '6-7'}, ...
    'title',   {'the allocation, in open loop', 'holding a point with three loops', 'berthing, phase by phase', 'the same point, held in NED'});

if nargin == 1, M = M(strcmp({M.name}, which)); end
if isempty(M), error('W06:noSuchModel', 'no model named %s', which); end

if ~exist(fullfile(here, 'img'), 'dir'), mkdir(fullfile(here, 'img')); end
fprintf('\n  Week 6 models\n');
for k = 1:numel(M), build_one(M(k), here); end
fprintf('\n');
end

% =========================================================================
function build_one(o, here)
m   = o.name;
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');

% ---------------------------------------------------------------- 1) 설정값
%  세 모델이 **같은 네 태그**를 만든다 — p_d · psi_set · phase · d. 없는 신호는
%  NaN Constant 가 채운다. 열 수가 모델마다 다르면 절 스크립트가 어느 모델을
%  돌렸는지 알아야 하고, 그러면 표 하나를 두 모델로 채울 수 없다.
%  All three produce the same four tags; a NaN constant fills a signal a model
%  does not have, so one table can be filled from two different models.
if o.mission
    build_mission(m);
elseif o.loops
    add_block('simulink/Sources/Constant', [m '/N_d'], 'Value','N_d', ...
              'Position', [340 125 395 155]);
    add_block('simulink/Sources/Constant', [m '/E_d'], 'Value','E_d', ...
              'Position', [340 185 395 215]);
    %  두 스칼라를 **하나의 폭 2 태그**로 묶는다. 아래쪽 위치루프가 벡터를 받고,
    %  기록용 스칼라는 이 태그에서 다시 집어낸다 / one width-2 tag, picked apart
    %  again further down for the log
    add_block('simulink/Signal Routing/Mux', [m '/p_d mux'], 'Inputs','2', ...
              'DisplayOption','bar', 'Position', [460 120 465 220]);
    row_feed(m, 'p_d mux', {'N_d','E_d'});
    goto_plain(m, 'p_d', 170);
    route(m, 'p_d mux', 1, 'Goto p_d', 1, zeros(0,2));

    konst_goto(m, 'psi_d_cmd', 'psi_d_cmd', 'psi_set', 260);
    konst_goto(m, 'gate on',   '1',         'gate',    320);
    konst_goto(m, 'phase 0',   '0',         'phase',   380);
else
    konst_goto(m, 'p_d off',   '[NaN; NaN]', 'p_d',     160);
    konst_goto(m, 'psi_d off', 'NaN',        'psi_set', 220);
    konst_goto(m, 'phase 0',   '0',          'phase',   280);
    konst_goto(m, 'd off',     'NaN',        'd',       340);
end

% ----------------------------------------------------------------- 2) 제어
if o.loops
    %  좌표계가 고리 **두 개의 이름만** 바꾼다. 포트는 넷이 같다 — 이름도 수도
    %  순서도 — 그래서 아래의 배선이 두 좌표계에 **글자 하나 다르지 않고** 쓰인다.
    %  달라지는 것은 그 서브시스템 **안**이다: 회전이 바깥에 한 번 있는가,
    %  안쪽에 두 번 있는가 (7 절).
    %  The frame changes only the two subsystem NAMES. Both pairs carry the same
    %  ports, in the same order, so the wiring below serves either frame letter
    %  for letter. What differs is INSIDE: one rotation in the outer loop, or two
    %  in the inner one.
    if strcmp(o.frame, 'ned')
        posName = 'position loop NED';
        velName = 'velocity loop NED';
    else
        posName = 'position loop';
        velName = 'velocity loop';
    end

    %  바깥 위치루프. From 셋은 **블록을 만든 뒤 포트 높이를 읽어서** 그 자리에
    %  놓는다. 손으로 센 높이는 맞지 않는다 — 시뮬링크는 포트 간격을 5 px 격자에
    %  맞추고 띠 전체를 블록 중심에 모은다 (§15-52):
    %      pitch = round(H/n/5)*5,   y_k = 중심 - (n-1)*pitch/2 + (k-1)*pitch
    %  the From blocks are placed AFTER the subsystem exists, at the heights its
    %  ports really have: Simulink snaps the pitch to the 5 px grid and centres
    %  the band on the block, which is not top + H*k/(n+1)
    if strcmp(o.frame, 'ned')
        add_position_loop_ned(m, [760 180 920 420]);
    else
        add_position_loop(m, [760 180 920 420]);
    end
    FP = {'p_d', 'From p_d pos'; 'x', 'From x pos'; 'gate', 'From gate pos'};
    for i = 1:size(FP,1)
        q = port_xy(m, posName, 'Inport', i);
        from_at(m, FP{i,1}, [650 q(2)], FP{i,2});
        route(m, FP{i,2}, 1, posName, i, zeros(0,2));
    end

    %  목표까지의 거리. 임무 블록은 이것을 **받지 않는다** — 받으면 자기 출력에
    %  의존하는 대수 루프가 생긴다. 상태 x 를 주고 스스로 재게 한다
    %  the distance to the target; the mission block does NOT read it, or it
    %  would depend on its own output
    %  Goto 의 높이도 **읽어서** 맞춘다. 손으로 340 에 두었더니 포트가 360 에
    %  있어서 선이 되돌아 올라가는 비스듬한 조각이 되었다 (§15-52)
    %  the Goto's height is READ too: written in by hand at 340 while the port
    %  sits at 360, the line doubled back and became the one diagonal
    qd = port_xy(m, posName, 'Outport', 2);
    add_block('simulink/Signal Routing/Goto', [m '/Goto d'], 'GotoTag','d', ...
              'TagVisibility','local', 'ShowName','off', ...
              'Position', [940 qd(2)-9 1010 qd(2)+9]);
    route(m, posName, 2, 'Goto d', 1, zeros(0,2));

    %  안쪽 속도루프. nu_d 는 가로 한 조각으로 **직접** 잇는다. 그래서 높이를
    %  거꾸로 잡았다 — H = 160, n = 2 이면 pitch 는 80 이고 1 번 포트는 top+40
    %  이므로, 위치루프의 nu_d 출력 높이 240 에 오려면 top = 200 이다
    %  nu_d goes straight across, so the top is chosen backwards from the port:
    %  for H = 160 and two ports the pitch is 80 and port 1 sits at top + 40
    if strcmp(o.frame, 'ned')
        add_velocity_loop_ned(m, [1120 200 1280 360]);
    else
        add_velocity_loop(m, [1120 200 1280 360]);
    end
    qv = port_xy(m, velName, 'Inport', 2);
    from_at(m, 'x', [1010 qv(2)], 'From x vel');
    route(m, posName,      1, velName, 1, zeros(0,2));
    route(m, 'From x vel', 1, velName, 2, zeros(0,2));

    %  선수각 제어기는 4주차의 것 그대로다 / the Week 4 autopilot, unchanged
    add_heading_loop(m, [1120 450 1320 612], 'N_max');
    FH = {'psi_set', 'From psi_set head'; 'x', 'From x head'};
    for i = 1:size(FH,1)
        q = port_xy(m, 'heading autopilot', 'Inport', i);
        from_at(m, FH{i,1}, [1010 q(2)], FH{i,2});
        route(m, FH{i,2}, 1, 'heading autopilot', i, zeros(0,2));
    end

    %  Mux 는 **먹이는 두 출력 사이**에 걸쳐 둔다. 포트는 top+20 이 아니라
    %  중심에 모인 띠이므로 (§15-52) 두 선은 가로·세로 두 조각이 된다
    %  the Mux spans the two outputs it is fed from; its ports are a centred
    %  band, not top+20, so each line is one vertical and one horizontal piece
    add_block('simulink/Signal Routing/Mux', [m '/tau mux'], 'Inputs','2', ...
              'DisplayOption','bar', 'Position', [1420 267 1425 551]);
    route(m, velName,             1, 'tau mux', 1, zeros(0,2));
    route(m, 'heading autopilot', 1, 'tau mux', 2, zeros(0,2));
    yt = 409;
else
    %  열린 루프: 요구를 캔버스에서 **직접** 준다. 배분기만 보려는 절이다
    %  open loop: the demand is set on the canvas, so only the allocation acts
    C = {'X_cmd', 280; 'Y_cmd', 340; 'N_cmd', 400};
    for i = 1:size(C,1)
        add_block('simulink/Sources/Constant', [m '/' C{i,1}], 'Value', C{i,1}, ...
                  'Position', [1240 C{i,2}-15 1295 C{i,2}+15]);
    end
    add_block('simulink/Signal Routing/Mux', [m '/tau mux'], 'Inputs','3', ...
              'DisplayOption','bar', 'Position', [1420 260 1425 420]);
    row_feed(m, 'tau mux', C(:,1)');
    yt = 340;
end
add_block('simulink/Signal Routing/Goto', [m '/Goto tau'], 'GotoTag','tau', ...
          'TagVisibility','local', 'ShowName','off', 'Position', [1460 yt-9 1530 yt+9]);
route(m, 'tau mux', 1, 'Goto tau', 1, zeros(0,2));

% ------------------------------------------------------- 3) 배분기와 플랜트
%  **세 모델이 똑같다.** 이 아래로는 한 줄도 모델에 따라 갈라지지 않는다
%  IDENTICAL IN ALL THREE MODELS: nothing below here branches on the model
A = {'y_pont', 286; 'l_f', 340; 'k_pos', 394; 'k_neg', 448};
for i = 1:size(A,1)
    add_block('simulink/Sources/Constant', [m '/' A{i,1}], 'Value', A{i,1}, ...
              'Position', [1540 A{i,2}-15 1595 A{i,2}+15]);
end
from_at(m, 'tau', [1610 232], 'From tau');
add_allocation3(m, [1700 178 1900 502]);
route(m, 'From tau', 1, 'allocation', 1, zeros(0,2));
%  1 번 포트는 위에서 이미 이었으므로 빈 칸으로 넘긴다 / port 1 is already wired
row_feed(m, 'allocation', {'', A{:,1}});

add_block('simulink/Signal Routing/Goto', [m '/Goto n'], 'GotoTag','n', ...
          'TagVisibility','local', 'ShowName','off', 'Position', [1940 277 2010 295]);
add_block('simulink/Signal Routing/Goto', [m '/Goto tau_ext'], 'GotoTag','tau_ext', ...
          'TagVisibility','local', 'ShowName','off', 'Position', [1940 385 2010 403]);
route(m, 'allocation', 1, 'Goto n',       1, zeros(0,2));
route(m, 'allocation', 2, 'Goto tau_ext', 1, zeros(0,2));

%  선미 한 쌍은 **축 회전수**로, 선수추진기는 **힘**으로 선체에 들어간다.
%  otter.m 은 축 회전수 둘만 받으므로 세 번째 추진기는 tau_ext 로만 닿는다 —
%  그 중첩이 왜 근사가 아니고 정확한지는 6-1 절이 센다
%  The stern pair enter as SHAFT SPEEDS and the bow unit as a FORCE: otter.m
%  takes two shaft speeds, so the third thruster reaches the hull only through
%  tau_ext. Section 6-1 measures why that superposition is exact.
from_at(m, 'n',       [2030 313], 'From n');
from_at(m, 'tau_ext', [2030 367], 'From tau_ext');
add_otter_plant(m, 'Otter', [2120 259 2240 421], otter_config('bow_thruster'));
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
route(m, 'From n',       1, 'Otter', 1, zeros(0,2));
route(m, 'From tau_ext', 1, 'Otter', 2, zeros(0,2));

goto_at(m, {'Otter', 1}, [2270 340], 'up', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [2310 332 2326 348]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

% ------------------------------------------------------------ 4) 기록과 표시
measure(m, 2480);

% --------------------------------------------------- 5) 기록용으로 집어내기
%  폭 2 · 폭 3 태그에서 스칼라를 뽑아 **같은 17 열**을 채운다. 선택기 이름이
%  곧 식이므로 (`N_set = p_d(1)`) 그림을 읽는 사람이 열 번호를 세지 않는다
%  scalars picked off the wide tags to fill the same 17 columns; the selector's
%  name is the expression, so nobody counts column numbers
Y0 = 780;  dy = 70;
pick(m, 'p_d',     1, 2, 'N_set', Y0);
pick(m, 'p_d',     2, 2, 'E_set', Y0 +   dy);
deg_row(m,                        Y0 + 2*dy);
pick(m, 'tau',     1, 3, 'X_dem', Y0 + 3*dy);
pick(m, 'tau',     2, 3, 'Y_dem', Y0 + 4*dy);
pick(m, 'tau',     3, 3, 'N_dem', Y0 + 5*dy);
pick(m, 'n',       1, 2, 'n_L',   Y0 + 6*dy);
pick(m, 'n',       2, 2, 'n_R',   Y0 + 7*dy);
pick(m, 'tau_ext', 2, 3, 'F_B',   Y0 + 8*dy);

% ---------------------------------------------------------------- 6) 끝내기
note(m, o);
set_param(m, 'StopFcn', 'W06_plot;');
%  **Run 만 눌러도 돈다.** 학생이 .slx 를 더블클릭해 열고 Run 을 누르는 것이
%  가장 흔한 길인데, 그때 작업공간은 비어 있다. 모델의 Constant 는 숫자가 아니라
%  이름을 담으므로 (h · T_final · x0 · 게인들) 그대로면 첫 변수에서 멈춘다.
%  InitFcn 이 매 Run 마다 ① 도구 경로와 MSS ② 없는 변수 ③ 실시간 화면
%  ④ 현실 시간 진행을 챙긴다. 경로를 **먼저** 얹어야 run_alone 을 부를 수
%  있으므로 addpath 는 콜백 안에 있다 / press Run alone and it works
set_param(m, 'InitFcn', [ ...
    'addpath(fullfile(fileparts(fileparts(fileparts(' ...
        'get_param(bdroot, ''FileName'')))), ''_tools''), ' ...
        'fileparts(get_param(bdroot, ''FileName''))); ' ...
    'run_alone(''W06'', bdroot);']);

mss_style(m);
compact_layout(m, 60);                 % 빈 복도를 좁힌다 / squeeze empty corridors
straighten_lines(m);                   % 대각선 0 / no diagonals
save_system(m, out);

print(['-s' m], '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
%  **창을 열지 않고** 서브시스템을 뽑는다. open_system 으로 하나씩 열었더니
%  창이 쌓여 세션이 멈췄다 / exported without opening: opening each one piled up
%  windows and hung the session
SB = {'mission','position loop','velocity loop', ...
      'position loop NED','velocity loop NED','heading autopilot', ...
      'allocation','Otter','Measurements'};
for i = 1:numel(SB)
    if isempty(find_system(m, 'SearchDepth',1, 'Name',SB{i})), continue; end
    if strcmp(SB{i}, 'Measurements'), r = '-r55'; else, r = '-r70'; end
    print(['-s' m '/' SB{i}], '-dpng', r, ...
          fullfile(here, 'img', [m '_' strrep(SB{i},' ','_') '.png']));
end
close_system(m, 0);

%  **디스크의 파일에서 다시 센다.** save_system 이 가지선의 점을 다시 쓰므로
%  저장 전의 숫자는 끝난 모델의 숫자가 아니다 (§15-31)
%  counted again FROM THE FILE: save_system rewrites branch points
load_system(out);
n  = check_overlaps(m);
nd = check_diagonals(m);
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d, diagonals: %d)\n', [m '.slx'], n, nd);
end

% =========================================================================
function build_mission(m)
%  임무 상태기계. 네 단계가 **빗장 걸린 채 한 방향으로만** 간다
%  the mission state machine: four phases, latched and monotone
K = {'berth_N','berth_E','stand_off','psi_berth','R_app','R_berth'};

%  x 를 **맨 아래** 포트에 둔다. 위에 두면 상수 여섯의 선이 From 블록을 가로지른다
%  x goes on the BOTTOM port: above, the six constant lines would cross the From
sub = add_subsys(m, 'mission', [300 130 480 570], [K {'x'}], ...
                 {'p_d','psi_set','gate','phase'}, gnc_colour('reference'));

for i = 1:numel(K)
    add_block('simulink/Sources/Constant', [m '/' K{i}], 'Value', K{i}, ...
              'Position', [140 170+55*i 195 200+55*i]);
end
from_at(m, 'x', [120 515], 'From x mis');
row_feed(m, 'mission', [K {'From x mis'}]);

% ---- 안쪽 / inside
blk = [sub '/phases'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [260 60 440 500]);
%  persistent 을 쓰므로 표본시간을 **반드시** 말해야 한다. 물려 두면 연속시간을
%  물려받고, Simulink 가 그 스크립트를 거부한다
set_mlfcn(blk, mission_code(), 'p_d', '[2 1]', 'h');
%  공차 셋은 포트가 아니라 **작업공간 파라미터**다. 캔버스에 Constant 를 셋 더
%  달면 그림이 읽히지 않는다 / parameters, not ports
mlfcn_params(blk, {'psi_tol','v_tol','r_tol'});

np = numel(get_param(blk, 'PortHandles').Inport);
if np ~= numel(K) + 1
    error('W06:phasePorts', 'phases has %d inports, expected %d', np, numel(K)+1);
end
row_feed(sub, 'phases', [K {'x'}]);

OUT = {'p_d','psi_set','gate','phase'};
for k = 1:numel(OUT)
    at(sub, OUT{k}, port_xy(sub, 'phases', 'Outport', k) + [100 0]);
    route(sub, 'phases', k, OUT{k}, 1, zeros(0,2));
end

% ---- 네 출력을 태그로 / the four outputs onto tags
T = {'p_d','psi_set','gate','phase'};
for k = 1:numel(T)
    q = port_xy(m, 'mission', 'Outport', k);
    goto_plain(m, T{k}, q(2));
    route(m, 'mission', k, ['Goto ' T{k}], 1, zeros(0,2));
end
end

% =========================================================================
function L = mission_code()
%  MSS 의 `ssa` 는 코드생성이 안 되므로 atan2(sin, cos) 로 **펴서** 쓴다
%  MSS's ssa is not codegen-safe, so it is inlined as atan2(sin, cos)
L = { ...
'function [p_d, psi_set, gate, phase] = phases(berth_N, berth_E, stand_off, ...'
'                                                psi_berth, R_app, R_berth, x, ...'
'                                                psi_tol, v_tol, r_tol)'
'%#codegen'
'%  네 단계. 한 번 넘어가면 돌아오지 않는다 — 빗장이 걸려 있다.'
'%  Four phases. Once a transition is taken it is never taken back: it latches.'
'%'
'%    1 TRANSIT  접근점으로 간다. 선수각은 그쪽 방위 (5주차의 atan2 법칙)'
'%    2 ALIGN    제자리에서 psi_berth 로 돌린다'
'%    3 BERTH    그 선수각을 지킨 채 남은 stand_off 미터를 간다'
'%    4 MOORED   gate = 0 — 계류줄이 걸렸고 추진기는 0 으로 간다'
'%'
'%  왜 빗장을 거는가 / why it latches'
'%      단계마다 조건이 **경계에서** 참과 거짓을 왕복한다. 빗장이 없으면 배가'
'%      반경 R_app 안팎을 드나들 때 목표점이 접근점과 접안점 사이를 떨고,'
'%      안쪽 루프는 그 떨림을 추력으로 바꾼다.'
'%      Each condition flickers at its own boundary. Without the latch the'
'%      target would jitter between the two points and the inner loops would'
'%      turn that jitter into thrust.'
'%'
'%  왜 선수각을 **들고 있는가** / why the heading is HELD'
'%      1 단계의 선수각은 접근점 방위다. 접근점에 가까워지면 그 방위의 분모가'
'%      0 으로 가므로 2 m 안에서는 **마지막 값을 들고 있는다**. 이것이 이 절이'
'%      재는 예측 하나를 만든다 — 명령 선수각이 그 시각부터 평평해진다.'
'%      The bearing is ill-conditioned near the point, so inside 2 m the last'
'%      value is held. This section measures the prediction that makes: the'
'%      commanded heading goes flat from that instant.'
''
'persistent ph psi_hold'
'if isempty(ph), ph = 1; psi_hold = x(12); end'
''
'p   = [x(7); x(8)];     %  NED 위치 / position in NED'
'psi = x(12);'
'r   = x(6);'
'v   = x(2);'
''
'app = [berth_N; berth_E + stand_off];   %  접근점 / the approach point'
'brt = [berth_N; berth_E];               %  접안점 / the berth'
''
'switch ph'
'    case 1      %  TRANSIT'
'        e = app - p;'
'        if norm(e) > 2'
'            psi_hold = atan2(e(2), e(1));'
'        end'
'        if norm(e) <= R_app, ph = 2; end'
''
'    case 2      %  ALIGN'
'        psi_hold = psi_berth;'
'        de = atan2(sin(psi - psi_berth), cos(psi - psi_berth));'
'        if abs(de) <= psi_tol && abs(r) <= r_tol, ph = 3; end'
''
'    case 3      %  BERTH'
'        psi_hold = psi_berth;'
'        if norm(brt - p) <= R_berth && abs(v) <= v_tol, ph = 4; end'
''
'    otherwise   %  MOORED'
'        psi_hold = psi_berth;'
'end'
''
'if ph >= 3'
'    p_d = brt;'
'else'
'    p_d = app;'
'end'
'psi_set = psi_hold;'
'gate    = double(ph <= 3);   %  4 단계에서 0 — 추력을 끊는다 / thrust off'
'phase   = ph;'
'end'
};
end

% =========================================================================
function measure(m, X)
%  앞 여섯 열은 **온 과정이 같다** — [u v r N E psi]. 6주차가 열 열하나를 더한다
%  the first six columns are the course-wide contract; Week 6 appends eleven
Y = 340;
extra = {'N_set','E_set','psi_set','X_dem','Y_dem','N_dem','n_L','n_R','F_B','d','phase'};
add_measurement(m, [X Y-351 X+160 Y+351], 'W06', extra, ...
    struct('dash', true, ...
           'weekName', 'W06  this week:  set points, demands, n_L n_R, F_B, phase'));

%  psi_set 은 **도**로 기록한다. psi 가 도이고 (add_measurement 안의 rad2deg),
%  둘을 빼서 오차를 내는 자리가 많다 / psi_set is logged in DEGREES so that it
%  shares a unit with psi, which is subtracted from it in several places
tags = [{'x'} extra];
tags{4} = 'psi_set_deg';
for i = 1:numel(tags)
    q  = port_xy(m, 'Measurements', 'Inport', i);
    nm = ['From meas ' tags{i}];
    from_at(m, tags{i}, [X-120 q(2)], nm);
    route(m, nm, 1, 'Measurements', i, zeros(0,2));
end
end

% =========================================================================
function pick(m, srcTag, idx, width, dstTag, y)
%  폭이 2 나 3 인 태그에서 스칼라 하나를 뽑아 자기 태그로 내보낸다
%  one scalar off a wide tag, onto a tag of its own
nm = ['From p ' dstTag];
from_at(m, srcTag, [300 y], nm);
s = [dstTag ' = ' srcTag '(' num2str(idx) ')'];
add_block('simulink/Signal Routing/Selector', [m '/' s], ...
          'InputPortWidth', num2str(width), 'IndexOptions','Index vector (dialog)', ...
          'Indices', num2str(idx), 'Position', [430 y-18 570 y+18]);
route(m, nm, 1, s, 1, zeros(0,2));
add_block('simulink/Signal Routing/Goto', [m '/Goto ' dstTag], 'GotoTag', dstTag, ...
          'TagVisibility','local', 'ShowName','off', 'Position', [620 y-9 690 y+9]);
route(m, s, 1, ['Goto ' dstTag], 1, zeros(0,2));
end

% =========================================================================
function deg_row(m, y)
%  이 줄만 선택기가 아니라 **게인**이다 — 집어내는 것이 아니라 단위를 바꾼다
%  this row alone is a gain, not a selector: it changes a unit
from_at(m, 'psi_set', [300 y], 'From p psi_set_deg');
add_block('simulink/Math Operations/Gain', [m '/rad2deg psi_set'], ...
          'Gain', '180/pi', 'Position', [430 y-18 480 y+18]);
route(m, 'From p psi_set_deg', 1, 'rad2deg psi_set', 1, zeros(0,2));
add_block('simulink/Signal Routing/Goto', [m '/Goto psi_set_deg'], ...
          'GotoTag','psi_set_deg', 'TagVisibility','local', 'ShowName','off', ...
          'Position', [620 y-9 690 y+9]);
route(m, 'rad2deg psi_set', 1, 'Goto psi_set_deg', 1, zeros(0,2));
end

% =========================================================================
function note(m, o)
%  **모델이 실제로 들고 있는 것만** 적는다 (사용자 지시, 2026-10-14)
%  only what the model actually holds
L = {sprintf('WEEK 6, SECTION %s  -  %s', o.sec, o.title), ''};
if o.mission
    L = [L, { ...
      '   mission -> position loop -> velocity loop -> allocation -> Otter', ...
      '   the heading autopilot of Week 4 runs beside the velocity loop', ...
      '', ...
      '   four phases, latched and monotone:', ...
      '     1 TRANSIT   run to the approach point, heading = bearing to it', ...
      '     2 ALIGN     rotate in place to psi_berth', ...
      '     3 BERTH     cross the last stand_off metres holding that heading', ...
      '     4 MOORED    gate = 0, so the demand and the thrust go to zero', ...
      '', ...
      '   bow_on picks the strategy: 0 holds the hull parallel to the quay and', ...
      '   crosses in SWAY, -pi/2 turns the bow to the wall and crosses in SURGE'}];
elseif o.loops && strcmp(o.frame, 'ned')
    L = [L, { ...
      '   set point -> position loop NED -> velocity loop NED -> allocation -> Otter', ...
      '   the heading autopilot of Week 4 runs beside the velocity loop', ...
      '', ...
      '   the same task as W06_F_position, solved in the OTHER frame. the error', ...
      '   stays in NED and the outer loop asks for north and east speed, so that', ...
      '   subsystem has no psi port at all. the two rotations sit in the INNER', ...
      '   loop instead: one on the measured velocity coming in, one on the force', ...
      '   going out', ...
      '', ...
      '   two consequences, both measurable in Section 6-7:', ...
      '     the speed cap is on the VECTOR MAGNITUDE and must use the slow', ...
      '     axis''s value, 0.35 m/s, so the approach is slower than in body axes;', ...
      '     and the PI cannot see its own actuator rating, so its limit is loose', ...
      '     and the anti-windup bites late'}];
elseif o.loops
    L = [L, { ...
      '   set point -> position loop -> velocity loop -> allocation -> Otter', ...
      '   the heading autopilot of Week 4 runs beside the velocity loop', ...
      '', ...
      '   the outer loop is proportional and hands down a velocity demand;', ...
      '   the two inner loops are PI with back-calculation anti-windup', ...
      '', ...
      '   the error is rotated ONCE, in the outer loop, so everything downstream', ...
      '   is body-fixed and each axis keeps limits of its own', ...
      '', ...
      '   the sway axis carries gains of its own: M(2,2) = 162.5 kg against', ...
      '   M(1,1) = 85.5 kg, and Y_max = 35.13 N against X_max = 120 N'}];
else
    L = [L, { ...
      '   constant demand -> allocation -> Otter', ...
      '', ...
      '   no loop is closed here. tau = [X; Y; N] is set on the canvas and the', ...
      '   allocation inverts the square B of Section 6-1 by hand, one column', ...
      '   rule at a time, so that the inverse is read rather than evaluated'}];
end
L = [L, {'', '   double-click a block to read its code and comments'}];

a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
a.Position = [40 1400 1300 1640];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

equations(m, o);
end

% =========================================================================
function equations(m, o)
%  **그 절의 수식을 캔버스 위에** 조판한다 (사용자 지시, 2026-10-27).
%  typesets the section's own equations on the canvas.
%
%  주석 둘을 쓰는 이유 / why this is a SECOND annotation
%      `Interpreter = 'tex'` 주석은 글 **전체**를 수식으로 읽는다. 그래서 위의
%      평범한 글 주석과 한 덩어리로 둘 수 없다.
%      A 'tex' annotation reads ALL of its text as maths, so the prose note
%      above cannot share it.
%
%  쓸 수 있는 것과 없는 것 / what the interpreter does and does not take
%      MATLAB 의 TeX 해석기다 — `\tau` `\psi` `^{-1}` `_{p,pos}` `\leq`
%      `\rightarrow` `\surd` 가 조판되고, **`$$` 를 두르지 않는다.**
%      `\begin{bmatrix}` 는 없다. 그래서 행렬은 고정폭 글꼴(Consolas)로
%      **줄을 맞춰** 그린다. 실제로 렌더해서 확인했다.
%      It is MATLAB's TeX interpreter, not LaTeX: no $$ delimiters and no
%      bmatrix. Matrices are laid out by hand in a monospaced font.

switch o.name
case 'W06_C_actuation'
    E = { ...
    'SECTION 6-1   three axes out of three thrusters', ...
    '', ...
    '   \tau = B u', ...
    '     | X |   | 1.0    1.0   0.0 | | T_L |', ...
    '     | Y | = | 0.0    0.0   1.0 | | T_R |', ...
    '     | N |   | 0.395 -0.395 1.5 | | F_B |', ...
    '', ...
    '   the third row holds each unit''s moment arm about the centre:', ...
    '   y_p = 0.395 m, half the pontoon spacing;  l_f = 1.5 m, the bow lever', ...
    '   det B = 0.79 \neq 0', ...
    '   three columns, three rows, and the determinant is not zero:', ...
    '   the craft is FULLY ACTUATED and B can be inverted', ...
    '', ...
    'SECTION 6-2   reading the inverse, and where it runs out', ...
    '', ...
    '   u = B^{-1}\tau', ...
    '     T_L = X/2 - a Y + N/(2 y_p)        a = l_f/(2 y_p) = 1.8987', ...
    '     T_R = X/2 + a Y - N/(2 y_p)        1/(2 y_p) = 1.2658 1/m', ...
    '     F_B = Y', ...
    '', ...
    '   T_{min} \leq T_L, T_R \leq T_{max}        |F_B| \leq F_{B,max}', ...
    '', ...
    '   T_{max} = 119.68 N   T_{min} = -66.71 N   F_{B,max} = 40 N', ...
    '', ...
    '   at X = 0 and N = 0 the STERN sets the sway limit, not the bow unit:', ...
    '   |Y| \leq |T_{min}| / a = 35.13 N'};

case 'W06_F_position'
    E = { ...
    'SECTION 6-3   holding a point with three loops, in BODY axes', ...
    '', ...
    '   OUTER - one rotation, on the error', ...
    '     p_e = p_d - p                                      (NED)', ...
    '     the error, turned into hull axes:  [x_e; y_e] = R(\psi)^T p_e', ...
    '       | x_e |   |  cos\psi   sin\psi | | p_{e,N} |', ...
    '       | y_e | = | -sin\psi   cos\psi | | p_{e,E} |', ...
    '     u_c = sat(K_{p,pos} x_e, u_{lim})    v_c = sat(K_{p,pos} y_e, v_{lim})', ...
    '', ...
    '   INNER - one PI per axis, each knowing its own rating', ...
    '     X = sat(K_{p,u}(u_c - u) + I_u, X_{max})', ...
    '     I_u'' = K_{i,u}(u_c - u) + K_b(sat(X) - X)      back-calculation', ...
    '     Y = sat(K_{p,v}(v_c - v) + I_v, Y_{max})', ...
    '     I_v'' = K_{i,v}(v_c - v) + K_b(sat(Y) - Y)', ...
    '', ...
    '   HEADING - P-D, no integral, rate fed back directly', ...
    '     N = sat(K_p \psi_e - K_d r, N_{max})    \psi_e = ssa(\psi_d - \psi)', ...
    '', ...
    '   K_{p,pos} = 0.30 1/s   u_{lim} = 0.80 m/s   v_{lim} = 0.35 m/s', ...
    '   X_{max} = 120 N   Y_{max} = 35.13 N   N_{max} = 52.70 N m'};

case 'W06_H_berth'
    E = { ...
    'SECTION 6-5   berthing, phase by phase   (the loops of 6-3, unchanged)', ...
    '', ...
    '   the two waypoints, from the berth and the stand-off s', ...
    '     approach  p_{app}                berth  p_{brt}', ...
    '       | N_b     |                      | N_b |', ...
    '       | E_b + s |                      | E_b |', ...
    '', ...
    '   1 TRANSIT  p_d = p_{app},  \psi_d = atan2(p_{e,E}, p_{e,N})', ...
    '              |p_e| \leq R_{app}                            \rightarrow 2', ...
    '', ...
    '   2 ALIGN    p_d = p_{app},  \psi_d = \psi_{berth}', ...
    '              |ssa(\psi - \psi_{berth})| \leq \psi_{tol}  and  |r| \leq r_{tol}   \rightarrow 3', ...
    '', ...
    '   3 BERTH    p_d = p_{brt},  \psi_d = \psi_{berth}', ...
    '              |p_{brt} - p| \leq R_{berth}  and  |v| \leq v_{tol}      \rightarrow 4', ...
    '', ...
    '   4 MOORED   gate = 0  \rightarrow  \nu_d = 0  \rightarrow  \tau \rightarrow 0', ...
    '', ...
    '   the phase is LATCHED: it is monotone and never falls back', ...
    '   s = 7 m   R_{app} = 1.5 m   R_{berth} = 0.40 m', ...
    '   \psi_{tol} = 5 deg   r_{tol} = 1 deg/s   v_{tol} = 0.05 m/s', ...
    '', ...
    'SECTION 6-6   the last s metres, crossed two ways', ...
    '', ...
    '   bow\_on = 0    \psi_{berth} = 0        hull parallel to the quay, cross in SWAY', ...
    '   bow\_on = 1    \psi_{berth} = -\pi/2   bow at the wall, cross in SURGE', ...
    '', ...
    '   sway is bounded by 35.13 N, surge by 120 N: the same s metres', ...
    '   are crossed against limits that differ by a factor of 3.4'};

case 'W06_I_position_ned'
    E = { ...
    'SECTION 6-7   the same point, held in NED axes', ...
    '', ...
    '   OUTER - NO rotation, and no \psi port on the subsystem', ...
    '     p_e  = p_d - p                                     (NED)', ...
    '     \nu_p  = K_{p,pos} p_e', ...
    '     \nu_d  = \nu_p min(1, v_{ned,max}/|\nu_p|)            cap by MAGNITUDE', ...
    '', ...
    '   INNER - two rotations, one in and one out', ...
    '     \nu_n = R(\psi) \nu                                    rotation 1', ...
    '     e   = \nu_d - \nu_n', ...
    '     F_n = sat(K_{p,ned} e + I, 2X_{max})', ...
    '     I'' = K_{i,ned} e + K_b(sat(F_n) - F_n)', ...
    '     \tau_{uv} = R(\psi)^T F_n                              rotation 2', ...
    '', ...
    '     R(\psi), the rotation from hull axes into NED:', ...
    '       | cos\psi  -sin\psi |', ...
    '       | sin\psi   cos\psi |', ...
    '     R^{-1} = R^T   and   det R = 1', ...
    '', ...
    '   one gain pair serves both axes, because north is surge or sway', ...
    '   depending on \psi:  K_{p,ned} = 150,  K_{i,ned} = 120', ...
    '   v_{ned,max} = 0.35 m/s - the SLOW axis''s limit. per-axis caps would', ...
    '   give 0.35\surd2 = 0.495 m/s on a diagonal, over the rating', ...
    '', ...
    '   the heading law and the allocation are those of 6-3, letter for letter'};

otherwise
    return
end

%  글자 높이 약 22 px. 줄 수가 상자 높이를 정한다 / the line count sets the box
b = Simulink.Annotation([m '/equations']);
b.Text = strjoin(E, newline);
b.Interpreter = 'tex';
b.FontName = 'Consolas';           % 고정폭이라야 행렬의 열이 선다
b.FontSize = 13;
b.HorizontalAlignment = 'left';
b.Position = [40 1700 1300 1700 + 30 + 22*numel(E)];
b.BackgroundColor = 'lightBlue';
end

% =========================================================================
function konst_goto(m, name, val, tag, y)
%  캔버스의 Constant 하나와 그것을 실어 보내는 Goto 하나 / a canvas constant
%  and the Goto that carries it away
add_block('simulink/Sources/Constant', [m '/' name], 'Value', val, ...
          'Position', [340 y-15 395 y+15]);
goto_plain(m, tag, y);
route(m, name, 1, ['Goto ' tag], 1, zeros(0,2));
end

% -------------------------------------------------------------------------
function goto_plain(m, tag, y)
add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag', tag, ...
          'TagVisibility','local', 'ShowName','off', 'Position', [520 y-9 590 y+9]);
end

% -------------------------------------------------------------------------
function from_at(m, tag, at, name)
%  **받는 포트의 높이에** From 을 놓는다. 그러면 그 선이 가로 한 조각이다
%  the From is placed at the height of the port it feeds, so its line is one
%  horizontal segment and cannot run into anything
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag', tag, ...
          'ShowName','off', 'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

% -------------------------------------------------------------------------
function goto_at(m, src, at, dirn, tag)
%  출력에서 조금 나와서 위(아래)로 꺾어 Goto 로 들어간다 — 가로·세로뿐이다
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
at = round(at);
g  = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag', tag, ...
          'ShowName','off', 'TagVisibility','local', ...
          'Position', [at(1)+12 at(2)+dy-9 at(1)+72 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

% -------------------------------------------------------------------------
function at(s, name, p)
%  포트 블록의 세로 중심을 p(2) 에 맞춘다 / centre the port block on p(2)
set_param([s '/' name], 'Position', [p(1)-30 p(2)-7 p(1) p(2)+7]);
end

% -------------------------------------------------------------------------
function route(sys, src, sp, dst, dp, via)
%  두 포트의 높이를 **읽는다.** 숫자로 적어 두면 mss_style 이 블록 크기를 바꾸는
%  순간 어긋난다 / both heights are READ: a height written in by hand goes out of
%  true the moment mss_style resizes
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; via; b]);
end
