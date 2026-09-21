%% W04 · 절 C — 플랜트를 밖에서 본다 / Section C — the plant seen from outside
%
%  이 절이 묻는 것 / the question
%      제어기 없이 일정한 요 모멘트를 주면 선수각은 어떻게 되는가? 3주차의 속도처럼
%      어느 값에서 멈추는가?
%      With no controller and a constant yaw moment, what does the heading do?
%      Does it level off like the speed of Week 3?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W04_C_open_loop 에 요 모멘트 5, 10, 20 N m 를 t = 5 s 에 계단으로 준다
%         (배는 X_ff = 60 N 으로 전진 중).
%      ② 경우마다 최종 선회율, N m 당 선회율, 선회율이 63 % 에 닿는 시각, 40 s 의
%         선수각을 표로 찍는다.
%      ③ 선수각(위)과 선회율(아래)을 그려 저장한다.
%      ① Applies 5, 10 and 20 N m of yaw moment at t = 5 s to W04_C_open_loop,
%         with the vessel running ahead on X_ff = 60 N.
%      ② Prints the final turn rate, the rate per N m, the time to 63 % of the
%         rate, and the heading at 40 s.
%      ③ Plots the heading (top) and the turn rate (bottom) and saves them.
%
%  출력에서 볼 것 / what to look for in the output
%      - 선수각은 멈추지 않고 계속 커진다: 선수각은 선회율의 누적(적분)이다.
%        그래서 선수각을 붙잡아 두는 데는 모멘트가 필요 없다 — 절 D 에서 P 만으로
%        오차가 0 이 되는 이유다.
%      - N m 당 선회율이 모멘트가 클수록 작다 (0.610 -> 0.407): 요 감쇠가 선회율과
%        함께 커지는 비선형이다.
%      - The heading never stops growing: it is the running sum (integral) of the
%        turn rate. Holding a heading therefore takes no moment — which is why P
%        alone leaves no error in section D.
%      - The rate per N m falls as the moment grows (0.610 -> 0.407): the yaw
%        damping grows with the turn rate.
%
%  만드는 것 / produces: img/W04_result_open_loop.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W04 C  the plant seen from outside (no controller, X_ff = 60 N ahead)\n');
fprintf('    N [N m]   final turn rate [deg/s]   rate per N m   time to 63 %% of the rate [s]   heading at 40 s [deg]\n');
f = lab_fig('W04 C  open loop', 1000, 620);

%% 2) 모멘트 세 가지로 한 번씩 / one run for each of three moments
for N = [5 10 20]
    %  W04_read: 모델을 돌리고 R.t, R.psi [deg], R.N [N m] 를 돌려준다 (N_open 만 바꿈)
    %  W04_read runs the model and returns R.t, R.psi [deg] and R.N [N m]
    R = W04_read('W04_C_open_loop', 'N_open', N);

    %  선회율 = 선수각의 시간 미분 (기록된 선수각에서 수치로 구한다)
    %  Turn rate = time derivative of the heading, computed from the log
    r = gradient(R.psi, R.t);                          % 요각속도 / turn rate  [deg/s]

    %  계단 뒤만 보고, 선회율이 최종값의 63 % 에 닿는 시각을 찾는다
    %  After the step only; find when the rate reaches 63 % of its final value
    k = R.t >= 5;  t = R.t(k) - 5;  rk = r(k);
    fprintf('    %-7g   %23.2f   %12.3f   %28.2f   %21.1f\n', N, rk(end), rk(end)/N, ...
            t(find(rk >= 0.632*rk(end), 1)), R.psi(end));

    %  위: 선수각, 아래: 선회율 / top: heading, bottom: turn rate
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('N = %g N m', N));
    subplot(2,1,2); hold on; plot(R.t, r, 'LineWidth', 2, 'DisplayName', sprintf('N = %g N m', N));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); grid on; ylabel('heading \psi [deg]'); legend('Location','northwest');
title('a constant yaw moment: the heading never stops growing');
subplot(2,1,2); grid on; ylabel('turn rate [deg/s]'); xlabel('time [s]');
title('the turn rate levels off within a few seconds: the heading is its running sum');
exportgraphics(f, fullfile(here, 'img', 'W04_result_open_loop.png'), 'Resolution', 150);
