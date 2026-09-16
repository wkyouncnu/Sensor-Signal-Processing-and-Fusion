function blk = add_sum(sys, name, signs, centre)
%ADD_SUM  MSS 가 그리는 모양 그대로의 합산점 — 작은 원 하나.
%         A summing junction drawn the way MSS draws one: a small round circle.
%
%   blk = add_sum(sys, name, signs, centre)
%
%     sys      부모 시스템, 예를 들어 [mdl '/Controller']
%              the parent system, e.g. [mdl '/Controller']
%     signs    포트 순서대로의 부호. '+-', '++', '-+' 등
%              the signs, in port order
%     centre   원의 **중심** [x y]. 모서리가 아니다
%              the centre of the circle, not a corner
%
%   포트가 어디에 붙는지 / where the ports end up
%       입력이 둘인 둥근 합산점은 첫 입력을 왼쪽 가장자리에, 둘째 입력을 아래쪽
%       가장자리에 놓는다. 되먹임이 아래에서 올라오는 MSS 데모의 모양이 이렇게
%       나온다. 배선할 때 이것을 모르면 두 선을 같은 높이로 끌고 와 겹치게 된다.
%
%       With two inputs, the round sum places the first on its left edge and
%       the second underneath. That is how the MSS demonstration models come to
%       have feedback entering from below, and not knowing it leads to both
%       lines being brought in at the same height, where they overlap.
%
%   WHY THIS EXISTS
%
%   Simulink's default Sum block is a rectangle 25 x 40 with the signs printed
%   inside it. On a diagram that has to be read at page width it is a slab: it
%   is larger than the gain blocks around it, it breaks the line of the signal
%   chain, and the error junction - the one block a reader looks for first -
%   ends up the most visually heavy thing in the loop.
%
%   MSS uses a circle 20 x 20 throughout. Checked against
%   Tools/MSS/SIMULINK/mssSimulinkDemos/demoOtterUSVHeadingControl.slx, whose
%   eight Sum blocks are all IconShape 'round' at 20 x 20 with signs like
%   '|+-'. This function reproduces that exactly.
%
%   THE '|' IN THE SIGN STRING
%
%   A bar is a port-position spacer, not a port. '|+-' puts the two inputs on
%   different edges of the circle so their + and - are legible and the lines
%   arrive from different directions. Without it both signs crowd the left
%   edge and a small circle becomes unreadable. The bar is added here, so
%   callers pass the signs alone.
%
%   The centre is the argument rather than a corner because a summing junction
%   is placed to line up with the signal it interrupts. Aligning centres keeps
%   the wire straight; aligning corners does not.

if nargin < 4, error('add_sum:args', 'add_sum(sys, name, signs, centre)'); end

signs = strrep(signs, '|', '');            % tolerate a caller that passed one
R     = 10;                                % half of the MSS 20 x 20

blk = [sys '/' name];
add_block('simulink/Math Operations/Sum', blk, ...
          'IconShape', 'round', ...
          'Inputs',    ['|' signs], ...
          'Position',  [centre(1)-R, centre(2)-R, centre(1)+R, centre(2)+R]);
end
