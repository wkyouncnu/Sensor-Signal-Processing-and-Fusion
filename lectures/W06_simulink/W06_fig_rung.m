function W06_fig_rung(R, row, V, here)
%W06_FIG_RUNG  사다리 한 단의 그림 여섯 칸 / one rung of the ladder, in six panels.
%
%   W06_fig_rung(R, row, V, here)
%
%   row  = {단번호, 이름, 모델, 절, 목표}  —  W06_J_ladder 의 L 한 줄
%          {rung, name, model, section, target}, one row of the ladder
%
%   칸 여섯은 **모든 단이 같다.** 그래야 단과 단을 겹쳐 보지 않고 나란히 놓고
%   볼 수 있다 — 같은 자리에 같은 양이 있으므로 눈이 옮겨 다니지 않는다.
%   The six panels are the same on every rung, so the rungs can be read side by
%   side: the same quantity sits in the same place and the eye does not hunt.
%
%       (a) 항적 전체        the whole track, with the hull drawn along it
%       (b) 위치 오차        the position error, north and east and the distance
%       (c) 선수각 추종      the heading, its command and the error between them
%       (d) 목표 둘레 확대   the target at ship scale -- the only panel in metres
%                            small enough to see the hull
%       (e) 속도             u and v on the left axis, r on the right
%       (f) 추력 셋          the three thrusts against the ceilings of 6-2
%
%   목표가 없는 단(열린 루프)은 (b)·(d) 가 오차 대신 **위치 그 자체**를 그린다.
%   A rung with no target -- the open-loop one -- draws the position itself in
%   (b) and (d) instead of an error, because there is nothing to take it from.
%
%   See also W06_J_LADDER, W06_FIG_LADDER, TRACK_SHIPS, DRAW_SHIP.

k    = row{1};                       % 단 번호 / the rung number
name = row{2};
tgt  = row{5};                       % [N E psi(deg)]
has  = ~any(isnan(tgt));             % 목표가 있는 단인가 / is there a target
c1 = [0.00 0.45 0.74];  c2 = [0.85 0.33 0.10];  c3 = [0.47 0.67 0.19];
cg = [0.45 0.45 0.45];
ccm = [0.75 0.10 0.10];              % 명령 / the command, as in W06_plot·W06_animate

f = lab_fig(sprintf('W06 rung %d  %s', k, name), 1280, 760);
tiledlayout(f, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

%% (a) 항적 전체 / the whole track
nexttile; hold on; grid on; axis equal;
%  접안 가구는 접안하는 단에만 그린다 — W06_animate 와 같은 기준(phase > 0)이다.
%  접안하지 않는 단에 안벽을 그려 두면 그림이 뜻 없는 자국 하나를 더 갖는다
%  the berth furniture is drawn only on a rung that berths, by the same test the
%  live view uses; a quay on a rung that never docks is one more mark that means nothing
berths = ~all(isnan(R.phase)) && any(R.phase > 0);
if berths
    fill([V.quay_E V.track_Emin V.track_Emin V.quay_E], ...
         [V.track_Nmin V.track_Nmin V.track_Nmax V.track_Nmax], [.86 .86 .86], ...
         'EdgeColor', cg, 'HandleVisibility', 'off');
    text(V.track_Emin + 0.4, V.track_Nmax - 3, 'quay', 'Color', cg, 'FontSize', 8);
end
plot(R.E, R.N, 'Color', c1, 'LineWidth', 1.4, 'DisplayName', 'track');
track_ships({[R.N R.E R.psi]}, c1, 'Marks', 7);
plot(R.E(1), R.N(1), 'ko', 'MarkerFaceColor', 'w', 'DisplayName', 'start');
if has
    plot([R.E(1) tgt(2)], [R.N(1) tgt(1)], ':', 'Color', cg, 'DisplayName', 'straight line');
    plot(tgt(2), tgt(1), 'kp', 'MarkerSize', 13, 'MarkerFaceColor', [1 .85 .2], ...
         'DisplayName', 'target');
end
if berths
    plot(V.app_E, V.app_N, 'ks', 'MarkerSize', 8, 'MarkerFaceColor', [.7 .9 1], ...
         'DisplayName', 'approach point');
end
plot(R.E(end), R.N(end), 'kd', 'MarkerSize', 8, 'MarkerFaceColor', c2, ...
     'DisplayName', 'end');
xlim([V.track_Emin V.track_Emax]); ylim([V.track_Nmin V.track_Nmax]);
xlabel('east [m]'); ylabel('north [m]');
title(sprintf('(a) the track,  %.2f m travelled', sum(hypot(diff(R.N), diff(R.E)))));
%  단마다 항적이 있는 사분면이 다르다. 자리를 고정하면 범례가 항적 위에 앉는다
%  the track sits in a different quadrant on every rung, so a fixed corner puts
%  the legend on top of it
legend('Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

%% (b) 위치 오차 / the position error
nexttile; hold on; grid on;
if has
    plot(R.t, tgt(1) - R.N, 'Color', c1, 'LineWidth', 1.2, 'DisplayName', 'north error');
    plot(R.t, tgt(2) - R.E, 'Color', c2, 'LineWidth', 1.2, 'DisplayName', 'east error');
    plot(R.t, R.d,          'Color', c3, 'LineWidth', 1.4, 'DisplayName', 'distance');
    yline(V.R_berth, '--', 'R_{berth}', 'Color', cg, 'HandleVisibility', 'off');
    ttl = sprintf('(b) the error closing,  %.3f m at the end', R.d(end));
else
    plot(R.t, R.N, 'Color', c1, 'LineWidth', 1.2, 'DisplayName', 'north');
    plot(R.t, R.E, 'Color', c2, 'LineWidth', 1.2, 'DisplayName', 'east');
    ttl = '(b) the position itself,  no target on this rung';
end
xlabel('time [s]'); ylabel('[m]'); title(ttl);
legend('Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

%% (c) 선수각 추종 / the heading
nexttile; hold on; grid on;
%  명령 대 실제. 이 주의 규칙은 하나다 — **붉은 점선이 명령, 푸른 실선이 실제**
%  이고, 명령을 **나중에** 그린다. 먼저 그리면 잘 따라간 구간에서 실선이 점선을
%  덮어 명령이 사라지고, 그 구간이 바로 보여야 할 곳이다.
%  one rule for the week: the command is the red dashed line, the actual the blue
%  solid one, and the command is drawn LAST. Drawn first it disappears under the
%  solid exactly where the tracking is good, which is the part worth seeing.
e_psi = R.psi - R.psi_set;
has_c = ~all(isnan(R.psi_set));          % 열린 루프 단에는 선수각 명령이 없다
plot(R.t, R.psi,           'Color', c1,  'LineWidth', 1.4, 'DisplayName', '\psi  actual');
if has_c
    plot(R.t, e_psi,     ':',  'Color', cg,  'LineWidth', 1.2, 'DisplayName', 'error');
    plot(R.t, R.psi_set, '--', 'Color', ccm, 'LineWidth', 1.3, 'DisplayName', '\psi_{set}  commanded');
end
yline(0, 'Color', [.8 .8 .8], 'HandleVisibility', 'off');
tail = R.t >= R.t(end) - 10;
xlabel('time [s]'); ylabel('[deg]');
if has_c
    title(sprintf('(c) the heading,  |error| %.2f deg over the last 10 s', ...
                  mean(abs(e_psi(tail)), 'omitnan')));
else
    title('(c) the heading,  no command on this rung');
end
legend('Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

%% (d) 목표 둘레 확대 / the target, at ship scale
nexttile; hold on; grid on; axis equal;
if has, cN = tgt(1); cE = tgt(2); else, cN = R.N(end); cE = R.E(end); end
w = 6;
if V.quay_E > cE - w
    fill([V.quay_E cE-w cE-w V.quay_E], [cN-w cN-w cN+w cN+w], [.86 .86 .86], ...
         'EdgeColor', cg, 'HandleVisibility', 'off');
end
plot(R.E, R.N, 'Color', c1, 'LineWidth', 1.0, 'HandleVisibility', 'off');
hs = gobjects(0); lb = {};
if has
    hT = draw_ship(gca, tgt(1), tgt(2), deg2rad(tgt(3)), 2.0, [.6 .6 .6], 'FaceAlpha', 0.35);
    set(hT.head, 'HandleVisibility', 'off');
    hs(end+1) = hT.hull;  lb{end+1} = 'the attitude asked for';
end
hE = draw_ship(gca, R.N(end), R.E(end), deg2rad(R.psi(end)), 2.0, c2, 'FaceAlpha', 0.70);
set(hE.head, 'HandleVisibility', 'off');
hs(end+1) = hE.hull;  lb{end+1} = 'the attitude reached';
xlim([cE-w cE+w]); ylim([cN-w cN+w]);
xlabel('east [m]'); ylabel('north [m]');
if has
    title(sprintf('(d) the target at ship scale,  %.3f m and %.2f deg off', ...
                  R.d(end), e_psi(end)));
else
    title('(d) where the hull ended up, at ship scale');
end
legend(hs, lb, 'Location', 'southeast', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

%% (e) 속도 — 명령과 실제 / the speeds, commanded against actual
nexttile; hold on; grid on;
yyaxis left
%  한 축에 짝이 **둘**이므로 색이 둘이고(u 파랑, v 주황), 점선이 명령이다.
%  u_d · v_d 는 **바깥 위치 고리의 출력**이라 이 칸이 종속 고리가 그것을 따라가는지
%  보여 주는 자리다. 명령을 **나중에** 그린다 — 잘 따라간 구간에서 실선에 덮인다
%  two pairs on one axis, so one colour each and the dash tells command from
%  actual. u_d and v_d are the outer position loop's output, which makes this the
%  panel where the inner loop is seen following it; the commands are drawn LAST
plot(R.t, R.u, '-', 'Color', c1, 'LineWidth', 1.3, 'DisplayName', 'u');
plot(R.t, R.v, '-', 'Color', c2, 'LineWidth', 1.3, 'DisplayName', 'v');
%  열린 루프 단에는 명령이 없다 (NaN). 그리면 범례에 **빈 항목**이 선다
%  the open-loop rung has no command at all: plotting it would put two empty
%  entries in the legend, which is a mark that means nothing
if ~all(isnan(R.u_d))
    plot(R.t, R.u_d, '--', 'Color', c1, 'LineWidth', 1.1, 'DisplayName', 'u_d  commanded');
    plot(R.t, R.v_d, '--', 'Color', c2, 'LineWidth', 1.1, 'DisplayName', 'v_d  commanded');
end
ylabel('u, v [m/s]'); set(gca, 'YColor', 'k');
yyaxis right
plot(R.t, rad2deg(R.r), '-', 'Color', c3, 'LineWidth', 1.1, 'DisplayName', 'r');
ylabel('r [deg/s]'); set(gca, 'YColor', c3);
xlabel('time [s]');
%  꼬리만 센다. t = 0 의 차는 명령이 한 번에 뛰고 선체가 아직 서 있는 것이므로
%  추종 오차가 아니다 / the difference at t = 0 is the step itself, not a lag
gd = R.t > 1 & ~isnan(R.u_d) & ~isnan(R.v_d);
ttl = sprintf('(e) the speeds,  |u| %.3f  |v| %.3f m/s  |r| %.2f deg/s', ...
              max(abs(R.u)), max(abs(R.v)), rad2deg(max(abs(R.r))));
if any(gd)
    ttl = {ttl, sprintf('the inner loop follows:  |u-u_d| %.4f,  |v-v_d| %.4f m/s after 1 s', ...
                        mean(abs(R.u(gd) - R.u_d(gd))), mean(abs(R.v(gd) - R.v_d(gd))))};
end
title(ttl);
legend('Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

%% (f) 추력 셋 / the three thrusts, against the ceilings of 6-2
nexttile; hold on; grid on;
plot(R.t, R.T_L, 'Color', c1, 'LineWidth', 1.1, 'DisplayName', 'T_L');
plot(R.t, R.T_R, 'Color', c2, 'LineWidth', 1.1, 'DisplayName', 'T_R');
plot(R.t, R.F_B, 'Color', c3, 'LineWidth', 1.4, 'DisplayName', 'F_B');
yline( V.T_max,   ':', 'T_{max}',   'Color', cg, 'HandleVisibility', 'off');
yline( V.T_min,   ':', 'T_{min}',   'Color', cg, 'HandleVisibility', 'off');
yline( V.F_B_max, '--', 'F_{B,max}', 'Color', c3, 'HandleVisibility', 'off');
yline(-V.F_B_max, '--',              'Color', c3, 'HandleVisibility', 'off');
ylim([V.T_min - 15, V.T_max + 15]);     % 모든 단이 같은 눈금 / one scale for every rung
xlabel('time [s]'); ylabel('thrust [N]');
title(sprintf('(f) the three thrusts,  peaks %.1f / %.1f / %.1f N', ...
              max(abs(R.T_L)), max(abs(R.T_R)), max(abs(R.F_B))));
legend('Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

exportgraphics(f, fullfile(here, 'img', sprintf('W06_r%d_%s.png', k, name)), ...
               'Resolution', 150);
end
