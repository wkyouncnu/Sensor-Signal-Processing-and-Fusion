function y = W04_read(o)
%W04_READ  This week's log, with named fields and the angles in degrees.
%
%   y = W04_read(run_sim('W04_guidance', V))
%   plot(y.t, y.y_e(:,2))          % the cross-track error of the LOS vessel
%
%   THE LOG
%
%   add_measurement logs the course-wide contract followed by this week's
%   four bank signals, each four wide:
%
%       [u v r N E psi | psi_d(4) y_e(4) wp(4) aux(4) | trk(48)]
%         1 2 3 4 5  6    7..10    11..14  15..18 19..22   23..70
%
%   The first six columns belong to VESSEL 1 only, by the logging contract of
%   this course. The four-wide signals carry all four vessels, in the order
%
%       1 atan2   2 LOS   3 ILOS   4 ALOS
%
%   so y.y_e(:,3) is the ILOS vessel's cross-track error. The column order is
%   the same in every field, which is what lets a plotting loop index them
%   with one variable.
%
%   `trk` is the four 12-state vectors end to end, so vessel i occupies
%   columns 12(i-1)+1 .. 12i of it, and within that block N is 7, E is 8 and
%   psi is 12. y.trkN, y.trkE and y.trkPsi unpack that into one column per
%   vessel, which is what the track figures plot.

y.u   = o.y(:,1);                % surge velocity, vessel 1      [m/s]
y.v   = o.y(:,2);                % sway velocity,  vessel 1      [m/s]
y.r   = rad2deg(o.y(:,3));       % yaw rate,       vessel 1      [deg/s]
y.N   = o.y(:,4);                % north position, vessel 1      [m]
y.E   = o.y(:,5);                % east position,  vessel 1      [m]
y.psi = o.y(:,6);                % heading,        vessel 1      [deg]
y.t   = o.t;

y.psi_d = rad2deg(o.y(:,  7:10));  % commanded heading, four laws [deg]
y.y_e   =         o.y(:, 11:14);   % cross-track error            [m]
y.wp    =         o.y(:, 15:18);   % active waypoint index
y.aux   =         o.y(:, 19:22);   % ILOS y_int (col 3), ALOS b_hat (col 4)

%  All four tracks, one column per vessel.
trk      = o.y(:, 23:70);
y.trkN   = trk(:, 7:12:end);
y.trkE   = trk(:, 8:12:end);
y.trkPsi = rad2deg(trk(:, 12:12:end));
y.trkU   = trk(:, 1:12:end);
y.trkV   = trk(:, 2:12:end);

%  The crab angle of every vessel, which section G compares with b_hat.
y.beta   = atan2d(y.trkV, y.trkU);
y.beta_c = y.beta(:,1);
y.chi    = y.psi + y.beta_c;

y.name = {'atan2','LOS','ILOS','ALOS'};
end
