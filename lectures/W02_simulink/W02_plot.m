function f = W02_plot(R, LBL, ttl)
%W02_PLOT  W02 실행 결과의 설정값·응답·요구한 힘·적분기 상태를 그린다.
%          Reference, response, demand and integrator state of Week 2 runs.
%
%   W02_plot                      기본 작업공간에 있는 실행 결과
%                                 the run sitting in the base workspace
%   W02_plot(R, LBL, ttl)         실행 결과들의 셀 배열 / a cell array of runs
%   f = W02_plot(...)             그림 핸들 / the figure handle
%
%   모델의 StopFcn 이 자동으로 부르므로, Run 을 누르면 다른 명령 없이 그림이 뜬다.
%   절 스크립트도 같은 함수를 부르므로 화면의 그림과 강의노트의 그림이 어긋나지 않는다.
%   Called automatically by the model's StopFcn, so pressing Run produces the
%   figure without any further command. The section scripts call the same
%   function, so the figure on screen and the one in the notes cannot differ.
%
%   R is a cell array of structs with fields t and y, where the nine columns of
%   y are
%
%     1 u_d   2 u   3 X_cmd   4 X_sat   5 I   6 n1
%
%   The model logs the course-wide contract of add_measurement,
%   [u v r N E psi u_d X_cmd X_sat I n1]. w02_cols reorders it into the six
%   columns this week actually plots, at the single point where it is read.

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''W02'',''var'')'), return, end
    W = evalin('base', 'W02');
    y = squeeze(W.signals.values);  if size(y,1) < size(y,2), y = y.'; end
    R = {struct('t', W.time, 'y', w02_cols(y))};
    LBL = {'run'};
    ttl = 'W02 surge speed control — result of the last simulation';
end
if nargin < 2 || isempty(LBL), LBL = arrayfun(@(k) sprintf('run %d', k), ...
                                              1:numel(R), 'UniformOutput', false); end
if nargin < 3 || isempty(ttl), ttl = 'W02 surge speed control'; end

COL = [0    0.45 0.74
       0.85 0.33 0.10
       0.47 0.67 0.19
       0.49 0.18 0.56];
c = @(i) COL(1+mod(i-1,4),:);

%  The actuator limits, drawn on every force axis. A demand outside them is
%  not a demand at all.
cfg   = otter_config('base');
X_hi  =  2*cfg.k_pos*cfg.n_max^2;
X_lo  = -2*cfg.k_neg*cfg.n_min^2;
K_u   = (6*0.5144)/(24.4*9.81);          % 1/|X_u|, [(m/s) per N]

f = lab_fig('W02  speed loop', 1150, 680);

% -- speed -----------------------------------------------------------------
subplot(2,3,[1 2]); hold on;
plot(R{1}.t, R{1}.y(:,1), '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.4);
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,2), 'Color', c(i), 'LineWidth',1.3); end
%  Full ahead gives exactly U_max = 3.0864 m/s. No gain can move this line.
yline(X_hi*K_u, ':', 'u_{max} = 3.0864', ...
      'Color',[0.75 0.2 0.2], 'LabelHorizontalAlignment','left');
xlabel('time [s]'); ylabel('u  surge speed [m/s]');
legend([{'u_d'} LBL], 'Location','best', 'Interpreter','none');
title('speed');

% -- error -----------------------------------------------------------------
subplot(2,3,3); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,1)-R{i}.y(:,2), 'Color', c(i)); end
yline(0, 'k:');
xlabel('time [s]'); ylabel('e = u_d - u  [m/s]');
title('error — does it reach zero?');

% -- demanded against delivered force --------------------------------------
subplot(2,3,[4 5]); hold on;
for i = 1:numel(R)
    plot(R{i}.t, R{i}.y(:,3), '--', 'Color', c(i));
    plot(R{i}.t, R{i}.y(:,4), '-',  'Color', c(i), 'LineWidth',1.3);
end
yline(X_hi, ':', 'X_{max}', 'Color',[0.75 0.2 0.2]);
yline(X_lo, ':', 'X_{min}', 'Color',[0.75 0.2 0.2]);
xlabel('time [s]'); ylabel('surge force [N]');
title('dashed = demanded X_{cmd},  solid = delivered X_{sat}');

% -- the integrator --------------------------------------------------------
subplot(2,3,6); hold on;
for i = 1:numel(R), plot(R{i}.t, R{i}.y(:,5), 'Color', c(i)); end
yline(0, 'k:');
xlabel('time [s]'); ylabel('integrator state [N]');
title('what the integrator is holding');

sgtitle(ttl, 'FontWeight','bold');
end

% -------------------------------------------------------------------------
function z = w02_cols(y)
%W02_COLS  The course logging contract, reordered for this week.
%
%   add_measurement logs [u v r N E psi | u_d X_cmd X_sat I n1].
%   This week plots  [u_d u X_cmd X_sat I n1].
z = y(:, [7 1 8 9 10 11]);
end
