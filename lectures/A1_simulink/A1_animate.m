function A1_animate(u, v, r, N, E, psi, t)
%A1_ANIMATE  Live view for A1_actuation.slx.
%
%   Called every step by the model's Animate block. The drawing itself is in
%   _tools/live_dash.m, shared by every week of this course.
%
%   INPUTS are in the units otter.m works in — psi in rad, r in rad/s. The
%   conversion to degrees happens once, inside live_dash.
%
%   WHAT TO WATCH
%
%   The appendix's runs are turns on the spot, so the interesting thing on
%   screen is not the track — which stays inside a few metres — but the
%   heading line sweeping round while the track barely moves. The r panel on
%   the right is the one to read: it is the yaw rate the allocation bought
%   with a given pair of shaft speeds.

o.tag   = 'A1';
o.name  = 'A1 live dashboard — actuation';
o.title = 'A1 actuation   (bow = triangle, stern = square)';
o.lim   = [base_var('track_Emin', -15), base_var('track_Emax', 15), ...
           base_var('track_Nmin', -15), base_var('track_Nmax', 15)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
