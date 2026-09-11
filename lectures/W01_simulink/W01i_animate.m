function W01i_animate(u, v, r, N, E, psi, t)
%W01I_ANIMATE  W01_interactive.slx 의 실시간 화면 — 궤적, 상태, 그리고 두 프로펠러 속도.
%
%   W01_interactive.slx 의 Animate 블록이 매 스텝 부른다. 손으로 부를 일은 없다.
%
%   화면 구성 (4 x 4 칸)
%     왼쪽 절반        North-East 궤적과 선체. 창이 배를 따라간다
%     오른쪽 위 두 줄  u, v, r, psi
%     오른쪽 셋째 줄   North, East 위치
%     오른쪽 맨 아래   n_L, n_R — 버튼과 슬라이더가 실제로 만든 명령
%
%   왜 _tools/live_dash 를 쓰지 않는가
%     live_dash 는 모든 주차가 함께 쓰는 여섯 칸 화면이다. 이 모델에는 두 가지가
%     더 필요하다 — 프로펠러 속도 칸, 그리고 배를 따라가는 궤적 창. 공용 함수를
%     바꾸면 다른 주차의 그림이 함께 바뀌므로, 이 모델의 화면은 여기서 따로 그린다.
%
%   n 은 어디서 오는가
%     Animate 블록은 선체 상태만 받는다. 모델 최상위의 'n to live view' 블록이
%     매 스텝 setappdata(0,'W01i_n',n) 로 n 을 맡겨 두고, 여기서 꺼내 쓴다.
%
%   창 위치
%     새 실행마다 화면 오른쪽 절반에 연다. 모델 창은 W01i_control 이 왼쪽 절반에
%     둔다. 둘이 겹치면 버튼을 누를 때마다 모델 창이 앞으로 나와 그래프를 가린다.
%
%   INPUTS  otter.m 의 단위 그대로 (u, v [m/s], r [rad/s], N, E [m], psi [rad], t [s])

persistent fig A H D tDraw

W     = 120;                                    % 궤적 창의 한 변 [m]
every = 0.25;                                   % 다시 그리는 간격 [시뮬레이션 초]
span  = 60;                                     % 시간축에 보이는 길이 [s]
name  = 'W01 drive it yourself';

%  t = 0 의 첫 부름은 n 이 맡겨지기 전에 온다. 모델의 StartFcn 이 지난 실행의 값을
%  지워 두므로, 아직 없으면 NaN 으로 둔다 (그 점은 그려지지 않는다).
n = getappdata(0, 'W01i_n');
if numel(n) ~= 2, n = [nan; nan]; end

%% ---- 새 실행이면 창을 새로 만든다 ----------------------------------------
%  처음 부르거나, 창이 닫혔거나, 시간이 뒤로 갔으면 (STOP 뒤 START) 새 실행이다.
newRun = isempty(fig) || ~isvalid(fig) || isempty(D) || (~isempty(D.t) && t < D.t(end));
if newRun
    if ~isempty(fig) && isvalid(fig), close(fig); end
    delete(findall(0, 'Type','figure', 'Name', name));
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

    % ---- 오른쪽 위 : u, v, r, psi ----------------------------------------
    %        칸   축 이름                      선 색
    P = { 3,  'surge  u  [m/s]',         [0 0.45 0.74]
          4,  'sway  v  [m/s]',          [0.85 0.33 0.10]
          7,  'yaw rate  r  [deg/s]',    [0.47 0.67 0.19]
          8,  'heading  \psi  [deg]',    [0.49 0.18 0.56] };
    F = {'u','v','r','psi'};
    for k = 1:4
        A.(F{k}) = nexttile(T, P{k,1});
        hold(A.(F{k}),'on'); grid(A.(F{k}),'on'); box(A.(F{k}),'on');
        ylabel(A.(F{k}), P{k,2}, 'FontSize',9);  set(A.(F{k}), 'FontSize',8);
        H.(F{k}) = plot(A.(F{k}), nan, nan, '-', 'Color',P{k,3}, 'LineWidth',1.4);
    end
    ylim(A.psi, [-180 180]);  yticks(A.psi, -180:90:180);

    % ---- 셋째 줄 : 위치 ----------------------------------------------------
    A.pos = nexttile(T, 11, [1 2]);
    hold(A.pos,'on'); grid(A.pos,'on'); box(A.pos,'on'); set(A.pos,'FontSize',8);
    H.N = plot(A.pos, nan, nan, '-',  'Color',[0.30 0.30 0.30], 'LineWidth',1.4);
    H.E = plot(A.pos, nan, nan, '--', 'Color',[0.30 0.30 0.30], 'LineWidth',1.4);
    ylabel(A.pos, 'position  [m]', 'FontSize',9);
    legend(A.pos, {'North  x','East  y'}, 'Location','northwest', 'FontSize',8);

    % ---- 맨 아래 : 두 프로펠러 속도 — 버튼과 슬라이더가 만든 명령 ------------
    A.n = nexttile(T, 15, [1 2]);
    hold(A.n,'on'); grid(A.n,'on'); box(A.n,'on'); set(A.n,'FontSize',8);
    H.nL = plot(A.n, nan, nan, '-', 'Color',[0.00 0.45 0.74], 'LineWidth',1.8);
    H.nR = plot(A.n, nan, nan, '-', 'Color',[0.85 0.33 0.10], 'LineWidth',1.8);
    yline(A.n, 0, 'k:', 'HandleVisibility','off');
    ylabel(A.n, 'shaft speed  [rad/s]', 'FontSize',9);  xlabel(A.n, 'time  [s]', 'FontSize',9);
    legend(A.n, {'n_L  left','n_R  right'}, 'Location','northwest', 'FontSize',8);
    ylim(A.n, [-110 110]);

    D = struct('t',[], 'u',[], 'v',[], 'r',[], 'psi',[], 'N',[], 'E',[], 'nL',[], 'nR',[]);
    tDraw = -inf;
    figure(fig);                                % 앞으로 가져온다
end

%% ---- 값을 쌓는다 — 한 스텝에 한 번 ---------------------------------------
%  ode4 는 한 스텝 안에서 이 함수를 네 번 부른다 (중간 단계). 시각이 앞으로
%  나아갔을 때만 쌓는다.
if isempty(D.t) || t > D.t(end)
    D.t(end+1) = t;   D.u(end+1) = u;   D.v(end+1) = v;   D.r(end+1) = r*180/pi;
    D.psi(end+1) = mod(psi*180/pi + 180, 360) - 180;          % (-180, 180] 로 감는다
    D.N(end+1) = N;   D.E(end+1) = E;   D.nL(end+1) = n(1);   D.nR(end+1) = n(2);
end

%% ---- 화면은 every 초마다만 ------------------------------------------------
if ~newRun && t - tDraw < every, return; end
tDraw = t;

set(H.trail, 'XData', D.E, 'YData', D.N);
[xh, yh, xd, yd] = ship_poly(N, E, psi, 0.045*W);
set(H.hull, 'XData', xh, 'YData', yh);
set(H.head, 'XData', xd, 'YData', yd);
set(H.info, 'String', {'track — drive it with the buttons   (bow = triangle)', ...
    sprintf('t = %.1f s    u = %.2f m/s    \\psi = %.1f\\circ    n = [%.0f  %.0f] rad/s', ...
            t, u, D.psi(end), n(1), n(2))});

%  궤적 창은 배를 따라간다 : 가장자리 20 % 안으로 들어오면 창을 옮긴다. 크기는 그대로.
xl = xlim(A.trk);  yl = ylim(A.trk);  edge = 0.2*W;
if E < xl(1)+edge || E > xl(2)-edge, xlim(A.trk, E + [-W/2 W/2]); end
if N < yl(1)+edge || N > yl(2)-edge, ylim(A.trk, N + [-W/2 W/2]); end

tw = [max(0, t-span), max(t, 1)];                % 시간축은 최근 span 초만
F  = {'u','v','r','psi'};
for k = 1:4
    set(H.(F{k}), 'XData', D.t, 'YData', D.(F{k}));   xlim(A.(F{k}), tw);
end
set(H.N,  'XData', D.t, 'YData', D.N);    set(H.E,  'XData', D.t, 'YData', D.E);    xlim(A.pos, tw);
set(H.nL, 'XData', D.t, 'YData', D.nL);   set(H.nR, 'XData', D.t, 'YData', D.nR);   xlim(A.n, tw);
drawnow limitrate
end

% -------------------------------------------------------------------------
function [xh, yh, xd, yd] = ship_poly(N, E, psi, L)
%  _tools/live_dash 와 같은 선체 다각형 — 사각형 선미에 삼각형 선수.
%  선체 좌표에서 만들어 psi 만큼 돌린 뒤 NED 로 옮긴다. 그림은 (East, North).
b  = 0.30*L;
xb = [0.50*L  0.15*L -0.50*L -0.50*L  0.15*L];
yb = [0       b       b      -b      -b     ];
c  = cos(psi);  s = sin(psi);
xh = s*xb + c*yb + E;    yh = c*xb - s*yb + N;
xd = [E, E + 1.6*L*s];   yd = [N, N + 1.6*L*c];
end
