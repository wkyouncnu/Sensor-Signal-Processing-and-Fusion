%% W04 · section F — when to give up on this waypoint and aim at the next
%
%      W04_0_setup
%      W04_F_waypoint_switching
%
%  Two criteria are in circulation and they are not the same. MSS switches on
%  the ALONG-TRACK distance remaining; most textbooks draw a CIRCLE OF
%  ACCEPTANCE. They agree on the path and disagree off it.
%  Produces img/W04_result_switching.png

clear V RR i j o y f k tsw d_corner COL lab
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_guidance.slx')), W04_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V  = W04_vars;
RR = [2 5 15 25];

%% ---- the two criteria, on paper ----------------------------------------
%  A vessel R short of the waypoint along the leg but 2R to the side of it.
d   = hypot(V.WP(2,1)-V.WP(1,1), V.WP(2,2)-V.WP(1,2));
pip = atan2(V.WP(2,2)-V.WP(1,2), V.WP(2,1)-V.WP(1,1));
t   = [cos(pip) sin(pip)];  nrm = [-sin(pip) cos(pip)];
P   = V.WP(1,:) + (d - V.R_switch + 0.5)*t + 2*V.R_switch*nrm;
[x_eP, y_eP] = crosstrack_err(P(1), P(2), V.WP(1,:), V.WP(2,:));

fprintf('\n  W04 section F — two switching criteria\n\n');
fprintf('    A vessel %.1f m short of waypoint 2 along the leg, %.1f m to the side:\n\n', ...
        d - x_eP, y_eP);
fprintf('      along-track,  d - x_e = %.2f < R = %g   ->  %s\n', ...
        d - x_eP, V.R_switch, ternary((d-x_eP) < V.R_switch, 'SWITCH', 'hold'));
fprintf('      circle,      |P - wp| = %.2f < R = %g   ->  %s\n', ...
        hypot(P(1)-V.WP(2,1), P(2)-V.WP(2,2)), V.R_switch, ...
        ternary(hypot(P(1)-V.WP(2,1),P(2)-V.WP(2,2)) < V.R_switch, 'SWITCH', 'hold'));
fprintf(['\n    They disagree, and the along-track test is the safer one: it\n' ...
         '    cannot be defeated by being far from the path. A vessel blown\n' ...
         '    wide of a waypoint never enters its circle and, with the circle\n' ...
         '    test, waits for it for ever.\n']);

%% ---- sweeping R, with the along-track criterion ------------------------
fprintf('\n  sweeping R with the along-track criterion (sw_mode = 1)\n\n');
fprintf('    %8s %14s %16s %16s\n', 'R [m]', 'corner cut [m]', 'switch times [s]', 'settled |y_e|');
fprintf('    %s\n', repmat('-', 1, 60));

RES = cell(size(RR));
for i = 1:numel(RR)
    o = run_sim('W04_guidance', V, 'R_switch', RR(i));
    y = W04_read(o);
    RES{i} = y;

    %  The corner cut: how close the vessel came to waypoint 2, the first
    %  90 deg corner. A large R turns early and cuts the corner off.
    d_corner = min(hypot(y.trkN(:,2)-V.WP(2,1), y.trkE(:,2)-V.WP(2,2)));
    tsw = y.t(find(diff(y.wp(:,2)) > 0));
    k   = y.t >= 0.75*y.t(end);   % the last quarter, as W04_plot uses
    fprintf('    %8g %14.2f %16s %16.3f\n', RR(i), d_corner, ...
            mat2str(round(tsw',0)), mean(abs(y.y_e(k,2))));
end

fprintf(['\n    R decides HOW EARLY the vessel gives up on the corner. Large R\n' ...
         '    turns sooner and cuts the corner; small R drives closer to the\n' ...
         '    waypoint and turns harder. Neither is wrong - a survey wants the\n' ...
         '    line held to its end, a transit wants the fuel saved.\n' ...
         '\n    The one hard limit: R MUST be smaller than the shortest leg,\n' ...
         '    here %.0f m. Above that the switching test is already satisfied\n' ...
         '    for a leg the vessel has not started, and the waypoint is skipped\n' ...
         '    without ever being approached. wp_switch raises an error on it.\n'], ...
         min(hypot(diff(V.WP(:,1)), diff(V.WP(:,2)))));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 F  switching', 1150, 470);
COL = lines(numel(RR));

subplot(1,2,1); hold on; axis equal;
plot(V.WP(:,2), V.WP(:,1), '--', 'Color',[0.6 0.6 0.6], 'DisplayName','planned path');
for i = 1:numel(RR)
    plot(RES{i}.trkE(:,2), RES{i}.trkN(:,2), 'Color', COL(i,:), ...
         'DisplayName', sprintf('R = %g m', RR(i)));
end
%  THE THRESHOLD DRAWN HERE IS A LINE, NOT A CIRCLE. The sweep runs the
%  along-track criterion, d - x_e < R, and section 4-6 spends a whole figure
%  establishing that this is NOT the circle of acceptance. Drawing circles
%  here — as an earlier version did — contradicts that page. Leg 1 runs due
%  North along E = 0, so d - x_e < R is the half-plane N > 60 - R, and its
%  boundary is a horizontal line.
for i = 1:numel(RR)
    plot([-30 30], (V.WP(2,1)-RR(i))*[1 1], ':', 'Color', COL(i,:), ...
         'LineWidth', 1.3, 'HandleVisibility','off');
    text(-29, V.WP(2,1)-RR(i)+1.6, sprintf('switches here, R = %g', RR(i)), ...
         'Color', COL(i,:), 'FontSize', 8);
end
plot(V.WP(:,2), V.WP(:,1), 'ko', 'MarkerFaceColor','w', 'HandleVisibility','off');
text(V.WP(2,2)+3, V.WP(2,1)+5, 'waypoint 2', 'FontSize', 9);
xlim([-30 70]); ylim([28 76]);
xlabel('East [m]'); ylabel('North [m]');
%  NO legend on this panel. Wherever it is put it covers either the threshold
%  labels or the tracks, and it would only repeat the right-hand panel's.
%  Each dotted line already carries its own R, in its own colour.
title({'the first corner, four values of R  (colours as on the right)', ...
       'dotted lines are the along-track threshold  d - x_e = R'});

subplot(1,2,2); hold on;
for i = 1:numel(RR)
    plot(RES{i}.t, RES{i}.wp(:,2), 'Color', COL(i,:), 'LineWidth',1.4, ...
         'DisplayName', sprintf('R = %g m', RR(i)));
end
xlabel('time [s]'); ylabel('active waypoint index');
ylim([0.5 4.5]); yticks(1:4); grid on;
legend('Location','southeast');
title({'when each vessel gave up on the current leg', 'a larger R switches earlier'});

sgtitle('W04 F — R decides how early the corner is cut', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_switching.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_switching.png\n\n');


% =========================================================================
function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
