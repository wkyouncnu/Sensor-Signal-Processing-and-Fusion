%% W09 · 실험 9-3 — 한 주차씩 빼 본다 / Experiment 9-3 — one week at a time, removed
%
%  이 절이 묻는 것 / the question
%      각 주차가 이 임무에서 **얼마를 벌었는가**? 말이 아니라 수로.
%      What did each week actually buy in this mission — as a number, not a claim.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 같은 모델 W09_D_ablation 을 열 번 돌린다: 기준 한 번, 스위치 하나씩 0 으로 아홉 번.
%      ② 매번 W09_metrics 의 **같은 정의**로 재어 한 표에 쌓는다.
%      ③ 기준과 가장 크게 갈린 셋의 항적을 겹쳐 그린다.
%      ① Runs one model ten times: the reference, then each switch set to zero.
%      ② Measures every run with the same definitions, and stacks them in one table.
%      ③ Draws the three tracks that departed furthest from the reference.
%
%  출력에서 볼 것 / what to look for in the output
%      - use_ssa 와 use_Ki_u 를 끄면 임무가 **끝나지 않는다** (표의 T 열이 비어 있다).
%      - use_scale 를 끄면 명령한 모멘트와 나온 모멘트가 37.6 N m 까지 벌어진다.
%      - use_vane 를 끄면 유지 오차가 0.75 m 에서 3.68 m 로 다섯 배가 된다.
%      - use_pass 는 이 조류에서 아무것도 바꾸지 않는다 — §9-5 에서 값을 한다.
%      - Two switches stop the mission finishing at all; one costs the moment;
%        one costs the hold; and one changes nothing here, and everything in §9-5.
%
%  만드는 것 / produces: img/W09_result_ablation.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 열 번의 임무 / ten missions
clear RUN MET            % 앞 절이 남긴 누적 변수를 비운다 / clear what an earlier section left
S = {'none','use_Ki_u','use_ssa','use_Kd','use_ilos','use_pass','use_scale','use_notch','use_vane','hand_over'};
W = {'-','W3','W4','W4','W5','W5','W6','W7','W8','W8'};
fprintf('\n  W09 Experiment 9-3  one week at a time, removed\n');
fprintf('    switch off   week   T [s]   u [m/s]   y_e [m]   r [deg/s]   dN [N m]   hold [m]   settle [s]\n');
for i = 1:numel(S)
    if i == 1, R = W09_read('W09_D_ablation'); else, R = W09_read('W09_D_ablation', S{i}, 0); end
    M = W09_metrics(R);   RUN(i) = R;   MET(i) = M;   %#ok<SAGROW>
    if isnan(M.T), T = '   --'; else, T = sprintf('%5.1f', M.T); end
    fprintf('    %-12s  %-4s  %s    %6.3f    %6.2f      %6.2f     %6.2f     %6.3f       %5.1f\n', ...
            S{i}, W{i}, T, M.u, M.ye, M.r, M.Nerr, M.hold, M.tset);
end

%% 2) 가장 크게 갈린 셋 / the three that departed furthest
d = arrayfun(@(M) M.hold/MET(1).hold + MET(1).u/M.u + M.Nerr/MET(1).Nerr, MET);
d(1) = -Inf;  [~, ord] = sort(d, 'descend');   pick = [1 ord(1:3)];
f = lab_fig('W09 Exp 9-3  one week at a time', 1050, 480);
COL = lines(4);
subplot(1,2,1); hold on; grid on; axis equal;
V = RUN(1).V;  plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
for j = 1:4, plot(RUN(pick(j)).E, RUN(pick(j)).N, 'Color', COL(j,:), 'LineWidth', 1.3); end
xlabel('east [m]'); ylabel('north [m]'); title('the same mission, four vessels');
legend(['path', 'waypoints', S(pick)], 'Location', 'southoutside', 'NumColumns', 3, ...
       'Interpreter', 'none');
subplot(1,2,2);
b = bar([[MET.ye]' [MET.hold]']);  hold on; grid on;
yline(MET(1).ye, '--', 'Color', b(1).FaceColor);  yline(MET(1).hold, '--', 'Color', b(2).FaceColor);
bad = find(isnan([MET.T]));
plot(bad, 0.2*ones(size(bad)), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
set(gca, 'XTick', 1:numel(S), 'XTickLabel', S, 'TickLabelInterpreter', 'none');
xtickangle(40);  ylabel('[m]');  title('x = the mission did not finish');
legend({'cross-track at the end of a leg', 'hold error'}, 'Location', 'northwest');
exportgraphics(f, fullfile(here, 'img', 'W09_result_ablation.png'), 'Resolution', 150);
