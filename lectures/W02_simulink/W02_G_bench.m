%% W02 · 실험 2-10b — 시험대 위의 유사미분 / Experiment 2-10b — the pseudo-derivative on a bench
%
%  이 절이 묻는 것 / the question
%      교과서의 미분을 그대로 구현하지 않는 이유는 무엇인가?
%      Why is a textbook derivative never implemented as written?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W02_G_derivative_bench 를 Nf = 5, 20, 200 으로 한 번씩 돌린다.
%         루프도 플랜트도 없다 — 잡음 섞인 sin(0.5 t) 하나를 두 가지로 미분할 뿐이다.
%      ② 순수 미분과 유사미분의 가장 큰 값을 참값 0.5 와 나란히 찍는다.
%      ③ Nf = 20 의 세 곡선을 그려 저장한다.
%      ① Runs W02_G_derivative_bench at Nf = 5, 20 and 200 — no loop, no plant:
%         one noisy sin(0.5 t), differentiated two ways.
%      ② Prints the largest pure and pseudo derivative next to the true peak 0.5.
%      ③ Plots the three curves at Nf = 20 and saves the figure.
%
%  출력에서 볼 것 / what to look for in the output
%      - 순수 미분은 26.55 까지 튄다 — 참값의 53 배. 5 mm 잡음이 그렇게 만든다.
%      - 유사미분은 천장 Kd Nf 에 걸려 참값 근처에 머문다. Nf 가 클수록 잡음이 더 샌다.
%      - The pure derivative spikes to 26.55, 53 times the true value, from 5 mm of noise.
%      - The pseudo-derivative is held near the truth by its ceiling; a larger Nf lets more through.
%
%  만드는 것 / produces: img/W02_result_bench.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) Nf 세 개로 시험대를 돌린다 / three values of Nf on the bench
fprintf('\n  W02 Experiment 2-10b  the bench: derivative of sin(0.5 t) + 5 mm noise (true peak 0.5)\n');
fprintf('    Nf     largest |pure|   largest |pseudo|\n');
g = lab_fig('W02 Exp 2-10b  bench', 1000, 420);  hold on;
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
