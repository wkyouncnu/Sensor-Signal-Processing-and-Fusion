%% W02 · section I — the pseudo-derivative
%
%      W02_0_setup
%      W02_I_pseudo_derivative_run
%
%  A plant that genuinely wants derivative action, and four ways of taking it.

varargin = {};   % kept so the override loop below still works unchanged
%W02_PD_RUN  Run W02_I_pseudo_derivative.slx and report what the derivative filter buys.
%
%   W02_I_pseudo_derivative                      the four rows of section I
%   W02_I_pseudo_derivative('pd_noise', 0)       override any variable
%   out = W02_I_pseudo_derivative(...)           out.t, out.y
%
%   THE QUESTION
%
%   Derivative action is genuinely wanted on this plant. So how should the
%   derivative be taken? Four answers are run side by side against the same
%   noise, and the price of each is measured rather than asserted.
%
%   Produces
%     img/W02_I_pseudo_derivative.png              the block diagram
%     img/W02_result_pd.png           the four rows: output, actuator, D term
%     img/W02_result_pd_N.png         the trade, swept over N

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_I_pseudo_derivative.slx')), W02_I_build_pseudo_derivative(); end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = base_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

LBL = {'P only', 'ideal  K_d s', ...
       sprintf('pseudo  N = %g', V.pd_N1), ...
       sprintf('pseudo  N = %g', V.pd_N2)};

fprintf('\n  W02 · section I — the pseudo-derivative\n');
fprintf('\n    plant        G(s) = 1/(s^2 + 0.4 s)\n');
fprintf('    controller   Kp = %g, Kd = %g, derivative on the measurement\n', V.pd_Kp, V.pd_Kd);
fprintf('    sensor noise power %g at Ts = %g s  ->  std = %.4f\n', ...
        V.pd_noise, V.pd_ts, sqrt(V.pd_noise/V.pd_ts));

%% =====================================================================
%  1. The four rows, with noise
%  =====================================================================
R = one(V);
out = R;

fprintf('\n  1) the four rows, with the same measurement noise\n\n');
fprintf('    %-20s %11s %11s %13s %13s\n', ...
        'derivative', 'overshoot', 'settling', 'RMS(u) quiet', 'max |u|');
fprintf('    %s\n', repmat('-', 1, 74));

M = zeros(4,4);
for i = 1:4
    y = R.y(:,5+i);  u = R.y(:,1+i);
    M(i,1) = overshoot(R.t, y, V.pd_r, V.pd_t1);
    M(i,2) = settling(R.t, y, V.pd_r, V.pd_t1);
    M(i,3) = rms_after(R.t, u, V.pd_quiet);
    M(i,4) = max(abs(u));
    fprintf('    %-20s %10.2f%% %10.2fs %13.4f %13.2f\n', LBL{i}, M(i,:));
end

fprintf(['\n    RMS(u) quiet is measured after t = %g s, when the transient is\n' ...
         '    over and everything left in the actuator signal is noise.\n'], V.pd_quiet);

fprintf(['\n    Row 1 has no derivative and overshoots %.1f%%. Row 2 cures that\n' ...
         '    -- overshoot %.1f%% -- and pays for it with an actuator signal whose\n' ...
         '    quiet-state RMS is %.0f times row 1''s and whose peak is %.0f.\n' ...
         '    Rows 3 and 4 keep the damping and give the actuator back.\n'], ...
         M(1,1), M(2,1), M(2,3)/M(1,3), M(2,4));

fprintf(['\n    The ideal derivative is not a better derivative. It is the same\n' ...
         '    operator with no upper limit on its gain, so it finds the fastest\n' ...
         '    thing in the measurement -- the noise -- and multiplies it by the\n' ...
         '    largest number available.\n']);

%% =====================================================================
%  2. Without noise, all four are nearly the same
%  =====================================================================
%  This is the control experiment. If the rows differed with the noise
%  switched off, the difference would be the filter's phase lag and not the
%  noise amplification, and the whole argument would be about something else.
Rq = one(setfield(V, 'pd_noise', 0));   %#ok<SFLD>
fprintf('\n  2) the same four rows with the noise switched off\n\n');
fprintf('    %-20s %11s %11s %13s\n', 'derivative', 'overshoot', 'settling', 'RMS(u) quiet');
fprintf('    %s\n', repmat('-', 1, 60));
Mq = zeros(4,3);
for i = 1:4
    y = Rq.y(:,5+i);  u = Rq.y(:,1+i);
    Mq(i,:) = [overshoot(Rq.t, y, V.pd_r, V.pd_t1), ...
               settling(Rq.t, y, V.pd_r, V.pd_t1), ...
               rms_after(Rq.t, u, V.pd_quiet)];
    fprintf('    %-20s %10.2f%% %10.2fs %13.6f\n', LBL{i}, Mq(i,:));
end
fprintf(['\n    Every RMS(u) in this table is essentially zero: with no noise there\n' ...
         '    is nothing left for the derivative to amplify, and the difference\n' ...
         '    between rows 2 to 4 in experiment 1 -- a factor of %.0f -- was noise\n' ...
         '    and nothing else.\n'], M(2,3)/M(4,3));
fprintf(['\n    The response itself changes by only %.1f points of overshoot across\n' ...
         '    rows 2 to 4, and the slower filter is the BETTER of the three here.\n' ...
         '    Filtering the derivative is not a concession; at this N it costs\n' ...
         '    nothing in the response and removes most of the noise.\n'], ...
         max(Mq(2:4,1)) - min(Mq(2:4,1)));

%% =====================================================================
%  3. Sweeping N — the trade, in one table
%  =====================================================================
NS  = [2 5 10 20 50 100 200 500];
sw  = zeros(numel(NS), 3);
fprintf('\n  3) sweeping the filter coefficient N\n\n');
fprintf('    %8s %13s %12s %13s\n', 'N', 'overshoot', 'settling', 'RMS(u) quiet');
fprintf('    %s\n', repmat('-', 1, 50));
for k = 1:numel(NS)
    Rk = one(V, 'pd_N2', NS(k));
    y  = Rk.y(:,9);  u = Rk.y(:,5);          % row 4 is the swept one
    sw(k,:) = [overshoot(Rk.t, y, V.pd_r, V.pd_t1), ...
               settling(Rk.t, y, V.pd_r, V.pd_t1), ...
               rms_after(Rk.t, u, V.pd_quiet)];
    fprintf('    %8g %12.2f%% %11.2fs %13.4f\n', NS(k), sw(k,:));
end
[~, kb] = min(sw(:,1));
fprintf(['\n    The two columns do NOT trade off across the whole range. Overshoot\n' ...
         '    is worst at N = %g, best at N = %g, and then creeps back up and\n' ...
         '    FLATTENS -- from N = %g to N = %g it changes by %.1f points while\n' ...
         '    RMS(u) grows by a factor of %.0f.\n'], ...
         NS(1), NS(kb), NS(end-2), NS(end), ...
         sw(end,1)-sw(end-2,1), sw(end,3)/sw(end-2,3));
fprintf(['\n    So there are two regimes, not one trade:\n' ...
         '      N below about %g   the derivative arrives late, damping is lost\n' ...
         '      N above about %g   the response stops improving, the noise does not\n' ...
         '\n    Large N is not a safe default. It buys nothing and charges for it.\n' ...
         '    Choose N just above the closed-loop bandwidth -- here wn = %.1f rad/s\n' ...
         '    -- and no higher.\n'], NS(kb), NS(kb), sqrt(V.pd_Kp));

%% =====================================================================
%  Figures
%  =====================================================================
img = @(f) fullfile(here, 'img', f);
COL = [0.47 0.67 0.19; 0.85 0.33 0.10; 0.00 0.45 0.74; 0.49 0.18 0.56];

load_system('W02_I_pseudo_derivative');
print('-sW02_I_pseudo_derivative', '-dpng', '-r150', img('W02_I_pseudo_derivative.png'));
close_system('W02_I_pseudo_derivative', 0);

f = W02_pd_plot({R}, LBL, V, ...
    'W02 section I — one derivative, taken four ways, against the same noise');
exportgraphics(f, img('W02_result_pd.png'), 'Resolution', 150);

f = lab_fig('W02  choosing N', 1000, 400);
subplot(1,2,1);
semilogx(NS, sw(:,3), 'o-', 'Color', COL(3,:), 'MarkerFaceColor', COL(3,:));
xlabel('N  filter coefficient'); ylabel('RMS(u) in the quiet state');
title({'what a large N costs', 'the actuator works harder for no benefit'});
grid on;
subplot(1,2,2);
semilogx(NS, sw(:,1), 'o-', 'Color', COL(2,:), 'MarkerFaceColor', COL(2,:));
hold on;
plot(NS(kb), sw(kb,1), 'p', 'MarkerSize', 14, ...
     'MarkerFaceColor', COL(1,:), 'MarkerEdgeColor', COL(1,:));
text(NS(kb), sw(kb,1), sprintf('  best, N = %g', NS(kb)), 'Color', COL(1,:));
xlabel('N  filter coefficient'); ylabel('overshoot [%]');
title({'what a small N costs', 'below the best N the derivative arrives late'});
grid on;
sgtitle(sprintf(['W02 section I — above N \\approx %g the response stops improving ' ...
                 'and only the noise grows'], NS(kb)), 'FontWeight','bold');
exportgraphics(f, img('W02_result_pd_N.png'), 'Resolution', 150);

fprintf('\n  figures written to %s\n\n', fullfile(here,'img'));
%  (the old function-closing end was here; this file is a script now)

% =========================================================================
function o = one(V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput('W02_I_pseudo_derivative');
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
evalc('r = sim(in);');
y = squeeze(r.W02pd.signals.values);
if size(y,1) < size(y,2), y = y.'; end
o.t = r.W02pd.time;
o.y = y;              % [r  u1..u4  y1..y4  d1..d4]
end

function p = overshoot(t, y, r, t0)
k = t >= t0;
p = 100*(max(y(k)) - r)/r;
if p < 0, p = 0; end
end

function ts = settling(t, y, r, t0)
%SETTLING  First time after t0 from which y stays inside a 2% band on r.
k    = find(t >= t0);
band = 0.02*abs(r);
out  = find(abs(y(k) - r) > band, 1, 'last');
if isempty(out), ts = 0; else, ts = t(k(min(out+1, numel(k)))) - t0; end
end

function v = rms_after(t, u, t0)
%RMS_AFTER  RMS of the actuator signal about its own mean, after t0.
%   The mean is removed because it is the steady demand, not activity.
k = t >= t0;
v = sqrt(mean((u(k) - mean(u(k))).^2));
end

function V = base_vars()
V.pd_Kp    = 4;          % proportional gain
V.pd_Kd    = 2;          % derivative gain, same in all four rows
V.pd_N1    = 100;        % fast filter
V.pd_N2    = 10;         % slower filter
V.pd_r     = 1;          % step height
V.pd_t1    = 1;          % step time [s]
V.pd_T     = 20;         % run length [s]
V.pd_quiet = 12;         % after this, the transient is over [s]
V.pd_noise = 1e-6;       % noise power  -> std = sqrt(Cov/Ts) = 0.01
V.pd_ts    = 0.01;       % noise sample time [s]
V.h        = 0.001;      % solver step [s] — small, the ideal derivative needs it
end
