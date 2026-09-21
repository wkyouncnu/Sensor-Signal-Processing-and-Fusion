%% W03 · 절 G — 2주차의 튜닝 순서를 Otter 에 / Section G — the Week 2 tuning order on the Otter
%  모델 없이 측정만으로: 요구 → P → (D?) → I → 힘. 목표: 1.5 m/s 의 2 % 안에 3 s 안, 오버슛 5 % 미만.
%  Model-free, measurement only: requirement -> P -> (D?) -> I -> force.
%  Target: inside 2 % of 1.5 m/s within 3 s of the step, overshoot below 5 %.
%  만드는 것 / produces: img/W03_result_tuning.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
M = @(R) deal_metrics(R);

fprintf('\n  W03 G  the tuning order on the Otter\n');
R = W03_read('W03_G_tuning', 'Ki', 0, 'Kb', 0);                % P 만 / P only
[Mp, ~, tr] = step_metrics(R.t, R.u, R.u(end), 5);
fprintf('    1-2  Kp = 200: overshoot %.1f %%, rise %.2f s, error left %.3f m/s\n', max(Mp,0), tr, 1.5 - R.u(end));
fprintf('    3    no ringing, so nothing for D to damp: Kd = 0 (section E: D only adds overshoot)\n');
fprintf('    4    Ki = ');
for Ki = [50 100 200]
    R = W03_read('W03_G_tuning', 'Ki', Ki);  [Mp, ts] = M(R);
    fprintf('%g: %.2f s (%.1f %%)   ', Ki, ts, Mp);
    if ts <= 3 && Mp < 5, break; end
end
fprintf('-> Ki = %g\n', Ki);
A = W03_read('W03_G_tuning');                                  % Kb = 1
B = W03_read('W03_G_tuning', 'ref_filter', 1);
[MpA, tsA] = M(A);  [MpB, tsB] = M(B);
fprintf('    5    force: %.1f N, on the thrust limit for %.2f s (anti-windup on); smoothed command: %.1f N, settle %.2f s\n', ...
        max(A.X), sum(A.X >= A.V.X_hi - 1e-6)*A.V.h, max(B.X), tsB);
fprintf('         final: Kp = 200, Ki = 200, Kd = 0, Kb = 1: overshoot %.2f %%, inside 2 %% after %.2f s\n', MpA, tsA);

f = lab_fig('W03 G  tuning', 1000, 620);
subplot(2,1,1); hold on; grid on;
plot(A.t, A.u, 'LineWidth', 2);  plot(B.t, B.u, 'LineWidth', 2);  plot(A.t, A.u_d, 'k--');
xlim([3 15]); ylabel('u [m/s]'); legend({'step command','smoothed command','command'}, 'Location','southeast');
title('the tuned loop: K_p = 200, K_i = 200, K_d = 0, K_b = 1');
subplot(2,1,2); hold on; grid on;
plot(A.t, A.X, 'LineWidth', 2);  plot(B.t, B.X, 'LineWidth', 2);  yline(A.V.X_hi, 'r:');
xlim([3 15]); ylabel('thrust X [N]'); xlabel('time [s]'); title('the step touches the thrust limit; the smoothed command never does');
exportgraphics(f, fullfile(here, 'img', 'W03_result_tuning.png'), 'Resolution', 150);

function [Mp, ts, tr] = deal_metrics(R)
[Mp, ts, tr] = step_metrics(R.t, R.u, 1.5, 5);
Mp = max(Mp, 0);
if abs(R.u(end) - 1.5) > 0.03, ts = Inf; end                    % 1.5 에 못 닿음 / never reaches 1.5
end
