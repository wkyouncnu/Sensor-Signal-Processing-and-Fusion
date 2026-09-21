%% W03 · 절 C — 플랜트를 밖에서 본다 / Section C — the plant seen from outside
%  모델 W03_C_open_loop 에 힘 50, 100, 200 N 을 계단으로 주고, 최종 속도와 63 % 시각을 잰다.
%  Applies 50, 100 and 200 N to W03_C_open_loop and measures the final speed and the time to 63 %.
%  만드는 것 / produces: img/W03_result_open_loop.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W03 C  the plant seen from outside (no controller)\n');
fprintf('    X [N]   final u [m/s]   u per newton [(m/s)/N]   time to 63 %% [s]\n');
f = lab_fig('W03 C  open loop', 1000, 480);  hold on; grid on;
for X = [50 100 200]
    R = W03_read('W03_C_open_loop', 'X_open', X);
    k = R.t >= 5;  t = R.t(k) - 5;  u = R.u(k);
    t63 = t(find(u >= 0.632*u(end), 1));
    fprintf('    %-5g   %13.3f   %22.5f   %16.2f\n', X, u(end), u(end)/X, t63);
    plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('X = %g N', X));
end
xlabel('time [s]'); ylabel('surge speed u [m/s]'); legend('Location','southeast');
title('a step force from t = 5 s: the speed rises without overshoot and levels off');
exportgraphics(f, fullfile(here, 'img', 'W03_result_open_loop.png'), 'Resolution', 150);
