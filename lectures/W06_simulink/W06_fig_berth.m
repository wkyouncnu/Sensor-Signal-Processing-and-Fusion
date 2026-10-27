function W06_fig_berth(Rs, C, PH, TE, V, here)
%W06_FIG_BERTH  6-5·6-6 절의 그림 / the figure of sections 6-5 and 6-6.
%
%   W06_G_berthing 이 부른다. 절 스크립트는 **돌리고 재는 것**까지이고 그리는
%   것은 여기다 - 실행 줄 45 개 규칙 (standing-orders §15-15). 한 스크립트가
%   두 절을 먹이므로(6-5 는 표를 행으로, 6-6 은 두 자세로 가로질러 읽는다)
%   표가 둘이고, 그림을 떼어 내도 54 줄이 남는다 — 그래서 §18 에 이름을 적은
%   예외를 두었고, 그림만은 여기로 옮겼다 (2026-10-27).
%   Called by W06_G_berthing. A section script runs and measures; the drawing
%   lives here. One script feeds two sections, so two tables stay in it; the
%   drawing does not.
%
%   Rs    두 자세의 실행 / the two attitude runs      (W06_read 의 결과, cell)
%   C     그 두 자세의 표 / the attitude table        이름 · psi_berth · 색
%   PH    네 단계의 이름 / the four phase names
%   TE    각 단계에 든 시각 / when each phase was entered    n x 4 [s]
%   V     주차 상수 / the week's constants            W06_vars()
%   here  그림을 저장할 주차 폴더 / the week's folder

n = size(C,1);
f = lab_fig('W06 G  berthing', 1180, 700);
subplot(2,3,1); hold on; grid on; axis equal;
fill([V.quay_E V.track_Emin V.track_Emin V.quay_E], ...
     [V.track_Nmin V.track_Nmin V.track_Nmax V.track_Nmax], [.85 .85 .85], ...
     'EdgeColor', [.5 .5 .5]);
plot(V.app_E, V.app_N, 'ko', 'MarkerSize', 7);
for i = 1:n
    R = Rs{i};   plot(R.E, R.N, 'Color', C{i,3}, 'LineWidth', 1.3);
    %   선체는 접안을 마친 순간 하나만 — 두 자세의 차이는 그 하나에 다 있다
    k4 = find(R.phase >= 4, 1);
    %   track_ships 는 **도**를 받는다 (안에서 deg2rad 한다). 로그의 psi 가 이미 도다
    track_ships({[R.N(k4) R.E(k4) R.psi(k4)]}, C{i,3}, 'Marks', 1);
end
%   접안점은 선체보다 **뒤에**, 그러나 작게 — 멈춘 선체가 바로 그 점 위에 있으므로
%   큰 표지는 선체를 가리고, 선체 아래에 두면 표지가 사라진다
plot(V.berth_E, V.berth_N, 'kp', 'MarkerSize', 9, 'MarkerFaceColor', [1 0.85 0.2]);
xlim([V.track_Emin 13]); ylim([33 45]);
xlabel('east [m]'); ylabel('north [m]');
title('the hull as moored.   circle: approach.   star: berth');

subplot(2,3,2); hold on; grid on;
for i = 1:n, stairs(Rs{i}.t, Rs{i}.phase, 'Color', C{i,3}, 'LineWidth', 1.3); end
ylim([0.5 4.5]); yticks(1:4); yticklabels(PH); xlim([0 100]);
xlabel('time [s]'); title('the phase: latched, and it only ever rises');

subplot(2,3,3); hold on; grid on;
for i = 1:n, plot(Rs{i}.t, Rs{i}.d, 'Color', C{i,3}, 'LineWidth', 1.3); end
yline(V.R_app, 'k--'); yline(V.R_berth, 'k:');
set(gca, 'YScale', 'log'); ylim([0.1 60]); xlim([0 100]);
xlabel('time [s]'); ylabel('d to the active target [m]');
title(sprintf('dashed R_{app} = %.1f m, dotted R_{berth} = %.2f m', V.R_app, V.R_berth));
legend(C(:,1), 'Location', 'southwest');

subplot(2,3,4); hold on; grid on;
for i = 1:n
    plot(Rs{i}.t, Rs{i}.psi, 'Color', C{i,3}, 'LineWidth', 1.3);
    plot(Rs{i}.t, Rs{i}.psi_set, '--', 'Color', C{i,3});
end
xlim([0 100]); ylim([-100 10]); xlabel('time [s]'); ylabel('\psi [deg]');
title('solid: the heading.   dashed: asked');

subplot(2,3,5); hold on; grid on;
for i = 1:n
    plot(Rs{i}.t - TE(i,3), Rs{i}.X_dem, 'Color', C{i,3}, 'LineWidth', 1.3);
    plot(Rs{i}.t - TE(i,3), Rs{i}.Y_dem, '--', 'Color', C{i,3});
end
%   한계선은 그 선을 묶는 신호와 같은 모양으로 — 실선 X 는 회색 실선, 파선 Y 는 점선
yline([-V.X_max V.X_max], '-', 'Color', [.45 .45 .45], 'LineWidth', 0.9);
yline([-V.Y_max V.Y_max], 'k:'); xlim([0 30]); xlabel('time since phase 3 began [s]');
ylabel('demand [N]');
title(sprintf('solid X, dashed Y.   grey \\pm%.0f, dotted \\pm%.2f N', ...
              V.X_max, V.Y_max));

subplot(2,3,6); hold on; grid on;
for i = 1:n
    plot(Rs{i}.t - TE(i,3), Rs{i}.u, 'Color', C{i,3}, 'LineWidth', 1.3);
    plot(Rs{i}.t - TE(i,3), Rs{i}.v, '--', 'Color', C{i,3});
end
yline([-V.u_lim V.u_lim], '-', 'Color', [.45 .45 .45], 'LineWidth', 0.9);
yline([-V.v_lim V.v_lim], 'k:'); xlim([0 30]);
xlabel('time since phase 3 began [s]'); ylabel('speed [m/s]');
title(sprintf('solid u, dashed v.   grey \\pm%.2f, dotted \\pm%.2f m/s', ...
              V.u_lim, V.v_lim));

exportgraphics(f, fullfile(here, 'img', 'W06_result_berth.png'), 'Resolution', 150);
end
