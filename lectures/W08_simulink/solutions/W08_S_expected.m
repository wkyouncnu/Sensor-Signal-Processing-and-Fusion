function W08_S_expected()
%W08_S_EXPECTED  모범답안이 내는 그림 셋을 다시 만든다.
%                Regenerate the three expected-result figures of the Week 8 lab.
%
%   >> W08_S_expected
%
%   만드는 것 / produces
%       ../problems/img/W08_P1_expected.png   the direction it cannot hold
%       ../problems/img/W08_P2_expected.png   the bow set free
%       ../problems/img/W08_P3_expected.png   the mission, and the handover

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
img = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
if ~isfile(fullfile(here,'W08_S1.slx')), W08_S1_dp; end
V0 = defaults();

%% ---- 문제 1 · 지킬 수 없는 방향 / the direction it cannot hold ---------
V = V0;  V.vane = 0;
A = run_one('W08_S1', V);
f = lab_fig('W08 Problem 1  the direction it cannot hold', 1000, 460);
subplot(1,2,1); hold on; grid on; axis equal;
plot(A.E, A.N, 'LineWidth', 1.5);
track_ships({[A.N A.E A.psi]}, [0 0.45 0.74], 'Marks', 7);
plot(0, 0, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
quiver(2, -6, 8, 0, 0, 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
text(3, -9, 'current');  xlabel('east [m]');  ylabel('north [m]');
title('the bow is held north; the vessel goes east');
subplot(1,2,2); hold on; grid on;
yyaxis left;  plot(A.t, A.e, 'LineWidth', 2);  ylabel('distance from the station [m]');
yyaxis right; plot(A.t, A.X, 'LineWidth', 2);  ylabel('X [N]');  ylim([-5 5]);
xlabel('time [s]');
title('the error grows and the surge force never leaves zero');
exportgraphics(f, fullfile(img, 'W08_P1_expected.png'), 'Resolution', 150);

%% ---- 문제 2 · 뱃머리를 놓아 준다 / the bow set free --------------------
V = V0;  V.vane = 1;
B = run_one('W08_S1', V);
f = lab_fig('W08 Problem 2  the bow set free', 1000, 460);
subplot(1,2,1); hold on; grid on; axis equal;
plot(B.E, B.N, 'LineWidth', 1.5);
track_ships({[B.N B.E B.psi]}, [0 0.45 0.74], 'Marks', 6);
plot(0, 0, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
quiver(1.2, -2.2, 1.2, 0, 0, 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
text(1.4, -2.6, 'current');  xlabel('east [m]');  ylabel('north [m]');
title('the vessel stays; the bow turns into the flow');
subplot(1,2,2); hold on; grid on;
yyaxis left;  plot(B.t, B.psi, 'LineWidth', 2);  ylabel('\psi [deg]');
yline(-90, 'k--', 'HandleVisibility','off');
yyaxis right; plot(B.t, B.X, 'LineWidth', 2);   ylabel('X [N]');
yline(V.V_c/0.012894, ':', 'the drag at 0.3 m/s', 'HandleVisibility','off');
xlabel('time [s]');
title('the heading it chose, and the force it holds');
exportgraphics(f, fullfile(img, 'W08_P2_expected.png'), 'Resolution', 150);

%% ---- 문제 3 · 임무와 넘겨받기 / the mission, and the handover ----------
V = V0;  V.vane = 1;  V.T_final = 400;
V.WP_N = [0 40 40]';  V.WP_E = [0 0 40]';  V.T_hold = 40;
C = run_one('W08_S1', V, 'hand_over', 1);
D = run_one('W08_S1', V, 'hand_over', 0);
f = lab_fig('W08 Problem 3  the mission and the handover', 1050, 480);
subplot(1,2,1); hold on; grid on; axis equal;
plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(C.E, C.N, 'LineWidth', 1.4);  plot(D.E, D.N, 'LineWidth', 1.4);
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
xlabel('east [m]');  ylabel('north [m]');
legend({'path','hand\_over = 1','hand\_over = 0','waypoints'}, 'Location','southeast');
title('the same mission, one integrator apart');
subplot(2,2,2); hold on; grid on;
stairs(C.t, C.mode, 'LineWidth', 1.8);  ylim([0.5 3.5]);  yticks(1:3);
yticklabels({'transit','hold','done'});  title('the two rules, and nothing else');
subplot(2,2,4); hold on; grid on;
plot(C.t, C.e, 'LineWidth', 1.4);  plot(D.t, D.e, 'LineWidth', 1.4);
xlabel('time [s]');  ylabel('distance to the station [m]');  ylim([0 40]);
legend({'hand\_over = 1','hand\_over = 0'}, 'Location','northeast');
title('what an integrator that was not in charge costs');
exportgraphics(f, fullfile(img, 'W08_P3_expected.png'), 'Resolution', 150);

fprintf('\n  three figures written to %s\n\n', img);
end

% =========================================================================
function V = defaults()
cfg = otter_config('base');
V.WP_N = 0;  V.WP_E = 0;  V.R_arrive = 2;  V.T_hold = 1e9;
V.psi_fix = 0;  V.vane = 1;
V.Kp_x = 30;  V.Ki_x = 3;  V.Kd_x = 60;  V.e_min = 0.3;  V.X_max = 120;
V.Kp = 300;   V.Kd = 100;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_max/2), ...
              2*cfg.y_pont*(V.X_max/2 + cfg.k_neg*cfg.n_min^2));
V.X_ff = 60;  V.Delta = 5;  V.hand_over = 1;
V.V_c = 0.3;  V.beta_c = pi/2;
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.x0 = zeros(12,1);
V.h = 0.02;  V.T_final = 200;
end

function y = run_one(mdl, V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
b = 'base';
f = fieldnames(V);
for i = 1:numel(f), assignin(b, f{i}, V.(f{i})); end
evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b,'dlog');
D = squeeze(S.signals.values);   if size(D,1)==3,  D = D.';  end
M = squeeze(evalin(b,'mlog').signals.values);  if size(M,1)==3,  M = M.';  end
X = squeeze(evalin(b,'xlog').signals.values);  if size(X,1)==12, X = X.'; end
y.t = S.time;
y.psi_d = D(:,1);  y.X = D(:,2);  y.Nm = D(:,3);
y.N_d = M(:,1);    y.E_d = M(:,2);  y.mode = M(:,3);
y.N = X(:,7);      y.E = X(:,8);    y.psi = X(:,12)*180/pi;
y.e = hypot(y.N_d - y.N, y.E_d - y.E);
end
