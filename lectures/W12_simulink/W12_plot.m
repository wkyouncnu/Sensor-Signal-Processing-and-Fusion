function f = W12_plot(R, LBL, ttl, STY)
%W12_PLOT  12주차 실행 결과의 상태량과 궤적을 그린다.
%          Draw the states and the track of one or more Week 12 runs.
%
%   W12_plot                      기본 작업공간에 있는 실행 결과
%                                 the run sitting in the base workspace
%   W12_plot(R, LBL, ttl)         실행 결과들의 셀 배열. V 절이 이렇게 부른다
%                                 a cell array of runs, as used by section V
%   W12_plot(R, LBL, ttl, STY)    선 모양 하나씩 — 겹치는 두 경우를 **둘 다
%                                 보이게** 하는 유일한 방법이다. 뒤의 것을 점선
%                                 두껍게 주면 앞의 실선 위에 얹혀 두 곡선이
%                                 같다는 것이 눈으로 읽힌다
%                                 one line style per run; a dashed, thicker last
%                                 run lies on top of the solid one it duplicates
%   f = W12_plot(...)             그림 핸들 / the figure handle
%
%   어디서 불리는가 / where this is called from
%       모델의 StopFcn 이 자동으로 부른다. 따라서 Simulink 에서 Run 을 누르면
%       다른 명령 없이 그림이 뜬다. V 절도 같은 함수를 부르므로, 학생이 화면에서
%       보는 그림과 강의노트에 실린 그림이 같은 코드에서 나온다.
%
%   R 의 원소는 `W12_read` 가 돌려주는 struct 다 — 필드 이름으로 쓰고 열 번호를
%   세지 않는다. StopFcn 으로 불릴 때는 기본 작업공간의 로그를 같은 모양으로
%   바꿔서 쓴다 / each element of R is what W12_read returns; the StopFcn path
%   converts the base-workspace log into the same shape.
%       t  u  v  r [rad/s]  N  E  psi [deg]  n [4]  delta [4 rad]
%
%   궤적에 선체를 함께 그린다 / the hull is drawn along the track
%       1단계의 요점이 "준 명령대로 가는가" 이고, 그 판정에는 **어디로 가는가**와
%       **어디를 향하는가**가 함께 필요하다. 틸팅 넷을 모두 45 도로 돌리면 배는
%       비스듬히 미끄러지면서도 선수를 거의 그 자리에 둔다 — 궤적선만으로는
%       그것이 보이지 않는다.
%
%   See also W12_READ, W12_V_OPENLOOP, TRACK_SHIPS, LAB_FIG.

if nargin < 1 || isempty(R)
    % StopFcn path: pick the logged signal out of the base workspace
    if evalin('base', '~exist(''W12'',''var'')')
        return                                   % nothing logged, nothing to draw
    end
    W = evalin('base', 'W12');
    y = squeeze(W.signals.values);
    if size(y,1) < size(y,2), y = y.'; end
    R = {named(W.time, y)};
    if evalin('base', 'exist(''n_cmd'',''var'') && exist(''d_cmd'',''var'')')
        nc = evalin('base', 'n_cmd');  dc = evalin('base', 'd_cmd');
        LBL = {sprintf('n = [%g %g %g %g],  delta = [%g %g %g %g] deg', ...
                       nc, rad2deg(dc))};
    else
        LBL = {'run'};
    end
    ttl = 'W12 open loop — result of the last simulation';
end
if nargin < 2 || isempty(LBL), LBL = arrayfun(@(k) sprintf('case %d', k), ...
                                              1:numel(R), 'UniformOutput', false); end
if nargin < 3 || isempty(ttl), ttl = 'W12 four tilting thrusters, open loop'; end
if nargin < 4 || isempty(STY), STY = repmat({'-'}, 1, numel(R)); end

sty = @(i) STY{1+mod(i-1, numel(STY))};
lw  = @(i) 1.4 + 0.8*strcmp(sty(i), '--');   % 점선은 두껍게 — 실선 위에 얹힌다

%  여덟 줄이다 — 시나리오 여덟이 **서로 다른 색**이어야 겹쳐 그린 그림에서
%  갈라진다 / eight rows, one per scenario, so the overlay separates
COL = [0    0.45 0.74
       0.85 0.33 0.10
       0.47 0.67 0.19
       0.49 0.18 0.56
       0.30 0.75 0.93
       0.64 0.08 0.18
       0.93 0.69 0.13
       0.20 0.20 0.20];
col = @(i) COL(1+mod(i-1, size(COL,1)), :);

f = lab_fig('W12  states and track', 1150, 680);

%  칸 배치 / the panel layout
%      궤적은 1:1 이라 자료가 상자의 모양을 정하고, 이 주차의 자료는 가로보다
%      세로가 두 배 넘게 길다. 그래서 궤적을 **오른쪽 세로 한 칸 전체**에 두고
%      상태량 넷을 왼쪽 2x2 에 둔다. 가로로 넓은 칸에 두면 상자가 가운데로
%      줄어들고 양옆이 빈다 / the track is 1:1, so it gets the tall right column
S  = {'u  surge [m/s]', 'v  sway [m/s]', 'r  yaw rate [deg/s]'};
CL = [1 2 4];                               % 상태량 세 칸 / the three state cells
for s = 1:3
    subplot(2,3,CL(s)); hold on;
    for i = 1:numel(R)
        switch s
            case 1, d = R{i}.u;
            case 2, d = R{i}.v;
            case 3, d = rad2deg(R{i}.r);
        end
        plot(R{i}.t, d, 'Color', col(i), 'LineStyle', sty(i), 'LineWidth', lw(i));
    end
    xlabel('time [s]'); ylabel(S{s});
    if s == 1
        legend(LBL, 'Location','best', 'Interpreter','none', 'FontSize', 8);
    end
end

subplot(2,3,5); hold on;
for i = 1:numel(R)
    plot(R{i}.t, R{i}.psi, 'Color', col(i), 'LineStyle', sty(i), 'LineWidth', lw(i));
end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
title('unwrapped — nothing here wraps it');

ax = subplot(2,3,[3 6]); hold on;
for i = 1:numel(R)
    plot(R{i}.E, R{i}.N, 'Color', col(i), 'LineStyle', sty(i), 'LineWidth', lw(i));
end
track_ships(cellfun(@(r) [r.N r.E r.psi], R, 'UniformOutput', false), COL);
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
xlabel('East [m]'); ylabel('North [m]');

%  축은 **자료가 정한다** / the data sets the limits
%      `axis equal` 만 걸면 MATLAB 은 넓은 칸을 채우려고 가로 범위를 늘려서,
%      반지름 1.5 m 짜리 선회와 60 m 직진을 한 칸에 놓았을 때 그림의 3분의 2 가
%      빈칸이 된다. 범위를 자료에서 잡고 `daspect` 로 1:1 을 고정하면 상자가
%      대신 줄어든다 / fixing the limits and the data aspect shrinks the box
%      instead of padding the East axis
Ea = cell2mat(cellfun(@(r) r.E(:), R(:), 'UniformOutput', false));
Na = cell2mat(cellfun(@(r) r.N(:), R(:), 'UniformOutput', false));
pad = 0.08 * max([max(Ea)-min(Ea), max(Na)-min(Na), 4]);
xlim(ax, [min(Ea)-pad, max(Ea)+pad]);
ylim(ax, [min(Na)-pad, max(Na)+pad]);
daspect(ax, [1 1 1]);
title({'track — the hull is drawn every few metres', ...
       'bow = triangle, and the line leaving it is the heading'});

sgtitle(ttl, 'FontWeight','bold');
end

% =========================================================================
function R = named(t, y)
%  로그의 열 순서를 이름으로. 이 순서를 정하는 것은 `_tools/add_measurement` 이고
%  `W12_read` 가 같은 이름을 쓴다 / the column order add_measurement fixes
R.t     = t;
R.u     = y(:, 1);  R.v   = y(:, 2);  R.r   = y(:, 3);
R.N     = y(:, 4);  R.E   = y(:, 5);  R.psi = y(:, 6);     % [deg]
R.n     = y(:,  7:10);
R.delta = y(:, 11:14);
end
