function W07wpt_animate(y, t)
%W07WPT_ANIMATE  `W07_wpt_los` 의 Animate 블록이 매 스텝 부르는 래퍼.
%                The thin wrapper the Animate block of W07_wpt_los calls.
%
%   이름은 고를 수 없다 / the name is not a choice
%       `add_measurement` 이 꼬리표 `W07wpt` 에서 `<tag>_animate` 를 만들어
%       블록 안에 적는다. 그래서 이 파일의 이름이 꼬리표를 따른다.
%       add_measurement writes <tag>_animate into the block, so the file name
%       follows the tag.
%
%   하는 일은 **그릴 것을 고르는 것뿐**이다. 그리는 쪽은 `W07_anim` 이고,
%   `W07pose_animate` 도 같은 함수를 부른다 (§15-34).
%   All this file does is choose what to draw; the drawing is in W07_anim,
%   which W07pose_animate calls as well.
%
%   로그 열 / the logged columns      (add_measurement 이 정한 순서)
%       1 u   2 v   3 r   4 N   5 E   6 psi [deg]
%       7 psi_d [deg]   8 u_d gated   9 y_e
%       10-12 tau asked [X Y N]       13-15 tau applied [X Y N]
%
%   See also W07_ANIM, W07_PLOT_WPT, W07_3_BUILD_WPT.

o.tag   = 'W07wpt_anim';
o.name  = 'W07 live view  -  waypoint following';
o.lim   = [base_var('track_Emin', -60), base_var('track_Emax', 140), ...
           base_var('track_Nmin', -60), base_var('track_Nmax', 140)];
o.wp    = [base_var('WP_N', 0), base_var('WP_E', 0)];
o.goal  = [];
o.cmdNE = [];                      % LOS 는 위치를 명령하지 않는다 / no position command
o.info  = {'\psi', 6, 1; '\psi_d', 7, 1; 'u', 1, 1; 'u_d', 8, 1; 'y_e', 9, 1};

%  점선이 명령, 실선이 실제. 다섯 칸 모두 같다 / dashed command, solid actual
o.panels = { ...
    {'\psi  [deg]',        [6 7],   {'-','--'},           {'act','cmd'}, ...
     {'\psi  actual','\psi_d  LOS'},                        false}, ...
    {'u  [m/s]',           [1 8],   {'-','--'},           {'act','cmd'}, ...
     {'u  actual','u_d  command (gated)'},                  false}, ...
    {'y_e  [m]',           [9],     {'-'},                {'aux'}, ...
     {'cross-track error'},                                 true}, ...
    {'\tau_X , \tau_Y  [N]', [13 14 10 11], {'-','-','--','--'}, ...
     {'act','sway','cmd','aux'}, ...
     {'X applied','Y applied','X asked','Y asked'},         true}, ...
    {'\tau_N  [N m]',      [15 12], {'-','--'},           {'act','cmd'}, ...
     {'N applied','N asked'},                               true}};

W07_anim(y, t, o);
end
