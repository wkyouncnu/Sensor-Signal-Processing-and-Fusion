function [Mp, ts, tr] = step_metrics(t, y, yf, t0)
%STEP_METRICS  계단응답의 오버슛, 2 % 정착시간, 10-90 % 상승시간.
%              Overshoot, 2 % settling time and 10-90 % rise time of one step.
%
%   [Mp, ts, tr] = step_metrics(t, y, yf, t0)
%
%     t, y   응답 / the response
%     yf     요구한 최종값 / the final value asked for
%     t0     계단이 가해진 시각 / the instant the step was applied
%
%   모든 값을 t = 0 이 아니라 t0 부터 잰다. 정의를 한곳에 모아 두는 이유는,
%   같은 양을 재는 방법이 스크립트마다 조금씩 달라지면 주차 사이의 비교가
%   무의미해지기 때문이다. 실제로 5주차 채점기가 각을 강의와 다른 방법으로 재어
%   0.56 도 어긋나 오답 처리를 낸 적이 있다.
%
%   Everything is measured from t0 rather than from t = 0. The definitions are
%   kept in one place because a quantity measured slightly differently in each
%   script makes comparison between weeks meaningless: the Week 5 checker once
%   measured an angle by a different definition from the lecture's, disagreed
%   by 0.56 deg, and failed a correct submission.
%
%   A model that runs five
%   seconds before the step would otherwise report a settling time five
%   seconds too long, and the error is easy to miss because the number still
%   looks reasonable.
%
%   Settling time is the last instant the response is outside the 2 % band,
%   not the first instant it enters: a response that re-enters the band and
%   leaves it again has not settled.

k  = t >= t0;
t  = t(k) - t0;
y  = y(k);

Mp = 100*(max(y) - yf)/yf;

out = find(abs(y - yf) > 0.02*yf, 1, 'last');
if isempty(out), ts = 0; else, ts = t(out); end

k1 = find(y >= 0.1*yf, 1);
k2 = find(y >= 0.9*yf, 1);
if isempty(k1) || isempty(k2), tr = NaN; else, tr = t(k2) - t(k1); end
end
