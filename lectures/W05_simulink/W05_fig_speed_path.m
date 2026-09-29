function W05_fig_speed_path(RUN, LBL, cfg, here)
%W05_FIG_SPEED_PATH  5-7 절의 그림 셋 / the three figures of section 5-7.
%
%   W05_H_speed_and_path 가 부른다. 절 스크립트는 **돌리고 재는 것**까지이고
%   그리는 것은 여기다 - 실행 줄 45 개 규칙 (standing-orders 15-15 절).
%   Called by W05_H_speed_and_path. A section script runs and measures; the
%   drawing lives here, so that the script stays under the 45-line rule.

%% 4) 그림 / the figure
f = lab_fig('W05 H  speed control and path following', 1150, 620);
V = W05_vars();  COL = lines(2);
Nlim = @(X) min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X/2), 2*cfg.y_pont*(X/2 + cfg.k_neg*cfg.n_min^2));  %#ok<NASGU>
subplot(1,2,1); hold on; grid on; axis equal;
plot(V.WP_E, V.WP_N, 'k--', 'HandleVisibility','off');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor','k', 'DisplayName','waypoints');
for i = 1:2, plot(RUN{i}.E, RUN{i}.N, 'Color', COL(i,:), 'LineWidth', 1.6, 'DisplayName', LBL{i}); end
track_ships({[RUN{2}.N RUN{2}.E RUN{2}.psi]}, COL(2,:), 'Marks', 10);
xlim([-15 135]); ylim([-15 105]);
xlabel('east [m]'); ylabel('north [m]'); legend('Location','southeast', 'FontSize', 8);
title('the same mission, the same guidance, two sources of surge force');

PAN = {'u_d , u  [m/s]', 'X  [N]', 'N  [N m]', 'n_L , n_R  [rad/s]'};
for p = 1:4
    ax = subplot(4,2,2*p); hold on; grid on;
    switch p
        case 1
            yline(V.u_d, '--', 'Color',[.45 .45 .45], 'LineWidth',1.3, ...
                  'DisplayName', sprintf('u_d = %.2f  commanded', V.u_d));
            for i = 1:2, plot(RUN{i}.t, RUN{i}.u, 'Color',COL(i,:), 'LineWidth',1.2, ...
                              'DisplayName', sprintf('u  %s', LBL{i})); end
        case 2
            for i = 1:2, plot(RUN{i}.t, RUN{i}.X, 'Color',COL(i,:), 'LineWidth',1.2, ...
                              'DisplayName', LBL{i}); end
        case 3
            for i = 1:2, plot(RUN{i}.t, RUN{i}.Nmom, 'Color',COL(i,:), 'LineWidth',1.0, ...
                              'DisplayName', LBL{i}); end
            %  각 모델이 실제로 들고 있는 Saturation 의 값 / the constant each model holds
            yline( V.N_max,   ':', 'Color',COL(1,:), 'LineWidth',1.2, ...
                   'DisplayName', sprintf('\\pm N_{max} = %.1f', V.N_max));
            yline(-V.N_max,   ':', 'Color',COL(1,:), 'LineWidth',1.2, 'HandleVisibility','off');
            yline( V.N_speed, ':', 'Color',COL(2,:), 'LineWidth',1.2, ...
                   'DisplayName', sprintf('\\pm N_{speed} = %.1f', V.N_speed));
            yline(-V.N_speed, ':', 'Color',COL(2,:), 'LineWidth',1.2, 'HandleVisibility','off');
        case 4
            plot(RUN{2}.t, RUN{2}.nL, 'LineWidth',1.1, 'DisplayName','n_L  port');
            plot(RUN{2}.t, RUN{2}.nR, 'LineWidth',1.1, 'DisplayName','n_R  starboard');
            yline(cfg.n_max, 'r:', 'LineWidth',1.2, 'DisplayName','n_{max}');
    end
    ylabel(PAN{p});  if p == 4, xlabel('time [s]'); end
    legend(ax, 'Location','best', 'FontSize', 6, 'AutoUpdate','off');
end
exportgraphics(f, fullfile(here, 'img', 'W05_result_speed_path.png'), 'Resolution', 150);

%% 5) 시뮬링크만 돌렸을 때 나오는 그림 / the figure that pressing Run alone produces
%    모델의 StopFcn 이 W05_plot 을 부른다. 같은 로그, 같은 수치다 — 이 절의 그림과
%    다른 점은 한 번만 돌린다는 것뿐이다.
%    The model's StopFcn calls W05_plot: the same log and the same numbers, from a
%    single run instead of two.
evalin('base', 'sim(''W05_H_speed_path'');');
exportgraphics(gcf, fullfile(here, 'img', 'W05_run_speed_path.png'), 'Resolution', 110);

%% 6) 블록도에서 제어 사슬만 잘라 낸다 / the block diagram, cropped to the control chain
%    모델 전체는 2300 px 가 넘어 A4 본문 폭(703 px)에서 글자를 읽을 수 없다. 이 절이
%    말하는 것은 왼쪽 사슬이므로 그 부분만 싣는다 (results-and-figures.md 2-9 절).
%    The whole canvas is over 2300 px wide and its text is unreadable at the 703 px
%    of an A4 column. This section is about the left-hand chain, so that is what is shown.
I = imread(fullfile(here, 'img', 'W05_H_speed_path.png'));
imwrite(I(:, 1:round(0.482*size(I,2)), :), fullfile(here, 'img', 'W05_H_chain.png'));

end
