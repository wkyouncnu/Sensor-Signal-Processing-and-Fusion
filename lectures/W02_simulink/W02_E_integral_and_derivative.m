%% W02 · 절 E — 적분 동작, 그리고 미분항이 실제로 놓이는 자리
%  W02 · Section E — integral action, and where the derivative term goes
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_E_integral_and_derivative
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 E 이며 §2-3 과 §2-4 를 함께 받는다. §2-3 은 감쇠비와 고유
%      진동수로 PI 게인을 정하는 법을 유도했고, §2-4 는 미분항이 이 축에서
%      감쇠가 아니라 질량으로 작용함을 보였다. 두 주장을 차례로 확인한다.
%
%      This is section E of Part 2 and it answers both §2-3, which designed
%      the PI gains from a damping ratio and a natural frequency, and §2-4,
%      which showed that on this axis the derivative term acts as a mass
%      rather than as a damper.
%
%  두 개의 실험 / the two experiments
%      E-1  적분 동작을 넣어 정상상태 오차가 사라지는 것을 확인하고, 동시에
%           아무도 배치하지 않은 영점이 오버슛을 얼마나 올리는지 잰다.
%      E-2  미분게인을 넷으로 바꾸어 가며, 이 축에서는 미분이 오히려 감쇠비를
%           떨어뜨린다는 것을 확인한다.
%
%      E-1  add integral action, confirm that the steady-state error is
%           removed, and measure how much overshoot the zero that nobody
%           placed contributes.
%      E-2  sweep four derivative gains and confirm that on this axis
%           derivative action lowers the damping ratio instead of raising it.
%
%  만드는 것 / what it produces
%      img/W02_result_PI.png   PI 설계와, 아무도 배치하지 않은 영점
%                              the PI design, and the zero nobody placed
%      img/W02_result_D.png    미분 동작이 오히려 나쁘게 만드는 모습
%                              derivative action making the response worse

clear RI RD KDS LD i te Td s Gp Tcl S pcl
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W02_surge_control.slx')), W02_1_build_surge_control; end

V = W02_vars;
c = W02_cols;

%% =====================================================================
%  E-1  PI, designed for zeta = 0.7 and wn = 1.5 rad/s
%  =====================================================================
RI = run_sim('W02_surge_control', V, ...
             'Kp', V.Kp_d, 'Ki', V.Ki_d, 'Kd', 0, 'T_final', 30);
[Mp, ts] = step_metrics(RI.t, RI.y(:, c.u), V.u_d1, V.t_up);

%  The same design as a linear model, so the two predictions can be compared.
s   = tf('s');
Gp  = V.K_u/(V.T_u*s + 1);
Tcl = feedback((V.Kp_d + V.Ki_d/s)*Gp, 1);
S   = stepinfo(Tcl);
pcl = pole(Tcl);
Mp_pole = 100*exp(-pi*V.zeta_d/sqrt(1 - V.zeta_d^2));   % poles only

fprintf('\n  W02 section E — PI for zeta = %.2f, wn = %.2f rad/s\n\n', V.zeta_d, V.wn_d);
fprintf('    Kp = %.2f    Ki = %.2f    zero at s = %.4f\n\n', ...
        V.Kp_d, V.Ki_d, -V.Ki_d/V.Kp_d);
fprintf('    %-38s %12s %12s\n', 'source', 'overshoot [%]', 'ts 2% [s]');
fprintf('    %s\n', repmat('-', 1, 66));
fprintf('    %-38s %12.2f %12.2f\n', 'poles only, exp(-pi z/sqrt(1-z^2))', ...
        Mp_pole, 4/(V.zeta_d*V.wn_d));
fprintf('    %-38s %12.2f %12.2f\n', 'linear model INCLUDING the PI zero', ...
        S.Overshoot, S.SettlingTime);
fprintf('    %-38s %12.2f %12.2f\n', 'the 12-state plant', Mp, ts);
fprintf(['\n    THE INTEGRATOR REMOVES THE ERROR THAT SECTION D COULD NOT.\n' ...
         '\n      At t = %g s the remaining error is %.3e m/s, which is zero to\n' ...
         '      the precision of the solver. The integrator holds a steady force\n' ...
         '      while its input is zero, so the loop can supply the force the\n' ...
         '      damping demands without holding an error to generate it.\n' ...
         '\n    THE TABULATED OVERSHOOT FOR zeta = 0.7 DOES NOT APPLY, AND THE\n' ...
         '    DISCREPANCY IS LARGE: %.1f PER CENT PREDICTED AGAINST %.1f MEASURED.\n' ...
         '\n      The standard relation Mp = exp(-pi zeta / sqrt(1 - zeta^2)) is\n' ...
         '      derived for a second-order system whose numerator is a constant.\n' ...
         '      A PI controller does not only place poles. Its numerator is\n' ...
         '      Kp s + Ki, so it also places a ZERO at s = -Ki/Kp = %.3f, and\n' ...
         '      that zero sits among the poles at %.3f +- %.3fj.\n' ...
         '\n      A zero near the poles differentiates part of the response and\n' ...
         '      adds it back, which raises the peak. The damping ratio was\n' ...
         '      designed correctly and the poles are where they were asked to be;\n' ...
         '      what failed is the prediction made from the damping ratio alone.\n' ...
         '      The green curve in the figure has the same poles with the zero\n' ...
         '      removed, which is how the two effects are separated.\n'], ...
         RI.t(end), V.u_d1 - RI.y(end, c.u), Mp_pole, S.Overshoot, ...
         -V.Ki_d/V.Kp_d, real(pcl(1)), abs(imag(pcl(1))));

%  step() and pzmap() replace the axes if called without outputs, and every
%  later xlabel/title then applies to an axes ARRAY and errors. Take their data
%  and draw it, so the panel stays one axes.
[y_lin, t_lin] = step(Tcl*V.u_d1, RI.t(end) - V.t_up);

%  step() starts its step at t = 0; the Simulink run applies the setpoint at
%  t = t_up = 5 s. Plotting them on the same axes without shifting draws the
%  linear model FIVE SECONDS EARLY, and the two curves then look like different
%  responses when they are in fact the same one.  (Reported by the lecturer,
%  2026-09-08 — "왜 선형 모델 결과가 왼쪽에 있는거야?")
%
%  The TABLE was never affected: stepinfo() measures overshoot and settling
%  from the step instant, so both are time-shift invariant. Only the picture
%  was wrong, which is the more dangerous of the two — a reader trusts a
%  picture without checking it against a number.
t_lin = t_lin + V.t_up;
t_lin = [0; t_lin];                 % hold the initial value before the step
y_lin = [0; y_lin];

f = lab_fig('W02 E  PI', 950, 400);
subplot(1,2,1); hold on;
yline(V.u_d1, 'k:', 'DisplayName','setpoint');
plot(RI.t, RI.y(:, c.u), 'DisplayName','the 12-state plant');
plot(t_lin, y_lin, '--', 'DisplayName','linear model, zero included');
xlabel('time [s]'); ylabel('u  [m/s]'); legend('Location','southeast');
title({sprintf('overshoot %.1f %% measured', Mp), ...
       sprintf('%.1f %% from the poles alone — that leaves the zero out', Mp_pole)});

%  RIGHT PANEL, replaced 2026-09-08 at the lecturer's request.
%
%  It used to be a pole-zero map in the s-plane. That asks the reader to
%  translate "a circle at -1.886, crosses at -1.050 +- 1.071j" into "the
%  response overshoots more", which is a step this course has not taught yet
%  and does not need here. ("폴 제로 극 좌표계 그림이 왜 있는거야? 너무 어려워")
%
%  The same claim is now made in the time domain, where the section already
%  speaks: run the SAME poles twice, once with the PI zero and once without,
%  and let the two curves show what the zero costs. Nothing is asserted that
%  the picture does not display.
%
%  Tnz: same denominator as Tcl, no numerator zero, DC gain 1.
Tnz = tf(real(prod(-pcl)), real(poly(pcl)));
[y_nz, t_nz] = step(Tnz*V.u_d1, RI.t(end) - V.t_up);
t_nz = [0; t_nz + V.t_up];   y_nz = [0; y_nz];

subplot(1,2,2); hold on;
yline(V.u_d1, 'k:', 'DisplayName','setpoint');
plot(t_lin, y_lin, '--', 'Color',[0.85 0.33 0.10], 'LineWidth',1.4, ...
     'DisplayName', sprintf('with the PI zero  (%.1f %%)', S.Overshoot));
plot(t_nz,  y_nz,  '-',  'Color',[0.47 0.67 0.19], 'LineWidth',1.4, ...
     'DisplayName', sprintf('same poles, no zero  (%.1f %%)', Mp_pole));
grid on; legend('Location','southeast');
xlabel('time [s]'); ylabel('u  [m/s]');
title({'what the zero costs', ...
       sprintf('identical poles; overshoot %.1f %% against %.1f %%', ...
               S.Overshoot, Mp_pole)});
sgtitle('W02 E — integral action, and the zero nobody placed', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_PI.png'), 'Resolution', 150);

%% =====================================================================
%  E-2  Derivative action adds MASS on this axis, not damping
%  =====================================================================
%  The controlled variable is a velocity, so its derivative is an acceleration
%  and Kd lands where the mass is:  (M11 + Kd) udot = X + Xu u.
KDS = [0 20 60 150];
RD  = cell(size(KDS));  LD = cell(size(KDS));

fprintf('\n  E-2) derivative action, Kp and Ki held at the values above\n\n');
fprintf('    %6s %12s %10s %10s %14s %14s\n', ...
        'Kd', 'M11+Kd [kg]', 'wn', 'zeta', 'Mp pred [%]', 'Mp meas [%]');
fprintf('    %s\n', repmat('-', 1, 76));
zeD = zeros(size(KDS));
for i = 1:numel(KDS)
    te     = V.T_u + V.K_u*KDS(i);                 % the effective time constant
    wn     = sqrt(V.K_u*V.Ki_d/te);
    zeD(i) = (1 + V.K_u*V.Kp_d)/(2*sqrt(te*V.K_u*V.Ki_d));
    Td     = feedback((V.Kp_d + V.Ki_d/s)*(V.K_u/(te*s + 1)), 1);
    RD{i}  = run_sim('W02_surge_control', V, ...
                     'Kp', V.Kp_d, 'Ki', V.Ki_d, 'Kd', KDS(i), 'T_final', 30);
    LD{i}  = sprintf('K_d = %g', KDS(i));
    fprintf('    %6g %12.2f %10.4f %10.4f %14.2f %14.2f\n', KDS(i), V.M11 + KDS(i), ...
            wn, zeD(i), stepinfo(Td).Overshoot, ...
            step_metrics(RD{i}.t, RD{i}.y(:, c.u), V.u_d1, V.t_up));
end
fprintf(['\n    DERIVATIVE ACTION MAKES THIS LOOP WORSE, AND NOT THROUGH A SIGN\n' ...
         '    ERROR.\n' ...
         '\n      The controlled variable is a velocity, so its derivative is an\n' ...
         '      acceleration, and an acceleration is multiplied by a mass. Moving\n' ...
         '      the derivative term to the left-hand side of the equation of\n' ...
         '      motion shows where it lands:\n' ...
         '\n          (M11 + Kd) udot = X_PI + Xu u ,\n' ...
         '\n      so the effective time constant is T_eff = T_u + K_u Kd, and the\n' ...
         '      effective mass is M11 + Kd in kilograms. Kd = %g therefore makes\n' ...
         '      an %.1f kg vessel behave like a %.1f kg one.\n' ...
         '\n      A heavier vessel with unchanged damping is a less damped vessel,\n' ...
         '      and the table shows it: zeta falls from %.3f to %.3f across the\n' ...
         '      sweep, and the measured overshoot rises with it.\n' ...
         '\n      This is a property of the AXIS and not of PID. Week 3 controls\n' ...
         '      an angle, whose derivative is a rate rather than an acceleration,\n' ...
         '      and a rate multiplies damping. The identical term in the identical\n' ...
         '      controller gives the opposite result there. Substituting the\n' ...
         '      control law into the equation of motion, before assuming what a\n' ...
         '      term does, is what separates the two cases.\n'], ...
         KDS(end), V.M11, V.M11 + KDS(end), zeD(1), zeD(end));

f = lab_fig('W02 E  derivative', 950, 400);
subplot(1,2,1); hold on;
yline(V.u_d1, 'k:', 'DisplayName','setpoint');
for i = 1:numel(KDS), plot(RD{i}.t, RD{i}.y(:, c.u), 'DisplayName', LD{i}); end
xlabel('time [s]'); ylabel('u  [m/s]'); legend('Location','southeast');
title({'more derivative, more overshoot', 'the opposite of what a position loop does'});
subplot(1,2,2);
plot(KDS, zeD, 'o-'); grid on;
xlabel('K_d'); ylabel('\zeta  damping ratio');
title({'\zeta falls as K_d rises', '\tau_{eff} = (M_{11} + K_d)/|X_u|'});
sgtitle('W02 E — on a velocity loop the derivative term is a mass', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_D.png'), 'Resolution', 150);

fprintf('\n  figures -> img/W02_result_PI.png, img/W02_result_D.png\n\n');
