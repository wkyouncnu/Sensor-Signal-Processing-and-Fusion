function W06_fig_stopping(Rs, Rc, G, CL, V, here)
%W06_FIG_STOPPING  6-4 절의 그림 / the figure of section 6-4.
%
%   W06_F_stopping 이 부른다. 절 스크립트는 **돌리고 재는 것**까지이고 그리는 것은
%   여기다 - 실행 줄 45 개 규칙 (standing-orders §15-15). 게인 셋과 조류 둘을
%   함께 재면서 스크립트가 63 줄이 되었고, 그래서 그림을 떼어 냈다 (2026-10-27).
%   Called by W06_F_stopping. A section script runs and measures; the drawing
%   lives here, so that the script stays under the 45-line rule.
%
%   Rs    게인 세 개의 실행 / the three gain runs      (W06_read 의 결과, cell)
%   Rc    조류 없음·0.3 m/s 두 실행 / the two current runs      (cell, 2)
%   G     그 세 게인 / those three gains                        Kp_pos
%   CL    세 게인의 색 / one colour row per gain                3x3
%   V     주차 상수 / the week's constants                      W06_vars()
%   here  그림을 저장할 주차 폴더 / the week's folder

f = lab_fig('W06 F  stopping', 1180, 380);
for i = 1:numel(G)
    subplot(1,3,1); hold on; grid on; plot(Rs{i}.d, Rs{i}.u, 'Color', CL(i,:), 'LineWidth', 1.3);
    plot(0:0.1:12, min(V.u_lim, G(i)*(0:0.1:12)), '--', 'Color', [0.55 0.55 0.55]);
    subplot(1,3,2); hold on; grid on; plot(Rs{i}.t, Rs{i}.d, 'Color', CL(i,:), 'LineWidth', 1.3);
end
subplot(1,3,1); set(gca, 'XDir', 'reverse'); xlim([0 12.5]);
xlabel('distance left [m]'); ylabel('u [m/s]');
title('grey dashed: sat(K_{p,pos} d).   coloured: what the hull did');
subplot(1,3,2); set(gca, 'YScale', 'log'); ylim([1e-2 20]); xlim([0 50]);
xlabel('time [s]'); ylabel('distance left [m]');
title('straight on a log axis: the slope is -K_{p,pos}');
legend(compose('K_{p,pos} = %.2f', G'), 'Location', 'southwest');
subplot(1,3,3); hold on; grid on;
plot(Rc{1}.t, Rc{1}.d, 'Color', CL(1,:), 'LineWidth', 1.3);
plot(Rc{2}.t, Rc{2}.d, 'Color', CL(2,:), 'LineWidth', 1.3);
yline(V.R_berth, 'k--'); ylim([0 inf]); xlim([0 125]);
xlabel('time [s]'); ylabel('distance left [m]');
title('at (10, 10): dashed is R_{berth} = 0.40 m');
legend({'no current', '0.3 m/s cross-current'}, 'Location', 'northeast');

exportgraphics(f, fullfile(here, 'img', 'W06_result_stopping.png'), 'Resolution', 150);
end
