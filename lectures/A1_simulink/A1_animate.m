function A1_animate(N, E, psi, t)
%A1_ANIMATE  Live view for A1_actuation.slx.
%
%   Called every step by the model's Animate block. The drawing itself is in
%   _tools/live_track.m, shared by every week of this course.
%
%   Week 2's runs are turns on the spot, so the interesting thing on screen is
%   not the track — which stays inside a few metres — but the heading line
%   sweeping round while the track barely moves.

o.tag   = 'A1';
o.name  = 'A1 live track';
o.title = 'A1 actuation   (bow = triangle, stern = square)';
o.lim   = [base_var('track_Emin', -15), base_var('track_Emax', 15), ...
           base_var('track_Nmin', -15), base_var('track_Nmax', 15)];
o.every = base_var('animate_every', 0.5);

live_track(N, E, psi, t, o);
end
