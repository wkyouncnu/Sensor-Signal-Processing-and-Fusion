function tr = recovery_time(t, y, yf, t0)
%RECOVERY_TIME  Time after t0 for a signal to reach a 2 % band on yf and STAY.
%
%   tr = recovery_time(t, y, yf, t0)
%
%   Used wherever a loop has to climb out of something — saturation in Week 2,
%   a heading wrap in Week 3. The distinction that matters is "and stay": the
%   last exit from the band is taken, not the first entry, because a loop that
%   crosses the band on its way past has not recovered.

k = t >= t0;
t = t(k) - t0;
y = y(k);

out = find(abs(y - yf) > 0.02*yf, 1, 'last');
if isempty(out), tr = 0; else, tr = t(min(out+1, numel(t))); end
end
