%% W02 · 절 B-2 — 감쇠비와 고유진동수 / Section B-2 — damping ratio and natural frequency
%  모델 W02_B_second_order 에서 zeta 만, 그다음 wn 만 바꿔 가며 네 지표와 대역폭을 잰다.
%  Runs W02_B_second_order varying zeta alone, then wn alone; measures four metrics and the bandwidth.
%  만드는 것 / produces: img/W02_result_zeta_wn.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

f = lab_fig('W02 B-2  zeta and wn', 1100, 800);
fprintf('\n  W02 B-2  the standard second-order system\n');
C = {'zeta', [0.2 0.5 0.707 1 2], 2, 'wn';  'wn', [1 2 4], 0.5, 'zeta'};   % 바꾸는 것, 값, 고정값, 고정된 것
for c = 1:2
    fprintf('    %s varies, %s = %g\n', C{c,1}, C{c,4}, C{c,3});
    fprintf('      zeta    wn   overshoot %% (formula)  peak time [s] (formula)  rise [s]  settle [s]  bandwidth [rad/s]\n');
    for v = C{c,2}
        if c == 1, z = v; w = C{c,3}; else, z = C{c,3}; w = v; end
        R = W02_read('W02_B_second_order', 'zeta', z, 'wn', w);
        [Mp, ts, tr] = step_metrics(R.t, R.y, 1, 1);
        [~, i] = max(R.y);  tp = R.t(i) - 1;
        if z < 1, fMp = 100*exp(-pi*z/sqrt(1 - z^2)); ftp = pi/(w*sqrt(1 - z^2));
        else,     fMp = 0; ftp = NaN; tp = NaN; end                % 봉우리가 없다 / no peak
        wB = bandwidth(tf(w^2, [1 2*z*w w^2]), -10*log10(2));   % 이득이 1/sqrt(2) 로 떨어지는 곳 / where the gain falls to 1/sqrt(2)
        if isnan(tp), P = '   none          '; else, P = sprintf('%7.3f (%6.3f)', tp, ftp); end
        fprintf('      %5.3f  %4g  %8.1f (%5.1f)        %s       %6.3f   %8.2f   %10.2f\n', ...
                z, w, max(Mp,0), fMp, P, tr, ts, wB);
        subplot(2,2,2*c-1); hold on; plot(R.t - 1, R.y, 'LineWidth', 1.8, ...
                'DisplayName', sprintf('\\zeta = %g, \\omega_n = %g', z, w));
        p = roots([1 2*z*w w^2]);
        subplot(2,2,2*c); hold on; plot(real(p), imag(p), 'x', 'MarkerSize', 11, 'LineWidth', 2.2, ...
                'DisplayName', sprintf('\\zeta = %g, \\omega_n = %g', z, w));
    end
end
tt = {'\zeta varies, \omega_n = 2: larger \zeta, less overshoot', ...
      '\omega_n varies, \zeta = 0.5: larger \omega_n, faster, same overshoot'};
for c = 1:2
    subplot(2,2,2*c-1); yline(1,'k--','HandleVisibility','off'); xlim([0 9]); grid on;
    xlabel('time after the step [s]'); ylabel('y'); title(tt{c}); legend('Location','southeast');
    subplot(2,2,2*c); xline(0,'k-'); yline(0,'k:');
    grid on; xlabel('real part'); ylabel('imaginary part');
end
subplot(2,2,2); th = linspace(pi/2, 3*pi/2, 100); plot(2*cos(th), 2*sin(th), 'k:');
axis equal; xlim([-8 0.5]); ylim([-4 4]);
title('the poles slide along the circle of radius \omega_n = 2');
subplot(2,2,4); plot([0 -4*cos(pi/3)], [0 4*sin(pi/3)], 'k:', [0 -4*cos(pi/3)], [0 -4*sin(pi/3)], 'k:');
axis equal; xlim([-5 1]); ylim([-4 4]);
title('the poles move out along the ray \zeta = cos 60\circ = 0.5');
exportgraphics(f, fullfile(here, 'img', 'W02_result_zeta_wn.png'), 'Resolution', 150);
