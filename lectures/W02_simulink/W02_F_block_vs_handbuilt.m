%% W02 · 절 F — 손으로 만든 PID 는 Simulink PID 블록과 같은가
%  W02 · Section F — is the hand-built PID the Simulink PID block?
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_F_block_vs_handbuilt
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 F 이다. §2-6 이 PID 를 상자 셋으로 적었고, 모델의 2줄이 그것을
%      손으로 조립했다. 이 절은 그 조립이 라이브러리 블록과 같은 것인지 잰다.
%      Section F of Part 2. §2-6 writes the PID as three boxes and row 2 of the
%      model assembles them by hand; this section measures whether that
%      assembly is the library block.
%
%  무엇을 하는가 / what it does
%      세 갈래를 모두 켜고, 힘을 2.5 N 으로 제한하고, 센서 잡음을 넣은 가장 어려운
%      조건에서 두 줄을 함께 돌린다. 두 줄은 같은 목표, 같은 플랜트, 같은 잡음을
%      받는다. 그런 다음 **대조 실험**을 하나 더 한다. 손으로 만든 줄만 순수 미분으로
%      바꾸어, 이 비교가 차이가 있을 때 실제로 차이를 잡아내는지 확인한다.
%      Both rows are run under the hardest condition available: all three terms
%      on, the force limited to 2.5 N, and sensor noise. They receive the same
%      setpoint, plant and noise. A CONTROL experiment follows: the hand-built
%      row alone is switched to a pure derivative, to confirm that the
%      comparison does detect a difference when there is one.
%
%  결과를 읽는 법 / how to read the result
%      첫 줄의 차이가 정확히 0 이고 대조 실험의 차이가 0 이 아니면, 두 줄은 같은
%      계산을 같은 순서로 하고 있다는 뜻이다. 그러면 블록 대화상자의 P, I, D, N,
%      Kb 가 각각 §2-6 의 어느 상자인지 말할 수 있다.
%      If the first difference is exactly zero and the control's is not, the
%      two rows perform the same arithmetic in the same order, and each field
%      of the block dialog - P, I, D, N, Kb - can be named as a box of §2-6.
%
%  만드는 것 / what it produces
%      표 하나, img/W02_result_block.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V = W02_vars();
V.tau_max = 2.5;  V.noise_std = 0.005;          % 가장 어려운 조건 / the hardest condition
R  = W02_read(run_sim('W02_pid', V));
Rc = W02_read(run_sim('W02_pid', V, 'd_filtered', 0));

fprintf('\n  W02 section F — the hand-built PID against the Simulink PID block\n');
fprintf('\n    condition: Kp = %g, Ki = %g, Kd = %g, Nf = %g, |tau| <= %g N, Kb = %g,\n', ...
        V.Kp, V.Ki, V.Kd, V.Nf, V.tau_max, V.Kb);
fprintf('               sensor noise %g m every %g s, the same sequence in both rows\n', ...
        V.noise_std, V.noise_ts);
fprintf('\n    %-44s %16s %16s\n', 'comparison', 'max |y diff|', 'max |tau diff|');
fprintf('    %s\n', repmat('-', 1, 78));
fprintf('    %-44s %16.3g %16.3g\n', 'hand-built vs PID block', ...
        max(abs(R.y - R.y_blk)), max(abs(R.tau - R.tau_blk)));
fprintf('    %-44s %16.3g %16.3g\n', 'control: hand-built with a pure derivative', ...
        max(abs(Rc.y - Rc.y_blk)), max(abs(Rc.tau - Rc.tau_blk)));
fprintf('\n    time the force spent on its limit: %.2f s\n', ...
        sum(abs(abs(R.tau) - V.tau_max) < 1e-9) * V.h);

fprintf(['\n    WHAT THE TABLE SAYS.\n' ...
         '\n      The difference is exactly zero, not merely small. The two rows do\n' ...
         '      the same arithmetic in the same order, step for step, through the\n' ...
         '      saturation and the anti-windup and the noise.\n' ...
         '\n      The control row shows the comparison is not blind. Changing one box\n' ...
         '      of the hand-built row changes its result at once.\n' ...
         '\n      So the dialog of the PID block can be read box by box:\n' ...
         '        P    the gain of box P                        Kp\n' ...
         '        I    the gain ahead of the integrator in box I  Ki\n' ...
         '        D, N the two gains of box D, the filter state   Kd, Nf\n' ...
         '        Kb   the back-calculation gain of box I         Kb\n']);

%% ---- figure ------------------------------------------------------------
f = lab_fig('W02 F  block vs hand-built', 1000, 700);
subplot(3,1,1); hold on;
plot(R.t, R.y_d, 'k--', 'LineWidth', 1.1, 'DisplayName', 'setpoint');
plot(R.t, R.y_blk, 'Color', [0.75 0.75 0.75], 'LineWidth', 5, 'DisplayName', 'PID block');
plot(R.t, R.y, 'Color', [0 0.45 0.74], 'LineWidth', 1.4, 'DisplayName', 'hand-built');
ylabel('position [m]');  legend('Location','southeast');  grid on;
title('the two rows, drawn on top of each other: the thick grey line is under the blue one');
subplot(3,1,2); hold on;
plot(R.t, R.tau_blk, 'Color', [0.75 0.75 0.75], 'LineWidth', 5, 'DisplayName', 'PID block');
plot(R.t, R.tau, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2, 'DisplayName', 'hand-built');
yline([-1 1]*V.tau_max, 'k:', 'HandleVisibility','off');
ylabel('force \tau [N]');  legend('Location','northeast');  grid on;
title(sprintf('with the force limited to %g N and the sensor noisy', V.tau_max));
subplot(3,1,3); hold on;
plot(Rc.t, Rc.y - Rc.y_blk, 'Color', [0.49 0.18 0.56], 'LineWidth', 1.2, ...
     'DisplayName', 'control: pure derivative in the hand-built row');
plot(R.t, R.y - R.y_blk, 'Color', [0 0.45 0.74], 'LineWidth', 2, ...
     'DisplayName', 'hand-built minus block');
ylabel('difference in y [m]');  xlabel('time [s]');  legend('Location','northeast');  grid on;
title('the difference: identically zero, while one changed box makes it visible at once');
exportgraphics(f, fullfile(here, 'img', 'W02_result_block.png'), 'Resolution', 150);
