%% W04 · 절 C — 비례제어만으로도 이미 0 인 오차
%  W04 · Section C — proportional only, and the error that is already zero
%
%  실행 순서 / order of execution
%      W04_0_setup
%      W04_C_proportional_only
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 C 이며 §4-1 과 짝을 이룬다. 3주차의 속도축은 어떤 게인을
%      써도 설정값에 도달하지 못했는데, 이 축은 어떤 게인을 써도 도달한다.
%      그렇게 되도록 무언가를 조정한 것이 아니라, 축이 다르기 때문이다.
%
%      This is section C of Part 2, the counterpart of §4-1. The surge axis of
%      Week 3 could not reach its setpoint at any gain; this axis reaches it at
%      every gain. Nothing was tuned to bring that about — the axis is
%      different.
%
%  왜 그런가 / why this happens
%      선수방위의 운동방정식에는 요 각속도에 비례하는 감쇠만 있고 각도 자체에
%      작용하는 복원력이 없다. 그래서 정지 상태에서 그 각도를 유지하는 데 힘이
%      필요하지 않다. 속도축에서는 속도를 유지하는 데 감쇠를 이기는 힘이 늘
%      필요했고, 그 힘을 만들려면 오차가 남아야 했다. 여기서는 그럴 필요가 없다.
%      다시 말해 이 고리는 1 형이다.
%
%      The equation of motion for heading contains damping proportional to the
%      yaw rate but no restoring term acting on the angle itself, so holding
%      an angle at rest costs no moment. On the surge axis, holding a speed
%      always required a force to overcome damping, and producing that force
%      required an error to remain. Here it does not: the loop is type 1.
%
%  절차 / procedure
%      비례게인 셋에 계단 명령 하나. 각 게인에서 정상상태 오차와 오버슛을 잰다.
%      Three proportional gains and one step command; the steady-state error
%      and the overshoot are measured at each gain.
%
%  만드는 것 / what it produces
%      표 하나와 img/W04_result_P.png
%      One table and img/W04_result_P.png

clear RP KPS LP i wn ze Mp ts y
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_heading_control.slx')), W04_1_build_heading; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W04_vars;

%% ---- three proportional gains, Kd = 0 ----------------------------------
KPS = [30 100 300];
RP  = cell(size(KPS));
LP  = cell(size(KPS));

fprintf('\n  W04 section C — proportional only, Kd = 0, step to %g deg\n\n', V.psi_1);
%  peak |tau_N| is printed because the lecture quotes it. A number read off
%  the right-hand panel is not traceable to a runner; this column makes it so.
fprintf('    %8s %10s %10s %20s %14s %12s %16s\n', ...
        'Kp', 'wn', 'zeta', 'steady error [deg]', 'overshoot [%]', 'ts 2% [s]', ...
        'peak |tau_N| [N.m]');
fprintf('    %s\n', repmat('-', 1, 96));

for i = 1:numel(KPS)
    RP{i} = W04_read(run_sim('W04_heading_control', V, 'Kp', KPS(i), 'Kd', 0, 'T_final', 60));
    wn    = sqrt(KPS(i)/V.M66);                       % from M66 psi'' + |Nr| psi' + Kp psi
    ze    = abs(V.Nr)/(2*sqrt(KPS(i)*V.M66));
    [Mp, ts] = step_metrics(RP{i}.t, RP{i}.psi, V.psi_1, V.t_up);
    LP{i} = sprintf('K_p = %.4g', KPS(i));
    fprintf('    %8.4g %10.4f %10.4f %20.2e %14.2f %12.2f %16.1f\n', ...
            KPS(i), wn, ze, V.psi_1 - RP{i}.psi(end), Mp, ts, ...
            max(abs(RP{i}.tau_N)));
end

fprintf(['\n    The steady-state error is zero at EVERY gain, to solver tolerance.\n' ...
         '    Nothing was tuned to achieve it. The heading is the integral of the\n' ...
         '    yaw rate, psi = int r, so the plant carries a free integrator and\n' ...
         '    the loop is TYPE 1. Week 3 could not reach its setpoint at any gain,\n' ...
         '    and the difference is one structural fact about the axis, not a\n' ...
         '    better controller.\n']);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 C  proportional only', 1000, 400);

subplot(1,2,1); hold on;
yline(V.psi_1, 'k:', 'DisplayName','command');
for i = 1:numel(KPS), plot(RP{i}.t, RP{i}.psi, 'DisplayName', LP{i}); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
legend('Location','southeast');
title({'every gain reaches the setpoint', 'the plant integrates, so P alone suffices'});

subplot(1,2,2); hold on;
for i = 1:numel(KPS), plot(RP{i}.t, RP{i}.tau_N, 'DisplayName', LP{i}); end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('time [s]'); ylabel('\tau_N  commanded moment [N m]');
title({'and the moment returns to zero', 'a vessel that is not turning needs none'});

sgtitle('W04 C — a type 1 plant needs no integral action', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_P.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_P.png\n\n');
