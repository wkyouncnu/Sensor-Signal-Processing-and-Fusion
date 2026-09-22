%% W05 · 절 E — 언제 다음 다리로 넘어가는가 / Section E — when to move to the next leg
%
%  이 절이 묻는 것 / the question
%      모퉁이에서 다음 다리로 너무 늦게 넘어가면 어떻게 되고, 너무 일찍 넘어가면 어떻게 되는가?
%      What happens at a corner when the switch to the next leg comes too late,
%      and when it comes too early?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 다섯 웨이포인트 임무 (다리 넷, 각 60 m) 를 W05_E_switching (LOS, Delta = 5 m) 로 돈다.
%      ② 전환 거리 R_switch = 1, 3, 5, 10, 20 m 로 한 번씩.
%      ③ 모퉁이마다, 넘어간 뒤 25 s 동안 새 다리에서 가장 멀리 벗어난 거리를 찍고,
%         마지막 웨이포인트 3 m 안에 닿은 시각을 찍는다. 항적을 그린다.
%      ① Runs the five-waypoint mission (four 60 m legs) with W05_E_switching
%         (LOS, Delta = 5 m).
%      ② Once each for R_switch = 1, 3, 5, 10 and 20 m.
%      ③ For each corner, prints the largest distance from the new leg in the
%         25 s after the switch, and the time the last waypoint is reached
%         within 3 m. Draws the tracks.
%
%  출력에서 볼 것 / what to look for in the output
%      - R 이 크면 모퉁이를 깎는다: 넘어가는 순간 이미 새 다리에서 R 만큼 떨어져 있다 (20 m 면 20 m).
%      - R 이 작으면 모퉁이를 지나쳐 바깥으로 나간다 (1 m 면 135 도 모퉁이에서 3.70 m).
%      - R = 3 m 에서 가장 나쁜 모퉁이가 가장 작다 (2.98 m) -> 선택.
%      - A large R cuts the corner: at the switch the vessel is already R from
%        the new leg (20 m at R = 20 m).
%      - A small R carries the vessel past the corner (3.70 m at the 135 deg
%        corner for R = 1 m).
%      - R = 3 m has the smallest worst corner (2.98 m) -> the choice.
%
%  만드는 것 / produces: img/W05_result_switching.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 전환 거리 다섯 가지 / five switching distances
fprintf('\n  W05 E  waypoint switching on the mission  (LOS, Delta = 5 m, no current)\n');
fprintf('    R_switch [m]   largest distance from the new leg at corners 1, 2, 3 [m]   last waypoint at [s]\n');
f = lab_fig('W05 E  switching', 1000, 560);
RS = [1 3 5 10 20];  COL = lines(numel(RS));
for i = 1:numel(RS)
    R = W05_read('W05_E_switching', 'R_switch', RS(i));

    %  다리 번호 wp 가 바뀐 표본 = 모퉁이에서 넘어간 순간 / where the leg number changes = a switch
    sw = find(diff(R.wp) > 0);
    c = zeros(1, numel(sw));
    for j = 1:numel(sw)
        kk = R.t > R.t(sw(j)) & R.t < R.t(sw(j)) + 25;     % 넘어간 뒤 25 s / 25 s after the switch
        c(j) = max(abs(R.y_e(kk)));
    end
    %  마지막 웨이포인트 (60, 120) 의 3 m 안에 든 시각 / the time within 3 m of the last waypoint
    k = find(hypot(R.N - 60, R.E - 120) < 3, 1);
    fprintf('    %-12g   %12.2f %6.2f %6.2f                             %8.1f\n', RS(i), c, R.t(k));

    %  항적 / the track
    plot(R.E, R.N, 'Color', COL(i,:), 'LineWidth', 1.8, 'DisplayName', sprintf('R = %g m', RS(i)));
    hold on;
    if RS(i) == 3, R3 = R; end                         % 고른 값의 항적은 선체도 그린다 / hulls on the chosen one
end

%% 2) 경로와 웨이포인트를 겹쳐 그리고 저장한다 / overlay the path and waypoints, and save
V = W05_vars();
plot(V.WP_E, V.WP_N, 'k--o', 'MarkerFaceColor', 'k', 'DisplayName', 'path');
track_ships({[R3.N R3.E R3.psi]}, COL(2,:), 'Marks', 8);
axis equal; grid on; xlim([-10 130]); ylim([-10 70]);
xlabel('east [m]'); ylabel('north [m]'); legend('Location','southeast');
title('a large R cuts the corners; a small R carries the vessel past them');
exportgraphics(f, fullfile(here, 'img', 'W05_result_switching.png'), 'Resolution', 150);
