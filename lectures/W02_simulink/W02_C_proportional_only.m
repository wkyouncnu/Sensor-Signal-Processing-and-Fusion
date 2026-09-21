%% W02 · 절 C — P 만 키운다: 빨라지지만 출렁이고, 오차가 남는다
%  W02 · Section C — proportional only: faster, more oscillatory, never exact
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_C_proportional_only
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 C 이며, §2-3 이 유도한 식을 모델에서 잰다.
%      Section C of Part 2. It measures, on the model, what §2-3 derives.
%
%  무엇을 하는가 / what it does
%      Ki = 0, Kd = 0 으로 두고 Kp 만 2, 10, 50 으로 바꾸어 세 번 돌린다. 매번
%      정상상태값, 오버슈트, 상승시간, 정착시간, 남는 오차, 그리고 제어기가 낸 가장
%      큰 힘을 잰다. 같은 줄에 §2-3 의 공식이 주는 값을 나란히 적는다.
%      Ki and Kd are held at zero and Kp is set to 2, 10 and 50 in turn. Each
%      run is measured for its steady value, overshoot, rise time, settling
%      time, remaining error and the largest force the controller asked for.
%      The value §2-3's formula predicts is printed on the same line.
%
%  결과를 읽는 법 / how to read the result
%      세 가지가 한꺼번에 일어난다. Kp 를 키우면 빨라지고, 더 출렁이고, 오차는
%      줄지만 0 이 되지 않는다. 측정값과 공식이 맞으면 모델이 강의의 식대로
%      움직인다는 뜻이다.
%      Three things happen at once: a larger Kp is faster, rings more, and
%      leaves a smaller error that never reaches zero. Agreement between the
%      measured and predicted columns says the model obeys the lecture's
%      equations.
%
%  만드는 것 / what it produces
%      표 하나, img/W02_result_P.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V   = W02_vars();
KP  = [2 10 50];
m = V.pid_m;  b = V.pid_b;  k = V.pid_k;

fprintf('\n  W02 section C — proportional control only (Ki = 0, Kd = 0)\n');
fprintf('\n    plant G(s) = 1/(%g s^2 + %g s + %g), setpoint step 0 -> %g at t = %g s\n', ...
        m, b, k, V.y_step, V.t_step);
fprintf('\n    %-6s | %-17s | %-17s | %-17s | %8s %8s | %9s\n', 'Kp', ...
        'steady value', 'overshoot [%]', 'error left', 'rise [s]', 'settle[s]', 'peak tau');
fprintf('    %-6s | %8s %8s | %8s %8s | %8s %8s | %8s %8s | %9s\n', '', ...
        'meas.', 'formula', 'meas.', 'formula', 'meas.', 'formula', '', '', '[N]');
fprintf('    %s\n', repmat('-', 1, 96));

R = cell(1, numel(KP));
for i = 1:numel(KP)
    R{i} = W02_read(run_sim('W02_pid', V, 'Kp', KP(i), 'Ki', 0, 'Kd', 0));
    t = R{i}.t;  y = R{i}.y;

    %  측정 / measured. 정상상태는 마지막 1 초의 평균 / steady value = mean of the last second
    yss = mean(y(t > V.T_final - 1));
    [Mp, ts, tr] = step_metrics(t, y, yss, V.t_step);

    %  공식 / formula (§2-3):  T(s) = Kp / (m s^2 + b s + k + Kp)
    wn   = sqrt((k + KP(i))/m);
    zeta = b/(2*sqrt(m*(k + KP(i))));
    yssF = KP(i)/(k + KP(i));
    MpF  = 100*exp(-pi*zeta/sqrt(1 - zeta^2));

    fprintf('    %-6g | %8.3f %8.3f | %8.1f %8.1f | %8.3f %8.3f | %8.3f %8.2f | %9.1f\n', ...
            KP(i), yss, yssF, Mp, MpF, V.y_step - yss, V.y_step - yssF, tr, ts, ...
            max(abs(R{i}.tau)));
    R{i}.zeta = zeta;  R{i}.wn = wn;
end

fprintf(['\n    WHAT THE TABLE SAYS.\n' ...
         '\n      Faster. The rise time falls from %.2f s to %.2f s, because the\n' ...
         '      same error now produces a larger force.\n' ...
         '\n      More oscillatory. A stiffer loop is a stiffer spring: the closed\n' ...
         '      loop has natural frequency sqrt(k + Kp) and damping b/(2 sqrt(k + Kp)),\n' ...
         '      so raising Kp raises the frequency and lowers the damping ratio,\n' ...
         '      from %.3f to %.3f. The overshoot follows the damping ratio.\n' ...
         '\n      Never exact. The spring pulls back with k y. Holding y above zero\n' ...
         '      takes a steady force, and a proportional controller makes force only\n' ...
         '      from error. Some error must remain to produce it: e_ss = k/(k + Kp).\n' ...
         '\n      The price. At the instant of the step the whole error is 1 m, so the\n' ...
         '      force jumps to Kp newtons. A gain that looks good on the response\n' ...
         '      can ask the actuator for more than it has - check the last column.\n'], ...
         step_rise(R{1}, V), step_rise(R{end}, V), ...
         R{1}.zeta, R{end}.zeta);

%% ---- figure ------------------------------------------------------------
col = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
f = lab_fig('W02 C  proportional only', 1000, 620);
subplot(2,1,1); hold on;
plot(R{1}.t, R{1}.y_d, 'k--', 'LineWidth', 1.2, 'DisplayName', 'setpoint y_d');
for i = 1:numel(KP)
    plot(R{i}.t, R{i}.y, 'Color', col(i,:), 'LineWidth', 2, ...
         'DisplayName', sprintf('K_p = %g', KP(i)));
    yline(KP(i)/(k + KP(i)), ':', 'Color', col(i,:), 'LineWidth', 1.2, 'HandleVisibility','off');
end
ylabel('position y [m]');  legend('Location','southeast');  grid on;
title({'P alone: a larger K_p is faster and rings more', ...
       'dotted: the steady value K_p/(k + K_p) predicted by §2-3 — it never reaches 1'});
subplot(2,1,2); hold on;
for i = 1:numel(KP)
    plot(R{i}.t, R{i}.tau, 'Color', col(i,:), 'LineWidth', 1.6, ...
         'DisplayName', sprintf('K_p = %g', KP(i)));
end
ylabel('force \tau [N]');  xlabel('time [s]');  legend('Location','northeast');  grid on;
title('what it cost: at the step the force jumps to K_p times the error');
exportgraphics(f, fullfile(here, 'img', 'W02_result_P.png'), 'Resolution', 150);

% -------------------------------------------------------------------------
function tr = step_rise(R, V)
yss = mean(R.y(R.t > V.T_final - 1));
[~, ~, tr] = step_metrics(R.t, R.y, yss, V.t_step);
end
