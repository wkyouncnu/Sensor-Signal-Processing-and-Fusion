%% W06 · 실험 6-3 — 고리 셋으로 한 점을 잡는다 / Experiment 6-3 — holding a point with three loops
%
%  이 절이 묻는 것 / the question
%      위치 오차를 바로 추력으로 바꾸지 않는다. 위치 P 가 **속도 요구**를 내고,
%      속도 PI 가 그 속도를 지키고, 선수각 P-D 가 따로 선수를 잡는다. 고리를
%      셋으로 나누면 무엇이 달라지는가? 그리고 그 셋을 그대로 둔 채 **선수추진기
%      하나만** 없애면 배는 어디까지 할 수 있는가?
%      The position error is not turned into thrust directly: an outer P loop
%      asks for a VELOCITY, an inner PI loop holds that velocity, and a separate
%      P-D loop holds the heading. This section runs the cascade to a point, and
%      then runs it again with the bow thruster removed and nothing else changed.
%
%  이 스크립트가 하는 일 / what this script does
%      ① W06_F_position 을 목표 (10, 10) m · 선수각 0 도로 돌린다.
%      ② 같은 게인 그대로 F_B_max = 0 으로 한 번 더 돌린다 — 저구동 선체다.
%      ③ 도착 시각 · 남은 거리 · 선수각 오차 · 최대 횡속도를 표로 낸다.
%      ① Runs W06_F_position to the point (10, 10) m with the heading held at 0.
%      ② Runs it again with F_B_max = 0 and every gain unchanged: the hull is
%         then the under-actuated one of Week 5.
%      ③ Tables the arrival time, the distance left, the heading error and the
%         largest sway speed.
%
%  출력에서 볼 것 / what to look for in the output
%      - 추진기 셋이면 42.68 초에 0.5 m 안에 들고, 끝에서 **0.000 m** 에 선다.
%        선수각 오차는 -0.00 도다. 위치와 선수각을 **동시에** 지킨 것이다.
%      - 선수추진기를 끄면 0.5 m 안에 **영영 들어오지 못하고** 14.827 m 를 남긴다.
%        게인은 한 자리도 바꾸지 않았다.
%      - 남은 거리가 왜 하필 15 m 쯤인가. 출발 (0, 25) 에서 목표 (10, 10) 까지는
%        북으로 10 m, 서로 15 m 다. 선수각을 0 으로 묶어 두었으므로 전진이 갈 수
%        있는 곳은 북쪽뿐이다 — 북 10 m 는 메우고 서 15 m 는 그대로 남는다.
%      - 그런데도 선수각이 10.37 도 틀어진다. 횡력 요구는 두 경우 모두 35.13 N 으로
%        **같다.** 배분기는 그 요구를 보고 선수가 낼 힘의 모멘트를 선미 둘로 미리
%        지워 두는데, F_B 가 0 으로 잘려 **만들지 않은 힘의 모멘트를 지운** 셈이
%        된다. 그 지운 양이 그대로 선회로 샌다 — 6-2 절과 같은 누출이다.
%      - 왼쪽 그림에서 선체 표시는 전부 북쪽을 보는데 배는 북서로 간다. 그 어긋남이
%        옆걸음이고, 저구동 선체에는 없는 것이다.
%      - With three thrusters the hull is inside 0.5 m at 42.68 s and stops 0.000 m
%        from the target with a heading error of -0.00 deg: position and heading
%        are held at the same time.
%      - With the bow unit off it NEVER reaches 0.5 m and gives up 14.827 m away,
%        with no gain changed by a single digit.
%      - Why about 15 m. From (0, 25) to (10, 10) is 10 m north and 15 m west.
%        The heading is pinned at 0, so surge can only go north: the 10 m closes
%        and the 15 m stays.
%      - The heading still swings 10.37 deg. The sway demand is 35.13 N in BOTH
%        cases. The allocation cancels, with the stern pair, the moment the bow
%        force would have brought; with F_B clipped to zero it has cancelled the
%        moment of a force that was never made, and that cancellation leaks
%        straight into yaw. It is the leak of Section 6-2.
%      - In the left figure every hull mark faces north while the boat travels
%        north-west. That mismatch is the sideways motion an under-actuated hull
%        does not have.
%
%  만드는 것 / produces: img/W06_result_hold.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

V = W06_vars();
p_d = [10 10];                 % 목표 [N, E] / the target

%% 1) 같은 고리, 추진기만 둘과 셋 / the same loops, three thrusters and then two
%  넷째 칸은 궤적 위에 세울 선체 수다. 선수추진기를 끈 쪽은 거의 움직이지 않아
%  다섯을 세우면 서로 겹쳐 궤적선을 덮는다 / the fourth column is how many hulls to
%  draw on the track: the bow-off case barely moves, and five marks there pile up
C = {'three thrusters', V.F_B_max, [0 0.45 0.74], 5
     'bow unit off',    0,         [0.85 0.33 0.10], 3};
fprintf('\n  W06 Experiment 6-3  holding the point (%g, %g) m, heading 0 deg\n', p_d);
fprintf('    case               t to 0.5 m [s]   d(end) [m]   psi error [deg]   max |v| [m/s]   max |Y| [N]\n');
Rs = cell(size(C,1), 1);
for i = 1:size(C,1)
    Rs{i} = W06_read('W06_F_position', 'N_d', p_d(1), 'E_d', p_d(2), ...
                     'psi_d_cmd', 0, 'F_B_max', C{i,2}, 'T_final', 120);
    R = Rs{i};
    k = find(R.d < 0.5, 1);                       % 처음으로 0.5 m 안에 든 때
    t_in = NaN;  if ~isempty(k), t_in = R.t(k); end
    fprintf('    %-16s   %12.2f   %10.3f   %15.2f   %13.3f   %11.2f\n', ...
            C{i,1}, t_in, R.d(end), R.psi(end) - R.psi_set(end), ...
            max(abs(R.v)), max(abs(R.Y_dem)));
end

%% 2) 궤적 · 거리 · 선수각 / the track, the distance and the heading
f = lab_fig('W06 E  holding a point', 1180, 380);
subplot(1,3,1); hold on; grid on; axis equal;
for i = 1:size(C,1)
    R = Rs{i};
    plot(R.E, R.N, 'Color', C{i,3}, 'LineWidth', 1.3);
    track_ships({[R.N R.E R.psi*pi/180]}, C{i,3}, 'Marks', C{i,4});
end
plot(p_d(2), p_d(1), 'kp', 'MarkerSize', 13, 'MarkerFaceColor', [1 0.85 0.2]);
xlabel('east [m]'); ylabel('north [m]'); title('track, with the target marked');

subplot(1,3,2); hold on; grid on;
for i = 1:size(C,1), plot(Rs{i}.t, Rs{i}.d, 'Color', C{i,3}, 'LineWidth', 1.3); end
yline(0.5, 'Color', [.4 .4 .4], 'HandleVisibility', 'off');
xlabel('time [s]'); ylabel('distance to the target [m]');
title('how the distance closes'); legend(C(:,1), 'Location', 'northeast');

subplot(1,3,3); hold on; grid on;
for i = 1:size(C,1), plot(Rs{i}.t, Rs{i}.psi, 'Color', C{i,3}, 'LineWidth', 1.3); end
yline(0, 'Color', [.4 .4 .4], 'HandleVisibility', 'off');
xlabel('time [s]'); ylabel('\psi [deg]'); title('the heading that was asked to stay at 0');

%% 3) 그림을 저장한다 / save the figure
exportgraphics(f, fullfile(here, 'img', 'W06_result_hold.png'), 'Resolution', 150);
