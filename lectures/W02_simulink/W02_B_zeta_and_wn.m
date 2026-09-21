%% W02 · 절 B-2 — 감쇠비와 고유진동수 / Section B-2 — damping ratio and natural frequency
%  모델 W02_B_second_order 에서 zeta 만, 그다음 wn 만 바꿔 가며 네 지표와 대역폭을 잰다.
%  Runs W02_B_second_order varying zeta alone, then wn alone; measures four metrics and the bandwidth.
%
%  표준 2차 시스템 / the standard second-order system (§2-3)
%      Y(s)/Y_d(s) = wn^2 / (s^2 + 2 zeta wn s + wn^2)
%
%  출력에서 볼 것 / what to look for in the output
%      - zeta 가 클수록 오버슛이 작다 (52.7 -> 16.3 -> 4.3 -> 0 %). 오버슛은 zeta 만의 함수다.
%      - wn 이 두 배면 첨두시간·상승시간·정착시간이 반, 대역폭은 두 배. 오버슛은 그대로다.
%      - 측정한 오버슛과 첨두시간이 괄호 안의 공식값과 같다.
%      - A larger zeta, less overshoot (52.7 -> 16.3 -> 4.3 -> 0 %); the overshoot
%        depends on zeta alone.
%      - Doubling wn halves the peak, rise and settling times and doubles the
%        bandwidth; the overshoot stays.
%      - The measured overshoot and peak time equal the formulas in brackets.
%
%  만드는 것 / produces: img/W02_result_zeta_wn.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 두 번의 훑기: zeta 만 바꾸기, 그다음 wn 만 바꾸기
%     Two sweeps: zeta alone, then wn alone
%  C 의 한 줄 = {바꾸는 이름, 값들, 고정한 값, 고정한 이름}
%  One row of C = {name varied, its values, the fixed value, the fixed name}

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
