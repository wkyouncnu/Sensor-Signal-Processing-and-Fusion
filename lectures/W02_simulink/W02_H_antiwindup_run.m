%% W02 · section H — the windup principle, on a first-order plant
%
%      W02_0_setup
%      W02_H_antiwindup_run
%
%  Everything the vessel showed in F, on G(s) = 1/(s+1) with |u| <= 1.
%  Four controllers, one plant each, the same gains throughout.

varargin = {};   % kept so the override loop below still works unchanged
%W02_AW_RUN  Run W02_H_antiwindup.slx, report the measurements, save the figures.
%
%   W02_H_antiwindup                    the anti-windup demonstration
%   W02_H_antiwindup('aw_Kb', 10)       override any variable
%
%   Produces
%     img/W02_H_antiwindup.png            the block diagram
%     img/W02_result_aw_principle.png   the four schemes on one plant
%     img/W02_result_aw_Kb.png          what the back-calculation gain does

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_H_antiwindup.slx')), W02_H_build_antiwindup(); end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = aw_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

LBL = {'none','clamping','back-calculation','by hand'};

fprintf('\n  W02 · the anti-windup principle, on a first-order plant\n');
fprintf('\n    G(s) = 1/(s+1),  u in [%g, %g],  Kp = %g, Ki = %g, Kb = %g\n', ...
        V.aw_umin, V.aw_umax, V.aw_Kp, V.aw_Ki, V.aw_Kb);
fprintf('    r = 0 -> %g at t = %g s  (unreachable: y_max = %g)\n', ...
        V.aw_r1, V.aw_t1, V.aw_umax);
fprintf('      then -> %g at t = %g s  (reachable)\n', V.aw_r2, V.aw_t2);

%% =====================================================================
%  1. The four schemes
%  =====================================================================
R = one(V);

%  Setting Kb = 0 switches the back-calculation off, so row 4 becomes a plain
%  PI with no anti-windup at all. Its integrator state is then the windup
%  itself, measured rather than estimated.
R0 = one(V, 'aw_Kb', 0);

fprintf('\n  1) the four schemes\n\n');
fprintf('    %-18s %18s %16s %16s\n', ...
        'anti-windup', 'time on the limit', 'recovery [s]', 'y at t = 20 s');
fprintf('    %s\n', repmat('-', 1, 74));
rec = zeros(1,4);
for i = 1:4
    rec(i) = recovery_time(R.t, R.y(:,5+i), V.aw_r2, V.aw_t2);
    fprintf('    %-18s %18.2f %16.3f %16.4f\n', LBL{i}, ...
            on_limit(R.t, R.y(:,1+i), V.aw_umax), rec(i), ...
            interp1(R.t, R.y(:,5+i), 20));
end
fprintf(['\n    All four are IDENTICAL on the way up. While the reference is\n' ...
         '    unreachable every scheme sits on the limit, and the output of every\n' ...
         '    one of them is y = %.4f. Nothing distinguishes them yet.\n' ...
         '\n    They separate at t = %g s, when the reference becomes reachable.\n' ...
         '    Without anti-windup the loop needs %.2f s to come down; with\n' ...
         '    back-calculation it needs %.2f s, a factor of %.1f.\n' ...
         '\n    The integrator is where the difference lives, and setting Kb = 0\n' ...
         '    makes row 4 a plain PI so that it can be measured. Its state peaks\n' ...
         '    at %.2f against %.3f with back-calculation, a factor of %.0f, and\n' ...
         '    against a largest useful value of %.1f. Every unit of that excess\n' ...
         '    has to be integrated back out before the loop responds at all.\n'], ...
         interp1(R.t, R.y(:,6), V.aw_t2 - 0.1), V.aw_t2, rec(1), rec(3), ...
         rec(1)/rec(3), max(R0.y(:,10)), max(R.y(:,10)), ...
         max(R0.y(:,10))/max(R.y(:,10)), V.aw_umax);

gap = max(abs(R.y(:,8) - R.y(:,9)));
fprintf(['\n    Rows 3 and 4 agree to %.2e. The library block and the hand-built\n' ...
         '    path are the same algorithm, so the annotation inside PID bank is a\n' ...
         '    correct description of what the block does.\n'], gap);

%% =====================================================================
%  2. What the back-calculation gain does
%  =====================================================================
KB = [0.2 0.5 1 2 5 20 100];
fprintf('\n  2) the back-calculation gain\n\n');
fprintf('    %10s %16s %18s %16s\n', ...
        'Kb', 'recovery [s]', 'peak integrator', 'overshoot after [%]');
fprintf('    %s\n', repmat('-', 1, 66));
RK = cell(size(KB));  recK = zeros(size(KB));  ipk = recK;  ovs = recK;
for i = 1:numel(KB)
    RK{i}   = one(V, 'aw_Kb', KB(i));
    recK(i) = recovery_time(RK{i}.t, RK{i}.y(:,8), V.aw_r2, V.aw_t2);
    ipk(i)  = max(RK{i}.y(:,10));
    k       = RK{i}.t >= V.aw_t2;
    ovs(i)  = 100*(V.aw_r2 - min(RK{i}.y(k,8)))/V.aw_r2;
    fprintf('    %10g %16.3f %18.3f %16.2f\n', KB(i), recK(i), ipk(i), ovs(i));
end

%  Clamping, for comparison — it is the other scheme, not a limit of this one.
recC = recovery_time(R.t, R.y(:,7), V.aw_r2, V.aw_t2);
fprintf(['\n    Raising Kb shortens the recovery and lowers the stored charge, but\n' ...
         '    it does not converge on clamping, which recovers in %.3f s. The two\n' ...
         '    schemes do different things:\n' ...
         '\n      clamping         stops the integrator, holding whatever it had\n' ...
         '      back-calculation  drives the integrator towards the value that\n' ...
         '                        makes the demand equal the limit\n' ...
         '\n    A large Kb also makes the loop stiff at the moment of leaving\n' ...
         '    saturation. The undershoot after the step down is %.2f per cent at\n' ...
         '    Kb = %g and %.2f per cent at Kb = %g.\n'], ...
         recC, ovs(1), KB(1), ovs(end), KB(end));

out = R;

%% =====================================================================
%  Figures
%  =====================================================================
img = @(fn) fullfile(here, 'img', fn);

load_system('W02_H_antiwindup');
print('-sW02_H_antiwindup', '-dpng', '-r150', img('W02_H_antiwindup.png'));
close_system('W02_H_antiwindup', 0);

f = W02_aw_plot(R, ...
    'W02 — one plant, one limit, four ways of treating the integrator', R0);
exportgraphics(f, img('W02_result_aw_principle.png'), 'Resolution', 150);

f = lab_fig('W02  Kb sweep', 1050, 430);
subplot(1,2,1); hold on;
CO = parula(numel(KB));
plot(R.t, R.y(:,1), ':', 'Color',[0.35 0.35 0.35], 'LineWidth',1.3);
for i = 1:numel(KB)
    plot(RK{i}.t, RK{i}.y(:,8), 'Color', CO(i,:), 'LineWidth',1.3);
end
plot(R.t, R.y(:,7), '--', 'Color',[0.47 0.67 0.19], 'LineWidth',1.8);
xlim([V.aw_t2-1 V.aw_t2+12]);
xlabel('time [s]'); ylabel('y');
legend([{'r'} arrayfun(@(k) sprintf('K_b = %g', k), KB, 'UniformOutput',false) ...
        {'clamping'}], 'Location','southeast', 'NumColumns',2);
title({'leaving saturation', 'back-calculation at seven gains, and clamping'});

subplot(1,2,2); hold on;
yyaxis left
semilogx(KB, recK, 'o-', 'LineWidth',1.5);
yline(recC, ':', 'clamping', 'LineWidth',1.4);
ylabel('recovery time [s]');
yyaxis right
semilogx(KB, ipk, 's--', 'LineWidth',1.5);
ylabel('peak integrator state');
set(gca,'XScale','log'); grid on;
xlabel('K_b');
legend({'recovery','clamping','peak integrator'}, 'Location','north');
title({'more K_b, less stored charge', 'but it does not become clamping'});
sgtitle('W02 — back-calculation and clamping are different schemes', ...
        'FontWeight','bold');
exportgraphics(f, img('W02_result_aw_Kb.png'), 'Resolution', 150);

fprintf('\n  figures written to %s\n\n', fullfile(here,'img'));
%  (the old function-closing end was here; this file is a script now)

% =========================================================================
function o = one(V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput('W02_H_antiwindup');
fn = fieldnames(V);
for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
evalc('r = sim(in);');
y = squeeze(r.W02aw.signals.values);  if size(y,1) < size(y,2), y = y.'; end
o.t = r.W02aw.time;
o.y = y;      % [r  u1..u4  y1..y4  I_by_hand]
end

function p = on_limit(t, u, umax)
%ON_LIMIT  Seconds for which the control signal sat on its saturation limit.
%   Observable for every scheme, because u is what reaches the plant.
k = abs(abs(u) - umax) < 1e-6;
p = sum(k) * (t(2) - t(1));
end

function tr = recovery_time(t, y, yf, t0)
%RECOVERY_TIME  Time after t0 for the output to enter and stay in a 2% band.
k = t >= t0;
t = t(k) - t0;  y = y(k);
out = find(abs(y - yf) > 0.02*abs(yf), 1, 'last');
if isempty(out), tr = 0; else, tr = t(min(out+1, numel(t))); end
end

function V = aw_vars()
V.aw_Kp = 1.8;   V.aw_Ki = 4;    V.aw_Kb = 2;
V.aw_umax = 1;   V.aw_umin = -1;
V.aw_r1 = 2;     V.aw_r2 = 0.5;
V.aw_t1 = 1;     V.aw_t2 = 15;
V.aw_T  = 60;    V.h = 0.005;
end
