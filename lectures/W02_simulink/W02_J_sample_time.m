%% W02 · 절 J — 같은 PID 를 컴퓨터에 올리면 / Section J — the same PID on a computer
%  모델 없이 MATLAB 으로: 플랜트는 영차 유지(ZOH), 제어기는 Tustin 으로 이산화하고 샘플 시간 Ts 를 늘려 간다.
%  Ts 와 폐루프 대역폭 wB 의 곱이 작으면 연속시간과 같고, 커지면 오버슛이 늘다가 불안정해진다.
%  Without a model: plant by zero-order hold, controller by Tustin, for growing Ts.
%  Small Ts*wB behaves like continuous time; larger Ts*wB overshoots more and finally goes unstable.
%  만드는 것 / produces: img/W02_result_sampling.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
s  = tf('s');
G  = 1/(s^2 + 2*s + 2);
C  = 10 + 8/s + 4*20*s/(s + 20);                     % Kp 10, Ki 8, Kd 4, Nf 20
wB = bandwidth(feedback(C*G, 1));
cl = @(Ts) feedback(c2d(C, Ts, 'tustin')*c2d(G, Ts, 'zoh'), 1);

fprintf('\n  W02 J  sampled PID, closed-loop bandwidth wB = %.2f rad/s\n', wB);
fprintf('    Ts [s]   Ts*wB   overshoot %%   settle [s]\n');
f = lab_fig('W02 J  sample time', 1000, 460);  hold on;
tt = (0:0.001:9)';  yc = step(feedback(C*G, 1), tt);
plot(tt, yc, 'k', 'LineWidth', 3, 'DisplayName', 'continuous');
[Mp, ts] = step_metrics(tt, yc, 1, 0);
fprintf('    cont.    -       %8.1f   %9.2f\n', Mp, ts);
for Ts = [0.01 0.05 0.1 0.2 0.3 0.4]
    td = (0:Ts:9)';  yd = step(cl(Ts), td);
    [Mp, ts] = step_metrics(td, yd, 1, 0);
    fprintf('    %-7g  %5.2f   %8.1f   %9.2f\n', Ts, Ts*wB, Mp, ts);
    stairs(td, yd, 'LineWidth', 1.3, 'DisplayName', sprintf('T_s = %g s', Ts));
end
lo = 0.01;  hi = 2;                                  % 불안정해지는 Ts / where it goes unstable
for it = 1:50
    m = (lo + hi)/2;
    if max(abs(pole(cl(m)))) < 1, lo = m; else, hi = m; end
end
fprintf('    unstable from Ts = %.3f s  (Ts*wB = %.2f)\n', lo, lo*wB);
ylim([-0.5 2]); grid on; legend; xlabel('time [s]'); ylabel('position y [m]');
title('the same gains, sampled more and more slowly');
exportgraphics(f, fullfile(here, 'img', 'W02_result_sampling.png'), 'Resolution', 150);
