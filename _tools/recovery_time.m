function tr = recovery_time(t, y, yf, t0)
%RECOVERY_TIME  t0 이후 신호가 yf 의 2 % 띠 안에 들어가 **머무르기까지**의 시간.
%               Time after t0 for a signal to reach a 2 % band on yf and stay.
%
%   tr = recovery_time(t, y, yf, t0)
%
%   고리가 무언가에서 빠져나와야 하는 자리마다 쓴다. 2주차의 포화, 3주차의
%   선수방위 되감김이 그렇다.
%   Used wherever a loop has to climb out of something: saturation in Week 2,
%   a heading wrap in Week 3.
%
%   "머무르기까지" 가 요점이다 / the words "and stay" are the point
%       띠를 처음 통과한 시각이 아니라 **마지막으로 벗어난** 시각을 쓴다.
%       지나가는 길에 띠를 가로지른 고리는 회복한 것이 아니기 때문이다. 처음
%       진입을 쓰면 크게 오버슛하는 응답이 가장 빨리 회복한 것으로 나온다.
%
%       The last exit from the band is taken, not the first entry, because a
%       loop that crosses the band on its way past has not recovered. Measured
%       from the first entry, the response that overshoots worst would appear
%       to recover soonest.

k = t >= t0;
t = t(k) - t0;
y = y(k);

out = find(abs(y - yf) > 0.02*yf, 1, 'last');
if isempty(out), tr = 0; else, tr = t(min(out+1, numel(t))); end
end
