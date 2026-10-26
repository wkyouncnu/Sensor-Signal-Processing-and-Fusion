function s = add_allocation3(m, pos)
%ADD_ALLOCATION3  세 추진기에 대한 제어 배분을 서브시스템 하나로 넣는다 (6주차).
%                 Control allocation for three thrusters, as one subsystem.
%
%   s = add_allocation3(m, pos)
%
%     m     모델 이름 / the model
%     pos   서브시스템 자리 [x1 y1 x2 y2] / where the subsystem goes
%
%   들어가는 것 tau = [X; Y; N],  y_pont, l_f, k_pos, k_neg
%   나오는 것   n = [n_L; n_R] (축 회전수),  tau_ext = [0; F_B; l_f F_B]
%
%   WHY THE INVERSE IS WRITTEN OUT BY HAND
%
%   With three thrusters against three planar degrees of freedom B is square and
%   non-singular (det B = 0.79), so the allocation is one matrix inverse. A Gain
%   block holding inv(B) would compute it correctly and teach nothing. Written
%   out, the solution says WHY the numbers in inv(B) are what they are:
%
%       F_B = Y                              the bow thruster is the only
%                                            actuator with a sway column, so
%                                            the sway demand fixes it alone
%       N_s = N - l_f F_B                    what is left of the yaw demand once
%                                            the bow thruster's own moment is
%                                            accounted for
%       T_L = (X + N_s/y_pont)/2
%       T_R = (X - N_s/y_pont)/2
%
%   The lever ratio l_f/(2 y_pont) = 1.8987 falls out of the third line: a sway
%   demand the bow thruster meets with 1 N makes the stern pair work 1.8987 N
%   each, in opposition, purely to cancel the moment it produced. That ratio,
%   and not the bow unit's rating, is what limits the sway authority (6-4 절).
%
%   비교 / for comparison
%       7주차는 추진기가 넷이라 B 가 정사각이 아니고 pinv(B) 를 쓴다. 여기서는
%       정사각이므로 해가 하나뿐이고, 영공간이 없어 고를 것이 없다. 그 차이가
%       완전구동과 과구동의 차이다 (6-1 절).
%       Week 7 has four thrusters, a non-square B and pinv(B). Here B is square,
%       the solution is unique and there is no null space to choose within. That
%       difference is the difference between fully actuated and over-actuated.
%
%   WHERE THE LIMIT IS APPLIED
%
%   The Saturation acts on the three THRUSTS, not on the shaft speeds, because
%   T = k n|n| is monotone and T_max = k_pos n_max^2: cutting the force at
%   T_max and cutting the shaft speed at n_max are the same constraint written
%   in two coordinates. Applying it to the force is what makes the limit visible
%   on the diagram, and otter.m's own internal shaft-speed saturation then never
%   has anything left to do.
%
%   See also OTTER_B, ADD_POSITION_LOOP, ADD_OTTER_PLANT.

if nargin < 2 || isempty(pos), pos = [700 100 860 220]; end

s = add_subsys(m, 'allocation', pos, ...
               {'tau','y_pont','l_f','k_pos','k_neg'}, {'n','tau_ext'}, ...
               gnc_colour('allocation'));

%% ---- 1) 세 방정식을 푼다 / solve the three equations --------------------
blk = [s '/allocate'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [180 68 320 212]);
set_mlfcn(blk, { ...
'function f = allocate(tau, y_pont, l_f)'
'% Solve B f = tau for the three thrusts, by hand rather than with inv(B).'
'%'
'%   B = [    1         1       0  ]      f = [T_L; T_R; F_B]   [N]'
'%       [    0         0       1  ]      tau = [X; Y; N]       [N, N, N m]'
'%       [ y_pont   -y_pont   l_f ]'
'X = tau(1);  Y = tau(2);  N = tau(3);'
''
'% The second row of B has one non-zero entry, so the sway demand fixes the bow'
'% thruster on its own. This is the only line of the allocation that does not'
'% have to share a degree of freedom.'
'F_B = Y;'
''
'% The bow thruster sits l_f forward of the origin, so meeting the sway demand'
'% has already produced a yaw moment l_f*F_B whether that was wanted or not.'
'% What the stern pair has to produce is the remainder.'
'N_s = N - l_f*F_B;'
''
'% The stern pair: their sum is the surge demand, their difference is the'
'% remaining moment divided by the lever y_pont.'
'T_L = 0.5*(X + N_s/y_pont);'
'T_R = 0.5*(X - N_s/y_pont);'
''
'f = [T_L; T_R; F_B];'
'end'}, 'f', '[3 1]');

%% ---- 2) 추진기가 낼 수 있는 만큼으로 자른다 / limit to what each can give
%   세 성분의 한계가 서로 다르다. 선미는 전진과 후진이 비대칭이고 (119.68 대
%   -66.71), 선수 터널 추진기는 양쪽이 같다.
%   The three components have different limits: the stern propellers are
%   asymmetric fore and aft, the bow tunnel thruster is symmetric.
add_block('simulink/Discontinuities/Saturation', [s '/thrust limit'], ...
          'UpperLimit', '[ T_max;  T_max;  F_B_max]', ...
          'LowerLimit', '[ T_min;  T_min; -F_B_max]', ...
          'Position', [380 122 430 158]);

%% ---- 3) 선미와 선수로 갈라진다 / the stern pair and the bow unit part ways
sel(s, 'stern T',  [1 2], [490 122 590 158]);
sel(s, 'bow F_B',      3, [490 282 590 318]);

%% ---- 4) 추력 곡선을 거꾸로 푼다 / invert the thrust curve ---------------
blk = [s '/shaft speeds'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [650 68 790 212]);
set_mlfcn(blk, { ...
'function n = shaft_speeds(T, k_pos, k_neg)'
'% Invert T = k n|n| for the two stern propellers, so that what the allocation'
'% asked for in newtons reaches otter.m as the shaft speeds it takes.'
'%'
'% The coefficient differs by direction: a propeller pushing astern is less'
'% efficient than the same propeller pushing ahead, which is why T_min is'
'% -66.71 N where T_max is +119.68 N.'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        n(i) =  sqrt( T(i)/k_pos);'
'    else'
'        n(i) = -sqrt(-T(i)/k_neg);'
'    end'
'end'
'end'}, 'n', '[2 1]');

%% ---- 5) 선수추진기의 열 / the bow thruster's column ---------------------
%   힘 하나가 일반화 힘 셋이 된다. 그 세 성분이 B 의 셋째 **열**이고, 그래서 이
%   Gain 의 값이 열 규칙을 그대로 적은 것이다 (6-2 절).
%   One force becomes three generalized forces, and those three are the third
%   COLUMN of B. The value of this Gain is the column rule written out.
add_block('simulink/Math Operations/Gain', [s '/bow column'], ...
          'Gain', '[0; 1; l_f]', 'Multiplication', 'Element-wise(K.*u)', ...
          'Position', [650 282 710 318]);

%% ---- 배선 / wiring ------------------------------------------------------
%   계수 포트는 블록의 포트 높이에 맞춰 옮긴다. 높이를 계산하지 않고 읽는다
%   (port_xy), 그래야 선이 가로·세로만으로 끝난다.
%   The coefficient ports are moved to the port heights of the blocks they
%   feed. The heights are READ, not calculated, which is what keeps every line
%   horizontal or vertical.
at(s, 'tau',    port_xy(s,'allocate','Inport',1));
at(s, 'y_pont', port_xy(s,'allocate','Inport',2));
at(s, 'l_f',    port_xy(s,'allocate','Inport',3));
route(s, 'tau',    1, 'allocate', 1, zeros(0,2));
route(s, 'y_pont', 1, 'allocate', 2, zeros(0,2));
route(s, 'l_f',    1, 'allocate', 3, zeros(0,2));

route(s, 'allocate',     1, 'thrust limit', 1, zeros(0,2));
route(s, 'thrust limit', 1, 'stern T',      1, zeros(0,2));
riser(s, 'thrust limit', 1, 'bow F_B',      1, 460);

%  계수는 아래 통로를 지나 올라간다. 올라가는 x 를 셋 다 다르게 두어야 겹치지
%  않는다. 통로의 높이는 포트에서 읽는다 — 숫자를 적어 두면 mss_style 이 블록
%  크기를 바꿀 때 어긋난다 (실제로 한 번 어긋났다).
%  The coefficients run along a lane below and rise on distinct x. The height of
%  each lane is READ from the port: a number written in by hand goes out of true
%  the moment mss_style resizes the block.
set_param([s '/k_pos'], 'Position', [60 413  90 427]);
set_param([s '/k_neg'], 'Position', [60 473  90 487]);
riser(s, 'stern T', 1, 'shaft speeds', 1, 612);
riser(s, 'k_pos',   1, 'shaft speeds', 2, 626);
riser(s, 'k_neg',   1, 'shaft speeds', 3, 638);

route(s, 'bow F_B', 1, 'bow column', 1, zeros(0,2));

at(s, 'n',       port_xy(s,'shaft speeds','Outport',1) + [160 0]);
at(s, 'tau_ext', port_xy(s,'bow column','Outport',1)   + [160 0]);
route(s, 'shaft speeds', 1, 'n',       1, zeros(0,2));
route(s, 'bow column',   1, 'tau_ext', 1, zeros(0,2));
end

% =========================================================================
function sel(s, name, idx, pos)
add_block('simulink/Signal Routing/Selector', [s '/' name], 'InputPortWidth','3', ...
          'IndexOptions','Index vector (dialog)', 'Indices', mat2str(idx), ...
          'Position', pos);
end

function at(s, name, p)
%  포트 블록을 [x y] 높이에 맞춰 놓는다. 높이를 맞추는 것이 목적이므로 세로
%  중심이 p(2) 여야 한다 / place a port block so that its centre is at p(2)
set_param([s '/' name], 'Position', [p(1)-30 p(2)-7 p(1) p(2)+7]);
end

function route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; via; b]);
end

function riser(sys, src, sp, dst, dp, x)
%  가로 - 세로 - 가로. 두 포트의 높이를 모두 읽으므로 비스듬한 조각이 남지 않는다
%  horizontal, vertical, horizontal; both heights are read, so nothing is left
%  at an angle
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
add_line(sys, [a; x a(2); x b(2); b]);
end
