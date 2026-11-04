function [f, info] = W12_alloc(B, tau, method, P)
%W12_ALLOC  tau = [X;Y;N] 하나를 여덟 성분 f 로 배분한다. 법칙 여덟이 한 함수에.
%           One tau = [X;Y;N] split into eight components f. Eight laws in one
%           function, chosen by one flag, so they can be read side by side.
%
%  [f, info] = W12_ALLOC(B, tau, method, P)
%
%  method      무엇을 푸는가                                  / what it solves
%  ---------------------------------------------------------------------------
%  'pinv'      최소노름       f = B'(BB')\tau                  닫힌형
%              minimum norm, closed form
%  'wpinv'     가중 최소노름  f = W\B'(B/W*B')\tau             닫힌형
%              weighted minimum norm, closed form
%  'clip'      가중 + 벽 위로 각을 접는다                      닫힌형 + 한 줄
%              weighted, then the angle folded onto the wall
%  'qp'        원뿔 딱딱, tau 등식, 부호를 한 번 짐작          quadprog x1
%              hard cone, tau as an equality, the sign guessed once
%  'wls'       원뿔 딱딱, tau 는 비용, 부호를 한 번 짐작       lsqlin   x1
%              hard cone, tau in the cost, the sign guessed once
%  'wls16'     원뿔 딱딱, 부호 조각 열여섯을 전부              lsqlin  x16
%              hard cone, all sixteen sign pieces
%  'wls16cap'  원뿔 **과 추력 캡** 둘 다 딱딱, 열여섯 전부     lsqlin  x16
%              hard cone AND hard thrust cap, all sixteen pieces
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
%  info.sigma   단위별 추력 부호 (+1 앞, -1 뒤). 이중원뿔을 반쪽으로 가르는 것
%               the per-unit thrust sign (+1 forward, -1 reverse): the choice
%               that cuts the double cone into one convex half
%  info.exit    솔버의 exitflag. <= 0 이면 해가 없다
%               the solver exitflag; <= 0 means there is no solution
%  info.cost    그 법칙이 최소화한 값 ('wls' 계열). 조각을 줄 세우는 데 쓴다
%               what the law minimised, used to rank the pieces
%  info.ntried  실제로 푼 QP 의 개수 — 실시간 예산 계산에 쓴다 (§12-11)
%               how many QPs were solved, for the real-time budget
%
%  왜 이렇게 쓰는가 — 강의 §12-10 · §12-12 / why it is written this way
%  (1) |delta_i| <= alpha_max 는 atan2 로 쓰면 비선형으로 보인다. 그러나 그
%      단위의 추력 **부호** sigma_i 를 먼저 정해 두면 **직선 둘**이다:
%          |f_y| <= tan(alpha_max) * sigma_i * f_x
%      그래서 비선형 문제가 아니라 QP 이고, 국소최소가 없고 훨씬 빠르다.
%      Written through atan2 the servo limit looks nonlinear. Fix the thrust
%      sign sigma_i of that unit first and it is two straight lines, so the
%      problem is a QP: no local minima, and far faster.
%  (2) 이중원뿔은 볼록하지 않다. 그러나 **볼록한 조각 2^4 = 16 개**로 정확히
%      덮인다. 하나를 짐작하면 빠르고('qp','wls'), 열여섯을 다 풀면 참값이다.
%      The double cone is not convex, but 2^4 = 16 convex pieces cover it
%      exactly. Guessing one piece is fast; solving all sixteen is exact.
%  (3) 서보 벽은 물리이고 tau 요구는 바람이다. 그래서 'wls' 계열은 벽을 딱딱하게
%      두고 tau 를 비용으로 보낸다 — 참조 코드와 반대 방향이며, 요구가
%      불가능할 때에도 해가 늘 있다.
%      The wall is physics and the demand is a wish, so the 'wls' family keeps
%      the wall hard and puts tau in the cost. A solution therefore always
%      exists, even when the demand does not.
%  (4) 'wls16' 까지는 추력 크기 한계를 제약으로 넣지 않는다. f 를 스칼라로 줄이면
%      tau 도 같은 비율로 줄어 **방향이 보존**되므로 풀고 나서 한 번 곱해도 된다
%      (`W12_hw` 의 rho). 'wls16cap' 은 그 한계를 **안에서** 지킨다 — 한 단위만
%      한계에 닿았을 때 전체를 줄이지 않기 때문에 tau 를 덜 버린다 (§12-12).
%      Up to 'wls16' the thrust magnitude limit is left out: scaling f scales
%      tau and preserves its direction, so one multiplication after the solve
%      is enough (rho in W12_hw). 'wls16cap' enforces it inside instead, which
%      gives up less of tau when only one unit is against its cap.
%  (5) 회전수 포화는 **별개의 한계가 아니다.** n = sign(T) sqrt(|T|/k) 이므로
%      |n| <= n_max 는 |T| <= k n_max^2 와 같은 벽이고, 곡선을 통해 본 것일
%      뿐이다. 전진과 후진의 k 가 달라 벽의 높이가 둘이다 (§12-12).
%      The shaft-speed saturation is not a separate limit: |n| <= n_max is the
%      same wall as |T| <= k n_max^2, seen through the thrust curve. Forward
%      and reverse have different k, hence two different cap heights.
%
%  See also W12_HW, W12_CHAIN, W12_G_ALLOCATION, W12_K_HARDWARE, OTTER_B.

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

% 짐작하는 부호: 가중 최소노름이 가리키는 쪽. 조각 하나를 고르는 한 줄.
% The guessed sign: whichever way the weighted minimum norm points.
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
    % 벽을 넘은 단위만 벽 위로 각을 접는다. 추력 크기는 그대로 둔다.
    % Only the units past the wall are folded onto it; the magnitude stays.
    f = f_wpinv;
    for i = 1:4
        fx = f(2*i-1);  fy = f(2*i);
        Ti = sigma(i)*hypot(fx, fy);
        de = atan2(sigma(i)*fy, sigma(i)*fx);
        de = min(max(de, -P.alpha_max), P.alpha_max);
        f(2*i-1) = Ti*cos(de);  f(2*i) = Ti*sin(de);
    end

case 'qp'
    % min f'Wf  s.t. Bf = tau, 짐작한 조각 안에서. tau 는 정확하지만 해가 없을 수 있다.
    % Exact tau, but on a guessed piece there may be no solution at all.
    o = optimoptions('quadprog','Display','off');
    [f, ~, info.exit] = quadprog(2*P.W, zeros(8,1), cone(sigma,t), zeros(8,1), ...
                                 B, tau, [], [], [], o);
    info.ntried = 1;
    if isempty(f), f = f_wpinv; end

case 'wls'
    % min ||Q(Bf-tau)||^2 + eps*||W^(1/2) f||^2, 짐작한 조각 안에서. 해가 늘 있다.
    % The same wall, tau in the cost: a solution always exists.
    [C, d] = wls_cost(B, tau, P);
    [f, info.cost, info.exit] = solve_piece(C, d, cone(sigma,t), zeros(8,1));
    info.ntried = 1;
    if isempty(f), f = f_wpinv; end

case 'wls16'
    % 같은 비용, **조각 열여섯을 모두** 푼다. 비용이 가장 낮은 것이 참값이다.
    % The same cost on all sixteen pieces: the cheapest one is the true answer.
    [C, d] = wls_cost(B, tau, P);
    f = [];  info.cost = inf;
    for m = 0:15
        sg = 1 - 2*bitget(m, 1:4);
        [x, c, ef] = solve_piece(C, d, cone(sg,t), zeros(8,1));
        info.ntried = info.ntried + 1;
        if ef > 0 && ~isempty(x) && c < info.cost
            f = x;  info.cost = c;  info.sigma = sg;  info.exit = ef;
        end
    end
    if isempty(f), f = f_wpinv;  info.exit = -2; end

case 'wls16cap'
    % 벽이 둘이다 — 서보 원뿔(직선 둘)과 추력 캡(원호). 원호는 **내접 현**으로
    % 바꾼다. 안쪽으로 깎으므로 나온 해는 반드시 실현 가능하다.
    % Two walls now: the servo cone (two lines) and the thrust cap (an arc).
    % The arc is replaced by inscribed chords, which cut inwards, so whatever
    % comes out is certainly realisable.
    [C, d] = wls_cost(B, tau, P);
    f = [];  info.cost = inf;
    for m = 0:15
        sg = 1 - 2*bitget(m, 1:4);
        [A, b] = cone_cap(sg, P);
        [x, c, ef] = solve_piece(C, d, A, b);
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
    error('W12_alloc: 모르는 법칙 / unknown law "%s"', method);
end

f = f(:);
end

% ---------------------------------------------------------------------------
function A = cone(sigma, t)
%CONE  조각 하나의 선형 제약 A*f <= 0. 단위마다 직선 둘.
%      One piece's linear constraints: two straight lines per unit.
A = zeros(8,8);
for i = 1:4
    A(2*i-1, 2*i-1) = -t*sigma(i);  A(2*i-1, 2*i) =  1;   %  f_y - t s f_x <= 0
    A(2*i  , 2*i-1) = -t*sigma(i);  A(2*i  , 2*i) = -1;   % -f_y - t s f_x <= 0
end
end

function [A, b] = cone_cap(sigma, P)
%CONE_CAP  원뿔 **과** 추력 캡. 단위마다 직선 둘 + 내접 현 M 개.
%          The cone AND the thrust cap: two lines plus M inscribed chords.
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
    r = r + 1;  A(r, 2*i-1) = -t*s;  A(r, 2*i) =  1;    % 서보 벽 / the wall
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

function [x, c, ef] = solve_piece(C, d, A, b)
%SOLVE_PIECE  조각 하나를 푼다 / solve one piece.
persistent o
if isempty(o), o = optimoptions('lsqlin','Display','off'); end
[x, c, ~, ef] = lsqlin(C, d, A, b, [], [], [], [], [], o);
if isempty(x), c = inf; end
end
