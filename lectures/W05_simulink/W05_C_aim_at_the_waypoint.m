%% W05 · 실험 5-2 — 웨이포인트를 곧장 겨냥하면 / Experiment 5-2 — aiming straight at the waypoint
%
%  이 절이 묻는 것 / the question
%      다음 웨이포인트를 곧장 겨냥하면 경로를 따라가는가?
%      Does aiming straight at the next waypoint follow the path?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 북쪽으로 곧은 경로 (웨이포인트 0, 100, 200, 300 m) 에서, 경로 동쪽 20 m 에서 출발한다.
%      ② W05_C_atan2 (웨이포인트를 겨냥) 와 W05_D_LOS (경로 위 Delta 앞을 겨냥) 를 한 번씩 돌린다.
%      ③ 북쪽으로 50, 100, 150 m 갔을 때의 횡방향 오차를 찍고, 항적을 그린다.
%      ① A straight path north (waypoints at 0, 100, 200, 300 m); start 20 m east of it.
%      ② Runs W05_C_atan2 (aim at the waypoint) and W05_D_LOS (aim Delta ahead on the path).
%      ③ Prints the cross-track error at 50, 100 and 150 m north and draws both tracks.
%
%  출력에서 볼 것 / what to look for in the output
%      - atan2: 50 m 지점에서 아직 10.75 m 벗어나 있다. 웨이포인트(100 m)에 가서야 경로에 닿는다.
%        점을 겨냥하므로 점까지의 거리를 줄일 뿐, 선까지의 거리는 줄이지 않는다.
%      - LOS: 50 m 지점에서 이미 0.04 m 안이다. 선을 겨냥하기 때문이다.
%      - atan2: still 10.75 m off at 50 m north; it reaches the path only at the
%        waypoint (100 m). Aiming at a point closes the distance to the point,
%        not to the line.
%      - LOS: within 0.04 m by 50 m north, because it aims at the line.
%
%  만드는 것 / produces: img/W05_result_atan2.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  북쪽으로 곧은 경로, 300 s / a straight path north, 300 s
L = {'WP_N', [0 100 200 300]', 'WP_E', [0 0 0 0]', 'T_final', 300};

%% 1) 두 법칙으로 돌린다 / run the two laws
A = W05_read('W05_C_atan2', L{:});
B = W05_read('W05_D_LOS', L{:});

%% 2) 북쪽으로 50, 100, 150 m 갔을 때의 횡방향 오차 / cross-track error at 50, 100, 150 m north
%  interp1(북쪽 위치, 오차, 50): 북쪽으로 50 m 에 있을 때의 오차 / the error when 50 m north
fprintf('\n  W05 Experiment 5-2  aiming at the waypoint against line of sight (start 20 m east of the path)\n');
fprintf('    law     y_e at N = 50 m   N = 100 m   N = 150 m\n');
for R = {A, B; 'atan2', 'LOS'}
    r = R{1};
    fprintf('    %-6s  %14.2f  %10.2f  %10.2f\n', R{2}, interp1(r.N, r.y_e, 50), ...
            interp1(r.N, r.y_e, 99), interp1(r.N, r.y_e, 150));
end

%% 3) 그림: 왼쪽 항적 (선체와 선수 방향 포함), 오른쪽 횡방향 오차
%     figure: left the tracks (hull and heading drawn), right the cross-track error
f = lab_fig('W05 C  atan2 against LOS', 1000, 520);
COL = lines(2);                                                     % 두 법칙의 색 / one colour per law
subplot(1,3,1); hold on; axis equal; grid on;
plot([0 0], [0 300], 'k--', 'HandleVisibility','off');              % 경로 / the path
plot(A.E, A.N, 'Color', COL(1,:), 'LineWidth', 2, 'DisplayName', 'atan2');
plot(B.E, B.N, 'Color', COL(2,:), 'LineWidth', 2, 'DisplayName', 'LOS');
track_ships({[A.N A.E A.psi], [B.N B.E B.psi]}, COL, 'Marks', 4);
plot(0, 100, 'ko', 'MarkerFaceColor', 'k', 'HandleVisibility','off');   % 웨이포인트 / waypoint
xlim([-10 30]); ylim([0 120]); xlabel('east [m]'); ylabel('north [m]');
legend('Location','northeast'); title('the tracks');
subplot(1,3,[2 3]); hold on; grid on;
plot(A.N, A.y_e, 'Color', COL(1,:), 'LineWidth', 2);  plot(B.N, B.y_e, 'Color', COL(2,:), 'LineWidth', 2);  yline(0, 'k--');
xlim([0 200]); xlabel('distance north [m]'); ylabel('cross-track error y_e [m]');
legend({'atan2','LOS'}); title('atan2 reaches the path only at the waypoint');
exportgraphics(f, fullfile(here, 'img', 'W05_result_atan2.png'), 'Resolution', 150);
