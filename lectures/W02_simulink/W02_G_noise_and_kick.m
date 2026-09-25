%% W02 · 실험 2-10c — 루프 안의 미분: 잡음과 계단 모서리 / Experiment 2-10c — in the loop: noise and the kick
%
%  이 절이 묻는 것 / the question
%      시험대에서 본 것이 루프 안에서는 무엇으로 나타나는가? 값은 누가 치르는가?
%      What does the bench result cost once the derivative is inside a loop?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W02_G_noise_kick 을 네 가지 미분(Nf = 5, 20, 200, 순수)으로 돌린다.
%         경우마다 두 번: 잡음 5 mm 를 넣고(힘의 떨림), 빼고(오버슛).
%      ② 같은 모델을 계단 목표와 부드럽게 한 목표로 한 번씩 돌려 미분 킥을 잰다.
%      ③ 힘의 시간 그림 두 장을 저장한다.
%      ① Runs W02_G_noise_kick with four derivatives (Nf = 5, 20, 200, pure),
%         each twice: with 5 mm of noise (force chatter) and without (overshoot).
%      ② Runs the same model with a step setpoint and a smoothed one — the kick.
%      ③ Saves the two force plots.
%
%  출력에서 볼 것 / what to look for in the output
%      - 힘의 떨림은 천장 Kd Nf 에 비례한다: 순수 9.29 N, Nf = 20 이면 0.45 N.
%      - 위치의 흔들림은 넷 다 0.5 mm 대다 — 늘어난 힘은 잡음에만 쓰인다.
%      - Nf = 5 는 브레이크가 너무 늦어 오버슛이 16 % 로 돌아온다.
%      - 계단 목표의 최대 힘 89.7 N 이 부드럽게 한 목표에서는 10.5 N.
%      - The chatter follows the ceiling Kd Nf: 9.29 N pure, 0.45 N at Nf = 20.
%      - The position wanders by about 0.5 mm in all four — the extra force is spent on the noise.
%      - At Nf = 5 the brake is so late that the overshoot returns to 16 %.
%      - A step setpoint asks 89.7 N at its peak; the smoothed one 10.5 N.
%
%  만드는 것 / produces: img/W02_result_noise.png, img/W02_result_kick.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 잡음 속의 네 가지 미분 / four derivatives in the same noise
CASE = {'Nf = 5', {'Nf',5}; 'Nf = 20', {'Nf',20}; 'Nf = 200', {'Nf',200}; 'pure', {'d_filtered',0}};
fprintf('\n  W02 Experiment 2-10c  1) the loop, 5 mm of noise (Kp 10, Ki 8, Kd 4)\n');
fprintf('    %-10s  force std [N]  y std [mm]  overshoot %% (no noise)\n', 'derivative');
f = lab_fig('W02 Exp 2-10c  noise', 1000, 420);  hold on;
for i = [4 3 2 1]
    N = W02_read('W02_G_noise_kick', 'noise_std', 0.005, CASE{i,2}{:});   % 잡음 있음 / with noise
    Q = W02_read('W02_G_noise_kick', CASE{i,2}{:});                       % 잡음 없음 / without
    late = N.t > 6;                        % 응답이 자리 잡은 뒤 / after the response has settled
    fprintf('    %-10s  %13.2f  %10.2f  %12.1f\n', CASE{i,1}, std(N.tau(late)), 1e3*std(N.y(late)), ...
            max(0, step_metrics(Q.t, Q.y, 1, 1)));
    plot(N.t, N.tau, 'LineWidth', 1, 'DisplayName', CASE{i,1});
end
xlim([5 10]); grid on; legend; xlabel('time [s]'); ylabel('force \tau [N]');
title('the same 5 mm of noise: the force each derivative asks for');
exportgraphics(f, fullfile(here, 'img', 'W02_result_noise.png'), 'Resolution', 150);

%% 2) 미분 킥: 계단 목표 대 부드럽게 한 목표 / the kick: a step setpoint against a smoothed one
fprintf('\n  2) the kick: step setpoint against a smoothed one (Tf = 0.3 s)\n');
fprintf('    %-10s  peak force [N]  peak D [N]\n', 'setpoint');
h = lab_fig('W02 Exp 2-10c  kick', 1000, 420);  hold on;
L = {'step', 'smoothed'};
for r = [0 1]
    K = W02_read('W02_G_noise_kick', 'ref_filter', r);   % 0 계단 그대로, 1 은 1/(0.3 s + 1)
    fprintf('    %-10s  %14.1f  %10.1f\n', L{r+1}, max(abs(K.tau)), max(abs(K.D)));
    plot(K.t, K.tau, 'LineWidth', 2, 'DisplayName', L{r+1});
end
xlim([0 6]); grid on; legend; xlabel('time [s]'); ylabel('force \tau [N]');
title('the kick belongs to the corner of the step, not to the task');
exportgraphics(h, fullfile(here, 'img', 'W02_result_kick.png'), 'Resolution', 150);
