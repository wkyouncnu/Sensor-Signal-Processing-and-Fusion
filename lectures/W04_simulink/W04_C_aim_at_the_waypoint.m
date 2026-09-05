%% W04 · section C — aiming at a point is not following a path
%
%      W04_0_setup
%      W04_C_aim_at_the_waypoint
%
%  The obvious guidance law: point the bow at the next waypoint. It reaches
%  every waypoint and it never follows the line between them.
%  Produces img/W04_result_atan2.png

clear V o y k i f COL leg
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_guidance.slx')), W04_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W04_vars;
o = run_sim('W04_guidance', V);
y = W04_read(o);

%% ---- what atan2 does, leg by leg --------------------------------------
%  Measured over the LAST THIRD of each leg, so the number describes steady
%  tracking on that leg and not the turn onto it.
fprintf('\n  W04 section C — psi_d = atan2(E_next - E, N_next - N)\n\n');
fprintf('    %-6s %14s %14s %14s %14s\n', ...
        'leg', 'atan2 |y_e|', 'LOS |y_e|', 'atan2 max', 'ratio');
fprintf('    %s\n', repmat('-', 1, 70));

for leg = 1:size(V.WP,1)-1
    k = leg_window(y.wp(:,1), leg);
    if ~any(k), continue, end
    a = mean(abs(y.y_e(k,1)));
    b = mean(abs(y.y_e(k,2)));
    %  Leg 1 starts ON the path heading along it, so both errors are zero and
    %  the ratio is meaningless rather than large. Say so instead of printing
    %  a NaN that a reader has to interpret.
    if b < 1e-6
        r = '     both zero';
    else
        r = sprintf('%14.1f', a/b);
    end
    fprintf('    %-6d %14.3f %14.3f %14.3f %s\n', ...
            leg, a, b, max(abs(y.y_e(k,1))), r);
end

fprintf(['\n    atan2 REACHES every waypoint and never follows the line to it.\n' ...
         '    The law regulates the distance to a POINT, and a point does not\n' ...
         '    know about the line it sits on. Pushed off the path - by a corner\n' ...
         '    here, by a current in section G - the vessel simply approaches\n' ...
         '    the waypoint from wherever it happens to be, along a curve.\n' ...
         '\n    LOS on the same legs is %.0f times closer to the path.\n' ...
         '    Both vessels visit the same waypoints. Only one follows the path.\n'], ...
         mean(abs(y.y_e(y.t>150,1)))/mean(abs(y.y_e(y.t>150,2))));

%% ---- the figure --------------------------------------------------------
f = W04_plot(y, V, 'W04 C — atan2 visits the waypoints; LOS follows the path', [1 2]);
exportgraphics(f, fullfile(here,'img','W04_result_atan2.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_atan2.png\n\n');


% =========================================================================
function k = leg_window(wp, leg)
%LEG_WINDOW  The last third of the time spent on one leg.
idx = find(round(wp) == leg);
k   = false(size(wp));
if isempty(idx), return, end
k(idx(max(1, round(0.67*numel(idx))):end)) = true;
end
