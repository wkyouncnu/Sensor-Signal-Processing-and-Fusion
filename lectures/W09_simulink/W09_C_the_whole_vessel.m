%% W09 · 실험 9-2 — 여덟 주차가 한 번에 / Experiment 9-2 — the eight weeks, in one run
%
%  이 절이 묻는 것 / the question
%      2~8주차를 한 배에 얹으면 임무가 도는가? 그리고 한 번의 실행에서
%      어느 주차가 어느 구간을 책임지는지 읽을 수 있는가?
%      Put Weeks 2 to 8 on one vessel: does the mission run, and can one run be
%      read to say which week is in charge of which stretch?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W09_C_full 을 강의 기본값으로 한 번 돌린다.
%      ② 다리마다 · 유지마다 수치를 찍는다.
%      ③ 항적과 네 시간 이력을 그린다. 모드가 바뀌는 자리를 세로선으로 표시한다.
%      ① Runs W09_C_full once, with the lecture defaults.
%      ② Prints the numbers of each leg and each hold.
%      ③ Plots the track and four time histories, with the mode changes marked.
%
%  출력에서 볼 것 / what to look for in the output
%      - 임무가 277.7 s 에 끝난다. 세 다리, 세 번의 유지, 한 번의 중단도 없이.
%      - 이동 중 속도는 0.999 m/s — 3주차의 적분이 조류에 맞서 세운 값이다.
%      - 다리 끝 횡방향 오차 0.14 m — 5주차의 ILOS 가 크랩각을 메운 결과다.
%      - 유지 오차 0.75 m — 8주차의 뱃머리 규칙이 조류를 맞바라본 결과다.
%      - The mission ends at 277.7 s: three legs, three holds, no intervention.
%      - The transit speed is 0.999 m/s, held against the current by Week 3.
%      - The cross-track at the end of a leg is 0.14 m, the crab angle paid by Week 5.
%      - The hold is 0.75 m, the bow turned into the flow by Week 8.
%
%  만드는 것 / produces: img/W09_result_mission.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 한 번 돌린다 / one run
R = W09_read('W09_C_full');   M = W09_metrics(R);   V = R.V;
fprintf('\n  W09 Experiment 9-2  the reference mission\n');
fprintf('    leg   transit [s]   speed [m/s]   cross-track at the end [m]   hold [m]   settled [s]\n');
for k = 1:3
    a = (R.wp == k) & (R.mode == 1);  b = (R.wp == k) & (R.mode == 2);
    t = R.t(a);  tb = R.t(b);
    fprintf('     %d       %6.1f        %6.3f            %8.2f            %6.3f       %5.1f\n', k, ...
        t(end)-t(1), mean(R.u(a & R.t >= t(1)+15)), mean(abs(R.y_e(a & R.t >= t(end)-10))), ...
        mean(R.e(b & R.t >= tb(end)-20)), tb(find(R.e(b) > 1, 1, 'last'))-tb(1));
end
fprintf('    mission complete at %.1f s;  |X| at its limit %.1f %% of the run,  |N| %.1f %%\n', ...
    M.T, 100*mean(abs(R.X) > V.X_max-1e-6), 100*mean(abs(R.Nm) > V.N_max-1e-6));

%% 2) 항적과 시간 이력 / the track and the time histories
f = lab_fig('W09 Exp 9-2  the reference mission', 1100, 640);
subplot(1,2,1); hold on; grid on; axis equal;
plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(R.E, R.N, 'Color', [0 0.45 0.74], 'LineWidth', 1.2);
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
track_ships({[R.N R.E R.psi]}, [0 0.45 0.74], 'Marks', 14);
quiver(-14, -14, 9, 0, 0, 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MaxHeadSize', 0.6);
text(-13, -18, 'current');  xlabel('east [m]');  ylabel('north [m]');
title('three legs, three holds');
sw = R.t([false; diff(R.mode) ~= 0]).';
pw = atan2d(sind(R.psi), cosd(R.psi));   % 그림에는 -180..180 으로 / wrapped for the plot
P = {R.u, 'u [m/s]'; R.y_e, 'y_e [m]'; pw, '\psi [deg]'; R.X, 'X [N]'; R.Nm, 'N [N m]'};
for i = 1:5
    subplot(5,2,2*i); hold on; grid on;
    plot(R.t, P{i,1}, 'LineWidth', 1.0);
    if i == 3                                    % 명령과 실제 / the command and the bow
        plot(R.t, atan2d(sind(R.psi_d), cosd(R.psi_d)), '.', 'Color', [.6 .6 .6], 'MarkerSize', 2);
        yline(-90, 'k--');                       % 조류를 맞바라보는 방향 / facing the flow
    end
    if i == 4, yline(V.X_max, 'r--'); end
    if i == 5, yline([-1 1]*V.N_max, 'r--'); end
    for s = sw, xline(s, 'Color', [.6 .6 .6]); end
    ylabel(P{i,2});  if i == 5, xlabel('time [s]'); end
    if i == 1, title('the grey lines are the changes of mode'); end
end
exportgraphics(f, fullfile(here, 'img', 'W09_result_mission.png'), 'Resolution', 150);
