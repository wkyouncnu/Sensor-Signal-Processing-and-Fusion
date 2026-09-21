%% W02 · 절 F — 손으로 만든 PID 와 Simulink PID 블록 / Section F — hand-built PID vs the PID block
%
%  이 절이 묻는 것 / the question
%      Simulink 의 PID Controller 블록은 블록 하나하나로 만든 PID 와 정말 같은가?
%      Is Simulink's PID Controller block really the same as a PID built from
%      ordinary blocks?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W02_F_block_vs_hand 는 같은 법칙을 두 줄로 돌린다
%         (위: 블록 하나하나로, 아래: 라이브러리 PID 블록). 힘 한계 2.5 N, 센서 잡음 5 mm.
%      ② 두 줄의 위치 차이와 힘 차이의 최댓값을 찍는다.
%      ③ 대조 실험: 블록의 필터 계수만 20 -> 19 로 바꿔 같은 비교를 한다.
%      ① W02_F_block_vs_hand runs the same law twice: from blocks (top) and the
%         library PID block (bottom), with a 2.5 N limit and 5 mm sensor noise.
%      ② Prints the largest difference in position and in force.
%      ③ Control run: only the block's filter coefficient changed, 20 -> 19.
%
%  출력에서 볼 것 / what to look for in the output
%      - 차이가 1e-15 수준: 반올림 오차뿐이다. 두 줄은 같은 법칙이다.
%      - 대조 실험에서는 1e-3 m 로 곧바로 드러난다: 비교가 눈먼 것이 아님을 보인다.
%      - The difference is about 1e-15: round-off only. The two rows are one law.
%      - The control run shows 1e-3 m at once: the comparison is not blind.
%
%  만드는 것 / produces: img/W02_result_block.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 두 번 돌린다: 그대로, 그리고 블록의 필터 계수만 19 로
%     Two runs: as built, and with only the block's filter coefficient at 19
A = {'tau_max', 2.5, 'noise_std', 0.005};                    % 힘 한계와 잡음 / force limit and noise
R  = W02_read('W02_F_block_vs_hand', A{:});
Rc = W02_read('W02_F_block_vs_hand', A{:}, 'Nf_blk', 19);

%% 2) 차이를 찍는다 / print the differences
%  R.y, R.tau = 손으로 만든 줄 / hand-built row;  R.y_blk, R.tau_blk = PID 블록 줄 / PID block row
fprintf('\n  W02 F  hand-built law against the PID block (|tau| <= 2.5 N, 5 mm noise)\n');
fprintf('    %-36s %14s %16s\n', 'comparison', 'max |y diff|', 'max |tau diff|');
fprintf('    %-36s %14.2e %16.2e\n', 'hand-built vs PID block', max(abs(R.y - R.y_blk)), max(abs(R.tau - R.tau_blk)));
fprintf('    %-36s %14.2e %16.2e\n', 'control: block with Nf = 19', max(abs(Rc.y - Rc.y_blk)), max(abs(Rc.tau - Rc.tau_blk)));

%% 3) 그림: 위치, 힘, 차이 / figure: position, force, difference
f = lab_fig('W02 F  block vs hand', 1000, 700);
subplot(3,1,1); hold on;
plot(R.t, R.y_blk, 'Color', [0.75 0.75 0.75], 'LineWidth', 5, 'DisplayName', 'PID block');
plot(R.t, R.y, 'Color', [0 0.45 0.74], 'LineWidth', 1.4, 'DisplayName', 'hand-built');
ylabel('position [m]'); legend('Location','southeast'); grid on; title('the two rows lie on top of each other');
subplot(3,1,2); hold on;
plot(R.t, R.tau_blk, 'Color', [0.75 0.75 0.75], 'LineWidth', 5, 'DisplayName', 'PID block');
plot(R.t, R.tau, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.1, 'DisplayName', 'hand-built');
ylabel('force \tau [N]'); legend('Location','southeast'); grid on; title('with the force limited to 2.5 N and a noisy sensor');
subplot(3,1,3); hold on;
plot(Rc.t, Rc.y - Rc.y_blk, 'Color', [0.49 0.18 0.56], 'LineWidth', 1.2, 'DisplayName', 'control: block with N_f = 19');
plot(R.t, R.y - R.y_blk, 'Color', [0 0.45 0.74], 'LineWidth', 2, 'DisplayName', 'hand-built minus block');
ylabel('difference in y [m]'); xlabel('time [s]'); legend; grid on;
title('the difference: at round-off level, while a 5 % change in one number shows at once');
exportgraphics(f, fullfile(here, 'img', 'W02_result_block.png'), 'Resolution', 150);
