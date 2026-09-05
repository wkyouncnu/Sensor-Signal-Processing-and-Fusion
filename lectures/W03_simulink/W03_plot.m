function f = W03_plot(R, LBL, ttl)
%W03_PLOT  Heading, yaw rate, yaw moment and track of one or more W03 runs.
%
%   W03_plot                      the run sitting in the base workspace
%   W03_plot(R, LBL, ttl)         a cell array of runs, for W03_run
%
%   Called automatically by the model's StopFcn, so pressing Run produces the
%   figure without any further command.
%
%   R is a cell array of structs with fields t and y, where the columns of y are
%
%     1 psi_d[deg]  2 psi[deg]  3 r[deg/s]  4 tau_N[N m]  5 n1  6 n2  7 N  8 E

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''W03'',''var'')'), return, end
    W = evalin('base', 'W03');
    y = squeeze(W.signals.values);  if size(y,1) < size(y,2), y = y.'; end
    R = {struct('t', W.time, 'y', w03_cols(y))};
    LBL = {'run'};
    ttl = 'W03 heading control — result of the last simulation';
end
if nargin < 2 || isempty(LBL), LBL = arrayfun(@(k) sprintf('run %d', k), ...
                                              1:numel(R), 'UniformOutput', false); end
if nargin < 3 || isempty(ttl), ttl = 'W03 heading control'; end

COL = [0    0.45 0.74
       0.85 0.33 0.10
       0.47 0.67 0.19
       0.49 0.18 0.56];
c = @(i) COL(1+mod(i-1,4),:);

f = lab_fig('W03  heading loop', 1150, 660);

% -- heading ---------------------------------------------------------------
subplot(2,3,[1 2]); hold on;
plot(R{1}.t, R{1}.y(:,1), ':', 'Color',[0.35 0.35 0.35], 'LineWidth',1.4);
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,2), 'Color', c(i), 'LineWidth',1.3); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
legend([{'\psi_d'} LBL], 'Location','best', 'Interpreter','none');
title('heading');

% -- error -----------------------------------------------------------------
subplot(2,3,3); hold on;
for i = 1:numel(R)
    e = R{i}.y(:,1) - R{i}.y(:,2);
    plot(R{i}.t, e, 'Color', c(i));
end
yline(0,'k:');
xlabel('time [s]'); ylabel('\psi_d - \psi  [deg]');
title({'error', 'a type 1 plant reaches zero'});

% -- yaw rate --------------------------------------------------------------
subplot(2,3,4); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,3), 'Color', c(i)); end
yline(0,'k:');
xlabel('time [s]'); ylabel('r  yaw rate [deg/s]');
title('what the D term feeds on');

% -- yaw moment and shafts -------------------------------------------------
subplot(2,3,5); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,4), 'Color', c(i)); end
yline(0,'k:');
xlabel('time [s]'); ylabel('\tau_N  [N\cdotm]');
title('the demanded yaw moment');

% -- track -----------------------------------------------------------------
subplot(2,3,6); hold on; axis equal;
for i = 1:numel(R), plot(R{i}.y(:,8), R{i}.y(:,7), 'Color', c(i)); end
track_ships(cellfun(@(q) q.y(:,[7 8 2]), R, 'UniformOutput', false), COL, 'Marks', 6);
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
xlabel('East [m]'); ylabel('North [m]');
title('track — hull and heading');

sgtitle(ttl, 'FontWeight','bold');
end

% -------------------------------------------------------------------------
function z = w03_cols(y)
%W03_COLS  The course logging contract, reordered for this week.
%
%   add_measurement logs [u v r N E psi | psi_d tau_N n1 n2], with psi already
%   in degrees, r in rad/s and psi_d in radians. This week works in
%   [psi_d psi r tau_N n1 n2 N E], all angles in degrees.
z = [rad2deg(y(:,7)), y(:,6), rad2deg(y(:,3)), y(:,8), y(:,9), y(:,10), y(:,4), y(:,5)];
end
