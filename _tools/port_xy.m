function p = port_xy(sys, blk, kind, k)
%PORT_XY  포트 하나의 화면 위치를 [x y] 로 돌려준다.
%         Screen position of one port, as [x y].
%
%   p = port_xy(sys, 'Animate', 'Inport', 3)
%   p = port_xy(sys, 'log', 'Outport', 1)
%
%   포트 높이는 계산하지 말고 읽는다 / read port heights, do not calculate them
%       Simulink 는 블록의 첫 포트와 마지막 포트를 자기가 정한 여백만큼 안쪽으로
%       들여놓고 나머지를 그 사이에 고르게 편다. 그래서 맞아 보이는 공식을 써도
%       선이 몇 픽셀씩 어긋나고, 도면이 완만한 사선으로 가득 찬다. 읽으면 그런
%       일이 없다.
%
%       Simulink insets the first and last port of a block by a margin of its
%       own choosing and spreads the rest evenly between them, so a formula
%       that looks right leaves lines a few pixels out of true and the diagram
%       fills up with shallow diagonals. Reading avoids all of it.
%
%       다만 간격 자체는 일정하므로, 포트가 어디로 갔는지 묻기 전에 블록의
%       크기를 정할 때는 그 값을 쓸 수 있다.
%       The pitch itself does hold, and a builder may use it to size a block
%       before asking where its ports went:
%
%       pitch = (height - 40) / (number of ports - 1)
%
%   Blocks are sized so that pitch is at least 52 px, which is what a 30 px
%   block plus its name underneath needs.

h = get_param([sys '/' blk], 'PortHandles');
p = get_param(h.(kind)(k), 'Position');
end
