%% W04 · section D — the line-of-sight law
%
%      W04_0_setup
%      W04_D_line_of_sight
%
%  Aim at a point Delta ahead ON THE PATH, not at the waypoint. One arctan
%  separates the two laws, and it is the difference between visiting points
%  and following a path.
%  Produces img/W04_result_los.png

clear V o y k i f ye psid pi_p err
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_guidance.slx')), W04_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W04_vars;
o = run_sim('W04_guidance', V);
y = W04_read(o);

%% ---- the law, checked against its own arithmetic -----------------------
%  The block computes psi_d from y_e. Recomputing it here from the logged
%  cross-track error and comparing is a check that the signal called y_e in
%  the log really is the y_e the law used.
k = y.t > 30 & y.t < 70;                       % on leg 1, away from corners
pi_p = atan2(V.WP(2,2)-V.WP(1,2), V.WP(2,1)-V.WP(1,1));
psid = rad2deg(pi_p - atan(y.y_e(k,2)/V.Delta));
err  = max(abs(atan2d(sind(y.psi_d(k,2)-psid), cosd(y.psi_d(k,2)-psid))));

fprintf('\n  W04 section D — psi_d = pi_p - atan(y_e / Delta)\n\n');
fprintf('    Delta = %g m,  path-tangential angle on leg 1 = %.1f deg\n\n', ...
        V.Delta, rad2deg(pi_p));
fprintf('    recomputed psi_d against the logged one, leg 1:  %.3e deg\n', err);
fprintf('    (the same arithmetic, so this is a check on the LOG, not the law)\n');

%% ---- the two laws, side by side ----------------------------------------
fprintf('\n    %-8s %16s %16s %16s\n', 'law', 'settled |y_e|', 'max |y_e|', 'RMS |y_e|');
fprintf('    %s\n', repmat('-', 1, 60));
%  The LAST QUARTER, the same window W04_plot uses for the number it prints
%  in every track figure. Two windows for one quantity would put two slightly
%  different "settled |y_e|" values in front of the reader.
k = y.t >= 0.75*y.t(end);
for i = 1:2
    fprintf('    %-8s %16.4f %16.4f %16.4f\n', y.name{i}, ...
            mean(abs(y.y_e(k,i))), max(abs(y.y_e(:,i))), rms(y.y_e(y.t>80,i)));
end

fprintf(['\n    THE ARCTAN IS THE WHOLE LAW. Read it as two pieces:\n' ...
         '\n      pi_p                  line up with the path\n' ...
         '      - atan(y_e / Delta)   and lean towards it\n' ...
         '\n    The correction is bounded by 90 deg, so a vessel far from the\n' ...
         '    path heads almost perpendicular to it and NEVER turns away from\n' ...
         '    it. Close in, the correction fades smoothly to zero, which is\n' ...
         '    why the settled error is %.3f m and not a limit cycle.\n' ...
         '\n    Delta / L = %.1f, with L = 2.0 m the hull length. Section E\n' ...
         '    measures what happens on either side of that choice.\n'], ...
         mean(abs(y.y_e(k,2))), V.Delta/2.0);

%% ---- the figure --------------------------------------------------------
%  NOT the standard track + y_e pair. Section C already shows that picture,
%  and repeating it here would give two of the six result figures the same
%  content under different titles. This section is about the LAW, so the
%  figure takes the law apart: pi_p, the arctan correction, and their sum.
f = lab_fig('W04 D  the LOS law', 1400, 450);

kk = y.t <= 300;                        % the four legs, before the run tails off
pi_leg = zeros(size(y.t));
for i = 1:size(V.WP,1)-1
    j = round(y.wp(:,2)) == i;
    pi_leg(j) = atan2d(V.WP(i+1,2)-V.WP(i,2), V.WP(i+1,1)-V.WP(i,1));
end
%  The correction the law PRESCRIBES, and the one the block ACTUALLY applied.
%  Both wrapped the same way, so the comparison is of angles and not of branches.
corr_law  = -atand(y.y_e(:,2)/V.Delta);
dpsi      = y.psi_d(:,2) - pi_leg;
corr_used = atan2d(sind(dpsi), cosd(dpsi));

%  At the exact sample a leg changes, the logged psi_d still carries the OLD
%  pi_p while pi_leg has already stepped to the new one, so the difference
%  spikes for one sample. That is an artefact of comparing two signals across
%  a discontinuity, not a correction leaving the +-90 deg bound, so those
%  samples are blanked rather than drawn.
sw_edge = [false; abs(diff(round(y.wp(:,2)))) > 0];
sw_edge = sw_edge | [sw_edge(2:end); false] | [false; sw_edge(1:end-1)];
corr_used(sw_edge) = NaN;

C_atan2 = [0.85 0.325 0.098];       % orange, the same in every panel
C_los   = [0    0.447 0.741];       % blue,   the same in every panel

subplot(1,3,1); hold on; grid on;
stairs(y.t(kk), mod(pi_leg(kk),360), 'LineWidth',1.8);
xlabel('time [s]'); ylabel('\pi_p  [deg]');
ylim([-20 200]); yticks([0 45 90 135 180]);
title({'piece one: \pi_p', 'constant on a leg, steps at each waypoint'});

subplot(1,3,2); hold on; grid on;
plot(y.t(kk), corr_law(kk),  '-',  'Color', C_los, 'LineWidth',2.6, ...
     'DisplayName','-atan(y_e/\Delta), the law');
plot(y.t(kk), corr_used(kk), '--', 'Color', [0.15 0.15 0.15], 'LineWidth',1.1, ...
     'DisplayName','\psi_d - \pi_p, as applied');
plot(y.t([1 end]), [ 90  90], ':', 'Color',[0.75 0.2 0.2], 'LineWidth',1.4, 'DisplayName','the \pm90 deg bound');
plot(y.t([1 end]), [-90 -90], ':', 'Color',[0.75 0.2 0.2], 'LineWidth',1.4, 'HandleVisibility','off');
xlim([0 300]); ylim([-110 110]);
xlabel('time [s]'); ylabel('correction [deg]');
legend('Location','southeast');
title({'piece two: the arctan', ...
       sprintf('the two curves agree to %.1e deg, and never leave \\pm90', err)});

subplot(1,3,3); hold on; grid on;
plot(y.t, y.y_e(:,1), 'Color', C_atan2, 'LineWidth',1.5, 'DisplayName', y.name{1});
plot(y.t, y.y_e(:,2), 'Color', C_los,   'LineWidth',1.5, 'DisplayName', y.name{2});
plot([0 300], [0 0], ':', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');
xlabel('time [s]'); ylabel('y_e  cross-track error [m]');
%  Same 0-300 s window as the other two panels, and zoomed to +-1.5 m. The
%  full-scale picture, and what atan2 does after the last waypoint, are in
%  section C; this panel is only the settled comparison.
xlim([0 300]); ylim([-1.5 1.5]);
legend('Location','southwest');
title({sprintf('settled |y_e|, last quarter:  atan2 %.3f m,  LOS %.3f m', ...
               mean(abs(y.y_e(k,1))), mean(abs(y.y_e(k,2)))), ...
       'panel shows 0-300 s at \pm1.5 m; the rest is in section C'});

sgtitle('W04 D — one arctan turns waypoint-chasing into path following', ...
        'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_los.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_los.png\n\n');
