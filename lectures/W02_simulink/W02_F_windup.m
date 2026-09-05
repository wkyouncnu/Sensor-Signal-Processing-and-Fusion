%% W02 · section F — windup, and two ways of surviving it
%
%      W02_0_setup
%      W02_F_windup
%
%  Asks the vessel for 3.5 m/s, which it cannot reach: full ahead is 3.0864.
%  Holds the impossible demand for 35 s, then drops to a reachable 1.5 m/s.
%  Produces img/W02_result_windup.png

clear RW AW i rec peakI peakX
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W02_surge_control.slx')), W02_1_build_surge_control; end

V = W02_vars;
c = W02_cols;

%% ---- the same demand, three anti-windup settings -----------------------
AW    = {'none','clamping','back-calculation'};
RW    = cell(1,3);
rec   = zeros(1,3);
peakI = zeros(1,3);
peakX = zeros(1,3);

fprintf('\n  W02 section F — windup: u_d = 3.5 m/s (unreachable) for 35 s, then 1.5\n\n');
fprintf('    %-18s %14s %16s %18s\n', ...
        'anti-windup', 'peak I [N]', 'peak X_cmd [N]', 'recovery [s]');
fprintf('    %s\n', repmat('-', 1, 72));

for i = 1:3
    RW{i}    = run_sim('W02_surge_control', V, ...
                       'Kp', V.Kp_d, 'Ki', V.Ki_d, 'Kd', 0, 'aw_mode', i-1, ...
                       'u_d1', 3.5, 'u_d2', 1.5, 't_up', 5, 't_dn', 40, 'T_final', 90);
    peakI(i) = max(RW{i}.y(:, c.I));
    peakX(i) = max(RW{i}.y(:, c.X_cmd));
    rec(i)   = recovery_time(RW{i}.t, RW{i}.y(:, c.u), 1.5, 40);
    fprintf('    %-18s %14.1f %16.1f %18.3f\n', AW{i}, peakI(i), peakX(i), rec(i));
end

fprintf(['\n    Windup is an ACTUATOR problem, not an integrator problem. While\n' ...
         '    the demand is impossible the error never changes sign, so the\n' ...
         '    integrator keeps climbing to %.0f N — a force the propellers can\n' ...
         '    never deliver, since they saturate at %.0f N. When the setpoint\n' ...
         '    finally becomes reachable the loop must first UNWIND that stored\n' ...
         '    demand, and the vessel overshoots for %.1f s doing it.\n'], ...
         peakI(1), V.X_hi, rec(1));

fprintf(['\n    Both remedies cut the recovery from %.2f s to about %.2f s, and\n' ...
         '    they are NOT the same scheme:\n' ...
         '      clamping          stops the integrator where it happens to be\n' ...
         '      back-calculation  steers it to the value that makes the demand\n' ...
         '                        equal the limit\n' ...
         '    They settle at different integrator values, which is why raising\n' ...
         '    the back-calculation gain never turns one into the other.\n'], ...
         rec(1), mean(rec(2:3)));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W02 F  windup', 1150, 760);

subplot(2,2,1); hold on;
yline(3.5, 'k:', 'HandleVisibility','off');
yline(1.5, 'k:', 'HandleVisibility','off');
for i = 1:3, plot(RW{i}.t, RW{i}.y(:, c.u), 'DisplayName', AW{i}); end
xlabel('time [s]'); ylabel('u  [m/s]'); legend('Location','east');
title({'the speed', 'all three ask for 3.5 and none of them gets it'});

subplot(2,2,2); hold on;
for i = 1:3, plot(RW{i}.t, RW{i}.y(:, c.I), 'DisplayName', AW{i}); end
xlabel('time [s]'); ylabel('integrator state  [N]');
title({'where the trouble is stored', ...
       sprintf('unprotected reaches %.0f N; the limit is %.0f N', peakI(1), V.X_hi)});

subplot(2,2,3); hold on;
yline(V.X_hi, 'k:', 'DisplayName','saturation');
for i = 1:3, plot(RW{i}.t, RW{i}.y(:, c.X_cmd), 'DisplayName', AW{i}); end
xlabel('time [s]'); ylabel('X demanded  [N]'); legend('Location','east');
title({'what the controller asked for', 'far above what the propellers can give'});

subplot(2,2,4); hold on;
for i = 1:3, plot(RW{i}.t, RW{i}.y(:, c.X_sat), 'DisplayName', AW{i}); end
xlabel('time [s]'); ylabel('X delivered  [N]');
title({'what the propellers actually gave', 'identical while saturated — that is the point'});

sgtitle('W02 F — windup is a saturation problem wearing an integrator costume', ...
        'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_windup.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W02_result_windup.png\n\n');
