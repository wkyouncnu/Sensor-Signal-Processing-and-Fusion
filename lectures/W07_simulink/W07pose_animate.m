function W07pose_animate(y, t)
%W07POSE_ANIMATE  `W07_pose_dp` 의 Animate 블록이 매 스텝 부르는 래퍼.
%                 The thin wrapper the Animate block of W07_pose_dp calls.
%
%   이름은 꼬리표 `W07pose` 가 정한다 — `add_measurement` 이 블록 안에
%   `<tag>_animate` 를 적는다. 그리는 쪽은 `W07_anim` 하나다 (§15-34).
%   The name follows the tag, and the drawing is in W07_anim.
%
%   축 범위만 다른 것이 아니다 / the limits are not a detail
%       웨이포인트 모델은 60 m 격자를 돌지만 이 모델은 **10 m** 를 간다.
%       같은 축(-60…140 m)으로 그리면 배가 화면 가운데 한 점으로 보이고
%       45 도 선수각 명령을 따라가는지 전혀 보이지 않는다. 그래서 이 창은
%       목표 자세를 중심으로 좁게 잡는다.
%       The waypoint model drives a 60 m grid; this one travels 10 m. On the
%       same axes the vessel is a dot and nothing about the 45 deg heading
%       command is visible, so this window opens tight around the target.
%
%   로그 열 / the logged columns      (add_measurement 이 정한 순서)
%       1 u   2 v   3 r   4 N   5 E   6 psi [deg]
%       7-8 p_d [N E]   9 psi_d [deg]   10-11 nu_d [u_d v_d]
%       12-14 tau asked [X Y N]         15-17 tau applied [X Y N]
%
%   See also W07_ANIM, W07_PLOT_POSE, W07_4_BUILD_POSE.

pd = base_var('p_d', [10; 10]);

o.tag   = 'W07pose_anim';
o.name  = 'W07 live view  -  position hold';
o.lim   = [-6, max(pd(2)) + 8, -6, max(pd(1)) + 8];
o.wp    = [];
o.goal  = [pd(1), pd(2), rad2deg(base_var('psi_set', pi/4))];
o.cmdNE = [7 8];                   % 바깥 고리가 위치를 명령한다 / a position command
o.info  = {'N', 4, 1; 'E', 5, 1; '\psi', 6, 1; ...
           'N_d', 7, 1; 'E_d', 8, 1; '\psi_d', 9, 1};

%  점선이 명령, 실선이 실제. 다섯 칸 모두 같다 / dashed command, solid actual
o.panels = { ...
    {'north  [m]',  [4 7],   {'-','--'}, {'act','cmd'}, ...
     {'N  actual','N_d  command'},                           false}, ...
    {'east  [m]',   [5 8],   {'-','--'}, {'act','cmd'}, ...
     {'E  actual','E_d  command'},                           false}, ...
    {'\psi  [deg]', [6 9],   {'-','--'}, {'act','cmd'}, ...
     {'\psi  actual','\psi_d  command'},                     false}, ...
    {'u , v  [m/s]', [1 2 10 11], {'-','-','--','--'}, ...
     {'act','sway','act','sway'}, ...
     {'u  actual','v  actual','u_d  outer loop','v_d  outer loop'}, true}, ...
    {'\tau_X , \tau_Y  [N]', [15 16 12 13], {'-','-','--','--'}, ...
     {'act','sway','cmd','aux'}, ...
     {'X applied','Y applied','X asked','Y asked'},          true}};

W07_anim(y, t, o);
end
