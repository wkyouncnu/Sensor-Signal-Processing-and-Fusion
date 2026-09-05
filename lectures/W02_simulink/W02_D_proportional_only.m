%% W02 · section D — proportional control, and the error it cannot remove
%
%      W02_0_setup
%      W02_D_proportional_only
%
%  Three gains, one setpoint. The point is that none of them reaches it.
%  Produces img/W02_result_P.png

clear R KPS LBL i pred meas
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W02_surge_control.slx')), W02_1_build_surge_control; end

V = W02_vars;
c = W02_cols;

%% ---- three proportional gains ------------------------------------------
%  Ki = 0 and Kd = 0, so this is a pure P controller. aw_mode = 0 because
%  with no integrator there is nothing to protect from windup.
KPS = [100 500 2000];
R   = cell(size(KPS));
LBL = cell(size(KPS));

fprintf('\n  W02 section D — proportional only, u_d = %g m/s\n\n', V.u_d1);
%  peak X_cmd is printed because the lecture quotes it. A number read off a
%  figure is not traceable to a runner, which is the rule this column keeps.
fprintf('    %8s %12s %14s %14s %12s %12s %14s\n', ...
        'Kp', 'Kp K_u', 'predicted u_ss', 'measured u_ss', 'error [%]', ...
        'X_ss [N]', 'peak X_cmd [N]');
fprintf('    %s\n', repmat('-', 1, 92));

for i = 1:numel(KPS)
    R{i}   = run_sim('W02_surge_control', V, ...
                     'Kp', KPS(i), 'Ki', 0, 'Kd', 0, 'aw_mode', 0, 'T_final', 30);
    pred   = V.u_d1 * KPS(i)*V.K_u/(1 + KPS(i)*V.K_u);   % final value theorem
    meas   = R{i}.y(end, c.u);
    LBL{i} = sprintf('K_p = %d', KPS(i));
    fprintf('    %8d %12.4f %14.4f %14.4f %12.2f %12.3f %14.1f\n', ...
            KPS(i), KPS(i)*V.K_u, pred, meas, ...
            100*(V.u_d1-meas)/V.u_d1, R{i}.y(end, c.X_sat), ...
            max(abs(R{i}.y(:, c.X_cmd))));
end

fprintf(['\n    The plant has no free integrator, so the loop is TYPE 0 and a\n' ...
         '    proportional controller cannot reach the setpoint. The final value\n' ...
         '    theorem gives u_ss/u_d = Kp K_u / (1 + Kp K_u) and the simulation\n' ...
         '    reproduces it. Raising Kp from 100 to 2000 shrinks the error from\n' ...
         '    44 to 4 per cent and never removes it: the steady force the damping\n' ...
         '    demands can only be produced by a NON-ZERO error.\n']);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W02 D  proportional only', 950, 400);

subplot(1,2,1); hold on;
yline(V.u_d1, 'k:', 'DisplayName', 'setpoint');
for i = 1:numel(KPS), plot(R{i}.t, R{i}.y(:, c.u), 'DisplayName', LBL{i}); end
xlabel('time [s]'); ylabel('u  [m/s]');
legend('Location','southeast');
title({'the gap never closes', 'higher gain shrinks it and never removes it'});

subplot(1,2,2); hold on;
for i = 1:numel(KPS), plot(R{i}.t, R{i}.y(:, c.X_cmd), 'DisplayName', LBL{i}); end
xlabel('time [s]'); ylabel('X  demanded [N]');
title({'the force that error buys', 'a steady force needs a steady error'});

sgtitle('W02 D — proportional control on a type 0 plant', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_P.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W02_result_P.png\n\n');
