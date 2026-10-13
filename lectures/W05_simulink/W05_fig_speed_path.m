function W05_fig_speed_path(RUN, LBL, cfg, here)
%W05_FIG_SPEED_PATH  5-7 절의 그림 / the figures of section 5-7.
%
%   W05_H_speed_and_path 가 부른다. 절 스크립트는 **돌리고 재는 것**까지이고
%   그리는 것은 여기다 - 실행 줄 45 개 규칙 (standing-orders 15-15 절).
%   Called by W05_H_speed_and_path. A section script runs and measures; the
%   drawing lives here, so that the script stays under the 45-line rule.
%
%   그림은 **속도 루프를 쓴 실행 하나**만 그린다 (사용자 지시, 2026-10-13).
%   상수 전진력과의 비교는 절 스크립트가 찍는 표에 그대로 있다 - 한 그림에 두
%   임무를 겹쳐 그리면 어느 선이 무엇인지 읽느라 칸마다 범례를 봐야 했다.
%   그 자리에 **다리 번호**와 **횡방향 오차**를 시간축으로 넣는다. 둘 다 이 절이
%   말하는 것이고, 그림에 없으면 로그를 열어야 읽을 수 있었다.
%   The figure draws the run that uses the speed loop and nothing else. The
%   comparison with a constant surge force stays in the table the section script
%   prints; overlaying two missions meant reading a legend in every panel. The
%   space goes to the leg index and the cross-track error against time, both of
%   which this section talks about and neither of which was drawn.

R = RUN{2};                                  % 속도 루프를 쓴 실행 / the speed-loop run
V = W05_vars();
C = lines(7);

f = lab_fig('W05 H  speed control and path following', 1150, 740);

%% 왼쪽: 임무 전체 / left: the mission
subplot(1,2,1); hold on; grid on; axis equal;
plot(V.WP_E, V.WP_N, 'k--', 'HandleVisibility','off');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor','k', 'DisplayName','waypoints');
plot(R.E, R.N, 'Color', C(1,:), 'LineWidth', 1.6, 'DisplayName', LBL{2});
track_ships({[R.N R.E R.psi]}, C(1,:), 'Marks', 10);
xlim([-15 135]); ylim([-15 105]);
xlabel('east [m]'); ylabel('north [m]'); legend('Location','southeast', 'FontSize', 8);
title('one mission: guidance outside, speed and heading inside');

%% 오른쪽 여섯 줄, 각각 한 가지 / right: six rows, one thing each
PAN = {'u_d , u  [m/s]', 'X  [N]', 'N  [N m]', 'n_L , n_R  [rad/s]', 'waypoint k', 'y_e  [m]'};
for p = 1:6
    ax = subplot(6,2,2*p); hold on; grid on;
    switch p
        case 1
            yline(V.u_d, '--', 'Color',[.45 .45 .45], 'LineWidth',1.3, ...
                  'DisplayName', sprintf('u_d = %.2f', V.u_d));
            plot(R.t, R.u, 'Color',C(1,:), 'LineWidth',1.2, 'DisplayName','u');
        case 2
            plot(R.t, R.X, 'Color',C(2,:), 'LineWidth',1.2, 'DisplayName','X');
            yline(V.X_max, ':', 'Color',[.6 .1 .1], 'LineWidth',1.2, ...
                  'DisplayName', sprintf('X_{max} = %.0f', V.X_max));
        case 3
            plot(R.t, R.Nmom, 'Color',C(3,:), 'LineWidth',1.0, 'DisplayName','N');
            yline( V.N_speed, ':', 'Color',[.6 .1 .1], 'LineWidth',1.2, ...
                   'DisplayName', sprintf('\\pm N_{speed} = %.1f', V.N_speed));
            yline(-V.N_speed, ':', 'Color',[.6 .1 .1], 'LineWidth',1.2, 'HandleVisibility','off');
        case 4
            plot(R.t, R.nL, 'LineWidth',1.1, 'DisplayName','n_L  port');
            plot(R.t, R.nR, 'LineWidth',1.1, 'DisplayName','n_R  starboard');
            yline(cfg.n_max, 'r:', 'LineWidth',1.2, 'DisplayName','n_{max}');
        case 5
            stairs(R.t, R.wp, 'Color',C(4,:), 'LineWidth',1.4, 'DisplayName','leg');
            ylim([0.5 max(R.wp)+0.5]);
        case 6
            plot(R.t, R.y_e, 'Color',C(5,:), 'LineWidth',1.2, 'DisplayName','y_e');
            yline(0, 'k:', 'HandleVisibility','off');
    end
    ylabel(PAN{p});  if p == 6, xlabel('time [s]'); end
    legend(ax, 'Location','best', 'FontSize', 6, 'AutoUpdate','off');
end
exportgraphics(f, fullfile(here, 'img', 'W05_result_speed_path.png'), 'Resolution', 150);

%% 시뮬링크만 돌렸을 때 나오는 그림 / the figure that pressing Run alone produces
%    모델의 StopFcn 이 W05_plot 을 부른다. 같은 로그, 같은 수치다.
%    The model's StopFcn calls W05_plot: the same log and the same numbers.
evalin('base', 'sim(''W05_H_speed_path'');');
exportgraphics(gcf, fullfile(here, 'img', 'W05_run_speed_path.png'), 'Resolution', 110);

%% 도는 동안의 화면 / the live view, as it looks while the model runs
%    작업공간의 animate 가 1 이면 Animate 블록이 매 스텝 그린다. 그 창을 그대로
%    뽑아 둔다 - 학생이 Run 을 눌렀을 때 보는 것과 같은 그림이다.
%    With animate = 1 in the workspace the Animate block draws at every step;
%    that window is exported as it stands, so the lecture shows what a student
%    sees on pressing Run.
g = findobj('Type','figure','-regexp','Name','W05 live view');
if ~isempty(g)
    exportgraphics(g(1), fullfile(here, 'img', 'W05_live_view.png'), 'Resolution', 110);
end

%% 블록도에서 제어 사슬만 잘라 낸다 / the block diagram, cropped to the control chain
%    모델 전체는 2300 px 가 넘어 A4 본문 폭(703 px)에서 글자를 읽을 수 없다. 이 절이
%    말하는 것은 왼쪽 사슬이므로 그 부분만 싣는다 (results-and-figures.md 2-9 절).
%    The whole canvas is over 2300 px wide and its text is unreadable at the 703 px
%    of an A4 column. This section is about the left-hand chain, so that is what is shown.
I = imread(fullfile(here, 'img', 'W05_H_speed_path.png'));
imwrite(I(:, 1:round(0.482*size(I,2)), :), fullfile(here, 'img', 'W05_H_chain.png'));

end
