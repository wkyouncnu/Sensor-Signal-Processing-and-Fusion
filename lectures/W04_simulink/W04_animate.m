function W04_animate(u, v, r, N, E, psi, t)
%W04_ANIMATE  Live view for W04_guidance.slx — waypoint following.
%
%   Called every step by the Animate block inside Measurements. The drawing
%   itself is in _tools/live_dash.m, shared by every week of this course.
%
%   THIS WRAPPER WAS MISSING UNTIL 2026-09-08
%
%   W04_1_build_guidance has always created an Animate block that calls
%   W04_animate, and W04_0_setup has always set animate = 1, but the function
%   did not exist. Anyone who opened W04_guidance.slx and pressed Run got an
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
%   4-7 to 4-9.

o.tag   = 'W04';
o.name  = 'W04 live dashboard — waypoint following';
o.title = 'W04 guidance   (dashed = the path, squares = waypoints)';
o.lim   = [base_var('track_Emin', -20), base_var('track_Emax', 80), ...
           base_var('track_Nmin', -20), base_var('track_Nmax', 80)];
o.every = base_var('animate_every', 0.5);

%  The waypoint list is read from the base workspace rather than passed in, so
%  the Animate block keeps the port list every week uses. WP is [N E] per row,
%  which is the order live_dash expects.
o.wp = base_var('WP', []);

live_dash(u, v, r, N, E, psi, t, o);
end
