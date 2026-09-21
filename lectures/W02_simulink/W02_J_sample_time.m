%% W02 · 절 J — 같은 PID 를 컴퓨터에 올리면: 샘플 시간
%  W02 · Section J — the same PID on a computer: the sample time
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_J_sample_time
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 J 이며, §2-10 의 이산 제어를 잰다. MATLAB Tech Talk "Understanding
%      PID Control" 7편이 "스트로보 불빛 아래에서 복도를 달리는 것" 에 비유한 것을
%      수로 확인한다.
%      Section J of Part 2. It measures the sampled control of §2-10 - what
%      part 7 of the MATLAB Tech Talk "Understanding PID Control" compares to
%      running down a corridor lit by a strobe.
%
%  무엇을 하는가 / what it does
%      모델을 쓰지 않고 MATLAB 에서 계산한다. 플랜트는 영차 유지(ZOH)로, 제어기는
%      Tustin 변환으로 이산화하여 샘플 시간 Ts 를 0.01 에서 0.4 s 까지 바꾼다. 연속시간
%      폐루프의 대역폭 wB 와 곱 Ts wB 를 함께 적고, 루프가 불안정해지는 Ts 를
%      이분법으로 찾는다.
%      Computed in MATLAB, without the model. The plant is discretised with a
%      zero-order hold and the controller with the Tustin transform, for Ts
%      from 0.01 to 0.4 s. The bandwidth wB of the continuous closed loop is
%      printed with the product Ts wB, and the Ts at which the loop goes
%      unstable is found by bisection.
%
%  결과를 읽는 법 / how to read the result
%      Ts wB 가 작으면 이산 제어기는 연속 제어기와 구별되지 않는다. 커질수록 오버슛이
%      늘고, 어느 지점을 넘으면 폐루프 극점이 단위원 밖으로 나가 발산한다. 같은
%      게인이 샘플 시간 하나 때문에 불안정해진다.
%      With Ts wB small the sampled controller cannot be told from the
%      continuous one. As it grows the overshoot grows, and past some point a
%      closed-loop pole leaves the unit circle and the loop diverges. The same
%      gains become unstable because of the sample time alone.
%
%  만드는 것 / what it produces
%      표 하나, img/W02_result_sampling.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);

V  = W02_vars();
s  = tf('s');
G  = 1/(V.pid_m*s^2 + V.pid_b*s + V.pid_k);
C  = V.Kp + V.Ki/s + V.Kd*V.Nf*s/(s + V.Nf);
Tc = feedback(C*G, 1);
wB = bandwidth(Tc);
TS = [0.01 0.05 0.1 0.2 0.3 0.4];
tt = (0:0.001:9)';

fprintf('\n  W02 section J — the same PID, sampled (Kp = %g, Ki = %g, Kd = %g, Nf = %g)\n', ...
        V.Kp, V.Ki, V.Kd, V.Nf);
fprintf('\n    continuous closed-loop bandwidth  wB = %.2f rad/s\n', wB);
yc = step(Tc, tt);
[Mpc, tsc] = step_metrics(tt, yc, 1, 0);
fprintf('\n    %-12s %9s %14s %13s %13s\n', 'Ts [s]', 'Ts wB', 'largest |pole|', ...
        'overshoot [%]', 'settle [s]');
fprintf('    %s\n', repmat('-', 1, 66));
fprintf('    %-12s %9s %14s %13.1f %13.2f\n', 'continuous', '-', '-', Mpc, tsc);
Y = cell(1, numel(TS));  P = zeros(1, numel(TS));  MPS = nan(1, numel(TS));
for i = 1:numel(TS)
    Gd = c2d(G, TS(i), 'zoh');
    Cd = c2d(C, TS(i), 'tustin');
    Td = feedback(Cd*Gd, 1);
    P(i) = max(abs(pole(Td)));
    td = (0:TS(i):9)';
    yd = step(Td, td);
    Y{i} = [td yd];
    if P(i) < 1
        [Mp, ts] = step_metrics(td, yd, 1, 0);  MPS(i) = Mp;
        fprintf('    %-12g %9.2f %14.4f %13.1f %13.2f\n', TS(i), TS(i)*wB, P(i), Mp, ts);
    else
        fprintf('    %-12g %9.2f %14.4f %13s %13s\n', TS(i), TS(i)*wB, P(i), 'unstable', '-');
    end
end
%  폐루프 극점이 단위원에 닿는 샘플 시간을 이분법으로 찾는다.
%  The sample time at which a closed-loop pole reaches the unit circle, by bisection.
lo = 0.01;  hi = 2;
for it = 1:60
    Tm = (lo + hi)/2;
    Td = feedback(c2d(C, Tm, 'tustin')*c2d(G, Tm, 'zoh'), 1);
    if max(abs(pole(Td))) < 1, lo = Tm; else, hi = Tm; end
end
fprintf('\n    the loop becomes unstable at Ts = %.3f s  (Ts wB = %.2f)\n', lo, lo*wB);
fprintf(['\n    A sampled controller sees the error only at the sample instants and\n' ...
         '    holds its force in between. Sampling 20 times faster than the closed-\n' ...
         '    loop bandwidth, Ts wB below 2 pi/20 = 0.31, leaves the response almost\n' ...
         '    unchanged (%.1f %% overshoot at Ts = 0.05 s). Slower than that the\n' ...
         '    controller always acts on stale information and the overshoot grows;\n' ...
         '    at Ts = %.3f s a pole reaches the unit circle and the very gains that\n' ...
         '    were fine in continuous time no longer hold the loop together.\n' ...
         '\n    This course simulates the controllers in continuous time, as MSS does,\n' ...
         '    and tunes them there. The table is the check to make before the same\n' ...
         '    gains go onto a computer running at a given rate.\n'], MPS(TS == 0.05), lo);

%% ---- figure ------------------------------------------------------------
col = [0 0.45 0.74; 0.47 0.67 0.19; 0.93 0.69 0.13; 0.85 0.33 0.10; 0.49 0.18 0.56; 0.64 0.08 0.18];
f = lab_fig('W02 J  sample time', 1000, 480);
hold on;
plot(tt, yc, 'k-', 'LineWidth', 3, 'DisplayName', 'continuous');
for i = 1:numel(TS)
    stairs(Y{i}(:,1), Y{i}(:,2), 'Color', col(i,:), 'LineWidth', 1.4, ...
           'DisplayName', sprintf('T_s = %g s  (T_s \\omega_B = %.2f)', TS(i), TS(i)*wB));
end
ylim([-0.5 2]);  xlim([0 9]);  grid on;
xlabel('time [s]');  ylabel('position y [m]');  legend('Location','northeast');
title({'the same gains, sampled more and more slowly', ...
       'the controller holds its force between samples and acts on older and older errors'});
exportgraphics(f, fullfile(here, 'img', 'W02_result_sampling.png'), 'Resolution', 150);
