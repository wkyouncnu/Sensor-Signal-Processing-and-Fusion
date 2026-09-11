function W01rc_animate(u, v, r, N, E, psi, t) %#ok<INUSL>
%W01RC_ANIMATE  W01_rc.slx 의 실시간 화면 — 궤적, 도달 가능 집합, 속도, 프로펠러.
%
%   W01_rc.slx 의 Animate 블록이 매 스텝 부른다. 손으로 부를 일은 없다.
%
%   화면 구성 (4 x 4 칸)
%     왼쪽 절반          North-East 궤적과 선체. 창이 배를 따라간다 (W01i_animate 와 같다)
%     오른쪽 위 2 x 2    도달 가능 집합. 가로 tau_N, 세로 tau_X — 조종기 스틱과 같은 방향
%                        (위 = 전진, 오른쪽 = 우현 선회). 회색 영역이 두 프로펠러로 낼 수
%                        있는 힘 전부이고, 점선 사각형이 스틱이 요구할 수 있는 범위다.
%                        빈 원 = 요구한 힘, 주황 점 = 실제로 낸 힘. 둘이 떨어지면 포화다
%     오른쪽 셋째 줄     u (실선) 와 예측 종단속도 tau_X / |X_u| (점선), 그리고 r
%     오른쪽 맨 아래     n_L, n_R 과 포화 한계
%
%   값은 어디서 오는가
%     선체 상태는 인수로 받는다. 요구한 힘, 낸 힘, n 은 모델 최상위의 'to live view'
%     블록이 매 스텝 setappdata(0,'W01rc_tap',[tau_d; tau_a; n]) 로 맡겨 둔다.
%     한계값(k_pos, n_max, X_max …)은 모델 작업공간에서 읽는다 — 모델과 같은 수다.
%
%   INPUTS  otter.m 의 단위 그대로 (u, v [m/s], r [rad/s], N, E [m], psi [rad], t [s])

persistent fig A H D tDraw

W     = 120;                                    % 궤적 창의 한 변 [m]
every = 0.25;                                   % 다시 그리는 간격 [시뮬레이션 초]
span  = 60;                                     % 시간축에 보이는 길이 [s]
name  = 'W01 RC transmitter';
m     = 'W01_rc';                               % 모델의 StartFcn 이 자기 이름을 맡겨 둔다
if isappdata(0, 'W01rc_model'), m = getappdata(0, 'W01rc_model'); end   % W01_rc_usb (§H)

%  t = 0 의 첫 부름은 값이 맡겨지기 전에 온다. StartFcn 이 지난 실행의 값을 지우므로
%  아직 없으면 NaN 이다 (그 점은 그려지지 않는다).
tap = getappdata(0, 'W01rc_tap');
if numel(tap) ~= 6, tap = nan(6,1); end
tau_d = tap(1:2);   tau_a = tap(3:4);   n = tap(5:6);

%% ---- 새 실행이면 창을 새로 만든다 ----------------------------------------
newRun = isempty(fig) || ~isvalid(fig) || isempty(D) || (~isempty(D.t) && t < D.t(end));
if newRun
    if ~isempty(fig) && isvalid(fig), close(fig); end
    delete(findall(0, 'Type','figure', 'Name', name));
    L = limits(m);
    ss  = get(groot, 'ScreenSize');
    fig = figure('Name', name, 'NumberTitle','off', 'Color','w', ...
                 'Position', [round(0.5*ss(3))+5, 50, round(0.5*ss(3))-15, ss(4)-130]);
    T = tiledlayout(fig, 4, 4, 'TileSpacing','compact', 'Padding','compact');

    % ---- 왼쪽 : 궤적과 선체 -----------------------------------------------
    A.trk = nexttile(T, 1, [4 2]);
    hold(A.trk,'on'); grid(A.trk,'on'); box(A.trk,'on'); axis(A.trk,'equal');
    axis(A.trk, [-W/2 W/2 -W/3 2*W/3]);
    xlabel(A.trk, 'East  [m]');  ylabel(A.trk, 'North  [m]');
    plot(A.trk, 0, 0, 'ks', 'MarkerFaceColor','w', 'MarkerSize',9);
    H.trail = plot(A.trk, nan, nan, '-', 'Color',[0 0.45 0.74], 'LineWidth',1.5);
    H.hull  = patch('Parent',A.trk, 'XData',nan, 'YData',nan, 'FaceColor',[0.85 0.33 0.10], ...
                    'FaceAlpha',0.85, 'EdgeColor',[0.35 0.12 0.03]);
    H.head  = plot(A.trk, nan, nan, '-', 'Color',[0.35 0.12 0.03], 'LineWidth',1.2);
    H.info  = title(A.trk, '', 'FontWeight','normal');

    % ---- 오른쪽 위 : 도달 가능 집합 (부록 A1-6) -----------------------------
    %  두 추력이 [T_min, T_max] 안에 있을 때 [X; N] = Bxn [T_L; T_R] 가 닿는 곳.
    %  네 꼭짓점은 두 추력이 각각 끝에 있을 때다. 가로를 N, 세로를 X 로 둔다.
    A.set = nexttile(T, 3, [2 2]);
    hold(A.set,'on'); grid(A.set,'on'); box(A.set,'on'); set(A.set,'FontSize',8);
    Tc = [L.Tmax L.Tmax; L.Tmax L.Tmin; L.Tmin L.Tmin; L.Tmin L.Tmax];   % [T_L T_R]
    V  = (L.Bxn * Tc.').';                                               % [X N]
    fill(A.set, V([1:end 1],2), V([1:end 1],1), [0.88 0.88 0.88], ...
         'EdgeColor',[0.45 0.45 0.45], 'DisplayName','attainable');
    plot(A.set, L.Nmax*[-1 1 1 -1 -1], L.Xmax*[-1 -1 1 1 -1], '--', ...
         'Color',[0 0.45 0.74], 'LineWidth',1.1, 'DisplayName','stick range');
    H.link = plot(A.set, nan, nan, '-', 'Color',[0.85 0.33 0.10], 'LineWidth',1.0, ...
                  'HandleVisibility','off');
    H.dem  = plot(A.set, nan, nan, 'o', 'Color','k', 'MarkerSize',10, 'LineWidth',1.6, ...
                  'DisplayName','demanded  \tau_d');
    H.ach  = plot(A.set, nan, nan, 'o', 'MarkerFaceColor',[0.85 0.33 0.10], ...
                  'MarkerEdgeColor','none', 'MarkerSize',8, 'DisplayName','delivered  \tau_a');
    xline(A.set, 0, 'k:', 'HandleVisibility','off');  yline(A.set, 0, 'k:', 'HandleVisibility','off');
    xlim(A.set, 1.1*max(abs(V(:,2)))*[-1 1]);  ylim(A.set, 1.12*L.Xmax*[-1 1]);   % 옆 꼭짓점까지
    xlabel(A.set, 'yaw moment  \tau_N  [N m]   (right = starboard)', 'FontSize',9);
    ylabel(A.set, 'surge force  \tau_X  [N]   (up = ahead)', 'FontSize',9);
    legend(A.set, 'Location','southoutside', 'Orientation','horizontal', 'FontSize',8);
    H.sat = title(A.set, '', 'FontWeight','normal', 'FontSize',9);

    % ---- 셋째 줄 : u 와 r ---------------------------------------------------
    A.u = nexttile(T, 11);
    hold(A.u,'on'); grid(A.u,'on'); box(A.u,'on'); set(A.u,'FontSize',8);
    H.u  = plot(A.u, nan, nan, '-',  'Color',[0 0.45 0.74], 'LineWidth',1.4, 'DisplayName','u');
    H.up = plot(A.u, nan, nan, '--', 'Color',[0.30 0.30 0.30], 'LineWidth',1.1, ...
                'DisplayName','\tau_{X,a} / |X_u|');
    ylabel(A.u, 'surge  u  [m/s]', 'FontSize',9);
    legend(A.u, 'Location','northwest', 'FontSize',7);
    A.r = nexttile(T, 12);
    hold(A.r,'on'); grid(A.r,'on'); box(A.r,'on'); set(A.r,'FontSize',8);
    H.r = plot(A.r, nan, nan, '-', 'Color',[0.47 0.67 0.19], 'LineWidth',1.4);
    ylabel(A.r, 'yaw rate  r  [deg/s]', 'FontSize',9);

    % ---- 맨 아래 : 두 프로펠러 속도와 포화 한계 -------------------------------
    A.n = nexttile(T, 15, [1 2]);
    hold(A.n,'on'); grid(A.n,'on'); box(A.n,'on'); set(A.n,'FontSize',8);
    H.nL = plot(A.n, nan, nan, '-', 'Color',[0.00 0.45 0.74], 'LineWidth',1.8);
    H.nR = plot(A.n, nan, nan, '-', 'Color',[0.85 0.33 0.10], 'LineWidth',1.8);
    yline(A.n, [L.n_min L.n_max], 'k--', 'HandleVisibility','off');
    yline(A.n, 0, 'k:', 'HandleVisibility','off');
    ylabel(A.n, 'shaft speed  [rad/s]', 'FontSize',9);  xlabel(A.n, 'time  [s]', 'FontSize',9);
    legend(A.n, {'n_L  left','n_R  right'}, 'Location','northwest', 'FontSize',8);
    ylim(A.n, [-115 115]);

    D = struct('t',[], 'u',[], 'up',[], 'r',[], 'N',[], 'E',[], 'nL',[], 'nR',[], ...
               'Xu',L.Xu, 'tol',1e-3*L.Xmax);
    tDraw = -inf;
    figure(fig);
end

%% ---- 값을 쌓는다 — 한 스텝에 한 번 ---------------------------------------
if isempty(D.t) || t > D.t(end)
    D.t(end+1)  = t;   D.u(end+1) = u;   D.up(end+1) = tau_a(1) / D.Xu;
    D.r(end+1)  = r*180/pi;   D.nL(end+1) = n(1);   D.nR(end+1) = n(2);
    D.N(end+1)  = N;          D.E(end+1)  = E;
end

%% ---- 화면은 every 초마다만 ------------------------------------------------
if ~newRun && t - tDraw < every, return; end
tDraw = t;

%  궤적과 선체
set(H.trail, 'XData', D.E, 'YData', D.N);
[xh, yh, xd, yd] = ship_poly(N, E, psi, 0.045*W);
set(H.hull, 'XData', xh, 'YData', yh);
set(H.head, 'XData', xd, 'YData', yd);
set(H.info, 'String', {'track — drive it with the transmitter   (bow = triangle)', ...
    sprintf('t = %.1f s    u = %.2f m/s    \\psi = %.1f\\circ    n = [%.0f  %.0f] rad/s', ...
            t, u, mod(psi*180/pi + 180, 360) - 180, n(1), n(2))});

%  궤적 창은 배를 따라간다 : 가장자리 20 % 안으로 들어오면 창을 옮긴다. 크기는 그대로.
xl = xlim(A.trk);  yl = ylim(A.trk);  edge = 0.2*W;
if E < xl(1)+edge || E > xl(2)-edge, xlim(A.trk, E + [-W/2 W/2]); end
if N < yl(1)+edge || N > yl(2)-edge, ylim(A.trk, N + [-W/2 W/2]); end

%  도달 가능 집합 위의 두 점. 떨어져 있으면 포화 — 제목에 적는다.
set(H.dem,  'XData', tau_d(2), 'YData', tau_d(1));
set(H.ach,  'XData', tau_a(2), 'YData', tau_a(1));
set(H.link, 'XData', [tau_d(2) tau_a(2)], 'YData', [tau_d(1) tau_a(1)]);
if all(isfinite(tau_d)) && max(abs(tau_d - tau_a)) > D.tol
    set(H.sat, 'String', sprintf('SATURATED — asked X = %.0f N, N = %.1f N m;  got X = %.0f N, N = %.1f N m', ...
        tau_d(1), tau_d(2), tau_a(1), tau_a(2)), 'Color',[0.75 0.10 0.05]);
else
    set(H.sat, 'String', sprintf('delivered = demanded :  X = %.0f N,  N = %.1f N m', ...
        tau_a(1), tau_a(2)), 'Color',[0.2 0.2 0.2]);
end

%  시간 그래프는 최근 span 초만
tw = [max(0, t-span), max(t, 1)];
set(H.u,  'XData', D.t, 'YData', D.u);    set(H.up, 'XData', D.t, 'YData', D.up);   xlim(A.u, tw);
set(H.r,  'XData', D.t, 'YData', D.r);                                             xlim(A.r, tw);
set(H.nL, 'XData', D.t, 'YData', D.nL);   set(H.nR, 'XData', D.t, 'YData', D.nR);   xlim(A.n, tw);
drawnow limitrate
end

% -------------------------------------------------------------------------
function L = limits(m)
%  모델 작업공간에서 한계값을 읽는다. 모델이 쓰는 수와 화면의 수가 같아야 한다.
mw  = get_param(m, 'ModelWorkspace');
g   = @(s) mw.getVariable(s);
L.Bxn   = g('Bxn');
L.Xmax  = g('X_max');   L.Nmax  = g('N_max');   L.Xu = g('Xu_abs');
L.n_max = g('n_max');   L.n_min = g('n_min');
L.Tmax  =  g('k_pos') * L.n_max^2;
L.Tmin  = -g('k_neg') * L.n_min^2;
end

function [xh, yh, xd, yd] = ship_poly(N, E, psi, L)
%  _tools/live_dash 와 같은 선체 다각형 — 사각형 선미에 삼각형 선수.
b  = 0.30*L;
xb = [0.50*L  0.15*L -0.50*L -0.50*L  0.15*L];
yb = [0       b       b      -b      -b     ];
c  = cos(psi);  s = sin(psi);
xh = s*xb + c*yb + E;    yh = c*xb - s*yb + N;
xd = [E, E + 1.6*L*s];   yd = [N, N + 1.6*L*c];
end
