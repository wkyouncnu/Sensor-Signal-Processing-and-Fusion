%W12_G_ALLOCATION  강의 §12-7 · §12-8 — 배분 문제와 최소노름 해.
%  무엇을 찍는가: 해가 무한히 많다는 것(영공간), 최소노름 해 하나, 그것이
%  실제로 하드웨어가 받는 여덟 숫자로 어떻게 바뀌는가, 그리고 서보 벽 검사.
%  그림 하나: 평면도 위의 네 추력 화살표.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
cfg = otter_config('quad_tilt');
B   = cfg.B;

fprintf('\n=== §12-7  배분 문제 ===\n');
fprintf('B 는 %dx%d,  rank %d,  영공간 차원 %d\n', ...
        size(B,1), size(B,2), rank(B), size(B,2)-rank(B));

tau_d = [80; 30; 20];
fprintf('\n요구  tau_d = [%.0f N, %.0f N, %.0f Nm]\n', tau_d);

%% (1) 해가 하나가 아니다 — 영공간 벡터를 더해도 같은 tau 가 나온다
f0 = W12_alloc(B, tau_d, 'pinv');
Z  = null(B);                                   % 8x5
f1 = f0 + 40*Z(:,1);                            % 다른 해 하나
fprintf('\n(1) 같은 tau 를 내는 해 둘\n');
fprintf('    최소노름  ||f|| = %7.2f N   ||B f - tau|| = %.2e\n', ...
        norm(f0), norm(B*f0 - tau_d));
fprintf('    영공간 더한 것    %7.2f N   %21.2e\n', ...
        norm(f1), norm(B*f1 - tau_d));
fprintf('    -> 같은 힘을 내면서 추진기는 %.0f %% 더 쓴다\n', ...
        100*(norm(f1)/norm(f0) - 1));

%% (2) 최소노름 해, 성분별
fprintf('\n(2) 최소노름 해  f = B^T (B B^T)^{-1} tau\n');
fprintf('    unit      f_x [N]   f_y [N]\n');
for i = 1:4
    fprintf('     %d      %9.3f %9.3f\n', i, f0(2*i-1), f0(2*i));
end

%% (3) 하드웨어가 받는 여덟 숫자
H = W12_hw(B, f0, cfg);
fprintf('\n(3) 하드웨어 명령\n');
fprintf('    unit     T [N]   delta [deg]    n [rad/s]   |delta|<=45?\n');
for i = 1:4
    fprintf('     %d    %8.3f %11.2f %12.2f        %s\n', i, H.T(i), ...
        rad2deg(H.delta(i)), H.n(i), ...
        string(abs(H.delta(i)) <= cfg.alpha_max(i)+1e-9));
end
fprintf('    rho = %.4f   (1 이면 추력 한계에 걸리지 않았다)\n', H.rho);
fprintf('    실제 tau = [%.3f %.3f %.3f]   요구와의 차이 %.2e\n', ...
        H.tau, norm(H.tau - tau_d));

%% (4) 그림 — 평면도 위의 네 추력. 그리는 것은 `W12_plot_alloc`
W12_plot_alloc(cfg, H, tau_d, fileparts(mfilename('fullpath')));
