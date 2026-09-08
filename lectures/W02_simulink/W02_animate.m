function W02_animate(u, v, r, N, E, psi, t)
%W02_ANIMATE  Live view for W02_surge_control.slx.
%
%   Called every step by the model's Animate block. The drawing itself is in
%   _tools/live_dash.m, shared by every week of this course.
%
%   INPUTS are in the units otter.m works in — psi in rad, r in rad/s. The
%   conversion to degrees happens once, inside live_dash.
%
%   WHAT TO WATCH
%
%   Nothing steers this week, so the vessel runs due north and the heading
%   never moves. That is the point: the loop being closed is the SPEED loop,
%   and the track is there to show that closing it changes how far the vessel
%   gets, not where it points. The panel to watch is u — it is the only state
%   this week's controller can move.

o.tag   = 'W02';
o.name  = 'W02 live dashboard — surge speed control';
o.title = 'W02 surge speed control   (heading is not controlled this week)';
o.lim   = [base_var('track_Emin', -35), base_var('track_Emax', 35), ...
           base_var('track_Nmin',  -5), base_var('track_Nmax', 65)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
