function [Mp, ts, tr] = step_metrics(t, y, yf, t0)
%STEP_METRICS  Overshoot, 2 % settling time and 10-90 % rise time of one step.
%
%   [Mp, ts, tr] = step_metrics(t, y, yf, t0)
%
%     t, y   the response
%     yf     the final value asked for
%     t0     the instant the step was applied
%
%   Everything is measured FROM t0, not from t = 0. A model that runs five
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
