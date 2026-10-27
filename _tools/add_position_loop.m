function s = add_position_loop(m, pos)
%ADD_POSITION_LOOP  위치 오차를 속도 명령으로 바꾸는 바깥 루프 (6주차).
%                   The outer loop that turns a position error into a velocity
%                   command.
%
%   s = add_position_loop(m, pos)
%
%     m     모델 이름 / the model
%     pos   서브시스템 자리 [x1 y1 x2 y2] / where the subsystem goes
%
%   들어가는 것 p_d = [N_d; E_d] [m],  x (12 상태),  gate (0 또는 1)
%   나오는 것   nu_d = [u_d; v_d] [m/s],  d = |p_d - p| [m]
%
%   WHY A TOOL
%
%   6 주차 사다리의 다섯 단 — W06_1_point · W06_2_sway · W06_4_stop · W06_5_dock ·
%   W06_7_front — 이 **같은 바깥 루프**를 쓴다. 단끼리의 차이는 목표점을 누가
%   주느냐 하나뿐이다 — 앞의 셋은 Constant 가, 뒤의 둘은 단계 기계가 준다.
%   한 곳에 두어야 그 차이가 **그 하나뿐**이라는 것이 코드로 보인다.
%   Five rungs of the Week 6 ladder use the same outer loop; the only difference
%   between them is who supplies the target. Keeping it in one place is what
%   makes that the ONLY difference.
%
%   WHAT THE LOOP COMPUTES
%
%       p_e   = p_d - p                      오차는 NED 에서 잰다 / measured in NED
%       p_b   = R(psi)' p_e                  제어는 선체에서 한다 / control in {b}
%       nu_d  = gate * sat(Kp_pos * p_b)
%
%   오차를 NED 에서 재고 명령을 선체에서 내는 이유는 **구동장치가 선체에 붙어
%   있기** 때문이다. 전진과 횡이동은 추진기가 밀 수 있는 방향이고, 북과 동은
%   아니다. R(psi) 가 선체에서 NED 로 보내므로 그 전치가 NED 에서 선체로 보낸다.
%   The error is measured in NED and the command given in the body frame because
%   that is where the actuators are: surge and sway are directions the thrusters
%   can push, north and east are not. R(psi) maps body to NED, so its transpose
%   maps NED to body.
%
%   두 성분의 포화 한계가 다르다 — u_lim = 0.80, v_lim = 0.35 m/s. 낼 수 있는
%   횡력이 전진력보다 작기 때문이고, 얼마나 작은지는 6-4 절이 센다.
%   The two components saturate at different values, because the lateral force
%   available is smaller than the longitudinal one (6-4 절).
%
%   THE GATE
%
%   gate = 0 이면 속도 명령이 **0** 이 된다. 위치 명령이 사라지는 것이 아니라
%   "그 자리에서 서라" 가 된다 — 안쪽 PI 가 속도를 0 으로 몰고, 적분기가 계속
%   돌므로 조류가 있어도 0 을 지킨다. 접안의 마지막 판정이 이것이다 (6-7 절).
%   gate = 0 makes the velocity command zero. That is not "no command" but
%   "stop here": the inner PI drives the velocity to zero and keeps it there,
%   integrators still running, so a current does not move the vessel off.
%
%   d 를 **여기서** 내보내는 이유는 단계 기계가 거리를 다시 계산하지 않게 하려는
%   것이다. 거리를 두 군데에서 재면 두 정의가 생기고, 강의의 수치와 채점기의
%   수치가 어긋난다.
%   d leaves this subsystem so that the phase machine does not compute the
%   distance a second time: two places measuring it would be two definitions.
%
%   See also ADD_VELOCITY_LOOP, ADD_HEADING_LOOP, ADD_ALLOCATION3.

if nargin < 2 || isempty(pos), pos = [300 100 460 220]; end

s = add_subsys(m, 'position loop', pos, {'p_d','x','gate'}, {'nu_d','d'}, ...
               gnc_colour('controller'));
set_param([s '/p_d'],  'Position', [ 60 193  90 207]);
set_param([s '/x'],    'Position', [ 60 313  90 327]);
set_param([s '/gate'], 'Position', [ 60 513  90 527]);

%% ---- 1) 상태에서 필요한 셋 / the three states this loop uses -------------
sel(s, 'p = x(7:8)',  [7 8], [150 302 260 338]);
sel(s, 'psi = x(12)',    12, [150 382 260 418]);
route(s, 'x', 1, 'p = x(7:8)',  1, zeros(0,2));
route(s, 'x', 1, 'psi = x(12)', 1, [115 320; 115 400]);

%% ---- 2) 오차는 NED 에서 / the error, in NED ------------------------------
%   명령이 왼쪽에서, 측정이 아래에서 들어온다 — MSS 데모의 되먹임 합산점 모양이다.
%   Command from the left, measurement from below: the shape a feedback junction
%   has in the MSS demonstration models.
add_sum(s, 'p_e', '+-', [330 200]);
route(s, 'p_d',         1, 'p_e', 1, zeros(0,2));
route(s, 'p = x(7:8)',  1, 'p_e', 2, [330 320]);

%% ---- 3) 선체 좌표로 돌린다 / rotate into the body frame ------------------
blk = [s '/to body'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [400 150 540 300]);
set_mlfcn(blk, { ...
'function p_b = to_body(p_e, psi)'
'% Rotate the position error from NED into the body frame.'
'%'
'%            [ cos(psi)  -sin(psi) ]'
'%   R(psi) = [ sin(psi)   cos(psi) ]     maps the BODY frame to NED,'
'%'
'% so the transpose maps NED to the body frame. R is orthogonal, so the'
'% transpose is the inverse and nothing is lost in the change of frame: the'
'% distance to the target is the same number in either one.'
'c = cos(psi);'
's = sin(psi);'
'p_b = [  c*p_e(1) + s*p_e(2) ;      % 전진 방향의 오차 / along the bow'
'        -s*p_e(1) + c*p_e(2) ];     % 우현 방향의 오차 / to starboard'
'end'}, 'p_b', '[2 1]');
route(s, 'p_e',          1, 'to body', 1, zeros(0,2));
route(s, 'psi = x(12)',  1, 'to body', 2, [380 400; 380 250]);

%% ---- 4) P 게인과 속도 한계 / the proportional gain and the speed limits ---
gain(s, 'Kp_pos', 'Kp_pos', [600 207 660 243]);
add_block('simulink/Discontinuities/Saturation', [s '/speed limit'], ...
          'UpperLimit', '[ u_lim;  v_lim]', ...
          'LowerLimit', '[-u_lim; -v_lim]', ...
          'Position', [710 207 760 243]);
route(s, 'to body', 1, 'Kp_pos',      1, zeros(0,2));
route(s, 'Kp_pos',  1, 'speed limit', 1, zeros(0,2));

%% ---- 5) 멈추라는 신호 / the signal that says stop ------------------------
add_block('simulink/Math Operations/Product', [s '/stop gate'], ...
          'Inputs','2', 'Multiplication','Element-wise(.*)', ...
          'Position', [820 180 850 270]);
riser(s, 'speed limit', 1, 'stop gate', 1, 790);
riser(s, 'gate',        1, 'stop gate', 2, 800);

%% ---- 6) 거리. 단계 기계가 쓴다 / the distance, used by the phase machine --
add_block('simulink/User-Defined Functions/Fcn', [s '/distance'], ...
          'Expr','sqrt(u(1)^2 + u(2)^2)', 'Position', [400 420 500 456]);
route(s, 'p_e', 1, 'distance', 1, [365 200; 365 438]);

%% ---- 배선의 끝 / the two outputs ----------------------------------------
at(s, 'nu_d', port_xy(s,'stop gate','Outport',1) + [100 0]);
at(s, 'd',    port_xy(s,'distance', 'Outport',1) + [ 90 0]);
route(s, 'stop gate', 1, 'nu_d', 1, zeros(0,2));
route(s, 'distance',  1, 'd',    1, zeros(0,2));

set_param([s '/p_e'], 'NamePlacement','alternate');
end

% =========================================================================
function sel(s, name, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], 'InputPortWidth','12', ...
          'IndexOptions','Index vector (dialog)', 'Indices', mat2str(idx), ...
          'Position', pos);
end

function gain(s, name, val, pos)
add_block('simulink/Math Operations/Gain', [s '/' name], 'Gain', val, 'Position', pos);
end

function at(s, name, p)
%  포트 블록의 세로 중심을 p(2) 에 맞춘다 / centre the port block on p(2)
set_param([s '/' name], 'Position', [p(1)-30 p(2)-7 p(1) p(2)+7]);
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end

function riser(sys, src, sp, dst, dp, x)
%  가로 - 세로 - 가로. 두 포트의 높이를 모두 **읽으므로** 비스듬한 조각이 남지
%  않는다. 높이를 숫자로 적어 두면 mss_style 이 블록 크기를 바꿀 때 어긋난다.
%  Horizontal, vertical, horizontal, with both heights READ from the ports: a
%  height written in by hand goes out of true the moment mss_style resizes.
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; x a(2); x b(2); b]);
end
