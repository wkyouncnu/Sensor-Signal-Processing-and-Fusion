%% W03 · section F — big turns overshoot LESS, which no linear model can do
%
%      W03_0_setup
%      W03_F_big_turns_overshoot_less
%
%  Four step sizes, one controller. The nonlinear yaw damping of otter.m,
%      Nh = Nr (1 + 10 |r|) r,
%  grows with the turn rate, so the hull damps its own large turns.
%  Produces img/W03_result_size.png

clear RS SZ LS MpS rpk i ts Kp0 mult
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W03_heading_control.slx')), W03_1_build_heading; end

V   = W03_vars;
Kp0 = 100.00;
SZ  = [5 20 60 120];

RS  = cell(size(SZ));  LS = cell(size(SZ));
MpS = zeros(size(SZ)); rpk = MpS;

fprintf('\n  W03 section F — step size, Kp = %.2f, Kd = 0\n\n', Kp0);
fprintf('    %10s %18s %16s %14s %16s\n', ...
        'step [deg]', 'peak |r| [deg/s]', 'overshoot [%]', 'ts 2% [s]', 'damping x');
fprintf('    %s\n', repmat('-', 1, 78));

for i = 1:numel(SZ)
    RS{i} = W03_read(run_sim('W03_heading_control', V, 'psi_1', SZ(i), 'psi_2', SZ(i), ...
                             'Kp', Kp0, 'Kd', 0, 'T_final', 60));
    [MpS(i), ts] = step_metrics(RS{i}.t, RS{i}.psi, SZ(i), V.t_up);
    rpk(i) = max(abs(RS{i}.r));
    LS{i}  = sprintf('%g deg', SZ(i));
    fprintf('    %10g %18.3f %16.2f %14.2f %16.2f\n', ...
            SZ(i), rpk(i), MpS(i), ts, 1 + 10*deg2rad(rpk(i)));
end

mult = 1 + 10*deg2rad(rpk(end));
fprintf(['\n    A larger step overshoots LESS, which no linear model can produce.\n' ...
         '    The yaw damping in otter.m is\n' ...
         '\n        Nh = Nr (1 + 10 |r|) r,\n' ...
         '\n    so at the peak rate of the %g deg step, %.3f deg/s = %.4f rad/s,\n' ...
         '    the damping is %.2f times its small-signal value. The design\n' ...
         '    equations of section D use Nr alone and are therefore a\n' ...
         '    SMALL-SIGNAL result: valid for the %g deg step and conservative\n' ...
         '    for the large ones.\n'], ...
         SZ(end), rpk(end), deg2rad(rpk(end)), mult, SZ(1));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W03 F  step size', 1050, 400);

subplot(1,2,1); hold on;
for i = 1:numel(SZ)
    plot(RS{i}.t, RS{i}.psi/SZ(i), 'DisplayName', LS{i});   % normalised
end
yline(1, 'k:', 'HandleVisibility','off');
xlabel('time [s]'); ylabel('\psi / step   [-]');
legend('Location','southeast');
title({'normalised, so the shapes can be compared', ...
       'a linear plant would put these four exactly on top of each other'});

subplot(1,2,2);
yyaxis left
plot(SZ, MpS, 'o-'); ylabel('overshoot [%]');
yyaxis right
plot(SZ, 1 + 10*deg2rad(rpk), 's--'); ylabel('damping multiplier  1 + 10|r|');
grid on; xlabel('step size [deg]');
title({'bigger step, more damping, less overshoot', ...
       sprintf('the multiplier reaches %.2f at %g deg', mult, SZ(end))});

sgtitle('W03 F — the hull damps its own large turns', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W03_result_size.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W03_result_size.png\n\n');
