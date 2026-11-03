function k = W12_pick(S, pick)
%W12_PICK  어떤 시나리오를 돌릴지 고른다. 하나든, 몇 개든, 전부든.
%          Which scenarios to run: one, a few, or all of them.
%
%   k = W12_pick(S, pick)
%
%     S      `W12_cases` 가 돌려준 8 x 5 셀
%     pick   'all' | 'S5' | {'S1','S5'} | 5 | [1 5 7]
%     k      S 의 줄 번호 / row indices into S
%
%   왜 고를 수 있어야 하는가 / why the choice exists
%       여덟을 한 번에 돌리면 한 시나리오만 보고 싶을 때도 30 초 운항 여덟 번을
%       기다려야 하고, 겹쳐 그린 그림에서는 **어느 것이 예상대로 되었는지** 읽을
%       수 없다. 그래서 절 스크립트는 하나씩 부를 수 있다.
%       Running all eight to look at one of them wastes seven runs, and an
%       overlay cannot answer "did S5 do what S5 was supposed to do".
%
%   See also W12_V_OPENLOOP, W12_CASES, W12_PLOT_SCENARIO.

if nargin < 2 || isempty(pick), pick = 'all'; end

if isnumeric(pick)
    k = pick(:)';
    assert(all(k >= 1 & k <= size(S,1)), 'W12:pickRange', ...
           'scenario index outside 1..%d', size(S,1));
    return
end

if ischar(pick), pick = {pick}; end

if numel(pick) == 1 && strcmpi(pick{1}, 'all')
    k = 1:size(S,1);
    return
end

k = zeros(1, numel(pick));
for i = 1:numel(pick)
    j = find(strcmpi(S(:,1), pick{i}));
    assert(~isempty(j), 'W12:noSuchCase', ...
           'no scenario named %s; the tags are %s', pick{i}, strjoin(S(:,1)', ' '));
    k(i) = j;
end

end
