function W06_plot()
%W06_PLOT  Run 을 누르면 이것이 돈다 — 절 스크립트와 같은 그림을 그린다.
%          Called when Run finishes: draws what the section scripts draw.
%
%   모델의 StopFcn 이 이 함수를 부른다 (W06_1_build_bow). 그래서 **시뮬링크만
%   돌려도** 항적과 수치가 나온다. 절 스크립트는 같은 것을 여러 값에 대해 할 뿐이다.
%   The model's StopFcn calls this, so running Simulink alone produces the track
%   and the numbers; the section scripts only do the same for several values.
%
%   그리는 것 / what it draws
%       왼쪽   항적 — 부두선·접근점·접안점·선체와 선수 방향
%       오른쪽 ① 목표까지의 거리 d  ② 명령 선수각과 선수각  ③ u 와 v
%              ④ 요구 힘 X · Y 와 **한계선**  ⑤ 좌현·우현 축 회전수와 선수추진기
%              ⑥ 임무 단계
%
%   왜 u 와 v 를 **한 축에** 놓는가
%
%   이 주차의 요점은 **옆으로 가는 것**이다. 두 속도를 따로 그리면 축이 저마다
%   늘어나서 "전진보다 횡이동이 느리다" 가 보이지 않는다. 같은 축에 놓으면
%   v 가 u 보다 작은 것이 그림에서 바로 읽히고, 그 비는 6-6 절이 센 것과 같다.
%   This week is about moving sideways. On separate axes each scales to itself and
%   the point is lost; on one axis the sway speed is visibly the smaller, in the
%   ratio Section 6-6 measures.
%
%   한계선 / the limit lines
%
%   ④ 의 점선은 X_max 와 Y_max 다. Y_max 가 X_max 의 1/3 이 못 되는 것이 그림의
%   한 자리에서 보여야 한다 — 그것이 6-2 절의 결론이고, 횡방향 적분기가 금방
%   쌓이는 이유다.
%   The dashed lines in panel 4 are X_max and Y_max. That Y_max is under a third
%   of X_max has to be visible in one place: it is the conclusion of Section 6-2
%   and the reason the sway integrator fills so quickly.
%
%   범례 / the legends
%       단계가 바뀌는 시각을 긋는 세로선에는 `HandleVisibility','off'` 를 준다.
%       주지 않으면 범례에 data1, data2 가 딸려 들어온다 (5주차에서 실제로 그랬다).
%       The phase lines carry HandleVisibility off; without it they enter the
%       legend as data1, data2, which is what happened in Week 5.
%
%   See also W06_READ, W06_ANIMATE, W06_1_BUILD_BOW.

%  절 스크립트(W06_read)가 돌리는 중이면 아무것도 하지 않는다. 그때의 로그는 `out`
%  안에 있고 기본 작업공간의 W06 은 **직전 Run 이 남긴 낡은 것**이다.
%  Do nothing while a section script runs: its log lives inside `out`, and the
%  base-workspace W06 is then whatever the last manual Run left behind.
if evalin('base', 'exist(''W06batch'', ''var'')'), return; end
if evalin('base', '~exist(''W06'', ''var'')'), return; end
L = evalin('base', 'W06');
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = L.time;

%  열 순서는 W06_read 와 **같다** — 둘 다 `add_measurement` 이 정한 것을 받아
%  쓴다. 이름을 두 번 쓰는 셈이지만, StopFcn 은 `out` 없이 돌아야 하므로
%  W06_read 를 부를 수 없다. 둘이 어긋나면 verify 가 잡는다.
%  The order is the one W06_read names, and both take it from add_measurement.
%  It is written twice because a StopFcn runs without an `out` object and so
%  cannot call W06_read; the verify script compares the two.
%
%  psi 와 psi_set 은 **도**로 들어온다 / psi and psi_set arrive in DEGREES
u     = y(:, 1);  v     = y(:, 2);  r       = y(:, 3);
N     = y(:, 4);  E     = y(:, 5);  psi     = y(:, 6);
N_set = y(:, 7);  E_set = y(:, 8);  psi_set = y(:, 9);
X_dem = y(:,10);  Y_dem = y(:,11);  N_dem   = y(:,12);
n_L   = y(:,13);  n_R   = y(:,14);  F_B     = y(:,15);
d     = y(:,16);  phase = y(:,17);
%  바깥 위치 고리가 지시한 속도. 늘 **몸체 축**이므로 u·v 와 한 축에 놓인다
%  what the outer position loop asked for, always in body axes, so it shares an
%  axis with u and v
u_d   = y(:,18);  v_d   = y(:,19);

X_max = base_var('X_max', 120);
Y_max = base_var('Y_max', 35.13);
quay_E = base_var('quay_E', 0);

%  track_ships 는 psi 를 **도**로 받는다 — 안에서 deg2rad 한 뒤 라디안을 받는
%  draw_ship 에 넘긴다. add_measurement 는 psi 행에만 180/pi 를 걸므로 로그의
%  psi 는 이미 도다. 그대로 넘긴다 / track_ships takes psi in DEGREES and
%  converts internally; the logged psi is already in degrees

%  단계가 바뀐 시각. 단계가 없는 모델에서는 빈 벡터다 / when the phase changed
ph = t([false; diff(phase) ~= 0]);

%% 1) 수치 / the numbers
fprintf('\n  %s  —  %g s\n', get_param(bdroot, 'Name'), t(end));
if any(isfinite(N_set))
    eN = N(end) - N_set(end);  eE = E(end) - E_set(end);
    fprintf('    final position error   %6.3f m north, %6.3f m east   (%.3f m away)\n', ...
            eN, eE, hypot(eN, eE));
end
if any(isfinite(psi_set))
    fprintf('    final heading error    %6.2f deg\n', ...
            ssa_deg(psi(end) - psi_set(end)));
end
fprintf('    final speeds           u = %6.3f, v = %6.3f m/s,  r = %6.3f deg/s\n', ...
        u(end), v(end), r(end)*180/pi);
fprintf('    peak sway speed        %6.3f m/s\n', max(abs(v)));
%  안쪽 고리가 바깥 고리의 명령을 따라갔는가. 포화에 걸린 구간에서는 이 값이
%  커지는 것이 **옳다** — 명령이 힘의 한계를 넘었다는 뜻이다
%  did the inner loop follow the outer one; this grows while the demand is
%  clipped, and that is correct -- the command then exceeds what the force can do
if any(isfinite(u_d))
    fprintf('    inner loop follows     |u - u_d| %6.3f, |v - v_d| %6.3f m/s on average\n', ...
            mean(abs(u - u_d), 'omitnan'), mean(abs(v - v_d), 'omitnan'));
end
%  포화에 걸려 있던 시간의 비. 이것이 횡방향에서 크면 안티와인드업이 일을 한다
%  the fraction of the run spent saturated; large on sway means anti-windup works
fprintf('    saturated  X %5.1f %% of the run,  Y %5.1f %%\n', ...
        100*mean(abs(abs(X_dem) - X_max) < 1e-6), ...
        100*mean(abs(abs(Y_dem) - Y_max) < 1e-6));
fprintf('    peak demand            X = %7.2f N, Y = %7.2f N, N = %7.2f N m\n', ...
        max(abs(X_dem)), max(abs(Y_dem)), max(abs(N_dem)));
fprintf('    peak bow force         F_B = %6.2f N\n', max(abs(F_B)));
if ~isempty(ph)
    fprintf('    phase changed at %s s\n', strjoin(compose('%.1f', ph(:).'), ', '));
end

%% 2) 그림 / the figure
lab_fig(sprintf('%s  —  Run', get_param(bdroot,'Name')), 1150, 720);

%  왼쪽: 항적 / left: the track
subplot(1,2,1); hold on; grid on; axis equal;
%  부두. 선체가 이 선을 **넘지 않아야** 한다 / the quay; the hull must not cross it
yl = [min(N)-6, max(N)+6];
plot([quay_E quay_E], yl, 'Color', [0.35 0.25 0.15], 'LineWidth', 3);
if any(isfinite(N_set))
    plot(E_set, N_set, '--', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.1);
    plot(E_set(end), N_set(end), 'p', 'MarkerSize', 13, ...
         'MarkerEdgeColor', [0.75 0.10 0.10], 'MarkerFaceColor', [0.95 0.75 0.75]);
end
plot(E, N, 'Color', [0 0.45 0.74], 'LineWidth', 1.3);
track_ships({[N E psi]}, [0 0.45 0.74], 'Marks', 12);
xlabel('east [m]');  ylabel('north [m]');
title({'the track, with the hull and its heading', ...
       '\color[rgb]{0.35,0.25,0.15}\bfthe quay is the thick line at E = 0'});

LBL = {'d  [m]', '\psi_{set} , \psi  [deg]', 'u , v  [m/s]', ...
       'X , Y  [N]', 'n_L , n_R  [rad/s]', 'phase'};
for i = 1:6
    ax = subplot(6,2,2*i); hold on; grid on;
    switch i
        case 1
            if any(isfinite(d))
                plot(t, d, 'LineWidth', 1.2);
                yline(base_var('R_berth', 0.40), ':', 'Color', [.55 .55 .55], ...
                      'HandleVisibility','off');
            else
                %  거리가 없는 모델(열린 루프)에서는 위치 둘을 그린다 — 빈 축을
                %  남기지 않는다 / an open-loop model has no distance: plot the
                %  two positions instead of leaving the axis empty
                plot(t, N, 'LineWidth', 1.2, 'DisplayName', 'north');
                plot(t, E, 'LineWidth', 1.2, 'DisplayName', 'east');
                legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7);
                ylabel(ax, 'N , E  [m]');
            end
        case 2
            %  **명령을 나중에 그린다.** 먼저 그리면 잘 따라간 구간에서 실선이
            %  점선을 덮어 명령이 사라지고, 학생은 "명령이 안 보인다" 고 한다.
            %  나중에 그리면 점선이 실선 위에 올라타 둘이 함께 보인다
            %  the command is drawn LAST: drawn first it disappears under the
            %  solid line wherever tracking is good, which is most of the run
            plot(t, psi, 'Color', [0 0.45 0.74], 'LineWidth', 1.3, ...
                 'DisplayName', '\psi  actual');
            if any(isfinite(psi_set))
                plot(t, psi_set, '--', 'Color', [0.75 0.10 0.10], ...
                     'LineWidth', 1.2, 'DisplayName', '\psi_{set}  commanded');
            end
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7, ...
                   'Box', 'off', 'Color', 'none');
        case 3
            %  **점선이 명령, 실선이 실제**다. 한 축에 쌍이 **둘**이므로 명령을
            %  붉게 두면 두 명령이 같은 색이 되어 어느 쌍인지 알 수 없다. 그래서
            %  이 칸만 **쌍마다 한 색**이고 점선과 실선으로 가른다 — 쌍이 하나인
            %  칸(② 선수각)은 붉은 점선 대 푸른 실선이다. 여기서도 명령이 나중이다
            %  two pairs share this axis, so a single command colour would make
            %  the two commands identical; this panel pairs BY COLOUR and tells
            %  command from actual by the dash. A panel with one pair uses red
            %  against blue instead. The command is drawn last here too
            cu = [0 0.45 0.74];  cv = [0.85 0.33 0.10];
            plot(t, u, 'Color', cu, 'LineWidth', 1.3, 'DisplayName', 'u  surge');
            plot(t, v, 'Color', cv, 'LineWidth', 1.3, 'DisplayName', 'v  sway');
            if any(isfinite(u_d))
                plot(t, u_d, '--', 'Color', cu, 'LineWidth', 1.1, ...
                     'DisplayName', 'u_d  outer loop');
            end
            if any(isfinite(v_d))
                plot(t, v_d, '--', 'Color', cv, 'LineWidth', 1.1, ...
                     'DisplayName', 'v_d  outer loop');
            end
            yline(0, 'k:', 'HandleVisibility','off');
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7, ...
                   'Box', 'off', 'Color', 'none');
        case 4
            plot(t, X_dem, 'LineWidth', 1.2, 'DisplayName', 'X  surge force');
            plot(t, Y_dem, 'LineWidth', 1.2, 'DisplayName', 'Y  sway force');
            %  한계선. 6-2 절이 센 두 값이다 / the limits Section 6-2 measures
            for s = [X_max -X_max]
                yline(s, '--', 'Color', [0 0.45 0.74], 'HandleVisibility','off');
            end
            for s = [Y_max -Y_max]
                yline(s, '--', 'Color', [0.85 0.33 0.10], 'HandleVisibility','off');
            end
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7);
        case 5
            plot(t, n_L, 'LineWidth', 1.1, 'DisplayName', 'n_L  port');
            plot(t, n_R, 'LineWidth', 1.1, 'DisplayName', 'n_R  starboard');
            yline(0, 'k:', 'HandleVisibility','off');
            legend(ax, 'Location','best', 'AutoUpdate','off', 'FontSize', 7);
        case 6
            %  단계와 선수추진기를 함께. 둘 다 이 주차에만 있는 것이다
            %  the phase and the bow force together: both are new this week
            yyaxis left;   stairs(t, phase, 'LineWidth', 1.4);
            ylim([-0.5 max(4, max(phase))+0.5]);  ylabel('phase');
            yyaxis right;  plot(t, F_B, 'LineWidth', 1.2);
            ylabel('F_B  [N]');
            xlabel('time [s]');
    end
    if i <= 5, ylabel(LBL{i}); end
    %  단계가 바뀐 시각. 범례에 들어가지 않게 / the phase changes, kept out
    for s = ph(:).'
        xline(s, 'Color', [.6 .6 .6], 'HandleVisibility','off');
    end
end
end

% ------------------------------------------------------------------------
function a = ssa_deg(e_deg)
%  **도로 들어온** 각 오차를 (-180, 180] 으로. 로그의 psi 와 psi_set 이 둘 다
%  도이므로 입력도 도다 / the smallest signed angle, degrees in and degrees out,
%  because both psi and psi_set are logged in degrees
e = e_deg * pi/180;
a = atan2(sin(e), cos(e)) * 180/pi;
end
