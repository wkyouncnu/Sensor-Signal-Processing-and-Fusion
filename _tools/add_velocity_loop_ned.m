function s = add_velocity_loop_ned(m, pos)
%ADD_VELOCITY_LOOP_NED  NED 속도를 지키는 안쪽 고리 — 회전이 **두 번** 들어간다
%
%  왜 따로 두는가 / why this exists next to add_velocity_loop
%      add_velocity_loop 은 선체고정 속도 (u, v) 를 지킨다. 측정값도 선체고정이고
%      내놓는 힘도 선체고정이므로 **회전이 없다.**
%      이 파일은 **북·동 속도**를 지킨다. 측정 속도는 선체고정으로 재므로 들어올 때
%      한 번 돌리고, 내놓는 힘은 추진기가 선체고정에서 받으므로 나갈 때 한 번 돌린다.
%      회전 두 번이 **이 고리 안에** 있고, 바깥 고리에는 하나도 없다.
%
%  법칙 / the law  (축 두 개가 **같은 게인**을 쓴다)
%      nu_n   = R(psi) nu                     측정 속도를 NED 로      <- 회전 1
%      e      = nu_d_n - nu_n                 북·동 각각의 오차
%      F_raw  = Kp_ned e + I
%      I'     = Ki_ned e + Kb (F - F_raw)     back-calculation 안티와인드업
%      F      = sat(F_raw)                    느슨한 한계 2 X_max
%      tau_uv = R(psi)' F_n                   힘을 선체고정으로        <- 회전 2
%
%  왜 두 축이 **게인 하나**를 쓰는가 / why one gain pair serves both axes
%      선체고정 고리는 전진축과 횡축이 물리적으로 다르므로 게인이 달랐다
%      (Kp_u 200 / Kp_v 150, M(1,1) 85.5 대 M(2,2) 162.5). NED 의 북축은
%      선수각에 따라 전진일 때도 있고 횡일 때도 있다 — 게인을 전진에 맞추면
%      배가 돌아섰을 때 과도해진다. 그래서 **느린 축의 값**을 두 축에 함께 쓴다.
%
%  왜 포화 한계가 느슨한가 / why the saturation limits are loose
%      선체고정 고리의 횡 PI 는 자기 축의 액추에이터 정격을 안다 (Y_max 35.13 N).
%      NED 의 북 PI 는 그것을 모른다 — 선수각에 따라 전진 추진기 둘이 낼 수도 있고
%      선수추진기가 낼 수도 있다. 참된 한계는 **배분기가 F_B 를 자를 때** 비로소
%      드러나므로, 여기서는 2 X_max 로 느슨히 두고 안티와인드업이 그만큼 늦게 걸린다.
%      이것이 NED 전략이 치르는 **두 번째 값**이다.
%
%  포트 / ports
%      in   nu_d_n [2x1]  요구 NED 속도 [북; 동]
%           x      [12x1] 플랜트 상태 (1:2 가 u·v, 12 가 psi 다)
%      out  tau_uv [2x1]  선체고정 요구 힘 [X; Y]
%
%  쓰는 작업공간 변수 / workspace variables used
%      Kp_ned, Ki_ned   두 축이 함께 쓰는 PI 게인
%      Kb               안티와인드업 되돌림 게인 (선체고정 고리와 같은 값)
%      X_max            한계를 느슨히 잡을 기준값
%
%  근거 / sources
%      Fossen (2021) §15.3. 캡스톤 W06 의 addInnerLoopNED.m 과 같은 구조이며,
%      psi 를 따로 받지 않고 x 에서 꺼내는 것만 다르다.

if nargin < 2 || isempty(pos), pos = [480 100 640 220]; end

s = add_subsys(m, 'velocity loop NED', pos, {'nu_d_n','x'}, {'tau_uv'}, ...
               gnc_colour('controller'));

set_param([s '/nu_d_n'], 'Position', [ 60  193  90  207]);
set_param([s '/x'],      'Position', [ 60  993  90 1007]);

%% 1) 요구값을 축별로 가른다 / split the command into its two axes
sel(s, 'n_d = nu_d_n(1)', 2, 1, [150 182 260 218]);
sel(s, 'e_d = nu_d_n(2)', 2, 2, [150 542 260 578]);
route(s, 'nu_d_n', 1, 'n_d = nu_d_n(1)', 1, zeros(0,2));
route(s, 'nu_d_n', 1, 'e_d = nu_d_n(2)', 1, [115 200; 115 560]);

%% 2) 회전 하나 — 측정 속도를 NED 로 / rotation one, the measurement into NED
sel(s, 'nu = x(1:2)', 12, [1 2], [150  932 260  968]);
sel(s, 'psi = x(12)', 12,    12, [150 1132 260 1168]);
route(s, 'x', 1, 'nu = x(1:2)', 1, [120 1000; 120  950]);
route(s, 'x', 1, 'psi = x(12)', 1, [130 1000; 130 1150]);

blk = [s '/to NED'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [330 900 470 1100]);
set_mlfcn(blk, { ...
'function nu_n = to_ned(nu, psi)'
'c = cos(psi);'
's = sin(psi);'
'nu_n = [ c*nu(1) - s*nu(2) ;      % 북쪽으로 가는 빠르기 / speed to the north'
'         s*nu(1) + c*nu(2) ];     % 동쪽으로 가는 빠르기 / speed to the east'
'end'}, 'nu_n', '[2 1]');
route(s, 'nu = x(1:2)', 1, 'to NED', 1, zeros(0,2));
route(s, 'psi = x(12)', 1, 'to NED', 2, [300 1150; 300 1050]);

%  되먹임을 축별로 가른다. 바깥에서 들어오지 않고 **이 고리 안에서** 만든다
sel(s, 'n_fb = nu_n(1)', 2, 1, [530 282 640 318]);
sel(s, 'e_fb = nu_n(2)', 2, 2, [530 642 640 678]);
route(s, 'to NED', 1, 'n_fb = nu_n(1)', 1, [500 1000; 500 300]);
route(s, 'to NED', 1, 'e_fb = nu_n(2)', 1, [510 1000; 510 660]);

%% 3) 축 둘, **같은 게인** / the two axes, with one gain pair
pi_axis_ned(s, 200, 'n_d = nu_d_n(1)', 'n_fb = nu_n(1)', ...
            'e_n', 'I_n', 'N raw', 'north limit', 'N - N raw', 'Kb_n');
pi_axis_ned(s, 560, 'e_d = nu_d_n(2)', 'e_fb = nu_n(2)', ...
            'e_e', 'I_e', 'E raw', 'east limit',  'E - E raw', 'Kb_e');

%% 4) 회전 둘 — 요구 힘을 선체고정으로 / rotation two, the force back into the hull
add_block('simulink/Signal Routing/Mux', [s '/F_n mux'], 'Inputs','2', ...
          'Position', [1280 200 1285 500]);
riser(s, 'north limit', 1, 'F_n mux', 1, 1230);
riser(s, 'east limit',  1, 'F_n mux', 2, 1240);

blk = [s '/to body'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [1340 300 1480 500]);
set_mlfcn(blk, { ...
'function tau_uv = to_body(F_n, psi)'
'c = cos(psi);'
's = sin(psi);'
'tau_uv = [  c*F_n(1) + s*F_n(2) ;    % 전진 방향의 힘 / along the bow'
'           -s*F_n(1) + c*F_n(2) ];   % 우현 방향의 힘 / to starboard'
'end'}, 'tau_uv', '[2 1]');
route(s, 'F_n mux',     1, 'to body', 1, zeros(0,2));
route(s, 'psi = x(12)', 1, 'to body', 2, [1310 1150; 1310 450]);

at(s, 'tau_uv', port_xy(s,'to body','Outport',1) + [105 0]);
route(s, 'to body', 1, 'tau_uv', 1, zeros(0,2));
end

% =========================================================================
function pi_axis_ned(s, y0, cmdSel, fbSel, eName, iName, rawName, satName, bckName, kbName)
%  띠 하나의 모양은 add_velocity_loop 의 pi_axis 와 같다. 다른 것은 둘뿐이다 —
%  측정값 Selector 를 **이 안에서 만들지 않고** (회전 뒤에 이미 갈라 두었다),
%  게인 이름이 축마다 다르지 않고 **Kp_ned · Ki_ned 하나**다
%      y0        명령 · 오차 · Kp · 요구 힘 · 포화          the forward path
%      y0 + 120  Ki · 적분기                                 the integral path
%      y0 + 260  안티와인드업이 돌아오는 통로                the return lane

add_sum(s, eName, '+-', [730 y0]);
route(s, cmdSel, 1, eName, 1, zeros(0,2));
route(s, fbSel,  1, eName, 2, [730 y0+100]);

gain(s, ['Kp ' eName], 'Kp_ned', [800 y0- 18 860 y0+ 18]);
gain(s, ['Ki ' eName], 'Ki_ned', [800 y0+102 860 y0+138]);
route(s, eName, 1, ['Kp ' eName], 1, zeros(0,2));
route(s, eName, 1, ['Ki ' eName], 1, [770 y0; 770 y0+120]);

add_sum(s, ['into ' iName], '++', [920 y0+120]);
add_block('simulink/Continuous/Integrator', [s '/' iName], ...
          'InitialCondition','0', 'Position', [980 y0+102 1020 y0+138]);
route(s, ['Ki ' eName],   1, ['into ' iName], 1, zeros(0,2));
route(s, ['into ' iName], 1, iName,           1, zeros(0,2));

add_sum(s, rawName, '++', [1080 y0]);
route(s, ['Kp ' eName], 1, rawName, 1, zeros(0,2));
route(s, iName,         1, rawName, 2, [1080 y0+120]);

%  한계가 느슨하다. 참된 한계는 배분기가 F_B 를 자를 때 드러난다
add_block('simulink/Discontinuities/Saturation', [s '/' satName], ...
          'UpperLimit','2*X_max', 'LowerLimit','-2*X_max', ...
          'Position', [1130 y0-18 1180 y0+18]);
route(s, rawName, 1, satName, 1, zeros(0,2));

add_sum(s, bckName, '-+', [1060 y0+260]);
set_param([s '/' bckName], 'Orientation','left');
gain(s, kbName, 'Kb', [940 y0+242 990 y0+278]);
set_param([s '/' kbName], 'Orientation','left');
riser(s, rawName, 1, bckName, 1, 1110);
riser(s, satName, 1, bckName, 2, 1220);
route(s, bckName, 1, kbName, 1, zeros(0,2));
riser(s, kbName,  1, ['into ' iName], 2, 900);

for nm = {eName, ['into ' iName], rawName, bckName}
    set_param([s '/' nm{1}], 'NamePlacement','alternate');
end
end

% ---- 지역 헬퍼. add_velocity_loop 의 것을 그대로 쓴다 ----------------------
function sel(s, name, width, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], ...
          'InputPortWidth', num2str(width), ...
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
