function W06_fig_ladder(Rs, L, V, here)
%W06_FIG_LADDER  6-8 절의 그림 / the figure of Section 6-8.
%
%   W06_fig_ladder(Rs, L, V, here)
%
%   Rs    단마다 한 번의 실행 / one run per rung      (W06_read 의 결과, cell)
%   L     사다리 표 / the ladder table                {단번호, 이름, 모델, 절, 목표}
%   V     주차 상수 / the week's constants            W06_vars()
%   here  그림을 저장할 주차 폴더 / the week's folder
%
%   단마다의 그림은 `W06_fig_rung` 이 여섯 칸으로 그린다. 이 그림은 그것과 다른
%   것을 한다 — **단들을 겹쳐 놓는다.** 겹쳐야 보이는 것이 셋 있다: 어느 단이
%   어디로 갔는가, 거리를 얼마나 빨리 닫았는가, 그리고 어느 단이 천장에 닿았는가.
%   W06_fig_rung draws each rung in six panels. This figure does the one thing
%   those cannot: it lays the rungs ON TOP OF EACH OTHER. Three things only show
%   up that way -- where each rung went, how fast each closed its distance, and
%   which rungs pressed against the ceilings.
%
%   See also W06_J_LADDER, W06_FIG_RUNG.

n   = size(L,1);
col = lines(n);
lab = arrayfun(@(i) sprintf('%d %s', L{i,1}, L{i,2}), 1:n, 'UniformOutput', false);

f = lab_fig('W06 J  the ladder', 1180, 380);

%% 왼쪽 — 모든 단의 항적 한 장에 / every rung, on one chart
subplot(1,3,1); hold on; grid on; axis equal;
fill([V.quay_E V.track_Emin V.track_Emin V.quay_E], ...
     [V.track_Nmin V.track_Nmin V.track_Nmax V.track_Nmax], [.85 .85 .85], ...
     'EdgeColor', [.5 .5 .5], 'HandleVisibility', 'off');
for i = 1:n
    R = Rs{i};
    plot(R.E, R.N, 'Color', col(i,:), 'LineWidth', 1.2);
    track_ships({[R.N R.E R.psi]}, col(i,:), 'Marks', 3);
    if ~any(isnan(L{i,5}))
        plot(L{i,5}(2), L{i,5}(1), 'kp', 'MarkerSize', 11, ...
             'MarkerFaceColor', [1 0.85 0.2], 'HandleVisibility', 'off');
    end
end
xlabel('east [m]'); ylabel('north [m]'); title('every rung, on one chart');

%% 가운데 — 거리를 닫는 속도 / how each rung closes the distance
subplot(1,3,2); hold on; grid on;
for i = 1:n, plot(Rs{i}.t, Rs{i}.d, 'Color', col(i,:), 'LineWidth', 1.2); end
yline(0.5, 'Color', [.4 .4 .4], 'HandleVisibility', 'off');
xlabel('time [s]'); ylabel('distance to the target [m]');
title('how each rung closes the distance');
legend(lab, 'Location', 'northeast', 'FontSize', 7);

%% 오른쪽 — 단마다 세 추력의 최댓값 / the three thrusts, rung by rung
subplot(1,3,3);
Fm = cell2mat(cellfun(@(R) [max(abs(R.T_L)) max(abs(R.T_R)) max(abs(R.F_B))], ...
                      Rs, 'UniformOutput', false));
bar(Fm); grid on;
set(gca, 'XTickLabel', cellfun(@(r) sprintf('%d', r), L(:,1), 'UniformOutput', false));
yline(V.F_B_max, '--', 'F_{B,max}', 'Color', [.4 .4 .4], 'HandleVisibility', 'off');
xlabel('rung'); ylabel('largest magnitude [N]');
title('the three thrusts, rung by rung');
legend({'|T_L|', '|T_R|', '|F_B|'}, 'Location', 'northwest', 'FontSize', 8);

exportgraphics(f, fullfile(here, 'img', 'W06_result_ladder.png'), 'Resolution', 150);
end
