function live_guidance(N, E, psi_deg, psi_d_deg, y_e, u, u_d, n, wp, t, o)
%LIVE_GUIDANCE  유도 주차의 실시간 화면 — 모델이 도는 동안 한 창에 다 보인다.
%               The live view for the guidance weeks: everything in one window
%               while the model runs.
%
%   live_guidance(N, E, psi_deg, psi_d_deg, y_e, u, u_d, n, wp, t, o)
%
%   `live_track` 은 궤적만, `live_dash` 는 궤적과 선체 상태 여섯을 그린다. 유도
%   주차가 보고 싶은 것은 그 둘이 아니다 — **명령대로 가고 있는가**를 두 루프
%   각각에 대해, **지금 몇 번째 다리인가**, **경로에서 얼마나 벗어났는가**,
%   그리고 그러느라 **두 축이 얼마나 돌고 있는가** 다.
%
%   live_track draws the track alone and live_dash draws the track and six hull
%   states. A guidance week wants neither: it wants whether each of the two
%   loops is following its command, which leg is active, how far off the path
%   the vessel is, and what the two shafts are doing to keep it there.
%
%   INPUTS  (모델이 쓰는 단위 그대로 / in the units the model works in)
%     N, E       NED 위치 [m]
%     psi_deg    선수각 [deg], (-180, 180] 로 감긴 값 / heading, already wrapped
%     psi_d_deg  유도가 낸 **목표 선수각** [deg]. 바깥 루프의 명령이다
%                the commanded heading, the outer loop's output
%     y_e        횡방향 오차 [m] / cross-track error
%     u          전진속도 [m/s] / surge speed
%     u_d        명령 속도 [m/s]. **NaN 이면 속도 루프가 없는 모델**이라 그리지 않는다
%                commanded speed; NaN means the model has no speed loop, so it is
%                not drawn — an unfollowed dashed line would be a lie
%     n          축 회전수 [rad/s], 2x1 = [좌현; 우현] / shaft speeds [port; starboard]
%     wp         지금 따라가는 다리 번호 / the active leg
%     t          시뮬레이션 시각 [s]
%     o          옵션 / options
%                  o.tag    주차 식별자. 바뀌면 창을 새로 연다 / a new tag starts a new figure
%                  o.name   창 이름 / figure name
%                  o.lim    [Emin Emax Nmin Nmax]
%                  o.every  다시 그리는 간격 [시뮬레이션 초] / redraw interval
%                  o.wp     n-by-2 [N E] 웨이포인트 목록 / the waypoint list
%
%   화면 배치 / the layout  (사용자 지시, 2026-10-13)
%       왼쪽 한 칸    경로 · 웨이포인트 · 지나온 궤적 · **선체와 선수 방향**
%                     가로축이 동쪽, 세로축이 북쪽 — 해도와 같은 방향이다
%       오른쪽 다섯 줄, 각각 **한 가지만**:
%         1  u_d 와 u        속도 루프가 명령대로 가고 있는가
%         2  psi_d 와 psi    선수각 루프가 명령대로 가고 있는가 [deg]
%         3  waypoint k      하나씩 올라가는 계단. 전환이 언제 일어났는지 보인다
%         4  y_e             경로에서 얼마나 벗어나 있는가
%         5  n_L 과 n_R      그 둘을 만들려고 두 축이 무엇을 하고 있는가
%       명령과 실제를 **같은 칸에 겹쳐** 그린다. 다른 칸에 두면 눈이 두 축을
%       오가며 비교해야 하고, 그 비교가 이 화면의 전부다.
%       The command and the response share a panel: in separate panels the eye
%       has to carry one curve to the other, and that comparison is the point.
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

persistent fig ax hTrail hHull hPath hU hUd hPsi hPsid hWp hYe hNL hNR hInfo
persistent trailN trailE tHist yeH uH udH psiH psidH nLH nRH wpH tLast tag Lship

new = isempty(fig) || ~isvalid(fig) || ~strcmp(tag, o.tag) || t < tLast;
if new
    tag = o.tag;  tLast = -inf;
    trailN = [];  trailE = [];  tHist = [];
    yeH = [];  uH = [];  udH = [];  psiH = [];  psidH = [];
    nLH = [];  nRH = [];  wpH = [];
    fig = findobj('Type','figure','Name',o.name);
    if isempty(fig), fig = figure('Name',o.name,'NumberTitle','off','Color','w'); end
    clf(fig);  set(fig,'Position',[60 60 1280 760]);
    Lship = max(0.045*max(o.lim(2)-o.lim(1), o.lim(4)-o.lim(3)), 2.00);

    ax = gobjects(1,6);
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

    LBL = {'u  [m/s]', '\psi  [deg]', 'waypoint k', 'y_e  [m]', 'n_L , n_R  [rad/s]'};
    for i = 1:5
        ax(i+1) = subplot(5,2,2*i,'Parent',fig);  hold(ax(i+1),'on');  grid(ax(i+1),'on');
        ylabel(ax(i+1), LBL{i});
    end
    xlabel(ax(6), 'time [s]');

    %  1) 속도: 명령과 실제 / the speed, commanded and made
    hUd = plot(ax(2), nan, nan, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.4);
    hU  = plot(ax(2), nan, nan, 'Color', [0 0.45 0.74], 'LineWidth', 1.4);
    legend(ax(2), [hUd hU], {'u_d','u'}, 'Location','southeast', 'Orientation','horizontal');

    %  2) 선수각: 명령과 실제 / the heading, commanded and made
    hPsid = plot(ax(3), nan, nan, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.4);
    hPsi  = plot(ax(3), nan, nan, 'Color', [0 0.45 0.74], 'LineWidth', 1.4);
    legend(ax(3), [hPsid hPsi], {'\psi_d','\psi'}, 'Location','southeast', 'Orientation','horizontal');

    %  3) 다리 번호 / the leg, one step at a time
    hWp = stairs(ax(4), nan, nan, 'Color', [0.49 0.18 0.56], 'LineWidth', 1.6);

    %  4) 횡방향 오차 / how far off the path
    hYe = plot(ax(5), nan, nan, 'Color', [0.47 0.67 0.19], 'LineWidth', 1.4);
    yline(ax(5), 0, 'k:');

    %  5) 두 축 / the two shafts
    hNL = plot(ax(6), nan, nan, 'LineWidth', 1.2);
    hNR = plot(ax(6), nan, nan, 'LineWidth', 1.2);
    legend(ax(6), {'n_L','n_R'}, 'Location','southeast', 'Orientation','horizontal');
end

%  o.every 시뮬레이션 초마다 한 번만 / at most once every o.every simulated seconds
trailN(end+1) = N;     trailE(end+1) = E;      tHist(end+1) = t;
yeH(end+1)    = y_e;   uH(end+1)     = u;      udH(end+1)   = u_d;
psiH(end+1)   = psi_deg;  psidH(end+1) = psi_d_deg;
nLH(end+1)    = n(1);  nRH(end+1)    = n(2);   wpH(end+1)   = wp;
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
set(hInfo, 'String', sprintf(['t = %6.1f s    leg %d    y_e = %+6.2f m    ' ...
                              'u = %4.2f m/s    \\psi = %+6.1f deg'], ...
                             t, round(wp), y_e, u, psi_deg));
set(hU,   'XData', tHist, 'YData', uH);
if any(isfinite(udH)), set(hUd, 'XData', tHist, 'YData', udH); end
set(hPsi,  'XData', tHist, 'YData', psiH);
set(hPsid, 'XData', tHist, 'YData', psidH);
set(hWp,   'XData', tHist, 'YData', wpH);
set(hYe,   'XData', tHist, 'YData', yeH);
set(hNL,   'XData', tHist, 'YData', nLH);
set(hNR,   'XData', tHist, 'YData', nRH);
for i = 2:6, xlim(ax(i), [0 max(t, o.every)]); end
ylim(ax(4), [0.5 max(2, max(wpH)) + 0.5]);
drawnow limitrate;
end
