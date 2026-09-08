function W02_S_expected()
%W02_S_EXPECTED  The result graphs a correct Week 2 submission must produce.
%
%   >> W02_S_expected
%
%   Runs the reference solution three ways and writes one PNG per problem into
%   ../problems/img/. The problem sheet shows those, so a student can compare
%   a plot against the plot rather than against a number alone.
%
%   Only the OUTPUT crosses into problems/. The solution code stays here.
%
%   See also W02_CHECK, W02_S1_SPEED_LOOP.

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
img  = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
close all; bdclose('all');

Ku = 0.012894;

%% ---- Problem 1 : the open loop is first order, and its DC gain is exact -
f = lab_fig('W02 P1 expected', 900, 360);
subplot(1,2,1); hold on; grid on
C = lines(3);  k = 0;
for X = [50 100 200]
    k = k + 1;
    y = run_one(struct('loop_closed',0,'X_open',X,'u_d',0,'Kp',0,'Ki',0,'T_final',40));
    plot(y.t, y.u, 'LineWidth', 1.5, 'Color', C(k,:));
    yline(Ku*X, '--', sprintf('K_u X = %.4f', Ku*X), 'Color', C(k,:), ...
          'LabelHorizontalAlignment','left', 'FontSize',8);
end
xlabel('time  [s]'); ylabel('surge  u  [m/s]');
title('u = K_u X, exactly');
legend('X = 50 N','','X = 100 N','','X = 200 N','', 'Location','southeast');

subplot(1,2,2); hold on; grid on
X  = 0:10:239;
plot(X, Ku*X, 'LineWidth', 1.6);
plot([50 100 200], Ku*[50 100 200], 'o', 'MarkerFaceColor','w', 'LineWidth',1.4);
xline(239.364, '--', 'X_{max} = 239.364 N', 'LabelVerticalAlignment','bottom');
xlabel('demanded force  X  [N]'); ylabel('settled  u  [m/s]');
title('the straight line the three runs land on');
save_png(f, fullfile(img,'W02_P1_expected.png'));

%% ---- Problem 2 : proportional only, and the gap that never closes ------
f = lab_fig('W02 P2 expected', 900, 380);
subplot(1,2,1); hold on; grid on
ud = 1.5;  G = [100 500 2000];  U = zeros(size(G));
for k = 1:3
    y = run_one(struct('loop_closed',1,'X_open',0,'u_d',ud,'Kp',G(k),'Ki',0,'T_final',40));
    plot(y.t, y.u, 'LineWidth', 1.5);
    U(k) = y.u(end);
end
yline(ud, '--', 'u_d = 1.5 m/s', 'LabelHorizontalAlignment','left');
%  머리 공간을 둔다. ylim 을 1.5 로 두면 기준선이 축과 겹쳐서, "아무도
%  닿지 못한다" 는 그림의 요점이 보이지 않는다.
ylim([0 1.7]);
xlabel('time  [s]'); ylabel('surge  u  [m/s]');
title('none of them reaches the dashed line');
legend(compose('K_p = %g', G), 'Location','southeast');

subplot(1,2,2); hold on; grid on
Kp = logspace(1.5, 4, 60);
plot(Kp, 100*(1 - Kp*Ku./(1 + Kp*Ku)), 'LineWidth', 1.6);
plot(G, 100*(ud - U)/ud, 'o', 'MarkerFaceColor','w', 'LineWidth',1.4);
set(gca,'XScale','log'); ylim([0 60]);
xlabel('K_p'); ylabel('steady-state error  [%]');
title('the error falls, and never reaches zero');
save_png(f, fullfile(img,'W02_P2_expected.png'));

%% ---- Problem 3 : the integrator closes it, and buys overshoot ----------
yP  = run_one(struct('loop_closed',1,'X_open',0,'u_d',1.5,'Kp',102,'Ki',0,     'T_final',40));
yPI = run_one(struct('loop_closed',1,'X_open',0,'u_d',1.5,'Kp',102,'Ki',192.38,'T_final',40));
f = lab_fig('W02 P3 expected', 900, 360);
subplot(1,2,1); hold on; grid on
plot(yP.t,  yP.u,  'LineWidth',1.5);
plot(yPI.t, yPI.u, 'LineWidth',1.7);
yline(1.5, '--', 'u_d = 1.5 m/s', 'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('surge  u  [m/s]');
title('P stops short; PI arrives');
legend({'P only  (K_i = 0)','PI'}, 'Location','southeast');

subplot(1,2,2); hold on; grid on
plot(yP.t,  1.5 - yP.u,  'LineWidth',1.5);
plot(yPI.t, 1.5 - yPI.u, 'LineWidth',1.7);
yline(0, '--');
xlabel('time  [s]'); ylabel('error  u_d - u  [m/s]');
title('and the PI error crosses zero — that is the overshoot');
legend({'P only','PI'}, 'Location','northeast');
save_png(f, fullfile(img,'W02_P3_expected.png'));

close all; bdclose('all');
fprintf('\n  three expected-result figures written to %s\n\n', img);
end

% =========================================================================
function y = run_one(V)
b = 'base';
assignin(b,'h',0.02);              assignin(b,'T_final',V.T_final);
assignin(b,'loop_closed',V.loop_closed);
assignin(b,'X_open',V.X_open);     assignin(b,'u_d',V.u_d);
assignin(b,'Kp',V.Kp);             assignin(b,'Ki',V.Ki);
assignin(b,'Kd',0);                assignin(b,'Nf',20);
assignin(b,'mp',25);               assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);               assignin(b,'beta_c',0);
assignin(b,'x0',zeros(12,1));      assignin(b,'t_step',5);
assignin(b,'animate',0);           assignin(b,'animate_every',0.5);
evalin(b, 'bdclose(''W02_S1'');');
load_system('W02_S1');
set_param('W02_S1','StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, 'sim(''W02_S1'');');
S = evalin(b,'xlog');
x = squeeze(S.signals.values);  if size(x,1)==12, x = x.'; end
y.t = S.time;  y.u = x(:,1);
end

function save_png(f, out)
exportgraphics(f, out, 'Resolution', 110);
d = dir(out);
fprintf('  %-46s %5.0f KB\n', out, d.bytes/1024);
end
