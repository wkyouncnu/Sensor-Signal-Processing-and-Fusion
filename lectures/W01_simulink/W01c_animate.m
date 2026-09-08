function W01c_animate(u, v, r, N, E, psi, t)
%W01C_ANIMATE  Live view for W01_current.slx — the open loop in a current.
%
%   Called every step by the Animate block inside Measurements. The drawing
%   itself is in _tools/live_dash.m, shared by every week of this course.
%
%   THIS WRAPPER WAS MISSING UNTIL 2026-09-08
%
%   W01_E_build_current has always created an Animate block that calls
%   W01c_animate, and W01_0_setup has always set animate = 1, but the function
%   did not exist. Anyone who opened W01_current.slx and pressed Run got an
%   undefined-function error; only the section script escaped it, because it
%   sets animate = 0 before sweeping. The same hole existed for W04.
%
%   WHAT TO WATCH
%
%   The command never changes and the vessel never steers, yet the track bends
%   away from the heading. The hull is drawn on the track for exactly that
%   reason: the angle between where the bow points and where the vessel goes is
%   the drift, and it is produced by the water moving, not by any force on the
%   hull. Section E measures it.

o.tag   = 'W01c';
o.name  = 'W01 live dashboard — ocean current';
o.title = 'track in a current   (bow = triangle; the track leaves the heading)';
o.lim   = [base_var('track_Emin', -60), base_var('track_Emax', 60), ...
           base_var('track_Nmin', -10), base_var('track_Nmax', 140)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
