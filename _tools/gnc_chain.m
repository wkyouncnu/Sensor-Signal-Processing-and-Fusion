function P = gnc_chain(stages, varargin)
%GNC_CHAIN  GNC 신호 사슬의 각 단계가 놓일 표준 위치를 돌려준다.
%           Standard block positions for the stages of the GNC signal chain.
%
%   P = gnc_chain({'command','controller','allocation','plant','measurement'})
%   P.controller                        -> [x1 y1 x2 y2]
%   P = gnc_chain(..., 'Height', struct('controller',150))
%
%   왜 좌표를 손으로 쓰지 않는가 / why coordinates are not typed by hand
%       매주 같은 자리에서 같은 것을 찾을 수 있어야 한다. 좌표를 빌더마다 손으로
%       적으면 주차마다 조금씩 달라지고, 그 차이는 아무 의미도 없으면서 읽는
%       사람의 눈을 매번 다시 적응시킨다.
%
%       The same thing must be in the same place every week. Coordinates typed
%       into each builder drift from week to week, and the differences carry no
%       meaning while forcing the reader's eye to re-adjust each time.
%
%   사슬 / the chain
%       이 강의의 모든 모델은 MSS 데모 모델
%       (Tools/MSS/SIMULINK/mssSimulinkDemos/demoOtterUSVHeadingControl.slx)
%       과 같은 순서로 왼쪽에서 오른쪽으로 놓인다.
%       Every model in this course is laid out left to right in the same order,
%       the order used by the MSS demonstration models:
%
%     command --> reference --> controller --> allocation --> plant --> measurement
%      what is     what is       what force     which          how the   what is
%      asked for   achievable    is needed      thrusters      vessel    recorded
%                  and how fast                 produce it     responds
%
%   A week that does not need a stage simply leaves it out of the list, and the
%   remaining stages close up. The ORDER is the contract, not the coordinates:
%   a reader who has seen one model knows where to look in every other one.
%
%   STAGE NAMES, in chain order
%
%     'command'      constants and step blocks — the setpoint
%     'reference'    reference model, when there is one
%     'controller'   the control law
%     'allocation'   generalised force to shaft speed
%     'plant'        the vessel, add_otter_plant
%     'measurement'  selectors, scopes, logging, live view
%
%   NAME/VALUE
%
%     'Height'  scalar, or a struct with a field per stage. Default 90
%     'Width'   scalar, or a struct with a field per stage. Default 110
%     'Y'       top edge of the chain. Default 140
%     'Pitch'   left-edge spacing between stages. Default 160
%
%   WHY THE POSITIONS ARE FIXED
%
%   The block diagram of every week is exported into the lecture note. Fixed
%   positions keep that PNG under the 2000 px width a document can display,
%   and they stop the layout decaying every time a block is added by hand.

ORDER = {'command','reference','controller','allocation','plant','measurement'};

p = inputParser;
p.addParameter('Height', 90);
p.addParameter('Width',  110);
p.addParameter('Y',      140);
p.addParameter('Pitch',  160);
p.parse(varargin{:});
o = p.Results;

if ischar(stages) || isstring(stages), stages = {char(stages)}; end
stages = cellfun(@(s) lower(strtrim(s)), stages, 'UniformOutput', false);

bad = setdiff(stages, ORDER);
if ~isempty(bad)
    error('gnc_chain:stage', ...
          'Unknown stage ''%s''. Valid stages are: %s.', bad{1}, strjoin(ORDER, ', '));
end

%  Order the requested stages by the chain, never by the order given. A builder
%  that lists them out of order still produces a diagram that reads correctly.
[~, k] = ismember(stages, ORDER);
[~, s] = sort(k);
stages = stages(s);

x = 40;
P  = struct();
for i = 1:numel(stages)
    st = stages{i};
    w  = pick(o.Width,  st, 110);
    hh = pick(o.Height, st, 90);
    P.(st) = [x, o.Y, x + w, o.Y + hh];
    x = x + o.Pitch;
end
end

% -------------------------------------------------------------------------
function v = pick(spec, name, dflt)
%PICK  A scalar option, or the field of a per-stage struct, or the default.
if isstruct(spec)
    if isfield(spec, name), v = spec.(name); else, v = dflt; end
else
    v = spec;
end
end
