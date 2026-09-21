%% W02 · 절 H — 액추에이터에는 한계가 있고, 적분기는 그것을 모른다
%  W02 · Section H — the actuator has a limit, and the integrator does not know it
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_H_windup
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 H 이며, §2-8 의 와인드업과 되감기(back-calculation)를 잰다.
%      3주차 §3-6 이 같은 문제를 Otter 위에서 세 가지 방식으로 자세히 다룬다.
%      Section H of Part 2. It measures the windup and back-calculation of
%      §2-8. Week 3 §3-6 treats the same problem on the Otter, three schemes
%      in full.
%
%  무엇을 하는가 / what it does
%      힘을 |tau| <= 2.5 N 으로 제한한다. y = 1 을 붙잡는 데 필요한 힘은 k y = 2 N
%      이므로 목표는 도달할 수 있다. 다만 올라가는 동안 제어기는 한계보다 큰 힘을
%      요구하고, 그동안 적분기는 한계를 모른 채 계속 쌓는다. 되감기 이득 Kb 를 0 과
%      2 로 두고 두 번 돌린다.
%      The force is limited to |tau| <= 2.5 N. Holding y = 1 needs k y = 2 N,
%      so the target is reachable; but on the way up the controller asks for
%      more than the limit, and meanwhile the integrator keeps accumulating
%      without knowing about it. The run is made with back-calculation gain
%      Kb = 0 and Kb = 2.
%
%  결과를 읽는 법 / how to read the result
%      Kb = 0 이면 목표에 도달한 순간에도 적분기에 쌓인 값이 계속 밀어붙여 크게
%      지나친다. Kb = 2 이면 잘려 나간 만큼이 적분기로 되돌아간다. 포화 중에 적분기는
%      요구가 한계와 같아지는 값 I* = tau_max - P - D + (Ki/Kb) e 로 끌려가는데,
%      계단 직후에는 P 와 D 만으로 이미 한계를 넘으므로 I* 가 음수이다. 적분기가
%      음수로 내려가는 것은 오류가 아니라 이 식 그대로이다.
%      With Kb = 0 the charge stored in the integrator keeps pushing after the
%      target is reached, and the response overshoots a long way. With Kb = 2
%      the part that was cut off is fed back: while saturated the integrator is
%      pulled towards I* = tau_max - P - D + (Ki/Kb) e, the value that makes
%      the demand equal to the limit. Just after the step P and D alone exceed
%      the limit, so I* is negative; the integrator dipping below zero is that
%      formula, not a fault.
%
%  만드는 것 / what it produces
%      표 하나, img/W02_result_windup.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V  = W02_vars();
V.tau_max = 2.5;
KB = [0 2];
LBL = {'Kb = 0   no anti-windup', 'Kb = 2   back-calculation'};

fprintf('\n  W02 section H — saturation and windup (|tau| <= %g N; holding y = 1 takes %g N)\n', ...
        V.tau_max, V.pid_k*V.y_step);
fprintf('\n    %-28s %11s %14s %11s %11s %11s %13s\n', 'anti-windup', 'peak y [m]', ...
        'overshoot [%]', 'settle [s]', 'I max [N]', 'I min [N]', 'on limit [s]');
fprintf('    %s\n', repmat('-', 1, 106));
R = cell(1,2);
for i = 1:2
    R{i} = W02_read(run_sim('W02_pid', V, 'Kb', KB(i)));
    [Mp, ts] = step_metrics(R{i}.t, R{i}.y, V.y_step, V.t_step);
    onl = sum(abs(abs(R{i}.tau) - V.tau_max) < 1e-9) * V.h;
    fprintf('    %-28s %11.3f %14.2f %11.2f %11.2f %11.2f %13.2f\n', LBL{i}, max(R{i}.y), ...
            Mp, ts, max(R{i}.I), min(R{i}.I), onl);
    R{i}.Mp = Mp;  R{i}.ts = ts;  R{i}.onl = onl;
end
fprintf(['\n    WHAT THE TABLE SAYS.\n' ...
         '\n      Without anti-windup the integrator climbs to %.2f N while the actuator\n' ...
         '      can give %g N. That excess has to be unwound by NEGATIVE error, which\n' ...
         '      means overshooting the target: %.1f %%, and %.2f s on the limit.\n' ...
         '\n      With back-calculation the integrator does more than stop. While the\n' ...
         '      actuator is saturated it is driven towards the value that makes the\n' ...
         '      demand equal to the limit,\n' ...
         '\n          I* = tau_max - P - D + (Ki/Kb) e ,\n' ...
         '\n      and just after the step P and D alone already ask for far more than\n' ...
         '      %g N, so I* is NEGATIVE: the integrator dips to %.2f N. It gives the\n' ...
         '      actuator back as soon as the demand falls inside the limit - %.2f s on\n' ...
         '      the limit instead of %.2f s - and the overshoot is %.2f %%.\n' ...
         '\n      Nothing about the linear controller was changed: the gains are\n' ...
         '      identical. Only what the integrator does while the actuator is\n' ...
         '      saturated. Week 3 §3-6 derives I* and compares three schemes.\n'], ...
         max(R{1}.I), V.tau_max, R{1}.Mp, R{1}.onl, V.tau_max, min(R{2}.I), ...
         R{2}.onl, R{1}.onl, R{2}.Mp);

%% ---- figure ------------------------------------------------------------
col = [0.85 0.33 0.10; 0 0.45 0.74];
f = lab_fig('W02 H  windup', 1000, 720);
subplot(3,1,1); hold on;
plot(R{1}.t, R{1}.y_d, 'k--', 'LineWidth', 1.1, 'DisplayName', 'setpoint');
for i = 1:2
    plot(R{i}.t, R{i}.y, 'Color', col(i,:), 'LineWidth', 2, 'DisplayName', LBL{i});
end
ylabel('position [m]');  legend('Location','southeast');  grid on;
title('same gains, same limit: only what the integrator does while saturated differs');
subplot(3,1,2); hold on;
for i = 1:2
    plot(R{i}.t, R{i}.tau, 'Color', col(i,:), 'LineWidth', 2, 'DisplayName', LBL{i});
end
yline([-1 1]*V.tau_max, 'k:', 'HandleVisibility','off');
ylabel('force \tau [N]');  legend('Location','southeast');  grid on;
title(sprintf('the actuator gives at most %g N; dotted lines are the limit', V.tau_max));
subplot(3,1,3); hold on;
for i = 1:2
    plot(R{i}.t, R{i}.I, 'Color', col(i,:), 'LineWidth', 2, 'DisplayName', LBL{i});
end
yline(V.tau_max, 'k:', 'the limit, 2.5 N', 'LabelHorizontalAlignment','left', ...
      'LabelVerticalAlignment','top', 'HandleVisibility','off');
yline(V.pid_k*V.y_step, 'k-.', 'k y_d = 2 N', 'LabelHorizontalAlignment','left', ...
      'LabelVerticalAlignment','bottom', 'HandleVisibility','off');
ylabel('integral term I [N]');  xlabel('time [s]');  legend('Location','northeast');  grid on;
title('the integrator: wound up past the limit, or pulled below it by the excess');
exportgraphics(f, fullfile(here, 'img', 'W02_result_windup.png'), 'Resolution', 150);
