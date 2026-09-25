%% W07 · 실험 7-5 — 필터의 값 / Experiment 7-5 — what the filter costs
%
%  이 절이 묻는 것 / the question
%      노치는 공짜인가? 파랑이 없는 날에도 그대로 두어도 되는가?
%      Is the notch free? Can it be left in on a calm day?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 바다를 끄고, 필터가 없는 모델과 노치가 있는 모델에 같은 계단을 준다.
%      ② 오버슈트·상승시간·정착시간을 나란히 찍는다.
%      ③ 두 계단응답을 겹쳐 그린다.
%      ① With the sea off, gives the same step to the unfiltered and the notched model.
%      ② Prints the overshoot, the rise time and the settling time of both.
%      ③ Plots the two step responses on one axis.
%
%  출력에서 볼 것 / what to look for in the output
%      - 노치는 w0 에서만 내려가지 않는다. 그 **위상**은 훨씬 낮은 주파수까지 끌고 온다.
%      - D 항이 늦게 들어오므로 감쇠가 줄고, 오버슈트가 0.93 -> 9.07 % 로 커진다.
%      - 정착시간도 1.72 -> 7.76 s 로 늘어난다. 이것이 필터의 값이다.
%      - A notch does not only attenuate at w0: its **phase** reaches much lower.
%      - The D term arrives late, damping falls, and the overshoot grows from
%        0.93 to 9.07 %, with settling from 1.72 to 7.76 s.
%      - That is the price, and §7-7 is where it is weighed.
%
%  만드는 것 / produces: img/W07_result_cost.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 바다를 끄고 같은 계단을 / the same step, with the sea off
fprintf('\n  W07 Experiment 7-5  what the filter costs  (the sea switched off)\n');
fprintf('    %-12s  overshoot   rise [s]   settle [s]   phase of H at 1.6 rad/s\n', 'filter');
NAME = {'none', 'notch'};  MODEL = {'W07_D_no_filter', 'W07_E_notch'};  RUN = cell(1,2);
s = tf('s');
for i = 1:2
    R = W07_read(MODEL{i}, 'wave_on', 0, 'T_final', 40);
    RUN{i} = R;
    [Mp, ts, tr] = step_metrics(R.t, R.psi, R.V.psi_step, R.V.t_step);
    zn = R.V.zeta_n;  if i == 1, zn = R.V.zeta_d; end      % 필터가 없으면 H(s) = 1
    H = (s^2 + 2*zn*R.V.w0*s + R.V.w0^2)/(s^2 + 2*R.V.zeta_d*R.V.w0*s + R.V.w0^2);
    [~, ph] = bode(H, 1.6);
    fprintf('    %-12s %9.2f %% %9.2f %11.2f %17.1f deg\n', NAME{i}, Mp, tr, ts, ph);
end

%% 2) 두 계단응답 / the two step responses
fg = lab_fig('W07 Exp 7-5  the cost', 1000, 460);
hold on; grid on; xlim([4 30]);
plot(RUN{1}.t, RUN{1}.psi, 'LineWidth', 2, 'DisplayName', 'no filter');
plot(RUN{2}.t, RUN{2}.psi, 'LineWidth', 2, 'DisplayName', 'notch');
yline(RUN{1}.V.psi_step, 'k--', 'HandleVisibility','off');
xlabel('time [s]'); ylabel('\psi [deg]'); legend('Location','southeast');
title('a 10 deg turn in still water: the filter that helped in waves is in the way here');
exportgraphics(fg, fullfile(here, 'img', 'W07_result_cost.png'), 'Resolution', 150);
