%% W08 · 실험 8-3 — 뱃머리를 힘 쪽으로 / Experiment 8-3 — pointing the bow along the force
%
%  이 절이 묻는 것 / the question
%      선수각을 놓아 주면 자리를 지킬 수 있는가? 그러면 뱃머리는 어디를 향하는가?
%      If the heading is set free, can the station be held — and where does the bow end up?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W08_D_weathervane 을 돌린다. 같은 조류, 같은 게인, 선수각만 자유다.
%      ② 마지막 50 s 의 오차·선수각·전진력을 찍고, 항력에서 나온 예측과 비교한다.
%      ③ 항적(선체 그림 포함)과 선수각·힘의 시간 이력을 그린다.
%      ① Runs W08_D_weathervane: the same current and gains, the heading free.
%      ② Prints the error, the heading and the force over the last 50 s, against
%         the force the drag law predicts.
%      ③ Plots the track with hulls, and the heading and force against time.
%
%  출력에서 볼 것 / what to look for in the output
%      - 오차가 0.19 m 에 머문다. 조류는 그대로인데 자리를 지킨다.
%      - 뱃머리가 -90.6 도, 곧 **조류를 맞바라보는 방향**으로 돌아가 멈춘다.
%      - 전진력 23.0 N 은 0.3 m/s 의 항력 0.3/0.01289 = 23.3 N 과 같다.
%      - The error settles at 0.19 m: the same current, and the station is held.
%      - The bow settles at -90.6 deg, which is into the oncoming flow.
%      - The 23.0 N of surge force is the drag at 0.3 m/s, 0.3/0.01289 = 23.3 N.
%
%  만드는 것 / produces: img/W08_result_vane.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 선수각을 놓아 준다 / the heading set free
R = W08_read('W08_D_weathervane');
j = R.t > 150;
fprintf('\n  W08 Experiment 8-3  the bow set free, in the same current\n');
fprintf('    over the last 50 s:  |e| mean %.3f m, max %.3f m\n', mean(R.e(j)), max(R.e(j)));
fprintf('    the bow settles at %.1f deg;  the current runs towards %.0f deg\n', ...
        mean(R.psi(j)), R.V.beta_c*180/pi);
fprintf('    surge force %.1f N;  the drag at %.2f m/s is %.1f N\n', ...
        mean(R.X(j)), R.V.V_c, R.V.V_c/0.012894);

%% 2) 항적과 시간 이력 / the track and the time histories
f = lab_fig('W08 Exp 8-3  weathervaning', 1000, 460);
subplot(1,2,1); hold on; grid on; axis equal;
plot(R.E, R.N, 'LineWidth', 1.5);
track_ships({[R.N R.E R.psi]}, [0 0.45 0.74], 'Marks', 6);   % 선체와 선수 방향 / hulls and heading
plot(R.E_d(1), R.N_d(1), 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
quiver(1.2, -2.2, 1.2, 0, 0, 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
text(1.4, -2.6, 'current'); xlabel('east [m]'); ylabel('north [m]');
title('the vessel stays; the bow turns into the flow');
subplot(1,2,2); hold on; grid on;
yyaxis left;  plot(R.t, R.psi, 'LineWidth', 2); ylabel('\psi [deg]');
yyaxis right; plot(R.t, R.X, 'LineWidth', 2);  ylabel('X [N]');
xlabel('time [s]'); title('the heading it chose, and the force it holds');
exportgraphics(f, fullfile(here, 'img', 'W08_result_vane.png'), 'Resolution', 150);
