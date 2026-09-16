function f = W01_plot(R, LBL, ttl)
%W01_PLOT  1주차 실행 결과의 상태량과 궤적을 그린다.
%          Draw the states and the track of one or more Week 1 runs.
%
%   W01_plot                      기본 작업공간에 있는 실행 결과
%                                 the run sitting in the base workspace
%   W01_plot(R, LBL, ttl)         실행 결과들의 셀 배열. 절 D 가 이렇게 부른다
%                                 a cell array of runs, as used by section D
%   f = W01_plot(...)             그림 핸들 / the figure handle
%
%   어디서 불리는가 / where this is called from
%       모델의 StopFcn 이 자동으로 부른다. 따라서 Simulink 에서 Run 을 누르면
%       다른 명령 없이 그림이 뜬다. 절 D 도 같은 함수를 부르므로, 학생이 화면에서
%       보는 그림과 강의노트에 실린 그림이 같은 코드에서 나온다. 둘이 어긋날 수
%       없게 하려는 것이다.
%
%       The model's StopFcn calls this automatically, so pressing Run in
%       Simulink produces the figure without any further command. Section D
%       calls the same function, which means the figure seen on screen and the
%       figure printed in the lecture note come from one piece of code and
%       cannot disagree.
%
%   R is a cell array of structs with fields
%     t   time
%     y   [u  v  r(rad/s)  N  E  psi(deg)]

if nargin < 1 || isempty(R)
    % StopFcn path: pick the logged signal out of the base workspace
    if evalin('base', '~exist(''W01'',''var'')')
        return                                   % nothing logged, nothing to draw
    end
    W = evalin('base', 'W01');
    y = squeeze(W.signals.values);
    if size(y,1) < size(y,2), y = y.'; end
    R   = {struct('t', W.time, 'y', y)};
    if evalin('base', 'exist(''n0'',''var'') && exist(''dn'',''var'')')
        LBL = {sprintf('n0 = %g, dn = %g', evalin('base','n0'), evalin('base','dn'))};
    else
        LBL = {'run'};
    end
    ttl = 'W01 open loop — result of the last simulation';
end
if nargin < 2 || isempty(LBL), LBL = arrayfun(@(k) sprintf('run %d', k), ...
                                              1:numel(R), 'UniformOutput', false); end
if nargin < 3 || isempty(ttl), ttl = 'W01 open loop'; end

COL = [0    0.45 0.74
       0.85 0.33 0.10
       0.47 0.67 0.19
       0.49 0.18 0.56];

f = lab_fig('W01  states and track', 1100, 660);

S = {'u  surge [m/s]', 'v  sway [m/s]', 'r  yaw rate [deg/s]'};
for s = 1:3
    subplot(2,3,s); hold on;
    for i = 1:numel(R)
        switch s
            case 1, d = R{i}.y(:,1);
            case 2, d = R{i}.y(:,2);
            case 3, d = rad2deg(R{i}.y(:,3));
        end
        plot(R{i}.t, d, 'Color', COL(1+mod(i-1,4),:));
    end
    xlabel('time [s]'); ylabel(S{s});
    if s == 1
        legend(LBL, 'Location','best', 'Interpreter','none');
    end
end

subplot(2,3,4); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,6), 'Color', COL(1+mod(i-1,4),:)); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
title('unwrapped — nothing here wraps it');

subplot(2,3,[5 6]); hold on; axis equal;
for i = 1:numel(R)
    plot(R{i}.y(:,5), R{i}.y(:,4), 'Color', COL(1+mod(i-1,4),:));
end
track_ships(cellfun(@(r) r.y(:,[4 5 6]), R, 'UniformOutput', false), COL);
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
xlabel('East [m]'); ylabel('North [m]');
title({'track — the hull is drawn every few metres', ...
       'bow = triangle, and the line leaving it is the heading'});

sgtitle(ttl, 'FontWeight','bold');
end
