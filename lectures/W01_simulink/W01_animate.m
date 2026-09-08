function W01_animate(u, v, r, N, E, psi, t)
%W01_ANIMATE  Draw the vessel, its states and its track while the model runs.
%
%   Called every step by the Animate block inside W01_openloop.slx. There is no
%   reason to call it by hand; to change what the live view shows, edit
%   _tools/live_dash.m, which every week of this course shares.
%
%   INPUTS  (in the units otter.m works in - the conversion happens once,
%            inside live_dash, so no two figures can disagree)
%     u, v   surge and sway velocity [m/s]
%     r      yaw rate [rad/s]          -> drawn in deg/s
%     N, E   position in NED [m]
%     psi    heading [rad], from North, positive clockwise
%                                      -> drawn in deg, wrapped to (-180, 180]
%     t      simulation time [s]
%
%   The axis limits and the redraw interval are read from the base workspace,
%   so widening the window is an edit to W01_0_setup.m and not to the model.

o.tag   = 'W01';
o.name  = 'W01 live dashboard';
o.title = 'track   (bow = triangle, stern = square)';
o.lim   = [base_var('track_Emin', -80), base_var('track_Emax',  80), ...
           base_var('track_Nmin', -20), base_var('track_Nmax', 140)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
