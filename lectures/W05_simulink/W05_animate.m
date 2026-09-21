function W05_animate(u, v, r, N, E, psi, t)
%W05_ANIMATE  W05_guidance.slx 의 실시간 화면 — 웨이포인트 추종.
%             Live view for W05_guidance.slx: waypoint following.
%
%   Measurements 안의 Animate 블록이 매 스텝 부른다. 실제로 그리는 일은 모든
%   주차가 함께 쓰는 _tools/live_dash.m 이 한다.
%   Called at every step by the Animate block inside Measurements; the drawing
%   itself is done by _tools/live_dash.m, shared by every week of this course.
%
%   이력 — 2026-09-08 까지 이 파일이 없었다
%   history: this wrapper did not exist until 2026-09-08
%
%   W05_1_build_guidance has always created an Animate block that calls
%   W05_animate, and W05_0_setup has always set animate = 1, but the function
%   did not exist. Anyone who opened W05_guidance.slx and pressed Run got an
%   undefined-function error; the section scripts escaped it only because they
%   set animate = 0. The same hole existed for W01_current.slx.
%
%   INPUTS are in the units otter.m works in — psi in rad, r in rad/s. The
%   conversion to degrees happens once, inside live_dash.
%
%   WHAT TO WATCH
%
%   The dashed polyline with square markers is the commanded path. The vessel
%   should sit ON it, not merely pass near its corners, and the panel to read
%   while it does is psi: in a current the bow settles UPSTREAM of the path
%   direction and stays there. That offset is the whole subject of sections
%   5-7 to 4-9.

o.tag   = 'W05';
o.name  = 'W05 live dashboard — waypoint following';
o.title = 'W05 guidance   (dashed = the path, squares = waypoints)';
o.lim   = [base_var('track_Emin', -20), base_var('track_Emax', 80), ...
           base_var('track_Nmin', -20), base_var('track_Nmax', 80)];
o.every = base_var('animate_every', 0.5);

%  The waypoint list is read from the base workspace rather than passed in, so
%  the Animate block keeps the port list every week uses. WP is [N E] per row,
%  which is the order live_dash expects.
o.wp = base_var('WP', []);

live_dash(u, v, r, N, E, psi, t, o);
end
