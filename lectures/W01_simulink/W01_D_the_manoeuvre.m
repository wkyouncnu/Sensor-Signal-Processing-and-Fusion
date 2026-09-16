%% W01 · 절 D — 한 번의 기동 : 직진, 좌선회, 직진, 우선회, 직진
%  W01 · Section D — one manoeuvre: straight, port, straight, starboard, straight
%
%  실행 순서 / order of execution
%      W01_0_setup
%      W01_D_the_manoeuvre
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 D 이며, Part 1 의 §1-12 가 예고한 두 가지를 실제로 보이는
%      자리이다. 하나는 옆으로 미는 힘이 전혀 없는데도 옆 속도가 생긴다는 것이고,
%      다른 하나는 선수가 가리키는 방향과 배가 실제로 가는 방향이 다르다는 것이다.
%      뒤의 것이 크랩각이며, 4주차의 유도법칙이 정면으로 다루게 될 양이다.
%
%      This is section D of Part 2, and it demonstrates the two consequences
%      announced in §1-12 of Part 1: that a sway velocity appears although no
%      sway force is ever applied, and that the direction the bow points
%      differs from the direction the vessel travels. The second of these is
%      the crab angle, the quantity the guidance laws of Week 4 must confront.
%
%  절차 / procedure
%      1. W01_openloop.slx 를 150 s 동안 한 번 돌린다. 제어기는 없으며, 두
%         프로펠러의 회전수가 미리 정해진 시간표를 따를 뿐이다. 좌선회 구간에서는
%         왼쪽 프로펠러를 3.5 rad/s 느리게 돌리고, 우선회 구간에서는 그 반대로 한다.
%      2. 다섯 구간 각각에 대해 u, v, r 과 크랩각 beta 를 표로 낸다. 값은 각
%         구간의 마지막 5분의 1 을 평균한 것이며, 이렇게 하면 구간이 바뀔 때의
%         과도응답이 섞이지 않는다.
%      3. 궤적 그림과, 선수각과 항로각을 함께 그린 그림을 만든다.
%
%      1. Run W01_openloop.slx once for 150 s. There is no controller: the two
%         propeller speeds simply follow a schedule, the port propeller turned
%         down by 3.5 rad/s for the turn to port and the reverse for the turn
%         to starboard.
%      2. Tabulate u, v, r and the crab angle beta for each of the five
%         segments, averaged over the final fifth of the segment so that the
%         transient at each change of command is excluded.
%      3. Plot the track, and plot heading against course.
%
%  결과를 읽는 법 / how to read the result
%      - 두 프로펠러 회전수의 작은 차이만으로 선박이 선회한다. 어느 프로펠러도
%        후진하지 않는다. 요 모멘트가 N = y_pont (T_left - T_right) 이므로,
%        좌선회를 위해서는 왼쪽을 느리게 하는 것으로 충분하다.
%      - 옆으로 미는 힘 Y 는 0 인데도 옆 속도 v 는 0 이 아니다. 선회로 생긴
%        회전이 Coriolis 항을 통해 옆 방향 운동을 만들기 때문이며, §1-12 가
%        유도한 그대로이다.
%      - 선회 중에는 선수가 가리키는 방향과 실제로 나아가는 방향이 약 7° 어긋난다.
%        이 차이가 크랩각이고, 제어기가 선수각을 완벽하게 맞추더라도 남는 양이다.
%
%      - A small difference between the two propeller speeds is enough to turn
%        the vessel, and neither propeller ever runs astern. The yaw moment is
%        N = y_pont (T_left - T_right), so turning to port requires only that
%        the port propeller be slowed.
%      - The sway force Y is zero throughout, yet the sway velocity v is not.
%        The rotation set up by the turn produces lateral motion through the
%        Coriolis terms, exactly as derived in §1-12.
%      - During a turn the bow points some 7 degrees away from the direction
%        of travel. That difference is the crab angle, and it remains even
%        when the heading is controlled perfectly.
%
%  만드는 것 / what it produces
%      img/W01_result_track.png, 그리고 강의노트 §D 의 구간별 표.
%      img/W01_result_track.png and the per-segment table of section D.

clear V cfg y_p o y tp PH seg i k u v r nL nR dpsi N_cmd Ymax nn kP kS f Ls b ax
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_openloop.slx')), W01_1_build_openloop; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V   = W01_vars;
cfg = otter_config('base');
y_p = cfg.y_pont;                    % 0.395 m, half the propeller separation

o  = run_sim('W01_openloop', V);
y  = W01_read(o);
tp = V.t_phase;

PH  = {'straight   1', 'PORT turn', 'straight   2', 'STARBOARD turn', 'straight   3'};
seg = { y.t <  tp(1), ...
        y.t >= tp(1) & y.t < tp(2), ...
        y.t >= tp(2) & y.t < tp(3), ...
        y.t >= tp(3) & y.t < tp(4), ...
        y.t >= tp(4) };

%% ---- the five phases ---------------------------------------------------
%  Steady values are read from the LAST FIFTH of each phase, after the
%  transient at the phase boundary has died away. Averaging over the whole
%  phase would mix the transient into the steady number.
fprintf('\n  W01 section D — the manoeuvre, %g s, n0 = %g, dn = %g rad/s\n\n', ...
        V.T_final, V.n0, V.dn);
fprintf('    %-16s %9s %9s %10s %10s %10s %10s\n', ...
        'phase', 'n_L', 'n_R', 'u [m/s]', 'v [m/s]', 'r [deg/s]', 'beta [deg]');
fprintf('    %s\n', repmat('-', 1, 82));

for i = 1:numel(PH)
    k = last_fifth(seg{i});
    switch i
        case 2,    nL = V.n0 - V.dn;  nR = V.n0 + V.dn;
        case 4,    nL = V.n0 + V.dn;  nR = V.n0 - V.dn;
        otherwise, nL = V.n0;         nR = V.n0;
    end
    fprintf('    %-16s %9.1f %9.1f %10.4f %10.4f %10.4f %10.4f\n', PH{i}, nL, nR, ...
            mean(y.u(k)), mean(y.v(k)), mean(y.r(k)), mean(y.beta(k)));
end

dpsi = @(i) y.psi(find(seg{i}, 1, 'last')) - y.psi(find(seg{i}, 1, 'first'));
fprintf(['\n    Heading change: port %+.1f deg, starboard %+.1f deg.\n' ...
         '    The two turns are commanded with the same |dn| = %g rad/s and are\n' ...
         '    the same size to within %.2f deg, so the hull is symmetric about\n' ...
         '    its centreline and nothing in otter.m favours one side.\n'], ...
         dpsi(2), dpsi(4), V.dn, abs(abs(dpsi(2)) - abs(dpsi(4))));

N_cmd = y_p*(prop_thrust(V.n0 + V.dn, cfg) - prop_thrust(V.n0 - V.dn, cfg));
fprintf(['\n    The commanded yaw moment is N = y_p (T_left - T_right) = %+.3f N.m\n' ...
         '    in the starboard turn. Nothing reverses: the slower propeller still\n' ...
         '    pushes ahead at %.2f N while the faster one pushes at %.2f N.\n'], ...
         N_cmd, prop_thrust(V.n0 - V.dn, cfg), prop_thrust(V.n0 + V.dn, cfg));

%% ---- the empty sway row ------------------------------------------------
Ymax = 0;
for i = [1 2 4]
    switch i
        case 2,    nn = [V.n0 - V.dn; V.n0 + V.dn];
        case 4,    nn = [V.n0 + V.dn; V.n0 - V.dn];
        otherwise, nn = [V.n0; V.n0];
    end
    Ymax = max(Ymax, abs(cfg.B(2,:) * prop_thrust(nn, cfg)));
end
kP = last_fifth(seg{2});
kS = last_fifth(seg{4});

fprintf('\n  the sway row, over the whole manoeuvre\n\n');
fprintf('    max |Y| over every command in the manoeuvre   %.1e N\n', Ymax);
fprintf('    mean v in the port turn                        %+.4f m/s\n', mean(y.v(kP)));
fprintf('    mean v in the starboard turn                   %+.4f m/s\n', mean(y.v(kS)));
fprintf(['\n    Y is identically zero. Both propellers are bolted to the hull\n' ...
         '    facing forward, so no combination of them has a component across\n' ...
         '    the centreline. That is a property of the geometry, not a small\n' ...
         '    number that could be tuned away.\n' ...
         '\n    The vessel nevertheless sways in both turns, and v CHANGES SIGN\n' ...
         '    between them. That sway velocity is produced by the hull ROTATING\n' ...
         '    while it moves, through the Coriolis term in otter.m, and not by\n' ...
         '    any side force. It is the crab angle, and Week 3 has to steer\n' ...
         '    around it.\n']);

%  WITHDRAWN 2026-09-08, at the lecturer's request: the five-panel state
%  figure that used to be saved here as img/W01_result_states.png.
%
%  It drew u, v, r, psi and the track — and the live dashboard inside
%  W01_openloop.slx now draws exactly those six signals WHILE the run is in
%  progress. Saving them a second time afterwards is the same picture twice.
%  See gnc-lecture-vault/references/standing-orders.md §9-8.
%
%  `W01_plot.m` is untouched and still in use: it is the model's StopFcn.

%% ---- the figure: where it went, and where it pointed -------------------
%  Two panels. The track answers "where did it go", the angle panel answers
%  "where was it pointing while it went there" — which is the whole reason
%  the hull is drawn on the track rather than a bare line.
f = lab_fig('W01 D  track', 1150, 470);

subplot(1,2,1); hold on; axis equal;
plot(y.E, y.N, 'Color',[0 0.45 0.74]);
Ls = track_ships({[y.N y.E y.psi]}, [0 0.45 0.74], 'Marks', 14, 'Heading', 0.7);
plot(0, 0, 'ks', 'MarkerFaceColor','w');
for i = [2 4]
    plot(y.E(seg{i}), y.N(seg{i}), 'Color',[0.85 0.33 0.10], 'LineWidth',1.6);
end
xlabel('East [m]'); ylabel('North [m]');
title({'the horizontal track — turns in orange', ...
       sprintf('hull drawn at %.0f x true size', Ls/2.00)});

subplot(1,2,2); hold on;
plot(y.t, y.psi,  'Color',[0 0.45 0.74],     'DisplayName','heading \psi');
plot(y.t, y.chi,  'Color',[0.85 0.33 0.10],  'DisplayName','course \chi = \psi + \beta');
plot(y.t, y.beta, 'Color',[0.47 0.67 0.19],  'DisplayName','crab angle \beta');
yline(0, 'k:', 'HandleVisibility','off');
for b = tp, xline(b, 'Color',[0.7 0.7 0.7], 'HandleVisibility','off'); end
legend('Location','best');
xlabel('time [s]'); ylabel('angle [deg]');
title({'where it points, and where it goes', ...
       sprintf('|\\beta| reaches %.2f deg, and changes sign between the turns', ...
               max(abs(y.beta)))});

sgtitle('W01 D — where the vessel went, and where it pointed', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W01_result_track.png'), 'Resolution', 150);

fprintf('\n  figure -> img/W01_result_track.png\n\n');


% =========================================================================
function k = last_fifth(mask)
%LAST_FIFTH  The settled part of a phase: its final fifth.
idx = find(mask);
k   = false(size(mask));
if isempty(idx), return; end
k(idx(max(1, round(0.8*numel(idx))):end)) = true;
end
