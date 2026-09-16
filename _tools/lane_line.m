function lane_line(sys, s, sk, d, dk, xl)
%LANE_LINE  출발 포트에서 도착 포트까지, 이름을 붙인 세로 통로 하나를 지나게 한다.
%           Source port to destination port through one named vertical lane.
%
%   lane_line(sys, 'N', 1, 'Animate', 1, 360)
%
%   왜 필요한가 / why this exists
%       자동 배선은 여러 신호에 같은 통로를 골라 줄 수 있고, 그렇게 되면 서로
%       관계없는 두 선이 겹쳐 그려진다. 그러면 읽는 사람은 어느 출발점이 어느
%       도착점에 닿는지 알 수 없고, 도면은 있지도 않은 연결을 주장하게 된다.
%
%       통로에 x 를 직접 붙여 두면 그 선택이 코드에 드러난다. 같은 x 를 쓴 통로가
%       둘이면 소스만 보고도 알 수 있는 결함이 되고, 그래도 남는 것은
%       _tools/check_overlaps.m 이 찾아낸다.
%
%       Autorouting is free to choose the same corridor for several signals,
%       and when it does, two unrelated lines are drawn on top of each other:
%       the reader cannot tell which source reaches which destination, and the
%       diagram claims a connection that does not exist. Naming the lane makes
%       the choice explicit in the source, so two lanes sharing an x is a
%       defect that can be seen by reading the builder, and check_overlaps
%       finds whatever is left.
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
