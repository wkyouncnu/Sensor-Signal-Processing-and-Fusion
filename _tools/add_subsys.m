function sub = add_subsys(mdl, name, pos, ins, outs, colour)
%ADD_SUBSYS  An empty subsystem with named ports, ready to be filled.
%
%   sub = add_subsys(mdl, name, pos, ins, outs, colour)
%
%     mdl     model name
%     name    subsystem name, e.g. 'Heading autopilot'
%     pos     [x1 y1 x2 y2], normally from gnc_chain
%     ins     cell array of inport names,  e.g. {'psi_d','x'}
%     outs    cell array of outport names, e.g. {'tau_N'}
%     colour  optional BackgroundColor string
%
%   Returns the full path of the subsystem, so the caller can go on adding
%   blocks inside it.
%
%   WHY EVERY STAGE IS A SUBSYSTEM
%
%   The top level of a model in this course shows the signal chain and nothing
%   else: six blocks in a row, one line between each pair, and one feedback
%   line. Everything that makes a stage work lives inside that stage. A reader
%   who wants to know what the controller does opens the controller.
%
%   The alternative — every gain, sum and integrator on one canvas — produces a
%   diagram that cannot be read on a page and cannot be exported into a
%   document. It is also harder to change, because moving one block moves
%   nothing else and the layout decays with every edit.
%
%   PORT NAMES ARE THE INTERFACE
%
%   Ports are named, never left as In1 and Out1. The name is what the top-level
%   diagram shows next to the line, so `psi_d` and `tau_N` document the model
%   without a single annotation.

if nargin < 6, colour = ''; end
if nargin < 5 || isempty(outs), outs = {}; end
if nargin < 4 || isempty(ins),  ins  = {}; end

sub = [mdl '/' name];
add_block('built-in/Subsystem', sub, 'Position', pos);
clear_subsystem(sub);

%  Ports are spread down the left and right edges of the subsystem canvas at a
%  fixed pitch, so a subsystem with three inports always looks like one.
PITCH = 60;  Y0 = 80;
for i = 1:numel(ins)
    add_block('simulink/Sources/In1', [sub '/' ins{i}], ...
              'Port', num2str(i), ...
              'Position', [60 Y0+PITCH*(i-1) 90 Y0+PITCH*(i-1)+20]);
end
for i = 1:numel(outs)
    add_block('simulink/Sinks/Out1', [sub '/' outs{i}], ...
              'Port', num2str(i), ...
              'Position', [700 Y0+PITCH*(i-1) 730 Y0+PITCH*(i-1)+20]);
end

if ~isempty(colour), set_param(sub, 'BackgroundColor', colour); end
end

% -------------------------------------------------------------------------
function clear_subsystem(sub)
b = find_system(sub, 'SearchDepth',1, 'LookUnderMasks','all', 'Type','Block');
for i = 1:numel(b)
    if ~strcmp(b{i}, sub), delete_block(b{i}); end
end
end
