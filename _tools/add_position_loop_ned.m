function s = add_position_loop_ned(m, pos)
%ADD_POSITION_LOOP_NED  NED 좌표에서 도는 바깥 고리 — 위치 P 가 **NED 속도**를 요구한다
%
%  왜 따로 두는가 / why this exists next to add_position_loop
%      add_position_loop 은 위치 오차를 **선체고정**으로 돌려 놓고 (회전 한 번),
%      전진·횡 속도를 요구한다. 이 파일은 그 회전을 **하지 않는다** — 오차를 NED
%      에서 그대로 쓰고, 북·동 속도를 요구한다. 회전은 안쪽 고리로 내려간다
%      (add_velocity_loop_ned 가 측정 속도와 요구 힘에 **두 번** 쓴다).
%      That single difference is the whole lesson of Section 6-7, and it is
%      visible from the port list alone: this subsystem has **no psi port**.
%
%  법칙 / the law
%      p_e   = p_d - p                        (NED, 북·동)
%      nu_p  = Kp_pos p_e                     (NED 속도 요구, 자르기 전)
%      nu_d  = cap(nu_p, v_ned_max)           **크기**로 자른다
%      nu_d  <- nu_d * gate                   도착하면 0 으로 닫는다
%      d     = |p_e|
%
%  왜 축마다 자르지 않고 **크기**로 자르는가 / why the cap is by magnitude
%      두 축을 따로 0.35 로 자르면 비스듬한 방향에서 0.35*sqrt(2) = 0.495 m/s 가
%      되어 한계를 넘는다. 크기로 자르면 **방향은 그대로 두고 빠르기만** 줄어든다.
%      그리고 그 한계값은 **느린 축의 것**이어야 한다 — NED 의 북 1 m/s 는 선수각에
%      따라 전진일 수도 있고 횡이동일 수도 있고, 횡은 0.35 m/s 밖에 못 낸다.
%      선체고정 고리는 축마다 다른 한계 (u_lim 0.80, v_lim 0.35) 를 쓸 수 있었다.
%      이것이 NED 전략이 치르는 **첫 번째 값**이다: 접근이 느리다.
%
%  포트 / ports
%      in   p_d [2x1]  목표 [N; E]
%           x   [12x1] 플랜트 상태 (7:8 이 위치다)
%           gate        도착 래치. 1 이면 가고 0 이면 선다
%      out  nu_d [2x1] 요구 NED 속도 [북; 동]
%           d           목표까지 남은 거리
%
%  쓰는 작업공간 변수 / workspace variables used
%      Kp_pos     위치 P 게인 [1/s]            — 선체고정 고리와 같은 값을 쓴다
%      v_ned_max  NED 속도 크기 한계 [m/s]     — 느린 축의 한계 (v_lim)
%
%  근거 / sources
%      Fossen (2021) §15.3 의 DP 바깥 고리. 캡스톤 W06 의 addOuterLoopNED.m 과
%      같은 구조이며, 벡터 하나로 묶고 한계를 Parameter 로 돌린 것만 다르다.

if nargin < 2 || isempty(pos), pos = [300 100 460 220]; end

s = add_subsys(m, 'position loop NED', pos, {'p_d','x','gate'}, {'nu_d','d'}, ...
               gnc_colour('controller'));

%  포트 높이를 먼저 잡는다. 회전 블록이 없으므로 전진 경로는 **y 200 한 줄**이다
set_param([s '/p_d'],  'Position', [ 60 193  90 207]);
set_param([s '/x'],    'Position', [ 60 313  90 327]);
set_param([s '/gate'], 'Position', [ 60 513  90 527]);

%  1) 위치만 꺼낸다. **psi 는 꺼내지 않는다** — 그것이 이 고리의 요점이다
sel(s, 'p = x(7:8)', [7 8], [150 302 260 338]);
route(s, 'x', 1, 'p = x(7:8)', 1, zeros(0,2));

%  2) NED 오차 / the error, left in NED
add_sum(s, 'p_e', '+-', [330 200]);
route(s, 'p_d',        1, 'p_e', 1, zeros(0,2));
route(s, 'p = x(7:8)', 1, 'p_e', 2, [330 320]);

%  3) P 게인이 **NED 오차에 바로** 걸린다. 돌려 놓는 블록이 중간에 없다
gain(s, 'Kp_pos', 'Kp_pos', [430 182 490 218]);
route(s, 'p_e', 1, 'Kp_pos', 1, zeros(0,2));

%  4) 크기로 자른다. 한계는 Parameter 라 포트가 생기지 않는다 (mlfcn_params)
blk = [s '/cap speed'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [560 160 700 240]);
set_mlfcn(blk, { ...
'function nu_d = cap_speed(nu_p, v_ned_max)'
'%  방향은 그대로, 빠르기만 줄인다 / keep the direction, shrink the speed'
'sp = sqrt(nu_p(1)^2 + nu_p(2)^2);'
'if sp > v_ned_max'
'    nu_d = nu_p * (v_ned_max/sp);'
'else'
'    nu_d = nu_p;'
'end'
'end'}, 'nu_d', '[2 1]');
mlfcn_params(blk, {'v_ned_max'});
route(s, 'Kp_pos', 1, 'cap speed', 1, zeros(0,2));

%  5) 도착 래치. 선체고정 고리와 **똑같은** 블록이다
add_block('simulink/Math Operations/Product', [s '/stop gate'], ...
          'Inputs','2', 'Multiplication','Element-wise(.*)', ...
          'Position', [820 180 850 270]);
riser(s, 'cap speed', 1, 'stop gate', 1, 790);
riser(s, 'gate',      1, 'stop gate', 2, 800);

%  6) 남은 거리. 좌표계와 무관하므로 선체고정 고리와 같다
add_block('simulink/User-Defined Functions/Fcn', [s '/distance'], ...
          'Expr','sqrt(u(1)^2 + u(2)^2)', 'Position', [400 420 500 456]);
route(s, 'p_e', 1, 'distance', 1, [365 200; 365 438]);

at(s, 'nu_d', port_xy(s,'stop gate','Outport',1) + [100 0]);
at(s, 'd',    port_xy(s,'distance', 'Outport',1) + [ 90 0]);
route(s, 'stop gate', 1, 'nu_d', 1, zeros(0,2));
route(s, 'distance',  1, 'd',    1, zeros(0,2));

set_param([s '/p_e'], 'NamePlacement','alternate');
end

% ---- 지역 헬퍼. add_position_loop 의 것을 그대로 쓴다 ----------------------
function sel(s, name, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], 'InputPortWidth','12', ...
          'IndexOptions','Index vector (dialog)', 'Indices', mat2str(idx), 'Position', pos);
end

function gain(s, name, val, pos)
add_block('simulink/Math Operations/Gain', [s '/' name], 'Gain', val, 'Position', pos);
end

function at(s, name, p)
set_param([s '/' name], 'Position', [p(1)-30 p(2)-7 p(1) p(2)+7]);
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; via; b]);
end

function riser(sys, src, sp, dst, dp, x)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; x a(2); x b(2); b]);
end
