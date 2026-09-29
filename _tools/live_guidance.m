function live_guidance(N, E, psi_deg, y_e, u, u_d, n, wp, t, o)
%LIVE_GUIDANCE  유도 주차의 실시간 화면 — 모델이 도는 동안 한 창에 다 보인다.
%               The live view for the guidance weeks: everything in one window
%               while the model runs.
%
%   live_guidance(N, E, psi_deg, y_e, u, u_d, n, wp, t, o)
%
%   `live_track` 은 궤적만, `live_dash` 는 궤적과 선체 상태 여섯을 그린다. 유도
%   주차가 보고 싶은 것은 그 둘이 아니다 — **경로를 얼마나 잘 따르고 있는가**,
%   **지금 몇 번째 다리인가**, **명령한 속도를 내고 있는가**, 그리고 그러느라
%   **두 축이 얼마나 돌고 있는가** 다. 그래서 세 번째 화면이 있다.
%
%   live_track draws the track alone and live_dash draws the track and six hull
%   states. A guidance week wants neither: it wants how well the path is being
%   followed, which leg is active, whether the commanded speed is being made,
%   and what the two shafts are doing to make it.
%
%   INPUTS  (모델이 쓰는 단위 그대로 / in the units the model works in)
%     N, E      NED 위치 [m]
%     psi_deg   선수각 [deg], (-180, 180] 로 감긴 값 / heading, already wrapped
%     y_e       횡방향 오차 [m] / cross-track error
%     u         전진속도 [m/s] / surge speed
%     u_d       명령 속도 [m/s]. **NaN 이면 속도 루프가 없는 모델**이라 그리지 않는다
%               commanded speed; NaN means the model has no speed loop, so it is
%               not drawn — an unfollowed dashed line would be a lie
%     n         축 회전수 [rad/s], 2x1 = [좌현; 우현] / shaft speeds, [port; starboard]
%     wp        지금 따라가는 다리 번호 / the active leg
%     t         시뮬레이션 시각 [s]
%     o         옵션 / options
%                 o.tag    주차 식별자. 바뀌면 창을 새로 연다 / a new tag starts a new figure
%                 o.name   창 이름 / figure name
%                 o.lim    [Emin Emax Nmin Nmax]
%                 o.every  다시 그리는 간격 [시뮬레이션 초] / redraw interval
%                 o.wp     n-by-2 [N E] 웨이포인트 목록 / the waypoint list
%
%   성능 / performance
%       매 솔버 스텝마다 다시 그리면 시뮬레이션보다 그리기가 느려진다. o.every
%       시뮬레이션 초마다 한 번만 갱신하고, 그래픽 핸들은 만들지 않고 **다시 쓴다**.
%       스텝마다 patch 를 만들면 객체가 쌓여 창이 기어간다 (live_track 과 같은 이유).
%       Redrawing every step is slower than the simulation itself. The figure is
%       refreshed at most every o.every simulated seconds and the handles are
%       reused, never recreated.
%
%   See also LIVE_TRACK, LIVE_DASH, W05_ANIMATE.

persistent fig ax hTrail hHull hPath hYe hU hUd hNL hNR hWp hInfo
persistent trailN trailE tHist yeH uH nLH nRH wpH tLast tag Lship

new = isempty(fig) || ~isvalid(fig) || ~strcmp(tag, o.tag) || t < tLast;
if new
    tag = o.tag;  tLast = -inf;
    trailN = [];  trailE = [];  tHist = [];
    yeH = [];  uH = [];  nLH = [];  nRH = [];  wpH = [];
    fig = findobj('Type','figure','Name',o.name);
    if isempty(fig), fig = figure('Name',o.name,'NumberTitle','off','Color','w'); end
    clf(fig);  set(fig,'Position',[80 80 1180 620]);
    Lship = max(0.045*max(o.lim(2)-o.lim(1), o.lim(4)-o.lim(3)), 2.00);

    ax = gobjects(1,5);
    ax(1) = subplot(1,2,1,'Parent',fig);  hold(ax(1),'on');  grid(ax(1),'on');
    axis(ax(1),'equal');  axis(ax(1), o.lim);
    xlabel(ax(1),'east [m]');  ylabel(ax(1),'north [m]');
    if isfield(o,'wp') && ~isempty(o.wp)
        hPath = plot(ax(1), o.wp(:,2), o.wp(:,1), 'k--', 'LineWidth', 1);
        plot(ax(1), o.wp(:,2), o.wp(:,1), 'kp', 'MarkerSize', 11, 'MarkerFaceColor','k');
    end
    hTrail = plot(ax(1), nan, nan, 'Color', [0 0.45 0.74], 'LineWidth', 1.3);
    hHull  = patch('Parent',ax(1), 'XData',nan, 'YData',nan, ...
                   'FaceColor',[0.1 0.1 0.1], 'FaceAlpha',0.85, 'EdgeColor','none');
    hInfo  = title(ax(1), '');

    LBL = {'y_e  [m]', 'u  [m/s]', 'n_L , n_R  [rad/s]', 'waypoint k'};
    for i = 1:4
        ax(i+1) = subplot(4,2,2*i,'Parent',fig);  hold(ax(i+1),'on');  grid(ax(i+1),'on');
        ylabel(ax(i+1), LBL{i});
    end
    xlabel(ax(5), 'time [s]');
    hYe = plot(ax(2), nan, nan, 'LineWidth', 1.3);  yline(ax(2), 0, 'k:');
    hU  = plot(ax(3), nan, nan, 'LineWidth', 1.3);
    hUd = plot(ax(3), nan, nan, '--', 'Color', [.5 .5 .5], 'LineWidth', 1.2);
    hNL = plot(ax(4), nan, nan, 'LineWidth', 1.2);
    hNR = plot(ax(4), nan, nan, 'LineWidth', 1.2);
    legend(ax(4), {'n_L','n_R'}, 'Location','northeast');
    hWp = stairs(ax(5), nan, nan, 'LineWidth', 1.4);
end

%  o.every 시뮬레이션 초마다 한 번만 / at most once every o.every simulated seconds
trailN(end+1) = N;  trailE(end+1) = E;  tHist(end+1) = t;
yeH(end+1) = y_e;   uH(end+1) = u;
nLH(end+1) = n(1);  nRH(end+1) = n(2);  wpH(end+1) = wp;
if t - tLast < o.every, return; end
tLast = t;

set(hTrail, 'XData', trailE, 'YData', trailN);
%  선체 — live_track.m 과 **같은 다각형, 같은 회전**. 핸들을 다시 쓰려고 여기에
%  한 번 더 적는다 (스텝마다 patch 를 만들면 객체가 쌓인다).
%  The hull: the same polygon and rotation as live_track.m, repeated so the
%  handle can be reused rather than a patch created per step.
psi = psi_deg*pi/180;
a = Lship/2;  b = Lship*(1.08/2.00)/2;
bx = [ -a   -a    0.25*a   a    0.25*a ];
by = [  b   -b   -b        0    b      ];
set(hHull, 'XData', E + bx*sin(psi) + by*cos(psi), ...
           'YData', N + bx*cos(psi) - by*sin(psi));
set(hInfo, 'String', sprintf('t = %6.1f s    leg %d    y_e = %+6.2f m    u = %4.2f m/s', ...
                             t, round(wp), y_e, u));
set(hYe, 'XData', tHist, 'YData', yeH);
set(hU,  'XData', tHist, 'YData', uH);
if isfinite(u_d)
    set(hUd, 'XData', tHist([1 end]), 'YData', [u_d u_d]);
end
set(hNL, 'XData', tHist, 'YData', nLH);
set(hNR, 'XData', tHist, 'YData', nRH);
set(hWp, 'XData', tHist, 'YData', wpH);
for i = 2:5, xlim(ax(i), [0 max(t, o.every)]); end
ylim(ax(5), [0.5 max(2, max(wpH)) + 0.5]);
drawnow limitrate;
end
