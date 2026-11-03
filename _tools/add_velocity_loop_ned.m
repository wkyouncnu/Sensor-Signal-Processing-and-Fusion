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
%  축마다 서브시스템 하나 / one subsystem per axis
%      선체고정 고리와 **같은 모양으로** 접는다 (사용자 지시, 2026-11-03).
%
%          velocity loop NED
%            ├── to NED               회전 1
%            ├── north speed control  n_d, n_fb -> N
%            ├── east speed control   e_d, e_fb -> E
%            └── to body              회전 2
%
%      6-7 절은 이 고리를 선체고정 고리와 **나란히 놓고** 무엇이 더 붙었는지를
%      묻는다. 한쪽만 접어 두면 그 비교가 "블록이 몇 개인가" 가 되어 버린다.
%      둘을 같은 모양으로 접으면 남는 차이가 **회전 둘**뿐이고, 그것이 이 절이
%      말하려는 전부다.
%      Section 6-7 puts this loop beside the body-fixed one and asks what has
%      been added. Folded the same way, the only remaining difference is the
%      two rotations, which is the whole point of that section.
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
%      그래서 두 서브시스템의 Gain 블록 값이 **글자까지 같다** — 더블클릭해
%      둘을 비교하면 그것이 바로 보인다.
%
%  왜 포화 한계가 느슨한가 / why the saturation limits are loose
%      선체고정 고리의 횡 PI 는 자기 축의 액추에이터 정격을 안다 (Y_max 35.13 N).
%      NED 의 북 PI 는 그것을 모른다 — 선수각에 따라 전진 추진기 둘이 낼 수도 있고
%      선수추진기가 낼 수도 있다. 참된 한계는 **배분기가 세 추진기의 회전수를
%      자를 때** 비로소 드러나므로, 여기서는 2 X_max 로 느슨히 두고 안티와인드업이
%      그만큼 늦게 걸린다. 이것이 NED 전략이 치르는 **두 번째 값**이다.
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

%% ---- 축마다 서브시스템 하나 / one subsystem per axis ----------------------
axis_loop_ned(s, 'north speed control', [740 200 920 340], ...
              'n_d', 'n_fb', 'N', 'e_n', 'I_n', 'N raw', 'north limit', ...
              'N - N raw', 'Kb_n');
axis_loop_ned(s, 'east speed control',  [740 560 920 700], ...
              'e_d', 'e_fb', 'E', 'e_e', 'I_e', 'E raw', 'east limit',  ...
              'E - E raw', 'Kb_e');

%% ---- 1) 요구값을 축별로 가른다 / split the command into its two axes ------
%  선택기를 **먹이는 포트의 높이로** 놓는다. 높이는 읽는다, 계산하지 않는다
q = port_xy(s, 'north speed control', 'Inport', 1);
sel(s, 'n_d = nu_d_n(1)', 2, 1, [150 q(2)-18 290 q(2)+18]);
q = port_xy(s, 'east speed control',  'Inport', 1);
sel(s, 'e_d = nu_d_n(2)', 2, 2, [150 q(2)-18 290 q(2)+18]);

at(s, 'nu_d_n', port_xy(s, 'n_d = nu_d_n(1)', 'Inport', 1));
route(s, 'nu_d_n', 1, 'n_d = nu_d_n(1)', 1, zeros(0,2));
riser(s, 'nu_d_n', 1, 'e_d = nu_d_n(2)', 1, 120);

%% ---- 2) 회전 하나 — 측정 속도를 NED 로 / rotation one, into NED ----------
sel(s, 'nu = x(1:2)', 12, [1 2], [150  932 290  968]);
sel(s, 'psi = x(12)', 12,    12, [150 1132 290 1168]);
at(s, 'x', port_xy(s, 'nu = x(1:2)', 'Inport', 1));
route(s, 'x', 1, 'nu = x(1:2)', 1, zeros(0,2));
riser(s, 'x', 1, 'psi = x(12)', 1, 135);

blk = [s '/to NED'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [340 900 480 1100]);
set_mlfcn(blk, { ...
'function nu_n = to_ned(nu, psi)'
'c = cos(psi);'
's = sin(psi);'
'nu_n = [ c*nu(1) - s*nu(2) ;      % 북쪽으로 가는 빠르기 / speed to the north'
'         s*nu(1) + c*nu(2) ];     % 동쪽으로 가는 빠르기 / speed to the east'
'end'}, 'nu_n', '[2 1]');
route(s, 'nu = x(1:2)', 1, 'to NED', 1, zeros(0,2));
riser(s, 'psi = x(12)', 1, 'to NED', 2, 315);

%  되먹임을 축별로 가른다. 바깥에서 들어오지 않고 **이 고리 안에서** 만든다
q = port_xy(s, 'north speed control', 'Inport', 2);
sel(s, 'n_fb = nu_n(1)', 2, 1, [540 q(2)-18 680 q(2)+18]);
q = port_xy(s, 'east speed control',  'Inport', 2);
sel(s, 'e_fb = nu_n(2)', 2, 2, [540 q(2)-18 680 q(2)+18]);
riser(s, 'to NED', 1, 'n_fb = nu_n(1)', 1, 505);
riser(s, 'to NED', 1, 'e_fb = nu_n(2)', 1, 520);

%% ---- 3) 축으로 들어가고 나온다 / into each axis, and out ------------------
route(s, 'n_d = nu_d_n(1)', 1, 'north speed control', 1, zeros(0,2));
route(s, 'n_fb = nu_n(1)',  1, 'north speed control', 2, zeros(0,2));
route(s, 'e_d = nu_d_n(2)', 1, 'east speed control',  1, zeros(0,2));
route(s, 'e_fb = nu_n(2)',  1, 'east speed control',  2, zeros(0,2));

%% ---- 4) 회전 둘 — 요구 힘을 선체고정으로 / rotation two, back to the hull -
blk = [s '/to body'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [1070 330 1210 570]);
set_mlfcn(blk, { ...
'function tau_uv = to_body(F_n, psi)'
'c = cos(psi);'
's = sin(psi);'
'tau_uv = [  c*F_n(1) + s*F_n(2) ;    % 전진 방향의 힘 / along the bow'
'           -s*F_n(1) + c*F_n(2) ];   % 우현 방향의 힘 / to starboard'
'end'}, 'tau_uv', '[2 1]');

add_block('simulink/Signal Routing/Mux', [s '/F_n mux'], 'Inputs','2', ...
          'Position', [1000 330 1005 570]);
riser(s, 'north speed control', 1, 'F_n mux', 1, 960);
riser(s, 'east speed control',  1, 'F_n mux', 2, 975);
riser(s, 'F_n mux',     1, 'to body', 1, 1040);
riser(s, 'psi = x(12)', 1, 'to body', 2, 1300);

at(s, 'tau_uv', port_xy(s, 'to body', 'Outport', 1) + [105 0]);
route(s, 'to body', 1, 'tau_uv', 1, zeros(0,2));
end

% =========================================================================
function axis_loop_ned(parent, name, pos, cmdName, fbName, outName, ...
                       eName, iName, rawName, satName, bckName, kbName)
%AXIS_LOOP_NED  NED 한 축의 PI 를 서브시스템 하나로. 안의 모양이 선체고정
%               고리의 axis_loop 과 **같다**. 다른 것은 둘뿐이다 — 게인 이름이
%               축마다 다르지 않고 Kp_ned·Ki_ned 하나이고, 포화 한계가 느슨하다.
%               One NED axis as a subsystem. The shape inside is the body-fixed
%               loop's, with two differences: one gain pair serves both axes,
%               and the limit is loose.

s = add_subsys(parent, name, pos, {cmdName, fbName}, {outName}, ...
               gnc_colour('controller'));
y0 = 200;

add_sum(s, eName, '+-', [330 y0]);
at(s, cmdName, [150 y0]);
at(s, fbName,  [150 y0+100]);
route(s, cmdName, 1, eName, 1, zeros(0,2));
route(s, fbName,  1, eName, 2, [330 y0+100]);

gain(s, 'Kp', 'Kp_ned', [400 y0- 18 460 y0+ 18]);
gain(s, 'Ki', 'Ki_ned', [400 y0+102 460 y0+138]);
route(s, eName, 1, 'Kp', 1, zeros(0,2));
route(s, eName, 1, 'Ki', 1, [370 y0; 370 y0+120]);

add_sum(s, ['into ' iName], '++', [520 y0+120]);
add_block('simulink/Continuous/Integrator', [s '/' iName], ...
          'InitialCondition','0', 'Position', [580 y0+102 620 y0+138]);
route(s, 'Ki',            1, ['into ' iName], 1, zeros(0,2));
route(s, ['into ' iName], 1, iName,           1, zeros(0,2));

add_sum(s, rawName, '++', [680 y0]);
route(s, 'Kp',  1, rawName, 1, zeros(0,2));
route(s, iName, 1, rawName, 2, [680 y0+120]);

%  한계가 느슨하다. 참된 한계는 배분기가 회전수를 자를 때 드러난다
add_block('simulink/Discontinuities/Saturation', [s '/' satName], ...
          'UpperLimit','2*X_max', 'LowerLimit','-2*X_max', ...
          'Position', [730 y0-18 780 y0+18]);
route(s, rawName, 1, satName, 1, zeros(0,2));

add_sum(s, bckName, '-+', [660 y0+260]);
set_param([s '/' bckName], 'Orientation','left');
gain(s, kbName, 'Kb', [540 y0+242 590 y0+278]);
set_param([s '/' kbName], 'Orientation','left');
riser(s, rawName, 1, bckName, 1, 710);
riser(s, satName, 1, bckName, 2, 820);
route(s, bckName, 1, kbName, 1, zeros(0,2));
riser(s, kbName, 1, ['into ' iName], 2, 500);

at(s, outName, port_xy(s, satName, 'Outport', 1) + [120 0]);
route(s, satName, 1, outName, 1, zeros(0,2));

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
