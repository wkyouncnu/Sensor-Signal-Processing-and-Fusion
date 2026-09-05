function y = W01_read(o)
%W01_READ  This week's log, with named fields and the angles in degrees.
%
%   y = W01_read(run_sim('W01_openloop', V))
%   plot(y.t, y.psi)
%
%   WHY A CONVERSION AND NOT JUST COLUMN NAMES
%
%   add_measurement logs the course-wide contract
%
%       [u v r N E psi | ...]
%
%   in the units the MODEL works in: psi already in degrees (add_measurement
%   converts it) but r in rad/s, because otter.m works in radians. Week 1 is
%   read in degrees throughout, so the conversion happens ONCE, here.
%
%   The current model adds four columns of its own. They are present only
%   when that model produced the log, so the fields appear only then and a
%   script that asks for y.u_r on an open-loop run gets a clear error rather
%   than a wrong number.

y.u   = o.y(:,1);                % surge velocity, over ground   [m/s]
y.v   = o.y(:,2);                % sway velocity,  over ground   [m/s]
y.r   = rad2deg(o.y(:,3));       % yaw rate                      [deg/s]  <- converted
y.N   = o.y(:,4);                % north position                [m]
y.E   = o.y(:,5);                % east position                 [m]
y.psi = o.y(:,6);                % heading                       [deg]    already degrees
y.t   = o.t;

%  The crab angle is the whole point of Week 1's track figure, so it is
%  computed here rather than in three separate scripts.
y.beta = atan2d(y.v, y.u);       % crab angle  beta = atan2(v, u)  [deg]
y.chi  = y.psi + y.beta;         % course over ground              [deg]

if size(o.y, 2) >= 10
    y.u_c = o.y(:,7);            % current, surge component in {b}   [m/s]
    y.v_c = o.y(:,8);            % current, sway  component in {b}   [m/s]
    y.u_r = o.y(:,9);            % relative surge, u - u_c           [m/s]
    y.v_r = o.y(:,10);           % relative sway,  v - v_c           [m/s]
end
end
