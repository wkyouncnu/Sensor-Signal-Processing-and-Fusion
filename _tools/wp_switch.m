function [k_new, done] = wp_switch(k, N, E, WP, R, mode)
%WP_SWITCH  Decide whether to move on to the next waypoint.
%
%   [k_new, done] = wp_switch(k, N, E, WP, R, mode)
%
%     k      index of the active waypoint, 1 .. size(WP,1)-1
%     N, E   vessel position [m]
%     WP     n-by-2 waypoint list, [N E] per row
%     R      switching parameter [m]
%     mode   1 = along-track (the MSS criterion)
%            2 = circle of acceptance
%
%     k_new  the index to use from now on
%     done   true once the last leg has been completed
%
%   TWO CRITERIA, AND THEY ARE NOT THE SAME
%
%   1  ALONG-TRACK, which is what MSS ILOSpsi.m and LOSchi.m use:
%
%          switch when   d - x_e < R
%
%      d is the length of the current leg and x_e the distance travelled
%      along it, so d - x_e is the distance REMAINING along the leg. The test
%      ignores how far the vessel is to the side of the path entirely.
%
%   2  CIRCLE OF ACCEPTANCE, the form most textbooks draw:
%
%          switch when   norm([N E] - wp_next) < R
%
%      This is a true distance, so a vessel far off the path never triggers
%      it, and a vessel blown past the waypoint on the wrong side may loiter
%      for ever.
%
%   THEY DIFFER WHENEVER y_e IS LARGE. With the vessel R metres short of the
%   waypoint but 2R to the side, criterion 1 switches and criterion 2 does
%   not. Section F of Week 4 measures that.
%
%   MSS DOCUMENTATION SLIP, worth knowing before reading the source: the help
%   text of ILOSpsi.m says "go to next waypoint when the along-track distance
%   x_e is less than R_switch", but the code tests d - x_e < R_switch, which
%   is the distance REMAINING, not the distance travelled. The code is the
%   sensible one; the sentence is wrong.
%
%   FEASIBILITY. R must be smaller than the shortest leg, or the vessel
%   satisfies the switching test for a leg it has not started and skips it.
%   MSS raises an error on this; so does this function.

n = size(WP, 1);

if k >= n - 1 + 1                       % already on the final waypoint
    k_new = n;  done = true;  return
end

%  ---- feasibility, checked once per call: it is cheap and it is a real trap
legs = hypot(diff(WP(:,1)), diff(WP(:,2)));
if R > min(legs)
    error('wp_switch:R', ...
        'R = %.2f m exceeds the shortest leg, %.2f m. The vessel would skip a waypoint.', ...
        R, min(legs));
end

wp_k    = WP(k,   :);
wp_next = WP(k+1, :);

switch mode
    case 1                                          % along-track
        [x_e, ~] = crosstrack_err(N, E, wp_k, wp_next);
        d        = hypot(wp_next(1)-wp_k(1), wp_next(2)-wp_k(2));
        hit      = (d - x_e) < R;
    case 2                                          % circle of acceptance
        hit      = hypot(N - wp_next(1), E - wp_next(2)) < R;
    otherwise
        error('wp_switch:mode', 'mode must be 1 (along-track) or 2 (circle).');
end

if hit && k < n-1
    k_new = k + 1;  done = false;
elseif hit
    k_new = k;      done = true;                    % last leg finished
else
    k_new = k;      done = false;
end
end
