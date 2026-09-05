function T = prop_thrust(n, cfg)
%PROP_THRUST  One propeller's thrust from its shaft speed, T = k n|n|.
%
%   T = prop_thrust(n, cfg)
%
%     n     shaft speed [rad/s]. Accepts an array
%     cfg   from otter_config: supplies k_pos, k_neg, n_max, n_min
%
%   Saturation is applied FIRST, because a propeller that is commanded past
%   its limit does not produce the thrust that formula would give. Reversing
%   uses a different coefficient: a marine propeller has camber and a defined
%   leading edge, so run backwards it presents the wrong face to the flow.
%
%   n|n| and not n^2: the square would throw the sign away and a reversed
%   propeller would still push the vessel forward.

n = min(max(n, cfg.n_min), cfg.n_max);
T = (n >= 0) .* (cfg.k_pos * n .* abs(n)) ...
  + (n <  0) .* (cfg.k_neg * n .* abs(n));
end
