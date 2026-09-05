function c = W02_cols()
%W02_COLS  Names for the columns of this week's log, so no script has to
%          remember that the integrator state is "column ten".
%
%   c = W02_cols;
%   plot(R.t, R.y(:, c.u))
%
%   add_measurement always logs the six course-wide columns first, then this
%   week's extras in the order the builder asked for them:
%
%       add_measurement(m, P.measurement, 'W02', {'u_d','X_cmd','X_sat','I','n1'})
%
%   If that list changes, change this function and nothing else.

c.u     =  1;   % surge velocity          [m/s]   <- the controlled variable
c.v     =  2;   % sway velocity           [m/s]   structurally zero this week
c.r     =  3;   % yaw rate                [rad/s] zero, nothing steers
c.N     =  4;   % north position          [m]
c.E     =  5;   % east position           [m]
c.psi   =  6;   % heading                 [deg]
c.u_d   =  7;   % speed command           [m/s]
c.X_cmd =  8;   % force the controller ASKED for   [N]
c.X_sat =  9;   % force the propellers GAVE        [N]
c.I     = 10;   % integrator state        [N]      the state windup lives in
c.n1    = 11;   % left propeller speed    [rad/s]
end
