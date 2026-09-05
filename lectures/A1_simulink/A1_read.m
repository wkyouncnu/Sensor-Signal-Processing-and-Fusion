function y = A1_read(o)
%A1_READ  This appendix's log, with named fields.
%
%   add_measurement logs [u v r N E psi | tau], so the generalised force
%   occupies columns 7 to 9. Naming them here keeps the scripts free of
%   column arithmetic.

y.u   = o.y(:,1);            % surge velocity        [m/s]
y.v   = o.y(:,2);            % sway velocity         [m/s]
y.r   = o.y(:,3);            % yaw rate              [rad/s]
y.N   = o.y(:,4);            % north position        [m]
y.E   = o.y(:,5);            % east position         [m]
y.psi = o.y(:,6);            % heading               [deg]
y.X   = o.y(:,7);            % surge force           [N]
y.Y   = o.y(:,8);            % sway force            [N]   structurally zero
y.Nm  = o.y(:,9);            % yaw moment            [N m]
y.tau = o.y(:,7:9);          % the whole generalised force
y.t   = o.t;
end
