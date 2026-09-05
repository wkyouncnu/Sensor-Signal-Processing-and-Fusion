%% W04 · section E — what the look-ahead distance trades against what
%
%      W04_0_setup
%      W04_E_lookahead_distance
%
%  Delta is the one number a LOS law has. Small Delta closes hard and
%  overshoots; large Delta is lazy and never quite arrives.
%  Produces img/W04_result_lookahead.png

clear V DD i o y k f R sw
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_guidance.slx')), W04_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V  = W04_vars;
DD = [2 4 8 16 30];

%  The vessel is started 8 m off the path so that every run has the same
%  disturbance to recover from. A run that starts ON the path measures
%  nothing about how hard the law pulls.
V.x0(8) = 8;                      % initial East position [m]

fprintf('\n  W04 section E — the look-ahead distance, started 8 m off the path\n\n');
fprintf('    %8s %8s %14s %14s %14s %14s\n', ...
        'Delta', 'Delta/L', 'settle [m]', 'overshoot [m]', 'settled |y_e|', 'max |psi_d''| ');
fprintf('    %s\n', repmat('-', 1, 82));

R  = cell(size(DD));
sw = zeros(numel(DD), 4);
ok = false(1, numel(DD));         % did this Delta settle before the leg ended?
for i = 1:numel(DD)
    o    = run_sim('W04_guidance', V, 'Delta', DD(i));
    y    = W04_read(o);
    R{i} = y;

    %  Everything is measured on LEG 1, before the first corner: the recovery
    %  from a known offset is the experiment, and a corner would contaminate it.
    k  = round(y.wp(:,2)) == 1;
    ye = y.y_e(k,2);
    tt = y.t(k);
    NN = y.trkN(k,2);

    %  Settling distance: how far NORTH the vessel had travelled by the time
    %  |y_e| stayed under 0.4 m. A distance, not a time, because the vessel's
    %  speed is the same in every run and distance is what a chart shows.
    j  = find(abs(ye) > 0.4, 1, 'last');
    if isempty(j)
        d_settle = 0;  reached = true;
    elseif j >= numel(ye) - 1
        %  Never got inside the band before the leg ended. Reporting the leg
        %  length here would read like a settling distance, and it is not one.
        d_settle = NaN;  reached = false;
    else
        d_settle = NN(j+1);  reached = true;
    end

    over = max(-ye);                                % overshoot past the path
    kk   = tt > 0.7*tt(end);
    sw(i,:) = [d_settle, over, mean(abs(ye(kk))), max(abs(diff(y.psi_d(k,2))))/V.h];
    ok(i)   = reached;

    if reached, ds = sprintf('%14.2f', d_settle);
    else,       ds = '   not on leg 1';
    end
    fprintf('    %8g %8.1f %s %14.3f %14.4f %14.2f\n', ...
            DD(i), DD(i)/2.0, ds, sw(i,2), sw(i,3), sw(i,4));
end

%  The sentence is built from the table rather than from fixed indices. An
%  earlier version quoted sw(4,1) by hand and printed "NaN m" the moment
%  Delta = 16 stopped settling inside leg 1 — a number the reader cannot use.
iL = find(ok, 1, 'last');            % largest Delta that DID settle
iF = find(~ok);                      % the ones that did not
fail = strjoin(arrayfun(@(d) sprintf('%g', d), DD(iF), 'uni', 0), ' and ');

fprintf(['\n    TWO FAILURES, ONE AT EACH END.\n' ...
         '\n    Small Delta: the arctan saturates almost at once, the vessel\n' ...
         '    turns nearly perpendicular to the path, arrives fast and\n' ...
         '    OVERSHOOTS - %.3f m at Delta = %g against %.3f m at Delta = %g.\n' ...
         '\n    Large Delta: the correction is gentle, nothing overshoots, and\n' ...
         '    the settling distance grows with every step: %.0f m at Delta = %g\n' ...
         '    against %.0f m at Delta = %g.\n'], ...
         sw(1,2), DD(1), sw(end,2), DD(end), ...
         sw(iL,1), DD(iL), sw(1,1), DD(1));

if ~isempty(iF)
    fprintf(['\n    At Delta = %s the vessel never gets within 0.4 m before the\n' ...
             '    60 m leg ends, so there is NO settling distance to report and\n' ...
             '    the table says so instead of quoting the leg length. At the\n' ...
             '    largest, Delta = %g, the settled error is %.2f m: the law is no\n' ...
             '    longer following the path, only leaning towards it.\n'], ...
             fail, DD(end), sw(end,3));
end

fprintf(['\n    The rule of thumb is Delta = 2 to 5 hull lengths, here 4 to 10 m,\n' ...
         '    and the table is why: it is the band where neither failure has\n' ...
         '    started. Delta = %g m is the default of this week.\n'], V.Delta);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 E  look-ahead', 1150, 470);
COL = lines(numel(DD));

subplot(1,2,1); hold on;
for i = 1:numel(DD)
    k = round(R{i}.wp(:,2)) == 1;
    plot(R{i}.trkE(k,2), R{i}.trkN(k,2), 'Color', COL(i,:), ...
         'DisplayName', sprintf('\\Delta = %g m', DD(i)));
end
plot([0 0], [0 60], '--', 'Color',[0.6 0.6 0.6], 'LineWidth',1.4, 'DisplayName','the path');
%  NOT axis equal. The leg is 60 m long and the whole story happens inside
%  9 m of East, so an equal aspect ratio squeezes every track onto the path
%  line and shows nothing. The axes are labelled, so the distortion is honest.
xlim([-1.2 9]); ylim([0 60]); grid on;
xlabel('East  [m]   (the vessel starts 8 m out)'); ylabel('North [m]');
legend('Location','northeast');
title({'closing on the path from 8 m out', ...
       'leg 1 only; note the axes are not to the same scale'});

subplot(1,2,2); hold on;
yyaxis left
plot(DD, sw(:,1), 'o-', 'LineWidth',1.5);
ylabel('distance to settle within 0.4 m [m]');
%  A NaN leaves a silent gap in the line, and a marker parked at some
%  fraction of the axis height reads as a measured value. Both are wrong.
%  Instead the axis is extended past the LENGTH OF THE LEG and the missing
%  points are drawn above that line, where "beyond 60 m" is what they mean.
ylim([10 72]);
plot([0 32], [60 60], '--', 'Color',[0.45 0.45 0.45], 'LineWidth',1.2);
text(31, 57.5, 'leg 1 ends at 60 m', 'FontSize',9, ...
     'HorizontalAlignment','right', 'Color',[0.35 0.35 0.35]);
if ~isempty(iF)
    plot(DD(iF), repmat(67, 1, numel(iF)), 'x', 'Color',[0.75 0.2 0.2], ...
         'MarkerSize', 11, 'LineWidth', 2);
    text(mean(DD(iF)), 70, 'never gets inside 0.4 m before the leg ends', ...
         'FontSize', 9, 'HorizontalAlignment','center', 'Color',[0.75 0.2 0.2]);
end
xlim([0 32]);
yyaxis right
plot(DD, sw(:,2), 's--', 'LineWidth',1.5);
ylabel('overshoot past the path [m]');
xlabel('\Delta  look-ahead distance [m]');
grid on;
title({'the trade, and it is not symmetric', ...
       'overshoot dies quickly; settling distance grows without limit'});

sgtitle('W04 E — \Delta is the only number a LOS law has', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_lookahead.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_lookahead.png\n\n');
