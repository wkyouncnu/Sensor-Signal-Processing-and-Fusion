%% W03 · section D — derivative action, which on this axis is a damper
%
%      W03_0_setup
%      W03_D_derivative_action
%
%  The same term that made Week 2 worse makes this week better. The term did
%  not change; the axis did.
%  Produces img/W03_result_D.png

clear RD KDS LD zeD MpP MpM i wn ts Kp0 STEPD
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W03_heading_control.slx')), W03_1_build_heading; end

V = W03_vars;

%  A SMALL step, deliberately. The yaw damping of otter.m grows with |r|, so a
%  large step is damped by the HULL rather than by the controller and the
%  linear prediction stops applying. Section F is that effect on purpose.
Kp0   = 100.00;
STEPD = 5;
KDS   = [0 25 74.90 150];

RD  = cell(size(KDS));  LD = cell(size(KDS));
zeD = zeros(size(KDS)); MpP = zeD;  MpM = zeD;

fprintf('\n  W03 section D — derivative action, Kp = %.2f held, %g deg step\n\n', Kp0, STEPD);
fprintf('    %8s %10s %10s %18s %18s %12s\n', ...
        'Kd', 'wn', 'zeta', 'Mp predicted [%]', 'Mp measured [%]', 'ts 2% [s]');
fprintf('    %s\n', repmat('-', 1, 82));

for i = 1:numel(KDS)
    RD{i}  = W03_read(run_sim('W03_heading_control', V, 'Kp', Kp0, 'Kd', KDS(i), ...
                              'psi_1', STEPD, 'psi_2', STEPD, 'T_final', 60));
    wn     = sqrt(Kp0/V.M66);
    zeD(i) = (abs(V.Nr) + KDS(i))/(2*sqrt(Kp0*V.M66));    % Kd sits beside |Nr|
    if zeD(i) < 1, MpP(i) = 100*exp(-pi*zeD(i)/sqrt(1-zeD(i)^2)); else, MpP(i) = 0; end
    [MpM(i), ts] = step_metrics(RD{i}.t, RD{i}.psi, STEPD, V.t_up);
    LD{i}  = sprintf('K_d = %.4g', KDS(i));
    fprintf('    %8.4g %10.4f %10.4f %18.2f %18.2f %12.2f\n', ...
            KDS(i), wn, zeD(i), MpP(i), MpM(i), ts);
end

fprintf(['\n    Overshoot FALLS as Kd rises. Substituting the control law into the\n' ...
         '    equation of motion shows why:\n' ...
         '\n        M66 psi_ddot + (|Nr| + Kd) psi_dot + Kp psi = Kp psi_d,\n' ...
         '\n    so Kd sits beside the DAMPING and not beside the inertia. In Week 2\n' ...
         '    the controlled variable was a velocity, its derivative was an\n' ...
         '    acceleration, and the same term sat beside the MASS and made the\n' ...
         '    response worse. The term did not change; the axis did.\n' ...
         '\n    The hull alone already gives zeta = %.4f at Kp = %.2f, because Nr\n' ...
         '    is large. Most of the damping in this loop is not the controller.\n'], ...
         zeD(1), Kp0);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W03 D  derivative action', 1000, 400);

subplot(1,2,1); hold on;
yline(STEPD, 'k:', 'DisplayName','command');
for i = 1:numel(KDS), plot(RD{i}.t, RD{i}.psi, 'DisplayName', LD{i}); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
legend('Location','southeast');
title({'more derivative, LESS overshoot', 'the opposite of Week 2, on the same term'});

subplot(1,2,2); hold on;
plot(KDS, MpP, 'o--', 'DisplayName','predicted from \zeta');
plot(KDS, MpM, 's-',  'DisplayName','measured');
grid on; legend('Location','northeast');
xlabel('K_d'); ylabel('overshoot [%]');
title({'prediction against measurement', ...
       sprintf('\\zeta rises from %.2f to %.2f', zeD(1), zeD(end))});

sgtitle('W03 D — on an angle loop the derivative term is a damper', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W03_result_D.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W03_result_D.png\n\n');
