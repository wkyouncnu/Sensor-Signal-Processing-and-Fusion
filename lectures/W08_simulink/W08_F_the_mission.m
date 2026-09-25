%% W08 · 실험 8-5 — 임무: 이동, 유지, 다시 이동 / Experiment 8-5 — the mission: transit, hold, transit
%
%  이 절이 묻는 것 / the question
%      5주차의 이동과 이번 주의 유지를 한 배에 얹으면 무엇이 새로 생기는가?
%      Put the transit of Week 5 and the hold of this week in one vessel: what is new?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W08_F_mission 을 두 번 돌린다: 모드가 바뀔 때 적분을 넘겨받는 경우와
%         그대로 두는 경우.
%      ② 모드가 바뀐 시각과 자리, 유지 구간마다의 오차를 찍는다.
%      ③ 넘겨받기의 값을 표로 찍고, 항적과 모드를 그린다.
%      ① Runs W08_F_mission twice: handing the integral over at a mode change, and not.
%      ② Prints when and where each mode change happened, and the error of each hold.
%      ③ Prints what the handover is worth, and plots the track and the modes.
%
%  출력에서 볼 것 / what to look for in the output
%      - 모드는 두 규칙으로만 바뀐다: 반경 안에 들면 유지, 시간이 차면 다음 지점.
%      - 유지 구간의 오차는 0.42~0.76 m — §8-3 의 0.19 m 보다 크다. 들어오는 속도를
%        먼저 죽여야 하기 때문이다.
%      - 적분을 그대로 두면 유지의 첫 힘이 120 N (한계) 로 튀고 오차가 25 m 로 벌어진다.
%        이동 중에 쌓인 수십 미터어치 적분이 유지를 시작하자마자 쏟아지는 것이다.
%      - The modes change by two rules only: inside the radius, hold; time up, go on.
%      - The holds run at 0.42 to 0.76 m, worse than §8-3's 0.19 m: the vessel
%        arrives with way on, and has to take it off first.
%      - Keeping the integral through the change makes the first force of the hold
%        saturate at 120 N and the error open to 25 m: tens of metres of transit
%        error, poured into the hold the moment it begins.
%
%  만드는 것 / produces: img/W08_result_mission.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 임무의 시간표 / the timeline of the mission
R = W08_read('W08_F_mission', 'T_final', 400);
MODE = {'transit', 'hold', 'done'};
fprintf('\n  W08 Experiment 8-5  the mission\n');
for i = find(diff(R.mode) ~= 0)' + 1
    fprintf('    t = %6.1f s   %-7s -> %-7s   at (N %6.2f, E %6.2f)\n', R.t(i), ...
            MODE{R.mode(i-1)}, MODE{R.mode(i)}, R.N(i), R.E(i));
end
for k = 1:numel(R.V.WP_N)
    j = R.mode == 2 & R.N_d == R.V.WP_N(k) & R.E_d == R.V.WP_E(k);
    if any(j)
        fprintf('    hold at waypoint %d: |e| mean %.2f m, max %.2f m over %.0f s\n', ...
                k, mean(R.e(j)), max(R.e(j)), sum(j)*R.V.h);
    end
end

%% 2) 모드가 바뀔 때 적분을 어떻게 하는가 / what to do with the integral at a change
fprintf('\n    hand_over   peak |X| in the first 10 s of the second hold   |e| over that hold\n');
for ho = [1 0]
    Q = W08_read('W08_F_mission', 'hand_over', ho, 'T_final', 400);
    i0 = find(Q.mode == 2 & Q.t > 60, 1);
    w = Q.t >= Q.t(i0) & Q.t <= Q.t(i0) + 10;
    j = Q.mode == 2 & Q.t > 60 & Q.t < Q.t(i0) + 40;
    fprintf('    %8d %37.1f N %18.3f m\n', ho, max(abs(Q.X(w))), mean(Q.e(j)));
end

%% 3) 항적과 모드 / the track and the modes
f = lab_fig('W08 Exp 8-5  the mission', 1000, 460);
subplot(1,2,1); hold on; grid on; axis equal;
plot(R.E, R.N, 'LineWidth', 1.6);
plot(R.V.WP_E, R.V.WP_N, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
xlabel('east [m]'); ylabel('north [m]'); title('three waypoints, held for 40 s each');
subplot(1,2,2); hold on; grid on;
yyaxis left;  stairs(R.t, R.mode, 'LineWidth', 2); ylim([0.5 3.5]);
yticks(1:3); yticklabels(MODE); ylabel('mode');
yyaxis right; plot(R.t, R.e, 'LineWidth', 1.6); ylabel('|e| [m]');
xlabel('time [s]'); title('the two rules that move the mission along');
exportgraphics(f, fullfile(here, 'img', 'W08_result_mission.png'), 'Resolution', 150);
