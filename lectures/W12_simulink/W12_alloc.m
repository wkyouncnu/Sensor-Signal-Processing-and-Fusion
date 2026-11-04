function [f, info] = W12_alloc(B, tau, method, P)
%W12_ALLOC  tau = [X;Y;N] 하나를 여덟 성분 f 로 배분한다. 법칙 일곱이 한 함수에.
%
%  [f, info] = W12_ALLOC(B, tau, method, P)
%
%  method  'pinv'    최소노름        f = B'(BB')\tau              닫힌형
%          'wpinv'   가중 최소노름   f = W\B'(B/W*B')\tau          닫힌형
%          'clip'    가중 + 벽에 자름                              닫힌형 + 한 줄
%          'qp'      원뿔 딱딱, tau 등식, 부호는 한 번 짐작        quadprog x1
%          'wls'     원뿔 딱딱, tau 최소제곱, 부호는 한 번 짐작    lsqlin   x1
%          'wls16'   원뿔 딱딱, tau 최소제곱, 부호 열여섯 가지 전부 lsqlin  x16
%          'fmincon' 참조 코드의 꼴 — atan2 를 비선형 제약으로     fmincon
%
%  P.W          8x8 가중 (대각). 어느 성분을 비싸게 매길 것인가
%  P.alpha_max  서보 한계 [rad]
%  P.Q          3x3 tau 잔차 가중 ('wls' 'wls16' 만)
%  P.eps_reg    f 정규화 계수 — 영공간을 묶어 해를 하나로 만든다
%
%  info.sigma   단위별 추력 부호 (+1 앞, -1 뒤). 이중원뿔을 반쪽으로 가르는 것
%  info.exit    솔버의 exitflag ('pinv' 'wpinv' 'clip' 은 1). <=0 이면 해가 없다
%  info.cost    그 법칙이 최소화한 값 ('wls' 'wls16' 만). 열여섯 조각 비교에 쓴다
%  info.ntried  실제로 푼 QP 의 개수 — 실시간 예산 계산에 쓴다 (§12-11)
%
%  왜 이렇게 쓰는가 — 강의 §12-10 참조.
%  (1) |delta_i| <= alpha_max 는 atan2 를 쓰면 비선형으로 보이지만, 그 단위의
%      추력 **부호** sigma_i 를 먼저 정해 두면 **직선 둘**이다:
%          |f_y| <= tan(alpha_max) * sigma_i * f_x
%      그래서 비선형 문제가 아니라 QP 이고, 국소최소가 없고 훨씬 빠르다.
%  (2) 이중원뿔은 볼록하지 않다. 그러나 **볼록한 조각 2^4 = 16 개**로 정확히
%      덮인다. 조각을 하나 짐작하면 빠르고('qp' 'wls'), 열여섯을 다 풀면
%      참값이다('wls16'). 짐작이 틀리면 벽이 셀 때 답이 나빠지거나 아예 없다 —
%      tau = [15;70;10] 이 그 예다 (§12-10 에서 재어 둔다).
%  (3) 서보 벽은 물리이고 tau 요구는 바람이다. 그래서 'wls' 계열은 벽을 딱딱하게
%      두고 tau 를 비용으로 보낸다 — 참조 코드와 반대 방향이며, 요구가
%      불가능할 때에도 해가 늘 있다.
%  (4) 추력 크기 한계는 제약으로 넣지 않는다. f 를 스칼라로 줄이면 tau 도 같은
%      비율로 줄어 **방향이 보존**되므로, 풀고 나서 한 번 곱하면 된다 (W12_hw).

if nargin < 4, P = struct; end
if ~isfield(P,'W'),         P.W = eye(8);                  end
if ~isfield(P,'alpha_max'), P.alpha_max = deg2rad(45);      end
if ~isfield(P,'Q'),         P.Q = eye(3);                   end
if ~isfield(P,'eps_reg'),   P.eps_reg = 1e-4;               end

tau = tau(:);
t   = tan(P.alpha_max);

% --- 닫힌형 둘 ---------------------------------------------------------------
f_pinv  = B' * ((B*B') \ tau);                       % 최소노름
Wi      = P.W \ eye(8);
f_wpinv = Wi * B' * ((B*Wi*B') \ tau);               % 가중 최소노름

% 짐작하는 부호: 가중 최소노름이 가리키는 쪽. 조각 하나를 고르는 한 줄.
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
    f = f_wpinv;
    for i = 1:4
        fx = f(2*i-1);  fy = f(2*i);
        Ti = sigma(i)*hypot(fx,fy);
        de = atan2(sigma(i)*fy, sigma(i)*fx);
        de = min(max(de, -P.alpha_max), P.alpha_max);
        f(2*i-1) = Ti*cos(de);  f(2*i) = Ti*sin(de);
    end

case 'qp'
    % min f'Wf  s.t.  Bf = tau, 짐작한 조각.  tau 를 정확히 내되 해가 없을 수 있다.
    o = optimoptions('quadprog','Display','off');
    [f, ~, info.exit] = quadprog(2*P.W, zeros(8,1), cone(sigma,t), zeros(8,1), ...
                                 B, tau, [], [], [], o);
    info.ntried = 1;
    if isempty(f), f = f_wpinv; end

case 'wls'
    % min ||Q(Bf-tau)||^2 + eps*||W^(1/2) f||^2  s.t. 짐작한 조각.  해가 늘 있다.
    [C, d] = wls_cost(B, tau, P);
    [f, info.cost, info.exit] = solve_piece(C, d, cone(sigma,t));
    info.ntried = 1;
    if isempty(f), f = f_wpinv; end

case 'wls16'
    % 같은 비용, **조각 열여섯을 모두** 푼다. 비용이 가장 낮은 것이 참값이다.
    [C, d] = wls_cost(B, tau, P);
    f = [];  info.cost = inf;
    for m = 0:15
        sg = 1 - 2*bitget(m, 1:4);
        [x, c, ef] = solve_piece(C, d, cone(sg,t));
        info.ntried = info.ntried + 1;
        if ef > 0 && ~isempty(x) && c < info.cost
            f = x;  info.cost = c;  info.sigma = sg;  info.exit = ef;
        end
    end
    if isempty(f), f = f_wpinv;  info.exit = -2; end

case 'fmincon'
    % 참조 코드의 꼴 — 같은 제약을 atan2 로 쓰면 비선형 문제가 된다.
    o = optimoptions('fmincon','Display','off','Algorithm','sqp');
    nl = @(x) deal(arrayfun(@(i) ...
            abs(atan2(x(2*i), x(2*i-1))) - P.alpha_max, (1:4)')', []);
    [f, ~, info.exit] = fmincon(@(x) x'*P.W*x, f_wpinv, [], [], B, tau, ...
                                [], [], nl, o);
    info.ntried = 1;

otherwise
    error('W12_alloc: 모르는 법칙 "%s"', method);
end

f = f(:);
end

% ---------------------------------------------------------------------------
function A = cone(sigma, t)
%CONE  조각 하나의 선형 제약 A*f <= 0. 단위마다 직선 둘.
A = zeros(8,8);
for i = 1:4
    A(2*i-1, 2*i-1) = -t*sigma(i);  A(2*i-1, 2*i) =  1;   %  f_y - t*s*f_x <= 0
    A(2*i  , 2*i-1) = -t*sigma(i);  A(2*i  , 2*i) = -1;   % -f_y - t*s*f_x <= 0
end
end

function [C, d] = wls_cost(B, tau, P)
%WLS_COST  ||C f - d||^2 = ||Q(Bf-tau)||^2 + eps*||W^(1/2) f||^2
C = [P.Q*B ; sqrt(P.eps_reg)*sqrt(P.W)];
d = [P.Q*tau ; zeros(8,1)];
end

function [x, c, ef] = solve_piece(C, d, A)
%SOLVE_PIECE  조각 하나를 푼다.
persistent o
if isempty(o), o = optimoptions('lsqlin','Display','off'); end
[x, c, ~, ef] = lsqlin(C, d, A, zeros(8,1), [], [], [], [], [], o);
if isempty(x), c = inf; end
end
