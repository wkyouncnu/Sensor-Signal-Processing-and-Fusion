function [x_e, y_e, pi_p] = crosstrack_err(N, E, wp_k, wp_next)
%CROSSTRACK_ERR  경로방향 오차와 경로이탈 오차를, 회전 하나로 함께 구한다.
%                Along-track and cross-track error, from a single rotation.
%
%   [x_e, y_e, pi_p] = crosstrack_err(N, E, wp_k, wp_next)
%
%     N, E       NED 좌표계에서의 선박 위치 [m]. 길이가 같은 벡터도 된다
%                the vessel position in NED [m]; equal-length vectors are allowed
%     wp_k       현재 겨냥하고 있는 웨이포인트 / the active waypoint,   [N E]
%     wp_next    그다음 웨이포인트 / the one after it,                  [N E]
%
%     x_e        경로방향 오차 — 구간을 따라 얼마나 왔는가
%                along-track error: how far along the leg the vessel is
%     y_e        경로이탈 오차 — 구간에서 옆으로 얼마나 벗어났는가
%                cross-track error: how far to the side of it
%     pi_p       경로의 접선 방향, 북쪽에서 잰 각 [rad]
%                the path-tangential angle, measured from North [rad]
%
%   왜 회전 하나로 둘 다 나오는가 / why one rotation gives both
%       웨이포인트를 원점으로 옮기고 좌표계를 경로 방향으로 돌리면, 두 오차는
%       회전한 좌표의 두 성분 그 자체가 된다. 따로 유도할 것이 없다.
%       Translating the origin to the waypoint and rotating the frame onto the
%       path makes the two errors the two components of the rotated
%       coordinate, so neither has to be derived separately.
%
%   tan(pi_p) 를 쓰는 형태는 쓰지 않는다. 그 형태는 pi_p = ±90 도에서 특이해지며,
%   실제로 동서 방향 구간에서 터진다. 회전행렬 형태에는 그런 자리가 없다.
%   The form written with tan(pi_p) is avoided: it is singular at
%   pi_p = ±90 deg and fails on an east-west leg. The rotation form has no
%   such point.
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
