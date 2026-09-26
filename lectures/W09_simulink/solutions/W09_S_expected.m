function W09_S_expected()
%W09_S_EXPECTED  모범답안이 내는 그림 셋을 다시 만든다.
%                Regenerate the three expected-result figures of the Week 9 lab.
%
%   >> W09_S_expected
%
%   만드는 것 / produces
%       ../problems/img/W09_P1_expected.png   the mission, run by two rules
%       ../problems/img/W09_P2_expected.png   the circle that was missed
%       ../problems/img/W09_P3_expected.png   one week at a time, removed

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
img = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
if ~isfile(fullfile(here,'W09_S1.slx')), W09_S1_mission; end

%% ---- 문제 1 · 두 규칙이 만든 임무 / the mission the two rules produced --
R = run_one('W09_S1');  V = R.V;
f = lab_fig('W09 Problem 1  the mission', 1050, 480);
subplot(1,2,1); hold on; grid on; axis equal;
plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(R.E, R.N, 'Color', [0 0.45 0.74], 'LineWidth', 1.2);
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
track_ships({[R.N R.E R.psi]}, [0 0.45 0.74], 'Marks', 14);
quiver(-14, -14, 9, 0, 0, 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MaxHeadSize', 0.6);
text(-13, -18, 'current');  xlabel('east [m]');  ylabel('north [m]');
title('three legs, three holds');
subplot(2,2,2); hold on; grid on;
stairs(R.t, R.mode, 'LineWidth', 1.8);  ylim([0.5 3.5]);  yticks(1:3);
yticklabels({'transit','hold','done'});  title('two rules, and nothing else');
subplot(2,2,4); hold on; grid on;
plot(R.t, R.e, 'LineWidth', 1.3);
xlabel('time [s]');  ylabel('distance to the active station [m]');  ylim([0 25]);
title('falling into every hold, rising in every transit');
exportgraphics(f, fullfile(img, 'W09_P1_expected.png'), 'Resolution', 150);

%% ---- 문제 2 · 놓친 원 / the circle that was missed ---------------------
A = run_one('W09_S1', 'V_c', 1.3, 'use_pass', 0, 'T_final', 600);
B = run_one('W09_S1', 'V_c', 1.3, 'use_pass', 1, 'T_final', 600);
near = min(hypot(A.V.WP_N(1) - A.N, A.V.WP_E(1) - A.E));
f = lab_fig('W09 Problem 2  the circle that was missed', 1000, 470);
subplot(1,2,1); hold on; grid on; axis equal;
plot([0; A.V.WP_E], [0; A.V.WP_N], 'k--');
plot(A.E, A.N, 'LineWidth', 1.4);  plot(B.E, B.N, 'LineWidth', 1.4);
plot(A.V.WP_E, A.V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
viscircles([A.V.WP_E(1) A.V.WP_N(1)], A.V.R_arrive, 'Color', [.5 .5 .5], 'LineWidth', 0.8);
xlabel('east [m]');  ylabel('north [m]');  xlim([-25 95]);  ylim([-15 145]);
legend({'path','circle only','along-track test','waypoints'}, 'Location','northwest');
title(sprintf('at V_c = 1.3 m/s, missed by %.2f m', near - A.V.R_arrive));
subplot(1,2,2); hold on; grid on;
plot(A.t, hypot(A.V.WP_N(1) - A.N, A.V.WP_E(1) - A.E), 'LineWidth', 1.6);
yline(A.V.R_arrive, 'r--', 'R_{arrive}');
xlabel('time [s]');  ylabel('distance to waypoint 1 [m]');  xlim([0 160]);  ylim([0 40]);
title('the closest approach never enters the circle');
exportgraphics(f, fullfile(img, 'W09_P2_expected.png'), 'Resolution', 150);

%% ---- 문제 3 · 한 주차씩 / one week at a time ---------------------------
S = {'none','use_Ki_u','use_ssa','use_Kd','use_ilos','use_pass','use_scale', ...
     'use_notch','use_vane','hand_over'};
clear M
for i = 1:numel(S)
    if i == 1, Q = run_one('W09_S1'); else, Q = run_one('W09_S1', S{i}, 0); end
    M(i) = W09_metrics(Q);  TR{i} = Q;                                %#ok<AGROW>
end
f = lab_fig('W09 Problem 3  one week at a time', 1050, 480);
subplot(1,2,1); hold on; grid on; axis equal;
V = TR{1}.V;
plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
pick = [1 3 7 9];                     % none, use_ssa, use_scale, use_vane
for j = 1:4, plot(TR{pick(j)}.E, TR{pick(j)}.N, 'LineWidth', 1.3); end
xlabel('east [m]');  ylabel('north [m]');  title('the same mission, four vessels');
legend([{'path','waypoints'}, S(pick)], 'Location','southoutside', ...
       'NumColumns', 3, 'Interpreter', 'none');
subplot(1,2,2);
b = bar([[M.ye]' [M.hold]']);  hold on; grid on;
yline(M(1).ye, '--', 'Color', b(1).FaceColor);
yline(M(1).hold, '--', 'Color', b(2).FaceColor);
bad = find(isnan([M.T]));
plot(bad, 0.2*ones(size(bad)), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
set(gca, 'XTick', 1:numel(S), 'XTickLabel', S, 'TickLabelInterpreter', 'none');
xtickangle(40);  ylabel('[m]');  title('x = the mission did not finish');
legend({'cross-track at the end of a leg','hold error'}, 'Location','northwest');
exportgraphics(f, fullfile(img, 'W09_P3_expected.png'), 'Resolution', 150);

fprintf('\n  three figures written to %s\n\n', img);
end

% =========================================================================
function R = run_one(mdl, varargin)
V = W09_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
V.w0 = 2*pi/V.T0;
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
V.phi_i = mod(V.phi_i + V.phase_shift, 2*pi);
if V.use_notch == 0, V.zeta_n = V.zeta_d; end
b = 'base';
f = fieldnames(V);
for i = 1:numel(f), assignin(b, f{i}, V.(f{i})); end
evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, sprintf('sim(''%s'');', mdl));
L = evalin(b,'plog');
P = squeeze(L.signals.values);                  if size(P,1)==4,  P = P.';  end
S = squeeze(evalin(b,'slog').signals.values);   if size(S,1)==2,  S = S.';  end
X = squeeze(evalin(b,'xlog').signals.values);   if size(X,1)==12, X = X.'; end
R.t = L.time;  R.V = V;
R.psi_d = P(:,1);  R.y_e = P(:,2);  R.X = P(:,3);  R.Nm = P(:,4);
R.wp = S(:,1);     R.mode = S(:,2);
R.N = X(:,7);      R.E = X(:,8);    R.psi = X(:,12)*180/pi;  R.u = X(:,1);
R.e = zeros(size(R.t));
for k = 1:numel(V.WP_N)
    j = R.wp == k;
    R.e(j) = hypot(V.WP_N(k) - R.N(j), V.WP_E(k) - R.E(j));
end
end
