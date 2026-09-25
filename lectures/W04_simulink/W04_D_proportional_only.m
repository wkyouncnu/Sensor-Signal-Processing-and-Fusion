%% W04 · 실험 4-3a — P 만 / Experiment 4-3a — P only
%
%  이 절이 묻는 것 / the question
%      P 만으로 선수각을 제어하면 3주차(속도)처럼 오차가 남는가? 울리는가?
%      With P alone on the heading, is an error left as in Week 3? Does it ring?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W04_D_P 를 Kp = 30, 100, 300, 1000 으로 돌린다 (10 도 선회, t = 5 s).
%      ② 최종 선수각, 오버슛, 상승시간, 정착시간, 최대 요 모멘트를 표로 찍는다.
%      ③ 선수각(위)과 요 모멘트(아래)를 그려 저장한다.
%      ① Runs W04_D_P at Kp = 30, 100, 300 and 1000 (a 10 deg turn at t = 5 s).
%      ② Prints the final heading, overshoot, rise and settling times, and the
%         peak yaw moment.
%      ③ Plots the heading (top) and the yaw moment (bottom) and saves them.
%
%  출력에서 볼 것 / what to look for in the output
%      - 모든 게인에서 최종 선수각이 10 도다: 오차가 남지 않는다 (절 C: 선수각은 스스로 적분기).
%      - 게인이 클수록 빠르고 더 울린다 (오버슛 5.8 -> 15.9 %). 3주차와 반대다.
%      - Kp = 1000 에서는 모멘트가 한계(70.85 N m)에 붙어 게인을 올린 효과가 적다.
%      - Every gain ends at 10 deg: no error is left (section C: the heading
%        integrates by itself).
%      - A larger gain is faster and rings more (overshoot 5.8 -> 15.9 %), the
%        opposite of Week 3.
%      - At Kp = 1000 the moment sits on its limit (70.85 N m) and extra gain buys little.
%
%  만드는 것 / produces: img/W04_result_P.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W04 Experiment 4-3a  P only  (psi_d = 10 deg at t = 5 s)\n');
fprintf('    Kp     final psi [deg]   overshoot %%   rise [s]   settle [s]   peak |N| [N m]\n');
f = lab_fig('W04 Exp 4-3a  P only', 1000, 620);

%% 2) 게인 네 개로 한 번씩 / one run for each of four gains
for Kp = [30 100 300 1000]
    R = W04_read('W04_D_P', 'Kp', Kp);

    %  목표 10 도 기준으로, t = 5 s 부터 오버슛·정착시간·상승시간을 잰다
    %  Overshoot, settling and rise time against 10 deg, from t = 5 s
    [Mp, ts, tr] = step_metrics(R.t, R.psi, 10, 5);
    fprintf('    %-5g  %15.3f   %11.1f   %8.2f   %10.2f   %14.1f\n', Kp, R.psi(end), max(Mp,0), tr, ts, max(abs(R.N)));

    %  위: 선수각, 아래: 요 모멘트 / top: heading, bottom: yaw moment
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_p = %g', Kp));
    subplot(2,1,2); hold on; plot(R.t, R.N, 'LineWidth', 1.6, 'DisplayName', sprintf('K_p = %g', Kp));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command'); xlim([0 20]); grid on;
ylabel('\psi [deg]'); legend('Location','southeast');
title('P alone: every gain ends exactly at 10 deg; a larger gain rings more');
subplot(2,1,2); yline(R.V.N_max*[-1 1], 'r:'); xlim([0 20]); grid on;
ylabel('yaw moment N [N m]'); xlabel('time [s]'); title('the dotted red lines are the moment limit');
exportgraphics(f, fullfile(here, 'img', 'W04_result_P.png'), 'Resolution', 150);
