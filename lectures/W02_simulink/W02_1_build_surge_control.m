function W02_1_build_surge_control()
%BUILD_W02_MODELS  Generate W02_surge_control.slx from code.
%
%   >> W02_1_build_surge_control
%
%   THE SIGNAL CHAIN
%
%   Left to right, in the order used by the MSS demonstration models:
%
%     Speed command --> Surge controller --> Control allocation --> Otter USV --> Measurements
%          u_d                X_cmd                  n                  x
%
%   Two signals travel backwards, and only two:
%
%     x      from the plant to the controller — the measured speed
%     X_sat  from the allocation to the controller — what the propellers
%            actually delivered, which is what every anti-windup scheme needs
%
%   Each stage is a subsystem. The top level shows the chain and the two
%   feedback paths; everything else lives inside a stage.
%
%   Regenerating is safe: any existing W02_surge_control.slx is overwritten.

m    = 'W02_surge_control';
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

%  적분기에 실제로 들어가는 양을, 표준 블록만으로 만든다.
%
%  2026-09-16 이전에는 이 자리가 MATLAB Function 블록 하나였다. 도면은 깔끔했지만
%  세 가지 안티와인드업 방식의 차이가 블록 안에 숨어 있어서, 더블클릭해 코드를
%  읽기 전에는 무엇이 다른지 볼 수 없었다. §2-6 이 설명하는 것이 바로 그 차이이므로,
%  그것만은 도면 위에 있어야 한다. 그래서 Sum·Product·Switch 로 풀어 썼다.
%  수치는 예전 블록과 같아야 하며, verify_w02_antiwindup 이 세 방식 모두에 대해
%  그것을 확인한다.
%
%  Until 2026-09-16 this was a single MATLAB Function block. The diagram was
%  tidier, but the difference between the three anti-windup schemes was hidden
%  inside it and could not be seen without opening the block and reading code.
%  That difference is precisely what §2-6 is about, so it belongs on the
%  canvas. It is therefore assembled here from sums, products and switches.
%  The arithmetic must match the block it replaces, and
%  verify_w02_antiwindup checks that for all three schemes.
%
%  들어가는 식 / the expression being built
%      sat = X_cmd - X_sat          작동기가 거절한 부분 / the part refused
%      mode 0  di = Ki e
%      mode 1  di = 0  while  |sat| > 1e-9  and  e and sat have one sign,
%              otherwise Ki e                        클램핑 / clamping
%      mode 2  di = Ki e - K_aw sat               역계산 / back-calculation
%
%  Ki = 0 이면 보호할 적분기가 없다. 그런데 역계산 항은 Ki 와 무관하므로 그대로
%  두면 존재하지도 않는 적분기를 충전한다. 그래서 'Ki live' 가 그 항을 막는다.
%  With Ki = 0 there is no integrator to protect, yet the back-calculation
%  term does not contain Ki and would charge an integrator that is not there.
%  'Ki live' gates it off.
%  입력은 셋뿐이다. 게인과 모드는 상수이므로 이 안에 둔다. 예전에는 셋을 모두
%  바깥에서 Constant 로 넣어 주었는데, 그러면 최상위 화면에 블록 셋과 선 셋이
%  늘어날 뿐 얻는 것이 없었다.
%  There are three inputs. The gains and the mode are constants, so they live
%  inside. They used to be supplied from outside as Constant blocks, which put
%  three more blocks and three more lines on the parent canvas for nothing.
aw_blk = add_subsys(c, 'anti-windup', [380 150 530 330], ...
                    {'e','X_cmd','X_sat'}, {'di'});

set_param([aw_blk '/e'],     'Position',[ 60  80  90 100]);
set_param([aw_blk '/X_cmd'], 'Position',[ 60 140  90 160]);
set_param([aw_blk '/X_sat'], 'Position',[ 60 200  90 220]);
set_param([aw_blk '/di'],    'Position',[980 290 1010 310]);

%  ---- 이 안에서만 쓰는 상수 / the constants used only here ---------------
add_block('simulink/Sources/Constant', [aw_blk '/Ki'],      'Value','Ki', ...
          'Position',[150 300 200 330]);
add_block('simulink/Sources/Constant', [aw_blk '/K_aw'],    'Value','K_aw', ...
          'Position',[150 360 200 390]);
add_block('simulink/Sources/Constant', [aw_blk '/zero'],    'Value','0', ...
          'Position',[150 440 200 470]);
add_block('simulink/Sources/Constant', [aw_blk '/tol'],     'Value','1e-9', ...
          'Position',[150 500 200 530]);
add_block('simulink/Sources/Constant', [aw_blk '/aw_mode'], 'Value','aw_mode', ...
          'Position',[150 560 210 590]);

%  ---- 무엇이 거절되었는가 / what the actuator refused --------------------
add_sum(aw_blk, 'sat', '+-', [280 180]);

%  ---- 보호가 없을 때 적분기에 들어가는 양 / the unprotected integrand -----
add_block('simulink/Math Operations/Product', [aw_blk '/Ki e'], ...
          'Position',[280 70 320 130]);

%  ---- 역계산 / back-calculation ------------------------------------------
add_block('simulink/Math Operations/Product', [aw_blk '/K_aw sat'], ...
          'Position',[400 150 440 210]);
add_sum(aw_blk, 'back-calculation', '+-', [520 120]);

%  Ki = 0 이면 역계산 항을 통째로 건너뛰고 Ki e 를 그대로 내보낸다. 곱셈이 아니라
%  스위치로 막는데, Relational Operator 의 출력이 boolean 이고 Product 블록이
%  boolean 을 곱하지 않기 때문이며, 스위치가 의도도 더 분명히 드러낸다.
%  With Ki = 0 the back-calculation term is bypassed and Ki e passes through
%  unchanged. The guard is a switch rather than a multiplication because a
%  Relational Operator outputs a boolean and a Product block will not multiply
%  one; the switch also states the intent more plainly.
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
          [aw_blk '/Ki live'], 'Operator','~=', 'Position',[400 290 440 340]);
add_block('simulink/Signal Routing/Switch', [aw_blk '/aw gate'], ...
          'Criteria','u2 ~= 0', 'Position',[600 80 640 180]);

%  ---- 클램핑 / clamping ---------------------------------------------------
%  얼어붙이는 조건 두 가지를 각각 블록으로 만든다.
%    ① 실제로 포화되어 있는가           |sat| > 1e-9
%    ② 오차가 그 포화를 더 깊게 미는가   e 와 sat 의 부호가 같은가, 즉 e*sat > 0
%  Each of the two conditions for freezing is built as its own block:
%    (1) is the actuator actually saturated,  |sat| > 1e-9
%    (2) is the error driving it further in,  e and sat of one sign, e*sat > 0
add_block('simulink/Math Operations/Abs', [aw_blk '/|sat|'], ...
          'Position',[400 380 440 410]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
          [aw_blk '/saturated'], 'Operator','>', 'Position',[520 370 560 420]);
add_block('simulink/Math Operations/Product', [aw_blk '/e sat'], ...
          'Position',[400 620 440 680]);
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
          [aw_blk '/driving in'], 'Operator','>', 'Position',[520 610 560 660]);
add_block('simulink/Logic and Bit Operations/Logical Operator', ...
          [aw_blk '/freeze'], 'Operator','AND', 'Position',[640 490 680 540]);
%  얼어붙어 있으면 0 을, 아니면 Ki e 를 그대로 통과시킨다.
%  Pass zero while frozen, and Ki e otherwise.
add_block('simulink/Signal Routing/Switch', [aw_blk '/clamping'], ...
          'Criteria','u2 ~= 0', 'Position',[740 420 780 520]);

%  ---- 세 방식 중 하나를 고른다 / select one of the three ------------------
%  aw_mode 는 0, 1, 2 이므로 0 기준 인덱싱으로 둔다. 1 을 더하는 블록을 두지 않는다.
%  aw_mode takes the values 0, 1 and 2, so the switch uses zero-based indexing
%  rather than having a block added to shift it by one.
add_block('simulink/Signal Routing/Multiport Switch', [aw_blk '/scheme'], ...
          'DataPortOrder','Zero-based contiguous', 'Inputs','3', ...
          'Position',[860 80 900 520]);

%  ---- 배선 / the wiring ---------------------------------------------------
%  세로로 내려가는 구간마다 서로 다른 x 를 준다. 자동 배선에 맡기면 여러 신호가
%  같은 세로줄을 공유해 도면에서 구별되지 않는다 (check_overlaps 가 그것을 센다).
%  Each vertical run is given an x of its own. Left to autorouting, several
%  signals share one column and become indistinguishable in print, which is
%  what check_overlaps counts.
Lw = @(src, sp, dst, dp, x) lane_line(aw_blk, src, sp, dst, dp, x);
Lw('X_cmd', 1, 'sat', 1, 240);
Lw('X_sat', 1, 'sat', 2, 250);
Lw('e',     1, 'Ki e', 1, 230);
Lw('Ki',    1, 'Ki e', 2, 260);
Lw('K_aw',  1, 'K_aw sat', 1, 360);
Lw('sat',   1, 'K_aw sat', 2, 370);
Lw('Ki e',      1, 'back-calculation', 1, 480);
Lw('K_aw sat',  1, 'back-calculation', 2, 490);
Lw('Ki',   1, 'Ki live', 1, 370);
Lw('zero', 1, 'Ki live', 2, 380);
Lw('back-calculation', 1, 'aw gate', 1, 570);
Lw('Ki live',          1, 'aw gate', 2, 580);
Lw('Ki e',             1, 'aw gate', 3, 560);
Lw('sat',   1, '|sat|', 1, 390);
Lw('|sat|', 1, 'saturated', 1, 480);
Lw('tol',   1, 'saturated', 2, 490);
Lw('e',     1, 'e sat', 1, 230);
Lw('sat',   1, 'e sat', 2, 390);
Lw('e sat', 1, 'driving in', 1, 480);
Lw('zero',  1, 'driving in', 2, 500);
Lw('saturated',  1, 'freeze', 1, 600);
Lw('driving in', 1, 'freeze', 2, 610);
Lw('zero',   1, 'clamping', 1, 700);
Lw('freeze', 1, 'clamping', 2, 710);
Lw('Ki e',   1, 'clamping', 3, 720);
Lw('aw_mode',  1, 'scheme', 1, 830);
Lw('Ki e',     1, 'scheme', 2, 840);
Lw('clamping', 1, 'scheme', 3, 810);
Lw('aw gate',  1, 'scheme', 4, 820);
add_line(aw_blk, 'scheme/1', 'di/1', 'autorouting','on');

note(aw_blk, [150 700 980 800], strjoin({ ...
 'WINDUP IS NOT A FAULT OF THE INTEGRATOR.'
 'It is what an integrator does when it is asked to close a loop that the actuator has already opened.'
 'Every scheme on this canvas works by telling the integrator that the loop was opened. sat = X_cmd - X_sat'
 'is the part of the demand that never reached the plant, and it is zero whenever nothing was refused, so'
 'none of the three schemes does anything at all until the actuator saturates.'}, newline));

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
%  왜 마이너스인지 설명할 수 없었다 (§2-4).
%
%  The derivative is built in its general form: a setpoint weight c_d is
%  introduced and (c_d*u_d - u) is differentiated. c_d = 0 gives the
%  derivative on the measurement and c_d = 1 the textbook derivative on the
%  error; neither is a separate controller. The earlier arrangement
%  differentiated u alone and reversed the sign at the summing junction, which
%  left no way to say what the minus meant once u_d began to move (§2-4).
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
add_measurement(m, P.measurement, 'W02', {'u_d','X_cmd','X_sat','I','n1'}, ...
                struct('dash', true, 'weekName', 'W02  command and force'));

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
'WEEK 2  -  SURGE SPEED CONTROL'
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
set_param(m, 'StopFcn', 'W02_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

%  Every block gets the size MSS uses. Measured from the MSS demo models, not
%  invented - see _tools/mss_style.m. Applied last so it catches every block
%  regardless of which helper created it.
mss_style(m);

save_system(m, out);

%  The block diagram belongs to the builder: it changes when the model changes
%  and not when a gain does. Exporting it here keeps it in step with the model.
export_diagram(m, fullfile(here, 'img'));
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
