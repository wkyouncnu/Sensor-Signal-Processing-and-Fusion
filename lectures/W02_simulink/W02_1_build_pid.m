function W02_1_build_pid()
%W02_1_BUILD_PID  2주차 모델 W02_pid.slx 를 코드로 만든다.
%                 Generate the Week 2 model, W02_pid.slx.
%
%   실행 / to run
%       W02_1_build_pid
%
%   강의에서의 위치 / place in the lecture
%       Part 2 절 B 이다. 이 주의 모든 실험이 이 모델 하나를 쓴다. 절 스크립트는
%       모델을 고치지 않고 변수만 바꾸어 돌린다.
%       Section B of Part 2. Every experiment of the week uses this one model;
%       the section scripts change variables, never the model.
%
%   모델의 모양 / what the model looks like
%
%       Setpoint --> PID bank --> Plant bank --> Measurements
%                       ^              |
%                       +---- y_m -----+        (되먹임 선 하나 / one feedback line)
%
%   PID bank 안에는 같은 PID 가 두 줄 있다 / two rows of the same PID
%       1줄 / row 1   Simulink 라이브러리의 PID Controller 블록
%                     the library PID Controller block
%       2줄 / row 2   같은 제어기를 상자 셋으로 손수 조립한 것
%                     the same controller assembled by hand from three boxes:
%                     P, I with anti-windup, D with filter
%
%       두 줄은 같은 목표값, 같은 플랜트, 같은 센서 잡음을 받는다. 그래서 두 줄의
%       결과가 기계 정밀도까지 같으면, 라이브러리 블록 안에서 일어나는 일이
%       강의가 적은 식 그대로라는 뜻이 된다 (절 F).
%       Both rows receive the same setpoint, the same plant and the same sensor
%       noise. If their results agree to machine precision, the library block
%       is doing exactly what the lecture's equations say (section F).
%
%   다시 만들어도 안전하다 / regenerating is safe
%       이미 있는 W02_pid.slx 는 덮어쓴다. 모델을 손으로 고치지 말고 이 파일을
%       고친 뒤 다시 돌린다.
%       An existing W02_pid.slx is overwritten. Edit this file, not the model.

m    = 'W02_pid';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W02_0_setup');          % 블록이 부르는 변수가 있어야 저장된다

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

P = gnc_chain({'command','controller','plant','measurement'}, ...
              'Height', struct('controller',150, 'plant',110, 'measurement',150), ...
              'Y', 110);

%% =====================================================================
%  1. Setpoint — 계단, 또는 부드럽게 한 계단 / a step, or a smoothed step
%  =====================================================================
s = add_subsys(m, 'Setpoint', P.command, {}, {'y_d'}, gnc_colour('command'));
%  블록은 처음부터 MSS 크기로 만든다. mss_style 이 나중에 줄이면 입력이 여럿인
%  Switch 의 포트가 옮겨 가서, 이미 그어 둔 선이 비스듬해진다.
%  Blocks are created at MSS size from the start: if mss_style shrank them
%  later, a multi-input Switch would move its ports and leave the lines
%  already drawn to it slanted.
add_block('simulink/Sources/Step', [s '/step'], ...
          'Time','t_step', 'Before','0', 'After','y_step', ...
          'Position',[70 175 100 205]);
add_block('simulink/Continuous/Transfer Fcn', [s '/smooth'], ...
          'Numerator','[1]', 'Denominator','[ref_Tf 1]', ...
          'Position',[220 52 280 88]);
add_block('simulink/Sources/Constant', [s '/ref_filter'], ...
          'Value','ref_filter', 'Position',[250 115 305 145]);
add_block('simulink/Signal Routing/Switch', [s '/which'], ...
          'Criteria','u2 > Threshold', 'Threshold','0.5', ...
          'Position',[420 115 450 145]);
q = port_xy(s, 'which', 'Inport', 2);  mv(s, 'ref_filter', q(2));
q = port_xy(s, 'which', 'Outport', 1);
set_param([s '/y_d'], 'Position',[520 q(2)-7 550 q(2)+7]);
q1 = port_xy(s, 'which', 'Inport', 1);
q3 = port_xy(s, 'which', 'Inport', 3);
route(s, 'step', 1, 'smooth', 1, [150 190; 150 70]);
route(s, 'smooth', 1, 'which', 1, [380 70; 380 q1(2)]);
route(s, 'ref_filter', 1, 'which', 2, zeros(0,2));
route(s, 'step', 1, 'which', 3, [390 190; 390 q3(2)]);
route(s, 'which', 1, 'y_d', 1, zeros(0,2));
note_at(s, 'what', [60 240 560 330], { ...
'y_d = step                          when ref_filter = 0'
'y_d = step through 1/(ref_Tf s + 1)  when ref_filter = 1'
''
'The smoothed step is what section G uses to remove the'
'derivative kick: a setpoint with no corner has a finite slope.'});

%% =====================================================================
%  2. PID bank — 같은 PID 두 줄 / the same PID twice
%  =====================================================================
c = add_subsys(m, 'PID bank', P.controller, {'y_d','y_m'}, {'tau','terms'}, ...
               gnc_colour('controller'));
ROW = [100 320];                                   % 두 줄의 높이 / the two rows

%  오차는 한 번만 만든다: e = y_d - y_m. y_m 은 두 줄의 측정값을 담은 벡터이고
%  y_d 는 스칼라이므로, 합산점 하나가 두 줄의 오차를 한꺼번에 낸다. 그 벡터를
%  Demux 가 두 줄로 나눈다.
%  The error is formed once: e = y_d - y_m. y_m carries both rows'
%  measurements and y_d is a scalar, so one junction produces both errors
%  and a Demux sends one to each row.
YM = (ROW(1) + ROW(2))/2;
add_sum(c, 'e', '+-', [180 YM]);
set_param([c '/y_d'], 'Position',[40 YM-10 70 YM+10]);
set_param([c '/y_m'], 'Position',[40 YM+80 70 YM+100]);
add_line(c, 'y_d/1','e/1','autorouting','on');
route(c, 'y_m', 1, 'e', 2, [180 YM+90]);
%  두 출력 Demux 의 포트는 높이의 1/4 과 3/4 — 높이를 줄 간격의 두 배로 잡는다.
%  A two-output Demux has its ports at 1/4 and 3/4 of its height.
D2 = ROW(2) - ROW(1);
add_block('simulink/Signal Routing/Demux', [c '/split e'], ...
          'Outputs','2', 'Position',[260 ROW(1)-D2/2 265 ROW(2)+D2/2]);
route(c, 'e', 1, 'split e', 1, zeros(0,2));
set_param([c '/e'], 'NamePlacement','alternate');

%  ---- 1줄: 라이브러리 블록 / row 1: the library block --------------------
add_block('simulink/Continuous/PID Controller', [c '/PID block'], ...
          'Controller','PID', 'Form','Parallel', ...
          'P','Kp', 'I','Ki', 'D','Kd', 'N','Nf', ...
          'LimitOutput','on', ...
          'UpperSaturationLimit','tau_max', 'LowerSaturationLimit','-tau_max', ...
          'AntiWindupMode','back-calculation', 'Kb','Kb', ...
          'Position',[380 ROW(1)-30 500 ROW(1)+30]);
route(c, 'split e', 1, 'PID block', 1, zeros(0,2));

%  ---- 2줄: 손으로 / row 2: by hand ---------------------------------------
hb = add_subsys(c, 'PID by hand', [380 ROW(2)-40 500 ROW(2)+80], ...
                {'e'}, {'tau','I','D'}, gnc_colour('controller'));
build_by_hand(hb);
q = port_xy(c, 'PID by hand', 'Inport', 1);
set_param([c '/PID by hand'], 'Position',[380 ROW(2)-40+(ROW(2)-q(2)) 500 ROW(2)+80+(ROW(2)-q(2))]);
route(c, 'split e', 2, 'PID by hand', 1, zeros(0,2));

%  ---- 모으기 / collect ---------------------------------------------------
%  두 입력 Mux 의 포트는 높이 H 의 1/4 과 3/4 에 있다. 그래서 H 를 두 줄 간격의
%  두 배로 잡으면 두 힘이 곧은 선으로 들어온다.
%  A two-input Mux has its ports at 1/4 and 3/4 of its height H, so H equal
%  to twice the row spacing brings both forces in on straight lines.
p2 = port_xy(c, 'PID by hand', 'Outport', 1);
H  = 2*(p2(2) - ROW(1));
add_block('simulink/Signal Routing/Mux', [c '/collect tau'], ...
          'Inputs','2', 'Position',[700 ROW(1)-H/4 705 ROW(1)+3*H/4]);
route(c, 'PID block', 1, 'collect tau', 1, zeros(0,2));
route(c, 'PID by hand', 1, 'collect tau', 2, zeros(0,2));
q = port_xy(c, 'collect tau', 'Outport', 1);
set_param([c '/tau'], 'Position',[800 q(2)-10 830 q(2)+10]);
route(c, 'collect tau', 1, 'tau', 1, zeros(0,2));

%  적분항과 미분항은 힘을 모으는 Mux 아래로 돌아서 따로 모은다.
%  The integral and derivative terms go round underneath the force Mux.
yb = ROW(1) + 3*H/4 + 50;
add_block('simulink/Signal Routing/Mux', [c '/collect terms'], ...
          'Inputs','2', 'Position',[760 yb-20 765 yb+60]);
pI = port_xy(c, 'PID by hand', 'Outport', 2);
pD = port_xy(c, 'PID by hand', 'Outport', 3);
qI = port_xy(c, 'collect terms', 'Inport', 1);
qD = port_xy(c, 'collect terms', 'Inport', 2);
route(c, 'PID by hand', 2, 'collect terms', 1, [560 pI(2); 560 qI(2)]);
route(c, 'PID by hand', 3, 'collect terms', 2, [580 pD(2); 580 qD(2)]);
q = port_xy(c, 'collect terms', 'Outport', 1);
set_param([c '/terms'], 'Position',[840 q(2)-10 870 q(2)+10]);
route(c, 'collect terms', 1, 'terms', 1, zeros(0,2));

note_at(c, 'what', [40 560 830 700], { ...
'ROW 1  the PID Controller block of the Simulink library'
'ROW 2  the same controller built by hand - open it'
''
'Same gains (Kp Ki Kd Nf), same limit (tau_max), same anti-windup (Kb),'
'same measurement y_m. Section F runs both and compares them: if the'
'two rows agree to machine precision, the block does what the equations say.'});

%% =====================================================================
%  3. Plant bank — 질량-스프링-댐퍼 둘과 센서 / two plants and a sensor
%  =====================================================================
p = add_subsys(m, 'Plant bank', P.plant, {'tau'}, {'y','y_m'}, gnc_colour('plant'));
set_param([p '/tau'], 'Position',[40 190 70 210]);
add_block('simulink/Signal Routing/Demux', [p '/split'], ...
          'Outputs','2', 'Position',[140 120 145 280]);
add_line(p, 'tau/1','split/1','autorouting','on');
add_block('simulink/Signal Routing/Mux', [p '/collect'], ...
          'Inputs','2', 'Position',[430 120 435 280]);
for i = 1:2
    q = port_xy(p, 'split', 'Outport', i);
    add_block('simulink/Continuous/Transfer Fcn', [p '/G' num2str(i)], ...
              'Numerator','[1]', 'Denominator','[pid_m pid_b pid_k]', ...
              'Position',[230 q(2)-25 350 q(2)+25]);
    add_line(p, sprintf('split/%d', i), sprintf('G%d/1', i), 'autorouting','on');
    add_line(p, sprintf('G%d/1', i), sprintf('collect/%d', i), 'autorouting','on');
end
q = port_xy(p, 'collect', 'Outport', 1);
set_param([p '/y'], 'Position',[700 q(2)-10 730 q(2)+10]);
add_line(p, 'collect/1','y/1','autorouting','on');

%  센서: 같은 잡음 한 줄기가 두 줄 모두에 더해진다 — 두 제어기가 같은 것을 본다.
%  The sensor: one noise sequence is added to both rows, so both controllers
%  see exactly the same measurement.
add_block('simulink/Sources/Random Number', [p '/noise'], ...
          'Mean','0', 'Variance','noise_std^2', 'Seed','23341', ...
          'SampleTime','noise_ts', 'Position',[430 330 470 360]);
add_sum(p, 'sensor', '++', [560 q(2)]);  set_param([p '/sensor'], 'NamePlacement','alternate');
set_param([p '/sensor'], 'Position',[550 q(2)+80-10 570 q(2)+80+10]);
add_line(p, 'collect/1','sensor/1','autorouting','on');
add_line(p, 'noise/1','sensor/2','autorouting','on');
q = port_xy(p, 'sensor', 'Outport', 1);
set_param([p '/y_m'], 'Position',[700 q(2)-10 730 q(2)+10]);
add_line(p, 'sensor/1','y_m/1','autorouting','on');
note_at(p, 'what', [40 400 730 500], { ...
'G(s) = 1 / (pid_m s^2 + pid_b s + pid_k),  one copy per row'
'y_m  = y + noise,  noise ~ N(0, noise_std^2) held for noise_ts'});

%% =====================================================================
%  4. Measurements
%  =====================================================================
%  log = [y_d  tau(1:2)  y(1:2)  I  D  y_m(1:2)]   -> W02_read
qq = add_subsys(m, 'Measurements', P.measurement, {'y_d','tau','y','terms','y_m'}, {}, ...
               gnc_colour('measurement'));
add_block('simulink/Signal Routing/Mux', [qq '/log'], ...
          'Inputs','5', 'Position',[260 40 265 400]);
row_feed(qq, 'log', {'y_d','tau','y','terms','y_m'});
add_block('simulink/Sinks/To Workspace', [qq '/W02log'], ...
          'VariableName','W02log', 'SaveFormat','Structure With Time', ...
          'Position',[340 205 440 235]);
add_line(qq, 'log/1','W02log/1','autorouting','on');
q = port_xy(qq, 'log', 'Outport', 1);
set_param([qq '/W02log'], 'Position',[340 q(2)-15 440 q(2)+15]);

add_block('simulink/Signal Routing/Mux', [qq '/show y'], ...
          'Inputs','2', 'Position',[260 -140 265 -40]);
add_block('simulink/Sinks/Scope', [qq '/position'], 'Position',[340 -110 380 -70]);
add_block('simulink/Sinks/Scope', [qq '/force'],    'Position',[340 460 380 500]);
lane_line(qq, 'y_d', 1, 'show y', 1, 150);
lane_line(qq, 'y',   1, 'show y', 2, 170);
add_line(qq, 'show y/1','position/1','autorouting','on');
lane_line(qq, 'tau', 1, 'force', 1, 190);
set_param([qq '/position'], 'Open', 'on');

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('Setpoint/1',   'PID bank/1');
L('Plant bank/2', 'PID bank/2');
L('PID bank/1',   'Plant bank/1');
L('Setpoint/1',   'Measurements/1');
L('PID bank/1',   'Measurements/2');
L('Plant bank/1', 'Measurements/3');
L('PID bank/2',   'Measurements/4');
L('Plant bank/2', 'Measurements/5');

%% ---- what the model is for ---------------------------------------------
note_at(m, 'note', [40 300 900 620], { ...
'WEEK 2  -  PID ON ONE TRANSFER FUNCTION'
''
'No vessel. A mass on a spring with a damper:'
''
'      m y'''' + b y'' + k y = tau        G(s) = 1 / (s^2 + 2 s + 2)'
''
'The controller reads one error, e = y_d - y_m, in three ways and adds them:'
''
'      tau = Kp e  +  Ki * integral(e)  +  Kd * (Nf s / (s + Nf)) e'
'            now      the past             where it is heading'
''
'PID bank holds the same controller twice: the library PID block (row 1)'
'and the same thing built by hand (row 2). Open PID by hand to see it.'
''
'Change Kp, Ki, Kd in the Command Window and press Run again. The'
'position scope opens with the model.'});

set_param(m, 'StopFcn', 'W02_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');
mss_style(m);
save_system(m, out);
export_diagram(m, fullfile(here, 'img'));
export_inside(m, 'PID bank', fullfile(here, 'img', 'W02_pid_bank.png'));
export_inside(m, 'PID bank/PID by hand', fullfile(here, 'img', 'W02_pid_by_hand.png'));
export_inside(m, 'PID bank/PID by hand/D with filter', fullfile(here, 'img', 'W02_d_filter.png'));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %s   (overlapping lines: %d)\n', out, n);
end

% =========================================================================
function build_by_hand(hb)
%  손으로 만든 PID 의 안쪽. 상자 셋이 식의 세 항이다.
%  Inside the hand-built PID. The three boxes are the three terms.
%
%      u     = P + I + D                      (the demand)
%      tau   = sat(u)                         (what the actuator gives)
%      I_dot = Ki e + Kb (tau - u)            (the integrator, with back-calculation)
ROW = [80 200 330];                                % P, I, D 의 높이

set_param([hb '/e'], 'Position',[40 ROW(2)-10 70 ROW(2)+10]);

%  P
bP = add_subsys(hb, 'P', [200 ROW(1)-25 300 ROW(1)+25], {'e'}, {'p'});
add_block('simulink/Math Operations/Gain', [bP '/Kp'], 'Gain','Kp', ...
          'Position',[250 70 300 110]);
set_param([bP '/e'], 'Position',[100 80 130 100]);
set_param([bP '/p'], 'Position',[400 80 430 100]);
add_line(bP, 'e/1','Kp/1','autorouting','on');
add_line(bP, 'Kp/1','p/1','autorouting','on');
note_at(bP, 'what', [100 150 430 190], {'p = Kp e'});

%  I, with back-calculation
bI = add_subsys(hb, 'I with anti-windup', [200 ROW(2)-30 300 ROW(2)+50], ...
                {'e','excess'}, {'i'});
set_param([bI '/e'],      'Position',[60  80  90 100]);
set_param([bI '/excess'], 'Position',[60 180  90 200]);
add_block('simulink/Math Operations/Gain', [bI '/Ki'], 'Gain','Ki', ...
          'Position',[160 70 210 110]);
add_block('simulink/Math Operations/Gain', [bI '/Kb'], 'Gain','Kb', ...
          'Position',[160 170 210 210]);
add_sum(bI, 'into I', '++', [290 90]);  set_param([bI '/into I'], 'NamePlacement','alternate');
add_block('simulink/Continuous/Integrator', [bI '/integrate'], ...
          'InitialCondition','0', 'Position',[350 72 385 108]);
set_param([bI '/i'], 'Position',[470 80 500 100]);
add_line(bI, 'e/1','Ki/1','autorouting','on');
add_line(bI, 'excess/1','Kb/1','autorouting','on');
add_line(bI, 'Ki/1','into I/1','autorouting','on');
add_line(bI, 'Kb/1','into I/2','autorouting','on');
add_line(bI, 'into I/1','integrate/1','autorouting','on');
add_line(bI, 'integrate/1','i/1','autorouting','on');
note_at(bI, 'what', [60 250 520 330], { ...
'i_dot = Ki e + Kb (tau - u)'
''
'excess = tau - u is zero until the actuator saturates. Then it pulls'
'the integrator back. Kb = 0 removes the anti-windup.'});

%  D, filtered (or not)
bD = add_subsys(hb, 'D with filter', [200 ROW(3)-25 300 ROW(3)+25], {'e'}, {'d'});
set_param([bD '/e'], 'Position',[40 80 70 100]);
add_block('simulink/Math Operations/Gain', [bD '/Kd'], 'Gain','Kd', ...
          'Position',[120 70 170 110]);
add_sum(bD, 'minus state', '+-', [230 90]);
add_block('simulink/Math Operations/Gain', [bD '/Nf'], 'Gain','Nf', ...
          'Position',[280 70 330 110]);
%  적분기를 왼쪽으로 돌려 둔다: 입력이 오른쪽, 출력이 왼쪽. 그러면 Nf 뒤에서 갈라져
%  아래로 내려와 되돌아가는 되먹임이 교과서의 그림 그대로 한 바퀴로 보인다.
%  The integrator faces left, input on the right and output on the left, so
%  the loop from Nf back to the junction reads as one turn, as in a textbook.
add_block('simulink/Continuous/Integrator', [bD '/filter state'], ...
          'InitialCondition','0', 'Orientation','left', ...
          'Position',[260 160 295 196]);
add_block('simulink/Continuous/Derivative', [bD '/pure derivative'], ...
          'Position',[280 250 330 290]);
add_block('simulink/Sources/Constant', [bD '/d_filtered'], ...
          'Value','d_filtered', 'Position',[380 165 435 195]);
add_block('simulink/Signal Routing/Switch', [bD '/which'], ...
          'Criteria','u2 > Threshold', 'Threshold','0.5', ...
          'Position',[490 165 520 195]);
q = port_xy(bD, 'which', 'Inport', 2);  mv(bD, 'd_filtered', q(2));
q = port_xy(bD, 'which', 'Outport', 1);
set_param([bD '/d'], 'Position',[600 q(2)-7 630 q(2)+7]);
set_param([bD '/minus state'], 'NamePlacement','alternate');
route(bD, 'e', 1, 'Kd', 1, zeros(0,2));
route(bD, 'Kd', 1, 'minus state', 1, zeros(0,2));
route(bD, 'minus state', 1, 'Nf', 1, zeros(0,2));
q1 = port_xy(bD, 'which', 'Inport', 1);
route(bD, 'Nf', 1, 'which', 1, [440 90; 440 q1(2)]);
qf = port_xy(bD, 'filter state', 'Inport', 1);
route(bD, 'Nf', 1, 'filter state', 1, [360 90; 360 qf(2)]);
qo = port_xy(bD, 'filter state', 'Outport', 1);
route(bD, 'filter state', 1, 'minus state', 2, [230 qo(2)]);
qp = port_xy(bD, 'pure derivative', 'Inport', 1);
route(bD, 'Kd', 1, 'pure derivative', 1, [190 90; 190 qp(2)]);
route(bD, 'd_filtered', 1, 'which', 2, zeros(0,2));
q3 = port_xy(bD, 'which', 'Inport', 3);
qd = port_xy(bD, 'pure derivative', 'Outport', 1);
route(bD, 'pure derivative', 1, 'which', 3, [460 qd(2); 460 q3(2)]);
route(bD, 'which', 1, 'd', 1, zeros(0,2));
note_at(bD, 'what', [40 340 640 440], { ...
'd = Nf (Kd e - x),  x_dot = d        which is   d = Kd (Nf s / (s + Nf)) e'
''
'Below Nf rad/s this differentiates; above it the gain stops growing at Kd Nf.'
'd_filtered = 0 switches to the pure derivative instead (section G).'});

%  I 상자를 옮겨 첫 입력이 e 의 높이에 오게 한다 — e 에서 I 로 가는 선이 곧은 한 도막.
%  Move the I box so that its first input is at the height of e: the line
%  from e to I is then one straight segment.
q = port_xy(hb, 'I with anti-windup', 'Inport', 1);
p = get_param([hb '/I with anti-windup'], 'Position');
set_param([hb '/I with anti-windup'], 'Position', p + [0 ROW(2)-q(2) 0 ROW(2)-q(2)]);

%  e 에서 세 상자로 / from e to the three boxes
route(hb, 'e', 1, 'P', 1,                  [120 ROW(2); 120 ROW(1)]);
route(hb, 'e', 1, 'I with anti-windup', 1, zeros(0,2));
route(hb, 'e', 1, 'D with filter', 1,      [120 ROW(2); 120 ROW(3)]);

%  더하기와 한계 / sum and limit
add_sum(hb, 'p+i', '++', [400 ROW(1)]);
add_sum(hb, 'u', '++', [460 ROW(1)]);
add_block('simulink/Discontinuities/Saturation', [hb '/limit'], ...
          'UpperLimit','tau_max', 'LowerLimit','-tau_max', ...
          'Position',[530 ROW(1)-20 570 ROW(1)+20]);
set_param([hb '/tau'], 'Position',[760 ROW(1)-10 790 ROW(1)+10]);
qi = port_xy(hb, 'I with anti-windup', 'Outport', 1);
route(hb, 'P', 1, 'p+i', 1, zeros(0,2));
route(hb, 'I with anti-windup', 1, 'p+i', 2, [400 qi(2)]);
route(hb, 'D with filter', 1, 'u', 2,        [460 ROW(3)]);
route(hb, 'p+i', 1, 'u', 1, zeros(0,2));
route(hb, 'u', 1, 'limit', 1, zeros(0,2));
route(hb, 'limit', 1, 'tau', 1, zeros(0,2));

%  되감기: excess = tau - u / back-calculation
%  excess 는 아래쪽에 두고, 되감기 선은 맨 아래 y = 500 을 따라 왼쪽으로 간다.
%  모델에서 오른쪽에서 왼쪽으로 가는 선은 이것 하나뿐이다.
%  The excess junction sits low, and the line back to the integrator runs
%  left along y = 500 underneath everything: the one backward line.
add_sum(hb, 'excess', '+-', [560 440]);
route(hb, 'limit', 1, 'excess', 1, [600 ROW(1); 600 400; 520 400; 520 440]);
route(hb, 'u', 1, 'excess', 2,     [500 ROW(1); 500 470; 560 470]);
qe = port_xy(hb, 'I with anti-windup', 'Inport', 2);
route(hb, 'excess', 1, 'I with anti-windup', 2, ...
      [590 440; 590 500; 160 500; 160 qe(2)]);

%  두 항을 밖으로 / the two terms, out for logging
set_param([hb '/I'], 'Position',[760 530 790 550]);
set_param([hb '/D'], 'Position',[760 590 790 610]);
route(hb, 'I with anti-windup', 1, 'I', 1, [330 qi(2); 330 540]);
route(hb, 'D with filter', 1, 'D', 1,      [350 ROW(3); 350 600]);

%  둥근 합산점의 이름은 아래 입력 화살표와 겹치므로 위로 올린다.
%  A round sum's name collides with the arrow entering from below, so it goes on top.
for nm = {'p+i','u','excess'}
    set_param([hb '/' nm{1}], 'NamePlacement','alternate');
end

note_at(hb, 'what', [40 640 790 760], { ...
'u     = p + i + d          what the controller asks for'
'tau   = sat(u)             what the actuator can give, |tau| <= tau_max'
'i_dot = Ki e + Kb (tau - u)   the integrator, told how much was cut off'
''
'Open each box: P, I and D are one term each.'});
end

% -------------------------------------------------------------------------
function mv(sys, blk, yc)
%  블록을 세로로만 옮겨 그 출력 포트가 높이 yc 에 오게 한다.
%  Move a block vertically so that its output port sits at height yc.
p  = get_param([sys '/' blk], 'Position');
q  = port_xy(sys, blk, 'Outport', 1);
dy = yc - q(2);
set_param([sys '/' blk], 'Position', p + [0 dy 0 dy]);
end

function route(sys, src, sp, dst, dp, via)
%  출발 포트에서 도착 포트까지, 지나갈 꺾임점을 직접 준 선 하나.
%  One line from a source port to a destination port through the corner
%  points given. Autorouting chose the same corridor for unrelated lines here,
%  so the corners are written out; nothing is left for the router to decide.
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end

function note_at(sys, name, pos, lines)
h = Simulink.Annotation([sys '/' name]);
h.Text = strjoin(lines, newline);  h.Position = pos;
h.HorizontalAlignment = 'left';  h.BackgroundColor = 'lightBlue';
end

function export_inside(m, sub, file)
%  서브시스템 안쪽 도면도 강의에 싣는다 / the inside of a subsystem, for the notes
print(['-s' m '/' sub], '-dpng', '-r120', file);
end
