%% W05 · 절 C — 한 점을 겨냥하는 것은 경로를 따라가는 것이 아니다
%  W05 · Section C — aiming at a point is not following a path
%
%  실행 순서 / order of execution
%      W05_0_setup
%      W05_C_aim_at_the_waypoint
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 C 이며 §5-1 과 짝을 이룬다. 유도법칙을 처음 만들 때 누구나
%      떠올리는 방법을 먼저 만들어 보고, 그것이 왜 부족한지를 측정으로 보인다.
%      실패하는 방법을 먼저 보아야 다음 방법이 무엇을 고치는 것인지 알 수 있다.
%
%      This is section C of Part 2, the counterpart of §5-1. The law anyone
%      would think of first is built and then measured, to show where it falls
%      short. Seeing the method that fails is what makes it possible to say
%      what the next method repairs.
%
%  무엇을 만드는가 / the law being tested
%      선수를 다음 웨이포인트로 향하게 한다.
%      Point the bow at the next waypoint:
%
%          psi_d = atan2(y_wp - y, x_wp - x)
%
%  결과를 읽는 법 / how to read the result
%      이 법칙은 웨이포인트를 모두 지나간다. 그러나 웨이포인트 사이의 선분은
%      한 번도 따라가지 못한다. 조류가 있으면 더 벌어진다. 겨냥하는 목표가
%      경로 위의 점이 아니라 경로의 끝점이기 때문이며, 끝점을 향해 가는 동안
%      배는 경로에서 얼마나 떨어져 있든 상관하지 않는다.
%
%      The law reaches every waypoint and never once follows the line between
%      them, and a current widens the gap further. What it aims at is the end
%      of the path rather than a point on it, and while heading for an end
%      point the vessel is indifferent to how far from the path it is.
%
%  만드는 것 / what it produces
%      표 하나와 img/W05_result_atan2.png
%      One table and img/W05_result_atan2.png

clear V o y k i f COL leg
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W05_guidance.slx')), W05_1_build_guidance; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W05_vars;
o = run_sim('W05_guidance', V);
y = W05_read(o);

%% ---- what atan2 does, leg by leg --------------------------------------
%  Measured over the LAST THIRD of each leg, so the number describes steady
%  tracking on that leg and not the turn onto it.
%  기호는 강의와 같게 쓴다: NED 좌표는 x^n, y^n 이다 (W01 1-1 의 표기 규약).
%  MATLAB 식별자에는 위첨자를 못 쓰므로 로그의 필드 이름만 N, E 로 남는다.
fprintf('\n  W05 section C — psi_d = atan2(yn_next - yn, xn_next - xn)\n\n');
fprintf('    %-6s %14s %14s %14s %14s\n', ...
        'leg', 'atan2 |y_e|', 'LOS |y_e|', 'atan2 max', 'ratio');
fprintf('    %s\n', repmat('-', 1, 70));

for leg = 1:size(V.WP,1)-1
    k = leg_window(y.wp(:,1), leg);
    if ~any(k), continue, end
    a = mean(abs(y.y_e(k,1)));
    b = mean(abs(y.y_e(k,2)));
    %  Leg 1 starts ON the path heading along it, so both errors are zero and
    %  the ratio is meaningless rather than large. Say so instead of printing
    %  a NaN that a reader has to interpret.
    if b < 1e-6
        r = '     both zero';
    else
        r = sprintf('%14.1f', a/b);
    end
    fprintf('    %-6d %14.3f %14.3f %14.3f %s\n', ...
            leg, a, b, max(abs(y.y_e(k,1))), r);
end

fprintf(['\n    atan2 REACHES every waypoint and never follows the line to it.\n' ...
         '    The law regulates the distance to a POINT, and a point does not\n' ...
         '    know about the line it sits on. Pushed off the path - by a corner\n' ...
         '    here, by a current in section G - the vessel simply approaches\n' ...
         '    the waypoint from wherever it happens to be, along a curve.\n' ...
         '\n    LOS on the same legs is %.0f times closer to the path.\n' ...
         '    Both vessels visit the same waypoints. Only one follows the path.\n'], ...
         mean(abs(y.y_e(y.t>150,1)))/mean(abs(y.y_e(y.t>150,2))));

%% ---- the figure --------------------------------------------------------
f = W05_plot(y, V, 'W05 C — atan2 visits the waypoints; LOS follows the path', [1 2]);
exportgraphics(f, fullfile(here,'img','W05_result_atan2.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W05_result_atan2.png\n\n');


% =========================================================================
function k = leg_window(wp, leg)
%LEG_WINDOW  The last third of the time spent on one leg.
idx = find(round(wp) == leg);
k   = false(size(wp));
if isempty(idx), return, end
k(idx(max(1, round(0.67*numel(idx))):end)) = true;
end
