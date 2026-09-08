function live_dash(u, v, r, N, E, psi, t, o)
%LIVE_DASH  한 창에 궤적과 상태 여섯 개를 함께 그린다 — 모델이 도는 동안.
%
%   live_dash(u, v, r, N, E, psi, t, o)
%
%   `live_track` 은 North-East 궤적 하나만 그린다. 그것으로는 "지금 배가
%   무엇을 하고 있는가" 의 절반밖에 안 보인다 — 속도가 얼마인지, 선회율이
%   얼마인지, 선수각이 어디로 가고 있는지가 안 보이기 때문이다.
%   이 함수는 **왼쪽에 궤적, 오른쪽에 상태 여섯 개**를 한 창에 놓는다.
%
%   INPUTS  (모델이 쓰는 단위 그대로 받는다. 변환은 여기서 한 번만 한다)
%     u, v   surge · sway 속도 [m/s]
%     r      yaw rate [rad/s]      -> 화면에는 deg/s
%     N, E   NED 위치 [m]
%     psi    선수각 [rad]          -> 화면에는 deg, (-180, 180] 으로 감는다
%     t      시뮬레이션 시각 [s]
%     o      옵션 구조체
%              o.tag     주차 식별자. 바뀌면 창을 새로 연다
%              o.name    창 이름
%              o.title   궤적 축 제목
%              o.lim     [Emin Emax Nmin Nmax]
%              o.every   다시 그리는 간격 [시뮬레이션 초]
%              o.wp      선택. n-by-2 [N E] 웨이포인트
%
%   왜 각도를 감는가
%
%   `otter.m` 의 psi 는 감기지 않은 채 계속 누적된다. 한 바퀴를 돌면 360 도를
%   넘고, 두 바퀴면 720 도가 된다. 그대로 그리면 축이 계속 늘어나서 **선수각이
%   어디를 향하는지 읽을 수 없다.** 나침반과 같은 범위로 감아서 보여준다.
%
%       psi_deg = mod(psi_deg + 180, 360) - 180        ->  (-180, 180]
%
%   정확히 180 도는 -180 도로 간다. 그것이 이 식의 유일한 경계다.
%
%   왜 선체를 함께 그리는가
%
%   궤적선은 배가 **어디로 갔는지**만 보여주고 **어디를 향하고 있었는지**는
%   보여주지 않는다. 둘의 차이가 크랩각 beta = atan2(v, u) 이고, W01 의 선회
%   구간에서 실제로 벌어진다. 선체는 `draw_ship` 이 그린다 — 실험실 교육용
%   코드 shipModel.m (J. Hong, KRISO, 2022) 의 다각형이다.
%
%   성능
%
%   매 솔버 스텝마다 다시 그리면 시뮬레이션보다 그리기가 느려진다. 값은 매번
%   쌓되 화면은 o.every 마다 갱신하고, 그래픽 핸들은 만들지 않고 재사용한다.
%
%   See also LIVE_TRACK, DRAW_SHIP, W01_ANIMATE.

persistent fig axT axS hTrail hHull hHead hLine hInfo D tLast tPrev Lship tag

%% ---- 기본값 -------------------------------------------------------------
if ~isfield(o,'tag'),   o.tag   = 'GNC';                      end
if ~isfield(o,'name'),  o.name  = [o.tag ' live dashboard'];  end
if ~isfield(o,'title'), o.title = 'track';                    end
if ~isfield(o,'lim'),   o.lim   = [-50 50 -50 50];            end
if ~isfield(o,'every'), o.every = 0.5;                        end
if ~isfield(o,'wp'),    o.wp    = [];                         end

%  화면에 쓸 단위로 여기서 한 번만 바꾼다.
r_deg   = r * 180/pi;                            % [deg/s]
psi_deg = mod(psi*180/pi + 180, 360) - 180;      % [deg], (-180, 180]

%% ---- 새 실행이면 전부 초기화 -------------------------------------------
%  t 가 뒤로 갔거나, 창이 닫혔거나, 다른 주차이면 새 실행이다.
newRun = isempty(tLast) || isempty(fig) || ~isvalid(fig) ...
         || t < tPrev || ~strcmp(tag, o.tag);

if newRun
    if ~isempty(fig) && isvalid(fig), close(fig); end
    tag = o.tag;
    fig = figure('Name', o.name, 'NumberTitle','off', 'Color','w', ...
                 'Position',[60 60 1180 720]);
    T = tiledlayout(fig, 3, 4, 'TileSpacing','compact', 'Padding','compact');

    % ---- 왼쪽: 궤적 -----------------------------------------------------
    axT = nexttile(T, 1, [3 2]);
    hold(axT,'on'); grid(axT,'on'); box(axT,'on'); axis(axT,'equal');
    axis(axT, o.lim);
    xlabel(axT, 'East  [m]');  ylabel(axT, 'North  [m]');
    title(axT, o.title, 'FontWeight','normal');

    Lship = max(0.045*max(o.lim(2)-o.lim(1), o.lim(4)-o.lim(3)), 2.00);

    if ~isempty(o.wp)
        plot(axT, o.wp(:,2), o.wp(:,1), '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
        plot(axT, o.wp(:,2), o.wp(:,1), 's', 'MarkerEdgeColor',[0.75 0.10 0.10], ...
             'MarkerFaceColor','w', 'MarkerSize',9, 'LineWidth',1.5);
    end
    plot(axT, 0, 0, 'ks', 'MarkerFaceColor','w', 'MarkerSize',9, 'LineWidth',1.2);

    hTrail = plot(axT, nan, nan, '-', 'Color',[0 0.45 0.74], 'LineWidth',1.5);
    hHull  = patch('Parent',axT, 'XData',nan, 'YData',nan, ...
                   'FaceColor',[0.85 0.33 0.10], 'FaceAlpha',0.85, ...
                   'EdgeColor',[0.35 0.12 0.03], 'LineWidth',1.0);
    hHead  = plot(axT, nan, nan, '-', 'Color',[0.35 0.12 0.03], 'LineWidth',1.2);
    hInfo  = title(axT, '', 'FontWeight','normal');

    % ---- 오른쪽: 상태 여섯 -----------------------------------------------
    %  두 열로 놓는다. 왼쪽 열이 속도 셋, 오른쪽 열이 위치와 자세 셋이다.
    %  같은 줄에 놓인 둘이 짝이 되도록 순서를 맞췄다: u-N, v-E, r-psi.
    P = { 'u'   'surge  u  [m/s]'      [0 0.45 0.74]
          'N'   'north  x  [m]'        [0.30 0.30 0.30]
          'v'   'sway  v  [m/s]'       [0.85 0.33 0.10]
          'E'   'east  y  [m]'         [0.30 0.30 0.30]
          'r'   'yaw rate  r  [deg/s]' [0.47 0.67 0.19]
          'psi' 'heading  \psi  [deg]' [0.49 0.18 0.56] };
    tileIdx = [3 4 7 8 11 12];
    for k = 1:6
        axS.(P{k,1}) = nexttile(T, tileIdx(k));
        hold(axS.(P{k,1}),'on'); grid(axS.(P{k,1}),'on'); box(axS.(P{k,1}),'on');
        ylabel(axS.(P{k,1}), P{k,2}, 'FontSize',9);
        hLine.(P{k,1}) = plot(axS.(P{k,1}), nan, nan, '-', ...
                              'Color', P{k,3}, 'LineWidth',1.4);
        set(axS.(P{k,1}), 'FontSize',8);
        if k >= 5, xlabel(axS.(P{k,1}), 'time  [s]', 'FontSize',9); end
    end
    %  선수각은 감아 놓았으므로 축도 나침반과 같은 범위로 못 박는다.
    ylim(axS.psi, [-180 180]);  yticks(axS.psi, -180:90:180);

    D = struct('t',[], 'u',[], 'v',[], 'r',[], 'N',[], 'E',[], 'psi',[]);
    tLast = -inf;
end
tPrev = t;

%% ---- 값은 매번 쌓는다 ---------------------------------------------------
D.t(end+1)   = t;      D.u(end+1) = u;        D.v(end+1)   = v;
D.r(end+1)   = r_deg;  D.N(end+1) = N;        D.E(end+1)   = E;
D.psi(end+1) = psi_deg;

%% ---- 화면은 o.every 마다만 --------------------------------------------
if t - tLast < o.every && t > 0, return; end
tLast = t;

set(hTrail, 'XData', D.E, 'YData', D.N);

%  선체와 선수 방향. draw_ship 은 축에 새로 그리므로, 여기서는 그것이 내는
%  좌표만 받아 기존 패치에 얹는다 — 스텝마다 패치를 만들면 그래픽 객체가
%  쌓여서 창이 멈춘다.
[xh, yh, xd, yd] = ship_poly(N, E, psi, Lship);
set(hHull, 'XData', xh, 'YData', yh);
set(hHead, 'XData', xd, 'YData', yd);

set(hInfo, 'String', sprintf(['%s        t = %6.1f s        u = %5.2f m/s' ...
                              '        \\psi = %6.1f\\circ'], ...
                             o.title, t, u, psi_deg));

F = {'u','v','r','N','E','psi'};
for k = 1:6
    set(hLine.(F{k}), 'XData', D.t, 'YData', D.(F{k}));
    xlim(axS.(F{k}), [0 max(D.t(end), 1e-3)]);
end
drawnow limitrate
end

% -------------------------------------------------------------------------
function [xh, yh, xd, yd] = ship_poly(N, E, psi, L)
%SHIP_POLY  draw_ship 과 같은 다각형을, 패치에 얹을 좌표로만.
%
%  shipModel.m (J. Hong, KRISO, 2022) 의 모양 그대로다: 사각형 선미에
%  삼각형 선수. 화면에서 몇 픽셀밖에 안 되어도 화살표로 읽힌다.
%  선체 좌표계에서 만든 뒤 R(psi) 로 돌려서 NED 로 옮기고, 그리는 것은
%  East 가 x, North 가 y 이므로 마지막에 (E, N) 순으로 낸다.
b  = 0.30*L;                                   % 반폭
xb = [ 0.50*L  0.15*L -0.50*L -0.50*L  0.15*L] ;   % 선수 -> 우현 -> 선미
yb = [ 0       b       b      -b      -b     ];
c  = cos(psi);  s = sin(psi);
Nh = c*xb - s*yb + N;
Eh = s*xb + c*yb + E;
xh = Eh;  yh = Nh;

%  선수 방향 지시선 — 선체 길이의 1.6 배.
Nd = [N, N + 1.6*L*c];
Ed = [E, E + 1.6*L*s];
xd = Ed;  yd = Nd;
end
