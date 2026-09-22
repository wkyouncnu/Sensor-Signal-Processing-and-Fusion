%% W05 · 절 D — 앞보기 거리 Delta 를 튜닝한다 / Section D — tuning the look-ahead distance Delta
%
%  이 절이 묻는 것 / the question
%      LOS 는 횡방향 오차에 대한 P 제어기다 (Kp = 1/Delta). Delta 를 줄이면 (게인을 올리면)
%      2~4주차의 P 처럼 빨라지고 울리는가?
%      LOS is a P controller on the cross-track error (Kp = 1/Delta). Does a
%      smaller Delta (a larger gain) make it faster and oscillatory, like P in
%      Weeks 2 to 4?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 북쪽 곧은 경로, 동쪽 20 m 에서 출발. W05_D_LOS 를 Delta = 0.5, 1, 2.5, 5, 10, 20, 40 m 로 돌린다.
%      ② 경로 1 m 안에 드는 시간, 경로를 넘어간 거리(오버슛), 0 을 가로지른 횟수를 찍는다.
%      ③ 횡방향 오차를 시간에 대해 그린다.
%      ① Straight path north, start 20 m east. Runs W05_D_LOS with Delta = 0.5, 1,
%         2.5, 5, 10, 20 and 40 m.
%      ② Prints the time to within 1 m of the path, how far past the path it
%         went (overshoot), and how many times the error crossed zero.
%      ③ Plots the cross-track error against time.
%
%  출력에서 볼 것 / what to look for in the output
%      - Delta 가 크면 느리다: 40 m 는 118 s, 5 m 는 32 s.
%      - Delta 가 작으면 오버슛이 커지고 흔들린다: 1 m 는 0.70 m, 0.5 m 는 1.35 m 에 7 번 가로지른다.
%      - 선체 길이(2 m)의 2~3 배인 Delta = 5 m 가 빠르면서 조용하다 -> 선택.
%      - A large Delta is slow: 118 s at 40 m, 32 s at 5 m.
%      - A small Delta overshoots and swings: 0.70 m at 1 m; 1.35 m and 7 crossings at 0.5 m.
%      - Delta = 5 m, two to three hull lengths, is fast and quiet -> the choice.
%
%  만드는 것 / produces: img/W05_result_lookahead.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 300};   % 곧은 경로 / a straight leg

%% 1) Delta 일곱 가지 / seven look-ahead distances
fprintf('\n  W05 D  LOS, the look-ahead distance  (start 20 m east of the path)\n');
fprintf('    Delta [m]   P gain 1/Delta   within 1 m after [s]   overshoot [m]   zero crossings\n');
f = lab_fig('W05 D  look-ahead', 1000, 480);  hold on; grid on;
for D = [0.5 1 2.5 5 10 20 40]
    R = W05_read('W05_D_LOS', L{:}, 'Delta', D);

    %  경로 1 m 안에 처음 든 시각 / the first time within 1 m of the path
    k = find(abs(R.y_e) < 1, 1);
    %  경로를 넘어간 거리 = 반대쪽(음수)으로 간 최대값 / overshoot = largest excursion to the other side
    over = max(0, -min(R.y_e));
    %  그 뒤 부호가 바뀐 횟수 / sign changes after that
    zc = sum(abs(diff(sign(R.y_e(R.t > R.t(k))))) > 0);
    fprintf('    %-9g   %14.3f   %20.1f   %13.2f   %14d\n', D, 1/D, R.t(k), over, zc);
    plot(R.t, R.y_e, 'LineWidth', 2, 'DisplayName', sprintf('\\Delta = %g m', D));
end

%% 2) 그림을 다듬어 저장한다 / label the figure and save it
yline(0, 'k--', 'HandleVisibility','off'); xlim([0 150]); ylim([-2 21]);
xlabel('time [s]'); ylabel('cross-track error y_e [m]'); legend('Location','northeast');
title('LOS as a P controller: a smaller \Delta is faster and overshoots more');
exportgraphics(f, fullfile(here, 'img', 'W05_result_lookahead.png'), 'Resolution', 150);
