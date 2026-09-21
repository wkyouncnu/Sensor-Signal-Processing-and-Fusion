%% W02 · 절 E — I 를 더한다: 남는 오차를 시간이 메운다. 그리고 그 한계
%  W02 · Section E — add the integral: time removes the error. And its limit
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_E_integral
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 E 이며, §2-5 의 두 결론을 잰다. 적분항이 있으면 남는 오차가 0 이
%      된다는 것(최종값 정리), 그리고 Ki 를 너무 키우면 루프가 불안정해진다는 것
%      (Routh 판정).
%      Section E of Part 2. It measures the two conclusions of §2-5: with an
%      integral term the remaining error goes to zero (final value theorem),
%      and too large a Ki makes the loop unstable (Routh criterion).
%
%  무엇을 하는가 / what it does
%      1) Kp = 10, Kd = 4 로 두고 Ki 를 0, 4, 12 로 바꾼다.
%         Kp = 10 and Kd = 4 are held while Ki takes 0, 4 and 12.
%      2) Ki 의 안정 한계를 두 가지로 구한다. 이상 미분이면 Routh 판정이
%         Ki < (b + Kd)(k + Kp) = 72 를 준다. 모델은 거른 미분을 쓰므로 한계가
%         조금 다르며, 폐루프 극점의 실수부가 0 을 지나는 Ki 를 이분법으로 찾는다.
%         그 한계의 0.9 배와 1.1 배로 모델을 돌려 진동이 줄어드는지 커지는지 본다.
%         The stability limit on Ki is found two ways. With an ideal derivative
%         the Routh criterion gives Ki < (b + Kd)(k + Kp) = 72. The model uses
%         the filtered derivative, which moves the limit slightly, so the Ki at
%         which a closed-loop pole crosses the imaginary axis is found by
%         bisection. The model is then run at 0.9 and 1.1 times that limit to
%         see whether the oscillation dies or grows.
%
%  만드는 것 / what it produces
%      표 둘, img/W02_result_I.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V  = W02_vars();
KI = [0 4 12];
Kp = 10;  Kd = 4;
m = V.pid_m;  b = V.pid_b;  k = V.pid_k;

fprintf('\n  W02 section E — add the integral (Kp = %g, Kd = %g, Nf = %g)\n', Kp, Kd, V.Nf);
fprintf('\n  1) three values of Ki\n\n');
fprintf('    %-5s %13s %11s %11s %14s %14s\n', 'Ki', 'steady value', 'overshoot', ...
        'settle [s]', 'error left', 'I at the end');
fprintf('    %-5s %13s %11s %11s %14s %14s\n', '', '', '[%]', '', '[m]', '[N]');
fprintf('    %s\n', repmat('-', 1, 74));
R = cell(1, numel(KI));
for i = 1:numel(KI)
    R{i} = W02_read(run_sim('W02_pid', V, 'Kp', Kp, 'Ki', KI(i), 'Kd', Kd));
    t = R{i}.t;  y = R{i}.y;
    %  오버슛과 정착은 t = 10 s 에 도달한 값에 대고 잰다. Ki = 0 이면 1 에 닿지
    %  않으므로, 1 에 대고 재면 "음의 오버슛" 이라는 뜻 없는 수가 나온다.
    %  Overshoot and settling are measured against the value reached at
    %  t = 10 s. With Ki = 0 the response never reaches 1, and measuring
    %  against 1 would report a meaningless negative overshoot.
    yss = y(end);
    [Mp, ts] = step_metrics(t, y, yss, V.t_step);
    fprintf('    %-5g %13.4f %11.1f %11.2f %14.2e %14.3f\n', KI(i), yss, Mp, ts, ...
            V.y_step - yss, R{i}.I(end));
    R{i}.ts = ts;
end
fprintf(['\n    The integral stops changing only when its input, the error, is zero.\n' ...
         '    Where it stops is therefore the force that holds y = 1 against the\n' ...
         '    spring: k y = %g N. Read the last column - the integral has found\n' ...
         '    that force on its own. Nobody told the controller what k is.\n'], k*V.y_step);

%% ---- 2) the stability limit on Ki -------------------------------------
s    = tf('s');
G    = 1/(m*s^2 + b*s + k);
Cid  = @(ki) Kp + ki/s + Kd*s;                          % ideal derivative
Cfl  = @(ki) Kp + ki/s + Kd*V.Nf*s/(s + V.Nf);          % the model's filtered derivative
KiR  = (b + Kd)*(k + Kp)/m;                             % Routh, ideal derivative
KiI  = bisect(@(ki) max(real(pole(feedback(Cid(ki)*G, 1)))));
KiF  = bisect(@(ki) max(real(pole(feedback(Cfl(ki)*G, 1)))));
wX   = sqrt((k + Kp)/m);                                % crossing frequency, ideal

fprintf('\n  2) how large can Ki be?\n\n');
fprintf('    ideal derivative, Routh:  Ki < (b + Kd)(k + Kp)/m = %.2f\n', KiR);
fprintf('    ideal derivative, poles:  crossing found at  Ki = %.2f\n', KiI);
fprintf('    filtered derivative (the model, Nf = %g):  Ki = %.2f\n', V.Nf, KiF);
pF = pole(feedback(Cfl(KiF)*G, 1));  wF = max(abs(imag(pF(abs(real(pF)) < 1e-6))));
fprintf(['    ideal: at the limit the loop oscillates at sqrt((k + Kp)/m) = %.3f rad/s\n' ...
         '    model: at its limit the loop oscillates at %.3f rad/s, period %.2f s\n'], ...
        wX, wF, 2*pi/wF);
fprintf(['\n    The derivative filter adds a pole to the loop, so the Routh number for\n' ...
         '    the ideal controller is not the limit of the controller actually built.\n' ...
         '    The limit that matters is the one computed for the implemented law,\n' ...
         '    and it is the one used below.\n']);

T2 = 40;                                                % long enough to see growth
Rlo = W02_read(run_sim('W02_pid', V, 'Kp',Kp, 'Kd',Kd, 'Ki',0.9*KiF, 'T_final',T2));
Rhi = W02_read(run_sim('W02_pid', V, 'Kp',Kp, 'Kd',Kd, 'Ki',1.1*KiF, 'T_final',T2));
e1  = @(R, a, z) max(abs(R.y(R.t >= a & R.t < z) - V.y_step));
fprintf('\n    %-22s %22s %22s\n', 'run', 'largest error 10-20 s', 'largest error 30-40 s');
fprintf('    %-22s %22.3f %22.3f\n', sprintf('Ki = 0.9 x %.1f', KiF), e1(Rlo,10,20), e1(Rlo,30,40));
fprintf('    %-22s %22.3f %22.3f\n', sprintf('Ki = 1.1 x %.1f', KiF), e1(Rhi,10,20), e1(Rhi,30,40));
fprintf(['\n    Below the limit the oscillation shrinks; above it the same oscillation\n' ...
         '    grows. The integral that removed the error in part 1 is the same term\n' ...
         '    that destabilises the loop here: it acts late, and a large enough\n' ...
         '    late push arrives in phase with the swing it was meant to correct.\n']);

%% ---- figure ------------------------------------------------------------
col = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
f = lab_fig('W02 E  integral', 1100, 700);
subplot(2,2,[1 2]); hold on;
plot(R{1}.t, R{1}.y_d, 'k--', 'LineWidth', 1.2, 'DisplayName', 'setpoint y_d');
for i = 1:numel(KI)
    plot(R{i}.t, R{i}.y, 'Color', col(i,:), 'LineWidth', 2, ...
         'DisplayName', sprintf('K_i = %g', KI(i)));
end
ylabel('position y [m]');  xlabel('time [s]');  legend('Location','southeast');  grid on;
ylim([0 1.15]);
title({'K_p = 10, K_d = 4: the integral removes the error that P and D leave', ...
       'K_i = 4 gets there slowly; K_i = 12 gets there fast and overshoots again'});
subplot(2,2,3); hold on;
for i = 2:numel(KI)
    plot(R{i}.t, R{i}.I, 'Color', col(i,:), 'LineWidth', 2, ...
         'DisplayName', sprintf('K_i = %g', KI(i)));
end
yline(k*V.y_step, 'k:', 'k y_d = 2 N', 'LineWidth', 1.2, 'HandleVisibility','off');
ylabel('integral term I [N]');  xlabel('time [s]');  legend('Location','southeast');  grid on;
title('the integral settles on the force the spring needs');
subplot(2,2,4); hold on;
plot(Rlo.t, Rlo.y, 'Color', [0 0.45 0.74], 'LineWidth', 1.4, ...
     'DisplayName', sprintf('K_i = %.0f  (0.9 x limit)', 0.9*KiF));
plot(Rhi.t, Rhi.y, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.4, ...
     'DisplayName', sprintf('K_i = %.0f  (1.1 x limit)', 1.1*KiF));
ylabel('position y [m]');  xlabel('time [s]');  legend('Location','northwest');  grid on;
ylim([-4 6]);
title(sprintf('either side of the stability limit K_i = %.1f', KiF));
exportgraphics(f, fullfile(here, 'img', 'W02_result_I.png'), 'Resolution', 150);

% -------------------------------------------------------------------------
function ki = bisect(g)
%  g(ki) 는 가장 오른쪽 극점의 실수부. 0 을 지나는 ki 를 찾는다.
%  g(ki) is the real part of the rightmost pole; find where it crosses zero.
lo = 1;  hi = 1000;
for it = 1:80
    ki = (lo + hi)/2;
    if g(ki) < 0, lo = ki; else, hi = ki; end
end
end
