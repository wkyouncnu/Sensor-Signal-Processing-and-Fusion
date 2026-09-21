%% W04 · 절 D — 이 축에서 미분항은 감쇠기이다
%  W04 · Section D — derivative action, which on this axis is a damper
%
%  실행 순서 / order of execution
%      W04_0_setup
%      W04_D_derivative_action
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 D 이며 §4-3 과 짝을 이룬다. 3주차 절 E 를 나쁘게 만들었던
%      바로 그 항이 이번 주에는 좋게 만든다. 항이 달라진 것이 아니라 축이 달라졌다.
%
%      This is section D of Part 2, the counterpart of §4-3. The very term that
%      made section E of Week 3 worse makes this week better. The term did not
%      change; the axis did.
%
%  왜 결과가 반대인가 / why the result is opposite
%      제어하는 양이 속도이면 그 미분은 가속도이고, 가속도에 곱해지는 것은
%      질량이다. 그래서 3주차에서 Kd 는 선체를 무겁게 만들어 감쇠비를 떨어뜨렸다.
%      제어하는 양이 각도이면 그 미분은 각속도이고, 각속도에 곱해지는 것은
%      감쇠계수이다. 그래서 여기서 Kd 는 감쇠와 같은 자리에 더해진다.
%
%          M66 psi_ddot + (|Nr| + Kd) psi_dot + Kp psi = Kp psi_d
%
%      제어법칙을 운동방정식에 대입해 보기 전에 어떤 항이 무엇을 하는지 단정하지
%      않는다는 것이 이 두 절의 교훈이다.
%
%      When the controlled variable is a velocity, its derivative is an
%      acceleration and what multiplies an acceleration is a mass, so in Week 3
%      Kd made the hull heavier and lowered the damping ratio. When the
%      controlled variable is an angle, its derivative is a rate and what
%      multiplies a rate is a damping coefficient, so here Kd adds to the
%      damping. The lesson of the pair of sections is to substitute the control
%      law into the equation of motion before assuming what a term does.
%
%  만드는 것 / what it produces
%      표 하나와 img/W04_result_D.png
%      One table and img/W04_result_D.png

clear RD KDS LD zeD MpP MpM i wn ts Kp0 STEPD
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_heading_control.slx')), W04_1_build_heading; end

V = W04_vars;

%  A SMALL step, deliberately. The yaw damping of otter.m grows with |r|, so a
%  large step is damped by the HULL rather than by the controller and the
%  linear prediction stops applying. Section F is that effect on purpose.
Kp0   = 100.00;
STEPD = 5;
KDS   = [0 25 74.90 150];

RD  = cell(size(KDS));  LD = cell(size(KDS));
zeD = zeros(size(KDS)); MpP = zeD;  MpM = zeD;

fprintf('\n  W04 section D — derivative action, Kp = %.2f held, %g deg step\n\n', Kp0, STEPD);
fprintf('    %8s %10s %10s %18s %18s %12s\n', ...
        'Kd', 'wn', 'zeta', 'Mp predicted [%]', 'Mp measured [%]', 'ts 2% [s]');
fprintf('    %s\n', repmat('-', 1, 82));

for i = 1:numel(KDS)
    RD{i}  = W04_read(run_sim('W04_heading_control', V, 'Kp', Kp0, 'Kd', KDS(i), ...
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
         '\n    so Kd sits beside the DAMPING and not beside the inertia. In Week 3\n' ...
         '    the controlled variable was a velocity, its derivative was an\n' ...
         '    acceleration, and the same term sat beside the MASS and made the\n' ...
         '    response worse. The term did not change; the axis did.\n' ...
         '\n    The hull alone already gives zeta = %.4f at Kp = %.2f, because Nr\n' ...
         '    is large. Most of the damping in this loop is not the controller.\n'], ...
         zeD(1), Kp0);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 D  derivative action', 1000, 400);

subplot(1,2,1); hold on;
yline(STEPD, 'k:', 'DisplayName','command');
for i = 1:numel(KDS), plot(RD{i}.t, RD{i}.psi, 'DisplayName', LD{i}); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
legend('Location','southeast');
title({'more derivative, LESS overshoot', 'the opposite of Week 3, on the same term'});

subplot(1,2,2); hold on;
plot(KDS, MpP, 'o--', 'DisplayName','predicted from \zeta');
plot(KDS, MpM, 's-',  'DisplayName','measured');
grid on; legend('Location','northeast');
xlabel('K_d'); ylabel('overshoot [%]');
title({'prediction against measurement', ...
       sprintf('\\zeta rises from %.2f to %.2f', zeD(1), zeD(end))});

sgtitle('W04 D — on an angle loop the derivative term is a damper', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_D.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_D.png\n\n');
