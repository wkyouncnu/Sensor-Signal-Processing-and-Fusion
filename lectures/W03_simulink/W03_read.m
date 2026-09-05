function y = W03_read(o)
%W03_READ  This week's log, with the angles in degrees and named columns.
%
%   y = W03_read(run_sim('W03_heading_control', V))
%   plot(o.t, y.psi)
%
%   WHY A CONVERSION AND NOT JUST COLUMN NAMES
%
%   add_measurement logs the course-wide contract
%
%       [u v r N E psi | psi_d tau_N n1 n2]
%
%   in the units the MODEL works in: psi already in degrees (add_measurement
%   converts it), but r in rad/s and psi_d in radians, because otter.m and the
%   controller work in radians. A heading lecture is read in degrees
%   throughout, so the conversion happens ONCE, here, and nowhere else.
%
%   Returning a struct rather than a reordered matrix means a script says
%   y.psi and not y(:,2), and a reader never has to count columns.

y.u     = o.y(:,1);              % surge velocity        [m/s]
y.v     = o.y(:,2);              % sway velocity         [m/s]
y.r     = rad2deg(o.y(:,3));     % yaw rate              [deg/s]  <- converted
y.N     = o.y(:,4);              % north position        [m]
y.E     = o.y(:,5);              % east position         [m]
y.psi   = o.y(:,6);              % heading               [deg]    already degrees
y.psi_d = rad2deg(o.y(:,7));     % heading command       [deg]    <- converted
y.tau_N = o.y(:,8);              % commanded yaw moment  [N m]
y.n1    = o.y(:,9);              % left propeller        [rad/s]
y.n2    = o.y(:,10);             % right propeller       [rad/s]
y.t     = o.t;
end
