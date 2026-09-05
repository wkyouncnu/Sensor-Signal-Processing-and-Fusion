function f = A1_plot(R, LBL, ttl)
%A1_PLOT  States, generalised force and track of one or more A1 runs.
%
%   A1_plot                      the run sitting in the base workspace
%   A1_plot(R, LBL, ttl)         a cell array of runs, for A1_E_command_that_turns
%   f = A1_plot(...)             the figure handle
%
%   Called automatically by the model's StopFcn, so pressing Run produces the
%   figure without any further command. Section E calls the same function.
%
%   R is a cell array of structs with fields
%     t    time
%     y    [u  v  r(rad/s)  N  E  psi(deg)]
%     tau  [X  Y  N]                        the generalised force

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''A1'',''var'')'), return, end
    W = evalin('base', 'A1');
    y = squeeze(W.signals.values);  if size(y,1) < size(y,2), y = y.'; end
    %  add_measurement logs [u v r N E psi | tau], so tau is columns 7:9.
    R = {struct('t', W.time, 'y', y(:,1:6), 'tau', y(:,7:9))};
    if evalin('base', 'exist(''n_cmd'',''var'')')
        n = evalin('base', 'n_cmd');
        LBL = {sprintf('n = [%g, %g]', n(1), n(2))};
    else
        LBL = {'run'};
    end
    ttl = 'A1 actuation — result of the last simulation';
end
if nargin < 2 || isempty(LBL), LBL = arrayfun(@(k) sprintf('run %d', k), ...
                                              1:numel(R), 'UniformOutput', false); end
if nargin < 3 || isempty(ttl), ttl = 'A1 actuation'; end

COL = [0    0.45 0.74
       0.85 0.33 0.10
       0.47 0.67 0.19
       0.49 0.18 0.56];
c = @(i) COL(1+mod(i-1,4),:);

f = lab_fig('A1  force and response', 1150, 680);

%  Top row: what the column rule says the vessel is being pushed with.
S = {'X  surge force [N]', 'Y  sway force [N]', 'N  yaw moment [N\cdotm]'};
for s = 1:3
    subplot(2,3,s); hold on;
    for i = 1:numel(R), plot(R{i}.t, R{i}.tau(:,s), 'Color', c(i)); end
    xlabel('time [s]'); ylabel(S{s});
    if s == 1, legend(LBL, 'Location','best', 'Interpreter','none'); end
    if s == 2
        %  Y is identically zero, so an auto-ranged axis shows numerical dust
        %  at 1e-16 and reads as if something were happening. It is not.
        ylim([-1 1]); title('empty by construction, not by tuning');
    end
end

%  Bottom row: what the vessel actually did.
subplot(2,3,4); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,1), 'Color', c(i)); end
xlabel('time [s]'); ylabel('u  surge [m/s]');
title('the creep that X predicts');

subplot(2,3,5); hold on;
for i = 1:numel(R), plot(R{i}.t, rad2deg(R{i}.y(:,3)), 'Color', c(i)); end
xlabel('time [s]'); ylabel('r  yaw rate [deg/s]');
title('the turn that N predicts');

%  Only the turning runs go on the track panel when there are three. The
%  straight-ahead run covers 60 m and the two turns cover two, so plotting all
%  three on one pair of equal axes reduces the comparison this figure exists to
%  make into a single dot at the origin.
if numel(R) == 3, ti = [2 3]; else, ti = 1:numel(R); end

%  ONE silhouette per track, at the final pose. These vessels turn on the spot:
%  the whole track is smaller than the hull, so several true-size silhouettes
%  are drawn on top of each other and hide the track they annotate. The hull
%  and the heading are still shown, which is what the track rule asks for.
subplot(2,3,6); hold on; axis equal;
for i = ti
    track_ships({R{i}.y(:,[4 5 6])}, c(i), 'Marks', 1, 'Heading', 0.8);
end
for i = ti
    plot(R{i}.y(:,5), R{i}.y(:,4), 'Color', c(i), 'LineWidth', 1.6);
    plot(R{i}.y(end,5), R{i}.y(end,4), 'o', 'Color', c(i), ...
         'MarkerFaceColor', c(i), 'MarkerSize', 7);
end
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'MarkerSize', 8);
%  Room for the heading lines, which otherwise run off the top of the axes.
axis padded;
xlabel('East [m]'); ylabel('North [m]');
if numel(R) == 3
    title({'track — the two turning commands only', ...
           sprintf('drift %.2f m against %.2f m', ...
                   hypot(R{2}.y(end,4), R{2}.y(end,5)), ...
                   hypot(R{3}.y(end,4), R{3}.y(end,5)))});
else
    title('track — hull and heading');
end

sgtitle(ttl, 'FontWeight','bold');
end
