function [tau, n, d, T] = W07_tau(Srow, cfg)
%W07_TAU  시나리오 한 줄에서 **손 수식으로** tau 를 구한다. 이 주차의 유일한 사본.
%         The hand formula for one scenario row, written once.
%
%   [tau, n, d, T] = W07_tau(Srow, cfg)
%
%     Srow   `W07_cases` 의 한 줄 — {tag, n [rad/s], delta [deg], 이름, 예상}
%     tau    [X Y N], 손으로 쓴 것
%     n      서보·회전수 한계로 **깎인 뒤**의 축회전수 [rad/s]
%     d      깎인 뒤의 틸팅 각 [rad]
%     T      추진기별 추력 [N], 거치 부호를 **입히기 전**
%
%   수식 / the formula
%       X = sum si Ti cos di
%       Y = sum si Ti sin di
%       N = sum si (xi sin di - yi cos di) Ti
%
%       s 는 **거치 부호**다. 선수 둘은 서보 0 도가 +x_b 를, 선미 둘은 -x_b 를
%       민다 / s is the mounting sign: servo zero pushes forward at the bow and
%       aft at the stern, which is why the two pairs define zero differently
%
%   왜 한 사본인가 / why exactly one copy
%       표 (1), 표 (3) 의 비대칭 설명, 시나리오 그림의 힘 화살표가 **같은 수식**을
%       필요로 한다. 세 군데에 적으면 한 군데만 고쳐지고, 그러면 그림이 표와
%       다른 배를 그린다 / three callers need this formula, and three copies means
%       one of them is eventually wrong
%
%   스스로 검사한다 / it checks itself
%       같은 것을 열 규칙(`otter_B`)으로 한 번 더 구해 견준다. 부호는 `f` 가
%       아니라 **B 의 열**이 들고 있다.
%
%   See also W07_CASES, W07_TAB_FORMULA, W07_TAB_TRACK, W07_PLOT_SCENARIO,
%            OTTER_B, OTTER_TILT4.

%  서보와 회전수 한계를 손으로 한 번 더 — 모델이 깎은 값과 **같은 값**으로 재야
%  표의 두 열이 같은 것을 가리킨다 / the clip is repeated by hand so the table
%  compares like with like
n = min(max(Srow{2}, cfg.n_min), cfg.n_max);
d = min(max(deg2rad(Srow{3}), -cfg.alpha_max), cfg.alpha_max);

T = (cfg.k_pos*(n >= 0) + cfg.k_neg*(n < 0)) .* n .* abs(n);

s = cfg.mount;
X = sum(s .* T .* cos(d));
Y = sum(s .* T .* sin(d));
N = sum(s .* (cfg.pos(1,:) .* sin(d) - cfg.pos(2,:) .* cos(d)) .* T);

tau = [X Y N];

%  열 규칙과 같은지 / the same thing through otter_B's column rule
f = zeros(2*cfg.n_thr, 1);
f(1:2:end) = T .* cos(d);
f(2:2:end) = T .* sin(d);
assert(max(abs(cfg.B*f - tau(:))) < 1e-12, 'W07:columnRule', ...
       'the hand formula and otter_B disagree on %s', Srow{1});

end
