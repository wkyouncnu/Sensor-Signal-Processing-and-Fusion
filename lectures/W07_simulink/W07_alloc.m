function [f, info] = W07_alloc(B, tau, method, P)
%W07_ALLOC  tau = [X;Y;N] 하나를 여덟 성분 f 로 배분한다. 법칙 여덟이 한 함수에.
%           One tau = [X;Y;N] split into eight components f. Eight laws in one
%           function, chosen by one flag, so they can be read side by side.
%
%  [f, info] = W07_ALLOC(B, tau, method, P)
%
%  method      무엇을 푸는가                                  / what it solves
%  ---------------------------------------------------------------------------
%  'pinv'      최소노름       f = B'(BB')\tau                  닫힌형
%              minimum norm, closed form
%  'wpinv'     가중 최소노름  f = W\B'(B/W*B')\tau             닫힌형
%              weighted minimum norm, closed form
%  'clip'      가중 해의 각을 한계면 위로 접는다               닫힌형 + 한 줄
%              weighted, then the angle folded onto the servo limit
%  'qp'        각 한계는 제약, tau 는 등식, 부호조합 하나      quadprog x1
%              angle limit as a constraint, tau as an equality, one sigma
%  'wls'       각 한계는 제약, tau 는 비용, 부호조합 하나      lsqlin   x1
%              angle limit as a constraint, tau in the cost, one sigma
%  'wls16'     각 한계는 제약, 부호조합 열여섯 전부            lsqlin  x16
%              angle limit as a constraint, all sixteen sign combinations
%  'wls16cap'  각 한계 **와 추력 한계**를 모두 제약으로        lsqlin  x16
%              angle limit AND thrust cap as constraints, all sixteen
%  'fmincon'   참조 코드의 꼴 — atan2 를 비선형 제약으로       fmincon
%              the reference code's shape: atan2 as a nonlinear constraint
%
%  P.W          8x8 가중 (대각). 어느 성분을 비싸게 매기는가
%               the 8x8 weight: which component is expensive
%  P.alpha_max  서보 한계 [rad] / the servo limit [rad]
%  P.Q          3x3 tau 잔차 가중 ('wls' 계열만)
%               the weight on the tau residual ('wls' family only)
%  P.eps_reg    f 정규화 계수 — 영공간을 묶어 해를 하나로 만든다
%               the regularisation on f, which pins the null space
%  P.T_pos      전진 추력 한계 [N] ('wls16cap' 만). 기본 inf = 캡 없음
%               forward thrust cap [N] ('wls16cap' only); inf means no cap
%  P.T_neg      후진 추력 한계 [N], 양수로 쓴다 ('wls16cap' 만)
%               reverse thrust cap [N], written positive ('wls16cap' only)
%  P.n_chord    원호를 대신할 **내접 현**의 개수 ('wls16cap' 만, 기본 3)
%               how many inscribed chords replace the arc (default 3)
%
%  info.sigma   단위별 추력 부호 (+1 전진, -1 후진). 이것을 고정하면 실행가능
%               영역이 볼록해진다
%               the per-unit thrust sign (+1 ahead, -1 astern): fixing it makes
%               the feasible set convex
%  info.exit    솔버의 exitflag. <= 0 이면 해가 없다
%               the solver exitflag; <= 0 means there is no solution
%  info.cost    그 법칙이 최소화한 값 ('wls' 계열). 부호조합을 줄 세우는 데 쓴다
%               what the law minimised, used to rank the sign combinations
%  info.ntried  실제로 푼 QP 의 개수 — 실시간 예산 계산에 쓴다 (§7-11)
%               how many QPs were solved, for the real-time budget
%
%  왜 이렇게 쓰는가 — 강의 §7-10 · §7-12 / why it is written this way
%  (1) |delta_i| <= alpha_max 는 atan2 로 쓰면 비선형으로 보인다. 그러나 그
%      단위의 추력 **부호** sigma_i 를 먼저 정해 두면 **직선 둘**이다:
%          |f_y| <= tan(alpha_max) * sigma_i * f_x
%      그래서 비선형 문제가 아니라 QP 이고, 국소최소가 없고 훨씬 빠르다.
%      Written through atan2 the servo limit looks nonlinear. Fix the thrust
%      sign sigma_i of that unit first and it is two straight lines, so the
%      problem is a QP: no local minima, and far faster.
%  (2) 네 단위의 부호를 묶지 않은 실행가능 영역은 볼록하지 않다. 그러나
%      **볼록한 영역 2^4 = 16 개**로 정확히 덮인다. 하나만 풀면 빠르고
%      ('qp','wls'), 열여섯을 다 풀면 전역해다.
%      With the four signs left free the feasible set is not convex, but
%      2^4 = 16 convex subsets cover it exactly. Solving one is fast; solving
%      all sixteen gives the global optimum.
%  (3) 각 한계는 하드웨어가 정한 값이고 tau 는 제어기가 요구한 값이다. 그래서
%      'wls' 계열은 각 한계를 제약으로 두고 tau 오차를 비용으로 보낸다 — 요구가
%      실행 불가능할 때에도 해가 늘 있다.
%      The angle limit is set by the hardware; tau is what the controller asked
%      for. The 'wls' family therefore keeps the angle limit as a constraint and
%      moves the tau error into the cost, so a solution always exists even when
%      the demand is infeasible.
%  (4) 'wls16' 까지는 추력 크기 한계를 제약으로 넣지 않는다. f 를 스칼라로 줄이면
%      tau 도 같은 비율로 줄어 **방향이 보존**되므로 풀고 나서 한 번 곱해도 된다
%      (`W07_hw` 의 rho). 'wls16cap' 은 그 한계를 **안에서** 지킨다 — 한 단위만
%      한계에 닿았을 때 전체를 줄이지 않기 때문에 tau 를 덜 버린다 (§7-12).
%      Up to 'wls16' the thrust magnitude limit is left out: scaling f scales
%      tau and preserves its direction, so one multiplication after the solve
%      is enough (rho in W07_hw). 'wls16cap' enforces it inside instead, which
%      gives up less of tau when only one unit is against its cap.
%  (5) 회전수 포화는 **별개의 한계가 아니다.** n = sign(T) sqrt(|T|/k) 이므로
%      |n| <= n_max 는 |T| <= k n_max^2 와 같은 한계를 추력곡선을 통해 본 것일
%      뿐이다. 전진과 후진의 k 가 달라 한계가 둘이다 (§7-12).
%      The shaft-speed saturation is not a separate limit: |n| <= n_max is the
%      same bound as |T| <= k n_max^2, seen through the thrust curve. Ahead and
%      astern have different k, hence two different cap heights.
%
%  See also W07_HW, W07_CHAIN, W07_CA, W07_SL_ALLOC, OTTER_B.

if nargin < 4, P = struct; end
if ~isfield(P,'W'),         P.W = eye(8);              end
if ~isfield(P,'alpha_max'), P.alpha_max = deg2rad(45); end
if ~isfield(P,'Q'),         P.Q = eye(3);              end
if ~isfield(P,'eps_reg'),   P.eps_reg = 1e-4;          end
if ~isfield(P,'T_pos'),     P.T_pos = inf;             end
if ~isfield(P,'T_neg'),     P.T_neg = inf;             end
if ~isfield(P,'n_chord'),   P.n_chord = 3;             end

tau = tau(:);
t   = tan(P.alpha_max);

% --- 닫힌형 둘 / the two closed forms ---------------------------------------
f_pinv  = B' * ((B*B') \ tau);            % 최소노름 / minimum norm
Wi      = P.W \ eye(8);
f_wpinv = Wi * B' * ((B*Wi*B') \ tau);    % 가중 최소노름 / weighted

% 부호조합 하나를 고른다 — 가중 최소노름 해가 가리키는 쪽.
% One sign combination, taken from the weighted minimum-norm solution.
sigma = sign(f_wpinv(1:2:end));
sigma(sigma == 0) = 1;

info.sigma  = sigma(:)';
info.exit   = 1;
info.cost   = NaN;
info.ntried = 0;

switch lower(method)
case 'pinv'
    f = f_pinv;

case 'wpinv'
    f = f_wpinv;

case 'clip'
    % 한계를 넘은 단위만 각을 한계값으로 접는다. 추력 크기는 그대로 둔다.
    % Only the units past the limit have their angle folded onto it; the thrust
    % magnitude is left unchanged.
    f = f_wpinv;
    for i = 1:4
        fx = f(2*i-1);  fy = f(2*i);
        Ti = sigma(i)*hypot(fx, fy);
        de = atan2(sigma(i)*fy, sigma(i)*fx);
        de = min(max(de, -P.alpha_max), P.alpha_max);
        f(2*i-1) = Ti*cos(de);  f(2*i) = Ti*sin(de);
    end

case 'qp'
    % min f'Wf  s.t. Bf = tau, 고른 부호조합 안에서. tau 는 정확히 맞지만 그
    % 조합 안에 실행가능해가 없을 수 있다.
    % Exact tau, but the chosen sign combination may contain no feasible point.
    o = optimoptions('quadprog','Display','off');
    [f, ~, info.exit] = quadprog(2*P.W, zeros(8,1), cone(sigma,t), zeros(8,1), ...
                                 B, tau, [], [], [], o);
    info.ntried = 1;
    if isempty(f), f = f_wpinv; end

case 'wls'
    % min ||Q(Bf-tau)||^2 + eps*||W^(1/2) f||^2, 고른 부호조합 안에서.
    % 각 한계는 그대로 제약이고 tau 만 비용으로 옮겼으므로 해가 늘 있다.
    % The same constraint with tau in the cost: a solution always exists.
    [C, d] = wls_cost(B, tau, P);
    [f, info.cost, info.exit] = solve_sigma(C, d, cone(sigma,t), zeros(8,1));
    info.ntried = 1;
    if isempty(f), f = f_wpinv; end

case 'wls16'
    % 같은 비용, **부호조합 열여섯을 모두** 푼다. 비용이 가장 낮은 것이 전역해다.
    % The same cost on all sixteen sign combinations: the lowest cost is the
    % global optimum.
    [C, d] = wls_cost(B, tau, P);
    f = [];  info.cost = inf;
    for m = 0:15
        sg = 1 - 2*bitget(m, 1:4);
        [x, c, ef] = solve_sigma(C, d, cone(sg,t), zeros(8,1));
        info.ntried = info.ntried + 1;
        if ef > 0 && ~isempty(x) && c < info.cost
            f = x;  info.cost = c;  info.sigma = sg;  info.exit = ef;
        end
    end
    if isempty(f), f = f_wpinv;  info.exit = -2; end

case 'wls16cap'
    % 제약이 둘이다 — 각 한계(직선 둘)와 추력 한계(원호). 원호는 **내접 현**으로
    % 바꾼다. 실행가능 영역을 안쪽으로 깎으므로 나온 해는 반드시 실현 가능하다.
    % Two constraints now: the angle limit (two lines) and the thrust cap (an
    % arc). The arc is replaced by inscribed chords, which shrink the feasible
    % set inwards, so whatever comes out is certainly realisable.
    [C, d] = wls_cost(B, tau, P);
    f = [];  info.cost = inf;
    for m = 0:15
        sg = 1 - 2*bitget(m, 1:4);
        [A, b] = cone_cap(sg, P);
        [x, c, ef] = solve_sigma(C, d, A, b);
        info.ntried = info.ntried + 1;
        if ef > 0 && ~isempty(x) && c < info.cost
            f = x;  info.cost = c;  info.sigma = sg;  info.exit = ef;
        end
    end
    if isempty(f), f = f_wpinv;  info.exit = -2; end

case 'fmincon'
    % 참조 코드의 꼴 — 같은 제약을 atan2 로 쓰면 비선형 문제가 된다.
    % The reference code's shape: the same constraint through atan2 is nonconvex.
    o  = optimoptions('fmincon','Display','off','Algorithm','sqp');
    nl = @(x) deal(arrayfun(@(i) ...
            abs(atan2(x(2*i), x(2*i-1))) - P.alpha_max, (1:4)')', []);
    [f, ~, info.exit] = fmincon(@(x) x'*P.W*x, f_wpinv, [], [], B, tau, ...
                                [], [], nl, o);
    info.ntried = 1;

otherwise
    error('W07_alloc: 모르는 법칙 / unknown law "%s"', method);
end

f = f(:);
end

% ---------------------------------------------------------------------------
function A = cone(sigma, t)
%CONE  부호조합 하나의 선형 제약 A*f <= 0. 단위마다 직선 둘.
%      The linear constraints of one sign combination: two lines per unit.
A = zeros(8,8);
for i = 1:4
    A(2*i-1, 2*i-1) = -t*sigma(i);  A(2*i-1, 2*i) =  1;   %  f_y - t s f_x <= 0
    A(2*i  , 2*i-1) = -t*sigma(i);  A(2*i  , 2*i) = -1;   % -f_y - t s f_x <= 0
end
end

function [A, b] = cone_cap(sigma, P)
%CONE_CAP  각 한계 **와** 추력 한계. 단위마다 직선 둘 + 내접 현 M 개.
%          The angle limit AND the thrust cap: two lines plus M chords per unit.
%
%  단위축으로 x' = sigma*f_x, y' = sigma*f_y 를 쓰면 실현 가능 영역은
%  **원의 부채꼴**이다 — 각이 |delta| <= alpha_max 를, 반지름이 |T| <= R 을 준다.
%  부채꼴의 원호를 각을 M 등분한 현으로 바꾼다. 현 j 의 식은
%      cos(th_j) x' + sin(th_j) y' <= R cos(alpha_max/M)
%  이고, 우변이 R 보다 작으므로 **안쪽**이다. M = 3, alpha_max = 45 도면 현의
%  법선이 -30, 0, +30 도에 서고, 현끼리 만나는 **꼭짓점은 반지름 R 의 원 위에
%  정확히 놓인다** (30 도 떨어진 현 둘이 R cos15 / cos15 = R 에서 만난다).
%  현의 중점만 0.966 R 이므로 다각형은 원에 **내접**하고, 캡을 넘지 않으면서
%  가장 나쁜 곳에서 3.4 % 만 보수적이다.
%
%  In unit axes x' = sigma*f_x, y' = sigma*f_y the feasible set is a circular
%  SECTOR: the angle gives |delta| <= alpha_max and the radius |T| <= R. The
%  arc is replaced by M chords; chord j reads
%      cos(th_j) x' + sin(th_j) y' <= R cos(alpha_max/M),
%  whose right side is below R, so each chord cuts inwards. With M = 3 and
%  alpha_max = 45 deg the normals stand at -30, 0 and +30 deg, and the vertices
%  where neighbouring chords meet lie EXACTLY on the circle of radius R (two
%  chords 30 deg apart meet at R cos15 / cos15 = R). Only the chord midpoints
%  sit at 0.966 R, so the polygon is inscribed: it never breaks the cap, and is
%  at worst 3.4 % conservative.
t = tan(P.alpha_max);
M = P.n_chord;
A = zeros(4*(2+M), 8);
b = zeros(4*(2+M), 1);
r = 0;
for i = 1:4
    s = sigma(i);
    R = P.T_pos*(s > 0) + P.T_neg*(s < 0);    % 캡의 높이가 둘 / two cap heights
    r = r + 1;  A(r, 2*i-1) = -t*s;  A(r, 2*i) =  1;    % 각 한계 / angle limit
    r = r + 1;  A(r, 2*i-1) = -t*s;  A(r, 2*i) = -1;
    for j = 1:M
        th = -P.alpha_max + (j - 0.5)*(2*P.alpha_max/M);
        r  = r + 1;
        A(r, 2*i-1) = s*cos(th);  A(r, 2*i) = s*sin(th);
        b(r)        = R*cos(P.alpha_max/M);
    end
end
end

function [C, d] = wls_cost(B, tau, P)
%WLS_COST  ||C f - d||^2 = ||Q(B f - tau)||^2 + eps*||W^(1/2) f||^2
C = [P.Q*B ; sqrt(P.eps_reg)*sqrt(P.W)];
d = [P.Q*tau ; zeros(8,1)];
end

function [x, c, ef] = solve_sigma(C, d, A, b)
%SOLVE_SIGMA  부호조합 하나의 QP / solve the QP of one sign combination.
persistent o
if isempty(o), o = optimoptions('lsqlin','Display','off'); end
[x, c, ~, ef] = lsqlin(C, d, A, b, [], [], [], [], [], o);
if isempty(x), c = inf; end
end
