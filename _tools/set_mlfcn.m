function set_mlfcn(blk, lines, outName, outSize)
%SET_MLFCN  Put a script into a MATLAB Function block, and size its output.
%
%   set_mlfcn(blk, lines)
%   set_mlfcn(blk, lines, outName, outSize)
%
%     blk      full path of an existing MATLAB Function block
%     lines    cell array of source lines, one per element
%     outName  output variable to give an explicit size, e.g. 'xdot'
%     outSize  size string, e.g. '[12 1]'
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
end
