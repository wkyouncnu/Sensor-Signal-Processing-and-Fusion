%W07_2_BUILD_ALLOC  배분 사슬 모델을 **코드로** 만든다. 법칙은 상수 하나가 고른다.
%                   Build the allocation chain from code; one constant selects
%                   the law.
%
%   실행 / to run
%       cd lectures/W07_simulink
%       W07_2_build_alloc           % W07_alloc_chain.slx 와 img/*.png 를 만든다
%       W07_0_setup                 % 값을 얹는다. 그 다음 Run 을 누른다
%
%   무엇을 만드는가 / what this builds
%       사슬이 넷이다 — **명령 tau_d → 배분 → 플랜트 → 계측**.
%       The chain has four stages: the demand tau_d, the allocation, the hull
%       and the measurement.
%
%       command        X · Y · N 세 Constant 와 **법칙 번호 `law`** 하나.
%                      네 가지 배분법을 파일 넷으로 두지 않고 이 상수 하나로
%                      고른다 (`law = 1 … 4`)
%                      three Constants for X, Y, N and one for the law number:
%                      the four laws are chosen here, not in four models
%       allocation     법칙 블록 넷 → Multiport Switch → `force to input` →
%                      한계 둘. 요구를 여덟 성분으로 나누고, 그것을 회전수와
%                      각으로 바꾸고, 구동장치가 할 수 있는 만큼으로 깎는다
%       Otter USV      `otter_tilt4.m`. 깎인 회전수와 각을 받고, **실제로 가해진
%                      tau 를 두 번째 출력으로 낸다**
%       Measurements   요구한 tau 와 실제로 나온 tau 를 한 Scope 에 겹쳐 그린다
%
%   법칙 하나에 블록 하나 / one law, one block
%       블록 넷이 나란히 서고 그 위의 Multiport Switch 가 `law` 를 읽어 하나를
%       고른다. 블록 안에서 다른 함수를 부르지 않으므로, 더블클릭한 학생이 보는
%       글자가 그 법칙의 전부다 (사용자 지시, 2026-11-14).
%       Four blocks stand side by side and the Multiport Switch above them reads
%       `law` to pick one. No block calls out to another function, so the script
%       a student sees on double-click is the whole law.
%
%   실제 tau 는 어디서 오는가 / where the delivered tau comes from
%       운동모델이 포화 뒤의 n 과 delta 로 **이미** [X Y N] 을 만든다. 그것을
%       포트로 내보내므로 같은 계산을 되풀이하는 블록이 필요 없다 (사용자 지시,
%       2026-11-14). 배분기는 요구를 그대로 낼 수 있다고 가정하고 풀지만 포화가
%       그 뒤에 있으므로 둘이 다를 수 있고, 그 차이가 이 주차의 결과다.
%       The motion model already forms [X Y N] from the clipped n and delta, so
%       it reports that as a second output and no block outside rebuilds it. The
%       allocator solves as if the demand could be delivered exactly; the
%       difference the saturations open up is this week's result.
%
%   절 스크립트는 따로다 / the section scripts are elsewhere
%       표와 그림은 `W07_alloc_run` 이 찍는다 (§7-8 … §7-12). 이 모델은 같은 네 법칙을
%       **연속시간 사슬 안에서** 돌려 보는 자리다.
%
%   See also W07_0_SETUP, W07_ALLOC_RUN, W07_PLOT_CA, OTTER_TILT4,
%            ADD_OTTER_PLANT, GNC_CHAIN.

m    = 'W07_alloc_chain';
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
%  X · Y · N 은 제어기가 낼 것을 손으로 적은 것이다. 7주차는 제어기를 넣지
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
                {'n', 'delta'}, gnc_colour('allocation'));

set_param([sa '/tau d'], 'Position', [ 40 185  70 215]);
set_param([sa '/law'],   'Position', [ 40  25  70  55]);
set_param([sa '/n'],     'Position', [850  95 880 125]);
set_param([sa '/delta'], 'Position', [850 295 880 325]);

%  (1) 법칙 넷. 블록 하나가 법칙 하나를 처음부터 끝까지 담는다
%      four laws, one block each, each written out in full
law1 = [sa '/law 1  minimum norm'];
add_block('simulink/User-Defined Functions/MATLAB Function', law1, ...
          'Position', [150 90 300 150]);
set_mlfcn(law1, { ...
'function f = law1_minimum_norm(tau_d, B_alloc)'
'% LAW 1 -- minimum norm.  Section 7-8.'
'%'
'%     min f''f    subject to    B f = tau_d        ->    f = B''(B B'')\tau_d'
'%'
'% Eight unknowns against three equations: the demand leaves five directions'
'% free, and this law spends them on the shortest f. Nothing here knows about'
'% the servo limit or the thrust cap, which is what laws 3 and 4 go on to fix.'
'%'
'%     f = [f_x1; f_y1; f_x2; f_y2; f_x3; f_y3; f_x4; f_y4]'
'f = B_alloc'' * ((B_alloc*B_alloc'') \ tau_d);'
'end'}, 'f', '[8 1]');
mlfcn_params(law1, {'B_alloc'});

law2 = [sa '/law 2  weighted minimum norm'];
add_block('simulink/User-Defined Functions/MATLAB Function', law2, ...
          'Position', [150 170 300 230]);
set_mlfcn(law2, { ...
'function f = law2_weighted_minimum_norm(tau_d, B_alloc, W_alloc)'
'% LAW 2 -- weighted minimum norm.  Section 7-9.'
'%'
'%     min f'' W f    subject to    B f = tau_d'
'%     ->    f = W^-1 B'' (B W^-1 B'')^-1 tau_d'
'%'
'% W states what is expensive. With W = diag([1 10 1 10 ...]) the sway'
'% component of a unit costs ten times its surge component, so the solution'
'% leans on the shaft speeds rather than on the tilt angles.'
'Wi = W_alloc \ eye(8);'
'f  = Wi * B_alloc'' * ((B_alloc*Wi*B_alloc'') \ tau_d);'
'end'}, 'f', '[8 1]');
mlfcn_params(law2, {'B_alloc', 'W_alloc'});

law3 = [sa '/law 3  folded onto the limit'];
add_block('simulink/User-Defined Functions/MATLAB Function', law3, ...
          'Position', [150 250 300 310]);
set_mlfcn(law3, { ...
'function f = law3_folded_onto_the_limit(tau_d, B_alloc, W_alloc, alpha_lim)'
'% LAW 3 -- the weighted solution, folded onto the servo limit.  Section 7-10.'
'%'
'% Law 2 can ask for a tilt angle no servo can reach. This law solves law 2'
'% first, then folds each angle back onto [-alpha_lim, +alpha_lim] while'
'% keeping the thrust magnitude of that unit:'
'%'
'%     T_i     = sigma_i |f_i|'
'%     delta_i = atan2(sigma_i f_yi, sigma_i f_xi)'
'%     delta_i <- min(max(delta_i, -alpha_lim), +alpha_lim)'
'%     f_i     <- T_i [cos delta_i ; sin delta_i]'
'%'
'% The fold treats each unit on its own, so the eight components no longer'
'% satisfy B f = tau_d. The error that opens up is the result of 7-10.'
'Wi = W_alloc \ eye(8);'
'f  = Wi * B_alloc'' * ((B_alloc*Wi*B_alloc'') \ tau_d);'
''
'for i = 1:4'
'    fx = f(2*i-1);'
'    fy = f(2*i);'
'    s  = sign(fx);'
'    if s == 0'
'        s = 1;        % a unit with no surge component is left pointing abeam'
'    end'
'    T  = s * hypot(fx, fy);'
'    de = atan2(s*fy, s*fx);'
'    de = min(max(de, -alpha_lim), alpha_lim);'
'    f(2*i-1) = T * cos(de);'
'    f(2*i)   = T * sin(de);'
'end'
'end'}, 'f', '[8 1]');
mlfcn_params(law3, {'B_alloc', 'W_alloc', 'alpha_lim'});

law4 = [sa '/law 4  limits as constraints'];
add_block('simulink/User-Defined Functions/MATLAB Function', law4, ...
          'Position', [150 330 300 390]);
set_mlfcn(law4, { ...
['function f = law4_limits_as_constraints(tau_d, B_alloc, W_alloc, ' ...
 'alpha_lim, Q_tau, eps_reg, T_pos, T_neg)']
'% LAW 4 -- the servo limit AND the thrust cap as hard constraints.  7-12.'
'%'
'% Minimise   ||Q (B f - tau_d)||^2 + eps ||W^(1/2) f||^2'
'% subject to, for every unit i,'
'%'
'%     |f_yi| <= tan(alpha_lim) sigma_i f_xi               the servo limit'
'%     cos(th) x'' + sin(th) y'' <= R cos(alpha_lim/M)       the thrust cap'
'%'
'% written in unit axes x'' = sigma_i f_xi and y'' = sigma_i f_yi. Both are'
'% straight lines once the thrust sign sigma_i of that unit is fixed, so the'
'% problem is a QP: no local minima. The signs are not known in advance, so'
'% all 2^4 = 16 sign combinations are solved and the cheapest feasible one is'
'% kept. tau_d sits in the cost rather than in an equality, so a solution'
'% exists even when the demand cannot be delivered.'
'%'
'% The cap is an arc, which no QP can hold. It is replaced by M = 3 inscribed'
'% chords: neighbouring chords meet exactly on the circle of radius R and'
'% their midpoints sit at cos(15 deg) = 0.966 R, so the polygon never breaks'
'% the cap and is at worst 3.4 per cent conservative.'
'%'
'% lsqlin has no code generation support, so the call is extrinsic and every'
'% output it returns is given a size and a type beforehand.'
'coder.extrinsic(''lsqlin'', ''optimoptions'');'
''
'M = 3;                   % chords per cone, the n_chord of W07_vars'
't = tan(alpha_lim);'
''
'% the whole cost as one least-squares residual,  ||C f - d||'
'C = [Q_tau*B_alloc ; sqrt(eps_reg)*sqrt(W_alloc)];'
'd = [Q_tau*tau_d   ; zeros(8,1)];'
''
'% the fallback, used if no sign combination turns out to be feasible'
'Wi = W_alloc \ eye(8);'
'f  = Wi * B_alloc'' * ((B_alloc*Wi*B_alloc'') \ tau_d);'
''
'opts = optimoptions(''lsqlin'', ''Display'', ''off'');'
'best = inf;'
''
'for p = 0:15'
'    % the four thrust signs of combination p, read off its four bits'
'    sg = zeros(4,1);'
'    for i = 1:4'
'        sg(i) = 1 - 2*mod(floor(p/2^(i-1)), 2);'
'    end'
''
'    A = zeros(4*(2+M), 8);'
'    b = zeros(4*(2+M), 1);'
'    r = 0;'
'    for i = 1:4'
'        s = sg(i);'
'        if s > 0'
'            R = T_pos;'
'        else'
'            R = T_neg;    % written positive, so the cap is a radius'
'        end'
'        r = r + 1;  A(r, 2*i-1) = -t*s;  A(r, 2*i) =  1;'
'        r = r + 1;  A(r, 2*i-1) = -t*s;  A(r, 2*i) = -1;'
'        for j = 1:M'
'            th = -alpha_lim + (j - 0.5)*(2*alpha_lim/M);'
'            r  = r + 1;'
'            A(r, 2*i-1) = s*cos(th);'
'            A(r, 2*i)   = s*sin(th);'
'            b(r)        = R*cos(alpha_lim/M);'
'        end'
'    end'
''
'    x   = zeros(8,1);'
'    cst = 0;'
'    res = zeros(11,1);'
'    ef  = 0;'
'    [x, cst, res, ef] = lsqlin(C, d, A, b, [], [], [], [], [], opts);'
''
'    % a cost is a cost only where the solver reported a solution'
'    if ef > 0 && cst < best'
'        best = cst;'
'        f    = x;'
'    end'
'end'
'end'}, 'f', '[8 1]');
mlfcn_params(law4, {'B_alloc', 'W_alloc', 'alpha_lim', 'Q_tau', 'eps_reg', ...
                    'T_pos', 'T_neg'});

%  (2) 넷 중 하나를 고른다 — 제어 포트가 `law` 다
%      one of the four, chosen by the control port
pick = [sa '/pick the law'];
add_block('simulink/Signal Routing/Multiport Switch', pick, ...
          'Inputs', '4', 'DataPortOrder', 'One-based contiguous', ...
          'Position', [380 70 410 390]);

%  (3) 여덟 성분을 여덟 명령으로 / eight components into eight commands
f2i = [sa '/force to input'];
add_block('simulink/User-Defined Functions/MATLAB Function', f2i, ...
          'Position', [480 150 630 310]);
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

%  (4) 구동장치의 한계 / what the actuator can do
add_block('simulink/Discontinuities/Saturation', [sa '/shaft limit'], ...
          'UpperLimit', 'n_max', 'LowerLimit', 'n_min', ...
          'Position', [690  80 750 140]);
add_block('simulink/Discontinuities/Saturation', [sa '/servo limit'], ...
          'UpperLimit', 'alpha_lim', 'LowerLimit', '-alpha_lim', ...
          'Position', [690 280 750 340]);

%  배선 / the wiring
%      `tau d` 하나가 법칙 블록 넷으로 갈라진다. 같은 신호의 분기이므로 통로를
%      나눠 쓴다. `law` 는 블록들 **위로** 돌아 스위치의 제어 포트로 간다.
%      The one demand branches to all four laws; `law` goes over the top of them
%      into the switch's control port.
add_line(sa, 'tau d/1', 'law 2  weighted minimum norm/1');
elbow(sa, 'tau d', 1, 'law 1  minimum norm',        1, 100);
elbow(sa, 'tau d', 1, 'law 3  folded onto the limit', 1, 120);
elbow(sa, 'tau d', 1, 'law 4  limits as constraints', 1, 140);
elbow(sa, 'law',   1, 'pick the law',                 1, 370);

elbow(sa, 'law 1  minimum norm',          1, 'pick the law', 2, 315);
elbow(sa, 'law 2  weighted minimum norm', 1, 'pick the law', 3, 330);
elbow(sa, 'law 3  folded onto the limit', 1, 'pick the law', 4, 345);
elbow(sa, 'law 4  limits as constraints', 1, 'pick the law', 5, 360);

add_line(sa, 'pick the law/1', 'force to input/1');
lane_line(sa, 'force to input', 1, 'shaft limit', 1, 655);
lane_line(sa, 'force to input', 2, 'servo limit', 1, 670);
add_line(sa, 'shaft limit/1', 'n/1');
add_line(sa, 'servo limit/1', 'delta/1');

a = Simulink.Annotation([sa '/note']);
a.Text = strjoin({ ...
  'Allocation, and the hardware limits that follow it.', ...
  '', ...
  'law 1 ... law 4   one demand tau_d -> eight force components f. Each block', ...
  '                  holds one law in full and calls nothing, so double-click', ...
  '                  the block to read the whole law:', ...
  '', ...
  '                      law 1   minimum norm                        7-8', ...
  '                      law 2   weighted minimum norm               7-9', ...
  '                      law 3   weighted, folded onto the limit     7-10', ...
  '                      law 4   both limits as hard constraints     7-12', ...
  '', ...
  'pick the law      the constant `law` on the canvas selects one of the four.', ...
  'force to input    f -> four shaft speeds n and four tilt angles delta. The', ...
  '                  thrust sign is taken first, which is what folds every', ...
  '                  angle into [-90, +90] deg before the servo ever sees it.', ...
  'shaft limit       n clipped to [n_min, n_max].', ...
  'servo limit       delta clipped to +-alpha_lim.', ...
  '', ...
  'What the hull was actually given is not rebuilt here: the motion model', ...
  'already forms it from the clipped n and delta and reports it on its own', ...
  'second output.'}, newline);
a.Position = [40 430 900 680];
a.HorizontalAlignment = 'left';

% ---- plant ---------------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);

% ---- measurement ---------------------------------------------------------
%  `add_measurement` 을 쓰지 않는다 / why not add_measurement
%      그 함수는 앞 여섯 열이 [u v r N E psi] 인 `W07_log` 를 만든다. 이 모델이
%      보는 것은 **요구한 tau 와 실제 tau** 이므로 열이 다르고, 같은 이름으로
%      기록하면 `W07_openloop_run` 의 열 해석이 깨진다. 그래서 로그 이름도 `W07ca_log`
%      로 따로 둔다 / this model logs a different set of columns, so it writes
%      a log of its own name rather than breaking the course-wide one
%  포트 순서는 플랜트가 정한다 / the plant fixes the port order
%      플랜트의 출력은 1 번이 상태 x, 2 번이 실제 tau 다. 받는 쪽도 그 순서로
%      두면 두 선이 서로 엇갈리지 않는다 / taking them in the same order keeps
%      the two lines from crossing
sm = add_subsys(m, 'Measurements', P.measurement, ...
                {'tau d', 'x', 'tau act'}, {}, gnc_colour('measurement'));

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
add_block('simulink/Sinks/To Workspace', [sm '/W07ca log'], ...
          'VariableName', 'W07ca_log', 'SaveFormat', 'Array', ...
          'SampleTime', '-1', 'Position', [560 440 630 480]);

row_feed(sm, 'compare', {'tau d', 'tau act'});
row_feed(sm, 'u v r',   {'x'});
row_feed(sm, 'log',     {'t', '', ''});
lane_line(sm, 'compare', 1, 'tau  demanded and delivered', 1, 330);
lane_line(sm, 'log',     1, 'W07ca log',                   1, 510);

%  로그로 가는 분기 둘. 통로를 서로 다르게 쓴다 / two branches, distinct lanes
elbow(sm, 'compare', 1, 'log', 2, 415);
elbow(sm, 'u v r',   1, 'log', 3, 435);

b = Simulink.Annotation([sm '/note']);
b.Text = strjoin({ ...
  'W07ca_log holds ten columns:  t,  tau_d(3),  tau_act(3),  u v r(3).', ...
  '', ...
  'The Scope draws the demand and the delivered force on one axis, which is', ...
  'the figure of 7-12: wherever the two separate, a limit is active.'}, newline);
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

%  플랜트가 상태와 **실제로 가해진 tau** 를 함께 낸다 / the hull reports both
lane_line(m, 'Otter USV',  1, 'Measurements', 2, 850);
lane_line(m, 'Otter USV',  2, 'Measurements', 3, 870);

%  요구한 tau 만 블록 **밑으로** 돌려 계측으로 보낸다
tap(m, 'tau d', 1, 'Measurements', 1, 250, 560, 900);

c = Simulink.Annotation([m '/note']);
c.Text = strjoin({ ...
  'W07 stage 2 -- CONTROL ALLOCATION.  One model, four laws.', ...
  '', ...
  'Inside `allocation` each law is a block of its own, and the constant `law`', ...
  'on the left selects one of them. The four laws of 7-8 to 7-12 are therefore', ...
  'compared without opening four models, and each can be read on its own:', ...
  '', ...
  '    law = 1    minimum norm                      f = B''(BB'')\\tau', ...
  '    law = 2    weighted minimum norm             W says what is expensive', ...
  '    law = 3    weighted, then folded onto the servo limit', ...
  '    law = 4    servo limit AND thrust cap as hard constraints', ...
  '', ...
  'X cmd, Y cmd and N cmd stand in for a controller: Week 7 asks only how a', ...
  'demand is split, not where the demand came from. The Scope inside', ...
  'Measurements draws the demand against what the hull actually received.'}, newline);
c.Position = [40 620 1100 800];
c.HorizontalAlignment = 'left';
c.BackgroundColor = 'lightBlue';

% ---- run-time behaviour --------------------------------------------------
set_param(m, 'StopFcn', 'W07_plot_ca;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

set_param(m, 'InitFcn', [ ...
    'addpath(fullfile(fileparts(fileparts(fileparts(' ...
        'get_param(bdroot, ''FileName'')))), ''_tools''), ' ...
        'fileparts(get_param(bdroot, ''FileName''))); ' ...
    'run_alone(''W07'', bdroot);']);

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
