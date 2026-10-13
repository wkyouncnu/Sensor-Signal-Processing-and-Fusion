function s = add_speed_loop(m, pos, kbName)
%ADD_SPEED_LOOP  3주차의 속도 루프를 **서브시스템 하나**로 넣는다.
%                Add the Week 3 surge-speed loop as one subsystem.
%
%   s = add_speed_loop(m, pos)            되감기 게인은 Kb / the gain is Kb
%   s = add_speed_loop(m, pos, 'Kb_u')    다른 이름으로 / under another name
%
%     m    모델 이름 / the model
%     pos  서브시스템 자리 [x1 y1 x2 y2] / where the subsystem goes
%     kbName  되감기 게인의 작업공간 변수 이름. 기본값 'Kb'. 4주차 통합 모델은
%             'Kb_u' 를 준다 - 그 주차의 Kb 는 **선수각 적분기**의 되감기 이득이라
%             이미 다른 값을 들고 있기 때문이다.
%             The workspace name of the back-calculation gain, 'Kb' by default.
%             The Week 4 combined model passes 'Kb_u', because Kb there is
%             already the heading integrator's gain and holds another value.
%
%   들어가는 것 u_d [m/s], x (12 상태)        나오는 것 X [N]
%
%     e = u_d - u
%     X_raw = Kp_u e + I,        I' = Ki_u e + Kb (X - X_raw)
%     X     = sat(X_raw),        |X| <= X_max
%
%   **3주차 모델과 같은 블록, 같은 이름, 같은 게인이다** (W03_1_build_speed 참조):
%   합산점 `e`, 게인 `Kp_u` 와 `Ki_u`, **연속 적분기** `I`, 합산점 `X raw`,
%   `Saturation` `thrust limit`, 되감기 게인 `Kb`. 다른 것은 명령 u_d 가 밖에서
%   들어온다는 것뿐이다.
%   The same blocks, names and gains as Week 3; the only change is that u_d
%   arrives from outside instead of from a Constant.
%
%   적분기는 **연속**이다 (사용자 지시, 2026-09-29). 이산 적분기를 쓰면 제어기가
%   솔버와 다른 시간축에서 돌아 모델이 두 개의 시간을 갖는다.
%   The integrator is continuous: a discrete one would put the controller on a
%   different time base from the plant.
%
%   안티와인드업은 **back-calculation** 이다 (3주차 F 절). 포화가 잘라 낸 양
%   X - X_raw 를 Kb 배 하여 적분기 입력에 되돌린다. Kb = 0 이면 꺼진다.
%   The anti-windup is back-calculation: the amount the saturation removed,
%   X - X_raw, is fed back through Kb into the integrator. Kb = 0 switches it off.
%
%   See also ADD_HEADING_LOOP, ADD_SUBSYS, ADD_SUM.

if nargin < 3 || isempty(kbName), kbName = 'Kb'; end

s = add_subsys(m, 'speed loop', pos, {'u_d','x'}, {'X'}, gnc_colour('controller'));
set_param([s '/u_d'], 'Position', [ 60 190  90 210]);
set_param([s '/x'],   'Position', [ 60 290  90 310]);
set_param([s '/X'],   'Position', [860 190 890 210]);

sel(s, 'u = x(1)', 1, [140 282 240 318]);
route(s, 'x', 1, 'u = x(1)', 1, zeros(0,2));

%  1) 속도 오차. 명령이 왼쪽, 측정이 아래에서 - MSS 데모의 되먹임 합산점 모양이다.
%     The command on the left edge and the measurement from below, the shape a
%     feedback junction has in the MSS demonstration models.
add_sum(s, 'e', '+-', [300 200]);
route(s, 'u_d',      1, 'e', 1, zeros(0,2));
route(s, 'u = x(1)', 1, 'e', 2, [300 300]);

%  2) P 와 I / the two terms
gain(s, 'Kp_u', 'Kp_u', [380 182 440 218]);
gain(s, 'Ki_u', 'Ki_u', [380 302 440 338]);
route(s, 'e', 1, 'Kp_u', 1, zeros(0,2));
route(s, 'e', 1, 'Ki_u', 1, [350 200; 350 320]);
add_sum(s, 'into I', '++', [500 320]);
add_block('simulink/Continuous/Integrator', [s '/I'], ...
          'InitialCondition','0', 'Position', [560 302 600 338]);
route(s, 'Ki_u',   1, 'into I', 1, zeros(0,2));
route(s, 'into I', 1, 'I', 1, zeros(0,2));

%  3) 더하고 자른다 / add them and clamp
add_sum(s, 'X raw', '++', [660 200]);
route(s, 'Kp_u', 1, 'X raw', 1, zeros(0,2));
route(s, 'I',    1, 'X raw', 2, [660 320]);
add_block('simulink/Discontinuities/Saturation', [s '/thrust limit'], ...
          'UpperLimit','X_max', 'LowerLimit','-X_max', 'Position', [710 182 760 218]);
route(s, 'X raw',        1, 'thrust limit', 1, zeros(0,2));
route(s, 'thrust limit', 1, 'X', 1, zeros(0,2));

%  4) 안티와인드업: 잘려 나간 만큼을 적분기로 되돌린다 (3주차 F 절과 같은 배선)
%     되돌아가는 길은 **맨 아래 한 줄의 통로**다 (사용자 수정, 2026-10-13). 뺄셈과
%     Kb 를 그 통로에 놓고 **둘 다 왼쪽을 보게** 돌린다. 그러면 신호는 각자 바로
%     아래로 떨어지고, 통로를 따라 곧게 왼쪽으로 가고, 한 번만 올라간다 - 꺾이는
%     곳이 네 군데뿐이고 비스듬한 선이 없다.
%     The return path is one lane along the bottom. The subtraction and Kb sit in
%     that lane and both face left, so each signal drops straight down, runs
%     straight back along the lane and rises once: four corners in all, and no
%     stretch at an angle.
add_sum(s, 'X - X raw', '-+', [640 460]);
set_param([s '/X - X raw'], 'Orientation','left');
gain(s, 'Kb', kbName, [520 442 570 478]);
set_param([s '/Kb'], 'Orientation','left');
route(s, 'X raw',        1, 'X - X raw', 1, [690 200; 690 455]);
route(s, 'thrust limit', 1, 'X - X raw', 2, [800 200; 800 465]);
route(s, 'X - X raw',    1, 'Kb',        1, zeros(0,2));
route(s, 'Kb',           1, 'into I',    2, [480 460; 480 325]);
for nm = {'e','into I','X raw','X - X raw'}
    set_param([s '/' nm{1}], 'NamePlacement','alternate');
end
end

% =========================================================================
function sel(s, name, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], 'InputPortWidth','12', ...
          'IndexOptions','Index vector (dialog)', 'Indices', num2str(idx), 'Position', pos);
end

function gain(s, name, val, pos)
add_block('simulink/Math Operations/Gain', [s '/' name], 'Gain', val, 'Position', pos);
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end
