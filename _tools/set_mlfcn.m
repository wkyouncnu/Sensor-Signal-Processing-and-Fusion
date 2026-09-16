function set_mlfcn(blk, lines, outName, outSize, sampleTime)
%SET_MLFCN  MATLAB Function 블록에 코드를 넣고, 출력의 크기를 명시한다.
%           Put a script into a MATLAB Function block, and size its output.
%
%   set_mlfcn(blk, lines)
%   set_mlfcn(blk, lines, outName, outSize)
%   set_mlfcn(blk, lines, outName, outSize, 'h')
%
%     blk         이미 존재하는 MATLAB Function 블록의 전체 경로
%                 the full path of an existing MATLAB Function block
%     lines       소스 줄들의 셀 배열. 한 원소가 한 줄
%                 a cell array of source lines, one per element
%     outName     크기를 명시할 출력 변수의 이름, 예를 들어 'xdot'
%                 the output variable to give an explicit size, e.g. 'xdot'
%
%   왜 크기를 명시하는가 / why the size is stated
%       Simulink 는 출력 크기를 추론하려 하고, 추론에 실패하면 컴파일 시점에야
%       알려 준다. 그때 나오는 메시지는 블록 안의 어느 줄이 원인인지 말해 주지
%       않는다. 크기를 미리 못박아 두면 그 부류의 오류가 아예 생기지 않는다.
%
%       Simulink tries to infer the output size and reports failure only at
%       compile time, in a message that does not say which line inside the
%       block caused it. Fixing the size in advance removes that class of
%       error altogether.
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
