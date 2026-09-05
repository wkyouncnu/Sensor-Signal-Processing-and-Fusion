function set_mlfcn(blk, lines, outName, outSize, sampleTime)
%SET_MLFCN  Put a script into a MATLAB Function block, and size its output.
%
%   set_mlfcn(blk, lines)
%   set_mlfcn(blk, lines, outName, outSize)
%   set_mlfcn(blk, lines, outName, outSize, 'h')
%
%     blk         full path of an existing MATLAB Function block
%     lines       cell array of source lines, one per element
%     outName     output variable to give an explicit size, e.g. 'xdot'
%     outSize     size string, e.g. '[12 1]'
%     sampleTime  discrete rate, e.g. 'h'. Required whenever the script keeps
%                 a PERSISTENT variable
%
%   WHY A BLOCK WITH MEMORY MUST DECLARE ITS RATE
%
%   Left to inherit, a MATLAB Function block wired to a continuous plant picks
%   up a continuous sample time, and Simulink then refuses the script:
%
%       ... uses invalid syntax when the block specifies or inherits a
%           continuous sample time ... writing to initialized persistent
%           variables ...
%
%   The refusal is right. A persistent variable has no meaning when the solver
%   may take a step, reject it and take it again: the state would advance more
%   than once for one step of time. Saying 'h' makes the block a discrete
%   algorithm updated once per step, which is what the Euler update inside it
%   already assumed.
%
%   The rate is a property of the Stateflow chart, not a block parameter, so
%   set_param(blk,'SampleTime',...) fails with "SubSystem block does not have
%   a parameter named 'SampleTime'".
%
%   The block's script is not a block parameter. It lives in the Stateflow
%   object tree, which is why this goes through sfroot() rather than set_param.
%
%   The explicit output size is needed whenever the block calls an extrinsic
%   function. Simulink does not compile such a call, so it cannot infer the
%   width of what comes back, and the width has to be declared.

n = sfroot().find('-isa','Stateflow.EMChart','-and','Path',blk);
if isempty(n)
    error('set_mlfcn:notFound','No MATLAB Function block at %s', blk);
end
n.Script = strjoin(lines, newline);

if nargin >= 4 && ~isempty(outName)
    d = n.find('-isa','Stateflow.Data','-and','Name',outName);
    d.DataType = 'double';
    d.Props.Array.Size = outSize;
end

if nargin >= 5 && ~isempty(sampleTime)
    n.ChartUpdate = 'DISCRETE';
    n.SampleTime  = sampleTime;
end
end
