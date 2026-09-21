function W03_1_build_surge_control()
%W03_1_BUILD_SURGE_CONTROL  속도제어 모델 W03_surge_control.slx 를 코드로 만든다.
%                           Generate W03_surge_control.slx from code.
%
%   실행 / to run
%       W03_1_build_surge_control
%
%   강의에서의 위치 / place in the lecture
%       Part 2 의 절 B 이다. 이번 주 실습의 절 C 부터 G 까지가 모두 이 모델
%       하나를 쓴다. 개루프 동정도, 제어기 비교도, 와인드업 실험도 같은 모델의
%       스위치를 바꾸어 하는 것이다.
%       This is section B of Part 2. Sections C to G all use this one model:
%       the open-loop identification, the comparison of controllers and the
%       windup experiment are all done by changing switches in it.
%
%   신호의 흐름 / the signal chain
%       MSS 데모 모델과 같은 순서로 왼쪽에서 오른쪽으로 놓는다.
%       Left to right, in the order used by the MSS demonstration models:
%
%     Speed command --> Surge controller --> Control allocation --> Otter USV --> Measurements
%          u_d                X_cmd                  n                  x
%
%   거꾸로 가는 신호는 둘뿐이다 / two signals travel backwards, and only two
%
%     x      플랜트에서 제어기로 — 측정한 속도
%            from the plant to the controller, the measured speed
%     X_sat  배분에서 제어기로 — 프로펠러가 실제로 낸 힘. 모든 안티와인드업
%            방식이 이 값을 필요로 한다. 요구한 힘과 실현된 힘의 차이를 알지
%            못하면 적분기에게 고리가 끊겼다고 알려 줄 방법이 없다
%            from the allocation to the controller, the force the propellers
%            actually delivered. Every anti-windup scheme needs it: without
%            the difference between what was demanded and what was produced,
%            there is no way to tell the integrator that the loop was opened
%
%   각 단계는 서브시스템이다. 최상위 화면에는 사슬과 두 개의 되먹임 경로만
%   보이고, 나머지는 모두 단계 안에 들어 있다.
%   Each stage is a subsystem. The top level shows the chain and the two
%   feedback paths; everything else lives inside a stage.
%
%   다시 생성해도 안전하다. 기존 W03_surge_control.slx 는 덮어쓴다.
%   Regenerating is safe: any existing W03_surge_control.slx is overwritten.

m    = 'W03_surge_control';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

P = gnc_chain({'command','controller','allocation','plant','measurement'}, ...
              'Height', struct('controller',130, 'allocation',110), 'Y', 120);

AW = {'aw_mode','Ki','K_aw'};
KK = {'k_pos','k_neg','n_max','n_min'};

%% =====================================================================
%  1. Speed command
%  =====================================================================
%  Two steps are summed, so one model covers a single step and the
%  up-then-down profile the windup experiment needs. Setting u_d2 = u_d1
%  turns the second step off.
s = add_subsys(m, 'Speed command', P.command, {}, {'u_d'}, gnc_colour('command'));
add_block('simulink/Sources/Step', [s '/step 1'], ...
          'Time','t_up', 'Before','0', 'After','u_d1', 'Position',[100 60 140 100]);
add_block('simulink/Sources/Step', [s '/step 2'], ...
          'Time','t_dn', 'Before','0', 'After','u_d2 - u_d1', 'Position',[100 140 140 180]);
add_sum(s, 'sum', '++', [262 120]);
set_param([s '/u_d'], 'Position',[400 110 430 130]);
add_line(s, 'step 1/1','sum/1','autorouting','on');
add_line(s, 'step 2/1','sum/2','autorouting','on');
add_line(s, 'sum/1','u_d/1','autorouting','on');

%% =====================================================================
%  2. Surge controller
%  =====================================================================
c = add_subsys(m, 'Surge controller', P.controller, ...
               {'u_d','x','X_sat'}, {'X_cmd','I'}, gnc_colour('controller'));

%  ---- LAYOUT -----------------------------------------------------------
%  The interior is laid out in columns, left to right, exactly like the top
%  level. Simulink.BlockDiagram.arrangeSystem was tried and rejected: it packs
%  the blocks more tightly but reorders them, and put the X_cmd OUTPORT at the
%  top left, ahead of the inports. Compactness is not the goal here; being
%  readable in a PDF at page width is.
%
%    50   150      260    380          600     690    790     950    1060
%    in   select   err    Kp / AW /    I       X_pid  hand    open   out
%         const    sum    D / PID      state   sum    or blk  or cls
%
%  One line runs right to left, from the switch output back into the
%  anti-windup block. That is the saturated command coming back to tell the
%  integrator the loop has been opened, and it is the whole subject of 2-6.
add_block('simulink/Signal Routing/Selector', [c '/u'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','1', ...
          'InputPortWidth','12', 'Position',[150 140 200 160]);
add_sum(c, 'error', '+-', [280 90]);
add_block('simulink/Math Operations/Gain', [c '/Kp'], 'Gain','Kp', ...
          'Position',[380 40 430 76]);

%  적분기에 실제로 들어가는 양을, 세 개의 상자로 나누어 만든다.
%
%  2026-09-16 에 MATLAB Function 하나를 표준 블록으로 풀어 썼는데, 그것을 한
%  화면에 평평하게 늘어놓으니 블록 열다섯 개와 서로 얽힌 선이 되어 오히려 읽기가
%  더 어려워졌다. 그래서 다시 정리한다. 이 화면에는 **세 방식이 상자 셋으로**
%  보이고, 각 방식의 계산은 그 상자 안에 있다.
%
%      sat = X_cmd - X_sat        작동기가 거절한 부분
%      Ki e                        보호가 없을 때 적분기에 들어갈 양
%      clamping                    상자 하나 — 얼릴 것인가 말 것인가
%      back-calculation            상자 하나 — 거절된 만큼을 되먹인다
%      scheme                      aw_mode 로 셋 중 하나를 고른다
%
%  On 2026-09-16 a single MATLAB Function was opened out into standard blocks,
%  but laid flat on one canvas that became fifteen blocks and a tangle of
%  lines, which was harder to read than what it replaced. It is arranged again
%  here so that the canvas shows three schemes as three boxes, with each
%  scheme's arithmetic inside its own box.
%
%  이 화면에 남는 계산은 둘뿐이다. 모든 방식이 공유하기 때문이다.
%  Only two computations remain on this canvas, because every scheme shares
%  them: what the actuator refused, and what an unprotected integrator would
%  receive.
aw_blk = add_subsys(c, 'anti-windup', [380 150 530 330], ...
                    {'e','X_cmd','X_sat'}, {'di'});

%  ---- 배치 / the arrangement ---------------------------------------------
%  블록을 **scheme 스위치의 포트 순서대로 위에서 아래로** 놓는다. 그러면 네 개의
%  연결이 모두 가로로 곧게 지나가고 서로 넘지 않는다. 처음에는 순서를 생각하지
%  않고 놓았더니 배선은 옳은데 그림에서 선 넷이 서로를 넘어가 읽히지 않았다.
%
%      aw_mode            -> 제어 포트
%      Ki e               -> 자리 0   보호 없음
%      clamping           -> 자리 1
%      back-calculation   -> 자리 2
%
%  The blocks are placed top to bottom in the port order of the scheme switch,
%  so that all four connections run straight across without crossing. Arranged
%  without regard to that order, the wiring was still correct but the four
%  lines climbed over one another and the drawing could not be read.
set_param([aw_blk '/e'],     'Position',[ 60  80  90 100]);
set_param([aw_blk '/X_cmd'], 'Position',[ 60 460  90 480]);
set_param([aw_blk '/X_sat'], 'Position',[ 60 520  90 540]);
set_param([aw_blk '/di'],    'Position',[740 250 770 270]);

%  ---- 모든 방식이 공유하는 둘 / the two every scheme shares ---------------
%  Ki 는 상수이므로 Constant 와 Product 대신 Gain 하나면 된다.
%  Ki is a constant, so one Gain does the work of a Constant and a Product.
add_block('simulink/Sources/Constant', [aw_blk '/aw_mode'], 'Value','aw_mode', ...
          'Position',[380 60 460 90]);
add_block('simulink/Math Operations/Gain', [aw_blk '/Ki e'], 'Gain','Ki', ...
          'Position',[200 130 260 170]);
add_sum(aw_blk, 'sat', '+-', [300 490]);

%  ---- 방식 하나에 상자 하나 / one box per scheme --------------------------
aw_clamping(aw_blk, [380 200 520 300]);
aw_backcalc(aw_blk, [380 340 520 440]);

%  aw_mode 는 0, 1, 2 이므로 0 기준 인덱싱으로 둔다. 0 번 자리는 보호가 없는
%  경우이고, 그때 적분기에 들어가는 것은 Ki e 그대로이므로 블록이 따로 필요 없다.
%  aw_mode takes the values 0, 1 and 2, so the switch uses zero-based indexing.
%  Entry 0 is the unprotected case, in which what reaches the integrator is Ki e
%  itself, so it needs no block of its own.
add_block('simulink/Signal Routing/Multiport Switch', [aw_blk '/scheme'], ...
          'DataPortOrder','Zero-based contiguous', 'Inputs','3', ...
          'Position',[620 60 660 460]);

Lw = @(src, sp, dst, dp, x) lane_line(aw_blk, src, sp, dst, dp, x);
Lw('e',     1, 'Ki e', 1, 170);
Lw('X_cmd', 1, 'sat',  1, 150);
q = port_xy(aw_blk, 'sat', 'Inport', 2);
Lw('X_sat', 1, 'sat',  2, q(1));

Lw('e',    1, 'clamping', 2, 320);
Lw('Ki e', 1, 'clamping', 1, 330);
Lw('Ki e', 1, 'back-calculation', 1, 340);
Lw('sat',  1, 'clamping', 3, 350);
Lw('sat',  1, 'back-calculation', 2, 360);

Lw('aw_mode',          1, 'scheme', 1, 560);
Lw('Ki e',             1, 'scheme', 2, 570);
Lw('clamping',         1, 'scheme', 3, 580);
Lw('back-calculation', 1, 'scheme', 4, 590);
add_line(aw_blk, 'scheme/1', 'di/1', 'autorouting','on');

note(aw_blk, [60 590 900 680], strjoin({ ...
 'WINDUP IS NOT A FAULT OF THE INTEGRATOR.'
 'It is what an integrator does when it is asked to close a loop that the actuator has already opened.'
 'sat = X_cmd - X_sat is the part of the demand that never reached the plant. It is zero whenever'
 'nothing was refused, so none of the three schemes does anything at all until the actuator saturates.'}, newline));

%  aw_mode · Ki · K_aw 를 넣어 주던 Constant 블록 셋은 2026-09-16 에 없앴다.
%  상수이므로 anti-windup 안에 두는 편이 낫고, 그만큼 이 화면이 조용해진다.
%  The three Constant blocks that used to supply aw_mode, Ki and K_aw were
%  removed on 2026-09-16. They are constants, so they belong inside
%  anti-windup, and this canvas is quieter without them.

%  The integrator on the row of the anti-windup output that feeds it.
q = port_xy(c, 'anti-windup', 'Outport', 1);
add_block('simulink/Continuous/Integrator', [c '/I state'], ...
          'InitialCondition','0', 'Position',[600 q(2)-15 630 q(2)+15]);

%  미분항은 일반형으로 둔다. 설정값 가중 c_d 를 두고 (c_d*u_d - u) 를 미분한다.
%  c_d = 0 이면 측정값을 미분하는 형태, c_d = 1 이면 오차를 미분하는 교과서
%  형태가 되며, 둘은 특수한 경우일 뿐 서로 다른 제어기가 아니다. 예전에는
%  u 만 미분하고 합산기에서 부호를 뒤집었는데, 그러면 u_d 가 시간에 따라 변할 때
%  왜 마이너스인지 설명할 수 없었다 (§3-4).
%
%  The derivative is built in its general form: a setpoint weight c_d is
%  introduced and (c_d*u_d - u) is differentiated. c_d = 0 gives the
%  derivative on the measurement and c_d = 1 the textbook derivative on the
%  error; neither is a separate controller. The earlier arrangement
%  differentiated u alone and reversed the sign at the summing junction, which
%  left no way to say what the minus meant once u_d began to move (§3-4).
add_block('simulink/Math Operations/Gain', [c '/c_d'], 'Gain','c_d', ...
          'Position',[260 475 310 511]);
add_sum(c, 'D input', '+-', [380 483]);
add_block('simulink/Continuous/Transfer Fcn', [c '/D filter'], ...
          'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]', ...
          'Position',[470 475 530 511]);

%  세 항이 모두 + 로 들어온다. 부호는 D input 합산기 안에 있다.
%  All three terms now enter with a plus: the sign lives inside D input.
add_sum(c, 'X_pid', '+++', [690 170]);

%  loop_closed = 0 disconnects the controller and applies a constant force, so
%  the same model performs the open-loop identification of section C.
add_block('simulink/Sources/Constant', [c '/loop_closed'], ...
          'Value','loop_closed', 'Position',[860 420 915 450]);
add_block('simulink/Sources/Constant', [c '/X_open'], ...
          'Value','X_open', 'Position',[860 480 915 510]);
%  ---- the same controller, written by Simulink ------------------------
%  Simulink ships a PID Controller block that does everything the blue blocks
%  above do: three terms, a filtered derivative, an output limit and the same
%  two anti-windup schemes. It is one block instead of nine.
%
%  Both are in the model and `pid_mode` chooses between them, because a
%  student who has only ever used the block does not know what is inside it,
%  and a student who has only ever built it by hand does not know that the
%  block exists. Section G runs both and compares them.
%
%  Two differences are real and are NOT hidden:
%    - the block differentiates its INPUT, which here is the error. The
%      hand-built path differentiates the measurement. With Kd = 0 the two
%      agree exactly; with Kd > 0 they do not, and section G measures it
%    - the block saturates its own output at [X_lo, X_hi], which are the same
%      limits the allocation imposes, so the two saturations coincide
add_block('simulink/Continuous/PID Controller', [c '/PID block'], ...
          'Controller','PID', 'P','Kp', 'I','Ki', 'D','Kd', 'N','Nf', ...
          'LimitOutput','on', ...
          'UpperSaturationLimit','X_hi', 'LowerSaturationLimit','X_lo', ...
          'AntiWindupMode','back-calculation', 'Kb','K_aw', ...
          'Position',[380 580 500 670]);
set_param([c '/PID block'], 'BackgroundColor', gnc_colour('controller'));

add_block('simulink/Sources/Constant', [c '/pid_mode'], ...
          'Value','pid_mode', 'Position',[690 700 745 730]);
add_block('simulink/Signal Routing/Switch', [c '/hand or block'], ...
          'Threshold','0.5', 'Position',[790 150 820 620]);

add_block('simulink/Signal Routing/Switch', [c '/open or closed'], ...
          'Threshold','0.5', 'Position',[950 160 980 500]);

set_param([c '/u_d'],   'Position',[ 50  83  80  97]);
set_param([c '/x'],     'Position',[ 50 143  80 157]);
set_param([c '/X_sat'], 'Position',[ 50 293  80 307]);
set_param([c '/X_cmd'], 'Position',[1060 293 1090 307]);
%  The integrator state is logged, not used, so it leaves along the top where
%  it crosses nothing. Taken straight across it would be drawn through both
%  switches.
set_param([c '/I'],     'Position',[1060  40 1090  54]);

Lc = @(x,y) add_line(c, x, y, 'autorouting','on');
Lc('x/1','u/1');
Lc('u_d/1','error/1');   Lc('u/1','error/2');
Lc('error/1','Kp/1');
Lc('error/1','anti-windup/1');

%  X_sat 은 이 서브시스템 바깥에서 들어오는 신호이고 그것만 공급하는 인포트가
%  있으므로, 그 인포트를 해당 포트의 행으로 옮겨 선 하나가 곧게 지나가게 한다.
%  포트 1 과 2 는 도면의 다른 곳에서 오므로 위아래로 따로 배선한다.
%  X_sat arrives from outside this subsystem through an inport that feeds
%  nothing else, so the inport is moved onto that port's row and the line
%  becomes straight. Ports 1 and 2 come from elsewhere and are wired
%  separately, above and below.
row_feed(c, 'anti-windup', {'', '', 'X_sat'});

lane_line(c, 'anti-windup', 1, 'I state', 1, 570);

%  미분 경로 : u_d 에 c_d 를 곱한 것에서 u 를 빼고, 그 차이를 미분한다.
%  The derivative path: u_d weighted by c_d, less u, and that difference
%  differentiated.
Lc('u_d/1','c_d/1');
%  세로 구간을 각각 다른 x 에 둔다. 335 는 포화된 지령이 되돌아오는 선이 쓴다.
%  Each vertical run gets its own x; 335 belongs to the saturated command
%  coming back round the bottom.
lane_line(c, 'c_d', 1, 'D input', 1, 350);
lane_line(c, 'u',   1, 'D input', 2, 360);
Lc('D input/1','D filter/1');

lane_line(c, 'Kp',       1, 'X_pid', 1, 645);
lane_line(c, 'I state',  1, 'X_pid', 2, 660);
lane_line(c, 'D filter', 1, 'X_pid', 3, 560);

Lc('error/1','PID block/1');

%  The two switches choose between whole paths. Only their SELECTOR constants
%  may be moved onto a row - row_feed moves the blocks it is given, and moving
%  the PID block would drag it out of the column it belongs to and on top of
%  the hand-built path it is there to be compared with.
row_feed(c, 'hand or block',  {'','pid_mode',''});
lane_line(c, 'PID block', 1, 'hand or block', 1, 755);
lane_line(c, 'X_pid',     1, 'hand or block', 3, 770);
row_feed(c, 'open or closed', {'','loop_closed','X_open'});
lane_line(c, 'hand or block', 1, 'open or closed', 1, 930);
Lc('open or closed/1','X_cmd/1');
lane_line(c, 'I state', 1, 'I', 1, 745);

%  THE ONE LINE THAT RUNS RIGHT TO LEFT. The saturated command goes back to
%  the integrator to tell it the loop has been opened, and that is the whole
%  subject of 2-6. It is taken round the bottom of the subsystem on a height
%  of its own rather than back across the middle of it, where it would be
%  drawn along the lines it is meant to be distinguished from.
qa = port_xy(c, 'open or closed', 'Outport', 1);
qb = port_xy(c, 'anti-windup',    'Inport',  2);
%  세로 구간을 x = 335 에 둔다. 350 은 u 에서 D input 으로 내려가는 선이 쓴다.
%  The vertical run is placed at x = 335: the line from u down to D input uses
%  350, and two different signals on one column cannot be told apart.
add_line(c, [qa; 1020 qa(2); 1020 780; 335 780; 335 qb(2); qb]);

%% =====================================================================
%  3. Control allocation
%  =====================================================================
a = add_subsys(m, 'Control allocation', P.allocation, ...
               {'X_cmd'}, {'n','X_sat','n1'}, gnc_colour('allocation'));

blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[260 60 430 270]);
set_mlfcn(blk, { ...
'function [n, X_sat] = allocation(X_cmd, k_pos, k_neg, n_max, n_min)'
'%#codegen'
'% Demanded surge force to shaft speed, and back again.'
'%'
'% The demand is split equally between the two propellers, because nothing in'
'% a pure surge command distinguishes them. Inverting T = k n|n| gives'
'%'
'%     n = sign(T) sqrt(|T| / k)'
'%'
'% X_sat is what the propellers ACTUALLY produce after saturation. Without it'
'% the controller cannot know that the loop has been opened by the actuator,'
'% and no anti-windup scheme can work.'
'T = X_cmd / 2;'
'if T >= 0'
'    ni =  sqrt( T / k_pos);'
'else'
'    ni = -sqrt(-T / k_neg);'
'end'
'ni = min(max(ni, n_min), n_max);'
'n = [ni; ni];'
'if ni >= 0'
'    X_sat = 2 * k_pos * ni * abs(ni);'
'else'
'    X_sat = 2 * k_neg * ni * abs(ni);'
'end'
'end'}, 'n', '[2 1]');

for i = 1:4
    add_block('simulink/Sources/Constant', [a '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 95+50*i 165 121+50*i]);
end
add_block('simulink/Signal Routing/Selector', [a '/first shaft'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','1', ...
          'InputPortWidth','2', 'Position',[510 260 560 280]);

set_param([a '/X_cmd'], 'Position',[ 60  95  90 115]);
set_param([a '/n'],     'Position',[630 100 660 120]);
set_param([a '/X_sat'], 'Position',[630 185 660 205]);
set_param([a '/n1'],    'Position',[630 260 660 280]);

La = @(x,y) add_line(a, x, y, 'autorouting','on');
La('X_cmd/1','allocation/1');
for i = 1:4, La([KK{i} '/1'], sprintf('allocation/%d', i+1)); end
La('allocation/1','n/1');
La('allocation/1','first shaft/1');
La('first shaft/1','n1/1');
La('allocation/2','X_sat/1');

%% =====================================================================
%  4. Otter USV
%  =====================================================================
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% =====================================================================
%  5. Measurements
%  =====================================================================
add_measurement(m, P.measurement, 'W03', {'u_d','X_cmd','X_sat','I','n1'}, ...
                struct('dash', true, 'weekName', 'W03  command and force'));

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Speed command/1',     'Surge controller/1');
L('Otter USV/1',         'Surge controller/2');
L('Control allocation/2','Surge controller/3');

L('Surge controller/1',  'Control allocation/1');
L('Control allocation/1','Otter USV/1');

L('Otter USV/1',         'Measurements/1');
L('Speed command/1',     'Measurements/2');
L('Surge controller/1',  'Measurements/3');
L('Control allocation/2','Measurements/4');
L('Surge controller/2',  'Measurements/5');
L('Control allocation/3','Measurements/6');

%% ---- what the model is for ---------------------------------------------
note(m, [40 340 880 720], strjoin({ ...
'WEEK 3  -  SURGE SPEED CONTROL'
''
'The first closed loop of the course. The surge axis is a first-order,'
'TYPE 0 plant:  u/X = K_u / (T_u s + 1),  K_u = 0.012894, T_u = 1.1025 s.'
''
'FOUR THINGS TO TRY'
''
'1  IDENTIFY THE PLANT.  loop_closed = 0, X_open = 100. Read the settled u'
'   and the 63 per cent time. They are K_u X_open and T_u.'
''
'2  PROPORTIONAL ONLY.  Ki = 0, Kd = 0. A type 0 plant under proportional'
'   control ALWAYS leaves a steady-state error:'
''
'        u_ss / u_d = K_p K_u / (1 + K_p K_u).'
''
'   Kp = 100 leaves 44 per cent. Kp = 2000 leaves 3.7 per cent and still'
'   does not arrive. Raising the gain does not remove the error.'
''
'3  ADD THE INTEGRATOR.  Ki = 192.38 with Kp = 102 places the closed-loop'
'   poles at zeta = 0.7, wn = 1.5 rad/s. The error goes to zero exactly.'
'   The overshoot does NOT match the textbook figure for zeta = 0.7,'
'   because a PI controller also adds a ZERO at s = -Ki/Kp.'
''
'4  SATURATE IT.  u_d1 = 3.5 m/s is not reachable: full ahead gives'
'   exactly 3.0864 m/s. Set t_dn = 40, u_d2 = 1.5, T_final = 90 and'
'   compare aw_mode = 0, 1, 2.'
''
'X_sat is the second feedback path, and it is the one that gets missed.'
'Without knowing what the propellers ACTUALLY delivered, no anti-windup'
'scheme can tell that the loop has been opened by the actuator.'}, newline));

%% ---- plot when the run finishes ----------------------------------------
set_param(m, 'StopFcn', 'W03_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

%  Every block gets the size MSS uses. Measured from the MSS demo models, not
%  invented - see _tools/mss_style.m. Applied last so it catches every block
%  regardless of which helper created it.
mss_style(m);

save_system(m, out);

%  The block diagram belongs to the builder: it changes when the model changes
%  and not when a gain does. Exporting it here keeps it in step with the model.
export_diagram(m, fullfile(here, 'img'));

%  anti-windup 서브시스템도 따로 뽑는다. §3-6 이 그 화면을 싣기 때문이다.
%  최상위 도면만으로는 세 방식이 어떻게 나뉘어 있는지 보이지 않고, 그것이 그
%  절의 주제이므로 그림이 있어야 한다.
%  The anti-windup subsystem is exported as well, because §3-6 prints that
%  canvas: the top-level diagram cannot show how the three schemes are divided,
%  and that division is the subject of the section.
print(['-s' aw_blk], '-dpng', '-r120', ...
      fullfile(here, 'img', 'W03_antiwindup_inside.png'));

close_system(m, 0);

fprintf('  built  %s\n', out);
end

% -------------------------------------------------------------------------
function note(m, pos, txt)
h = Simulink.Annotation([m '/note']);
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end

% -------------------------------------------------------------------------
function sub = aw_clamping(parent, pos)
%AW_CLAMPING  클램핑 — 포화되어 있고 오차가 그 포화를 더 깊게 밀고 있는 동안
%             적분을 멈춘다.
%             Clamping: stop integrating while the actuator is saturated and
%             the error is driving it further in.
%
%  얼릴 조건은 둘이고, 둘 다 성립해야 얼린다.
%    ① 실제로 포화되어 있는가            |sat| > 1e-9
%    ② 오차가 그 포화를 더 깊게 미는가    e 와 sat 의 부호가 같은가, 즉 e*sat > 0
%
%  ②가 필요한 이유는, 포화되어 있더라도 오차가 반대 방향이면 적분기는 빠져나오는
%  방향으로 움직이고 있기 때문이다. 그때까지 얼리면 영영 회복하지 못한다.
%
%  There are two conditions and both must hold:
%    (1) the actuator really is saturated,      |sat| > 1e-9
%    (2) the error drives it further in,        e and sat of one sign, e*sat > 0
%  The second is needed because a saturated actuator whose error has reversed
%  is already on its way out; freezing then would prevent it ever recovering.
sub = add_subsys(parent, 'clamping', pos, {'Ki e','e','sat'}, {'di'});

set_param([sub '/Ki e'], 'Position',[ 40  60  70  80]);
set_param([sub '/e'],    'Position',[ 40 140  70 160]);
set_param([sub '/sat'],  'Position',[ 40 220  70 240]);
set_param([sub '/di'],   'Position',[660  80 690 100]);

add_block('simulink/Sources/Constant', [sub '/zero'], 'Value','0', ...
          'Position',[160 380 220 410]);
add_block('simulink/Sources/Constant', [sub '/tol'],  'Value','1e-9', ...
          'Position',[160 300 220 330]);

%  ① 포화되어 있는가 / is it saturated
add_block('simulink/Math Operations/Abs', [sub '/|sat|'], ...
          'Position',[160 210 200 250]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
          [sub '/saturated'], 'Operator','>', 'Position',[280 205 320 255]);

%  ② 오차가 더 깊게 미는가 / is the error driving it further in
add_block('simulink/Math Operations/Product', [sub '/e sat'], ...
          'Position',[160 120 200 180]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
          [sub '/driving in'], 'Operator','>', 'Position',[280 115 320 165]);

add_block('simulink/Logic and Bit Operations/Logical Operator', ...
          [sub '/freeze'], 'Operator','AND', 'Position',[400 160 440 210]);

%  얼어붙어 있으면 0 을, 아니면 Ki e 를 그대로 통과시킨다.
%  Pass zero while frozen, and Ki e otherwise.
add_block('simulink/Signal Routing/Switch', [sub '/hold'], ...
          'Criteria','u2 ~= 0', 'Position',[520 40 560 140]);

L = @(src, sp, dst, dp, x) lane_line(sub, src, sp, dst, dp, x);
L('sat',   1, '|sat|',      1, 120);
L('|sat|', 1, 'saturated',  1, 240);
L('tol',   1, 'saturated',  2, 250);
L('e',     1, 'e sat',      1, 110);
L('sat',   1, 'e sat',      2, 130);
L('e sat', 1, 'driving in', 1, 235);
L('zero',  1, 'driving in', 2, 260);
L('saturated',  1, 'freeze', 1, 360);
L('driving in', 1, 'freeze', 2, 370);
L('zero',   1, 'hold', 1, 480);
L('freeze', 1, 'hold', 2, 490);
L('Ki e',   1, 'hold', 3, 500);
add_line(sub, 'hold/1', 'di/1', 'autorouting','on');

note(sub, [40 470 700 560], strjoin({ ...
 'CLAMPING, AS AN EQUATION'
 '                 0        while  |sat| > 0  and  sign(e) = sign(sat)'
 '    dI/dt  =  {'
 '                 Ki e     otherwise'
 'Integration is suspended, not corrected: I holds whatever value it had reached.'
 'The second condition matters. A saturated actuator whose error has already reversed is on its'
 'way out, and freezing then would stop the integrator from ever discharging.'}, newline));
end

% -------------------------------------------------------------------------
function sub = aw_backcalc(parent, pos)
%AW_BACKCALC  역계산 — 작동기가 거절한 만큼을 적분기로 되돌린다.
%             Back-calculation: feed the part the actuator refused back into
%             the integrator.
%
%      di = Ki e - K_aw sat
%
%  이 항은 적분기를 다음 고정점으로 몰고 간다.
%      I* = X_sat - Kp e + (Ki/K_aw) e
%  그러므로 지령은 한계보다 (Ki/K_aw) e 만큼 위에서 멈추며, 한계와 같아지는 것은
%  K_aw -> 무한대 일 때뿐이다. 클램핑과 다른 점이 바로 이것이다 — 클램핑은 멈추고,
%  역계산은 특정한 값으로 끌고 간다.
%
%  The term drives the integrator to the fixed point above, so the demand
%  settles (Ki/K_aw) e above the limit and equals it only as K_aw goes to
%  infinity. That is what distinguishes it from clamping, which stops the
%  integrator where it stands rather than steering it anywhere.
%
%  Ki = 0 이면 지켜야 할 적분 동작이 없는데, 이 항에는 Ki 가 들어 있지 않으므로
%  그대로 두면 존재하지 않는 적분 동작을 충전한다. 'Ki live' 가 그때 이 상자
%  전체를 건너뛰게 한다.
%  With Ki = 0 there is no integral action to protect, yet this term does not
%  contain Ki and would charge one that is not there. 'Ki live' bypasses the
%  whole box in that case.
sub = add_subsys(parent, 'back-calculation', pos, {'Ki e','sat'}, {'di'});

set_param([sub '/Ki e'], 'Position',[ 40  60  70  80]);
set_param([sub '/sat'],  'Position',[ 40 160  70 180]);
set_param([sub '/di'],   'Position',[600  80 630 100]);

add_block('simulink/Math Operations/Gain', [sub '/K_aw sat'], 'Gain','K_aw', ...
          'Position',[160 150 220 190]);
add_sum(sub, 'sum', '+-', [320 80]);

add_block('simulink/Sources/Constant', [sub '/Ki'],   'Value','Ki', ...
          'Position',[160 280 220 310]);
add_block('simulink/Sources/Constant', [sub '/zero'], 'Value','0', ...
          'Position',[160 340 220 370]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
          [sub '/Ki live'], 'Operator','~=', 'Position',[300 275 340 325]);
add_block('simulink/Signal Routing/Switch', [sub '/gate'], ...
          'Criteria','u2 ~= 0', 'Position',[440 40 480 140]);

L = @(src, sp, dst, dp, x) lane_line(sub, src, sp, dst, dp, x);
L('sat',  1, 'K_aw sat', 1, 120);
L('Ki e', 1, 'sum', 1, 260);
q = port_xy(sub, 'sum', 'Inport', 2);
L('K_aw sat', 1, 'sum', 2, q(1));
L('Ki',   1, 'Ki live', 1, 270);
L('zero', 1, 'Ki live', 2, 280);
L('sum',     1, 'gate', 1, 400);
L('Ki live', 1, 'gate', 2, 410);
L('Ki e',    1, 'gate', 3, 420);
add_line(sub, 'gate/1', 'di/1', 'autorouting','on');

note(sub, [40 430 760 540], strjoin({ ...
 'BACK-CALCULATION, AS AN EQUATION'
 '    dI/dt  =  Ki e  -  K_aw ( X_cmd - X_sat )'
 'The correction is zero while nothing is refused, so the controller is unchanged below the limit.'
 'Above it the term is a negative feedback on the excess with time constant 1/K_aw, which is why'
 'K_aw is a RATE and carries units of 1/s.'
 ''
 'Franklin (8E, Fig 9.22) draws the same law with the gain INSIDE the integral gain,'
 '    dI/dt  =  kI [ e - Ka ( u - u_sat ) ],   so that   K_aw = kI Ka.'
 'His kI = 4 and Ka = 10 are therefore K_aw = 40, and not comparable with a K_aw read off this'
 'canvas until that product is taken.'}, newline));
end
