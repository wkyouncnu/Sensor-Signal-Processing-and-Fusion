%W12_I_LIMITS  강의 §12-10 — 서보 벽. 닫힌형이 벽을 넘을 때 무엇을 할 것인가.
%              Lecture 12-10: the servo wall, and what to do when the closed
%              form walks through it.
%
%  법칙 다섯을 같은 요구에 걸어 **벽 위반 · tau 오차 · 해가 있는지**를 잰다.
%  Five laws are put to the same demand, and the wall violation, the tau error
%  and whether a solution exists at all are measured.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
cfg = otter_config('quad_tilt');
B   = cfg.B;

P.W         = diag(repmat([1 10], 1, 4));
P.alpha_max = cfg.alpha_max(1);
P.Q         = eye(3);
P.eps_reg   = 1e-4;
amax        = rad2deg(P.alpha_max);

%% 벽을 확실히 넘기는 요구 하나 / one demand that certainly breaks the wall ----
tau_hard = [15; 70; 10];
fprintf('\n=== 12-10  the servo wall ===\n');
fprintf('a demand that breaks it,  tau = [%.0f N, %.0f N, %.0f N m]\n', tau_hard);
fprintf('  (the sideways force is larger than the forward one -> the angle grows)\n\n');
fprintf('  method       max|delta| [deg]   ||B f - tau|| [N]   ||f|| [N]   QPs   exit\n');
for m = ["wpinv" "clip" "qp" "wls" "wls16"]
    [f, in] = W12_alloc(B, tau_hard, char(m), P);
    H = W12_hw(B, f, cfg);
    fprintf('  %-10s %13.2f %18.3f %12.2f %6d %6d\n', m, ...
            max(abs(rad2deg(H.delta))), norm(H.tau - tau_hard), norm(f), ...
            in.ntried, in.exit);
end

%% 짐작한 조각이 왜 틀릴 수 있는가 / why the guessed piece can be the wrong one
%  열여섯 조각을 직접 들여다본다 / the sixteen pieces, looked at one by one
[~, i1] = W12_alloc(B, tau_hard, 'qp',    P);
[~, i2] = W12_alloc(B, tau_hard, 'wls16', P);
fprintf('\nthe guessed piece  sigma = [%2d %2d %2d %2d]  -> quadprog exit %d\n', ...
        i1.sigma, i1.exit);
fprintf('the best of sixteen  sigma = [%2d %2d %2d %2d]  -> cost %.4f\n', ...
        i2.sigma, i2.cost);
fprintf('  -> this demand CAN be met, only not on the piece the weighted\n');
fprintf('     minimum norm pointed at\n');

%% 요구 궤적 하나에 전부 걸어 본다 / the same laws over one demand trajectory
%  쓸기와 표는 `W12_sweep_laws` / the sweep and its table live in W12_sweep_laws
S = W12_sweep_laws(B, cfg, P);

%% 그림 — 벽과 그 대가 / the wall and what it costs. 그리는 것은 `W12_plot_limits`
W12_plot_limits(S, amax, fileparts(mfilename('fullpath')));
