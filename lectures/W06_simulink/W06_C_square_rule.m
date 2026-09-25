%% W06 · 실험 6-2 — 두 요구를 두 추진기로 / Experiment 6-2 — two demands on two propellers
%
%  이 절이 묻는 것 / the question
%      3~5주차가 쓰던 배분은 어디에서 온 것인가? 언제 정확한가?
%      Where does the allocation of Weeks 3 to 5 come from, and when is it exact?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W06_C_square 를 한 번 돌린다. 요구는 시간표대로 X 만, 그 다음 X 와 N.
%      ② 구간마다 요구한 힘과 전달된 힘, 그리고 추진기 추력 둘을 표로 찍는다.
%      ③ 요구(점선)와 전달(실선)을 겹쳐 그린다.
%      ① Runs W06_C_square once: surge alone, then surge with a yaw moment.
%      ② Prints the demanded and delivered force in each leg, with the two thrusts.
%      ③ Plots the demand (dashed) and what was delivered (solid), one on the other.
%
%  출력에서 볼 것 / what to look for in the output
%      - 두 줄이 겹친다. 요구가 한계 안에 있는 한 정사각 배분은 **정확**하다.
%      - T1 + T2 = X 이고 y_pont (T1 - T2) = N 이다. 두 식, 두 미지수.
%      - The two lines lie on one another: while the demand fits, the square rule is exact.
%      - T1 + T2 = X and y_pont (T1 - T2) = N: two equations, two unknowns.
%
%  만드는 것 / produces: img/W06_result_square.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 한 번 돌리고 구간마다 읽는다 / one run, read leg by leg
R = W06_read('W06_C_square');
at = @(f, t) interp1(R.t, R.(f), t);
fprintf('\n  W06 Experiment 6-2  the square rule  (y_pont = %.3f m)\n', R.V.y_pont);
fprintf('    t [s]   demanded X    N        delivered X    N        T1      T2   T1+T2\n');
for t = [10 20 30]
    fprintf('    %5.0f   %10.2f %6.2f   %11.2f %6.2f  %7.2f %7.2f %7.2f\n', t, ...
            at('Xd',t), at('Nd',t), at('Xa',t), at('Na',t), at('T1',t), at('T2',t), at('T1',t)+at('T2',t));
end

%% 2) 요구와 전달을 겹쳐 그린다 / the demand and the delivery, one on the other
f = lab_fig('W06 Exp 6-2  the square rule', 1000, 620);
subplot(2,1,1); hold on; grid on;
plot(R.t, R.Xd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'X demanded');
plot(R.t, R.Xa, 'LineWidth', 2, 'DisplayName', 'X delivered');
plot(R.t, R.Nd, 'k:',  'LineWidth', 1.6, 'DisplayName', 'N demanded');
plot(R.t, R.Na, 'LineWidth', 2, 'DisplayName', 'N delivered');
ylabel('force [N], moment [N m]'); legend('Location','northwest');
title('while the demand fits, the delivered force is the demanded force');
subplot(2,1,2); hold on; grid on;
plot(R.t, R.T1, 'LineWidth', 2, 'DisplayName', 'T_1  (port)');
plot(R.t, R.T2, 'LineWidth', 2, 'DisplayName', 'T_2  (starboard)');
yline(R.V.T_max, 'r:', 'HandleVisibility','off');  yline(R.V.T_min, 'r:', 'HandleVisibility','off');
ylabel('thrust [N]'); xlabel('time [s]'); legend('Location','northwest');
title('the two thrusts: their sum is X, their difference times y_{pont} is N');
exportgraphics(f, fullfile(here, 'img', 'W06_result_square.png'), 'Resolution', 150);
