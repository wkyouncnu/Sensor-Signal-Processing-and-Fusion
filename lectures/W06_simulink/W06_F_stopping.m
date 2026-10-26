%% W06 · 실험 6-4 — 멈추는 법과 도착 판정 / Experiment 6-4 — stopping, and declaring arrival
%
%  이 절이 묻는 것 / the question
%      이 고리 어디에도 "멈춰라" 는 블록이 없다. 그런데 배는 선다. 무엇이 세우는가?
%      그리고 **언제 도착했다고 말할 것인가** — 비례 법칙은 유한한 시간에 목표에
%      닿지 않으므로, 도착은 도달하는 것이 아니라 **선언하는 것**이다.
%      Nothing in the cascade commands a stop, yet the hull stops. What stops it?
%      And when is arrival to be DECLARED -- a proportional law approaches the
%      target asymptotically and never reaches it, so arrival is not something
%      the hull attains but something an observer declares.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 정북 12 m 로만 보낸다. 선수각을 0 으로 묶으므로 **전진뿐**이고, 그래서
%         u_lim 과 Kp_pos 가 예측하는 수와 실측을 바로 견줄 수 있다. Kp_pos 를
%         셋으로 — 0.15 · 0.30(강의값) · 2.00.
%      ② 도착 반지름 다섯을 놓고, 좁힐 때마다 치르는 시간과 **그 자리에서 남은
%         속력**을 잰다.
%      ③ (10, 10) 으로 같은 명령을 두 번 보낸다 — 조류 없이, 그리고 0.3 m/s 의
%         횡조류와 함께. 접안 판정 네 조건이 각각 몇 %나 참이고 언제 처음 참이
%         되며 몇 번 답을 바꾸는지 센다.
%      ① Sends the hull 12 m due north with the heading pinned at 0, so the
%         motion is pure surge and the numbers u_lim and Kp_pos predict can be
%         compared with the measurement directly, at three gains -- 0.15, 0.30
%         (the lecture value) and 2.00.
%      ② Five arrival radii, and what each tightening costs in time and in the
%         speed still left at the instant of entry.
%      ③ Runs the same command to (10, 10) twice -- without a current, and with
%         a 0.3 m/s cross-current -- and counts, for each of the four berthing
%         conditions, how much of the run it is true, when it first becomes
%         true, and how often it changes its answer.
%
%  출력에서 볼 것 / what to look for in the output
%      · 꺾이는 거리는 예측보다 조금 **짧다** — 5.33 대 5.04, 2.67 대 2.46,
%        0.40 대 0.34 m. 모자라는 양이 게인이 커지면 줄어드는 것은, 그것이
%        속도가 천장을 떠나는 동안 더 지나간 거리이기 때문이다.
%      · 꼬리의 시간상수는 1/Kp_pos 와 맞는다 — 6.67 대 6.26 s, 3.33 대 2.90 s.
%        그러나 Kp_pos = 2.00 에서는 0.50 대 0.17 s 로 완전히 틀리고, 넘어가는
%        것(0.089 m)도 그 경우에만 나온다. 바깥 고리가 안쪽 고리가 낼 수 없는
%        제동을 요구한 것이다 — 종속 고리의 시간척도 분리 한계가 수로 나온 자리.
%      · 반지름을 지나는 순간의 속력은 Kp_pos·R 이다 (예측 0.600 → 0.015,
%        실측 0.679 → 0.017 m/s). 그러므로 **도착 반지름을 정하는 것은 그 자리의
%        속력을 정하는 것**이다. 40 배 좁히는 값은 12.98 → 23.70 s 로, 예측과
%        1 s 안에서 맞는다.
%      · 조류가 없으면 네 조건이 45.42 s 에 **한꺼번에** 참이 되고 답을 한 번만
%        바꾼다 — 빗장은 공짜다. 그런데 |v| < 0.05 혼자는 두 번 바꾼다(정지 →
%        이동 → 정지). 넷의 곱은 가장 덜 안정한 하나만큼만 안정하다.
%      · 조류 0.3 m/s 에서는 d < 0.40 m 가 **한 번도** 참이 되지 않는다. 배는
%        2.153 m 동쪽(N 10.000, E 12.153)에 서고 −0.108 m/s 로 기어든다. 횡력
%        요구는 두 경우 **모두** 35.13 N 에 눌려 있다 — 6-1·6-2 절의 Y_max 다.
%        포화 자체가 아니라 **남는 여유**가 도착을 결정한다.
%      · The braking corner is short of the prediction by 0.29 / 0.21 / 0.06 m,
%        a shortfall that shrinks with the gain: it is the extra ground covered
%        while the achieved speed is still leaving the ceiling.
%      · The tail's time constant matches 1/Kp_pos at the two low gains and
%        fails outright at 2.00 (0.17 s measured against 0.50 s predicted),
%        which is also the only case that overshoots. The outer loop asked for
%        a brake the inner loop could not deliver.
%      · The speed at the instant a radius is crossed is Kp_pos*R, so choosing
%        an arrival radius IS choosing a speed. Tightening it by 40 times costs
%        10.7 s, within 1 s of the exponential prediction.
%      · Without a current the four conditions come true together at 45.42 s and
%        the conjunction changes answer exactly once, so the latch costs
%        nothing -- but |v| < 0.05 alone changes twice, and a conjunction is
%        only as steady as its least steady term.
%      · With the current, d < 0.40 m is NEVER true: the hull stands 2.153 m
%        east of the target and creeps in at 0.108 m/s. The sway demand is
%        pinned at 35.13 N in BOTH runs -- the Y_max of 6-1 and 6-2 -- so what
%        decides arrival is not saturation but the margin left over.
%
%  만드는 것 / produces: img/W06_result_stopping.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

V = W06_vars();
p_d = [12 25];                 % 정북 12 m, 동쪽으로는 0 / 12 m due north

%% 1) 무엇이 세우는가 — 세 게인 / what stops the hull: three gains
%  꺾이는 거리는 u_lim/Kp_pos 다. 그보다 멀면 속도 명령이 천장에 눌려 **거리를
%  모르고** 달리고, 안으로 들면 명령이 거리에 비례해 줄어든다 / the braking
%  distance is u_lim/Kp_pos: outside it the command is pinned at the ceiling and
%  knows nothing about the distance, inside it the command is proportional to it
G  = [0.15 0.30 2.00];   Rs = cell(numel(G), 1);
CL = [0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
fprintf(['\n  W06 Experiment 6-4  stopping 12 m due north, heading 0 -- pure surge\n' ...
         '    Kp_pos   u_lim/Kp [m]   measured [m]   1/Kp [s]   measured [s]   overshoot [m]   t to 0.5 m [s]\n']);
for i = 1:numel(G)
    Rs{i} = W06_read('W06_F_position', 'N_d', p_d(1), 'E_d', p_d(2), ...
                     'psi_d_cmd', 0, 'Kp_pos', G(i));
    R = Rs{i};   cor = V.u_lim/G(i);   k = find(R.u > 0.98*V.u_lim, 1, 'last');
    j = R.t >= R.t(find(R.d < 0.5*cor, 1)) & R.t <= R.t(find(R.d < 0.1*cor, 1));
    c = polyfit(R.t(j), log(R.d(j)), 1);           % log d 의 기울기가 -Kp_pos 다
    fprintf('    %6.2f   %12.2f   %13.2f   %8.2f   %12.2f   %13.3f   %14.2f\n', G(i), ...
            cor, R.d(k), 1/G(i), -1/c(1), max(0, max(R.N) - p_d(1)), R.t(find(R.d < 0.5, 1)));
end

%% 2) 도착 반지름의 값 / what an arrival radius costs
%  꼬리가 지수이므로 반지름을 절반으로 줄이는 값은 **거리와 무관하게** 같다 —
%  ln2/Kp_pos 초다. 그리고 그 자리에서 남은 속력은 Kp_pos·R 이다 / the tail is
%  exponential, so halving the radius costs the same ln2/Kp_pos seconds wherever
%  it is done, and the speed still left at entry is Kp_pos*R
RR = [2 1 0.5 0.2 0.05];   R0 = Rs{2};   t05 = R0.t(find(R0.d < 0.5, 1));
ke = arrayfun(@(r) find(R0.d < r, 1), RR);
fprintf(['\n    radius [m]   first entry [s]   |U| there [m/s]   Kp_pos R [m/s]' ...
         '   t05 + ln(0.5/R)/Kp_pos [s]\n']);
fprintf('    %10.2f   %14.2f   %16.3f   %14.3f   %25.2f\n', ...
        [RR; R0.t(ke).'; hypot(R0.u(ke), R0.v(ke)).'; V.Kp_pos*RR; t05 + log(0.5./RR)/V.Kp_pos]);

%% 3) 도착은 선언이다 / arrival is a declaration
%  접안 판정은 조건 **넷의 곱**이다. 같은 명령을 조류 없이 한 번, 0.3 m/s 의 횡
%  조류와 함께 한 번 보낸다 / the berth test is a CONJUNCTION of four conditions;
%  the same command is sent once without a current and once with a cross-current
VC = [0 0.3];   Rc = cell(2, 1);
nm = {'d < R_berth', '|psi_e| < psi_tol', '|v| < v_tol', '|r| < r_tol', ...
      'all four at once'};
fprintf('\n    the berth test at (10, 10), without and with a cross-current\n');
fprintf('    V_c   term                 true [%% of run]   first true [s]   changes\n');
for q = 1:2
    Rc{q} = W06_read('W06_F_position', 'N_d', 10, 'E_d', 10, 'psi_d_cmd', 0, 'V_c', VC(q));
    R = Rc{q};
    T = [R.d < V.R_berth, abs(deg2rad(R.psi - R.psi_set)) < V.psi_tol, ...
         abs(R.v) < V.v_tol, abs(R.r) < V.r_tol];
    T(:,5) = all(T(:,1:4), 2);
    for i = 1:5
        k = find(T(:,i), 1);   tf = Inf;   if ~isempty(k), tf = R.t(k); end
        fprintf('    %3.1f   %-20s %13.1f   %14.2f   %7d\n', VC(q), nm{i}, ...
                100*mean(T(:,i)), tf, nnz(diff(T(:,i))));
    end
    fprintf('    %3.1f   ends at d = %.3f m, v = %+.4f m/s, max|Y| = %.2f N of the %.2f N available\n', ...
            VC(q), R.d(end), R.v(end), max(abs(R.Y_dem)), V.Y_max);
end

%% 4) 그림 / the figure
f = lab_fig('W06 F  stopping', 1180, 380);
for i = 1:numel(G)
    subplot(1,3,1); hold on; grid on; plot(Rs{i}.d, Rs{i}.u, 'Color', CL(i,:), 'LineWidth', 1.3);
    plot(0:0.1:12, min(V.u_lim, G(i)*(0:0.1:12)), '--', 'Color', [0.55 0.55 0.55]);
    subplot(1,3,2); hold on; grid on; plot(Rs{i}.t, Rs{i}.d, 'Color', CL(i,:), 'LineWidth', 1.3);
end
subplot(1,3,1); set(gca, 'XDir', 'reverse'); xlim([0 12.5]);
xlabel('distance left [m]'); ylabel('u [m/s]');
title('grey dashed: sat(K_{p,pos} d).   coloured: what the hull did');
subplot(1,3,2); set(gca, 'YScale', 'log'); ylim([1e-2 20]); xlim([0 50]);
xlabel('time [s]'); ylabel('distance left [m]');
title('straight on a log axis: the slope is -K_{p,pos}');
legend(compose('K_{p,pos} = %.2f', G'), 'Location', 'southwest');
subplot(1,3,3); hold on; grid on;
plot(Rc{1}.t, Rc{1}.d, 'Color', CL(1,:), 'LineWidth', 1.3);
plot(Rc{2}.t, Rc{2}.d, 'Color', CL(2,:), 'LineWidth', 1.3);
yline(V.R_berth, 'k--'); ylim([0 inf]); xlim([0 125]);
xlabel('time [s]'); ylabel('distance left [m]');
title('at (10, 10): dashed is R_{berth} = 0.40 m');
legend({'no current', '0.3 m/s cross-current'}, 'Location', 'northeast');

%% 5) 그림을 저장한다 / save the figure
exportgraphics(f, fullfile(here, 'img', 'W06_result_stopping.png'), 'Resolution', 150);
