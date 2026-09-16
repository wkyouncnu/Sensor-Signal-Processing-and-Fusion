function idx = ship_marks(N, E, k)
%SHIP_MARKS  궤적 위에서 선체를 어디에 그릴 것인가 — 고르게 떨어진 k 개의 점.
%            Where to draw the hull along a track: k points, evenly spaced.
%
%   idx = ship_marks(N, E, k)
%
%   궤적에 대한 인덱스 k 개를 돌려주되, 시간이 아니라 **호의 길이**로 고르게
%   나눈다. 시간으로 나누면 배가 느렸던 곳에 선체가 몰리고 빨랐던 곳은 비게 되는데,
%   Returns k indices into the track, spaced evenly by arc length rather than by
%   time. Spacing by time crowds the silhouettes wherever the vessel was slow
%   and thins them out wherever it was fast, which is the opposite of what a
%   track figure should show.
%
%   A vessel turning on the spot travels almost no distance, so its arc length
%   is nearly constant and no arc-length spacing exists. In that case the
%   function falls back to even spacing in index, which is the right answer:
%   what changes along that track is the heading, not the position.

n = numel(N);
if n == 0, idx = []; return; end
k = min(k, n);
if k <= 1, idx = n; return; end

s = [0; cumsum(hypot(diff(N(:)), diff(E(:))))];

if s(end) < 10*eps*max(1, max(abs([N(:); E(:)])))
    % the vessel stayed put — space in index instead
    idx = unique(round(linspace(1, n, k)));
    return
end

want = linspace(0, s(end), k);
idx  = zeros(1, k);
for i = 1:k
    [~, idx(i)] = min(abs(s - want(i)));
end
idx = unique(idx, 'stable');
end
