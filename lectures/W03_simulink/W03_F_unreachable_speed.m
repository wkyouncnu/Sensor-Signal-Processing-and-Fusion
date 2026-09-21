%% W03 · 절 F — 닿을 수 없는 속도 / Section F — an unreachable speed
%  W03_F_windup: 5 s 에 3.5 m/s (Otter 는 약 3.1 m/s 가 최대), 30 s 에 1.5 m/s. 되감기 이득 Kb 를 바꾼다.
%  W03_F_windup: 3.5 m/s at 5 s (the Otter tops out near 3.1 m/s), 1.5 m/s at 30 s; Kb varies.
%  만드는 것 / produces: img/W03_result_windup.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
S = {'u_step', 3.5, 't_step2', 30, 'u_step2', 1.5, 'T_final', 60};

fprintf('\n  W03 F  3.5 m/s from 5 s (unreachable), 1.5 m/s from 30 s\n');
fprintf('    Kb     u at 30 s   I at 30 s [N]   back within 2 %% of 1.5 m/s after [s]   lowest u [m/s]\n');
f = lab_fig('W03 F  windup', 1000, 620);
for Kb = [0 0.2 1 5]
    R = W03_read('W03_F_windup', S{:}, 'Kb', Kb);
    k = R.t >= 30;  t = R.t(k) - 30;  u = R.u(k);
    back = t(find(abs(u - 1.5) > 0.03, 1, 'last'));
    fprintf('    %-5g  %9.3f   %13.1f   %37.2f   %14.3f\n', Kb, interp1(R.t, R.u, 30), ...
            interp1(R.t, R.I, 30), back, min(u));
    subplot(2,1,1); hold on; plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_b = %g', Kb));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_b = %g', Kb));
end
subplot(2,1,1); plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); grid on;
ylabel('u [m/s]'); legend('Location','northeast'); title('the same thrust, the same top speed; what differs is the return');
subplot(2,1,2); grid on; ylabel('I [N]'); xlabel('time [s]');
title('without anti-windup (K_b = 0) the integral piles up thousands of newtons');
exportgraphics(f, fullfile(here, 'img', 'W03_result_windup.png'), 'Resolution', 150);
