function [x_e, y_e, pi_p] = crosstrack_err(N, E, wp_k, wp_next)
%CROSSTRACK_ERR  Along-track and cross-track error, from one rotation.
%
%   [x_e, y_e, pi_p] = crosstrack_err(N, E, wp_k, wp_next)
%
%     N, E       vessel position in NED [m]. May be vectors of equal length
%     wp_k       the active waypoint,   [N E]
%     wp_next    the one after it,      [N E]
%
%     x_e        along-track error  — how far ALONG the leg the vessel is
%     y_e        cross-track error  — how far TO THE SIDE of it
%     pi_p       path-tangential angle, from North [rad]
%
%   THE WHOLE DERIVATION IS ONE ROTATION
%
%   The leg from wp_k to wp_next defines a frame: its x axis points along the
%   leg, its y axis to starboard of it. Expressing the position error in that
%   frame is a rotation, and the two errors fall out together:
%
%       pi_p = atan2(E_next - E_k, N_next - N_k)
%
%       [x_e]   [ cos pi_p   sin pi_p ] [N - N_k]
%       [   ] = [                     ] [       ]
%       [y_e]   [-sin pi_p   cos pi_p ] [E - E_k]
%
%   which is R(pi_p)' applied to the position error. Nothing else is needed:
%   the projection onto the path and the distance from it are the two
%   components of one vector written in the right frame.
%
%   WHY NOT THE FORM WITH tan
%
%   MSS crosstrack.m solves a 3x3 system containing tan(pi_p), which is
%   singular at pi_p = +-90 deg — exactly a due-East or due-West leg, which is
%   half of any survey pattern. The rotation form above has no such point.
%   MSS crosstrackWpt.m uses the rotation form and agrees with this function
%   to machine precision; verify_guidance checks that on every call.
%
%   SIGN CONVENTION
%
%   y_e > 0 means the vessel is to STARBOARD of the leg when travelling along
%   it, because {n} is North-East-Down and a positive rotation takes North
%   towards East. A positive y_e must therefore be corrected by turning to
%   port, which is why the LOS law subtracts its correction from pi_p.

pi_p = atan2(wp_next(2) - wp_k(2), wp_next(1) - wp_k(1));

dN = N(:) - wp_k(1);
dE = E(:) - wp_k(2);

x_e =  dN*cos(pi_p) + dE*sin(pi_p);
y_e = -dN*sin(pi_p) + dE*cos(pi_p);

x_e = reshape(x_e, size(N));
y_e = reshape(y_e, size(N));
end
