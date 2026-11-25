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
%       16-19 n [rad/s]               20-23 delta [rad]
%
%   뒤의 여덟 열은 **한계를 지난 뒤**의 명령이다 / the last eight columns are
%   the commands AFTER clipping
%       배분기가 푼 것이 아니라 추진기가 실제로 받은 것이다. 그래서 그 여덟을
%       한계선과 함께 그리면 "배가 못 따라간 것인가, 추진기가 다 쓴 것인가" 를
%       Run 이 끝나기 전에 가른다. 포화에 붙은 채로 오차가 남아 있으면 제어기를
%       더 조여도 소용이 없다.
%       These are what the thrusters received, not what the allocator asked for.
%       Drawn against their limits they separate "the controller is too slow"
%       from "the actuators are spent", while the run is still going: an error
%       that persists with a unit pinned to its limit will not be fixed by a
%       larger gain.
%
%   See also W07_ANIM, W07_PLOT_WPT, W07_PLOT_SAT, W07_3_BUILD_WPT.

%  명세를 **한 Run 에 한 번만** 만든다. 이 함수는 Run 마다 2 만 번 불리고,
%  명세를 세우는 데 `base_var` 가 열 번 넘게 기본 작업공간을 들여다본다 —
%  그것을 매 스텝 되풀이하면 그리지 않는 스텝에서도 값이 새어 나간다.
%  시각이 뒤로 가면 새 Run 이므로 그때 다시 세운다 (`W07_anim` 과 같은 판정).
%  The spec is built ONCE per run: this function is called some twenty thousand
%  times, and building the spec reaches into the base workspace a dozen times
%  through base_var. A clock that goes backwards means a new run, the same test
%  W07_anim uses.
persistent o tLastRun
if isempty(o) || isempty(tLastRun) || t < tLastRun
    o = wpt_spec();
end
tLastRun = t;

W07_anim(y, t, o);
end

% =========================================================================
function o = wpt_spec()
%WPT_SPEC  이 Run 에서 그릴 것 / what this run draws
o.tag   = 'W07wpt_anim';
o.name  = 'W07 live view  -  waypoint following';
o.T     = base_var('T_wpt', 400);          % 제목의 시간 상한 / the title's time cap
o.lim   = [base_var('track_Emin', -60), base_var('track_Emax', 140), ...
           base_var('track_Nmin', -60), base_var('track_Nmax', 140)];
o.wp    = [base_var('WP_N', 0), base_var('WP_E', 0)];
o.goal  = [];
o.cmdNE = [];                      % LOS 는 위치를 명령하지 않는다 / no position command
%  넷째 칸이 **단위**다. 숫자만 있는 제목은 읽는 사람이 deg 인지 rad 인지
%  되물어야 한다 (사용자 지시, 2026-11-25) / the fourth cell is the UNIT
o.info  = {'\psi', 6, 1, 'deg'; '\psi_d', 7, 1, 'deg'; ...
           'u', 1, 1, 'm/s'; 'u_d', 8, 1, 'm/s'; 'y_e', 9, 1, 'm'};

%  한계 둘. 배분기가 쓴 것과 **같은 값**을 읽는다 — 화면의 빨간 선과 모델
%  안의 포화가 어긋나면 그림이 거짓말을 한다
%  the two limits, read from the same variables the allocator saturates with:
%  a red line that disagrees with the model would make the picture a lie
nlo = base_var('n_min',     -101.74);
nhi = base_var('n_max',      103.93);
alim = rad2deg(base_var('alpha_lim', pi/4));

%  점선이 명령, 실선이 실제. 앞의 다섯 칸이 모두 같다 / dashed command, solid
%  actual, in the first five panels. 뒤의 두 칸은 네 단위를 색으로 가른다 —
%  `W07_plot_sat` 과 같은 색이다 / the last two separate the four units by
%  colour, the same colours W07_plot_sat uses
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
     {'N applied','N asked'},                               true}, ...
    {'n  [rad/s]',         [16 17 18 19], {'-','-','-','-'}, ...
     {'u1','u2','u3','u4'}, {'n_1','n_2','n_3','n_4'},      true, ...
     1, [nlo nhi], {'n_{min}','n_{max}'}}, ...
    {'\delta  [deg]',      [20 21 22 23], {'-','-','-','-'}, ...
     {'u1','u2','u3','u4'}, ...
     {'\delta_1','\delta_2','\delta_3','\delta_4'},         true, ...
     180/pi, alim*[-1 1], {'-\alpha_{max}','+\alpha_{max}'}}};

%  추진기 넷을 항적 칸에 화살표로 / the four units, as arrows on the track
%      거치점과 거치 부호는 `V.quad` 의 네 행에서 그대로 온다 —
%      `[pos ; alpha_max ; mount]` (`W07_vars`). 여기서 다시 적지 않는다.
%      the stations and the mounting signs come straight out of V.quad's rows,
%      [pos ; alpha_max ; mount], so they are never written down twice
q = base_var('quad', []);
if isempty(q)
    o.thr = [];
else
    o.thr = struct('n',     16:19, ...
                   'd',     20:23, ...
                   'pos',   q(1:2,:), ...
                   'mount', q(4,:), ...
                   'kpos',  base_var('k_pos', 0.01108), ...
                   'kneg',  base_var('k_neg', 0.006445), ...
                   'Tref',  base_var('T_pos', 119.68));
end
end
