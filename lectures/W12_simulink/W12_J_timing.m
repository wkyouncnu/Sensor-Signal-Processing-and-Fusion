%W12_J_TIMING  강의 §12-11 — 50 Hz 안에 드는 것은 어느 것인가.
%  같은 요구 궤적에 법칙 일곱을 걸어 **한 번 푸는 데 걸리는 시간**을 잰다.
%  참조 코드의 fmincon 꼴도 같이 재서, 같은 제약을 직선으로 쓰면 얼마나
%  빨라지는지를 숫자로 둔다. 조각 열여섯을 다 푸는 값도 재야 한다 — 그것이
%  §12-10 이 고른 법칙이기 때문이다.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
cfg = otter_config('quad_tilt');
B   = cfg.B;

P.W         = diag(repmat([1 10], 1, 4));
P.alpha_max = cfg.alpha_max(1);
P.Q         = eye(3);
P.eps_reg   = 1e-4;

t      = linspace(0, 20, 101);
tau    = [100*sin(0.5*t); 60*cos(0.3*t); 30*sin(0.7*t)];
mth    = ["pinv" "wpinv" "clip" "qp" "wls" "wls16" "fmincon"];
budget = 20000;                            % 50 Hz = 20 ms = 20000 us

for a = 1:numel(mth)                       % 한 번 돌려 둔다 — 첫 호출은 느리다
    W12_alloc(B, tau(:,1), char(mth(a)), P);
end

fprintf('\n=== §12-11  한 번 푸는 데 걸리는 시간 ===\n');
fprintf('%d 개 요구를 차례로 배분.  50 Hz 예산 = %d us\n\n', numel(t), budget);
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

%% 닫힌형은 왜 빠른가 — B 가 상수이므로 역행렬을 한 번만 만든다
Wi  = P.W \ eye(8);
Kw  = Wi * B' / (B*Wi*B');                 % 8x3, **한 번** 계산해 두는 것
e = zeros(1, numel(t));
for k = 1:numel(t), c = tic; f = Kw*tau(:,k); e(k) = toc(c); end
fprintf('\n  미리 만든 8x3 행렬 하나로 : %.2f us  (곱셈 24 번)\n', 1e6*mean(e));
fprintf('  Kw*tau 와 wpinv 의 차이    : %.2e N\n', ...
        norm(Kw*tau(:,end) - W12_alloc(B, tau(:,end), 'wpinv', P)));
