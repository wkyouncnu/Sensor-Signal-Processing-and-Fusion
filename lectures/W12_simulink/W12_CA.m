function W12_CA(part)
%W12_CA  제어배분 절 전체를 **한 파일에서** 돌린다. 인자가 절을 고른다.
%        One file runs the whole control-allocation part; the argument selects
%        the section.
%
%   사용법 / usage
%       W12_CA        모든 절을 차례로        / every section, in order
%       W12_CA(8)     12-8   최소노름 해      / the minimum-norm solution
%       W12_CA(9)     12-9   가중행렬 W       / the weight matrix
%       W12_CA(10)    12-10  서보 각 한계     / the servo-angle limit
%       W12_CA(11)    12-11  계산 시간        / the solve time
%       W12_CA(12)    12-12  회전수 한계까지  / the shaft-speed limit as well
%
%   배분 법칙 자체는 `W12_alloc` 하나에 모두 들어 있고 이름 하나로 고른다.
%   같은 선택을 Simulink 에서 하려면 `W12_alloc_chain` 의 law 상수를 바꾼다.
%   All the allocation laws live in W12_alloc and are picked by name. The same
%   choice is made in Simulink by the law constant of W12_alloc_chain.

if nargin < 1, part = [8 9 10 11 12]; end

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
here = fileparts(mfilename('fullpath'));
cfg  = otter_config('quad_tilt');
B    = cfg.B;

% 모든 절이 같은 설정을 쓴다 / every section uses the same settings
P.W         = diag(repmat([1 10], 1, 4));   % 가로 성분이 열 배 비싸다 / f_y priced 10x
P.alpha_max = cfg.alpha_max(1);             % 서보 각 한계 / servo-angle limit
P.Q         = eye(3);                       % tau 오차의 가중 / weight on the tau error
P.eps_reg   = 1e-4;                         % 정칙화 / regularisation

for s = part(:).'
    switch s
        case 8,  sec08(B, cfg, here);
        case 9,  sec09(B, cfg, here);
        case 10, sec10(B, cfg, P, here);
        case 11, sec11(B, P);
        case 12, sec12(B, cfg, P, here);
        otherwise, error('W12_CA:part', 'part must be 8, 9, 10, 11 or 12');
    end
end
end

% ========================================================================= %
function sec08(B, cfg, here)
%SEC08  12-8 — 해는 무한히 많고, 그 중 노름이 가장 작은 하나를 고른다.
%       12-8: the solutions are infinite in number; the one of least norm is
%       taken.
tau_d = [80; 30; 20];
fprintf('\n=== 12-8  the allocation problem and its minimum-norm solution ===\n');
fprintf('B is %dx%d,  rank %d,  null space dimension %d\n', ...
        size(B,1), size(B,2), rank(B), size(B,2)-rank(B));
fprintf('demand  tau_d = [%.0f N, %.0f N, %.0f N m]\n', tau_d);

% 영공간 벡터를 더해도 같은 tau 가 나온다 / a null-space vector leaves tau unchanged
f0 = W12_alloc(B, tau_d, 'pinv');
Z  = null(B);
f1 = f0 + 40*Z(:,1);
fprintf('\n(1) two solutions that give the same tau\n');
fprintf('    minimum norm      ||f|| = %7.2f N   ||B f - tau|| = %.2e\n', ...
        norm(f0), norm(B*f0 - tau_d));
fprintf('    null space added        %7.2f N   %21.2e\n', ...
        norm(f1), norm(B*f1 - tau_d));
fprintf('    -> the same force costs the thrusters %.0f %% more\n', ...
        100*(norm(f1)/norm(f0) - 1));

fprintf('\n(2) minimum norm  f = B^T (B B^T)^{-1} tau\n');
fprintf('    unit      f_x [N]   f_y [N]\n');
fprintf('     %d      %9.3f %9.3f\n', [1:4; f0(1:2:7).'; f0(2:2:8).']);

% 여덟 성분을 여덟 명령으로 / the eight components, turned into eight commands
H = W12_hw(B, f0, cfg);
fprintf('\n(3) hardware command\n');
fprintf('    unit     T [N]   delta [deg]    n [rad/s]   |delta|<=45?\n');
for i = 1:4
    fprintf('     %d    %8.3f %11.2f %12.2f        %s\n', i, H.T(i), ...
        rad2deg(H.delta(i)), H.n(i), ...
        string(abs(H.delta(i)) <= cfg.alpha_max(i)+1e-9));
end
fprintf('    rho = %.4f   (1 means the thrust limit was not reached)\n', H.rho);
fprintf('    tau achieved = [%.3f %.3f %.3f]   distance from the demand %.2e\n', ...
        H.tau, norm(H.tau - tau_d));

W12_plot_alloc(cfg, H, tau_d, here);
end

% ========================================================================= %
function sec09(B, cfg, here)
%SEC09  12-9 — 가중행렬은 값표다. 무엇이 바뀌고 무엇은 바뀌지 않는가.
%       12-9: the weight matrix is a price list. What it changes, and what it
%       cannot change.
%
%  B 의 둘째 줄이 [0 1 0 1 0 -1 0 -1] 이므로 Y 는 f_y 열만이 낸다. 따라서
%  sum|f_y| 는 요구가 정한 값에 묶여 있고, f_y 를 비싸게 매겨도 줄지 않는다.
%  Row 2 of B is [0 1 0 1 0 -1 0 -1], so Y comes from the f_y columns alone.
%  The sum of |f_y| is pinned by the demand and pricing f_y dearly cannot
%  reduce it; what the price list moves is which unit pays.
tau_d = [80; 30; 20];
wlist = [1 3 10 30 100 300 1000];

fprintf('\n=== 12-9  the weight matrix W ===\n');
fprintf('demand tau_d = [%.0f N, %.0f N, %.0f N m],  W = diag([1 w 1 w 1 w 1 w])\n', tau_d);
fprintf('Y comes from the f_y columns alone (row 2 of B = [%s]) -> sum|f_y| is pinned\n\n', ...
        strtrim(sprintf('%g ', B(2,:))));
fprintf('       w   sum|f_y| [N]   f_x spread [N]   max|delta| [deg]   ||f|| [N]   ||B f - tau||\n');

md = zeros(size(wlist));  nf = md;  sf = md;  sp = md;
for j = 1:numel(wlist)
    f  = W12_alloc(B, tau_d, 'wpinv', struct('W', diag(repmat([1 wlist(j)], 1, 4))));
    H  = W12_hw(B, f, cfg);
    fx = f(1:2:end);  fy = f(2:2:end);
    md(j) = max(abs(rad2deg(H.delta)));
    nf(j) = norm(f);
    sf(j) = sum(abs(fy));
    sp(j) = max(abs(fx)) - min(abs(fx));   % f_x 의 쏠림 / how skewed f_x is
    fprintf('  %6g %13.2f %16.2f %18.2f %12.2f %15.1e\n', ...
            wlist(j), sf(j), sp(j), md(j), nf(j), norm(B*f - tau_d));
end

% W 를 통째로 키워도 해가 같다 — 비율만이 뜻을 가진다
% scaling the whole of W changes nothing: only the ratios carry meaning
f_a = W12_alloc(B, tau_d, 'wpinv', struct('W', diag(repmat([1 10],1,4))));
f_b = W12_alloc(B, tau_d, 'wpinv', struct('W', 1000*diag(repmat([1 10],1,4))));
fprintf('\ndistance between the W and 1000*W solutions : %.2e N   (only ratios matter)\n', ...
        norm(f_a - f_b));

% 값표가 실제로 바꾸는 것 — 어느 추진기가 몫을 지는가
% what the price list does change: which unit carries the share
f2   = W12_alloc(B, tau_d, 'wpinv', struct('W', diag([1 10 1 10 5 50 5 50])));
H2   = W12_hw(B, f2, cfg);
H1   = W12_hw(B, f_a, cfg);
shr1 = 100*sum(abs(H1.T(3:4)))/sum(abs(H1.T));
shr2 = 100*sum(abs(H2.T(3:4)))/sum(abs(H2.T));
fprintf('\nwhat the price list can change: who carries the share\n');
fprintf('  same price fore and aft : |T| = [%6.2f %6.2f %6.2f %6.2f] N   aft pair %.1f %%\n', ...
        abs(H1.T), shr1);
fprintf('  aft priced 5x dearer    : |T| = [%6.2f %6.2f %6.2f %6.2f] N   aft pair %.1f %%\n', ...
        abs(H2.T), shr2);
fprintf('\nwhat the price list cannot change: what the demand has already fixed\n');
fprintf('  sum|f_y| : %.2f N and %.2f N  (Y = %.0f N fixes it)\n', ...
        sum(abs(f_a(2:2:end))), sum(abs(f2(2:2:end))), tau_d(2));

W12_plot_weights(cfg, wlist, sf, sp, md, H1, H2, shr1, shr2, here);
end

% ========================================================================= %
function sec10(B, cfg, P, here)
%SEC10  12-10 — 서보 각 한계. 닫힌형 해가 그 한계를 넘을 때 무엇을 할 것인가.
%       12-10: the servo-angle limit, and what to do when the closed-form
%       solution exceeds it.
amax     = rad2deg(P.alpha_max);
tau_hard = [15; 70; 10];              % 한계 밖의 요구 / a demand outside the limit

fprintf('\n=== 12-10  the servo-angle limit ===\n');
fprintf('a demand that exceeds it,  tau = [%.0f N, %.0f N, %.0f N m]\n', tau_hard);
fprintf('  (the sideways force is larger than the forward one -> the angle grows)\n\n');
fprintf('  method       max|delta| [deg]   ||B f - tau|| [N]   ||f|| [N]   QPs   exit\n');
for m = ["wpinv" "clip" "qp" "wls" "wls16"]
    [f, in] = W12_alloc(B, tau_hard, char(m), P);
    H = W12_hw(B, f, cfg);
    fprintf('  %-10s %13.2f %18.3f %12.2f %6d %6d\n', m, ...
            max(abs(rad2deg(H.delta))), norm(H.tau - tau_hard), norm(f), ...
            in.ntried, in.exit);
end

% 추력 부호를 고정하면 각 한계가 직선 둘이 되어 QP 하나가 된다. 부호 조합이
% 열여섯 가지이므로 하나만 푸는 'qp' 는 틀릴 수 있고, 'wls16' 은 열여섯을
% 모두 풀어 가장 싼 것을 남긴다
% Fixing the thrust signs turns the angle limit into two straight lines, so the
% problem becomes one QP. There are sixteen sign combinations: 'qp' solves the
% one the closed form suggests, 'wls16' solves all sixteen and keeps the best
[~, i1] = W12_alloc(B, tau_hard, 'qp',    P);
[~, i2] = W12_alloc(B, tau_hard, 'wls16', P);
fprintf('\nsign combination from the closed form  sigma = [%2d %2d %2d %2d]  -> quadprog exit %d\n', ...
        i1.sigma, i1.exit);
fprintf('best of the sixteen combinations       sigma = [%2d %2d %2d %2d]  -> cost %.4f\n', ...
        i2.sigma, i2.cost);
fprintf('  -> the demand is feasible, but not with the sign combination the\n');
fprintf('     weighted minimum norm produced\n');

% 같은 법칙들을 요구 궤적 하나에 걸어 본다 / the same laws over one trajectory
S = W12_sweep_laws(B, cfg, P);
W12_plot_limits(S, amax, here);
end

% ========================================================================= %
function sec11(B, P)
%SEC11  12-11 — 한 번 푸는 데 걸리는 시간. 50 Hz 예산 안에 드는 것은 어느 것인가.
%       12-11: the time one solve takes, and which laws fit the 50 Hz budget.
t      = linspace(0, 20, 101);
tau    = [100*sin(0.5*t); 60*cos(0.3*t); 30*sin(0.7*t)];
mth    = ["pinv" "wpinv" "clip" "qp" "wls" "wls16" "fmincon"];
budget = 20000;                            % 50 Hz = 20 ms = 20000 us

for a = 1:numel(mth)                       % 첫 호출은 느리다 — 미리 한 번 돌린다
    W12_alloc(B, tau(:,1), char(mth(a)), P);   % warm-up: the first call is slow
end

fprintf('\n=== 12-11  the time one solve takes ===\n');
fprintf('%d demands allocated one after another.  the 50 Hz budget is %d us\n\n', ...
        numel(t), budget);
fprintf('  method       QPs   mean [us]   max [us]   x pinv   budget used [%%]\n');

base = NaN;
for a = 1:numel(mth)
    e = zeros(1, numel(t));  nq = 0;
    for k = 1:numel(t)
        c = tic;  [~, in] = W12_alloc(B, tau(:,k), char(mth(a)), P);  e(k) = toc(c);
        nq = in.ntried;
    end
    mu = 1e6*mean(e);  mx = 1e6*max(e);
    if a == 1, base = mu; end
    fprintf('  %-10s %5d %11.1f %10.1f %8.0f %17.2f\n', ...
            mth(a), nq, mu, mx, mu/base, 100*mu/budget);
end

% 닫힌형이 빠른 이유 — B 가 상수이므로 8x3 행렬을 한 번만 만들면 된다
% why the closed form is fast: B is constant, so the 8x3 matrix is built once
Wi = P.W \ eye(8);
Kw = Wi * B.' / (B*Wi*B.');
e  = zeros(1, numel(t));
for k = 1:numel(t), c = tic; f = Kw*tau(:,k); e(k) = toc(c); end  %#ok<NASGU>
fprintf('\n  with one 8x3 matrix prepared in advance : %.2f us  (24 multiplies)\n', ...
        1e6*mean(e));
fprintf('  distance between Kw*tau and wpinv       : %.2e N\n', ...
        norm(Kw*tau(:,end) - W12_alloc(B, tau(:,end), 'wpinv', P)));
end

% ========================================================================= %
function sec12(B, cfg, P, here)
%SEC12  12-12 — 한계가 둘이다. 서보 각과 회전수. 받은 힘은 운동모델에서 잰다.
%       12-12: there are two limits, the servo angle and the shaft speed. The
%       force the hull received is measured out of the motion model.
V = W12_vars;

% |n| <= n_max 는 T = k n|n| 을 지나 추력 한계가 된다. 전진과 후진의 k 가
% 다르므로 한계의 높이도 둘이다
% |n| <= n_max becomes a thrust limit through T = k n|n|; k differs ahead and
% astern, so the two limits have different heights
P.T_pos   = cfg.k_pos * cfg.n_max^2;
P.T_neg   = cfg.k_neg * cfg.n_min^2;
P.n_chord = 3;

fprintf('\n=== 12-12  two limits: the servo angle and the shaft speed ===\n\n');
fprintf('  the shaft speed limits are n_max = %+8.2f and n_min = %+8.2f rad/s\n', ...
        cfg.n_max, cfg.n_min);
fprintf('  through T = k n|n| those become thrust limits\n');
fprintf('      ahead   T <= k_pos n_max^2 = %.3f * %.2f^2 = %8.3f N\n', ...
        cfg.k_pos, cfg.n_max, P.T_pos);
fprintf('      astern  T <= k_neg n_min^2 = %.3f * %.2f^2 = %8.3f N\n', ...
        cfg.k_neg, abs(cfg.n_min), P.T_neg);
fprintf('  the astern limit is %.0f%% of the ahead limit, and that is what binds\n', ...
        100*P.T_neg/P.T_pos);
fprintf('  at delta = 0 the hull can therefore make at most\n');
fprintf('      X = 2 * %.2f + 2 * %.2f = %.2f N\n', ...
        P.T_pos, P.T_neg, 2*P.T_pos + 2*P.T_neg);

% 법칙 넷을 요구에서 선체까지 따라간다 / four laws, followed from demand to hull
RR = W12_tab_chain(B, cfg, V, P, ["wpinv" "clip" "wls16" "wls16cap"]);
W12_plot_chain(RR, cfg, here);
end
