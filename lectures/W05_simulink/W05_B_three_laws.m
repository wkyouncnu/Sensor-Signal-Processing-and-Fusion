%% W05 · 실험 5-1b — 한 모델, 세 법칙 / Experiment 5-1b — one model, three laws
%
%  이 절이 묻는 것 / the question
%      유도 블록 안에는 법칙이 셋 있고 `law` 가 고른다. 같은 임무·같은 조류·같은
%      오토파일럿에서 셋을 차례로 돌리면 무엇이 달라지는가?
%      The guidance block holds three laws and `law` chooses. Run the same mission,
%      the same current and the same autopilot with each in turn: what changes?
%
%  돌리는 법 / how to run one of them by hand
%      W05_0_setup        % law = 3 (ILOS) 이 기본 / the default
%      law = 1;           % 또는 2, 3 / or 2, or 3
%      open_system('W05_G_tuning')   그리고 Run / then press Run
%      -> Scope 와 XY Graph 가 그 법칙의 결과를 그린다. 모델을 다시 만들 필요가 없다.
%         The Scope and XY Graph draw that law's result; the model is not rebuilt.
%
%  출력에서 볼 것 / what to look for in the output
%      - atan2 는 다리마다 3.93 m 를 벗어난다. 점을 겨냥하기 때문이고, 튜닝의 문제가 아니다.
%      - LOS 는 1.52 m 로 줄인다. 선을 겨냥하기 때문이다. 남는 것은 조류가 미는 만큼이다.
%      - ILOS 는 0.61 m 까지 줄인다. 미는 만큼을 적분이 기억하기 때문이다.
%      - 대신 임무는 조금씩 느려진다: 316 -> 330 -> 339 s. 경로를 지키는 데 거리가 든다.
%      - atan2 strays 3.93 m from each leg because it aims at a POINT; no gain fixes
%        that. LOS aims at the LINE and leaves 1.52 m, which is what the current
%        pushes. ILOS remembers the push and leaves 0.61 m. Each step costs time:
%        316 -> 330 -> 339 s, because holding a line costs distance.
%
%  만드는 것 / produces: img/W05_result_three_laws.png

%% 0) 준비 / setup
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
clear RUN;
NM = {'atan2  aims at a point', 'LOS  aims at the line', 'ILOS  remembers the push'};
S  = {'V_c', 0.3, 'T_final', 450};          % 임무 + 동쪽으로 0.3 m/s 조류 / the mission and a current

%% 1) 같은 임무를 세 번, law 만 바꾼다 / the same mission three times, only law changes
fprintf('\n  W05 Experiment 5-1b  one model, three laws  (W05_G_tuning, current 0.3 m/s east)\n');
fprintf('    law   mean |y_e| legs 2-4 [m]   worst |y_e| [m]   last waypoint at [s]\n');
for j = 1:3
    R = W05_read('W05_G_tuning', S{:}, 'law', j);
    m = R.wp >= 2;                                  % 첫 다리는 20 m 떨어져 출발한다 / leg 1 starts 20 m off
    k = find(hypot(R.N - 60, R.E - 120) < 3, 1);
    fprintf('    %-5s %20.3f %17.3f %20.1f\n', ...
            strtok(NM{j}), mean(abs(R.y_e(m))), max(abs(R.y_e(m))), R.t(k));
    RUN{j} = R;
end

%% 2) 그림: 세 항적과 세 오차 / the three tracks and the three errors
f = lab_fig('W05 B  one model, three laws', 1150, 560);
V = W05_vars();  COL = lines(3);
subplot(1,2,1); hold on; grid on; axis equal;
plot(V.WP_E, V.WP_N, 'k--', 'HandleVisibility','off');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor','k', 'DisplayName','waypoints');
for j = 1:3
    plot(RUN{j}.E, RUN{j}.N, 'Color', COL(j,:), 'LineWidth', 1.5, 'DisplayName', NM{j});
end
quiver(100, 8, 12, 0, 0, 'Color', [0.2 0.4 0.8], 'LineWidth', 2, 'MaxHeadSize', 1, ...
       'DisplayName', 'current 0.3 m/s');
xlim([-20 140]); ylim([-20 80]);
xlabel('east [m]'); ylabel('north [m]'); legend('Location','southeast', 'FontSize', 8);
title('the same mission and the same autopilot; only law changes');

subplot(1,2,2); hold on; grid on;
for j = 1:3
    plot(RUN{j}.t, RUN{j}.y_e, 'Color', COL(j,:), 'LineWidth', 1.2, 'DisplayName', NM{j});
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('time [s]'); ylabel('y_e  [m]'); legend('Location','northeast', 'FontSize', 8);
title('the cross-track error each law leaves');
exportgraphics(f, fullfile(here, 'img', 'W05_result_three_laws.png'), 'Resolution', 150);
