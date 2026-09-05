%% W03 · section C — proportional only, and the error that is already zero
%
%      W03_0_setup
%      W03_C_proportional_only
%
%  Three gains, one step. Week 2 could not reach its setpoint at any gain.
%  This axis reaches it at every gain, and nothing was tuned to make that happen.
%  Produces img/W03_result_P.png

clear RP KPS LP i wn ze Mp ts y
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W03_heading_control.slx')), W03_1_build_heading; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W03_vars;

%% ---- three proportional gains, Kd = 0 ----------------------------------
KPS = [30 100 300];
RP  = cell(size(KPS));
LP  = cell(size(KPS));

fprintf('\n  W03 section C — proportional only, Kd = 0, step to %g deg\n\n', V.psi_1);
%  peak |tau_N| is printed because the lecture quotes it. A number read off
%  the right-hand panel is not traceable to a runner; this column makes it so.
fprintf('    %8s %10s %10s %20s %14s %12s %16s\n', ...
        'Kp', 'wn', 'zeta', 'steady error [deg]', 'overshoot [%]', 'ts 2% [s]', ...
        'peak |tau_N| [N.m]');
fprintf('    %s\n', repmat('-', 1, 96));

for i = 1:numel(KPS)
    RP{i} = W03_read(run_sim('W03_heading_control', V, 'Kp', KPS(i), 'Kd', 0, 'T_final', 60));
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
         '    the loop is TYPE 1. Week 2 could not reach its setpoint at any gain,\n' ...
         '    and the difference is one structural fact about the axis, not a\n' ...
         '    better controller.\n']);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W03 C  proportional only', 1000, 400);

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

sgtitle('W03 C — a type 1 plant needs no integral action', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W03_result_P.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W03_result_P.png\n\n');
