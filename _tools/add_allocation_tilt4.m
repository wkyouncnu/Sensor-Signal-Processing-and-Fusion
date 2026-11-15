function [s, ins] = add_allocation_tilt4(m, pos, laws, logName)
%ADD_ALLOCATION_TILT4  네 틸팅 추진기의 추력 배분 서브시스템을 만든다.
%                      Build the control-allocation subsystem of four tilting units.
%
%   [s, ins] = add_allocation_tilt4(m, pos, laws, logName)
%
%   m        모델 이름 / the model name
%   pos      서브시스템 위치 [l t r b] / the subsystem position
%   laws     실을 법칙 번호 / which laws to include, e.g. 1:4 or 4 (기본 1:4)
%   logName  구동장치 장부의 변수 이름 / the actuator record's variable name,
%            예 'W07ca_act'. 비우면 To Workspace 를 달지 않는다 /
%            empty leaves the To Workspace off
%
%   ins      만들어진 입력 포트 이름 / the input port names created:
%            법칙이 둘 이상이면 {'tau d','law'}, 하나면 {'tau d'} /
%            with more than one law the Multiport Switch needs `law`
%
%   왜 함수인가 / why this is a function
%       같은 배분기를 모델 셋이 쓴다 — §7-8~§7-12 의 비교 모델, 웨이포인트 추종,
%       위치 제어. 복사하면 한쪽만 고쳐진다 (CLAUDE.md §5, standing order §15-34) /
%       three models use the same allocator; a copy would drift.
%
%   한 법칙만 실을 때 / with a single law
%       Multiport Switch 가 사라진다. 스위치는 출력을 고르는 것이고 계산을
%       고르는 것이 아니므로, 법칙 넷을 실으면 넷이 매 스텝 다 돌고 닫힌 루프
%       예제에서는 그것이 전부 낭비다 (§7-11) / the switch selects an output, not a
%       computation: all four blocks run every step, which a closed loop cannot afford.
%
%   근거 / source
%       Fossen Handbook §11.3, MSS, W07 §7-8 ... §7-12.

if nargin < 3 || isempty(laws), laws    = 1:4; end
if nargin < 4,                  logName = '';  end

useSwitch = numel(laws) > 1;

%  ---- 포트 / the ports --------------------------------------------------
ins = {'tau d'};
if useSwitch, ins{end+1} = 'law'; end

s = add_subsys(m, 'allocation', pos, ins, {'n', 'delta'}, ...
               gnc_colour('allocation'));

set_param([s '/tau d'], 'Position', [ 40 185  70 215]);
if useSwitch
    set_param([s '/law'], 'Position', [ 40  25  70  55]);
end
set_param([s '/n'],     'Position', [850  95 880 125]);
set_param([s '/delta'], 'Position', [850 295 880 325]);

%  ---- (1) 법칙 블록 / the law blocks -----------------------------------
%  블록 하나가 법칙 하나를 처음부터 끝까지 담는다. 블록 안에서 다른 함수를
%  부르지 않는다 — 학생이 더블클릭해서 그 법칙 전체를 읽는다 (CLAUDE.md §5)
%  One block holds one law in full and calls nothing.
SPEC = law_specs();
NAME = cell(1, numel(laws));
for q = 1:numel(laws)
    sp      = SPEC(laws(q));
    NAME{q} = sp.name;
    if useSwitch
        y = 90 + 80*(laws(q) - 1);           % 넷이 나란히 / four in a column
    else
        y = 170;                             % 하나는 가운데 / one, centred
    end
    blk = [s '/' sp.name];
    add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
              'Position', [150 y 300 y+60]);
    set_mlfcn(blk, sp.code, 'f', '[8 1]');
    mlfcn_params(blk, sp.params);
end

%  ---- (2) 넷 중 하나 / one of the four ---------------------------------
if useSwitch
    add_block('simulink/Signal Routing/Multiport Switch', [s '/pick the law'], ...
              'Inputs', num2str(numel(laws)), ...
              'DataPortOrder', 'One-based contiguous', ...
              'Position', [380 70 410 390]);
    src = 'pick the law';
else
    src = NAME{1};
end

%  ---- (3) 여덟 성분을 여덟 명령으로 / eight components into eight commands
f2i = [s '/force to input'];
add_block('simulink/User-Defined Functions/MATLAB Function', f2i, ...
          'Position', [480 150 630 310]);
set_mlfcn(f2i, { ...
'function [n, delta] = force2input(f, k_pos, k_neg)'
'% Eight force components -> four shaft speeds and four tilt angles.'
'%'
'%     sigma_i = sign(f_xi)                        which way the unit pushes'
'%     T_i     = sigma_i |f_i|                     signed thrust        [N]'
'%     delta_i = atan2(sigma_i f_yi, sigma_i f_xi) tilt angle         [rad]'
'%     n_i     = sign(T_i) sqrt(|T_i| / k_i)       shaft speed      [rad/s]'
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
''
'% Below a tiny force the angle stops meaning anything: atan2 of two numbers'
'% near zero turns with the last bit of the arithmetic, so a servo asked to'
'% follow it would chatter while the vessel sits still. Hold such a unit at'
'% zero instead. The threshold is 0.5 N, which is 0.4 % of the ahead cap, so'
'% no force a controller could usefully ask for is thrown away here.'
'tiny = hypot(fx, fy) < 0.5;'
'delta(tiny) = 0;'
'n(tiny)     = 0;'
'end'}, 'n', '[4 1]');
mlfcn_params(f2i, {'k_pos', 'k_neg'});

%  ---- (4) 구동장치의 한계 / what the actuator can do --------------------
add_block('simulink/Discontinuities/Saturation', [s '/shaft limit'], ...
          'UpperLimit', 'n_max', 'LowerLimit', 'n_min', ...
          'Position', [690  80 750 140]);
add_block('simulink/Discontinuities/Saturation', [s '/servo limit'], ...
          'UpperLimit', 'alpha_lim', 'LowerLimit', '-alpha_lim', ...
          'Position', [690 280 750 340]);

%  ---- (5) 배분기의 장부 / the allocator's own record --------------------
%  요구한 명령과 한계가 허락한 명령을 함께 기록한다. 스물넷 열이다 /
%  what was asked and what the limits allowed, side by side; twenty-four columns:
%      f(8)  n 명령(4)  n 깎인 뒤(4)  delta 명령(4)  delta 깎인 뒤(4)
if ~isempty(logName)
    add_block('simulink/Signal Routing/Mux', [s '/actuator'], ...
              'Inputs', '5', 'DisplayOption', 'bar', ...
              'Position', [790 400 795 520]);
    add_block('simulink/Sinks/To Workspace', [s '/' logName], ...
              'VariableName', logName, 'SaveFormat', 'Array', ...
              'SampleTime', '-1', 'Position', [840 440 910 480]);
end

%  ---- 배선 / the wiring -------------------------------------------------
if useSwitch
    %  `tau d` 하나가 법칙 블록 넷으로 갈라진다. 같은 신호의 분기이므로 통로를
    %  나눠 쓴다. `law` 는 블록들 위로 돌아 스위치의 제어 포트로 간다 /
    %  the one demand branches to every law; `law` goes over the top of them
    lane = 100;
    for q = 1:numel(laws)
        elbow(s, 'tau d', 1, NAME{q}, 1, lane);
        lane = lane + 20;
    end
    elbow(s, 'law', 1, 'pick the law', 1, 370);
    lane = 315;
    for q = 1:numel(laws)
        elbow(s, NAME{q}, 1, 'pick the law', q+1, lane);
        lane = lane + 15;
    end
    add_line(s, 'pick the law/1', 'force to input/1');
else
    lane_line(s, 'tau d', 1, NAME{1}, 1, 120);
    lane_line(s, NAME{1}, 1, 'force to input', 1, 400);
end

lane_line(s, 'force to input', 1, 'shaft limit', 1, 655);
lane_line(s, 'force to input', 2, 'servo limit', 1, 670);
add_line(s, 'shaft limit/1', 'n/1');
add_line(s, 'servo limit/1', 'delta/1');

%  장부로 가는 분기 다섯. 통로를 하나씩 따로 쓴다 / five branches, one lane each
if ~isempty(logName)
    elbow(s, src,              1, 'actuator', 1, 440);
    elbow(s, 'force to input', 1, 'actuator', 2, 645);
    elbow(s, 'shaft limit',    1, 'actuator', 3, 765);
    elbow(s, 'force to input', 2, 'actuator', 4, 660);
    elbow(s, 'servo limit',    1, 'actuator', 5, 775);
    add_line(s, 'actuator/1', [logName '/1']);
end

%  ---- 주석 / the annotation --------------------------------------------
L = {'Allocation, and the hardware limits that follow it.', ''};
if useSwitch
    L = [L, { ...
'law 1 ... law 4   one demand tau_d -> eight force components f. Each block', ...
'                  holds one law in full and calls nothing, so double-click', ...
'                  the block to read the whole law:', ...
'', ...
'                      law 1   minimum norm                      sec. 7-8', ...
'                      law 2   weighted minimum norm             sec. 7-9', ...
'                      law 3   weighted, folded onto the limit   sec. 7-10', ...
'                      law 4   both limits as hard constraints   sec. 7-12', ...
'', ...
'pick the law      the constant `law` on the canvas selects one of the four.'}];
else
    L = [L, { ...
['law ' num2str(laws(1)) '             the one law this model uses, written out in full'], ...
'                  inside the block. Double-click it to read the whole law.', ...
'                  The other three laws of sections 7-8 to 7-12 are compared', ...
'                  in W07_alloc_chain; a closed loop carries only the one', ...
'                  that holds both limits at once.'}];
end
L = [L, { ...
'force to input    f -> four shaft speeds n and four tilt angles delta. The', ...
'                  thrust sign is taken first, which is what folds every', ...
'                  angle into [-90, +90] deg before the servo ever sees it.', ...
'                  A unit asked for less than 0.5 N is held at n = 0 and', ...
'                  delta = 0, because below that the angle is arithmetic', ...
'                  noise and the servo would chatter at rest.', ...
'shaft limit       n clipped to [n_min, n_max].', ...
'servo limit       delta clipped to +-alpha_lim.'}];
if ~isempty(logName)
    L = [L, { ...
['actuator          the record of this solve, written to ' logName ' as 24'], ...
'                  columns:  f(8),  n asked(4),  n allowed(4),  delta', ...
'                  asked(4),  delta allowed(4). Wherever asked and allowed', ...
'                  differ, that unit is against a limit.'}];
end
L = [L, { ...
'', ...
'What the hull was actually given is not rebuilt here: the motion model', ...
'already forms it from the clipped n and delta and reports it on its own', ...
'second output.'}];

a                    = Simulink.Annotation([s '/note']);
a.Text               = strjoin(L, newline);
a.Position           = [40 560 900 830];
a.HorizontalAlignment = 'left';
end


% =========================================================================
function elbow(sys, src, sp, dst, dp, x)
%ELBOW  한 출력에서 갈라져 세로 통로 하나를 지나 다른 포트로 간다.
%       Branch off one output, through one vertical lane, into another port.
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; x a(2); x b(2); b]);
end


% =========================================================================
function SPEC = law_specs()
%LAW_SPECS  법칙 넷의 이름·코드·매개변수 / the four laws: name, code, parameters.

SPEC(1).name   = 'law 1  minimum norm';
SPEC(1).params = {'B_alloc'};
SPEC(1).code   = { ...
'function f = law1_minimum_norm(tau_d, B_alloc)'
'% LAW 1 -- minimum norm.  Section 7-8.'
'%'
'%     min f''f    subject to    B f = tau_d       ->    f = B''(B B'')\tau_d'
'%'
'% Eight unknowns against three equations: the demand leaves five directions'
'% free, and this law spends them on the shortest f. Nothing here knows about'
'% the servo limit or the thrust cap, which is what laws 3 and 4 go on to fix.'
'%'
'%     f = [f_x1; f_y1; f_x2; f_y2; f_x3; f_y3; f_x4; f_y4]'
'f = B_alloc'' * ((B_alloc*B_alloc'') \ tau_d);'
'end'};

SPEC(2).name   = 'law 2  weighted minimum norm';
SPEC(2).params = {'B_alloc', 'W_alloc'};
SPEC(2).code   = { ...
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
'end'};

SPEC(3).name   = 'law 3  folded onto the limit';
SPEC(3).params = {'B_alloc', 'W_alloc', 'alpha_lim'};
SPEC(3).code   = { ...
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
'% satisfy B f = tau_d. The error that opens up is the result of section 7-10.'
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
'end'};

SPEC(4).name   = 'law 4  limits as constraints';
SPEC(4).params = {'B_alloc', 'W_alloc', 'alpha_lim', 'Q_tau', 'eps_reg', ...
                  'T_pos', 'T_neg'};
SPEC(4).code   = { ...
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
'end'};
end
