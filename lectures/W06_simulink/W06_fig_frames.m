function W06_fig_frames(Rs, C, p_d, V, here)
%W06_FIG_FRAMES  6-7 절의 그림 / the figure of section 6-7.
%
%   W06_I_two_frames 가 부른다. 절 스크립트는 **돌리고 재는 것**까지이고 그리는
%   것은 여기다 - 실행 줄 45 개 규칙 (standing-orders §15-15). 봉우리를 만든 것을
%   한 시각에서 재는 1b 절이 붙으면서 스크립트가 72 줄이 되었고, 그래서 그림을
%   떼어 냈다 (2026-10-27).
%   Called by W06_I_two_frames. A section script runs and measures; the drawing
%   lives here, so that the script stays under the 45-line rule.
%
%   Rs    네 경우의 실행 / the four runs           (W06_read 의 결과, cell)
%   C     그 네 경우의 표 / the case table         이름 · 모델 · psi · 색 · 선 모양
%   p_d   목표 [N, E] / the target
%   V     주차 상수 / the week's constants         W06_vars()
%   here  그림을 저장할 주차 폴더 / the week's folder

f = lab_fig('W06 I  two frames', 1180, 380);
%  선체는 **선수각 45 도 쌍에만** 세운다. 선수각 0 에서는 넷 다 북쪽을 보고 있어
%  선체가 궤적선 위에 글자만 더하고, 넷 다 세우면 열여섯 개가 서로를 덮는다.
%  45 도에서는 선체가 45 도로 선 채 궤적이 북서로 가므로 **그 차이가 크랩각**이다
%  hulls only on the psi = 45 pair: at psi = 0 all four point north, so the hulls
%  add nothing to the track line, and sixteen of them bury it. At 45 deg the hull
%  stands at 45 while the track runs north-west, and that difference is the crab
subplot(1,3,1); hold on; grid on; axis equal;
for i = 1:size(C,1)
    R = Rs{i};
    plot(R.E, R.N, 'Color', C{i,4}, 'LineStyle', C{i,5}, 'LineWidth', 1.3);
    %   track_ships 는 **도**를 받는다 (안에서 deg2rad 한다). 로그의 psi 가 이미 도다
    if i >= 3, track_ships({[R.N R.E R.psi]}, C{i,4}, 'Marks', 4); end
end
plot(p_d(2), p_d(1), 'kp', 'MarkerSize', 13, 'MarkerFaceColor', [1 0.85 0.2]);
xlabel('east [m]'); ylabel('north [m]');
title('track; hulls drawn on the psi 45 pair');

subplot(1,3,2); hold on; grid on;
for i = 1:size(C,1)
    plot(Rs{i}.t, Rs{i}.d, 'Color', C{i,4}, 'LineStyle', C{i,5}, 'LineWidth', 1.3);
end
yline(0.5, 'Color', [.4 .4 .4], 'HandleVisibility', 'off');
xlim([0 80]);          % 55 초면 넷 다 선다. 120 초까지 그리면 뒤 절반이 빈 칸이다
xlabel('time [s]'); ylabel('distance to the target [m]');
title('how the distance closes'); legend(C(:,1), 'Location', 'northeast');

subplot(1,3,3); hold on; grid on;
for i = 1:size(C,1)
    plot(Rs{i}.t, hypot(Rs{i}.u, Rs{i}.v), ...
         'Color', C{i,4}, 'LineStyle', C{i,5}, 'LineWidth', 1.3);
end
%  회색 선 둘은 **두 전략이 실제로 지키는 한계**다. 선체고정의 한계는 u_lim 0.80 이
%  아니라 대각선의 hypot(0.80, 0.35) = 0.873 이다 — 0.80 을 그으면 0.878 봉우리가
%  한계를 어긴 것처럼 보인다. 어긴 것이 아니라 안쪽 PI 가 자기 지령을 넘은 것이다
%  the two grey lines are the limits each strategy actually honours. The body-fixed
%  one is NOT u_lim 0.80 but the diagonal hypot(0.80, 0.35) = 0.873; drawing 0.80
%  would make the 0.878 peak look like a violation, which it is not -- it is the
%  inner PI overshooting its own command
yline(hypot(V.u_lim, V.v_lim), 'Color', [.4 .4 .4], 'HandleVisibility', 'off');
yline(V.v_ned_max,             'Color', [.4 .4 .4], 'HandleVisibility', 'off');
xlim([0 80]);
xlabel('time [s]'); ylabel('|U| = \surd(u^2 + v^2) [m/s]');
title('the body-fixed diagonal 0.873, the NED magnitude cap 0.350');

exportgraphics(f, fullfile(here, 'img', 'W06_result_frames.png'), 'Resolution', 150);
end
