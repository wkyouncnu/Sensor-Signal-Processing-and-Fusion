function f = W01_cur_plot(R, LBL, V, ttl)
%W01_CUR_PLOT  조류 실행 결과를 그린다 — 배가 어디로 갔는지, 그리고 무엇을 느꼈는지.
%              Draw the current runs: where the vessel went, and what it felt.
%
%   W01_cur_plot                     기본 작업공간에 있는 실행 결과
%                                    the run in the base workspace
%   W01_cur_plot(R, LBL, V, ttl)     실행 결과들의 셀 배열. 절 E 가 이렇게 부른다
%                                    a cell array of runs, as used by section E
%
%   모델의 StopFcn 과 절 스크립트가 모두 이 함수를 부르므로, 화면의 그림과
%   강의노트의 그림이 같은 코드에서 나온다.
%   Both the model's StopFcn and the section script call this, so the figure
%   on screen and the figure in the note come from one piece of code.
%
%   로그의 열 구성 / the columns of the log
%       [u v r N E psi | u_c v_c u_r v_r]
%       앞의 여섯은 모든 주차가 공유하는 규약이고, 뒤의 넷은 조류 모델만 남긴다.
%       u_c, v_c 는 선체좌표계로 옮긴 조류이고, u_r, v_r 은 물에 대한 상대속도이다.
%       배가 실제로 지나간 자리는 앞의 것으로, 유체력이 느낀 것은 뒤의 것으로
%       그려야 §1-13 의 갈라짐이 그림에 드러난다.
%
%       The first six columns are the contract shared by every week; the last
%       four are produced by the current model alone. u_c and v_c are the
%       current resolved in the body frame, and u_r and v_r the velocity
%       relative to the water. The track is drawn from the former and the
%       forces from the latter, which is how the split of §1-13 becomes
%       visible in a figure.

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''W01c'',''var'')'), return; end
    W = evalin('base', 'W01c');
    y = squeeze(W.signals.values);
    if size(y,1) < size(y,2), y = y.'; end
    R = {struct('t', W.time, 'y', y)};
    V = struct('V_c', base_var('V_c',0), 'beta_c', base_var('beta_c',0));
    LBL = {sprintf('V_c = %g, \\beta_c = %g deg', V.V_c, rad2deg(V.beta_c))};
    ttl = 'W01 — open loop in a current';
end
if nargin < 4 || isempty(ttl), ttl = 'W01 — open loop in a current'; end

COL = [0    0.45 0.74
       0.47 0.67 0.19
       0.85 0.33 0.10
       0.49 0.18 0.56];

f = lab_fig('W01  current', 1250, 760);

%  ---- the tracks: the whole point --------------------------------------
subplot(2,3,[1 2 4 5]); hold on; axis equal;
for i = 1:numel(R)
    plot(R{i}.y(:,5), R{i}.y(:,4), 'Color', COL(1+mod(i-1,4),:), 'LineWidth', 1.2);
end
Ls = track_ships(cellfun(@(r) r.y(:,[4 5 6]), R, 'UniformOutput', false), COL, 'Marks', 7);
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
legend(LBL, 'Location','best', 'Interpreter','tex');
current_arrows(R, COL);
xlabel('East [m]'); ylabel('North [m]');
title({'the track — one command, four currents', ...
       sprintf('hull at %.0f x true size; thin arrows are the current', Ls/2.00)});

%  ---- through the water, the runs are nearly the same -------------------
subplot(2,3,3); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,9), 'Color', COL(1+mod(i-1,4),:)); end
xlabel('time [s]'); ylabel('u_r  through the water [m/s]');
title({'speed THROUGH THE WATER', 'what the hull actually feels'});

%  ---- over the ground, they are not ------------------------------------
subplot(2,3,6); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,1), 'Color', COL(1+mod(i-1,4),:)); end
xlabel('time [s]'); ylabel('u  over the ground [m/s]');
title({'speed OVER THE GROUND', 'the same hull, four different answers'});

sgtitle(ttl, 'FontWeight','bold');
end

% =========================================================================
function current_arrows(R, COL)
%CURRENT_ARROWS  Draw the current direction on the track, sparsely.
%
%   A track that bends says nothing on its own about WHICH WAY the water was
%   going. Three arrows per run answer that without turning the panel into a
%   flow field: any denser and they compete with the hull outlines, which are
%   the other thing the reader has to see here.
%
%   NED to plot axes: the panel has East to the right and North up, and
%   beta_c is measured CLOCKWISE FROM NORTH, so
%
%       east component  = V_c sin(beta_c)
%       north component = V_c cos(beta_c)
%
%   Getting that pair the wrong way round mirrors every arrow about the
%   diagonal and still looks plausible, which is why it is written out here.

NARROW = 3;                          % per run. Three reads as a direction
LEN    = 11;                         % metres on the plot, at V_c = 0.5

for i = 1:numel(R)
    if ~isfield(R{i}, 'V_c') || R{i}.V_c <= 0, continue; end   % still water

    b  = deg2rad(R{i}.beta_c);
    dE = LEN * (R{i}.V_c/0.5) * sin(b);
    dN = LEN * (R{i}.V_c/0.5) * cos(b);

    %  Anchor the arrows beside the track, not on it, so they never cross a
    %  hull outline. The offset is perpendicular to the current itself.
    k  = round(linspace(0.18, 0.82, NARROW) * size(R{i}.y,1));
    ox =  0.9*dN;                    % perpendicular to (dE,dN)
    oy = -0.9*dE;

    quiver(R{i}.y(k,5) + ox, R{i}.y(k,4) + oy, ...
           repmat(dE, NARROW, 1), repmat(dN, NARROW, 1), 0, ...
           'Color', COL(1+mod(i-1,4),:), 'LineWidth', 1.0, ...
           'MaxHeadSize', 0.55, 'HandleVisibility', 'off');
end
end
