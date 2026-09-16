function [f, T] = W01_frames(R)
%W01_FRAMES  선체고정 속도와 NED 속도를 손으로 계산하고 그림으로 확인한다.
%            Body-frame velocity against NED velocity, worked and drawn.
%
%   [f, T] = W01_frames(R)      R 은 절 D 의 실행 결과 하나. 생략할 수 있다
%                               R is one run from section D, or omitted
%
%   이번 주가 없애려는 단 하나의 혼동 / the one confusion this week exists to remove
%
%       u 와 v 는 배와 함께 도는 축을 따라 잰 성분이다.
%       x^n 과 y^n 의 시간변화율은 결코 움직이지 않는 축을 따라 잰 성분이다.
%
%       u and v are components along axes that turn with the vessel.
%       The rates of change of the NED coordinates are components along axes
%       that never move.
%
%   둘은 같은 물리적 벡터를 두 번 표현한 것이며, 평면 회전행렬로 이어진다.
%   They are the same physical vector expressed twice, related by the planar
%   rotation matrix
%
%       [xn_dot; yn_dot] = R(psi) [u; v],  R(psi) = [cos psi, -sin psi
%                                                    sin psi,  cos psi]
%
%       xn_dot, yn_dot 은 강의의 x^n, y^n 의 시간변화율이다. 로그의 열 이름
%       N, E 가 가리키는 것과 같은 양이다.
%       xn_dot and yn_dot are the rates of the lecture's x^n and y^n, the same
%       quantities the log columns named N and E carry.
%
%   1주차의 선회 실행이 그 자체로 이 점을 보인다. 배가 회전하고 있으므로 u 와 v 는
%   일정한데 NED 속도 성분은 완전한 사인파를 그린다. u 를 그대로 적분해서 북쪽
%   위치를 얻으려 한 적이 있는 사람은 자기 실수를 바로 여기서 보게 된다.
%
%   The turning run of Week 1 makes the point by itself: u and v are constant
%   while the NED velocity components sweep through full sinusoids, because
%   the vessel is rotating. Anyone who has integrated u to obtain a north
%   position sees the error here and nowhere else.
%
%   T 는 절 C 가 출력하는 손계산 예제의 표이다.
%   T is the table of the hand-worked example printed by section C.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);

%% ---- the hand-worked example -------------------------------------------
psi = deg2rad(30);  u = 2.0;  v = 0.5;
Rp  = [cos(psi) -sin(psi); sin(psi) cos(psi)];
pn  = Rp*[u; v];

T = table( ...
    {'u  (surge, in {b})'; 'v  (sway, in {b})'; 'speed in {b}'; ...
     'xn_dot  (north rate, in {n})'; 'yn_dot  (east rate, in {n})'; 'speed in {n}'; ...
     'crab angle beta = atan2(v,u)'; 'course chi = psi + beta'; ...
     'check: atan2(yn_dot, xn_dot)'}, ...
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
legend({'$\dot{x}^n$  north rate','$\dot{y}^n$  east rate'}, ...
       'Interpreter','latex', 'Location','east');
title({'the same motion in the NED frame', 'full sinusoids — the axes did not move, the vessel did'});
grid on;

% -- the speed check -------------------------------------------------------
subplot(2,2,3); hold on;
plot(t, hypot(uu,vv), 'Color',[0 0.45 0.74], 'LineWidth',3);
plot(t, hypot(Nd,Ed), '--', 'Color',[0.49 0.18 0.56], 'LineWidth',1.6);
xlabel('time [s]'); ylabel('speed [m/s]');
legend({'$\|[u\ \ v]\|$','$\|[\dot{x}^n\ \ \dot{y}^n]\|$'}, ...
       'Interpreter','latex', 'Location','best');
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
