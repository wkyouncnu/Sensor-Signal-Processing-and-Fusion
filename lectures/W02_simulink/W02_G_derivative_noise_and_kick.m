%% W02 · 절 G — 미분항이 교과서대로면 부러지는 두 곳: 잡음과 계단
%  W02 · Section G — the two places a textbook derivative breaks: noise and steps
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_G_derivative_noise_and_kick
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 G 이며, §2-7 의 두 결론을 잰다.
%      Section G of Part 2. It measures the two conclusions of §2-7.
%
%  무엇을 하는가 / what it does
%      1) 잡음. 위치 센서에 표준편차 5 mm 의 잡음을 넣고, 미분 필터 계수 Nf 를 5,
%         20, 200 으로 바꾸고, 마지막으로 필터 없는 순수 미분으로 돌린다. 출력이 얼마나
%         흔들리는지와 제어기가 내는 힘이 얼마나 떨리는지를 잰다.
%         Noise. The position sensor gets noise of standard deviation 5 mm, the
%         filter coefficient Nf is set to 5, 20 and 200, and finally the pure,
%         unfiltered derivative is used. How much the output wanders and how
%         much the force chatters are measured.
%      2) 킥. 잡음 없이, 목표를 계단으로 줄 때와 1차 필터로 부드럽게 줄 때 제어기가
%         낸 가장 큰 힘을 비교한다. 제어조교(Ctrl튜브)의 PID 튜닝 영상이 권하는 방법
%         이다.
%         The kick. Without noise, the largest force is compared between a step
%         setpoint and the same step passed through a first-order filter - the
%         remedy recommended by the Ctrl-tube PID tuning video.
%
%  결과를 읽는 법 / how to read the result
%      미분은 신호를 크기가 아니라 빠르기로 키운다. 잡음은 가장 빠른 신호이므로
%      미분은 잡음만 골라 키운다. 필터는 그 증폭에 Kd Nf 라는 천장을 둔다.
%      계단은 무한히 빠른 신호이므로 그 순간의 미분도 천장까지 튄다. 목표에서 모서리를
%      없애면 그 튐이 사라진다.
%      A derivative amplifies a signal by how fast it is, not how large. Noise
%      is the fastest signal present, so the derivative selects the noise. The
%      filter puts a ceiling of Kd Nf on that amplification. A step is an
%      infinitely fast signal, so at that instant the derivative jumps to the
%      ceiling too; taking the corner off the setpoint removes the jump.
%
%  만드는 것 / what it produces
%      표 둘, img/W02_result_noise.png, img/W02_result_kick.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V = W02_vars();                                  % Kp 10, Ki 8, Kd 4
sd = 0.005;

%% ---- 1) noise -----------------------------------------------------------
CASE = {'Nf = 5',   {'Nf', 5}
        'Nf = 20',  {'Nf', 20}
        'Nf = 200', {'Nf', 200}
        'pure derivative', {'d_filtered', 0}};
fprintf('\n  W02 section G — the derivative, noise and the kick\n');
fprintf('\n  1) sensor noise of %g m standard deviation, every %g s\n\n', sd, V.noise_ts);
%  잡음이 있는 실행에서 힘과 위치의 흔들림을, 잡음이 없는 같은 실행에서 응답의
%  모양(오버슛, 정착)을 잰다. 잡음이 있으면 2 % 띠를 드나드는 것이 응답인지 잡음인지
%  가려낼 수 없기 때문이다.
%  The chatter is measured on the noisy run and the shape of the response
%  (overshoot, settling) on the same run without noise: with noise present,
%  crossing the 2 % band cannot be told apart from the noise itself.
fprintf('    %-17s %13s %15s %13s %15s %12s\n', 'derivative', 'ceiling', ...
        'force std', 'y std', 'overshoot', 'settle');
fprintf('    %-17s %13s %15s %13s %15s %12s\n', '', 'Kd Nf [N s/m]', ...
        '[N], t > 6 s', '[mm], t > 6 s', '[%], no noise', '[s], no noise');
fprintf('    %s\n', repmat('-', 1, 92));
N = cell(1, size(CASE,1));
for i = 1:size(CASE,1)
    a = CASE{i,2};
    N{i} = W02_read(run_sim('W02_pid', V, 'noise_std', sd, a{:}));
    Q    = W02_read(run_sim('W02_pid', V, 'noise_std', 0,  a{:}));
    late = N{i}.t > 6;
    [Mp, ts] = step_metrics(Q.t, Q.y, V.y_step, V.t_step);
    if strcmp(a{1}, 'Nf'), ceil_s = sprintf('%g', V.Kd*a{2}); else, ceil_s = 'none'; end
    fprintf('    %-17s %13s %15.2f %13.2f %15.1f %12.2f\n', CASE{i,1}, ceil_s, ...
            std(N{i}.tau(late)), 1e3*std(N{i}.y(late)), Mp, ts);
    N{i}.sd_tau = std(N{i}.tau(late));  N{i}.sd_y = 1e3*std(N{i}.y(late));
    N{i}.Mp = Mp;  N{i}.ts = ts;
end
fprintf(['\n    The force chatters in proportion to the ceiling: %.2f N at Nf = 5,\n' ...
         '    %.2f N at Nf = 200. A pure derivative has no ceiling at all, and the\n' ...
         '    force std reaches %.2f N on a plant that needs 2 N to hold its position.\n' ...
         '\n    The position does not improve in return. Its wander stays between\n' ...
         '    %.2f and %.2f mm in all four runs: the extra force is spent on the\n' ...
         '    noise, not on the mass. That is the whole argument for the filter.\n' ...
         '\n    Too low a ceiling costs something else. At Nf = 5 the filter delays\n' ...
         '    the derivative so much that it no longer brakes in time: the overshoot\n' ...
         '    is %.1f %% against %.1f %% at Nf = 20. Nf sits between the two costs -\n' ...
         '    above the frequencies of the response, below those of the noise.\n'], ...
         N{1}.sd_tau, N{3}.sd_tau, N{4}.sd_tau, ...
         min(cellfun(@(x) x.sd_y, N)), max(cellfun(@(x) x.sd_y, N)), N{1}.Mp, N{2}.Mp);

%% ---- 2) the kick --------------------------------------------------------
K = {W02_read(run_sim('W02_pid', V, 'ref_filter', 0)), ...
     W02_read(run_sim('W02_pid', V, 'ref_filter', 1))};
fprintf('\n  2) the derivative kick: a step setpoint against a smoothed one (Tf = %g s)\n\n', V.ref_Tf);
fprintf('    %-20s %16s %16s %14s %14s\n', 'setpoint', 'peak force [N]', 'peak D term [N]', ...
        'overshoot [%]', 'settle [s]');
fprintf('    %s\n', repmat('-', 1, 86));
LBL = {'step', 'smoothed step'};
for i = 1:2
    [Mp, ts] = step_metrics(K{i}.t, K{i}.y, V.y_step, V.t_step);
    fprintf('    %-20s %16.1f %16.1f %14.1f %14.2f\n', LBL{i}, max(abs(K{i}.tau)), ...
            max(abs(K{i}.D)), Mp, ts);
    K{i}.peak = max(abs(K{i}.tau));
end
fprintf(['\n    At the instant of the step the error jumps by 1 m. The filtered\n' ...
         '    derivative of a jump of height 1 starts at Kd Nf = %g N and decays with\n' ...
         '    time constant 1/Nf. Add Kp x 1 = %g N and the force starts at %g N.\n' ...
         '    The smoothed setpoint has no corner, its slope is at most 1/Tf, and the\n' ...
         '    peak force falls to %.1f N, a factor of %.1f.\n' ...
         '\n    The response is not simply slower: the setpoint itself now arrives\n' ...
         '    later, and that shows in the settling time. It is the price of asking\n' ...
         '    only for what the actuator can deliver.\n'], ...
         V.Kd*V.Nf, V.Kp, V.Kd*V.Nf + V.Kp, K{2}.peak, K{1}.peak/K{2}.peak);

%% ---- figures -----------------------------------------------------------
col = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.6 0.6 0.6];
f = lab_fig('W02 G  noise', 1000, 640);
subplot(2,1,1); hold on;
for i = [4 3 2 1]
    plot(N{i}.t, N{i}.tau, 'Color', col(i,:), 'LineWidth', 1, 'DisplayName', CASE{i,1});
end
xlim([5 10]);  ylabel('force \tau [N]');  legend('Location','northeast');  grid on;
title('the same 5 mm of sensor noise, four derivatives: the force they ask for');
subplot(2,1,2); hold on;
for i = [2 1]
    plot(N{i}.t, N{i}.tau, 'Color', col(i,:), 'LineWidth', 1.2, 'DisplayName', CASE{i,1});
end
xlim([5 10]);  ylabel('force \tau [N]');  xlabel('time [s]');  legend('Location','northeast');
grid on;  title('the two usable ones, on their own scale');
exportgraphics(f, fullfile(here, 'img', 'W02_result_noise.png'), 'Resolution', 150);

g = lab_fig('W02 G  kick', 1000, 600);
subplot(2,1,1); hold on;
plot(K{1}.t, K{1}.y_d, 'k--', 'LineWidth', 1.1, 'DisplayName', 'step setpoint');
plot(K{2}.t, K{2}.y_d, 'k:', 'LineWidth', 1.4, 'DisplayName', 'smoothed setpoint');
plot(K{1}.t, K{1}.y, 'Color', col(2,:), 'LineWidth', 2, 'DisplayName', 'response to the step');
plot(K{2}.t, K{2}.y, 'Color', col(1,:), 'LineWidth', 2, 'DisplayName', 'response to the smoothed step');
xlim([0 6]);  ylabel('position [m]');  legend('Location','southeast');  grid on;
title('the same controller, two setpoints');
subplot(2,1,2); hold on;
plot(K{1}.t, K{1}.tau, 'Color', col(2,:), 'LineWidth', 2, 'DisplayName', 'step');
plot(K{2}.t, K{2}.tau, 'Color', col(1,:), 'LineWidth', 2, 'DisplayName', 'smoothed step');
xlim([0 6]);  ylabel('force \tau [N]');  xlabel('time [s]');  legend('Location','northeast');
grid on;
title(sprintf('the kick: %.0f N at the corner of the step, %.1f N without the corner', ...
      K{1}.peak, K{2}.peak));
exportgraphics(g, fullfile(here, 'img', 'W02_result_kick.png'), 'Resolution', 150);
