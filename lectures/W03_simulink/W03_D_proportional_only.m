%% W03 · 절 D — P 만 / Section D — P only
%
%  이 절이 묻는 것 / the question
%      2주차의 P 제어기를 배의 속도에 그대로 두면 무엇이 같고 무엇이 다른가?
%      The P controller of Week 2, unchanged, on the vessel's speed: what stays
%      the same and what changes?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W03_D_P 를 Kp = 50, 100, 200, 400, 800 으로 한 번씩 돌린다
%         (목표 1.5 m/s, t = 5 s 에 계단).
%      ② 경우마다 최종 속도, 남은 오차, 오버슛, 상승시간, 정착시간, 추력이 한계에
%         붙어 있던 시간을 표로 찍는다.
%      ③ 속도(위)와 추력(아래)을 그려 저장한다.
%      ① Runs W03_D_P at Kp = 50, 100, 200, 400 and 800 (1.5 m/s at t = 5 s).
%      ② Prints the final speed, the error left, the overshoot, the rise and
%         settling times, and how long the thrust sat on its limit.
%      ③ Plots the speed (top) and the thrust (bottom) and saves the figure.
%
%  출력에서 볼 것 / what to look for in the output
%      - 오차가 줄지만 0 이 되지 않는다: 1.5 m/s 를 유지하려면 항력만큼의 힘이
%        계속 필요한데, P 는 오차가 있어야만 힘을 낸다.
%      - 오버슛이 거의 없다: 스프링이 없는 1차 플랜트라 울릴 것이 없다.
%      - Kp >= 200 부터 추력이 한계에 붙고, 게인을 더 올려도 상승시간이 거의 줄지 않는다.
%      - The error shrinks and never reaches zero: holding 1.5 m/s takes a steady
%        force against the drag, and P produces force only from error.
%      - Almost no overshoot: a first-order plant with no spring cannot ring.
%      - From Kp = 200 the thrust hits its limit, and more gain barely shortens
%        the rise time.
%
%  만드는 것 / produces: img/W03_result_P.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W03 D  P only  (u_d = 1.5 m/s at t = 5 s)\n');
fprintf('    Kp    final u   error left   overshoot %%   rise [s]   settle [s]   time at thrust limit [s]\n');
f = lab_fig('W03 D  P only', 1000, 620);

%% 2) 게인 다섯 개로 한 번씩 / one run for each of five gains
for Kp = [50 100 200 400 800]
    %  모델을 돌리고 신호를 이름으로 받는다 (Kp 만 바꾼다)
    %  Run the model and get the signals by name (only Kp changed)
    R = W03_read('W03_D_P', 'Kp', Kp);

    %  step_metrics: 오버슛·정착시간·상승시간을 t = 5 s 부터, 자기 최종값 기준으로 잰다.
    %  P 만으로는 1.5 에 닿지 않으므로 기준은 목표가 아니라 최종값이다 (2주차 §2-4).
    %  step_metrics measures overshoot, settling and rise time from t = 5 s,
    %  against the run's own final value: P alone never reaches 1.5 (Week 2 §2-4).
    [Mp, ts, tr] = step_metrics(R.t, R.u, R.u(end), 5);

    %  추력이 한계 X_hi 에 붙어 있던 시간 = 그런 표본 수 x 스텝 h
    %  Time spent on the thrust limit X_hi = number of such samples x step h
    fprintf('    %-4g  %7.3f   %10.3f   %11.1f   %8.2f   %10.2f   %24.2f\n', Kp, R.u(end), ...
            1.5 - R.u(end), max(Mp,0), tr, ts, sum(R.X >= R.V.X_hi - 1e-6)*R.V.h);

    %  위: 속도, 아래: 추력 / top: speed, bottom: thrust
    subplot(2,1,1); hold on; plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_p = %g', Kp));
    subplot(2,1,2); hold on; plot(R.t, R.X, 'LineWidth', 1.6, 'DisplayName', sprintf('K_p = %g', Kp));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); xlim([0 20]); grid on;
ylabel('u [m/s]'); legend('Location','southeast');
title('P alone: a larger K_p leaves less error, never none, and does not ring');
subplot(2,1,2); yline(R.V.X_hi, 'r:', 'HandleVisibility','off'); xlim([0 20]); grid on;
ylabel('thrust X [N]'); xlabel('time [s]'); title('above K_p = 160 the step asks for more than 239 N');
exportgraphics(f, fullfile(here, 'img', 'W03_result_P.png'), 'Resolution', 150);
