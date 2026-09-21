%% W04 · 절 H — 튜닝 순서, 그리고 큰 선회 / Section H — the tuning order, and a big turn
%  모델 없이 측정만으로: 요구 → P → D → I → 모멘트 한계와 되감기(Kb).
%  Model-free: requirement -> P -> D -> I -> the moment limit and back-calculation (Kb).
%  1~4 단계는 Kb = 0 (되감기 없이) 으로 잰다 — 3주차에서 본 것처럼, Ki = 0 인데 Kb 가
%  살아 있으면 되감기가 적분을 혼자 움직인다.
%  Steps 1 to 4 run with Kb = 0: with Ki = 0 and Kb on, back-calculation alone
%  would move the integral (as in Week 3).
%  만드는 것 / produces: img/W04_result_tuning.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
m = 'W04_H_tuning';
M = @(R, target) metrics(R, target);

fprintf('\n  W04 H  the tuning order on the heading\n');
[Mp, ts] = M(W04_read(m, 'Kd', 0, 'Ki', 0, 'Kb', 0), 10);
fprintf('    1-2  Kp = 300 (10 deg asks 52 N m of the 70.8 available): overshoot %.1f %%, settle %.2f s: it rings, so D\n', Mp, ts);
fprintf('    3    Kd = ');
for Kd = [25 50 100 150]
    [Mp, ts] = M(W04_read(m, 'Kd', Kd, 'Ki', 0, 'Kb', 0), 10);
    fprintf('%g: %.2f %%, %.2f s   ', Kd, Mp, ts);
end
fprintf('-> Kd = 100 (fastest settling)\n');
R = W04_read(m, 'Ki', 0, 'Kb', 0, 'port_eff', 0.7);
fprintf('    4    weak port propeller (0.7): PD leaves %.2f deg;', 10 - R.psi(end));
R = W04_read(m, 'Kb', 0, 'port_eff', 0.7);  [Mp, ts] = M(R, 10);
fprintf(' Ki = 20 removes it: %.3f deg left, settle %.2f s\n', 10 - R.psi(end), ts);

fprintf('    5    the moment limit: Kb against three turns (settle [s], overshoot %%)\n');
fprintf('         Kb      10 deg turn        weak propeller     90 deg turn\n');
f = lab_fig('W04 H  tuning', 1000, 620);
for Kb = [0 0.05 0.1 1]
    [M1, t1] = M(W04_read(m, 'Kb', Kb), 10);
    [M2, t2] = M(W04_read(m, 'Kb', Kb, 'port_eff', 0.7), 10);
    R = W04_read(m, 'Kb', Kb, 'psi_step', 90, 'T_final', 60);  [M3, t3] = M(R, 90);
    fprintf('         %-6g  %5.2f s  %5.2f %%   %5.2f s  %5.2f %%   %5.2f s  %5.2f %%\n', Kb, t1, M1, t2, M2, t3, M3);
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_b = %g', Kb));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_b = %g', Kb));
end
[Mp, ts] = M(W04_read(m, 'psi_step', 90, 'Ki', 0, 'Kb', 0, 'T_final', 60), 90);
fprintf('         PD alone, 90 deg turn: %.2f s, %.2f %%\n', ts, Mp);
fprintf('         final: Kp = 300, Kd = 100, Ki = 20, Kb = 0.1\n');
subplot(2,1,1); yline(90, 'k--', 'HandleVisibility','off'); grid on; xlim([0 50]);
ylabel('\psi [deg]'); legend('Location','southeast'); title('a 90 deg turn: too little K_b overshoots, too much stalls short');
subplot(2,1,2); grid on; xlim([0 50]); ylabel('I [N m]'); xlabel('time [s]');
title('the integral: piled up (K_b = 0) or dragged far below zero (K_b = 1)');
exportgraphics(f, fullfile(here, 'img', 'W04_result_tuning.png'), 'Resolution', 150);

function [Mp, ts] = metrics(R, target)
[Mp, ts] = step_metrics(R.t, R.psi, target, 5);
Mp = max(Mp, 0);
end
