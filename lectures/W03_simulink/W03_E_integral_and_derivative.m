%% W03 · 절 E — I 를 더하고, D 를 시험한다 / Section E — add I, then try D
%  모델 W03_E_PID 에서 Kp = 200 으로 두고 Ki 를, 그다음 Ki = 200 으로 두고 Kd 를 바꾼다.
%  On W03_E_PID with Kp = 200: vary Ki; then, with Ki = 200, vary Kd.
%  만드는 것 / produces: img/W03_result_I.png, img/W03_result_D.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W03 E  1) the integral  (Kp = 200, Kd = 0)\n');
fprintf('    Ki    u at 40 s   overshoot %%   settle [s]   I at 40 s [N]\n');
f = lab_fig('W03 E  integral', 1000, 620);
for Ki = [0 50 100 200 400]
    R = W03_read('W03_E_PID', 'Ki', Ki);
    [Mp, ts] = step_metrics(R.t, R.u, 1.5, 5);
    if Ki == 0, ts = Inf; end                       % 1.5 에 닿지 않는다 / never reaches 1.5
    fprintf('    %-4g  %9.4f   %11.1f   %10.2f   %13.1f\n', Ki, R.u(end), max(Mp,0), ts, R.I(end));
    subplot(2,1,1); hold on; plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_i = %g', Ki));
end
subplot(2,1,1); plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); xlim([0 25]); grid on;
ylabel('u [m/s]'); legend('Location','southeast'); title('the integral removes the error; too much of it overshoots');
subplot(2,1,2); xlim([0 25]); grid on; ylabel('I [N]'); xlabel('time [s]');
title('every integral stops at the same force: the drag at 1.5 m/s');
exportgraphics(f, fullfile(here, 'img', 'W03_result_I.png'), 'Resolution', 150);

fprintf('\n  2) the derivative  (Kp = 200, Ki = 200)\n');
fprintf('    Kd    overshoot %%   rise [s]   settle [s]\n');
f = lab_fig('W03 E  derivative', 1000, 420);  hold on; grid on;
for Kd = [0 20 50 100]
    R = W03_read('W03_E_PID', 'Kd', Kd);
    [Mp, ts, tr] = step_metrics(R.t, R.u, 1.5, 5);
    fprintf('    %-4g  %11.2f   %8.2f   %10.2f\n', Kd, max(Mp,0), tr, ts);
    plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_d = %g', Kd));
end
plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); xlim([3 15]);
ylabel('u [m/s]'); xlabel('time [s]'); legend('Location','southeast');
title('on a speed loop D makes it worse: more overshoot and slower');
exportgraphics(f, fullfile(here, 'img', 'W03_result_D.png'), 'Resolution', 150);
