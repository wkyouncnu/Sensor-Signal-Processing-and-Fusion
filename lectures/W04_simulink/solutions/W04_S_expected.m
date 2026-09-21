function W04_S_expected()
%W04_S_EXPECTED  올바른 4주차 제출물이 내야 하는 결과 그래프를 만든다.
%                The result graphs a correct Week 4 submission must produce.
%
%   >> W04_S_expected
%
%   모범답안을 세 가지로 돌려 문제마다 PNG 를 하나씩 ../problems/img/ 에 쓴다.
%   Runs the reference solution three ways and writes one PNG per problem into
%   ../problems/img/. Only the output crosses into problems/; the solution
%   code stays here.
%
%   See also W04_CHECK, W04_S1_HEADING_LOOP.

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
img  = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
close all; bdclose('all');

%% ---- Problem 1 : P only — no error, and more gain rings more ------------
f = lab_fig('W04 P1 expected', 900, 380);
G = [100 300];
for Kp = G
    y = run_one(struct('Kp',Kp,'Kd',0));
    subplot(1,2,1); hold on; plot(y.t, y.psi, 'LineWidth', 1.5);
    subplot(1,2,2); hold on; plot(y.t, 10 - y.psi, 'LineWidth', 1.5);
end
subplot(1,2,1); grid on; yline(10, '--', '\psi_d = 10\circ', 'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('heading  \psi  [deg]'); xlim([0 20]);
title('both gains arrive; the larger one rings more');
legend(compose('K_p = %g', G), 'Location','southeast');
subplot(1,2,2); grid on; yline(0,'--'); xlim([5 20]);
xlabel('time  [s]'); ylabel('error  \psi_d - \psi  [deg]'); title('the error goes to zero at every gain');
save_png(f, fullfile(img,'W04_P1_expected.png'));

%% ---- Problem 2 : the derivative damps the heading ---------------------
f = lab_fig('W04 P2 expected', 900, 380);
K = [0 25 50 100];  Mp = zeros(size(K));
for i = 1:numel(K)
    y = run_one(struct('Kp',300,'Kd',K(i)));
    subplot(1,2,1); hold on; plot(y.t, y.psi, 'LineWidth', 1.5);
    Mp(i) = max(step_metrics(y.t, y.psi, 10, 5), 0);
end
subplot(1,2,1); grid on; yline(10, '--', '\psi_d = 10\circ', 'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('heading  \psi  [deg]'); xlim([0 15]);
title('overshoot FALLS as K_d rises (K_p = 300)');
legend(compose('K_d = %g', K), 'Location','southeast');
subplot(1,2,2); plot(K, Mp, 'o-', 'LineWidth', 1.6, 'MarkerFaceColor','w'); grid on;
xlabel('K_d  [N m s/rad]'); ylabel('overshoot  [%]'); title('12.2 % to 0.4 %');
save_png(f, fullfile(img,'W04_P2_expected.png'));

%% ---- Problem 3 : the wrap ----------------------------------------------
x0 = zeros(12,1); x0(12) = deg2rad(170);
V = struct('Kp',300,'Kd',100,'psi_step',-170,'t_step',0,'T_final',60);
V.use_ssa = 1;  yOn  = run_one(V, x0);
V.use_ssa = 0;  yOff = run_one(V, x0);
f = lab_fig('W04 P3 expected', 900, 360);
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
yline(0,'--'); xlabel('time  [s]'); ylabel('yaw rate  r  [deg/s]');
title('and the yaw rates have OPPOSITE sign');
save_png(f, fullfile(img,'W04_P3_expected.png'));

close all; bdclose('all');
fprintf('\n  three expected-result figures written to %s\n\n', img);
end

% =========================================================================
function y = run_one(V, x0)
if nargin < 2, x0 = zeros(12,1); end
D = struct('Kp',300, 'Ki',0, 'Kd',0, 'Nf',20, 'use_ssa',1, 'psi_step',10, 't_step',5, 'T_final',40);
f = fieldnames(V);
for i = 1:numel(f), D.(f{i}) = V.(f{i}); end
cfg = otter_config('base');  b = 'base';
f = fieldnames(D);
for i = 1:numel(f), assignin(b, f{i}, D.(f{i})); end
assignin(b,'h',0.02);          assignin(b,'X_ff',60);
assignin(b,'k_pos',cfg.k_pos); assignin(b,'k_neg',cfg.k_neg);
assignin(b,'n_max',cfg.n_max); assignin(b,'n_min',cfg.n_min);
assignin(b,'y_pont',cfg.y_pont);
assignin(b,'mp',25);           assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);           assignin(b,'beta_c',0);   assignin(b,'x0',x0);
evalin(b, 'bdclose(''W04_S1'');');
load_system('W04_S1');
set_param('W04_S1','StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, 'sim(''W04_S1'');');
S = evalin(b,'xlog');
x = squeeze(S.signals.values);  if size(x,1)==12, x = x.'; end
y.t = S.time;  y.psi = rad2deg(x(:,12));  y.r = rad2deg(x(:,6));
end

function save_png(f, out)
exportgraphics(f, out, 'Resolution', 110);
d = dir(out);  fprintf('  %-46s %5.0f KB\n', out, d.bytes/1024);
end
