%% W02 · 절 D — D 를 더한다: 오버슛을 깎는다
%  W02 · Section D — add the derivative: the overshoot comes down
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_D_derivative
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 D 이며, §2-4 의 감쇠비 식을 모델에서 잰다.
%      Section D of Part 2. It measures the damping formula of §2-4.
%
%  무엇을 하는가 / what it does
%      Kp = 10, Ki = 0 으로 두고 Kd 만 0, 2, 6 으로 바꾼다. 미분항은 오차가 줄어드는
%      속도에 비례해 힘을 빼므로 브레이크처럼 작동한다. 폐루프의 특성다항식은
%      s^2 + (b + Kd) s + (k + Kp) 이므로 감쇠비는 (b + Kd)/(2 sqrt(k + Kp)) 이다.
%      Kp = 10 and Ki = 0 are held while Kd takes 0, 2 and 6. The derivative
%      term removes force in proportion to how fast the error is closing, so
%      it acts as a brake. The closed-loop characteristic polynomial is
%      s^2 + (b + Kd) s + (k + Kp), so the damping ratio is (b + Kd)/(2 sqrt(k + Kp)).
%
%  결과를 읽는 법 / how to read the result
%      오버슛과 정착시간이 함께 줄고, 남는 오차는 그대로이다. 미분항은 정상상태에서
%      0 이므로 남는 오차에 손대지 못한다. 감쇠비가 1 을 넘는 Kd = 6 에서도 오버슛이
%      남는 것은 오차를 미분할 때 생기는 영점 때문이다 (§2-4).
%      Overshoot and settling time fall together; the remaining error does not
%      move, because the derivative term is zero in steady state. That some
%      overshoot remains at Kd = 6, where the damping ratio exceeds 1, is the
%      work of the zero that differentiating the error introduces (§2-4).
%
%  만드는 것 / what it produces
%      표 하나, img/W02_result_D.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V  = W02_vars();
KD = [0 2 6];
Kp = 10;
m = V.pid_m;  b = V.pid_b;  k = V.pid_k;

fprintf('\n  W02 section D — add the derivative (Kp = %g, Ki = 0, Nf = %g)\n', Kp, V.Nf);
fprintf('\n    %-5s %9s %13s %11s %11s %12s %14s\n', 'Kd', 'zeta', 'zero at', ...
        'overshoot', 'settle [s]', 'error left', 'peak tau [N]');
fprintf('    %-5s %9s %13s %11s %11s %12s %14s\n', '', '(§2-4)', '-Kp/Kd', '[%]', '', '', '');
fprintf('    %s\n', repmat('-', 1, 80));

R = cell(1, numel(KD));
for i = 1:numel(KD)
    R{i} = W02_read(run_sim('W02_pid', V, 'Kp', Kp, 'Ki', 0, 'Kd', KD(i)));
    t = R{i}.t;  y = R{i}.y;
    yss = mean(y(t > V.T_final - 1));
    [Mp, ts] = step_metrics(t, y, yss, V.t_step);
    zeta = (b + KD(i))/(2*sqrt(m*(k + Kp)));
    if KD(i) > 0, z = sprintf('%.2f', -Kp/KD(i)); else, z = 'none'; end
    fprintf('    %-5g %9.3f %13s %11.1f %11.2f %12.3f %14.1f\n', KD(i), zeta, z, Mp, ts, ...
            V.y_step - yss, max(abs(R{i}.tau)));
    R{i}.Mp = Mp;
end

%  이상 미분일 때의 오버슛 — 영점의 효과를 필터와 떼어 보이기 위해
%  The overshoot with an ideal derivative, to separate the zero's effect from the filter's
st  = tf('s');
Tid = feedback((Kp + KD(end)*st)/(m*st^2 + b*st + k), 1);
yid = step(Tid, (0:1e-3:10)');
Mid = 100*(max(yid) - yid(end))/yid(end);

fprintf(['\n    WHAT THE TABLE SAYS.\n' ...
         '\n      The derivative is a brake. While the position is rising towards the\n' ...
         '      setpoint the error is shrinking, its rate is negative, and the\n' ...
         '      derivative term takes force away before the setpoint is reached.\n' ...
         '      The overshoot falls from %.1f %% to %.1f %%.\n' ...
         '\n      The error left is untouched. In steady state nothing is changing,\n' ...
         '      the derivative of the error is zero, and so is its contribution.\n' ...
         '\n      A damping ratio above 1 still overshoots. With Kd = 6 and an ideal\n' ...
         '      derivative the closed-loop poles are real, at -2 and -6, and would\n' ...
         '      give no overshoot on their own. But differentiating the error adds a\n' ...
         '      zero at -Kp/Kd = -1.67, closer to the origin than either pole, and\n' ...
         '      such a zero lifts the early response past its final value: %.2f %%\n' ...
         '      for the ideal law, %.1f %% measured here with the filter.\n' ...
         '\n      The peak force grows with Kd. At the step the error jumps, the\n' ...
         '      filtered derivative of a jump is Kd Nf times its height, and that\n' ...
         '      spike is the "derivative kick" of section G.\n'], ...
         R{1}.Mp, R{end}.Mp, Mid, R{end}.Mp);

%% ---- figure ------------------------------------------------------------
col = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
f = lab_fig('W02 D  derivative', 1000, 620);
subplot(2,1,1); hold on;
plot(R{1}.t, R{1}.y_d, 'k--', 'LineWidth', 1.2, 'DisplayName', 'setpoint y_d');
for i = 1:numel(KD)
    plot(R{i}.t, R{i}.y, 'Color', col(i,:), 'LineWidth', 2, ...
         'DisplayName', sprintf('K_d = %g', KD(i)));
end
yline(Kp/(k + Kp), ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, 'HandleVisibility','off');
ylabel('position y [m]');  legend('Location','southeast');  grid on;
title({'K_p = 10: more K_d, less overshoot', ...
       'dotted: K_p/(k + K_p) = 0.833 — the derivative does not touch the error left'});
subplot(2,1,2); hold on;
for i = numel(KD):-1:1
    plot(R{i}.t, R{i}.D, 'Color', col(i,:), 'LineWidth', 1.6, ...
         'DisplayName', sprintf('K_d = %g', KD(i)));
end
xlim([V.t_step - 0.2, V.t_step + 3]);
ylabel('derivative term D [N]');  xlabel('time [s]');  legend('Location','northeast');  grid on;
title('the brake: negative while the error is closing, zero once it stops changing');
exportgraphics(f, fullfile(here, 'img', 'W02_result_D.png'), 'Resolution', 150);
