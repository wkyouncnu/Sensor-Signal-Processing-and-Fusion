function W06_fig_limits(Rc, Rs, here)
%W06_FIG_LIMITS  6-6 절의 그림 / the figure of section 6-6.
%
%   W06_G_limits 가 부른다. 절 스크립트는 **돌리고 재는 것**까지이고 그리는 것은
%   여기다 - 실행 줄 45 개 규칙 (standing-orders §15-15). 6-8 절의 성능 판정에 쓸
%   수치를 재면서 스크립트가 48 줄이 되었고, 그래서 그림을 떼어 냈다 (2026-10-13).
%   Called by W06_G_limits. A section script runs and measures; the drawing lives
%   here, so that the script stays under the 45-line rule.
%
%   Rc  자르기 실행 / the clipping run        (W06_read 의 결과)
%   Rs  비율 줄이기 실행 / the scaling run
%   here  그림을 저장할 주차 폴더 / the week's folder

f = lab_fig('W06 Exp 6-6  clipping against scaling', 1000, 620);

subplot(2,1,1); hold on; grid on;
plot(Rc.t, Rc.Xd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'X demanded');
plot(Rc.t, Rc.Xa, 'LineWidth', 2, 'DisplayName', 'X, clipped');
plot(Rs.t, Rs.Xa, 'LineWidth', 2, 'DisplayName', 'X, scaled');
ylabel('surge force X [N]'); legend('Location','southwest');
title('neither can deliver what was asked; they give up different things');

subplot(2,1,2); hold on; grid on;
plot(Rc.t, Rc.Nd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'N demanded');
plot(Rc.t, Rc.Na, 'LineWidth', 2, 'DisplayName', 'N, clipped');
plot(Rs.t, Rs.Na, 'LineWidth', 2, 'DisplayName', 'N, scaled');
ylabel('yaw moment N [N m]'); xlabel('time [s]'); legend('Location','southwest');
title('clipping keeps more surge and loses yaw; scaling keeps the ratio 4.40');

exportgraphics(f, fullfile(here, 'img', 'W06_result_limits.png'), 'Resolution', 150);
end
