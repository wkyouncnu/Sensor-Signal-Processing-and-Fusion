function W01_animate(N, E, psi, t)
%W01_ANIMATE  Draw the vessel and its track while the simulation runs.
%
%   Called every step by the Animate block inside W01_openloop.slx. There is no
%   reason to call it by hand; to change what the live view shows, edit
%   _tools/live_track.m, which every week of this course shares.
%
%   INPUTS
%     N, E   position in NED [m]
%     psi    heading [rad], from North, positive clockwise
%     t      simulation time [s]
%
%   The axis limits and the redraw interval are read from the base workspace,
%   so widening the window is an edit to W01_0_setup.m and not to the model.

o.tag   = 'W01';
o.name  = 'W01 live track';
o.title = 'W01 live track   (bow = triangle, stern = square)';
o.lim   = [base_var('track_Emin', -80), base_var('track_Emax',  80), ...
           base_var('track_Nmin', -20), base_var('track_Nmax', 140)];
o.every = base_var('animate_every', 0.5);

live_track(N, E, psi, t, o);
end
