function f = W02_aw_plot(R, ttl, R0)
%W02_AW_PLOT  절 H 의 안티와인드업 실험을 그린다.
%             The anti-windup demonstration of section H, drawn.
%
%   W02_aw_plot                 기본 작업공간에 있는 실행 결과
%                               the run sitting in the base workspace
%   W02_aw_plot(R, ttl)         W02_H_antiwindup 이 만든 구조체
%                               a struct from W02_H_antiwindup
%
%   W02_H_antiwindup.slx 의 StopFcn 이 자동으로 부른다.
%   Called automatically by the StopFcn of W02_H_antiwindup.slx.
%
%   R.y 의 열 구성 — 그 모델의 로깅 규약이다 / the logging contract of that model:
%     1    설정값 r / the reference
%     2:5  네 방식의 작동기 신호 u / the actuator signal of the four schemes
%     6:9  네 방식의 출력 y / their outputs
%     10   4행의 적분기 상태 / the integrator state of row 4
%
%   적분기 상태를 4행에서만 뽑는 이유는, 그 행이 손으로 조립한 경로여서 내부
%   신호를 꺼낼 수 있기 때문이다. 라이브러리 블록에서는 그럴 수 없다.
%   The integrator state is taken from row 4 alone because that row is the
%   hand-built path, whose internal signals can be brought out; those of the
%   library block cannot.

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''W02aw'',''var'')'), return, end
    W = evalin('base', 'W02aw');
    y = squeeze(W.signals.values);  if size(y,1) < size(y,2), y = y.'; end
    R = struct('t', W.time, 'y', y);
    ttl = 'W02 anti-windup — result of the last simulation';
end
if nargin < 2 || isempty(ttl), ttl = 'W02 anti-windup'; end
if nargin < 3, R0 = []; end

LBL = {'none','clamping','back-calculation','by hand'};
COL = [0.85 0.33 0.10
       0.47 0.67 0.19
       0    0.45 0.74
       0.49 0.18 0.56];

umax = base_var('aw_umax', 1);
umin = base_var('aw_umin', -1);

f = lab_fig('W02  anti-windup', 1150, 660);

% -- output ----------------------------------------------------------------
subplot(2,2,1); hold on;
plot(R.t, R.y(:,1), ':', 'Color',[0.35 0.35 0.35], 'LineWidth',1.4);
for i = 1:4
    lw = 2.5 - 1.2*(i == 4);   st = '-';  if i == 4, st = '--'; end
    plot(R.t, R.y(:,5+i), st, 'Color', COL(i,:), 'LineWidth', lw);
end
yline(umax, ':', 'y_{max} = K u_{max}', 'Color',[0.75 0.2 0.2]);
xlabel('time [s]'); ylabel('y');
legend([{'r'} LBL], 'Location','southeast');
title({'output', 'identical on the way up, different on the way down'});

% -- control ---------------------------------------------------------------
subplot(2,2,2); hold on;
for i = 1:4
    lw = 2.5 - 1.2*(i == 4);   st = '-';  if i == 4, st = '--'; end
    plot(R.t, R.y(:,1+i), st, 'Color', COL(i,:), 'LineWidth', lw);
end
yline(umax, ':', 'Color',[0.75 0.2 0.2]);
yline(umin, ':', 'Color',[0.75 0.2 0.2]);
xlabel('time [s]'); ylabel('u  (already saturated)');
title({'the control signal', 'all four sit on the limit while the demand is impossible'});

% -- the integrator --------------------------------------------------------
subplot(2,2,3); hold on;
if ~isempty(R0)
    plot(R0.t, R0.y(:,10), 'Color', COL(1,:), 'LineWidth',1.8);
end
plot(R.t, R.y(:,10), 'Color', COL(3,:), 'LineWidth',1.8);
yline(umax, ':', 'the largest value the limit can use', 'Color',[0.75 0.2 0.2]);
yline(0,'k:');
set(gca,'YScale','log'); ylim([1e-2 1e2]);
xlabel('time [s]'); ylabel('integrator state  (log scale)');
if ~isempty(R0)
    legend({'no anti-windup  (K_b = 0)','back-calculation'}, 'Location','southeast');
end
title({'the integrator, which is where the difference lives', ...
       'the whole of windup is the gap between these two curves'});

% -- the error -------------------------------------------------------------
subplot(2,2,4); hold on;
for i = 1:4
    lw = 2.5 - 1.2*(i == 4);   st = '-';  if i == 4, st = '--'; end
    plot(R.t, R.y(:,1) - R.y(:,5+i), st, 'Color', COL(i,:), 'LineWidth', lw);
end
yline(0,'k:');
xlabel('time [s]'); ylabel('e = r - y');
legend(LBL, 'Location','northeast');
title({'the error', 'it cannot reach zero while the reference is unreachable'});

sgtitle(ttl, 'FontWeight','bold');
end
