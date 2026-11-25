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
%       18-21 n [rad/s]                 22-25 delta [rad]
%
%   뒤의 여덟 열은 **한계를 지난 뒤**의 명령이다 / the last eight columns are
%   the commands AFTER clipping
%       위치 유지에서 이 여덟이 특히 중요하다. 정지한 배는 속도가 없어 선체의
%       저항이 거의 돕지 않으므로 네 단위가 서로를 밀며 버티고, 바람이나 초기
%       오차가 조금만 커져도 한계에 먼저 닿는 것은 제어기가 아니라 추진기다.
%       They matter most in position hold: a stationary hull gets almost no help
%       from its own damping, the four units push against each other to stand
%       still, and what reaches a limit first is the actuator, not the loop.
%
%   See also W07_ANIM, W07_PLOT_POSE, W07_PLOT_SAT, W07_4_BUILD_POSE.

%  명세를 **한 Run 에 한 번만** 만든다 — 이유는 `W07wpt_animate` 와 같다.
%  built ONCE per run, for the reason W07wpt_animate gives
persistent o tLastRun
if isempty(o) || isempty(tLastRun) || t < tLastRun
    o = pose_spec();
end
tLastRun = t;

W07_anim(y, t, o);
end

% =========================================================================
function o = pose_spec()
%POSE_SPEC  이 Run 에서 그릴 것 / what this run draws
pd = base_var('p_d', [10; 10]);

o.tag   = 'W07pose_anim';
o.name  = 'W07 live view  -  position hold';
o.T     = base_var('T_pose', 60);          % 제목의 시간 상한 / the title's time cap
o.lim   = [-6, max(pd(2)) + 8, -6, max(pd(1)) + 8];
o.wp    = [];
o.goal  = [pd(1), pd(2), rad2deg(base_var('psi_set', pi/4))];
o.cmdNE = [7 8];                   % 바깥 고리가 위치를 명령한다 / a position command
%  넷째 칸이 **단위**다. 숫자만 있는 제목은 읽는 사람이 deg 인지 rad 인지
%  되물어야 한다 (사용자 지시, 2026-11-25) / the fourth cell is the UNIT
o.info  = {'N', 4, 1, 'm'; 'E', 5, 1, 'm'; '\psi', 6, 1, 'deg'; ...
           'N_d', 7, 1, 'm'; 'E_d', 8, 1, 'm'; '\psi_d', 9, 1, 'deg'};

%  한계 둘. 배분기가 쓴 것과 **같은 값**을 읽는다 — 화면의 빨간 선과 모델
%  안의 포화가 어긋나면 그림이 거짓말을 한다
%  the two limits, read from the same variables the allocator saturates with
nlo  = base_var('n_min',     -101.74);
nhi  = base_var('n_max',      103.93);
alim = rad2deg(base_var('alpha_lim', pi/4));

%  점선이 명령, 실선이 실제. 앞의 여섯 칸이 모두 같다 / dashed command, solid
%  actual, in the first six panels. 뒤의 두 칸은 네 단위를 색으로 가른다
%  the last two separate the four units by colour, as W07_plot_sat does
%
%  힘은 **세 성분이 모두** 있어야 한다 / all three force components, always
%      $\tau_X$ 와 $\tau_Y$ 만 두면 배분기에 들어가는 요구 가운데 요 모멘트
%      하나가 화면에서 빠진다. 그러면 선수각이 명령을 따라가지 못할 때
%      그것이 **제어기가 적게 요구한 것인지, 네 단위가 못 낸 것인지** 를
%      이 창만 보고는 가를 수 없다. `W07_plot_sat` 이 저장하는 그림과
%      `W07wpt_animate` 는 처음부터 셋을 모두 그렸다 — 이 창만 빠져 있었다.
%      With only tau_X and tau_Y on screen, the yaw demand that enters the
%      allocator is invisible, and a heading that lags its command cannot be
%      blamed on the loop or on the four units from this window alone.
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
     {'X applied','Y applied','X asked','Y asked'},          true}, ...
    {'\tau_N  [N m]', [17 14], {'-','--'}, {'act','cmd'}, ...
     {'N applied','N asked'},                                true}, ...
    {'n  [rad/s]',  [18 19 20 21], {'-','-','-','-'}, ...
     {'u1','u2','u3','u4'}, {'n_1','n_2','n_3','n_4'},       true, ...
     1, [nlo nhi], {'n_{min}','n_{max}'}}, ...
    {'\delta  [deg]', [22 23 24 25], {'-','-','-','-'}, ...
     {'u1','u2','u3','u4'}, ...
     {'\delta_1','\delta_2','\delta_3','\delta_4'},          true, ...
     180/pi, alim*[-1 1], {'-\alpha_{max}','+\alpha_{max}'}}};

%  추진기 넷을 화살표로. 열 번호만 다르고 규칙은 wpt 와 **같다**
%  the same arrows as the wpt view; only the log columns differ
q = base_var('quad', []);
if isempty(q)
    o.thr = [];
else
    o.thr = struct('n',     18:21, ...
                   'd',     22:25, ...
                   'pos',   q(1:2,:), ...
                   'mount', q(4,:), ...
                   'kpos',  base_var('k_pos', 0.01108), ...
                   'kneg',  base_var('k_neg', 0.006445), ...
                   'Tref',  base_var('T_pos', 119.68));
end
end
