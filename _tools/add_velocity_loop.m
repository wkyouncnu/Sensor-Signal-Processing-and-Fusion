function s = add_velocity_loop(m, pos)
%ADD_VELOCITY_LOOP  속도 명령을 힘으로 바꾸는 안쪽 루프, 두 축 (6주차).
%                   The inner loop that turns a velocity command into a force,
%                   on both axes.
%
%   s = add_velocity_loop(m, pos)
%
%   들어가는 것 nu_d = [u_d; v_d] [m/s],  x (12 상태)
%   나오는 것   tau_uv = [X; Y] [N]
%
%   안이 서브시스템 **둘**이다 / TWO SUBSYSTEMS INSIDE (사용자 지시, 2026-11-03)
%
%       velocity loop
%         ├── u speed control      u_d, u -> X
%         └── v speed control      v_d, v -> Y
%
%   두 축의 PI 를 한 캔버스에 나란히 펴 두면 블록이 서른 남짓이 되고, 그러면
%   "둘이 같은 구조인가" 를 **그림으로** 확인할 수 없다 — 블록을 하나씩 짚어
%   세어야 한다. 축마다 서브시스템 하나로 접으면 바깥 그림이 넉 줄로 읽히고,
%   더블클릭해 들어간 안쪽은 **3주차의 `add_speed_loop` 과 같은 그림**이다.
%   그것이 이 분리의 목적이다 — 전진 축이 3주차와 같다는 것을 눈으로 보이는 것.
%
%   Laid flat, the two axes put some thirty blocks on one canvas, and whether
%   they share a structure then has to be CHECKED block by block instead of
%   seen. Folded one subsystem per axis, the outer diagram reads in four rows
%   and each inner diagram is the same drawing as Week 3's add_speed_loop. That
%   is the point of the split: the surge axis is visibly Week 3's.
%
%   바깥에서 하는 일은 **나누고 모으는 것뿐**이다 / the parent only fans out
%
%       nu_d --> u_d, v_d        Selector 둘
%       x    --> u, v            Selector 둘
%       X, Y --> tau_uv          Mux 하나
%
%   WHY A TOOL, AND WHY NOT ADD_SPEED_LOOP
%
%   3·4·5 주차의 `add_speed_loop` 이 **전진 축 하나**에 대해 바로 이 PI 를 이미
%   만든다. 그것을 두 축으로 넓히지 않고 여기에 따로 둔 이유는, 그 함수를 고치면
%   3·4·5 주차 모델이 전부 함께 바뀌고 그 주차들의 수치가 흔들리기 때문이다.
%   대신 **구조를 그대로 베낀다** — 합산점의 모양, 안티와인드업이 아래 통로
%   하나로 돌아오는 모양, 게인이 전부 양수인 것.
%
%   add_speed_loop (Weeks 3 to 5) already builds exactly this PI for the surge
%   axis alone. It is not widened to two axes here because editing it would
%   change the Week 3, 4 and 5 models and move their measured numbers. The
%   structure is copied instead: the same junction shape, the same single
%   anti-windup lane along the bottom, the same all-positive gains.
%
%   6 주차 사다리에서 루프를 닫는 여섯 단이 이것을 함께 쓴다 (§15-34).
%
%   THE LAW, PER AXIS
%
%       e      = u_d - u                       (and v_d - v)
%       X_raw  = Kp_u e + I
%       I'     = Ki_u e + Kb (X - X_raw)       back-calculation
%       X      = sat(X_raw),  |X| <= X_max     (and Y_max on the sway axis)
%
%   적분기는 **연속 시간**이다. 플랜트가 연속이므로 제어기도 연속이고, 이산
%   적분기를 섞으면 모델이 시간축 둘을 갖는다 (사용자 지시, 2026-09-29).
%   The integrators are CONTINUOUS: the plant is continuous, so the controller
%   is too. A discrete integrator here would give the model two time axes.
%
%   WHY THE TWO AXES NEED DIFFERENT GAINS
%
%   같은 구조에 게인만 다르다 — Kp_u = 200, Kp_v = 150. 횡방향이 낮은 이유는
%   **관성이 크고 낼 수 있는 힘이 작기** 때문이다. M(2,2) = 162.5 kg 이 M(1,1) =
%   85.5 kg 의 거의 두 배이고, 횡력 한계 Y_max = 35.13 N 은 전진력 한계 X_max =
%   120 N 의 1/3 이 못 된다. 전진 축의 게인을 그대로 쓰면 횡방향은 거의 언제나
%   포화에 걸린 채로 돈다 (6-6 절).
%   Same structure, different gains. The sway axis is slower because its inertia
%   is larger and its available force smaller: M(2,2) = 162.5 kg against
%   M(1,1) = 85.5 kg, and Y_max = 35.13 N against X_max = 120 N. Carrying the
%   surge gains across would leave the sway axis saturated almost always.
%
%   그래서 안티와인드업이 이 주차에서 **없어서는 안 되는 것**이 된다. 4·5 주차는
%   포화가 드물어 Kb 를 0 으로 두어도 거의 같은 그림이 나왔지만, 여기서는 횡방향
%   적분기가 금방 쌓인다. 6-6 절이 Kb = 0 과 Kb = 1 을 나란히 잰다.
%   Anti-windup therefore stops being optional this week: where saturation was
%   rare in Weeks 4 and 5, the sway integrator fills quickly here.
%
%   See also ADD_SPEED_LOOP, ADD_POSITION_LOOP, ADD_HEADING_LOOP.

if nargin < 2 || isempty(pos), pos = [480 100 640 220]; end

s = add_subsys(m, 'velocity loop', pos, {'nu_d','x'}, {'tau_uv'}, ...
               gnc_colour('controller'));

%% ---- 축마다 서브시스템 하나 / one subsystem per axis ----------------------
axis_loop(s, 'u speed control', [400 150 580 290], 'u_d', 'u', 'X', ...
          'e_u', 'Kp_u', 'Ki_u', 'I_u', 'X raw', 'surge limit', 'X_max', ...
          'X - X raw', 'Kb_u');
axis_loop(s, 'v speed control', [400 390 580 530], 'v_d', 'v', 'Y', ...
          'e_v', 'Kp_v', 'Ki_v', 'I_v', 'Y raw', 'sway limit',  'Y_max', ...
          'Y - Y raw', 'Kb_v');

%% ---- 나누기. 선택기를 **먹이는 포트의 높이로** 옮긴다 / the fan-out -------
%  높이를 계산하지 않고 읽는다 (port_xy). 서브시스템의 포트 높이는 Simulink 가
%  정하므로, 계산하면 한 픽셀씩 어긋나 선이 비스듬해진다
%  The heights are READ, not calculated: Simulink decides a subsystem's port
%  heights, and a calculated guess leaves a one-pixel diagonal.
F = {'u_d = nu_d(1)',  2, 1, 'u speed control', 1, 'nu_d'
     'u = x(1)',      12, 1, 'u speed control', 2, 'x'
     'v_d = nu_d(2)',  2, 2, 'v speed control', 1, 'nu_d'
     'v = x(2)',      12, 2, 'v speed control', 2, 'x'};
for i = 1:size(F,1)
    q = port_xy(s, F{i,4}, 'Inport', F{i,5});
    sel(s, F{i,1}, F{i,2}, F{i,3}, [210 q(2)-18 350 q(2)+18]);
    route(s, F{i,1}, 1, F{i,4}, F{i,5}, zeros(0,2));
end

%  두 포트 블록은 **위쪽 축의** 선택기 높이에 둔다. 아래쪽 축으로 가는 가지만
%  통로를 하나 쓰고 내려간다 — 통로 둘, 비스듬한 것 없음
%  Each port block sits at the height of the UPPER axis's selector; only the
%  branch to the lower axis uses a lane and drops.
at(s, 'nu_d', port_xy(s, 'u_d = nu_d(1)', 'Inport', 1));
at(s, 'x',    port_xy(s, 'u = x(1)',      'Inport', 1));
route(s, 'nu_d', 1, 'u_d = nu_d(1)', 1, zeros(0,2));
route(s, 'x',    1, 'u = x(1)',      1, zeros(0,2));
drop(s, 'nu_d', 'v_d = nu_d(2)', 150);
drop(s, 'x',    'v = x(2)',      175);

%% ---- 모으기 / the two forces become one vector ---------------------------
add_block('simulink/Signal Routing/Mux', [s '/tau_uv mux'], ...
          'Inputs','2', 'Position', [680 310 685 390]);
riser(s, 'u speed control', 1, 'tau_uv mux', 1, 630);
riser(s, 'v speed control', 1, 'tau_uv mux', 2, 645);

at(s, 'tau_uv', port_xy(s, 'tau_uv mux', 'Outport', 1) + [105 0]);
route(s, 'tau_uv mux', 1, 'tau_uv', 1, zeros(0,2));
end

% =========================================================================
function axis_loop(parent, name, pos, cmdName, measName, outName, ...
                   eName, kpName, kiName, iName, rawName, satName, limName, ...
                   bckName, kbName)
%AXIS_LOOP  한 축의 PI 와 안티와인드업을 **서브시스템 하나**로 만든다.
%           One axis's PI and anti-windup, as a subsystem of its own.
%
%  안쪽의 모양 / the shape inside
%      y0        명령 · 오차 · Kp · 요구 힘 · 포화          the forward path
%      y0 + 100  측정값이 아래에서 들어온다                 the measurement
%      y0 + 120  Ki · 적분기                                 the integral path
%      y0 + 260  안티와인드업이 돌아오는 통로                the return lane
%
%  이 넉 줄이 3주차 `add_speed_loop` 의 넉 줄과 같다. 그것이 이 함수가 그
%  함수를 베끼면서도 고치지 않는 이유다 (위의 WHY A TOOL 절).
%  These four rows are Week 3's four rows, which is why this function copies
%  add_speed_loop rather than editing it.

s = add_subsys(parent, name, pos, {cmdName, measName}, {outName}, ...
               gnc_colour('controller'));
y0 = 200;

%  오차. 명령이 왼쪽에서, 측정이 아래에서 / the error
add_sum(s, eName, '+-', [330 y0]);
at(s, cmdName,  [150 y0]);
at(s, measName, [150 y0+100]);
route(s, cmdName,  1, eName, 1, zeros(0,2));
route(s, measName, 1, eName, 2, [330 y0+100]);

%  비례와 적분. 게인은 둘 다 양수다 / proportional and integral, both positive
gain(s, kpName, kpName, [400 y0- 18 460 y0+ 18]);
gain(s, kiName, kiName, [400 y0+102 460 y0+138]);
route(s, eName, 1, kpName, 1, zeros(0,2));
route(s, eName, 1, kiName, 1, [370 y0; 370 y0+120]);

add_sum(s, ['into ' iName], '++', [520 y0+120]);
add_block('simulink/Continuous/Integrator', [s '/' iName], ...
          'InitialCondition','0', 'Position', [580 y0+102 620 y0+138]);
route(s, kiName,          1, ['into ' iName], 1, zeros(0,2));
route(s, ['into ' iName], 1, iName,           1, zeros(0,2));

%  요구 힘과 포화 / the demanded force, and the limit
add_sum(s, rawName, '++', [680 y0]);
route(s, kpName, 1, rawName, 1, zeros(0,2));
route(s, iName,  1, rawName, 2, [680 y0+120]);
add_block('simulink/Discontinuities/Saturation', [s '/' satName], ...
          'UpperLimit', limName, 'LowerLimit', ['-' limName], ...
          'Position', [730 y0-18 780 y0+18]);
route(s, rawName, 1, satName, 1, zeros(0,2));

%  안티와인드업. sat(X) - X 를 Kb 배 해서 적분기 입력에 더한다. 적분기 안의
%  Limit output 은 도면에 보이지 않아 "안티와인드업이 없다" 는 말을 듣는다 —
%  그래서 back-calculation 을 그려서 보이게 한다. 두 신호가 각각 아래로 내려가
%  **하나의 통로**로 돌아오고 한 번 올라간다. 모서리 넷, 비스듬한 것 없음.
%  Anti-windup, drawn rather than hidden: an integrator's own Limit output does
%  not appear on the diagram, so back-calculation is wired instead. Both signals
%  drop straight down, run back along ONE lane and rise once.
add_sum(s, bckName, '-+', [660 y0+260]);
set_param([s '/' bckName], 'Orientation','left');
gain(s, kbName, 'Kb', [540 y0+242 590 y0+278]);
set_param([s '/' kbName], 'Orientation','left');
riser(s, rawName, 1, bckName, 1, 710);
riser(s, satName, 1, bckName, 2, 820);
route(s, bckName, 1, kbName, 1, zeros(0,2));
riser(s, kbName, 1, ['into ' iName], 2, 500);

%  포화를 지난 힘이 이 서브시스템의 출력이다 / the limited force leaves here
at(s, outName, port_xy(s, satName, 'Outport', 1) + [120 0]);
route(s, satName, 1, outName, 1, zeros(0,2));

%  합산점 이름을 반대쪽에 둔다. 원이 20 px 라 이름이 선 위에 앉는다
%  the junction names go on the other side: a 20 px circle leaves the name on
%  top of a line otherwise
for nm = {eName, ['into ' iName], rawName, bckName}
    set_param([s '/' nm{1}], 'NamePlacement','alternate');
end
end

% =========================================================================
function sel(s, name, width, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], ...
          'InputPortWidth', num2str(width), ...
          'IndexOptions','Index vector (dialog)', 'Indices', mat2str(idx), ...
          'Position', pos);
end

function gain(s, name, val, pos)
add_block('simulink/Math Operations/Gain', [s '/' name], 'Gain', val, 'Position', pos);
end

function at(s, name, p)
set_param([s '/' name], 'Position', [p(1)-30 p(2)-7 p(1) p(2)+7]);
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end

function riser(sys, src, sp, dst, dp, x)
%  가로 - 세로 - 가로. 두 포트의 높이를 모두 읽는다 / both heights are read
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; x a(2); x b(2); b]);
end

function drop(sys, src, dst, x)
%  위쪽 축에서 갈라져 아래쪽 축으로 내려가는 가지. riser 와 같은 모양이고
%  방향만 아래다 / the branch down to the lower axis: riser's shape, downwards
riser(sys, src, 1, dst, 1, x);
end
