%% W02 · 절 D — D 를 더한다 / Section D — add D
%
%  이 절이 묻는 것 / the question
%      P 제어기에 D (미분항) 를 더하면 무엇이 바뀌고 무엇이 그대로인가?
%      What does adding D (the derivative term) to the P controller change,
%      and what does it leave as it was?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W02_D_PD 를 Kp = 10 에 두고 Kd = 0, 2, 6 으로 한 번씩 돌린다.
%      ② 경우마다 감쇠비, 영점 위치, 오버슛, 정착시간, 남은 오차, 최대 힘을 표로 찍는다.
%      ③ 위치(위)와 D 항(아래)을 그려 저장한다.
%      ① Runs W02_D_PD at Kp = 10 with Kd = 0, 2 and 6.
%      ② Prints the damping ratio, the zero, the overshoot, the settling time,
%         the error left and the peak force for each.
%      ③ Plots the position (top) and the D term (bottom) and saves them.
%
%  출력에서 볼 것 / what to look for in the output
%      - Kd 가 커질수록 감쇠비가 커지고 오버슛이 줄어든다 (38.8 -> 8.6 %): D 는 브레이크다.
%      - 남은 오차는 0.167 그대로다: 멈춰 있으면 미분이 0 이라 D 는 힘을 내지 않는다.
%      - Kd = 6 에서 감쇠비가 1 을 넘어도 8.6 % 오버슛이 남는다: D 가 만든 영점 -Kp/Kd 때문이다.
%      - 최대 힘이 커진다 (129.6 N): 계단 순간 거른 미분이 Kd Nf 까지 튄다 (미분 킥, §2-10).
%      - As Kd grows the damping ratio rises and the overshoot falls
%        (38.8 -> 8.6 %): D is a brake.
%      - The error left stays at 0.167: at rest the derivative is zero, so D
%        produces no force.
%      - At Kd = 6 the damping ratio exceeds 1 and 8.6 % overshoot remains: the
%        zero at -Kp/Kd that D adds.
%      - The peak force grows (129.6 N): at the step the filtered derivative
%        jumps to Kd Nf (the derivative kick, §2-10).
%
%  만드는 것 / produces: img/W02_result_D.png

%% 0) 경로와 플랜트 값 / paths and the plant values
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  감쇠비 식 (b + Kd) / (2 sqrt(k + Kp)) 에 쓰는 값 (m = 1)
%  Values used in the damping-ratio formula (b + Kd) / (2 sqrt(k + Kp)), m = 1
Kp = 10;  k = 2;  b = 2;

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W02 D  P + D  (Kp = %g)\n', Kp);
fprintf('    Kd   zeta   zero    overshoot %%  settle [s]  error left  peak tau [N]\n');
f = lab_fig('W02 D  P + D', 1000, 620);

%% 2) 미분 게인 세 개 / three derivative gains
for Kd = [0 2 6]
    %  W02_read: 모델을 기본값으로 돌리고 R.t, R.y (위치), R.tau (힘), R.D (D 항) 를 돌려준다
    %  W02_read runs the model and returns R.t, R.y (position), R.tau (force), R.D (the D term)
    R = W02_read('W02_D_PD', 'Kp', Kp, 'Kd', Kd);

    %  정상상태값 = 마지막 1 s 의 평균. 오버슛·정착시간은 이 값을 기준으로 잰다 (§2-4)
    %  Steady value = mean of the last second; overshoot and settling are measured against it (§2-4)
    yss = mean(R.y(R.t > 9));
    [Mp, ts] = step_metrics(R.t, R.y, yss, 1);

    %  D 가 만드는 영점 -Kp/Kd / the zero D adds, at -Kp/Kd
    if Kd > 0, z = sprintf('%6.2f', -Kp/Kd); else, z = '  none'; end   % 영점 -Kp/Kd / the zero
    fprintf('    %-3g  %5.3f  %s  %10.1f  %10.2f  %10.3f  %11.1f\n', Kd, ...
            (b + Kd)/(2*sqrt(k + Kp)), z, Mp, ts, 1 - yss, max(R.tau));

    %  위: 위치, 아래: D 항 / top: position, bottom: the D term
    subplot(2,1,1); hold on; plot(R.t, R.y, 'LineWidth', 2, 'DisplayName', sprintf('K_d = %g', Kd));
    subplot(2,1,2); hold on; plot(R.t, R.D, 'LineWidth', 1.6, 'DisplayName', sprintf('K_d = %g', Kd));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); plot(R.t, R.y_d, 'k--', 'DisplayName', 'setpoint');
ylabel('position y [m]'); legend('Location','southeast'); grid on;
title('K_p = 10: more K_d, less overshoot — the level 0.833 does not move');
subplot(2,1,2); xlim([0.8 4]); ylabel('D term [N]'); xlabel('time [s]'); legend; grid on;
title('the brake: a spike at the step (the kick), then negative while the error closes');
exportgraphics(f, fullfile(here, 'img', 'W02_result_D.png'), 'Resolution', 150);
