%% W02 · 절 J — 같은 PID 를 컴퓨터에 올리면 / Section J — the same PID on a computer
%  모델 없이 MATLAB 으로: 플랜트는 영차 유지(ZOH), 제어기는 Tustin 으로 이산화하고 샘플 시간 Ts 를 늘려 간다.
%  Ts 와 폐루프 대역폭 wB 의 곱이 작으면 연속시간과 같고, 커지면 오버슛이 늘다가 불안정해진다.
%  Without a model: plant by zero-order hold, controller by Tustin, for growing Ts.
%  Small Ts*wB behaves like continuous time; larger Ts*wB overshoots more and finally goes unstable.
%
%  출력에서 볼 것 / what to look for in the output
%      - Ts*wB 가 0.31 이하이면 (샘플링 주파수가 대역폭의 20 배 이상) 연속시간과 거의 같다.
%      - 그보다 크면 오버슛이 늘고 (Ts = 0.4 s 에서 67.8 %), Ts = 0.511 s 에서 불안정해진다.
%      - Up to Ts*wB = 0.31 (sampling at 20 times the bandwidth or more) the
%        response is almost the continuous one.
%      - Beyond it the overshoot grows (67.8 % at Ts = 0.4 s), and at
%        Ts = 0.511 s the loop goes unstable.
%
%  만드는 것 / produces: img/W02_result_sampling.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 플랜트와 제어기의 전달함수, 폐루프 대역폭 / plant, controller, closed-loop bandwidth
%  cl(Ts): 플랜트는 영차 유지(ZOH), 제어기는 Tustin 으로 바꿔 만든 이산 폐루프
%  cl(Ts): the discrete closed loop, plant by zero-order hold, controller by Tustin
s  = tf('s');
G  = 1/(s^2 + 2*s + 2);
C  = 10 + 8/s + 4*20*s/(s + 20);                     % Kp 10, Ki 8, Kd 4, Nf 20
wB = bandwidth(feedback(C*G, 1));
cl = @(Ts) feedback(c2d(C, Ts, 'tustin')*c2d(G, Ts, 'zoh'), 1);

%% 2) 연속시간 기준, 그리고 샘플 시간 여섯 개 / the continuous reference, then six sample times
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
%% 3) 불안정해지는 Ts 를 이분법으로: 이산 극점의 크기가 1 을 넘는 곳
%     The Ts at which it goes unstable, by bisection: where a discrete pole's magnitude reaches 1
lo = 0.01;  hi = 2;                                  % 불안정해지는 Ts / where it goes unstable
for it = 1:50
    m = (lo + hi)/2;
    if max(abs(pole(cl(m)))) < 1, lo = m; else, hi = m; end
end
fprintf('    unstable from Ts = %.3f s  (Ts*wB = %.2f)\n', lo, lo*wB);
ylim([-0.5 2]); grid on; legend; xlabel('time [s]'); ylabel('position y [m]');
title('the same gains, sampled more and more slowly');
exportgraphics(f, fullfile(here, 'img', 'W02_result_sampling.png'), 'Resolution', 150);
