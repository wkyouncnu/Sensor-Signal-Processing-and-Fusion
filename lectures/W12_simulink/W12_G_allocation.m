%W12_G_ALLOCATION  강의 §12-7 · §12-8 — 배분 문제와 최소노름 해.
%                  Lecture 12-7 and 12-8: the allocation problem, and the
%                  minimum-norm solution.
%
%  무엇을 찍는가 / what this prints
%      ① 해가 무한히 많다는 것 — 영공간 / there is an infinity of solutions
%      ② 최소노름 해 하나        / the one minimum-norm solution
%      ③ 그것이 하드웨어가 받는 여덟 숫자로 어떻게 바뀌는가, 서보 벽 검사
%         how that becomes the eight numbers the hardware receives, and the
%         servo-wall check
%
%  그림 하나: 평면도 위의 네 추력 화살표 / one figure: four thrust arrows

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
cfg = otter_config('quad_tilt');
B   = cfg.B;

fprintf('\n=== 12-7  the allocation problem ===\n');
fprintf('B is %dx%d,  rank %d,  null space dimension %d\n', ...
        size(B,1), size(B,2), rank(B), size(B,2)-rank(B));

tau_d = [80; 30; 20];
fprintf('\ndemand  tau_d = [%.0f N, %.0f N, %.0f N m]\n', tau_d);

%% (1) 해가 하나가 아니다 / there is more than one solution
%     영공간 벡터를 더해도 같은 tau 가 나온다
%     adding a null-space vector leaves tau unchanged
f0 = W12_alloc(B, tau_d, 'pinv');
Z  = null(B);                                   % 8x5
f1 = f0 + 40*Z(:,1);                            % 다른 해 하나 / another solution
fprintf('\n(1) two solutions that give the same tau\n');
fprintf('    minimum norm      ||f|| = %7.2f N   ||B f - tau|| = %.2e\n', ...
        norm(f0), norm(B*f0 - tau_d));
fprintf('    null space added        %7.2f N   %21.2e\n', ...
        norm(f1), norm(B*f1 - tau_d));
fprintf('    -> the same force costs the thrusters %.0f %% more\n', ...
        100*(norm(f1)/norm(f0) - 1));

%% (2) 최소노름 해, 성분별 / the minimum-norm solution, component by component
fprintf('\n(2) minimum norm  f = B^T (B B^T)^{-1} tau\n');
fprintf('    unit      f_x [N]   f_y [N]\n');
for i = 1:4
    fprintf('     %d      %9.3f %9.3f\n', i, f0(2*i-1), f0(2*i));
end

%% (3) 하드웨어가 받는 여덟 숫자 / the eight numbers the hardware receives
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

%% (4) 그림 — 평면도 위의 네 추력 / the four thrusts, seen from above
%     그리는 것은 `W12_plot_alloc` / drawn by W12_plot_alloc
W12_plot_alloc(cfg, H, tau_d, fileparts(mfilename('fullpath')));
