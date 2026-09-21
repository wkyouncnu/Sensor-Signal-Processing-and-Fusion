%% W04 · 절 E — D 를 더한다 / Section E — add D
%
%  이 절이 묻는 것 / the question
%      3주차에서 속도 루프를 나쁘게 만든 D 가 선수각에서는 어떻게 작용하는가?
%      D made the speed loop of Week 3 worse. What does it do on the heading?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W04_E_PD 를 Kp = 300 으로 두고 Kd = 0, 10, 25, 50, 100, 150, 200 으로 돌린다
%         (10 도 선회).
%      ② 오버슛, 상승시간, 정착시간을 표로 찍고, 네 경우를 그림으로 저장한다.
%      ① Runs W04_E_PD at Kp = 300 with Kd = 0, 10, 25, 50, 100, 150 and 200
%         (a 10 deg turn).
%      ② Prints the overshoot, rise and settling times, and plots four of them.
%
%  출력에서 볼 것 / what to look for in the output
%      - Kd 를 올리면 오버슛이 줄어든다 (12.18 -> 0.39 %): 선수각 오차의 미분은
%        선회율이고, 선회율에 저항하는 것은 감쇠다 (2주차와 같다).
%      - 정착시간은 Kd = 100 에서 가장 짧고 (1.72 s), 더 올리면 다시 느려진다: 감쇠가
%        너무 크면 느리다 (2주차 §2-3, zeta > 1).
%      - Raising Kd lowers the overshoot (12.18 -> 0.39 %): the derivative of a
%        heading error is a turn rate, and resisting it is damping (as in Week 2).
%      - Settling is fastest at Kd = 100 (1.72 s) and slower beyond it: too much
%        damping is slow (Week 2 §2-3, zeta > 1).
%
%  만드는 것 / produces: img/W04_result_D.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W04 E  P + D  (Kp = 300, psi_d = 10 deg)\n');
fprintf('    Kd     overshoot %%   rise [s]   settle [s]\n');
f = lab_fig('W04 E  derivative', 1000, 460);  hold on; grid on;

%% 2) 미분 게인 일곱 개 / seven derivative gains
for Kd = [0 10 25 50 100 150 200]
    %  Kd 만 바꿔 돌린다 (Kp = 300 은 기본값) / only Kd changed (Kp = 300 is the default)
    R = W04_read('W04_E_PD', 'Kd', Kd);
    [Mp, ts, tr] = step_metrics(R.t, R.psi, 10, 5);
    fprintf('    %-5g  %11.2f   %8.2f   %10.2f\n', Kd, max(Mp,0), tr, ts);

    %  그림에는 네 경우만 그린다 / only four of them are drawn
    if any(Kd == [0 25 100 200])
        plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_d = %g', Kd));
    end
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command'); xlim([3 20]);
ylabel('\psi [deg]'); xlabel('time [s]'); legend('Location','southeast');
title('on the heading D damps again: less overshoot, and too much is slow');
exportgraphics(f, fullfile(here, 'img', 'W04_result_D.png'), 'Resolution', 150);
