function W01_F_build_interactive()
%W01_F_BUILD_INTERACTIVE  W01_interactive.slx 를 코드로 만든다 — 버튼으로 모는 Otter.
%
%   >> W01_F_build_interactive
%
%   무엇을 만드는가
%     W01_openloop.slx 와 같은 선체, 같은 실시간 화면(궤적 + u v r x y psi)에
%     시간표 대신 버튼 다섯 개와 슬라이더 두 개를 붙인 모델이다.
%
%       버튼      STOP · AHEAD · ASTERN · PORT · STARBOARD
%       슬라이더  SPEED  n0   0 ~ 100 rad/s   두 프로펠러의 공통 속도
%                 TURN   dn   0 ~  30 rad/s   선회할 때 두 프로펠러 속도의 차이
%
%     실행 속도를 실제 시간에 맞추고(Simulation Pacing, 1 배) Stop 을 누를
%     때까지 멈추지 않는다. 시뮬레이션이 도는 동안 버튼을 눌러 조종한다.
%
%   왜 스크립트 없이 도는가
%     W01_openloop 은 W01_0_setup 이 기본 작업공간에 변수를 채워야 돈다.
%     이 모델은 필요한 변수를 **모델 작업공간**에 담아 함께 저장하고, 경로는
%     모델을 열 때 PostLoadFcn 이 스스로 잡는다. .slx 를 열고 Run 만 누르면 된다.
%
%   명령 규칙 — W01_openloop 의 시간표와 같은 규칙이다 (강의 §1-10, §D)
%       AHEAD      n = [ n0     ;  n0    ]
%       ASTERN     n = [-n0     ; -n0    ]   후진 추력은 k_neg 라서 더 약하다
%       PORT       n = [ n0-dn  ;  n0+dn ]   왼쪽을 느리게 -> 선수가 좌현으로
%       STARBOARD  n = [ n0+dn  ;  n0-dn ]
%       STOP       n = [ 0      ;  0     ]   추력이 없으니 감쇠로 서서히 선다
%
%   다시 만들어도 안전하다. 기존 W01_interactive.slx 는 덮어쓴다.

m    = 'W01_interactive';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));                 % ...\GradCourse
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();
load_system('simulink_hmi_blocks');                % Dashboard 블록이 들어 있는 라이브러리

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);

%  Stop 을 누를 때까지 돈다. Pacing 을 켜서 시뮬레이션 1 초가 실제 1 초가 되게 한다 —
%  꺼 두면 수 초 만에 수백 초가 지나가 버려서 버튼을 누를 틈이 없다.
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','inf', ...
             'EnablePacing','on', 'PacingRate', 1);

%% ---- 모델 작업공간 : 스크립트 없이 돌기 위한 변수 전부 ------------------
%  플랜트가 읽는 mp, rp, V_c, beta_c, x0 와 스텝 h, 실시간 화면 스위치 animate.
%  기본 작업공간이 아니라 모델 안에 저장되므로 모델 파일 하나만 있으면 된다.
mw = get_param(m, 'ModelWorkspace');
VV = struct('mp', 25, 'rp', [0.05 0 -0.35]', 'V_c', 0, 'beta_c', 0, ...
            'x0', zeros(12,1), 'h', 0.02, 'animate', 1);
fn = fieldnames(VV);
for i = 1:numel(fn), assignin(mw, fn{i}, VV.(fn{i})); end

%% ---- the chain : command -> plant -> measurement -------------------------
P = gnc_chain({'command','plant','measurement'});

%  1. command — 버튼과 슬라이더가 값을 바꾸는 Constant 셋, 그리고 규칙 하나.
cmd = add_subsys(m, 'Drive command', P.command, {}, {'n'}, gnc_colour('command'));
K  = {'mode','n0','dn'};
V0 = {'1',   '60','10'};                           % 처음에는 AHEAD, 60 rad/s, 차이 10
for i = 1:numel(K)
    add_block('simulink/Sources/Constant', [cmd '/' K{i}], 'Value', V0{i}, ...
              'Position', [40 34+50*i 100 64+50*i]);
end
add_block('simulink/User-Defined Functions/MATLAB Function', [cmd '/drive'], ...
          'Position', [190 70 330 210]);
set_mlfcn([cmd '/drive'], { ...
'function n = drive(mode, n0, dn)'
'%#codegen'
'%DRIVE  Turn one button into two shaft speeds.'
'%'
'%   mode   0 STOP, 1 AHEAD, 2 ASTERN, 3 PORT, 4 STARBOARD   (the buttons)'
'%   n0     common shaft speed [rad/s]                         (SPEED slider)'
'%   dn     difference between the two in a turn [rad/s]       (TURN slider)'
'%'
'%   The yaw moment is N = y_p (T_left - T_right), so a PORT turn slows'
'%   the LEFT propeller - the same rule as the timetable of W01_openloop.'
''
'switch mode'
'    case 1,    n = [ n0;       n0      ];   % AHEAD'
'    case 2,    n = [-n0;      -n0      ];   % ASTERN'
'    case 3,    n = [ n0 - dn;  n0 + dn ];   % PORT'
'    case 4,    n = [ n0 + dn;  n0 - dn ];   % STARBOARD'
'    otherwise, n = [ 0;        0       ];   % STOP'
'end'}, 'n', '[2 1]');

%  W01_openloop 과 같은 이유로 2x1 행렬을 1-D 벡터로 편다 (로그 규약).
add_block('simulink/Math Operations/Reshape', [cmd '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[380 118 420 162]);
for i = 1:numel(K)
    add_line(cmd, [K{i} '/1'], sprintf('drive/%d', i), 'autorouting','smart');
end
add_line(cmd, 'drive/1',     'as vector/1', 'autorouting','smart');
add_line(cmd, 'as vector/1', 'n/1',         'autorouting','smart');

%  2. plant — W01_openloop 과 똑같은 선체.
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%  3. measurement — 태그 W01i. 실시간 화면은 W01i_animate 가 그리고,
%     궤적 창이 배를 따라간다 (버튼으로 모는 배는 어디로 갈지 모르므로).
add_measurement(m, P.measurement, 'W01i', {'n'}, ...
                struct('dash', true, 'weekName', 'input  n  (rad per s)'));

L = @(a,b) add_line(m, a, b, 'autorouting','smart');
L('Drive command/1', 'Otter USV/1');
L('Otter USV/1',     'Measurements/1');
L('Drive command/1', 'Measurements/2');

%  블록 크기는 MSS 그대로. Dashboard 블록은 MSS 에 없으므로 그 뒤에 넣는다 —
%  mss_style 은 모델의 모든 블록에 크기를 매기기 때문이다.
mss_style(m);

%% ---- 지금 두 프로펠러에 들어가는 값 --------------------------------------
%  플랜트 아래에 둔다. 명령 블록 아래에 두면 선이 왼쪽으로 되돌아 나가
%  "뒤로 가는 선" 이 하나 더 생긴다 (CLAUDE.md §5).
yD = P.command(4) + 110;
add_block('simulink/Sinks/Display', [m '/n now  (left ; right)'], ...
          'Position', [P.plant(1) yD P.plant(3) yD+50]);
L('Drive command/1', 'n now  (left ; right)/1');

%% ---- the dashboard : 버튼 다섯, 슬라이더 둘 --------------------------------
y0 = yD + 170;

%  START · STOP — 한 번 누르면 처음부터 / 멈춤 (W01i_control).
%  Dashboard 의 Callback Button 은 코드로 넣은 ClickFcn 과 글자가 저장 뒤
%  사라진다 (R2024b 에서 확인). 그래서 클릭 콜백이 있는 주석 상자를 버튼으로 쓴다.
%  주석 배경색은 이름 색만 저장된다 ('[r g b]' 문자열은 흰색으로 돌아간다).
button(m, 'START  (from the beginning)', [40  y0-100 330 y0-45], 'green',  'W01i_control(''start'')');
button(m, 'STOP',                        [360 y0-100 600 y0-45], 'orange', 'W01i_control(''stop'')');
add_block('simulink_hmi_blocks/Radio Button', [m '/DRIVE'], ...
          'Position', [40 y0 230 y0+160]);
set_param([m '/DRIVE'], 'States', struct('Value', {0, 1, 2, 3, 4}, ...
          'Label', {'STOP', 'AHEAD', 'ASTERN', 'PORT (left)', 'STARBOARD (right)'}));
set_param([m '/DRIVE'], 'ButtonGroupName', 'DRIVE');     % 기본값은 'Group'
bind_to([m '/DRIVE'], [cmd '/mode']);

%  슬라이더 위의 글자("n0:Value")는 묶인 Constant 를 알려 준다. 블록 이름은
%  아래에 따로 보이게 해서 무엇을 조절하는지 말로도 읽히게 한다.
%  Limits 는 [최솟값 눈금간격 최댓값] 이고, 눈금간격 -1 은 자동이다.
add_block('simulink_hmi_blocks/Slider', [m '/SPEED  n0  (rad per s)'], ...
          'Position', [270 y0 600 y0+60], 'ShowName', 'on');
set_param([m '/SPEED  n0  (rad per s)'], 'Limits', [0 -1 100]);
bind_to([m '/SPEED  n0  (rad per s)'], [cmd '/n0']);

add_block('simulink_hmi_blocks/Slider', [m '/TURN  dn  (rad per s)'], ...
          'Position', [270 y0+110 600 y0+170], 'ShowName', 'on');
set_param([m '/TURN  dn  (rad per s)'], 'Limits', [0 -1 30]);
bind_to([m '/TURN  dn  (rad per s)'], [cmd '/dn']);

note(m, [640 y0-20 1180 y0+300], strjoin({ ...
'WEEK 1  -  DRIVE IT YOURSELF'
''
'1  Click START (or press Run). The live view opens on the right'
'   half of the screen and the vessel moves ahead.'
'2  Click a button while it runs:'
'      STOP        both propellers stop'
'      AHEAD       n = [ n0 ;  n0 ]'
'      ASTERN      n = [-n0 ; -n0 ]   (astern thrust is weaker)'
'      PORT        n = [n0-dn ; n0+dn]   the LEFT one slows'
'      STARBOARD   n = [n0+dn ; n0-dn]   the RIGHT one slows'
'3  Drag SPEED and TURN to change n0 and dn.'
'4  Click STOP to end the run. START again begins from the origin.'
''
'The simulation runs at real time (Simulation Pacing),'
'and never stops on its own.'
''
'WHAT TO WATCH'
'  terminal speed : u settles where thrust = damping   (sec. 1-11)'
'  in a turn      : v is not zero although Y is       (sec. 1-12)'
'  in a turn      : the bow points off the track      (crab angle)'}, newline));

%% ---- 모델을 열 때 경로를 스스로 잡는다 -----------------------------------
%  .slx 를 탐색기에서 두 번 눌러 열어도 돌게 한다. 모델 폴더(W01i_animate),
%  _tools(live_dash 등), MSS(otter.m) 셋이 경로에 있어야 한다.
set_param(m, 'PostLoadFcn', strjoin({ ...
    'p_ = fileparts(get_param(bdroot,''FileName''));' ...
    'addpath(p_, fullfile(fileparts(fileparts(p_)),''_tools''));' ...
    'mss_path(); clear p_'}, ' '));

set_param(m, 'ReturnWorkspaceOutputs', 'off');

save_system(m, out);
export_diagram(m, fullfile(here, 'img'));
close_system(m, 0);

fprintf('  built  %s\n', out);
end

% -------------------------------------------------------------------------
function bind_to(dash, target)
%  Dashboard 블록 하나를 Constant 블록의 Value 에 묶는다.
b = Simulink.HMI.ParamSourceInfo;
b.BlockPath = Simulink.BlockPath(target);
b.ParamName = 'Value';
set_param(dash, 'Binding', b);
end

function button(m, txt, pos, bg, fcn)
%  한 번 누르면 fcn 이 도는 주석 상자 — 캔버스 위의 버튼.
h = Simulink.Annotation([m '/' txt]);
h.Position            = pos;
h.FontSize            = 18;
h.FontWeight          = 'bold';
h.BackgroundColor     = bg;
h.HorizontalAlignment = 'center';
h.ClickFcn            = fcn;
end

function note(m, pos, txt)
h = Simulink.Annotation([m '/note']);
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end
