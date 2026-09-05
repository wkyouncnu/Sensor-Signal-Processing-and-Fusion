%% W02 · section C — identify the plant from the plant
%
%  Run this after W02_0_setup. It opens the loop, applies four constant forces,
%  and measures the DC gain and time constant that Part 1 predicted.
%
%      W02_0_setup
%      W02_C_identify_plant
%
%  Produces one table and one figure: img/W02_result_openloop.png
%
%  This is a SCRIPT, not a function. Everything it computes stays in the
%  workspace afterwards, so the numbers in the table can be poked at.

clear R u_ol t63 XS i k
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W02_surge_control.slx')), W02_1_build_surge_control; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W02_vars;      % every variable the model needs
c = W02_cols;      % names for the log columns — no magic numbers below

%% ---- the four open-loop runs -------------------------------------------
%  loop_closed = 0 disconnects the controller and applies X_open directly, so
%  the same model that closes the loop later can identify the plant now.
XS   = [50 100 150 200];
u_ol = zeros(size(XS));
t63  = zeros(size(XS));
R    = cell(size(XS));

fprintf('\n  W02 section C — open-loop identification (loop_closed = 0)\n\n');
fprintf('    %10s %14s %14s %14s %14s\n', ...
        'X [N]', 'u_ss meas', 'u_ss = K_u X', 'tau meas [s]', 'error [%]');
fprintf('    %s\n', repmat('-', 1, 72));

for i = 1:numel(XS)
    R{i}    = run_sim('W02_surge_control', V, ...
                      'loop_closed', 0, 'X_open', XS(i), 'T_final', 30);
    u_ol(i) = R{i}.y(end, c.u);
    k       = find(R{i}.y(:, c.u) >= 0.6321*u_ol(i), 1);   % the 63.2 % point
    t63(i)  = R{i}.t(k);
    fprintf('    %10g %14.4f %14.4f %14.4f %14.2f\n', ...
            XS(i), u_ol(i), V.K_u*XS(i), t63(i), 100*(u_ol(i)/(V.K_u*XS(i)) - 1));
end

fprintf(['\n    The DC gain is exact: in steady state the plant really is\n' ...
         '    u = K_u X, with K_u = 1/|X_u| = %.6f (m/s)/N. The measured time\n' ...
         '    constant averages %.4f s against the first-order figure %.4f s,\n' ...
         '    a %.2f per cent excess produced by the surge-pitch coupling that\n' ...
         '    the scalar model of 2-1 discards.\n'], ...
         V.K_u, mean(t63), V.tau_u, 100*(mean(t63)/V.tau_u - 1));

fprintf(['\n    The speed ceiling is not an accident:\n' ...
         '      X_max = 2 k_pos n_max^2 = 24.4 g = %.3f N exactly, and\n' ...
         '      X_u   = -24.4 g / U_max, so u_max = X_max/|X_u| = %.4f m/s EXACTLY.\n'], ...
         V.X_hi, V.X_hi*V.K_u);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W02 C  open loop', 900, 380);

subplot(1,2,1); hold on;
for i = 1:numel(XS)
    plot(R{i}.t, R{i}.y(:, c.u), 'DisplayName', sprintf('X = %g N', XS(i)));
end
xlabel('time [s]'); ylabel('u  [m/s]');
legend('Location','southeast');
title({'open-loop step responses', 'first order, and the gain is linear in X'});

subplot(1,2,2); hold on;
plot(XS, V.K_u*XS, '--', 'DisplayName', 'K_u X  (predicted)');
plot(XS, u_ol, 'o', 'MarkerFaceColor','auto', 'DisplayName', 'measured');
xlabel('X  [N]'); ylabel('settled u  [m/s]');
legend('Location','northwest');
title({'DC gain', sprintf('K_u = %.6f (m/s)/N', V.K_u)});

sgtitle('W02 C — the plant, identified from the plant', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_openloop.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W02_result_openloop.png\n\n');
