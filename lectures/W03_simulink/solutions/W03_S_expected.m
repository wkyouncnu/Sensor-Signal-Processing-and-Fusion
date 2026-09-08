function W03_S_expected()
%W03_S_EXPECTED  The result graphs a correct Week 3 submission must produce.
%
%   >> W03_S_expected
%
%   Runs the reference solution three ways and writes one PNG per problem into
%   ../problems/img/. Only the OUTPUT crosses into problems/; the solution
%   code stays here.
%
%   See also W03_CHECK, W03_S1_HEADING_LOOP.

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
img  = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
close all; bdclose('all');
M66 = 42.65;  Nr = -42.65;

%% ---- Problem 1 : proportional only, and the error that is already zero --
f = lab_fig('W03 P1 expected', 900, 380);
subplot(1,2,1); hold on; grid on
G = [30 100 300];
for Kp = G
    y = run_one(struct('Kp',Kp,'Kd',0,'use_ssa',1,'psi_1',60,'psi_2',60,'T_final',40));
    plot(y.t, y.psi, 'LineWidth', 1.5);
end
yline(60, '--', '\psi_d = 60\circ', 'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('heading  \psi  [deg]');
title('every gain arrives — the error is structural, not tuned');
legend(compose('K_p = %g', G), 'Location','southeast'); ylim([-5 70]);

subplot(1,2,2); hold on; grid on
for Kp = G
    y = run_one(struct('Kp',Kp,'Kd',0,'use_ssa',1,'psi_1',60,'psi_2',60,'T_final',40));
    plot(y.t, 60 - y.psi, 'LineWidth', 1.5);
end
yline(0,'--'); xlim([5 40]); ylim([-2 2]);
xlabel('time  [s]'); ylabel('error  \psi_d - \psi  [deg]');
title('the same runs as error — all three reach zero');
save_png(f, fullfile(img,'W03_P1_expected.png'));

%% ---- Problem 2 : derivative action, and overshoot falling --------------
f = lab_fig('W03 P2 expected', 900, 380);
subplot(1,2,1); hold on; grid on
K = [0 25 74.9 150];  Mp = zeros(size(K));
for i = 1:numel(K)
    y = run_one(struct('Kp',100,'Kd',K(i),'use_ssa',1,'psi_1',5,'psi_2',5,'T_final',40));
    plot(y.t, y.psi, 'LineWidth', 1.5);
    k = y.t >= 5;  Mp(i) = 100*(max(y.psi(k)) - 5)/5;
end
yline(5, '--', '\psi_d = 5\circ', 'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('heading  \psi  [deg]');
title('overshoot FALLS as K_d rises');
legend(compose('K_d = %g', K), 'Location','southeast'); xlim([0 25]);

subplot(1,2,2); hold on; grid on
z = (abs(Nr) + K)/(2*sqrt(100*M66));
plot(z, Mp, 'o-', 'LineWidth', 1.6, 'MarkerFaceColor','w');
for i = 1:numel(K)
    text(z(i), Mp(i)+0.7, sprintf('K_d = %g', K(i)), 'FontSize',8, ...
         'HorizontalAlignment','center');
end
xlabel('damping ratio  \zeta = (|N_r| + K_d) / 2\surd(K_p M_{66})');
ylabel('overshoot  [%]');
title('and it does so along the second-order curve');
ylim([-2 15]);
save_png(f, fullfile(img,'W03_P2_expected.png'));

%% ---- Problem 3 : the wrap ----------------------------------------------
x0 = zeros(12,1); x0(12) = deg2rad(170);
yOn  = run_one(struct('Kp',100,'Kd',74.9,'use_ssa',1,'psi_1',-170,'psi_2',-170,'t_up',0,'T_final',60), x0);
yOff = run_one(struct('Kp',100,'Kd',74.9,'use_ssa',0,'psi_1',-170,'psi_2',-170,'t_up',0,'T_final',60), x0);
f = lab_fig('W03 P3 expected', 900, 360);
subplot(1,2,1); hold on; grid on
plot(yOn.t,  yOn.psi,  'LineWidth',1.7);
plot(yOff.t, yOff.psi, 'LineWidth',1.5);
yline(170,'--'); yline(-170,'--');
xlabel('time  [s]'); ylabel('heading  \psi  [deg]   (unwrapped)');
title('170\circ \rightarrow -170\circ : two ways round');
legend({'with the wrap  (use\_ssa = 1)','without  (use\_ssa = 0)'}, 'Location','southwest');

subplot(1,2,2); hold on; grid on
plot(yOn.t,  yOn.r,  'LineWidth',1.7);
plot(yOff.t, yOff.r, 'LineWidth',1.5);
yline(0,'--');
xlabel('time  [s]'); ylabel('yaw rate  r  [deg/s]');
title('and the yaw rates have OPPOSITE sign');
save_png(f, fullfile(img,'W03_P3_expected.png'));

close all; bdclose('all');
fprintf('\n  three expected-result figures written to %s\n\n', img);
end

% =========================================================================
function y = run_one(V, x0)
if nargin < 2, x0 = zeros(12,1); end
cfg = otter_config('base');  b = 'base';
assignin(b,'h',0.02);          assignin(b,'T_final',V.T_final);
assignin(b,'Kp',V.Kp);         assignin(b,'Kd',V.Kd);
assignin(b,'use_ssa',V.use_ssa);
assignin(b,'psi_1',V.psi_1);   assignin(b,'psi_2',V.psi_2);
%  Problem 3 commands from t = 0 — see the note in W03_check.
if isfield(V,'t_up'), t_up = V.t_up; else, t_up = 5; end
assignin(b,'t_up',t_up);       assignin(b,'t_dn',1e6);
assignin(b,'X_ff',60);         assignin(b,'M66',42.65);  assignin(b,'Nr',-42.65);
assignin(b,'k_pos',cfg.k_pos); assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max); assignin(b,'n_min',cfg.n_min);
assignin(b,'y_pont',0.395);
assignin(b,'mp',25);           assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);           assignin(b,'beta_c',0);   assignin(b,'x0',x0);
assignin(b,'animate',0);       assignin(b,'animate_every',0.5);
evalin(b, 'bdclose(''W03_S1'');');
load_system('W03_S1');
set_param('W03_S1','StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, 'sim(''W03_S1'');');
S = evalin(b,'xlog');
x = squeeze(S.signals.values);  if size(x,1)==12, x = x.'; end
y.t = S.time;  y.psi = rad2deg(x(:,12));  y.r = rad2deg(x(:,6));
end

function save_png(f, out)
exportgraphics(f, out, 'Resolution', 110);
d = dir(out);  fprintf('  %-46s %5.0f KB\n', out, d.bytes/1024);
end
