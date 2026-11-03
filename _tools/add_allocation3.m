function s = add_allocation3(m, pos)
%ADD_ALLOCATION3  세 추진기에 대한 제어 배분을 서브시스템 하나로 넣는다 (6주차).
%                 Control allocation for three thrusters, as one subsystem.
%
%   s = add_allocation3(m, pos)
%
%     m     모델 이름 / the model
%     pos   서브시스템 자리 [x1 y1 x2 y2] / where the subsystem goes
%
%   들어가는 것 tau = [X; Y; N],  Binv,  k_pos, k_neg, k_bow
%   나오는 것   n = [n_L; n_R; n_B]  축 회전수 셋, 운동모델이 받는 그대로
%
%   배분은 추진기 모형을 거꾸로 푸는 것이다 / allocation is the actuator model
%   run backwards. 정방향은 세 단계다 (2025 강의 PPT 133 쪽):
%
%       u_i = n_i |n_i|           회전수에서 정규화 입력으로
%       f   = K u                 K = diag(k_1, k_2, k_3)
%       tau = B f                 B 는 열 규칙이 만든 3 x 3
%
%   거꾸로 가면
%
%       f = B^-1 tau,   u = K^-1 f,   n_i = sign(u_i) sqrt(|u_i|)
%
%   PPT 133·134 쪽은 이것을 u = T^-1 K^-1 tau 로 적었다. (TK)^-1 = K^-1 T^-1
%   이므로 순서가 뒤집혀 있다. K 가 대각이라 세 추진기의 계수가 모두 같을 때만
%   두 순서가 우연히 같고, 여기서는 선수추진기의 계수가 달라 같지 않다.
%   Slides 133 and 134 write the inverse as T^-1 K^-1. The correct order is
%   (TK)^-1 = K^-1 T^-1; the two agree only when every k_i is equal, which is
%   not the case once the bow unit has its own coefficient.
%
%   WHY inv(B) AND NOT THREE EQUATIONS BY HAND
%
%   With three thrusters against three planar degrees of freedom B is square and
%   non-singular (det B = 0.79), so the allocation IS one matrix inverse and the
%   block should say so. B itself is derived once by otter_B() from the column
%   rule and inverted once by the setup script; nothing here re-derives it, so
%   there is one definition of the geometry in the project and not two.
%
%   손으로 푼 해는 강의 본문(6-2 절)에 남는다. 그 자리에서 inv(B) 의 성분이
%   **왜** 그 값인지가 나온다:
%
%       F_B = Y                      선수추진기만 횡력 열을 가지므로 횡력
%                                    요구가 그것 하나를 결정한다
%       N_s = N - l_f F_B            남은 요각 요구
%       T_L = (X + N_s/y_pont)/2
%       T_R = (X - N_s/y_pont)/2
%
%   지렛대비 l_f/(2 y_pont) = 1.8987 이 셋째 줄에서 나온다 — 선수추진기가 1 N
%   으로 맞춘 횡력 때문에 선미 한 쌍이 1.8987 N 씩 반대로 일해야 그 모멘트가
%   지워진다. 횡방향 권한을 묶는 것은 선수추진기의 정격이 아니라 이 비다
%   (6-4 절). 그 값들은 inv(B) 의 성분과 **같아야** 하고, W06_0_setup 이
%   확인한다.
%
%   비교 / for comparison
%       7주차는 추진기가 넷이라 B 가 정사각이 아니고 pinv(B) 를 쓴다. 여기서는
%       정사각이므로 해가 하나뿐이고, 영공간이 없어 고를 것이 없다. 그 차이가
%       완전구동과 과구동의 차이다 (6-1 절).
%       Week 7 has four thrusters, a non-square B and pinv(B). Here B is square,
%       the solution is unique and there is no null space to choose within.
%
%   WHERE THE LIMIT IS APPLIED
%
%   The Saturation acts on the three SHAFT SPEEDS, after the inverse, because
%   that is the quantity the motion model receives and the quantity each unit
%   physically has a limit on. T = k n|n| is monotone and T_max = k_pos n_max^2,
%   so cutting the force at T_max and cutting the speed at n_max are the same
%   constraint written in two coordinates; applying it here means otter_bow.m's
%   own internal saturation never has anything left to do, and the limit the
%   student edits in W06_0_setup is the one visible on the diagram.
%
%   See also OTTER_B, OTTER_BOW, ADD_POSITION_LOOP, ADD_OTTER_PLANT.

if nargin < 2 || isempty(pos), pos = [700 100 860 220]; end

s = add_subsys(m, 'allocation', pos, ...
               {'tau','Binv','k_pos','k_neg','k_bow'}, {'n'}, ...
               gnc_colour('allocation'));

%% ---- 배분과 추력곡선 역산을 한 블록에 / the inverse, in one block --------
%   힘으로 가는 단계와 회전수로 가는 단계를 나누어 두면 학생이 둘 사이에서
%   길을 잃는다. PPT 133 쪽의 역방향 한 줄이 블록 하나다.
%   Splitting the force step from the shaft-speed step gives the student two
%   half-answers. One slide, one block.
blk = [s '/allocate'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [200 60 360 260]);
set_mlfcn(blk, { ...
'function n = allocate(tau, Binv, k_pos, k_neg, k_bow)'
'% Run the actuator model backwards: tau -> f -> u -> n.'
'%'
'%   forward    u_i = n_i|n_i|      f = K u        tau = B f'
'%   inverse    f = B^-1 tau        u = K^-1 f     n_i = sign(u_i) sqrt(|u_i|)'
'%'
'%   B    = [    1         1       0  ]    f   = [T_L; T_R; F_B]  [N]'
'%          [    0         0       1  ]    tau = [X; Y; N]        [N, N, N m]'
'%          [ y_pont   -y_pont   l_f ]'
'%'
'% B is square and non-singular (det B = 0.79), so the solution is unique and'
'% there is no null space to choose within. Binv comes from the setup script,'
'% which inverts the B that otter_B() derives from the column rule.'
'f = Binv * tau;'
''
'% K is diagonal, so K^-1 is three divisions. Which coefficient applies depends'
'% on the sign for a stern propeller, because a propeller pushing astern is'
'% less efficient than the same propeller pushing ahead. It does not depend on'
'% the sign for the bow unit: a tunnel thruster is symmetric.'
'k = [k_pos; k_pos; k_bow];'
'if f(1) < 0, k(1) = k_neg; end'
'if f(2) < 0, k(2) = k_neg; end'
''
'u = f ./ k;'
''
'% n_i = sign(u_i) sqrt(|u_i|). The absolute value is not decoration: slide 133'
'% writes sqrt(u_i), and without the |.| every astern command returns a complex'
'% shaft speed.'
'n = sign(u) .* sqrt(abs(u));'
'end'}, 'n', '[3 1]');

%% ---- 회전수 한계 / what each unit can actually turn ---------------------
%   선미는 전진과 후진이 비대칭이고, 선수 터널 추진기는 양쪽이 같다.
%   The stern propellers are asymmetric fore and aft; the bow unit is not.
add_block('simulink/Discontinuities/Saturation', [s '/shaft limit'], ...
          'UpperLimit', '[ n_max;  n_max;  n_bow_max]', ...
          'LowerLimit', '[ n_min;  n_min; -n_bow_max]', ...
          'Position', [430 142 480 178]);

%% ---- 배선 / wiring ------------------------------------------------------
%   포트 블록을 그것이 먹이는 포트의 높이로 옮긴다. 높이를 계산하지 않고 읽는다
%   (port_xy), 그래야 선이 가로로만 끝난다.
%   Each port block is moved to the height of the port it feeds. The heights are
%   READ, not calculated, which is what keeps every line horizontal.
in = {'tau','Binv','k_pos','k_neg','k_bow'};
for i = 1:numel(in)
    at(s, in{i}, port_xy(s, 'allocate', 'Inport', i));
    route(s, in{i}, 1, 'allocate', i, zeros(0,2));
end

route(s, 'allocate', 1, 'shaft limit', 1, zeros(0,2));
at(s, 'n', port_xy(s, 'shaft limit', 'Outport', 1) + [140 0]);
route(s, 'shaft limit', 1, 'n', 1, zeros(0,2));
end

% =========================================================================
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
