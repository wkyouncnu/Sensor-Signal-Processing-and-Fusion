%% W02 · 절 F — 와인드업, 그리고 그것을 견디는 두 가지 방법
%  W02 · Section F — windup, and two ways of surviving it
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_F_windup
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 F 이며 §2-6 을 받는다. 절 E 까지의 실험은 모두 작동기가
%      요구를 들어줄 수 있는 범위 안에서 이루어졌다. 이 절은 처음으로 들어줄 수
%      없는 요구를 하고, 그때 적분기에서 무슨 일이 일어나는지를 본다.
%
%      This is section F of Part 2, following §2-6. Every experiment up to
%      section E stayed inside what the actuator could deliver. Here an
%      impossible demand is made for the first time, and what happens inside
%      the integrator is observed.
%
%  실험의 구성 / how the experiment is arranged
%      선박에 3.5 m/s 를 요구한다. 전속 전진이 3.0864 m/s 이므로 도달할 수 없는
%      값이다. 그 불가능한 요구를 35 s 동안 유지한 뒤, 도달 가능한 1.5 m/s 로
%      낮춘다. 요구가 불가능한 동안에는 세 방식이 모두 같아 보이고, 요구가
%      가능해지는 순간에 갈라진다.
%
%      The vessel is asked for 3.5 m/s, which it cannot reach: full ahead is
%      3.0864 m/s. The impossible demand is held for 35 s and then dropped to
%      a reachable 1.5 m/s. While the demand is impossible the three schemes
%      look alike; they separate at the instant it becomes possible.
%
%  만드는 것 / what it produces
%      표 하나와 img/W02_result_windup.png
%      One table and img/W02_result_windup.png

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

fprintf(['\n    WINDUP IS AN ACTUATOR PROBLEM BEFORE IT IS AN INTEGRATOR PROBLEM.\n' ...
         '\n      The integrator is doing exactly what it was built to do. It\n' ...
         '      accumulates error, and while the demand is impossible the error\n' ...
         '      never changes sign, so the accumulation never reverses. The\n' ...
         '      integrator state climbs to %.0f N, a force the propellers cannot\n' ...
         '      deliver, because they saturate at %.0f N.\n' ...
         '\n      Nothing is wrong with that arithmetic. What is wrong is that\n' ...
         '      the controller is never told its demand was refused: it computes\n' ...
         '      as though the actuator had complied. The fault lies at the point\n' ...
         '      where the loop is broken by the saturation, and both remedies\n' ...
         '      below work by reporting that break back to the integrator.\n' ...
         '\n      The cost appears only afterwards. When the setpoint becomes\n' ...
         '      reachable the loop must first unwind the stored demand, and the\n' ...
         '      vessel overshoots for %.1f s while it does so.\n'], ...
         peakI(1), V.X_hi, rec(1));

fprintf(['\n    THE TWO REMEDIES CUT THE RECOVERY FROM %.2f s TO ABOUT %.2f s,\n' ...
         '    AND THEY ARE NOT THE SAME SCHEME.\n' ...
         '\n        clamping           stops the integrator wherever it happens to\n' ...
         '                           be, and holds it there until the error\n' ...
         '                           changes sign\n' ...
         '        back-calculation   feeds the refused part of the demand back\n' ...
         '                           into the integrator, steering it towards\n' ...
         '                           I* = X_sat - Kp e + (Ki/Kaw) e, at which the\n' ...
         '                           demand still stands (Ki/Kaw) e ABOVE the\n' ...
         '                           limit and equals it only as Kaw -> infinity\n' ...
         '\n      The two therefore settle at different integrator values, which\n' ...
         '      is why raising the back-calculation gain never turns one scheme\n' ...
         '      into the other. Section H measures that on a plant simple enough\n' ...
         '      that nothing else can be blamed for the difference.\n'], ...
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
