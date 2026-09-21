%% W04 · 절 C — 플랜트를 밖에서 본다 / Section C — the plant seen from outside
%  W04_C_open_loop 에 요 모멘트 5, 10, 20 N m 를 계단으로 주고, 요각속도와 선수각을 본다.
%  Applies 5, 10 and 20 N m of yaw moment to W04_C_open_loop: the turn rate and the heading.
%  만드는 것 / produces: img/W04_result_open_loop.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W04 C  the plant seen from outside (no controller, X_ff = 60 N ahead)\n');
fprintf('    N [N m]   final turn rate [deg/s]   rate per N m   time to 63 %% of the rate [s]   heading at 40 s [deg]\n');
f = lab_fig('W04 C  open loop', 1000, 620);
for N = [5 10 20]
    R = W04_read('W04_C_open_loop', 'N_open', N);
    r = gradient(R.psi, R.t);                          % 요각속도 / turn rate  [deg/s]
    k = R.t >= 5;  t = R.t(k) - 5;  rk = r(k);
    fprintf('    %-7g   %23.2f   %12.3f   %28.2f   %21.1f\n', N, rk(end), rk(end)/N, ...
            t(find(rk >= 0.632*rk(end), 1)), R.psi(end));
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('N = %g N m', N));
    subplot(2,1,2); hold on; plot(R.t, r, 'LineWidth', 2, 'DisplayName', sprintf('N = %g N m', N));
end
subplot(2,1,1); grid on; ylabel('heading \psi [deg]'); legend('Location','northwest');
title('a constant yaw moment: the heading never stops growing');
subplot(2,1,2); grid on; ylabel('turn rate [deg/s]'); xlabel('time [s]');
title('the turn rate levels off within a few seconds: the heading is its running sum');
exportgraphics(f, fullfile(here, 'img', 'W04_result_open_loop.png'), 'Resolution', 150);
