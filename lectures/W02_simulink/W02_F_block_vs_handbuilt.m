%% W02 · 절 F — 손으로 만든 PID 와 Simulink PID 블록 / Section F — hand-built PID vs the PID block
%  모델 W02_F_block_vs_hand 는 같은 법칙을 두 줄로 돌린다(위: 블록 하나하나로, 아래: 라이브러리 PID 블록).
%  힘 한계 2.5 N 과 5 mm 잡음을 넣고 두 줄의 차이를 잰다. 대조 실험으로 블록의 필터 계수만 20 -> 19 로 바꾼다.
%  W02_F_block_vs_hand runs the same law twice: built from blocks (top) and the library PID block (bottom).
%  With a 2.5 N limit and 5 mm of noise the two rows are compared; as a control, only the block's
%  filter coefficient is changed from 20 to 19.
%  만드는 것 / produces: img/W02_result_block.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
A = {'tau_max', 2.5, 'noise_std', 0.005};
R  = W02_read('W02_F_block_vs_hand', A{:});
Rc = W02_read('W02_F_block_vs_hand', A{:}, 'Nf_blk', 19);

fprintf('\n  W02 F  hand-built law against the PID block (|tau| <= 2.5 N, 5 mm noise)\n');
fprintf('    %-36s %14s %16s\n', 'comparison', 'max |y diff|', 'max |tau diff|');
fprintf('    %-36s %14.2e %16.2e\n', 'hand-built vs PID block', max(abs(R.y - R.y_blk)), max(abs(R.tau - R.tau_blk)));
fprintf('    %-36s %14.2e %16.2e\n', 'control: block with Nf = 19', max(abs(Rc.y - Rc.y_blk)), max(abs(Rc.tau - Rc.tau_blk)));

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
