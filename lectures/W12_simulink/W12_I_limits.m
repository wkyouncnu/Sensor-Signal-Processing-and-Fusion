%W12_I_LIMITS  강의 §12-10 — 서보 벽. 닫힌형이 벽을 넘을 때 무엇을 할 것인가.
%  법칙 여섯을 같은 요구에 걸어 벽 위반·tau 오차·해가 있는지를 잰다.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
cfg = otter_config('quad_tilt');
B   = cfg.B;

P.W         = diag(repmat([1 10], 1, 4));
P.alpha_max = cfg.alpha_max(1);
P.Q         = eye(3);
P.eps_reg   = 1e-4;
amax        = rad2deg(P.alpha_max);

%% 벽을 확실히 넘기는 요구 하나 ------------------------------------------------
tau_hard = [15; 70; 10];
fprintf('\n=== §12-10  서보 벽 ===\n');
fprintf('벽을 넘기는 요구  tau = [%.0f N, %.0f N, %.0f Nm]\n', tau_hard);
fprintf('  (옆으로 미는 힘이 앞으로 가는 힘보다 크다 -> 각이 커진다)\n\n');
fprintf('  method       max|delta| [deg]   ||B f - tau|| [N]   ||f|| [N]   QPs   exit\n');
for m = ["wpinv" "clip" "qp" "wls" "wls16"]
    [f, in] = W12_alloc(B, tau_hard, char(m), P);
    H = W12_hw(B, f, cfg);
    fprintf('  %-10s %13.2f %18.3f %12.2f %6d %6d\n', m, ...
            max(abs(rad2deg(H.delta))), norm(H.tau - tau_hard), norm(f), ...
            in.ntried, in.exit);
end

%% 짐작한 조각이 왜 틀릴 수 있는가 — 열여섯 조각을 직접 들여다본다 -------------
[~, i1] = W12_alloc(B, tau_hard, 'qp',    P);
[~, i2] = W12_alloc(B, tau_hard, 'wls16', P);
fprintf('\n짐작한 조각  sigma = [%2d %2d %2d %2d]  -> quadprog exit %d\n', ...
        i1.sigma, i1.exit);
fprintf('열여섯 중 최선 sigma = [%2d %2d %2d %2d]  -> 비용 %.4f\n', ...
        i2.sigma, i2.cost);
fprintf('  -> 이 요구는 **풀 수 있다.** 다만 가중 최소노름이 가리킨 조각에서는 아니다\n');

%% 요구 궤적 하나에 전부 걸어 본다 — 쓸기와 표는 `W12_sweep_laws` ---------------
S = W12_sweep_laws(B, cfg, P);

%% 그림 — 벽과 그 대가. 그리는 것은 `W12_plot_limits`
W12_plot_limits(S, amax, fileparts(mfilename('fullpath')));
