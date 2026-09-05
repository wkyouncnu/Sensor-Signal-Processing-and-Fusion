function blk = add_sum(sys, name, signs, centre)
%ADD_SUM  A summing junction drawn the way MSS draws one: a small round circle.
%
%   blk = add_sum(sys, name, signs, centre)
%
%     sys      parent system, e.g. [mdl '/Controller']
%     signs    '+-' or '++' or '-+' — the signs in port order
%     centre   [x y], the CENTRE of the circle (not a corner)
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
