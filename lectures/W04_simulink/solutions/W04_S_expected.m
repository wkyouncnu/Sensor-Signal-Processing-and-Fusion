function W04_S_expected()
%W04_S_EXPECTED  The result graphs a correct Week 4 submission must produce.
%
%   >> W04_S_expected
%
%   Runs the reference solution three ways and writes one PNG per problem into
%   ../problems/img/. Only the OUTPUT crosses into problems/.
%
%   See also W04_CHECK, W04_S1_LOS.

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
img  = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
close all; bdclose('all');
Delta = 8;

%% ---- Problem 1 : the law joins the line and stays on it ----------------
y = run_one(struct('law',1,'V_c',0,'beta_c',0,'T_final',120,'y0',18));
f = lab_fig('W04 P1 expected', 940, 380);
subplot(1,3,1);
plot(y.y, y.x, 'LineWidth', 1.6); hold on; grid on; axis equal
plot([0 0], [0 90], '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
track_ships({[y.x y.y rad2deg(y.psi)]}, [0 0.45 0.74], 'Marks', 7);
xlabel('east  y^n  [m]'); ylabel('north  x^n  [m]');
title('joins the line, then runs along it');
subplot(1,3,2);
plot(y.t, y.y_e, 'LineWidth', 1.6, 'Color',[0.75 0.10 0.10]); hold on; grid on
yline(0,'--'); xlabel('time  [s]'); ylabel('y_e^p  [m]');
title('cross-track error \rightarrow 0');
subplot(1,3,3);
plot(y.t, rad2deg(y.psi_d), 'LineWidth',1.6, 'Color',[0.49 0.18 0.56]); hold on; grid on
plot(y.t, rad2deg(y.pi_p), '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
xlabel('time  [s]'); ylabel('[deg]');
title('\psi_d \rightarrow \pi_p as the error closes');
legend({'\psi_d','\pi_p'}, 'Location','northeast');
save_png(f, fullfile(img,'W04_P1_expected.png'));

%% ---- Problem 2 : the point against the line ----------------------------
yL = run_one(struct('law',1,'V_c',0,'beta_c',0,'T_final',120,'y0',18));
yA = run_one(struct('law',2,'V_c',0,'beta_c',0,'T_final',120,'y0',18));
f = lab_fig('W04 P2 expected', 900, 380);
subplot(1,2,1);
plot(yA.y, yA.x, 'LineWidth',1.6, 'Color',[0.85 0.33 0.10]); hold on; grid on; axis equal
plot(yL.y, yL.x, 'LineWidth',1.6, 'Color',[0 0.45 0.74]);
plot([0 0], [0 90], '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
plot(0, 60, 's', 'MarkerEdgeColor',[0.75 0.10 0.10], 'MarkerFaceColor','w', ...
     'MarkerSize',9, 'LineWidth',1.5);
xlabel('east  y^n  [m]'); ylabel('north  x^n  [m]');
title('both reach the waypoint; one follows the line');
legend({'atan2','LOS','the path'}, 'Location','southeast');
subplot(1,2,2);
plot(yA.t, abs(yA.y_e), 'LineWidth',1.6, 'Color',[0.85 0.33 0.10]); hold on; grid on
plot(yL.t, abs(yL.y_e), 'LineWidth',1.6, 'Color',[0 0.45 0.74]);
xline(90,'--','from here','LabelVerticalAlignment','bottom');
xlabel('time  [s]'); ylabel('|y_e^p|  [m]');
title('distance from the LINE');
legend({'atan2','LOS'}, 'Location','northeast');
save_png(f, fullfile(img,'W04_P2_expected.png'));

%% ---- Problem 3 : the current, and the offset that stays ----------------
y = run_one(struct('law',1,'V_c',0.3,'beta_c',pi/2,'T_final',200,'y0',0));
k = y.t >= 150;
beta = mean(atan2(y.v(k), y.u(k)));   pred = Delta*tan(beta);
f = lab_fig('W04 P3 expected', 940, 380);
subplot(1,3,1);
plot(y.y, y.x, 'LineWidth',1.6); hold on; grid on; axis equal
plot([0 0], [0 160], '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
track_ships({[y.x y.y rad2deg(y.psi)]}, [0 0.45 0.74], 'Marks', 8);
xlabel('east  y^n  [m]'); ylabel('north  x^n  [m]');
title('parallel to the path, beside it, for ever');
subplot(1,3,2);
plot(y.t, y.y_e, 'LineWidth',1.6, 'Color',[0.75 0.10 0.10]); hold on; grid on
yline(pred, '--', sprintf('\\Delta tan\\beta_c = %.3f m', pred), ...
      'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('y_e^p  [m]');
title('and it settles exactly on the prediction');
subplot(1,3,3);
he = rad2deg(mod(y.psi_d - y.psi + pi, 2*pi) - pi);
plot(y.t, he, 'LineWidth',1.6, 'Color',[0.47 0.67 0.19]); hold on; grid on
yline(0,'--'); ylim([-5 5]);
xlabel('time  [s]'); ylabel('\psi_d - \psi  [deg]');
title('while the HEADING error is already zero');
save_png(f, fullfile(img,'W04_P3_expected.png'));

close all; bdclose('all');
fprintf('\n  three expected-result figures written to %s\n\n', img);
end

% =========================================================================
function y = run_one(V)
cfg = otter_config('base');
W   = [0 0; 60 0; 60 60; 0 60; 60 120];  b = 'base';
assignin(b,'h',0.02);          assignin(b,'T_final',V.T_final);
assignin(b,'WP_N',W(:,1));     assignin(b,'WP_E',W(:,2));
assignin(b,'Delta',8);         assignin(b,'law',V.law);
assignin(b,'Kp',100);          assignin(b,'Kd',74.9);  assignin(b,'X_ff',60);
assignin(b,'k_pos',cfg.k_pos); assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max); assignin(b,'n_min',cfg.n_min);
assignin(b,'y_pont',0.395);
assignin(b,'mp',25);           assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',V.V_c);       assignin(b,'beta_c',V.beta_c);
x0 = zeros(12,1);  x0(8) = V.y0;  assignin(b,'x0',x0);
assignin(b,'animate',0);       assignin(b,'animate_every',0.5);
evalin(b, 'bdclose(''W04_S1'');');
load_system('W04_S1');
set_param('W04_S1','StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, 'sim(''W04_S1'');');
S = evalin(b,'xlog');  X = squeeze(S.signals.values);  if size(X,1)==12, X=X.'; end
G = squeeze(evalin(b,'glog').signals.values);          if size(G,1)==3,  G=G.'; end
y.t = S.time;
y.u = X(:,1);  y.v = X(:,2);  y.x = X(:,7);  y.y = X(:,8);  y.psi = X(:,12);
y.pi_p = G(:,1);  y.y_e = G(:,2);  y.psi_d = G(:,3);
end

function save_png(f, out)
exportgraphics(f, out, 'Resolution', 110);
d = dir(out);  fprintf('  %-46s %5.0f KB\n', out, d.bytes/1024);
end
