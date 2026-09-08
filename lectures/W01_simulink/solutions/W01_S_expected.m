function W01_S_expected()
%W01_S_EXPECTED  The result graphs a correct Week 1 submission must produce.
%
%   >> W01_S_expected
%
%   Runs the three reference solutions and writes one PNG per problem into
%   ../problems/img/. The problem sheet shows those, so a student can compare
%   a plot against the plot rather than against a number alone.
%
%   WHY THE PROBLEM SHEET GETS THE PICTURES AND NOT THE CODE
%
%   A number tells a student whether the answer is right. A picture tells them
%   what "right" looks like while they are still building — a track that bends
%   the wrong way, a speed that never settles, a heading that runs off the top
%   of the axis are all visible long before any checker is run. The solution
%   scripts stay in this folder; only their OUTPUT crosses into problems/.
%
%   The figures are produced by running the solution models, so they cannot
%   drift from what the checker measures.
%
%   See also W01_CHECK, W01_S1_OPENLOOP, W01_S2_MANOEUVRE, W01_S3_CURRENT.

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
img  = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();

close all; bdclose('all');

%% ---- Problem 1 : the open loop -----------------------------------------
y = run_one('W01_S1', struct('n0',60,'dn',0,'t_phase',[1e9 1e9 1e9 1e9], ...
                             'V_c',0,'beta_c',0,'T_final',60));
f = lab_fig('W01 P1 expected', 900, 360);
subplot(1,2,1);
plot(y.t, y.u, 'LineWidth', 1.6); hold on
yline(1.0286, '--', '1.0286 m/s', 'LabelHorizontalAlignment','left');
xlabel('time  [s]'); ylabel('surge  u  [m/s]');
title('u settles where thrust balances damping');
ylim([0 1.2]);
subplot(1,2,2);
plot(y.E, y.N, 'LineWidth', 1.6); hold on; axis equal; grid on
track_ships({[y.N y.E y.psi]}, [0 0.45 0.74], 'Marks', 5);
xlabel('East  [m]'); ylabel('North  [m]');
title('due north, and never turning');
save_png(f, fullfile(img,'W01_P1_expected.png'));

%% ---- Problem 2 : the manoeuvre -----------------------------------------
y = run_one('W01_S2', struct('n0',60,'dn',3.5,'t_phase',[30 60 90 120], ...
                             'V_c',0,'beta_c',0,'T_final',150));
f = lab_fig('W01 P2 expected', 980, 420);
subplot(2,3,1); plot(y.t,y.u,'LineWidth',1.4); ylabel('u  [m/s]'); title('surge');
subplot(2,3,2); plot(y.t,y.v,'LineWidth',1.4,'Color',[0.85 0.33 0.10]);
                ylabel('v  [m/s]'); title('sway — note the SIGN CHANGE');
subplot(2,3,4); plot(y.t,y.r,'LineWidth',1.4,'Color',[0.47 0.67 0.19]);
                ylabel('r  [deg/s]'); xlabel('time  [s]'); title('yaw rate');
subplot(2,3,5); plot(y.t,y.psi,'LineWidth',1.4,'Color',[0.49 0.18 0.56]);
                ylabel('\psi  [deg]'); xlabel('time  [s]'); title('heading');
subplot(2,3,[3 6]);
plot(y.E, y.N, 'LineWidth', 1.6); hold on; axis equal; grid on
track_ships({[y.N y.E y.psi]}, [0 0.45 0.74], 'Marks', 9);
xlabel('East  [m]'); ylabel('North  [m]'); title('straight, port, straight, starboard');
save_png(f, fullfile(img,'W01_P2_expected.png'));

%% ---- Problem 3 : the current -------------------------------------------
y = run_one('W01_S3', struct('n0',60,'dn',0,'t_phase',[1e9 1e9 1e9 1e9], ...
                             'V_c',0.5,'beta_c',pi/2,'T_final',120));
f = lab_fig('W01 P3 expected', 900, 380);
subplot(1,2,1);
plot(y.E, y.N, 'LineWidth', 1.6); hold on; axis equal; grid on
track_ships({[y.N y.E y.psi]}, [0 0.45 0.74], 'Marks', 8);
%  The hull points north while the track leans east. Drawing both is the
%  whole answer to Problem 3.
plot([0 y.E(end)], [0 y.N(end)], '--', 'Color',[0.75 0.10 0.10], 'LineWidth',1.2);
xlabel('East  [m]'); ylabel('North  [m]');
title('the hull points north; the track does not');
subplot(1,2,2);
plot(y.t, y.psi, 'LineWidth',1.4, 'Color',[0.49 0.18 0.56]); hold on
yline(0,'--');
xlabel('time  [s]'); ylabel('\psi  [deg]');
title('and it weathervanes ~4\circ with no yaw command');
save_png(f, fullfile(img,'W01_P3_expected.png'));

close all; bdclose('all');
fprintf('\n  three expected-result figures written to %s\n\n', img);
end

% =========================================================================
function y = run_one(mdl, V)
b = 'base';
assignin(b,'h',0.02);            assignin(b,'T_final',V.T_final);
assignin(b,'n0',V.n0);           assignin(b,'dn',V.dn);
assignin(b,'t_phase',V.t_phase);
assignin(b,'mp',25);             assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',V.V_c);         assignin(b,'beta_c',V.beta_c);
assignin(b,'x0',zeros(12,1));
assignin(b,'animate',0);         assignin(b,'animate_every',0.5);
evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b,'xlog');
x = squeeze(S.signals.values);  if size(x,1)==12, x = x.'; end
y.t = S.time;  y.u = x(:,1);  y.v = x(:,2);  y.r = rad2deg(x(:,6));
y.N = x(:,7);  y.E = x(:,8);  y.psi = rad2deg(x(:,12));
end

function save_png(f, out)
exportgraphics(f, out, 'Resolution', 110);
d = dir(out);
fprintf('  %-46s %5.0f KB\n', out, d.bytes/1024);
end
