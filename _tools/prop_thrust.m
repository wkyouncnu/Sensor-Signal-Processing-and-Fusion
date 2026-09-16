function T = prop_thrust(n, cfg)
%PROP_THRUST  프로펠러 하나의 추력을 축 회전수에서 구한다. T = k n|n|.
%             One propeller's thrust from its shaft speed, T = k n|n|.
%
%   T = prop_thrust(n, cfg)
%
%     n     축 회전수 [rad/s]. 배열도 받는다 / shaft speed [rad/s], array accepted
%     cfg   otter_config 이 준다. k_pos, k_neg, n_max, n_min 을 가져온다
%           from otter_config, which supplies k_pos, k_neg, n_max and n_min
%
%   왜 n|n| 인가 / why n|n| rather than n^2
%       추력의 크기는 회전수의 제곱을 따르지만 방향은 회전 방향을 따라야 한다.
%       n^2 은 언제나 양수이므로 후진을 표현하지 못한다. n|n| 은 크기는 제곱이면서
%       부호는 n 을 따르므로 두 가지를 한 식에 담는다.
%       The magnitude of thrust follows the square of the shaft speed while its
%       direction must follow the direction of rotation. n^2 is always positive
%       and cannot express going astern; n|n| keeps the square and takes its
%       sign from n, so one expression covers both.
%
%   포화를 먼저 적용한다 / saturation is applied first
%       한계를 넘겨 지시받은 프로펠러는 그 식이 주는 추력을 내지 못하기 때문이다.
%       Because a propeller commanded past its limit does not produce the
%       thrust the formula would give. Reversing
%   uses a different coefficient: a marine propeller has camber and a defined
%   leading edge, so run backwards it presents the wrong face to the flow.
%
%   n|n| and not n^2: the square would throw the sign away and a reversed
%   propeller would still push the vessel forward.

n = min(max(n, cfg.n_min), cfg.n_max);
T = (n >= 0) .* (cfg.k_pos * n .* abs(n)) ...
  + (n <  0) .* (cfg.k_neg * n .* abs(n));
end
