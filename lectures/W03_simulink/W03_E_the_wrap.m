%% W03 · section E — the wrap, and the one line of arithmetic that prevents it
%
%      W03_0_setup
%      W03_E_the_wrap
%
%  Hold +170 deg, then command -170 deg. The two headings are 20 deg apart.
%  One vessel turns 20 deg. The other turns 340 deg the other way.
%  Produces img/W03_result_ssa.png

clear W LW i k swept
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W03_heading_control.slx')), W03_1_build_heading; end

V = W03_vars;

%% ---- the same command, with and without ssa ----------------------------
W     = cell(1,2);
LW    = {'with ssa','without ssa'};
swept = zeros(1,2);

fprintf('\n  W03 section E — the wrap: +170 deg held, then -170 deg commanded\n\n');
fprintf('    %-14s %18s %18s %18s\n', ...
        'ssa', 'peak |r| [deg/s]', 'total turn [deg]', 'settled psi [deg]');
fprintf('    %s\n', repmat('-', 1, 74));

for i = 1:2
    W{i}     = W03_read(run_sim('W03_heading_control', V, ...
                        'psi_1', 170, 'psi_2', -170, 't_up', 5, 't_dn', 25, ...
                        'T_final', 120, 'use_ssa', 2-i));
    k        = W{i}.t >= 25;                       % after the second command
    swept(i) = abs(W{i}.psi(end) - interp1(W{i}.t, W{i}.psi, 25));
    fprintf('    %-14s %18.3f %18.1f %18.2f\n', LW{i}, ...
            max(abs(W{i}.r(k))), swept(i), W{i}.psi(end));
end

fprintf(['\n    Both vessels end on the same heading. One turned %.0f deg to get\n' ...
         '    there and the other turned %.0f deg the other way, because\n' ...
         '    psi_d - psi = -170 - 170 = -340 deg is a perfectly valid number\n' ...
         '    and a perfectly wrong error. ssa maps it into (-pi, pi], giving\n' ...
         '    +20 deg. One line of arithmetic separates the two runs:\n' ...
         '\n        ssa(a) = atan2(sin a, cos a)\n'], swept(1), swept(2));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W03 E  the wrap', 1050, 400);

subplot(1,2,1); hold on;
yline(170,  'k:', 'HandleVisibility','off');
yline(-170, 'k:', 'HandleVisibility','off');
for i = 1:2, plot(W{i}.t, W{i}.psi, 'DisplayName', LW{i}); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
legend('Location','best');
title({'the same command, two journeys', ...
       sprintf('%.0f deg against %.0f deg swept', swept(1), swept(2))});

subplot(1,2,2); hold on; axis equal;
for i = 1:2, plot(W{i}.E, W{i}.N, 'DisplayName', LW{i}); end
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
xlabel('East [m]'); ylabel('North [m]');
title({'and two very different tracks', 'the long way round is a full circle'});

sgtitle('W03 E — an angle error is not a subtraction', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W03_result_ssa.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W03_result_ssa.png\n\n');
