%% W06 · 실험 6-5 — 추력에서 회전수로 / Experiment 6-5 — from thrust to shaft speed
%
%  이 절이 묻는 것 / the question
%      배분기가 낸 것은 추력이다. 추진기에 주는 것은 회전수다. 그 사이는 선형이 아니다.
%      The allocator produces thrusts; the propellers take shaft speeds, and the
%      map between them is not linear.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W06_E_curve 를 use_kneg = 1 과 0 으로 한 번씩 돌린다.
%         시간표에 전진과 **후진** 구간이 모두 있다.
%      ② 구간마다 요구한 X 와 전달된 X 를 나란히 찍는다.
%      ③ 두 실행을 겹쳐 그린다.
%      ① Runs W06_E_curve twice, with use_kneg = 1 and 0; the timetable has an
%         ahead leg and an astern leg.
%      ② Prints the demanded and delivered surge force in each leg.
%      ③ Plots the two runs on one axis.
%
%  출력에서 볼 것 / what to look for in the output
%      - 전진 구간에서는 두 실행이 같다. 앞으로 갈 때는 k_pos 하나뿐이기 때문이다.
%      - 후진 구간에서 틀린 역곡선은 -100 N 요구에 -58.2 N 만 낸다. 비율은 k_neg/k_pos = 0.582.
%      - 순수 요 모멘트 요구(한쪽은 전진, 한쪽은 후진)에서는 더 나쁘다: 20 N m 요구에
%        15.82 N m 만 나오고, **요구하지도 않은 전진력 10.59 N** 이 따라 나온다.
%        한쪽만 모자라므로 두 추력의 균형이 깨지기 때문이다.
%      - Ahead the two runs agree: only k_pos is involved.
%      - Astern the wrong inverse delivers -58.2 N of the -100 N asked for, the ratio k_neg/k_pos.
%      - A pure yaw demand is worse: one propeller runs astern, so only that one
%        falls short, the pair is no longer balanced, and 20 N m becomes 15.82 N m
%        **plus 10.59 N of surge that nobody asked for**.
%
%  만드는 것 / produces: img/W06_result_curve.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 옳은 역곡선과 틀린 역곡선 / the right inverse and the wrong one
R1 = W06_read('W06_E_curve', 'use_kneg', 1);
R0 = W06_read('W06_E_curve', 'use_kneg', 0);
at = @(R, f, t) interp1(R.t, R.(f), t);
fprintf('\n  W06 Experiment 6-5  the inverse of the propeller curve\n');
fprintf('    t [s]   demanded X      N     delivered (k_neg astern)   delivered (k_pos both ways)\n');
for t = [10 20 30 40]
    fprintf('    %5.0f   %10.1f %6.2f   %16.2f %6.2f   %13.2f %6.2f\n', t, ...
            at(R1,'Xd',t), at(R1,'Nd',t), at(R1,'Xa',t), at(R1,'Na',t), at(R0,'Xa',t), at(R0,'Na',t));
end
fprintf('    astern ratio measured %.3f,  k_neg/k_pos = %.3f\n', ...
        at(R0,'Xa',20)/at(R1,'Xa',20), R1.V.k_neg/R1.V.k_pos);

%% 2) 두 실행을 겹쳐 그린다 / the two runs on one axis
f = lab_fig('W06 Exp 6-5  the curve inverted', 1000, 620);
subplot(2,1,1); hold on; grid on;
plot(R1.t, R1.Xd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'X demanded');
plot(R1.t, R1.Xa, 'LineWidth', 2, 'DisplayName', 'delivered, k_{neg} astern');
plot(R0.t, R0.Xa, 'LineWidth', 2, 'DisplayName', 'delivered, k_{pos} both ways');
ylabel('surge force X [N]'); legend('Location','southwest');
title('ahead the two agree; astern the wrong inverse is 42 % short');
subplot(2,1,2); hold on; grid on;
plot(R1.t, R1.Nd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'N demanded');
plot(R1.t, R1.Na, 'LineWidth', 2, 'DisplayName', 'delivered, k_{neg} astern');
plot(R0.t, R0.Na, 'LineWidth', 2, 'DisplayName', 'delivered, k_{pos} both ways');
ylabel('yaw moment N [N m]'); xlabel('time [s]'); legend('Location','southwest');
title('a pure yaw demand: 15.82 of 20 N m, and 10.59 N of surge nobody asked for');
exportgraphics(f, fullfile(here, 'img', 'W06_result_curve.png'), 'Resolution', 150);
