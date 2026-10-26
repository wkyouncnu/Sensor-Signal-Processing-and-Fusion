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
%   WHY A TOOL, AND WHY NOT ADD_SPEED_LOOP
%
%   3·4·5 주차의 `add_speed_loop` 이 **전진 축 하나**에 대해 바로 이 PI 를 이미
%   만든다. 그것을 두 축으로 넓히지 않고 여기에 따로 둔 이유는, 그 함수를 고치면
%   3·4·5 주차 모델이 전부 함께 바뀌고 그 주차들의 수치가 흔들리기 때문이다.
%   대신 **구조를 그대로 베낀다** — 합산점의 모양, 안티와인드업이 아래 통로
%   하나로 돌아오는 모양, 게인이 전부 양수인 것. 학생이 3주차 그림과 6주차 그림을
%   나란히 놓으면 전진 축은 **같은 그림**이어야 한다.
%
%   add_speed_loop (Weeks 3 to 5) already builds exactly this PI for the surge
%   axis alone. It is not widened to two axes here because editing it would
%   change the Week 3, 4 and 5 models and move their measured numbers. The
%   structure is copied instead: the same junction shape, the same single
%   anti-windup lane along the bottom, the same all-positive gains. Placed side
%   by side, the surge axis of this diagram and Week 3's must be the same
%   drawing.
%
%   W06_F_position 과 W06_H_berth 가 이것을 함께 쓴다 (§15-34).
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
set_param([s '/nu_d'], 'Position', [ 60 193  90 207]);
set_param([s '/x'],    'Position', [ 60 293  90 307]);

%% ---- 두 축. 구조가 같고 이름과 게인만 다르다 / two axes, one structure -----
pi_axis(s, 200, 'u_d = nu_d(1)', 1, 'u = x(1)',  1, ...
        'e_u', 'Kp_u', 'Ki_u', 'I_u', 'X raw', 'surge limit', 'X_max', ...
        'X - X raw', 'Kb_u');
pi_axis(s, 560, 'v_d = nu_d(2)', 2, 'v = x(2)',  2, ...
        'e_v', 'Kp_v', 'Ki_v', 'I_v', 'Y raw', 'sway limit',  'Y_max', ...
        'Y - Y raw', 'Kb_v');

%% ---- 명령과 상태를 두 축으로 나눈다 / the command and the state fan out ----
route(s, 'nu_d', 1, 'u_d = nu_d(1)', 1, zeros(0,2));
route(s, 'nu_d', 1, 'v_d = nu_d(2)', 1, [115 200; 115 560]);
route(s, 'x',    1, 'u = x(1)',      1, zeros(0,2));
route(s, 'x',    1, 'v = x(2)',      1, [130 300; 130 660]);

%% ---- 두 힘을 하나로 / the two forces become one vector --------------------
add_block('simulink/Signal Routing/Mux', [s '/tau_uv mux'], ...
          'Inputs','2', 'Position', [880 350 885 410]);
riser(s, 'surge limit', 1, 'tau_uv mux', 1, 840);
riser(s, 'sway limit',  1, 'tau_uv mux', 2, 850);

at(s, 'tau_uv', port_xy(s,'tau_uv mux','Outport',1) + [105 0]);
route(s, 'tau_uv mux', 1, 'tau_uv', 1, zeros(0,2));
end

% =========================================================================
function pi_axis(s, y0, cmdSel, cmdIdx, measSel, measIdx, ...
                 eName, kpName, kiName, iName, rawName, satName, limName, ...
                 bckName, kbName)
%PI_AXIS  한 축의 PI 와 안티와인드업을 y0 를 기준으로 한 띠에 놓는다.
%         One axis's PI and anti-windup, laid out in a band based at y0.
%
%  띠의 모양 / the shape of a band
%      y0        명령 · 오차 · Kp · 요구 힘 · 포화          the forward path
%      y0 + 100  측정값                                      the measurement
%      y0 + 120  Ki · 적분기                                 the integral path
%      y0 + 260  안티와인드업이 돌아오는 통로                the return lane

%  명령과 측정 / the command and the measurement
sel(s, cmdSel,   2, cmdIdx,  [150 y0- 18 260 y0+ 18]);
sel(s, measSel, 12, measIdx, [150 y0+ 82 260 y0+118]);

%  오차. 명령이 왼쪽에서, 측정이 아래에서 / the error
add_sum(s, eName, '+-', [330 y0]);
route(s, cmdSel,  1, eName, 1, zeros(0,2));
route(s, measSel, 1, eName, 2, [330 y0+100]);

%  비례와 적분. 게인은 둘 다 양수다 / proportional and integral, both positive
gain(s, kpName, kpName, [400 y0- 18 460 y0+ 18]);
gain(s, kiName, kiName, [400 y0+102 460 y0+138]);
route(s, eName, 1, kpName, 1, zeros(0,2));
route(s, eName, 1, kiName, 1, [370 y0; 370 y0+120]);

add_sum(s, ['into ' iName], '++', [520 y0+120]);
add_block('simulink/Continuous/Integrator', [s '/' iName], ...
          'InitialCondition','0', 'Position', [580 y0+102 620 y0+138]);
route(s, kiName,        1, ['into ' iName], 1, zeros(0,2));
route(s, ['into ' iName], 1, iName,         1, zeros(0,2));

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
