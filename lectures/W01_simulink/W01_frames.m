function [f, T] = W01_frames(R)
%W01_FRAMES  Body velocity against NED velocity, worked and drawn.
%
%   [f, T] = W01_frames(R)      R is one run from W01_run, or omitted
%
%   The one confusion this week exists to remove:
%
%       u and v are components along axes that TURN WITH THE VESSEL.
%       Ndot and Edot are components along axes that never move.
%
%   They are the same physical vector expressed twice, related by the planar
%   rotation matrix
%
%       [Ndot; Edot] = R(psi) [u; v],   R(psi) = [cos psi, -sin psi
%                                                 sin psi,  cos psi]
%
%   The turning run of Week 1 makes the point by itself: u and v are CONSTANT
%   while Ndot and Edot sweep through full sinusoids, because the vessel is
%   rotating. Anyone who has integrated u to get a north position sees the
%   error here and nowhere else.
%
%   T is a table of the hand-worked example printed by W01_run.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);

%% ---- the hand-worked example -------------------------------------------
psi = deg2rad(30);  u = 2.0;  v = 0.5;
Rp  = [cos(psi) -sin(psi); sin(psi) cos(psi)];
pn  = Rp*[u; v];

T = table( ...
    {'u  (surge, in {b})'; 'v  (sway, in {b})'; 'speed in {b}'; ...
     'Ndot  (north rate, in {n})'; 'Edot  (east rate, in {n})'; 'speed in {n}'; ...
     'crab angle beta = atan2(v,u)'; 'course chi = psi + beta'; ...
     'check: atan2(Edot, Ndot)'}, ...
    [u; v; norm([u;v]); pn(1); pn(2); norm(pn); ...
     rad2deg(atan2(v,u)); rad2deg(psi + atan2(v,u)); rad2deg(atan2(pn(2),pn(1)))], ...
    {'m/s';'m/s';'m/s';'m/s';'m/s';'m/s';'deg';'deg';'deg'}, ...
    'VariableNames', {'quantity','value','unit'});

if nargout < 1, disp(T); end

%% ---- the figure ---------------------------------------------------------
%  Uses the turning run if one is supplied, and generates the same motion
%  analytically if not, so the function is useful on its own.
if nargin < 1 || isempty(R)
    t   = (0:0.02:60)';
    r   = deg2rad(10.4369);
    ps  = r*t;
    uu  = 0.1932*ones(size(t));
    vv  = -0.0713*ones(size(t));
    N   = cumtrapz(t, uu.*cos(ps) - vv.*sin(ps));
    E   = cumtrapz(t, uu.*sin(ps) + vv.*cos(ps));
else
    t  = R.t;   uu = R.y(:,1);   vv = R.y(:,2);
    ps = deg2rad(R.y(:,6));      N  = R.y(:,4);   E = R.y(:,5);
end
Nd = uu.*cos(ps) - vv.*sin(ps);
Ed = uu.*sin(ps) + vv.*cos(ps);

f = lab_fig('W01  frames', 1150, 640);

% -- the two component pairs, on one time axis ---------------------------
subplot(2,2,1); hold on;
plot(t, uu, 'Color',[0.85 0.33 0.10], 'LineWidth',2.2);
plot(t, vv, '--', 'Color',[0.85 0.33 0.10], 'LineWidth',1.8);
xlabel('time [s]'); ylabel('velocity in \{b\} [m/s]');
legend({'u  surge','v  sway'}, 'Location','east');
title({'measured in the body frame', 'both constant — the vessel is in a steady turn'});
grid on;

subplot(2,2,2); hold on;
plot(t, Nd, 'Color',[0.47 0.67 0.19], 'LineWidth',2.2);
plot(t, Ed, '--', 'Color',[0.47 0.67 0.19], 'LineWidth',1.8);
yline(0,'k:');
xlabel('time [s]'); ylabel('velocity in \{n\} [m/s]');
legend({'Ndot  north rate','Edot  east rate'}, 'Location','east');
title({'the same motion in the NED frame', 'full sinusoids — the axes did not move, the vessel did'});
grid on;

% -- the speed check -------------------------------------------------------
subplot(2,2,3); hold on;
plot(t, hypot(uu,vv), 'Color',[0 0.45 0.74], 'LineWidth',3);
plot(t, hypot(Nd,Ed), '--', 'Color',[0.49 0.18 0.56], 'LineWidth',1.6);
xlabel('time [s]'); ylabel('speed [m/s]');
legend({'|[u  v]|','|[Ndot  Edot]|'}, 'Location','best');
title({sprintf('a rotation preserves length: largest gap %.2e m/s', ...
       max(abs(hypot(uu,vv) - hypot(Nd,Ed)))), ...
       'the cheapest check there is on a frame conversion'});
grid on; ylim([0 1.2*max(hypot(uu,vv))]);

% -- the track, with the two vectors drawn at intervals -------------------
%  No hull silhouettes on this panel. The subject is the two ARROWS, and at
%  the scale of a turn a couple of metres across a true-size hull covers them
%  completely. A dot marks each sample instead.
subplot(2,2,4); hold on; axis equal;
plot(E, N, 'Color',[0.72 0.72 0.72], 'LineWidth',1.4);
k   = ship_marks(N, E, 6);
span = max([range(N) range(E) 1]);
sc   = 0.42*span/max(hypot(uu,vv));
for j = k
    quiver(E(j), N(j), sc*(uu(j)*sin(ps(j))), sc*(uu(j)*cos(ps(j))), 0, ...
           'Color',[0.85 0.33 0.10], 'LineWidth',2.0, 'MaxHeadSize',1.2);
    quiver(E(j), N(j), sc*Ed(j), sc*Nd(j), 0, ...
           'Color',[0.47 0.67 0.19], 'LineWidth',2.0, 'MaxHeadSize',1.2);
    plot(E(j), N(j), 'ko', 'MarkerFaceColor','w', 'MarkerSize',5);
end
xlabel('East [m]'); ylabel('North [m]');
title({'orange: along x_b, the axis that turns with the hull', ...
       'green: the velocity as the ground sees it'});
grid on;

sgtitle('W01 — one velocity, two frames, two sets of numbers', 'FontWeight','bold');
end
