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

%  The heading is read straight from the log, which does not wrap it: otter.m
%  integrates psi and a vessel that turns twice reaches 720 deg. Every figure
%  that shows psi as a compass bearing wraps it, and does so with this one
%  expression so that no two of them disagree at the boundary.
%
%      psi_wrapped = mod(psi + 180, 360) - 180      ->  (-180, 180]
%
%  Exactly 180 deg maps to -180 deg. That is the only point where the two
%  forms differ, and it is why the unwrapped y.psi is kept as well: a turn
%  rate computed by differencing the WRAPPED angle has a spurious 360 deg
%  jump in it, so anything differentiated must use y.psi and not y.psi_w.
y.psi_w = mod(y.psi + 180, 360) - 180;             % heading, wrapped [deg]

%  The two shaft speeds, present whenever the model logged its own input.
%  The open-loop model logs 8 columns, the current model 12; in both the
%  command occupies 7 and 8, so the test is on the columns being there at
%  all and not on the total width.
if size(o.y, 2) >= 8
    y.nL = o.y(:,7);             % port propeller command           [rad/s]
    y.nR = o.y(:,8);             % starboard propeller command      [rad/s]
end

if size(o.y, 2) >= 12
    y.u_c = o.y(:,9);            % current, surge component in {b}   [m/s]
    y.v_c = o.y(:,10);           % current, sway  component in {b}   [m/s]
    y.u_r = o.y(:,11);           % relative surge, u - u_c           [m/s]
    y.v_r = o.y(:,12);           % relative sway,  v - v_c           [m/s]
end
end
