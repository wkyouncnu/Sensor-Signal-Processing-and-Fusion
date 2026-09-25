%% W02 · 실험 2-4 — 응답 하나에서 다섯 숫자를 읽는다 / Experiment 2-4 — five numbers off one response
%
%  이 절이 묻는 것 / the question
%      응답이 좋은지 나쁜지를 무엇으로 말하는가? "빠르고 덜 출렁인다" 는 확인할 수
%      없고, "오버슛 10 % 이하, 3 s 안에 정착" 은 확인할 수 있다.
%      How is a response judged? "Fast and not too oscillatory" cannot be checked;
%      "overshoot below 10 % and settled within 3 s" can.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W02_C_metrics 를 Kp = 10 으로 한 번 돌린다.
%      ② 상승시간·피크시간·오버슛·정착시간·남은 오차·IAE 를 한 줄로 찍는다.
%      ③ 그 다섯 개를 응답 위에 표시한 그림을 저장한다.
%      ① Runs W02_C_metrics once at Kp = 10.
%      ② Prints the rise time, peak time, overshoot, settling time, error left and IAE.
%      ③ Saves a figure with those five marked on the response itself.
%
%  출력에서 볼 것 / what to look for in the output
%      - 시간은 전부 계단 시각 t = 1 s 부터 잰다. 0 에서 재면 1 s 씩 길게 나온다.
%      - 오버슛은 목표가 아니라 **자기 최종값** 기준이다: 0.833 m 에 대해 38.8 %.
%      - Every time is measured from the step at t = 1 s, not from zero.
%      - The overshoot is measured against the run's **own final value**, 0.833 m.
%
%  만드는 것 / produces: img/W02_result_metrics.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 한 번 돌리고 다섯 숫자를 잰다 / one run, and the five numbers
R = W02_read('W02_C_metrics', 'Kp', 10);
t = R.t - 1;  y = R.y;  yss = mean(y(R.t > 9));      % 계단 뒤의 시간 / time after the step
[Mp, ts, tr] = step_metrics(R.t, y, yss, 1);
[yp, i] = max(y);  tp = t(i);
j = t >= 0;  IAE = trapz(t(j), abs(R.y_d(j) - y(j)));
fprintf('\n  W02 Experiment 2-4  the five numbers of one response\n');
fprintf('    Kp = 10:  rise %.3f s  peak time %.3f s  overshoot %.1f %%  settle %.2f s  error %.3f m  IAE %.3f m s\n', ...
        tr, tp, Mp, ts, 1 - yss, IAE);

%% 2) 그 다섯 개를 응답 위에 그린다 / the same five, drawn on the response
t1 = t(find(y >= 0.1*yss, 1));  t9 = t(find(y >= 0.9*yss, 1));
f = lab_fig('W02 Exp 2-4  five numbers', 1000, 560);  hold on; grid on;
fill([0 9 9 0], yss*[0.98 0.98 1.02 1.02], [0.85 0.85 0.85], 'EdgeColor','none');  % 2 % 띠 / the band
plot(t, y, 'LineWidth', 2.2);  plot(t, R.y_d, 'k--');
plot([t1 t9], 0.9*yss*[1 1], 'g-', 'LineWidth', 4);                                % 상승시간 / rise
plot([t1 t9], [0.1 0.9]*yss, 'o', 'Color', [0 0.5 0], 'MarkerFaceColor', [0 0.8 0]);
yline([0.1 0.9]*yss, ':', 'Color', [0 0.5 0]);
xline(tp, 'r:', 'LineWidth', 1.5);  plot(tp, yp, 'ro', 'MarkerFaceColor', 'r');     % 피크 / peak
plot([tp tp], [yss yp], 'r-', 'LineWidth', 3);  xline(ts, 'm:', 'LineWidth', 1.5);  % 오버슛·정착
plot([8.5 8.5], [yss 1], 'b-', 'LineWidth', 3);                                    % 남은 오차 / error
text(t9 + 0.05, 0.9*yss - 0.05, sprintf('rise time t_r = %.2f s  (10 %% to 90 %%)', tr), 'Color', [0 0.5 0]);
text(tp + 0.08, yp, sprintf('peak time t_p = %.2f s,  overshoot M_p = %.1f %%', tp, Mp), 'Color', 'r');
text(ts + 0.08, 0.55, sprintf('settling time t_s = %.2f s\n(inside the grey 2 %% band for good)', ts), 'Color', 'm');
text(6.2, 0.93, sprintf('steady-state error e_{ss} = %.3f m', 1 - yss), 'Color', 'b');
xlim([0 9]); ylim([0 1.25]); xlabel('time after the step [s]'); ylabel('position y [m]');
title('K_p = 10, P only: five numbers read off one step response');
exportgraphics(f, fullfile(here, 'img', 'W02_result_metrics.png'), 'Resolution', 150);
