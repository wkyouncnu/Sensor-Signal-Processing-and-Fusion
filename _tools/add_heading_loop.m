function s = add_heading_loop(m, pos, limitName)
%ADD_HEADING_LOOP  4주차의 선수각 오토파일럿을 **서브시스템 하나**로 넣는다.
%                  Add the Week 4 heading autopilot as one subsystem.
%
%   s = add_heading_loop(m, pos, limitName)
%
%     m          모델 이름 / the model
%     pos        서브시스템 자리 [x1 y1 x2 y2] / where the subsystem goes
%     limitName  Saturation 이 들고 있을 작업공간 변수 이름 / the workspace variable
%                the Saturation holds: 'N_max' 또는 'N_speed' (5-7 절)
%
%   들어가는 것 psi_d [rad], x (12 상태)      나오는 것 N [N m]
%
%     e = ssa(psi_d - psi),   ssa(u) = atan2(sin(u), cos(u))
%     N = Kp e - Kd r,        |N| <= limitName
%
%   WHY A TOOL
%
%   같은 제어기를 4주차와 5주차가 함께 쓴다. 한 곳에 두어야 **학생이 4주차에서 본
%   그림을 5주차에서 글자 하나까지 그대로** 다시 본다. 복사해 두면 한쪽만 고쳐져
%   둘이 어긋나고, 그때부터 "같은 제어기" 라는 말이 거짓이 된다.
%   Weeks 4 and 5 use the same controller. Keeping it in one place is what makes
%   the diagram a student saw in Week 4 identical, block for block, in Week 5. A
%   copy drifts the moment one of the two is edited.
%
%   D 항은 오차의 미분이 아니라 **측정한 요각속도**다 (4주차의 결론). 그래서 psi_d 가
%   계단으로 뛰어도 N 이 튀지 않는다 - 미분 블록 자체가 이 그림에 없다.
%   The D term is the measured yaw rate, not the derivative of the error, which is
%   why a step in psi_d produces no kick: there is no derivative block here at all.
%
%   **게인은 전부 양수이고 빼는 것은 합산점에서** (사용자 지시, 2026-09-29). 게인에
%   -Kd 를 넣으면 부호가 블록 이름·값·합산점 셋에 흩어진다. 한 군데에만 두면
%   "Kp e 에서 Kd r 을 뺀다" 가 그림 그대로 읽힌다.
%   Every gain is positive and the subtraction is at the junction: with -Kd in the
%   gain the sign is spread over three places and the reader has to count them.
%
%   See also ADD_SPEED_LOOP, ADD_SUBSYS, ADD_SUM.

s = add_subsys(m, 'heading autopilot', pos, {'psi_d','x'}, {'N'}, gnc_colour('controller'));
set_param([s '/psi_d'], 'Position', [ 60  90  90 110]);
set_param([s '/x'],     'Position', [ 60 190  90 210]);
set_param([s '/N'],     'Position', [700 120 730 140]);

%  x 에서 필요한 둘만 꺼낸다 / take the two states this law uses
sel(s, 'psi = x(12)', 12, [140 182 240 218]);
sel(s, 'r = x(6)',     6, [140 262 240 298]);
route(s, 'x', 1, 'psi = x(12)', 1, zeros(0,2));
route(s, 'x', 1, 'r = x(6)',    1, [115 200; 115 280]);

%  1) 오차, 그리고 (-pi, pi] 로 감기 / the error, wrapped into (-pi, pi]
add_sum(s, 'e', '+-', [300 100]);
route(s, 'psi_d',       1, 'e', 1, zeros(0,2));
route(s, 'psi = x(12)', 1, 'e', 2, [300 200]);
add_block('simulink/User-Defined Functions/Fcn', [s '/ssa'], ...
          'Expr','atan2(sin(u), cos(u))', 'Position', [360 82 440 118]);
route(s, 'e', 1, 'ssa', 1, zeros(0,2));

%  2) P 는 오차에, D 는 요각속도에 / P on the error, D on the yaw rate
gain(s, 'Kp', 'Kp', [480  82 540 118]);
gain(s, 'Kd', 'Kd', [480 262 540 298]);
route(s, 'ssa',      1, 'Kp', 1, zeros(0,2));
route(s, 'r = x(6)', 1, 'Kd', 1, zeros(0,2));
add_sum(s, 'N raw', '+-', [580 100]);
route(s, 'Kp', 1, 'N raw', 1, zeros(0,2));
route(s, 'Kd', 1, 'N raw', 2, [580 280]);

%  3) 두 프로펠러가 낼 수 있는 만큼으로 자른다 / limit to what the propellers give
add_block('simulink/Discontinuities/Saturation', [s '/moment limit'], ...
          'UpperLimit', limitName, 'LowerLimit', ['-' limitName], ...
          'Position', [620 82 670 118]);
route(s, 'N raw',        1, 'moment limit', 1, zeros(0,2));
route(s, 'moment limit', 1, 'N', 1, [690 100; 690 130]);
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
