%% W04 · 절 F — 좌현 프로펠러가 약할 때 / Section F — a weak port propeller
%  W04_F_PID: 먼저 PD (Ki = 0) 로 효율 1, 0.7, 0.5 를 보고, 효율 0.7 에서 Ki 를 바꾼다.
%  W04_F_PID: first PD (Ki = 0) at efficiency 1, 0.7, 0.5; then Ki varied at 0.7.
%  만드는 것 / produces: img/W04_result_I.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

fprintf('\n  W04 F  1) PD only (Kp = 300, Kd = 100), port propeller at reduced efficiency\n');
fprintf('    port_eff   final psi [deg]   error left [deg]   steady N [N m]\n');
for eff = [1 0.7 0.5]
    R = W04_read('W04_F_PID', 'Ki', 0, 'port_eff', eff);
    fprintf('    %-8g   %15.3f   %16.3f   %14.2f\n', eff, R.psi(end), 10 - R.psi(end), R.N(end));
end

fprintf('\n  2) add the integral, port_eff = 0.7\n');
fprintf('    Ki     final psi [deg]   overshoot %%   settle [s]   I at 40 s [N m]\n');
f = lab_fig('W04 F  integral', 1000, 620);
for Ki = [0 20 50 100]
    R = W04_read('W04_F_PID', 'Ki', Ki, 'port_eff', 0.7);
    [Mp, ts] = step_metrics(R.t, R.psi, 10, 5);
    if abs(R.psi(end) - 10) > 0.2, ts = Inf; end            % 10 도에 닿지 않음 / never reaches 10 deg
    fprintf('    %-5g  %15.3f   %11.2f   %10.2f   %15.2f\n', Ki, R.psi(end), max(Mp,0), ts, R.I(end));
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_i = %g', Ki));
end
subplot(2,1,1); plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command'); grid on;
ylabel('\psi [deg]'); legend('Location','southeast'); title('a weak port propeller: PD stops short, the integral finishes the turn');
subplot(2,1,2); grid on; ylabel('I [N m]'); xlabel('time [s]');
title('every integral ends at the same moment: what the weak propeller fails to give');
exportgraphics(f, fullfile(here, 'img', 'W04_result_I.png'), 'Resolution', 150);
