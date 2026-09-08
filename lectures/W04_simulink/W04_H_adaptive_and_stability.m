%% W04 · section H — the adaptive gains, and the function that justifies them
%
%      W04_0_setup
%      W04_H_adaptive_and_stability
%
%  The ALOS adaptation law was not guessed. It is the one choice that makes
%  the derivative of a Lyapunov function negative, and this section computes
%  that function from the simulation and watches it fall.
%  Produces img/W04_result_stability.png

clear V KK GG i o y k f U bt Vly RESk RESg COL leg1
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_guidance.slx')), W04_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W04_vars;
V.V_c    = 0.3;
V.beta_c = deg2rad(90);

%% ---- the ILOS gain -----------------------------------------------------
KK = [0.02 0.05 0.1 0.3 1.0];
RESk = zeros(numel(KK), 3);
fprintf('\n  W04 section H — the two adaptive gains, in a %.2f m/s current\n', V.V_c);
fprintf('\n  1) ILOS: kappa, with Ki = kappa / Delta\n\n');
fprintf('    %8s %10s %16s %16s %16s\n', 'kappa', 'Ki', 'settled |y_e|', 'peak |y_e|', 'settling [s]');
fprintf('    %s\n', repmat('-', 1, 72));
for i = 1:numel(KK)
    y = W04_read(run_sim('W04_guidance', V, 'kappa', KK(i)));
    k = y.t >= 0.8*y.t(end);
    leg1 = round(y.wp(:,3)) == 1;
    ts = settle_time(y.t(leg1), y.y_e(leg1,3), 0.5);
    RESk(i,:) = [mean(abs(y.y_e(k,3))), max(abs(y.y_e(leg1,3))), ts];
    fprintf('    %8.2f %10.4f %16.4f %16.4f %16.1f\n', ...
            KK(i), KK(i)/V.Delta, RESk(i,1), RESk(i,2), RESk(i,3));
end

%% ---- the ALOS gain -----------------------------------------------------
GG = [0.0005 0.001 0.002 0.005 0.02];
RESg = zeros(numel(GG), 4);
fprintf('\n  2) ALOS: gamma\n\n');
fprintf('    %10s %16s %16s %16s %16s\n', ...
        'gamma', 'settled |y_e|', 'b_hat [deg]', 'true crab [deg]', 'settling [s]');
fprintf('    %s\n', repmat('-', 1, 82));
YG = cell(size(GG));
for i = 1:numel(GG)
    y = W04_read(run_sim('W04_guidance', V, 'gamma', GG(i)));
    YG{i} = y;
    k = y.t >= 0.8*y.t(end);
    leg1 = round(y.wp(:,4)) == 1;
    ts = settle_time(y.t(leg1), y.y_e(leg1,4), 0.5);
    RESg(i,:) = [mean(abs(y.y_e(k,4))), rad2deg(mean(y.aux(k,4))), mean(y.beta(k,4)), ts];
    fprintf('    %10.4f %16.4f %16.2f %16.2f %16.1f\n', GG(i), RESg(i,:));
end

[~, ik] = min(RESk(:,1));
[~, ig] = min(RESg(:,1));
fprintf(['\n    BOTH GAINS HAVE A MIDDLE, and the tables locate it.\n' ...
         '\n      kappa = %g is best here, at %.4f m. Below it the integral\n' ...
         '      state has not finished moving by the end of the run; above it\n' ...
         '      the loop starts to ring and the error grows again.\n' ...
         '\n      gamma = %g is best here, at %.4f m, and its estimate lands\n' ...
         '      within %.2f deg of the true crab angle. At gamma = %g the\n' ...
         '      estimate is still %.1f deg short after 500 s; at gamma = %g it\n' ...
         '      chases the corners instead of the current.\n' ...
         '\n    Those two values are the defaults of this week, chosen from\n' ...
         '    these tables and not from a rule of thumb.\n'], ...
         KK(ik), RESk(ik,1), GG(ig), RESg(ig,1), abs(RESg(ig,2)-RESg(ig,3)), ...
         GG(1), abs(RESg(1,2)-RESg(1,3)), GG(end));

%% ---- the Lyapunov function, computed from the simulation --------------
%  V = 1/2 y_e^2 + U/(2 gamma) * (beta - b_hat)^2
%
%  The adaptation law was CHOSEN to make dV/dt negative; §4-9 does that
%  algebra. Here the function is evaluated on the run and plotted. It is not
%  a proof - a proof is in the reference - but a V that rose would say the
%  derivation had gone wrong somewhere, and it is the cheapest check there is.
y  = W04_read(run_sim('W04_guidance', V));
leg1 = find(round(y.wp(:,4)) == 1);
leg1 = leg1(y.t(leg1) > 5);                 % after the initial transient
U    = hypot(y.trkU(leg1,4), y.trkV(leg1,4));
bt   = deg2rad(y.beta(leg1,4)) - y.aux(leg1,4);       % beta tilde
Vly  = 0.5*y.y_e(leg1,4).^2 + U./(2*V.gamma) .* bt.^2;

fprintf('\n  3) the Lyapunov function on leg 1\n\n');
fprintf('    V at the start of the leg  %.4f\n', Vly(1));
fprintf('    V at its peak              %.4f  at t = %.1f s\n', max(Vly), y.t(leg1(find(Vly==max(Vly),1))));
fprintf('    V at the end of the leg    %.4f\n', Vly(end));
fprintf('    fall from the peak         %.1f x\n', max(Vly)/Vly(end));
fprintf('    samples with dV <= 0       %.1f %%\n', 100*mean(diff(Vly) <= 1e-9));

fprintf(['\n    V FALLS BY A FACTOR OF %.0f FROM ITS PEAK, AND IT IS NOT MONOTONE.\n' ...
         '\n    Both halves of that sentence matter. The fall is the result the\n' ...
         '    derivation of 4-9 predicts. The %.0f per cent of samples where V\n' ...
         '    rises are not a contradiction of it, because the derivation\n' ...
         '    assumes the heading follows psi_d EXACTLY. It does not: there is\n' ...
         '    a Week 3 autopilot in between, with its own settling time, and\n' ...
         '    while the heading lags the guidance the cross-track error can\n' ...
         '    grow even though the estimate is improving.\n' ...
         '\n    This is the honest reading of a Lyapunov argument applied to a\n' ...
         '    cascade: it governs the outer loop on the assumption that the\n' ...
         '    inner one is infinitely fast, and the inner one never is. The\n' ...
         '    reference proves USGES for the kinematic system; what is checked\n' ...
         '    here is that the vessel does not contradict it.\n'], ...
         max(Vly)/Vly(end), 100*mean(diff(Vly) > 1e-9));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 H  the adaptation, and the function that justifies it', 1000, 440);
COL = lines(numel(GG));

%  WITHDRAWN 2026-09-08, at the lecturer's request: the kappa sweep panel
%  that used to be the left third of this figure.
%
%  Three panels asked the reader to hold three unrelated sweeps at once, and
%  the section's point is only the last of them: the adaptation converges on
%  a current nothing told it about, and the Lyapunov function that justifies
%  it does NOT fall monotonically on a real vessel. The kappa numbers that
%  fix the course's choice of 0.3 are in the TABLE this script prints above.
%  See gnc-lecture-vault/references/standing-orders.md §9-8.

subplot(1,2,1); hold on;
for i = 1:numel(GG)
    plot(YG{i}.t, rad2deg(YG{i}.aux(:,4)), 'Color', COL(i,:), ...
         'DisplayName', sprintf('\\gamma = %g', GG(i)));
end
plot(y.t, y.beta(:,4), 'k--', 'LineWidth',1.2, 'DisplayName','true crab angle');
xlabel('time [s]'); ylabel('$\hat\beta$  [deg]', 'Interpreter','latex');
legend('Location','southeast');
title({'ALOS: the estimate, five gains', 'the dashed line is what it is estimating'});

subplot(1,2,2); hold on;
[Vpk, ipk] = max(Vly);
plot(y.t(leg1), Vly, 'Color',[0.49 0.18 0.56], 'LineWidth',1.6);
plot(y.t(leg1(ipk)), Vpk, 'o', 'Color',[0.49 0.18 0.56], 'MarkerFaceColor','w');
xlabel('time [s]');
ylabel('$V = \frac{1}{2}y_e^2 + \frac{U}{2\gamma}\tilde\beta^2$', 'Interpreter','latex');
grid on;
%  Say what the curve does, not what would be convenient. It RISES first,
%  while the autopilot is still turning the vessel onto the guidance command,
%  and only then falls. The derivation assumes that lag is zero.
title({'the Lyapunov function, on leg 1', ...
       sprintf('rises to %.1f while the heading catches up, then falls %.0f x', ...
               Vpk, Vpk/Vly(end))});

sgtitle('W04 H — the adaptation law is the choice that makes V decrease', ...
        'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_stability.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_stability.png\n\n');


% =========================================================================
function ts = settle_time(t, ye, band)
%SETTLE_TIME  When |ye| last left a band, measured from the start of the leg.
j = find(abs(ye) > band, 1, 'last');
if isempty(j) || j >= numel(ye), ts = NaN; else, ts = t(j+1) - t(1); end
end
