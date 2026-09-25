%% W08 · 실험 8-2 — 지킬 수 없는 방향 / Experiment 8-2 — the direction it cannot hold
%
%  이 절이 묻는 것 / the question
%      추진기 둘로 자리를 지킬 수 있는가? 조류가 옆에서 밀면 어떻게 되는가?
%      Can two propellers hold a station, when the current pushes from the side?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W08_C_fixed 를 돌린다. 선수각은 북쪽에 고정되고, 조류는 동쪽으로 흐른다.
%      ② 시각마다 위치·오차·전진력을 찍는다.
%      ③ 항적과 오차를 그린다.
%      ① Runs W08_C_fixed: the heading is fixed north, the current runs east.
%      ② Prints the position, the error and the surge force at four times.
%      ③ Plots the track and the error.
%
%  출력에서 볼 것 / what to look for in the output
%      - 배는 동쪽으로 계속 밀려난다. 200 s 에 56.6 m.
%      - **전진력이 0 N 이다.** 제어기가 고장난 것이 아니다 — 필요한 힘이 뱃머리와
%        직각이어서, 이 선체가 낼 수 있는 힘 가운데 그 방향 성분이 없는 것이다.
%      - The vessel is carried east without limit: 56.6 m in 200 s.
%      - **The surge force is 0 N.** Nothing is broken: the force that is needed
%        lies across the bow, and this hull can make no force in that direction.
%
%  만드는 것 / produces: img/W08_result_fixed.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 고정된 선수각으로 자리를 지키려 한다 / holding station on a fixed heading
R = W08_read('W08_C_fixed');
fprintf('\n  W08 Experiment 8-2  a fixed heading in a %.2f m/s current towards %.0f deg\n', ...
        R.V.V_c, R.V.beta_c*180/pi);
fprintf('    t [s]      N [m]     E [m]    |e| [m]   psi [deg]    X [N]\n');
for t = [0 50 100 200]
    i = find(R.t >= t, 1);
    fprintf('    %5.0f %10.2f %9.2f %10.2f %11.1f %8.1f\n', t, R.N(i), R.E(i), R.e(i), R.psi(i), R.X(i));
end

%% 2) 항적과 오차 / the track and the error
f = lab_fig('W08 Exp 8-2  the direction it cannot hold', 1000, 460);
subplot(1,2,1); hold on; grid on; axis equal;
plot(R.E, R.N, 'LineWidth', 2); plot(R.E_d(1), R.N_d(1), 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
quiver(10, -8, 12, 0, 0, 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
text(12, -12, 'current'); xlabel('east [m]'); ylabel('north [m]');
title('the station, and where the vessel went');
subplot(1,2,2); hold on; grid on;
plot(R.t, R.e, 'LineWidth', 2, 'DisplayName', '|e| [m]');
plot(R.t, R.X, 'LineWidth', 2, 'DisplayName', 'X [N]');
xlabel('time [s]'); legend('Location','northwest');
title('the error grows and the force stays at zero');
exportgraphics(f, fullfile(here, 'img', 'W08_result_fixed.png'), 'Resolution', 150);
