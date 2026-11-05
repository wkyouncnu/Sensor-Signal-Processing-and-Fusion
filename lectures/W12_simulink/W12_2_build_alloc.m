%W12_2_BUILD_ALLOC  배분 사슬 모델을 **코드로** 만든다. 법칙은 상수 하나가 고른다.
%                   Build the allocation chain from code; one constant selects
%                   the law.
%
%   실행 / to run
%       cd lectures/W12_simulink
%       W12_2_build_alloc           % W12_alloc_chain.slx 와 img/*.png 를 만든다
%       W12_0_setup                 % 값을 얹는다. 그 다음 Run 을 누른다
%
%   무엇을 만드는가 / what this builds
%       사슬이 넷이다 — **명령 tau_d → 배분 → 플랜트 → 계측**.
%       The chain has four stages: the demand tau_d, the allocation, the hull
%       and the measurement.
%
%       command        X · Y · N 세 Constant 와 **법칙 번호 `law`** 하나.
%                      네 가지 배분법을 파일 넷으로 두지 않고 이 상수 하나로
%                      고른다 (`law = 1 … 4`, `W12_sl_alloc` 의 표)
%                      three Constants for X, Y, N and one for the law number:
%                      the four laws are chosen here, not in four models
%       allocation     `allocate` → `force to input` → 한계 둘 →
%                      `force delivered`. 요구를 여덟 성분으로 나누고, 그것을
%                      회전수와 각으로 바꾸고, 구동장치가 할 수 있는 만큼으로
%                      깎은 **뒤에** 실제로 나온 tau 를 다시 계산한다
%       Otter USV      `otter_tilt4.m`. 깎인 회전수와 각을 받는다
%       Measurements   요구한 tau 와 실제로 나온 tau 를 한 Scope 에 겹쳐 그린다
%
%   왜 실제 tau 를 다시 계산하는가 / why the delivered tau is recomputed
%       배분기는 요구를 **그대로** 낼 수 있다고 가정하고 푼다. 그러나 회전수
%       포화와 서보 각 포화가 그 뒤에 있으므로, 배가 실제로 받은 힘은 요구와
%       다를 수 있다. 그 차이가 이 주차의 결과이고, 그래서 깎인 값에서 다시
%       tau = B f 를 계산해 요구와 함께 기록한다.
%       The allocator solves as if the demand could be delivered exactly, but
%       the shaft and servo saturations come after it. The difference is this
%       week's result, so tau = B f is recomputed from the clipped values and
%       logged next to the demand.
%
%   절 스크립트는 따로다 / the section scripts are elsewhere
%       표와 그림은 `W12_CA(8) … W12_CA(12)` 가 찍는다. 이 모델은 같은 네 법칙을
%       **연속시간 사슬 안에서** 돌려 보는 자리다.
%
%   See also W12_0_SETUP, W12_CA, W12_SL_ALLOC, W12_ALLOC, W12_PLOT_CA,
%            OTTER_TILT4, ADD_OTTER_PLANT, GNC_CHAIN.

m    = 'W12_alloc_chain';
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
             'StartTime', '0', 'StopTime', 'T_final');

P = gnc_chain({'command', 'allocation', 'plant', 'measurement'}, ...
              'Y', 120, 'Pitch', 300, ...
              'Height', struct('allocation', 320, 'plant', 162, 'measurement', 220), ...
              'Width',  struct('allocation', 170, 'plant', 130, 'measurement', 150));

% ---- command: 요구한 힘과 법칙 번호 / the demand and the law number -------
%  X · Y · N 은 제어기가 낼 것을 손으로 적은 것이다. 12주차는 제어기를 넣지
%  않고 배분만 본다 / the three Constants stand in for a controller
nm = {'X cmd', 'Y cmd', 'N cmd'};
for i = 1:3
    add_block('simulink/Sources/Constant', [m '/' nm{i}], ...
              'Value', sprintf('tau_cmd(%d)', i), ...
              'Position', [P.command(1) 120+52*(i-1) ...
                           P.command(1)+55 150+52*(i-1)]);
end
add_block('simulink/Signal Routing/Mux', [m '/tau d'], ...
          'Inputs', '3', 'DisplayOption', 'bar', 'Position', [200 120 205 264]);

add_block('simulink/Sources/Constant', [m '/law'], 'Value', 'law', ...
          'Position', [P.command(1) 360 P.command(1)+55 390]);

% ---- allocation ----------------------------------------------------------
sa = add_subsys(m, 'allocation', P.allocation, {'tau d', 'law'}, ...
                {'n', 'delta', 'tau act'}, gnc_colour('allocation'));

set_param([sa '/tau d'],   'Position', [ 40 130  70 150]);
set_param([sa '/law'],     'Position', [ 40 230  70 250]);
set_param([sa '/n'],       'Position', [900 100 930 120]);
set_param([sa '/delta'],   'Position', [900 300 930 320]);
set_param([sa '/tau act'], 'Position', [900 200 930 220]);

%  (1) 요구를 여덟 성분으로 / the demand into eight components
alc = [sa '/allocate'];
add_block('simulink/User-Defined Functions/MATLAB Function', alc, ...
          'Position', [150 110 290 270]);
set_mlfcn(alc, { ...
'function f = allocate(tau_d, law, B_alloc, W_alloc, alpha_lim, Q_tau, eps_reg, T_pos, T_neg, n_chord)'
'% Split one demand tau_d = [X; Y; N] into the eight components'
'%'
'%     f = [f_x1; f_y1; f_x2; f_y2; f_x3; f_y3; f_x4; f_y4]     B f = tau'
'%'
'% The law is selected by the number `law` on the canvas, not by which model'
'% is open:'
'%'
'%     1  minimum norm                     12-8'
'%     2  weighted minimum norm            12-9'
'%     3  weighted, folded onto the limit   12-10'
'%     4  both limits as constraints        12-10, 12-12'
'%'
'% The laws themselves are in W12_alloc, which is a plain MATLAB function and'
'% is not compiled for this block: quadprog and lsqlin have no code generation'
'% support. coder.extrinsic says so, and the width of f is declared below'
'% because Simulink cannot infer the width of what an extrinsic call returns.'
'coder.extrinsic(''W12_sl_alloc'');'
'f = zeros(8,1);'
'f = W12_sl_alloc(tau_d, law, B_alloc, W_alloc, alpha_lim, Q_tau, eps_reg, T_pos, T_neg, n_chord);'
'end'}, 'f', '[8 1]');
mlfcn_params(alc, {'B_alloc', 'W_alloc', 'alpha_lim', 'Q_tau', 'eps_reg', ...
                   'T_pos', 'T_neg', 'n_chord'});

%  (2) 여덟 성분을 여덟 명령으로 / eight components into eight commands
f2i = [sa '/force to input'];
add_block('simulink/User-Defined Functions/MATLAB Function', f2i, ...
          'Position', [370 110 520 270]);
set_mlfcn(f2i, { ...
'function [n, delta] = force2input(f, k_pos, k_neg)'
'% Eight force components -> four shaft speeds and four tilt angles.'
'%'
'%     sigma_i = sign(f_xi)                       which way the unit pushes'
'%     T_i     = sigma_i |f_i|                    signed thrust      [N]'
'%     delta_i = atan2(sigma_i f_yi, sigma_i f_xi)      tilt angle   [rad]'
'%     n_i     = sign(T_i) sqrt(|T_i| / k_i)      shaft speed    [rad/s]'
'%'
'% Multiplying BOTH arguments of atan2 by sigma_i turns the direction through'
'% exactly pi, and because sigma_i f_xi >= 0 the result always lands in'
'% [-pi/2, +pi/2]. That is what keeps the angle reachable: a unit pushing'
'% astern comes out as negative thrust at a small angle instead of positive'
'% thrust at 180 deg, which no servo limited to +-45 deg could hold.'
'fx = f(1:2:7);'
'fy = f(2:2:8);'
's  = sign(fx);'
's(s == 0) = 1;      % a unit with no surge component is left pointing abeam'
''
'T     = s .* hypot(fx, fy);'
'delta = atan2(s.*fy, s.*fx);'
''
'% The coefficient depends on the sign because a propeller pushing astern is'
'% less efficient than the same propeller pushing ahead.'
'k = k_pos*double(T >= 0) + k_neg*double(T < 0);'
'n = sign(T) .* sqrt(abs(T) ./ k);'
'end'}, 'n', '[4 1]');
mlfcn_params(f2i, {'k_pos', 'k_neg'});

%  (3) 구동장치의 한계 / what the actuator can do
add_block('simulink/Discontinuities/Saturation', [sa '/shaft limit'], ...
          'UpperLimit', 'n_max', 'LowerLimit', 'n_min', ...
          'Position', [580  80 640 140]);
add_block('simulink/Discontinuities/Saturation', [sa '/servo limit'], ...
          'UpperLimit', 'alpha_lim', 'LowerLimit', '-alpha_lim', ...
          'Position', [580 280 640 340]);

%  (4) 깎인 값에서 실제로 나온 tau / the tau the hull actually receives
dlv = [sa '/force delivered'];
add_block('simulink/User-Defined Functions/MATLAB Function', dlv, ...
          'Position', [700 160 840 260]);
set_mlfcn(dlv, { ...
'function tau = delivered(n, delta, k_pos, k_neg, B_alloc)'
'% Run the actuator model FORWARD, from what the hardware actually got.'
'%'
'%     T_i = k_i n_i |n_i|      f_i = T_i [cos delta_i; sin delta_i]'
'%     tau = B f'
'%'
'% This is the same product otter_tilt4 forms inside the hull, so the Scope'
'% compares the demand with what the hull was given and nothing else.'
'k = k_pos*double(n >= 0) + k_neg*double(n < 0);'
'T = k .* n .* abs(n);'
''
'f = zeros(8,1);'
'f(1:2:7) = T .* cos(delta);'
'f(2:2:8) = T .* sin(delta);'
''
'tau = B_alloc * f;'
'end'}, 'tau', '[3 1]');
mlfcn_params(dlv, {'k_pos', 'k_neg', 'B_alloc'});

row_feed(sa, 'allocate', {'tau d', 'law'});
add_line(sa, 'allocate/1', 'force to input/1');
lane_line(sa, 'force to input', 1, 'shaft limit', 1, 545);
lane_line(sa, 'force to input', 2, 'servo limit', 1, 560);
add_line(sa, 'shaft limit/1', 'n/1');
add_line(sa, 'servo limit/1', 'delta/1');
add_line(sa, 'force delivered/1', 'tau act/1');

%  분기 둘 — 포화 **뒤에서** 갈라져 실제 tau 계산으로 간다
%  two branches, taken AFTER the saturations
elbow(sa, 'shaft limit', 1, 'force delivered', 1, 665);
elbow(sa, 'servo limit', 1, 'force delivered', 2, 680);

a = Simulink.Annotation([sa '/note']);
a.Text = strjoin({ ...
  'Allocation, and the hardware limits that follow it.', ...
  '', ...
  'allocate          one demand tau_d -> eight force components f, by the law', ...
  '                  the constant `law` names. All four laws are in W12_alloc.', ...
  'force to input    f -> four shaft speeds n and four tilt angles delta. The', ...
  '                  thrust sign is taken first, which is what folds every', ...
  '                  angle into [-90, +90] deg before the servo ever sees it.', ...
  'shaft limit       n clipped to [n_min, n_max].', ...
  'servo limit       delta clipped to +-alpha_lim.', ...
  'force delivered   the actuator model run forward from the CLIPPED values,', ...
  '                  so the Scope shows what the hull was given, not what the', ...
  '                  allocator wished for.'}, newline);
a.Position = [40 400 880 540];
a.HorizontalAlignment = 'left';

% ---- plant ---------------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);

% ---- measurement ---------------------------------------------------------
%  `add_measurement` 을 쓰지 않는다 / why not add_measurement
%      그 함수는 앞 여섯 열이 [u v r N E psi] 인 `W12_log` 를 만든다. 이 모델이
%      보는 것은 **요구한 tau 와 실제 tau** 이므로 열이 다르고, 같은 이름으로
%      기록하면 `W12_read` 의 열 해석이 깨진다. 그래서 로그 이름도 `W12ca_log`
%      로 따로 둔다 / this model logs a different set of columns, so it writes
%      a log of its own name rather than breaking the course-wide one
sm = add_subsys(m, 'Measurements', P.measurement, ...
                {'tau d', 'tau act', 'x'}, {}, gnc_colour('measurement'));

add_block('simulink/Signal Routing/Selector', [sm '/u v r'], ...
          'IndexOptions', 'Index vector (dialog)', 'Indices', '[1 2 3]', ...
          'InputPortWidth', '12', 'Position', [150 300 200 340]);
add_block('simulink/Sources/Clock', [sm '/t'], 'Position', [150 400 180 430]);

%  요구와 실제를 한 묶음으로 / the demand and the delivered force, side by side
add_block('simulink/Signal Routing/Mux', [sm '/compare'], ...
          'Inputs', '2', 'DisplayOption', 'bar', 'Position', [280 100 285 220]);
add_block('simulink/Signal Routing/Mux', [sm '/log'], ...
          'Inputs', '3', 'DisplayOption', 'bar', 'Position', [460 340 465 580]);

add_block('simulink/Sinks/Scope', [sm '/tau  demanded and delivered'], ...
          'NumInputPorts', '1', 'Position', [370 140 410 180]);
add_block('simulink/Sinks/To Workspace', [sm '/W12ca log'], ...
          'VariableName', 'W12ca_log', 'SaveFormat', 'Array', ...
          'SampleTime', '-1', 'Position', [560 440 630 480]);

row_feed(sm, 'compare', {'tau d', 'tau act'});
row_feed(sm, 'u v r',   {'x'});
row_feed(sm, 'log',     {'t', '', ''});
lane_line(sm, 'compare', 1, 'tau  demanded and delivered', 1, 330);
lane_line(sm, 'log',     1, 'W12ca log',                   1, 510);

%  로그로 가는 분기 둘. 통로를 서로 다르게 쓴다 / two branches, distinct lanes
elbow(sm, 'compare', 1, 'log', 2, 415);
elbow(sm, 'u v r',   1, 'log', 3, 435);

b = Simulink.Annotation([sm '/note']);
b.Text = strjoin({ ...
  'W12ca_log holds ten columns:  t,  tau_d(3),  tau_act(3),  u v r(3).', ...
  '', ...
  'The Scope draws the demand and the delivered force on one axis, which is', ...
  'the figure of 12-12: wherever the two separate, a limit is active.'}, newline);
b.Position = [40 640 640 740];
b.HorizontalAlignment = 'left';

% ---- wiring at the top level ---------------------------------------------
%  순서가 중요하다 / the order matters
%      Mux 를 allocation 의 포트 높이로 먼저 옮기고, **그 다음에** 상수 셋을
%      Mux 의 새 포트 높이로 옮긴다. 거꾸로 하면 Mux 가 움직이면서 이미 그은
%      선 셋이 꺾인다 / move the Mux first, then the Constants onto where its
%      ports ended up: the other order bends three lines that are already drawn
row_feed(m, 'allocation', {'tau d', 'law'});
row_feed(m, 'tau d',      {'X cmd', 'Y cmd', 'N cmd'});

lane_line(m, 'allocation', 1, 'Otter USV',    1, 545);
lane_line(m, 'allocation', 2, 'Otter USV',    2, 585);
lane_line(m, 'Otter USV',  1, 'Measurements', 3, 860);

%  요구와 실제 tau 는 블록 **밑으로** 돌려 계측으로 보낸다
tap(m, 'tau d',      1, 'Measurements', 1, 250, 560, 900);
tap(m, 'allocation', 3, 'Measurements', 2, 525, 500, 915);

c = Simulink.Annotation([m '/note']);
c.Text = strjoin({ ...
  'W12 stage 2 -- CONTROL ALLOCATION.  One model, four laws.', ...
  '', ...
  'The constant `law` on the left selects the allocation law, so the four', ...
  'laws of 12-8 to 12-12 are compared without opening four models:', ...
  '', ...
  '    law = 1    minimum norm                      f = B''(BB'')\\tau', ...
  '    law = 2    weighted minimum norm             W says what is expensive', ...
  '    law = 3    weighted, then folded onto the servo limit', ...
  '    law = 4    servo limit AND thrust cap as hard constraints', ...
  '', ...
  'X cmd, Y cmd and N cmd stand in for a controller: Week 12 asks only how a', ...
  'demand is split, not where the demand came from. The Scope inside', ...
  'Measurements draws the demand against what the hull actually received.'}, newline);
c.Position = [40 620 1100 800];
c.HorizontalAlignment = 'left';
c.BackgroundColor = 'lightBlue';

% ---- run-time behaviour --------------------------------------------------
set_param(m, 'StopFcn', 'W12_plot_ca;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

set_param(m, 'InitFcn', [ ...
    'addpath(fullfile(fileparts(fileparts(fileparts(' ...
        'get_param(bdroot, ''FileName'')))), ''_tools''), ' ...
        'fileparts(get_param(bdroot, ''FileName''))); ' ...
    'run_alone(''W12'', bdroot);']);

% ---- finish --------------------------------------------------------------
mss_style(m);
compact_layout(m, 60);
straighten_lines(m);
save_system(m, out);

print(['-s' m],  '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
print(['-s' sa], '-dpng', '-r45', fullfile(here, 'img', [m '_alloc.png']));
print(['-s' sm], '-dpng', '-r45', fullfile(here, 'img', [m '_meas.png']));
close_system(m, 0);

load_system(out);
nov = check_overlaps(m);
ndg = check_diagonals(m);
fprintf('\n  %s   overlaps %d   diagonals %d\n\n', m, nov, ndg);
close_system(m, 0);


% =========================================================================
function elbow(sys, src, sp, dst, dp, x)
%ELBOW  한 출력에서 갈라져 세로 통로 하나를 지나 다른 포트로 간다.
%       Branch off one output, through one vertical lane, into another port.
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; x a(2); x b(2); b]);
end

% =========================================================================
function tap(mdl, src, sp, dst, dp, x1, yl, x2)
%TAP  한 출력에서 갈라져 **블록 밑을 돌아** 다른 포트로 간다.
%     Branch off one output and reach another port BELOW the blocks.
a = port_xy(mdl, src, 'Outport', sp);
b = port_xy(mdl, dst, 'Inport',  dp);
add_line(mdl, [a; x1 a(2); x1 yl; x2 yl; x2 b(2); b]);
end
