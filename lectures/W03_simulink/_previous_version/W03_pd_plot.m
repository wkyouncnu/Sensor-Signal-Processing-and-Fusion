function f = W03_pd_plot(R, LBL, V, ttl)
%W03_PD_PLOT  절 I 의 네 가지 미분 구현을 그린다.
%             Draw the four derivative implementations of section I.
%
%   W03_pd_plot                        기본 작업공간에 있는 실행 결과
%                                      the run sitting in the base workspace
%   W03_pd_plot(R, LBL, V, ttl)        절 I 스크립트가 부르는 형태
%                                      the form the section I script uses
%   f = W03_pd_plot(...)               그림 핸들 / the figure handle
%
%   모델의 StopFcn 과 절 스크립트가 모두 이 함수를 부른다. 그래서 Run 만 눌러도
%   그림이 뜨고, 화면의 그림과 강의노트의 그림이 같은 코드에서 나온다.
%   Both the model's StopFcn and the section script call this, so pressing Run
%   produces the figure without any further command, and the figure on screen
%   and the figure in the lecture note come from one piece of code.
%
%   로그의 열 구성 / the columns of the log
%       [r  u1..u4  y1..y4  d1..d4]
%       설정값 하나, 네 방식의 작동기 신호, 그 출력, 그리고 각 방식이 실제로 낸
%       미분항이다. 미분항을 따로 기록하는 것이 이 절의 요점이다 — 잡음이
%       증폭되는 자리가 바로 거기이고, 출력만 보아서는 보이지 않는다.
%
%       The reference, the actuator signal of each of the four schemes, their
%       outputs, and the derivative term each one actually produced. Logging
%       the derivative term separately is the point of this section: that is
%       where the noise is amplified, and it cannot be seen in the output.

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''W03pd'',''var'')'), return; end
    W = evalin('base', 'W03pd');
    y = squeeze(W.signals.values);
    if size(y,1) < size(y,2), y = y.'; end
    R = {struct('t', W.time, 'y', y)};
    V = struct('pd_N1', base_var('pd_N1', 100), 'pd_N2', base_var('pd_N2', 10), ...
               'pd_quiet', base_var('pd_quiet', 12), 'pd_r', base_var('pd_r', 1));
    LBL = {'P only', 'ideal  K_d s', ...
           sprintf('pseudo  N = %g', V.pd_N1), sprintf('pseudo  N = %g', V.pd_N2)};
    ttl = 'W03 section I — the pseudo-derivative';
end
if iscell(R), R = R{1}; end
if nargin < 4 || isempty(ttl), ttl = 'W03 section I — the pseudo-derivative'; end

COL = [0.47 0.67 0.19      % P only          green
       0.85 0.33 0.10      % ideal           orange
       0.00 0.45 0.74      % pseudo, fast    blue
       0.49 0.18 0.56];    % pseudo, slower  purple

f = lab_fig('W03  pseudo-derivative', 1250, 720);

%  ---- the outputs: this is where the derivative earns its place --------
subplot(2,2,1); hold on;
for i = 1:4, plot(R.t, R.y(:,5+i), 'Color', COL(i,:)); end
yline(V.pd_r, 'k:', 'HandleVisibility','off');
xlabel('time [s]'); ylabel('y  output');
legend(LBL, 'Location','southeast');
title({'the response', 'row 1 rings; the other three are damped, and alike'});

%  ---- the actuator: this is where it charges for it -------------------
subplot(2,2,2); hold on;
for i = 1:4, plot(R.t, R.y(:,1+i), 'Color', COL(i,:)); end
xlabel('time [s]'); ylabel('u  actuator demand');
title({'the actuator, whole run', 'the ideal derivative is off the scale of the others'});

%  ---- the quiet state, magnified --------------------------------------
%  After the transient there is nothing left to differentiate except noise,
%  so this window shows the noise amplification on its own.
%
%  Row 2 is LEFT OUT of this panel on purpose. Drawn with the others it sets
%  the y scale at +-100 and flattens the three rows the panel exists to
%  compare. Its size is the subject of the panel above; its absence here is
%  what makes the remaining three readable.
subplot(2,2,3); hold on;
k = R.t >= V.pd_quiet;
for i = [1 3 4], plot(R.t(k), R.y(k,1+i), 'Color', COL(i,:)); end
xlabel('time [s]'); ylabel('u  actuator demand');
legend(LBL([1 3 4]), 'Location','best');
title({sprintf('the quiet state, after t = %g s — ideal row omitted', V.pd_quiet), ...
       sprintf('it reaches \\pm%.0f here, off this scale', max(abs(R.y(k,3))))});

%  ---- the derivative term itself --------------------------------------
subplot(2,2,4); hold on;
for i = [3 4], plot(R.t, R.y(:,9+i), 'Color', COL(i,:)); end
xlabel('time [s]'); ylabel('derivative term  [-K_d \times dy/dt]');
legend(LBL([3 4]), 'Location','best');
title({'the derivative term, the two filtered rows', ...
       sprintf('N = %g passes %.0f\\times the noise that N = %g does', ...
               V.pd_N1, std(R.y(k,12))/std(R.y(k,13)), V.pd_N2)});

sgtitle(ttl, 'FontWeight','bold');
end
