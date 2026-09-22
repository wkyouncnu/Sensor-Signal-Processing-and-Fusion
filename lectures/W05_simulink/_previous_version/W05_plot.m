function f = W05_plot(y, V, ttl, rows)
%W05_PLOT  네 유도법칙의 궤적과 경로이탈 오차를 그린다.
%          Track and cross-track error of the four guidance laws.
%
%   W05_plot                       기본 작업공간에 있는 실행 결과
%                                  the run sitting in the base workspace
%   W05_plot(y, V, ttl, rows)      W05_read 가 만든 구조체. 절 스크립트가 쓴다
%                                  a struct from W05_read, for a section script
%   f = W05_plot(...)              그림 핸들 / the figure handle
%
%   rows 로 그릴 법칙을 고른다. 절마다 비교하려는 대상이 다르기 때문이다 — 절 D 는
%   atan2 와 LOS 둘만, 절 G 는 넷 모두를 그린다.
%   rows selects which laws to draw, because each section compares a different
%   pair or group: section D draws atan2 against LOS, section G draws all four.
%
%   Called by the model's StopFcn, so pressing Run in Simulink produces the
%   figure without any further command, and by the section scripts, so the
%   figure on screen and the figure in the lecture come from one piece of code.
%
%   ROWS selects which of the four laws to draw, in the order
%   1 atan2, 2 LOS, 3 ILOS, 4 ALOS. The base-workspace variable guid_show
%   does the same when the model is run from Simulink: 0 draws all four.

COL = [0.85 0.33 0.10      % atan2  — the one that does not work
       0    0.45 0.74      % LOS
       0.47 0.67 0.19      % ILOS
       0.49 0.18 0.56];    % ALOS

if nargin < 1 || isempty(y)
    if evalin('base', '~exist(''W05'',''var'')'), return, end
    W = evalin('base', 'W05');
    z = squeeze(W.signals.values);  if size(z,1) < size(z,2), z = z.'; end
    y = W05_read(struct('t', W.time, 'y', z));
    V = W05_vars;
    V.V_c = base_var('V_c', 0);  V.beta_c = base_var('beta_c', 0);
    ttl  = 'W05 guidance — four laws, one mission';
    rows = base_var('guid_show', 0);
end
if nargin < 3 || isempty(ttl),  ttl  = 'W05 guidance'; end
if nargin < 4 || isempty(rows), rows = 0; end
if isscalar(rows) && rows == 0,  rows = 1:4; end

f = lab_fig('W05  guidance', 1150, 470);

subplot(1,2,1);
path_plot(V.WP, V.R_switch, y.trkN(:,rows), y.trkE(:,rows), y.trkPsi(:,rows), ...
          COL(rows,:), y.name(rows), V);
legend('Location','southoutside', 'NumColumns',2);
title({'the track', 'hull and heading drawn along each'});

subplot(1,2,2); hold on;
yline(0, 'k:', 'HandleVisibility','off');
for i = rows
    plot(y.t, y.y_e(:,i), 'Color', COL(i,:), 'DisplayName', y.name{i});
end
xlabel('time [s]'); ylabel('y_e  cross-track error [m]');
legend('Location','best');
%  The settled value is read over the LAST QUARTER of the run, after the final
%  corner, so the number describes steady tracking and not a turn.
k = y.t >= 0.75*y.t(end);
title({'the distance from the path', ...
       sprintf('settled |y_e| over the last quarter: %s', ...
               strjoin(arrayfun(@(i) sprintf('%s %.2f m', y.name{i}, ...
                       mean(abs(y.y_e(k,i)))), rows, 'UniformOutput',false), ',  '))});

sgtitle(ttl, 'FontWeight','bold');
end
