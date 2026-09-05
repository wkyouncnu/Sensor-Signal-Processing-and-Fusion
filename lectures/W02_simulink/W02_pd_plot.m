function f = W02_pd_plot(R, LBL, V, ttl)
%W02_PD_PLOT  Draw the four derivative implementations of section I.
%
%   W02_pd_plot                        the run sitting in the base workspace
%   W02_pd_plot(R, LBL, V, ttl)        for W02_I_pseudo_derivative
%   f = W02_pd_plot(...)               the figure handle
%
%   Called by the model's StopFcn, so pressing Run produces the figure without
%   any further command, and called by the runner, so the figure on screen and
%   the figure in the lecture note come from one piece of code.
%
%   The log is  [r  u1..u4  y1..y4  d1..d4].

if nargin < 1 || isempty(R)
    if evalin('base', '~exist(''W02pd'',''var'')'), return; end
    W = evalin('base', 'W02pd');
    y = squeeze(W.signals.values);
    if size(y,1) < size(y,2), y = y.'; end
    R = {struct('t', W.time, 'y', y)};
    V = struct('pd_N1', base_var('pd_N1', 100), 'pd_N2', base_var('pd_N2', 10), ...
               'pd_quiet', base_var('pd_quiet', 12), 'pd_r', base_var('pd_r', 1));
    LBL = {'P only', 'ideal  K_d s', ...
           sprintf('pseudo  N = %g', V.pd_N1), sprintf('pseudo  N = %g', V.pd_N2)};
    ttl = 'W02 section I — the pseudo-derivative';
end
if iscell(R), R = R{1}; end
if nargin < 4 || isempty(ttl), ttl = 'W02 section I — the pseudo-derivative'; end

COL = [0.47 0.67 0.19      % P only          green
       0.85 0.33 0.10      % ideal           orange
       0.00 0.45 0.74      % pseudo, fast    blue
       0.49 0.18 0.56];    % pseudo, slower  purple

f = lab_fig('W02  pseudo-derivative', 1250, 720);

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
