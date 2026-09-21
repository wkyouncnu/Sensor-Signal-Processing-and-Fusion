%% W02 · 절 G — 유사미분(pseudo-derivative) / Section G — the pseudo-derivative
%  1) 시험대 W02_G_derivative_bench: 잡음 섞인 sin(0.5 t) 를 순수 미분과 Nf s/(s+Nf) 로 미분해 참값 0.5 와 비교.
%  2) 루프 W02_G_noise_kick: 5 mm 잡음에서 Nf = 5, 20, 200 과 순수 미분이 내는 힘의 떨림.
%  3) 같은 루프에서 계단 목표와 부드럽게 한 목표의 가장 큰 힘(미분 킥).
%  1) The bench: a noisy sin(0.5 t) differentiated purely and by Nf s/(s+Nf), against the true 0.5.
%  2) The loop with 5 mm of noise: force chatter for Nf = 5, 20, 200 and the pure derivative.
%  3) The same loop: peak force for a step setpoint and a smoothed one (the kick).
%
%  출력에서 볼 것 / what to look for in the output
%      1) 순수 미분은 26.55 까지 튄다 (참값 0.5 의 53 배). 유사미분은 Nf 가 작을수록 참값에 가깝다.
%      2) 순수 미분이면 힘이 9.29 N 표준편차로 떨린다; Nf = 20 이면 0.45 N. 위치의 흔들림은
%         넷 다 0.5 mm 대로 같다 — 늘어난 힘은 잡음에 쓰일 뿐이다. Nf = 5 는 너무 늦어 오버슛 16 %.
%      3) 계단 목표의 최대 힘 89.7 N 이 부드럽게 한 목표에서는 10.5 N.
%      1) The pure derivative spikes to 26.55 (53 times the true 0.5); the
%         pseudo-derivative is closer to the truth the smaller Nf is.
%      2) With the pure derivative the force chatters at 9.29 N standard
%         deviation; at Nf = 20, 0.45 N. The position wanders by about 0.5 mm in
%         all four — the extra force goes into the noise. Nf = 5 is so late
%         that the overshoot returns to 16 %.
%      3) A step setpoint asks 89.7 N at its peak; the smoothed one 10.5 N.
%
%  만드는 것 / produces: img/W02_result_bench.png, W02_result_noise.png, W02_result_kick.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 시험대: 루프 없이 미분만 / the bench: differentiation alone, no loop
%  bench(Nf) (맨 아래 함수) 가 시험대 모델을 돌려 [시간, 순수 미분, 유사미분, 참값] 을 돌려준다.
%  bench(Nf) (at the bottom) runs the bench model and returns [time, pure, pseudo, true].
fprintf('\n  W02 G  1) the bench: derivative of sin(0.5 t) + 5 mm noise (true peak 0.5)\n');
fprintf('    Nf     largest |pure|   largest |pseudo|\n');
g = lab_fig('W02 G  bench', 1000, 420);  hold on;
for Nf = [5 20 200]
    B = bench(Nf);
    fprintf('    %-5g  %13.2f   %15.2f\n', Nf, max(abs(B(:,2))), max(abs(B(:,3))));
    if Nf == 20
        plot(B(:,1), B(:,2), 'Color', [0.7 0.7 0.7], 'DisplayName', 'pure derivative');
        plot(B(:,1), B(:,3), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6, 'DisplayName', 'pseudo, N_f = 20');
        plot(B(:,1), B(:,4), 'k--', 'LineWidth', 1.6, 'DisplayName', 'true 0.5 cos(0.5 t)');
    end
end
ylim([-3 3]); grid on; legend('Location','northeast'); xlabel('time [s]'); ylabel('derivative');
title('the same noisy signal differentiated: the pure derivative is buried (clipped at \pm3), the pseudo-derivative is not');
exportgraphics(g, fullfile(here, 'img', 'W02_result_bench.png'), 'Resolution', 150);

%% 2) 루프 안에서, 잡음 5 mm / in the loop, with 5 mm of noise
%  네 가지 미분: Nf = 5, 20, 200 의 유사미분과 순수 미분 (d_filtered = 0).
%  경우마다 두 번 돌린다: N = 잡음이 있을 때 (힘의 떨림), Q = 잡음 없을 때 (오버슛).
%  Four derivatives: the pseudo-derivative at Nf = 5, 20, 200 and the pure one
%  (d_filtered = 0). Each is run twice: N with noise (force chatter), Q without (overshoot).
CASE = {'Nf = 5', {'Nf',5}; 'Nf = 20', {'Nf',20}; 'Nf = 200', {'Nf',200}; 'pure', {'d_filtered',0}};
fprintf('\n  2) the loop, 5 mm of noise (Kp 10, Ki 8, Kd 4)\n');
fprintf('    %-10s  force std [N]  y std [mm]  overshoot %% (no noise)\n', 'derivative');
f = lab_fig('W02 G  noise', 1000, 420);  hold on;
for i = [4 3 2 1]
    N = W02_read('W02_G_noise_kick', 'noise_std', 0.005, CASE{i,2}{:});
    Q = W02_read('W02_G_noise_kick', CASE{i,2}{:});
    late = N.t > 6;          % 응답이 자리 잡은 뒤의 구간 / the window after the response has settled
    fprintf('    %-10s  %13.2f  %10.2f  %12.1f\n', CASE{i,1}, std(N.tau(late)), 1e3*std(N.y(late)), ...
            max(0, step_metrics(Q.t, Q.y, 1, 1)));     % -0.0 대신 0.0 / 0.0 rather than -0.0
    plot(N.t, N.tau, 'LineWidth', 1, 'DisplayName', CASE{i,1});
end
xlim([5 10]); grid on; legend; xlabel('time [s]'); ylabel('force \tau [N]');
title('the same 5 mm of noise: the force each derivative asks for');
exportgraphics(f, fullfile(here, 'img', 'W02_result_noise.png'), 'Resolution', 150);

%% 3) 미분 킥: 계단 목표 대 부드럽게 한 목표 / the kick: a step setpoint against a smoothed one
%  ref_filter = 0 은 계단 그대로, 1 은 1/(0.3 s + 1) 로 모서리를 깎은 목표.
%  ref_filter = 0 is the raw step; 1 takes the corner off with 1/(0.3 s + 1).
fprintf('\n  3) the kick: step setpoint against a smoothed one (Tf = 0.3 s)\n');
fprintf('    %-10s  peak force [N]  peak D [N]\n', 'setpoint');
h = lab_fig('W02 G  kick', 1000, 420);  hold on;
L = {'step', 'smoothed'};
for r = [0 1]
    K = W02_read('W02_G_noise_kick', 'ref_filter', r);
    fprintf('    %-10s  %14.1f  %10.1f\n', L{r+1}, max(abs(K.tau)), max(abs(K.D)));
    plot(K.t, K.tau, 'LineWidth', 2, 'DisplayName', L{r+1});
end
xlim([0 6]); grid on; legend; xlabel('time [s]'); ylabel('force \tau [N]');
title('the kick belongs to the corner of the step, not to the task');
exportgraphics(h, fullfile(here, 'img', 'W02_result_kick.png'), 'Resolution', 150);

% -------------------------------------------------------------------------
function B = bench(Nf)
%  [t pure pseudo true], 처음 1 초는 버린다 (필터가 자리 잡는 동안) / first second dropped
V = W02_vars();  V.Nf = Nf;
in = Simulink.SimulationInput('W02_G_derivative_bench');
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
y = squeeze(out.W02bench.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = out.W02bench.time;  k = t > 1;
B = [t(k) y(k,:)];
end
