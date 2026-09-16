function row_feed(sys, dst, srcs)
%ROW_FEED  각 공급 블록을 자기가 먹이는 포트의 행으로 옮기고, 그대로 연결한다.
%          Put every source block on the row of the port it feeds, and wire it.
%
%   row_feed(a, 'allocation', {'tau_N','X_ff','k_pos','k_neg','n_max','n_min','y_pont'})
%
%   왜 필요한가 / why this exists
%       입력이 많은 블록은 도면을 못 읽게 만드는 가장 흔한 원인이다. 파라미터를
%       신호로 받는 MATLAB Function 이 그렇다. 왼쪽에 상수 블록 일곱 개가 쌓이고,
%       선 일곱 개가 꺾여 들어가며, 자동 배선이 그중 몇 개를 같은 세로줄로 합친다.
%
%       상수 하나하나를 자기 포트의 높이로 옮기면 그 선들이 전부 곧은 한 도막이
%       되고, 곧은 선은 겹칠 수가 없다. 배치로 문제를 푸는 것이 배선으로 푸는
%       것보다 낫다.
%
%       A block with many inputs — a MATLAB Function taking its parameters as
%       signals — is the usual source of unreadable wiring: seven Constants
%       stacked on the left, seven lines jogging into seven ports, and
%       autorouting merging several of them into one vertical run. Moving each
%       Constant onto the height of its own port turns every one of those
%       lines into a single straight segment, and straight lines cannot
%       overlap. Solving the problem by placement is better than solving it by
%       routing.
%
%   Each source must have exactly one output port, which is true of Constants,
%   Inports, Gains and Selectors. Sources are moved vertically only; their x
%   stays where the builder put it. An empty entry in SRCS leaves that port
%   alone, for a port fed from somewhere else.
%
%   A warning is issued when the destination block is too short for the number
%   of ports it carries, because that is the one thing this function cannot
%   fix: the block must be made taller in the builder.

h = get_param([sys '/' dst], 'PortHandles');
n = numel(h.Inport);

if n > 1
    p     = get_param([sys '/' dst], 'Position');
    pitch = (p(4) - p(2) - 40) / (n - 1);
    if pitch < 52
        warning('row_feed:tight', ...
            ['%s/%s has %d ports %.1f px apart. Make it %d px tall so the ' ...
             'feeding blocks clear each other''s names.'], ...
            sys, dst, n, pitch, 52*(n-1) + 40);
    end
end

for k = 1:min(numel(srcs), n)
    if isempty(srcs{k}), continue, end
    y = port_xy(sys, dst, 'Inport', k);
    b = [sys '/' srcs{k}];
    q = get_param(b, 'Position');
    dy = round(y(2) - (q(2) + q(4))/2);
    set_param(b, 'Position', q + [0 dy 0 dy]);
    add_line(sys, [srcs{k} '/1'], sprintf('%s/%d', dst, k));
end
end
