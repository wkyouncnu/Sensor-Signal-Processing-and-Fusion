function lane_line(sys, s, sk, d, dk, xl)
%LANE_LINE  Source port to destination port through one named vertical lane.
%
%   lane_line(sys, 'N', 1, 'Animate', 1, 360)
%
%   Autorouting is free to choose the same corridor for several signals, and
%   when it does, two unrelated lines are drawn on top of each other: the
%   reader cannot tell which source reaches which destination, and the diagram
%   claims a connection that does not exist. Naming the lane makes the choice
%   explicit and makes it checkable - two lanes with the same x are a bug that
%   can be seen in the source, and _tools/check_overlaps.m finds the rest.
%
%   If the two ports already share a row the line is drawn straight and the
%   lane is ignored, so the same call is correct either way.

a = port_xy(sys, s, 'Outport', sk);
b = port_xy(sys, d, 'Inport',  dk);

%  A round Sum puts its second input on the BOTTOM of the circle, and that port
%  must be approached from below, not from the side. It is recognised by its x
%  lying inside the block rather than outside its left edge, which is where a
%  side-facing port sits.
q = get_param([sys '/' d], 'Position');
if b(1) > q(1) && b(1) < q(3)
    xl = b(1);
elseif isempty(xl) || xl <= 0
    %  No lane named: take the midpoint. This is a fallback, not a default -
    %  a caller that needs the lane to miss something must say where it goes.
    xl = round((a(1) + b(1))/2);
end

if abs(a(2) - b(2)) < 0.5
    p = [a; b];
else
    p = [a; xl a(2); xl b(2); b];
end

%  Drop the zero-length segments that appear when the lane is already the
%  source's or the destination's own x. Simulink draws those as stray marks.
keep = [true; any(abs(diff(p,1,1)) > 0.5, 2)];
add_line(sys, p(keep,:));
end
