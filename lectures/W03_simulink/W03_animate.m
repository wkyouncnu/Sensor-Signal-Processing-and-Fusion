function W03_animate(N, E, psi, t)
%W03_ANIMATE  Live view for W03_heading_control.slx.
%
%   Called every step by the Animate block inside Measurements. The drawing
%   itself is in _tools/live_track.m, shared by every week of this course.
%
%   The dashed ray leaving the hull is the COMMANDED heading. Watching the
%   solid heading line swing onto the dashed one is the whole of this week.

o.tag   = 'W03';
o.name  = 'W03 live track';
o.title = 'W03 heading control   (solid = heading, dashed = commanded)';
o.lim   = [base_var('track_Emin', -25), base_var('track_Emax', 25), ...
           base_var('track_Nmin', -10), base_var('track_Nmax', 40)];
o.every = base_var('animate_every', 0.5);

%  The commanded heading is rebuilt here from the setup variables rather than
%  passed in, so the Animate block keeps the five inputs every week uses.
t_up = base_var('t_up', 0);   t_dn = base_var('t_dn', inf);
p1   = base_var('psi_1', 0);  p2   = base_var('psi_2', 0);
if     t < t_up, o.psi_d = 0;
elseif t < t_dn, o.psi_d = deg2rad(p1);
else,            o.psi_d = deg2rad(p2);
end

live_track(N, E, psi, t, o);
end
