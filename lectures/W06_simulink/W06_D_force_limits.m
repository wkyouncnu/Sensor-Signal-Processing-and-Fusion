%% W06 · 실험 6-2 — 횡력의 한계는 어디서 오는가 / Experiment 6-2 — where the sway limit comes from
%
%  이 절이 묻는 것 / the question
%      선수추진기의 정격은 40 N 이다. 그러면 이 배의 횡력 한계가 40 N 인가?
%      아니다. 횡력을 내려면 **선미 둘이 그 모멘트를 지워야** 하고, 그쪽이 먼저
%      바닥난다. 어느 한계가 먼저 걸리는지를 재는 절이다.
%      The bow thruster is rated at 40 N. Is 40 N then the hull's sway limit? It
%      is not: producing sway forces the stern pair to cancel the moment that
%      came with it, and that is what runs out first. This section measures
%      which of the limits binds.
%
%  이 스크립트가 하는 일 / what this script does
%      ① Y 요구를 20 N 에서 50 N 까지 올리며 W06_C_actuation 을 돌리고, 실제로
%         나온 힘을 축 회전수에서 되돌려 요구와 대조한다.
%      ② 세 후보 한계를 따로 계산한다 — 선미 후진 · 선미 전진 · 선수 정격.
%      ③ N = 0 에서 도달 가능한 (X, Y) 집합을 그린다.
%      ① Runs W06_C_actuation with the sway demand raised from 20 N to 50 N and
%         recovers the force actually produced from the shaft speeds.
%      ② Computes the three candidate limits separately: the stern astern
%         limit, the stern ahead limit and the bow thruster's rating.
%      ③ Draws the attainable (X, Y) set at N = 0.
%
%  출력에서 볼 것 / what to look for in the output
%      - 먼저 걸리는 것은 **선미의 후진 한계 35.13 N** 이다. 선수추진기 정격 40 N 이
%        아니고, 선미 전진 한계 63.03 N 도 아니다. 횡력을 내려면 왼쪽 추진기가
%        **뒤로** 밀어야 하는데 후진 추력이 전진보다 작기 때문이다.
%      - 한계를 넘어도 **횡력 자체는 나온다**: F_B = Y 가 정격 40 N 까지 그대로다.
%        무너지는 것은 X = 0 과 N = 0 이라는 약속이다.
%      - Y = 40 에서 X 로 9.24 N, N 으로 3.65 N m 가 샌다. 20 초 뒤 선수각이
%        +31.25 도 돌아 있고, Y = 50 에서는 선수추진기도 잘려 반대로 -37.58 도다.
%      - 두 예측 열이 측정 열과 **소수 둘째 자리까지 같다.** 자르기는 손으로 셀 수
%        있으며, 그래서 6-3 절의 위치 루프가 요구를 35.13 N 으로 묶는다.
%      - 오른쪽 그림: 전진을 함께 요구하면 횡력 여유가 넓어진다. X = 0 이 가장 좁고,
%        제어기가 지켜야 하는 것은 그 가장 좁은 자리다.
%      - The limit that binds is the stern's ASTERN limit, 35.13 N: not the bow
%        thruster's 40 N rating, and not the stern's ahead limit of 63.03 N.
%        Making sway forces the port propeller to push BACKWARDS, and astern
%        thrust is the weaker of the two.
%      - Past that limit the sway force itself still comes out, F_B = Y up to the
%        40 N rating. What breaks is the promise that X and N are zero.
%      - At Y = 40 the leak is 9.24 N of surge and 3.65 N m of yaw, and the
%        heading has swung to +31.25 deg after 20 s. At Y = 50 the bow unit
%        clips as well and the heading goes the other way, to -37.58 deg.
%      - Both prediction columns match the measured columns to the second
%        decimal: clipping is countable by hand, which is why the position loop
%        of Section 6-3 holds its sway demand to 35.13 N.
%      - In the right-hand figure, demanding surge as well widens the sway
%        authority. X = 0 is the narrowest place, and that is the one the
%        controller has to respect.
%
%  만드는 것 / produces: img/W06_result_limits.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

V = W06_vars();
a = V.l_f/(2*V.y_pont);        % 횡력 1 N 이 선미에 지우는 짐 / the stern's share

%% 1) 세 후보 한계 / the three candidate limits
%  N = 0, X = 0 에서 T_L = -a Y 이고 T_R = +a Y 다. 왼쪽이 **후진**으로 가므로
%  후진 한계가 먼저 걸린다 / at N = 0 and X = 0 the port propeller runs astern,
%  so the astern limit is the one that binds
fprintf('\n  W06 Experiment 6-2  which limit binds first  (N = 0, X = 0)\n');
fprintf('    lever  l_f/(2 y_pont)          = %.6f\n', a);
fprintf('    from the stern ASTERN limit    |Y| <= %7.4f N   (T_min = %.4f N)\n', abs(V.T_min)/a, V.T_min);
fprintf('    from the stern AHEAD  limit    |Y| <= %7.4f N   (T_max = %.4f N)\n', V.T_max/a, V.T_max);
fprintf('    from the bow thruster rating   |Y| <= %7.4f N\n', V.F_B_max);
fprintf('    binding, and so W06_vars.Y_max = %7.4f N\n\n', V.Y_max);

%% 2) 모델로 재본다 / measure it on the model
%  한계를 넘으면 **횡력이 모자라는 것이 아니다.** F_B = Y 는 그대로 나온다.
%  무너지는 것은 X = 0 과 N = 0 이라는 약속이다. 손으로 세어 둔 예측이 둘 있다:
%      T_L 이 T_min 에서 잘리면  X = T_min + a Y,
%                               N = y_pont (T_min - a Y) + l_f min(Y, F_B_max)
%  Past the limit it is NOT the sway force that falls short: F_B = Y still comes
%  out. What breaks is the promise that X and N are zero. Two hand predictions
%  are checked against the run, column by column.
fprintf('    demand Y [N]     T_L       T_R      F_B       X       Y       N      X pred   N pred    psi(end)\n');
Yc = [20 30 35 V.Y_max 40 50];
Xd = zeros(size(Yc));  Nd = zeros(size(Yc));
for i = 1:numel(Yc)
    R = W06_read('W06_C_actuation', 'X_cmd', 0, 'Y_cmd', Yc(i), 'N_cmd', 0, 'T_final', 20);
    f = [R.T_L(end); R.T_R(end); R.F_B(end)];  tau = V.B*f;
    Xd(i) = tau(1);  Nd(i) = tau(3);
    TL = max(-a*Yc(i), V.T_min);  FB = min(Yc(i), V.F_B_max);   % 손으로 센 예측
    fprintf('    %8.2f   %8.2f  %8.2f  %7.2f  %7.2f %7.2f %7.2f  %7.2f  %7.2f   %8.2f\n', ...
            Yc(i), f(1), f(2), f(3), tau(1), tau(2), tau(3), ...
            TL + a*Yc(i), V.y_pont*(TL - a*Yc(i)) + V.l_f*FB, R.psi(end));
end

%% 3) N = 0 에서 도달 가능한 (X, Y) / the attainable set at N = 0
%  T_L = X/2 - a Y,  T_R = X/2 + a Y 를 두 추진기의 구간에 넣고 Y 를 푼다
Xg = linspace(2*V.T_min, 2*V.T_max, 400);
Yhi = min(min((Xg/2 - V.T_min)/a, (V.T_max - Xg/2)/a),  V.F_B_max);
Ylo = max(max((Xg/2 - V.T_max)/a, (V.T_min - Xg/2)/a), -V.F_B_max);
ok  = Yhi >= Ylo;

f = lab_fig('W06 D  force limits', 960, 380);
subplot(1,2,1); hold on; grid on;
plot(Yc, Xd, 'o-', 'Color', [0 0.45 0.74], 'LineWidth', 1.4, 'MarkerFaceColor', 'w');
plot(Yc, Nd, 's-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.4, 'MarkerFaceColor', 'w');
xline(V.Y_max, 'Color', [.3 .3 .3], 'LineWidth', 1.2, 'HandleVisibility', 'off');
text(V.Y_max + 0.7, 24, sprintf('stern astern limit\n%.2f N', V.Y_max), 'Color', [.3 .3 .3]);
xlabel('demanded Y [N]'); ylabel('leaked into the other axes [N, N m]');
title('both were demanded as zero');
legend({'surge X', 'yaw N'}, 'Location', 'northwest');

subplot(1,2,2); hold on; grid on;
fill([Xg(ok) fliplr(Xg(ok))], [Yhi(ok) fliplr(Ylo(ok))], [0.81 0.93 0.81], ...
     'EdgeColor', [0.2 0.5 0.2], 'LineWidth', 1.1);
plot([0 0], [-V.Y_max V.Y_max], 'Color', [0.85 0.33 0.10], 'LineWidth', 2.2);
plot(0, 0, 'k+', 'MarkerSize', 9, 'LineWidth', 1.2);
%  축을 집합보다 넓게 둔다. 딱 맞추면 선수 정격이 자른 **평평한 위아래 변**이
%  축 테두리에 겹쳐 보이지 않는다 / the axes are set wider than the set: fitted
%  exactly, the flat top and bottom cut by the bow rating hide on the axis box
xlim([2*V.T_min - 20, 2*V.T_max + 20]);  ylim([-48 48]);
text(100, V.F_B_max + 4, sprintf('bow rating  %.0f N', V.F_B_max), 'Color', [0.2 0.5 0.2]);
xlabel('X [N]'); ylabel('Y [N]'); title('attainable (X, Y) at N = 0');
text(22, V.Y_max*0.60, sprintf('at X = 0:\n |Y| \\leq %.2f N', V.Y_max), 'Color', [0.85 0.33 0.10]);

%% 4) 그림을 저장한다 / save the figure
exportgraphics(f, fullfile(here, 'img', 'W06_result_limits.png'), 'Resolution', 150);
