%% W06 · 4 단 — 어떻게 서는가 / Rung 4 — stopping
%
%  >> W06_4_stop_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_4_stop.slx` 를 **그대로** 돌린다. 캔버스의 명령은 N_d = 12,
%         E_d = 25 — 출발점 (0, 25) 에서 정북으로 12 m.
%      ② 남은 거리 d(t) 를 재서 6-4 절의 두 구간을 가른다.
%      ③ 외측 게인 Kp_pos 를 쓸어 간다. 제동 거리와 시정수가 **함께** 움직이고,
%         충분히 크게 하면 지나친다 — 두 구간의 경계가 게인의 함수다.
%      ④ 반경마다 언제 닿는지를 재서, 배가 **점이 아니라 반경에** 닿는다는 것을
%         수치로 둔다.
%      ⑤ 그 다음 1 단의 점 잡기를 **계측기로 빌려** 도착 조건 넷을 따로 센다.
%         조류가 없을 때와 있을 때 — 위치 고리에 적분기가 없으므로 조류는
%         **정상상태 오차**로 남고, 그래서 도착이 선언되지 않는다.
%      ① Runs W06_4_stop.slx as it stands: 12 m due north.
%      ② Measures d(t) and separates the two regimes of Section 6-4.
%      ③ Sweeps the outer gain: brake distance and time constant move together.
%      ④ Times the entry into each radius -- the ship reaches radii, not points.
%      ⑤ Borrows rung 1 as an instrument to count the four arrival terms, with
%         and without a cross-current.
%
%  출력에서 볼 것 / what to look for
%      - 먼 구간에서 d 는 **직선**으로 준다. 외측 법칙이 포화해 있으므로
%        기울기가 -u_lim 이다.
%      - d_brake = u_lim/Kp_pos 아래에서 법칙이 선형이 되고, 거기서부터
%        d 는 **지수**로 준다. 그래서 **반으로 줄이는 데 드는 시간이 늘
%        같다** — 1.00 → 0.50 m 와 0.50 → 0.05 m 가 같은 비율을 낸다.
%      - 다만 그 시정수는 1/Kp_pos 가 **아니다.** 1/Kp_pos 는 속도 고리가
%        무한히 빠를 때의 값이고, 실제 두 고리는 함께 2차계를 이룬다:
%            s^2 + w s + w Kp_pos = 0,   w = 속도 고리의 대역폭
%        두 뿌리의 **곱**이 w·Kp_pos 로 묶여 있으므로, 빠른 뿌리가 w 쪽으로
%        밀리면 느린 뿌리는 Kp_pos 보다 **커진다.** 아래가 예측과 실측을
%        나란히 찍는다 — 지수라는 예측은 맞고, 그 비율은 조금 빠르다.
%      - 그래서 배는 점에 닿지 않는다. 반경에 닿을 뿐이다. 도착을 선언하는
%        것은 법칙이 아니라 6-5 절의 네 조건이다.

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>

%% 1) 돌린다 / run it
mdl = 'W06_4_stop';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

%% 2) 남은 거리 / the distance still to run
V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = W06.time;
d = hypot(y(:,7) - y(:,4), y(:,8) - y(:,5));

%% 3) 두 구간 / the two regimes
d_brake = V.u_lim / V.Kp_pos;
tau     = 1 / V.Kp_pos;

%  네 반경에 닿은 시각을 선형보간으로 집는다 / the instant each radius is reached
R  = [d_brake 1.00 0.50 0.05];
tR = nan(1,4);
for k = 1:4
    j = find(d <= R(k), 1);
    if ~isempty(j) && j > 1
        tR(k) = t(j-1) + (t(j) - t(j-1))*(d(j-1) - R(k))/(d(j-1) - d(j));
    end
end
t_brake = tR(1);  t_1 = tR(2);  t_05 = tR(3);  t_005 = tR(4);

%  직선 구간의 기울기 — 포화가 풀리기 전의 절반만 쓴다
i = t < 0.5*t_brake;
s = polyfit(t(i), d(i), 1);

%  지수 구간의 실측 시정수 — log d 를 직선으로 맞춘다. 창은 제동 거리의
%  절반 아래 — 게인을 쓸어 갈 때도 같은 규칙이라야 줄끼리 견줄 수 있다.
%  the measured time constant: log d fitted below half the brake distance.
%  The sweep below uses the SAME window, so its rows compare like with like.
j2  = d < 0.5*d_brake & d > 0.02;
p2  = polyfit(t(j2), log(d(j2)), 1);
tau_m = -1/p2(1);
%  그 시정수를 내는 속도 고리 대역폭 — s^2 + w s + w Kp = 0 을 거꾸로 푼다
lam   = 1/tau_m;
w_eff = lam^2 / (lam - V.Kp_pos);

fprintf('\n  W06 Rung 4  stopping, and who declares arrival  (%s)\n', mdl);
fprintf('    FAR   measured slope of d(t)   %7.4f m/s   (-u_lim = %7.4f)\n', ...
        s(1), -V.u_lim);
fprintf('    the two regimes meet at        d_brake = u_lim/Kp_pos = %5.2f m   at %6.2f s\n', ...
        d_brake, t_brake);
fprintf('    NEAR  1/Kp_pos (ideal inner loop)  %5.2f s   measured time constant %5.2f s\n', ...
        tau, tau_m);
fprintf('          the cascade is 2nd order: s^2 + w s + w Kp_pos,  w = %5.2f rad/s\n', w_eff);
fprintf('          halving time             measured  1.00 -> 0.50 m  %5.2f s\n', t_05 - t_1);
fprintf('                                   measured  0.50 -> 0.05 m  %5.2f s per halving\n', ...
        (t_005 - t_05)/log2(0.50/0.05));
fprintf('          the two agree to %4.1f %%  -- the decay IS exponential\n', ...
        100*abs((t_05 - t_1) - (t_005 - t_05)/log2(10))/(t_05 - t_1));
fprintf('    reached 0.50 m at %6.2f s,  0.05 m at %6.2f s\n', t_05, t_005);
j = find(d <= V.R_berth, 1);
if ~isempty(j)
    fprintf('    once inside R_berth = %4.2f m, d never rises above %6.4f m again\n', ...
            V.R_berth, max(d(j:end)));
end
fprintf('    final      error %6.4f m,  u %6.4f m/s,  v %6.4f m/s\n', ...
        d(end), y(end,1), y(end,2));

%% 4) 외측 게인을 쓸어 간다 / sweeping the outer gain
%  Kp_pos 는 두 구간의 **경계**이자 가까운 구간의 **속도**다. 하나를 키우면
%  제동 거리가 줄고 시정수도 줄지만, 속도 고리가 따라오지 못하는 자리를 넘으면
%  2차계의 감쇠가 모자라 **지나친다.** 세 줄이 그 셋을 한꺼번에 보인다.
%  Kp_pos sets BOTH the boundary between the regimes and the rate inside the
%  near one. Raising it shortens both -- until the inner loop can no longer
%  keep up and the second-order pair overshoots.
animate  = 0;           %#ok<NASGU>
W06batch = 1;           %#ok<NASGU>  W06_plot 이 바로 돌아간다 / W06_plot returns at once
fprintf('\n    sweeping Kp_pos  (overshoot = how far north of the target the hull ever got;\n');
fprintf('                      tau is withheld on a row that overshoots: not one exponential)\n');
fprintf('      %8s %14s %14s %10s %10s %14s %12s\n', 'Kp_pos', ...
        'u_lim/Kp [m]', 'measured [m]', '1/Kp [s]', 'tau [s]', 'overshoot [m]', 't to 0.5 m');
for Kp = [0.15 0.30 2.00]
    Kp_pos = Kp;        %#ok<NASGU>  Gain 의 값이 변수 이름이다 / the Gain reads this
    sim(mdl);
    z  = squeeze(W06.signals.values);  if size(z,1) < size(z,2), z = z.'; end
    tz = W06.time;
    dz = hypot(z(:,7) - z(:,4), z(:,8) - z(:,5));
    Uz = hypot(z(:,1), z(:,2));
    %  제동 거리의 실측 — 속도가 한계에서 **내려오는** 그 자리의 남은 거리
    %  measured brake distance: d at the instant the speed comes off the limit
    [~, kpk] = max(Uz);
    kb  = kpk - 1 + find(Uz(kpk:end) < 0.99*V.u_lim, 1);
    if ~isempty(kb), db_m = dz(kb); else, db_m = NaN; end
    jj  = dz < 0.5*V.u_lim/Kp & dz > 0.02;      % 3) 절과 같은 창 / same window
    if sum(jj) > 10
        pp = polyfit(tz(jj), log(dz(jj)), 1);  tau_k = -1/pp(1);
    else
        tau_k = NaN;
    end
    over = max(0, max(z(:,4) - z(:,7)));        % 목표 북쪽으로 넘어간 양
    %  지나친 줄에서는 가까운 구간이 더는 **하나의** 지수가 아니다. 맞춘 값이
    %  나오기는 하지만 그것은 아무것도 재지 않은 수이므로 적지 않는다.
    %  Once it overshoots the near field is no longer a single exponential; the
    %  fit still returns a number, but it measures nothing, so it is withheld.
    if over > 0.01, tau_k = NaN; end
    k05  = find(dz <= 0.5, 1);
    if ~isempty(k05), s05 = tz(k05); else, s05 = NaN; end
    fprintf('      %8.2f %14.2f %14.2f %10.2f %10.2f %14.3f %12.2f\n', ...
            Kp, V.u_lim/Kp, db_m, 1/Kp, tau_k, over, s05);
end
Kp_pos = V.Kp_pos;      %#ok<NASGU>  정격으로 되돌린다 / back to nominal

%% 5) 배는 점이 아니라 반경에 닿는다 / the ship reaches radii, not points
%  지수는 0 에 **닿지 않는다.** 그래서 "도착" 은 반경을 고르는 일이고, 반경을
%  반으로 줄일 때마다 같은 시간이 더 든다. 마지막 두 열이 그 예측이다 —
%  하나는 이상적인 1/Kp_pos 로, 하나는 실측 시정수로 센 것.
%  An exponential never reaches zero, so arrival is a choice of radius. Each
%  halving costs the same time; the last two columns predict it, once with the
%  ideal 1/Kp_pos and once with the measured constant.
fprintf('\n    when each radius is reached  (nominal Kp_pos = %4.2f)\n', V.Kp_pos);
fprintf('      %8s %14s %12s %16s %16s %16s\n', 'R [m]', 'first entry [s]', ...
        '|U| there', 'Kp_pos R [m/s]', 'pred 1/Kp [s]', 'pred tau [s]');
for Rk = [2.00 1.00 0.50 0.20 0.05]
    j = find(d <= Rk, 1);
    if isempty(j) || j == 1, continue, end
    tj = t(j-1) + (t(j) - t(j-1))*(d(j-1) - Rk)/(d(j-1) - d(j));
    fprintf('      %8.2f %14.2f %12.3f %16.3f %16.2f %16.2f\n', ...
            Rk, tj, hypot(y(j,1), y(j,2)), V.Kp_pos*Rk, ...
            t_05 + log(0.5/Rk)/V.Kp_pos, t_05 + tau_m*log(0.5/Rk));
end

%% 6) 도착을 누가 선언하는가 / who declares arrival
%  법칙은 도착을 말하지 않는다. 6-5 절이 쓰는 것은 **조건 넷**이고, 그 넷이
%  동시에 참이어야 한다. 여기서는 1 단의 점 잡기를 계측기로 빌려 그 넷을
%  따로 센다 — 조류가 없을 때, 그리고 동쪽으로 0.3 m/s 가 흐를 때.
%  위치 고리에는 적분기가 없다. 그래서 조류는 **정상상태 오차**로 남고,
%  첫 조건이 끝내 참이 되지 않는다. 넷을 and 로 묶는 이유가 그 자리에 있다.
%  The law never declares arrival; Section 6-5 uses four conditions, all true
%  at once. Rung 1's point hold is borrowed here as the instrument. The
%  position loop has no integrator, so a steady current leaves a steady offset
%  and the first term never latches -- which is why the four are ANDed.
rig = 'W06_1_point';
load_system(rig);
term = {'d < R_berth', '|psi err| < psi_tol', '|v| < v_tol', '|r| < r_tol'};
for Vc = [0 0.3]
    V_c    = Vc;        %#ok<NASGU>  Constant 의 값이 변수 이름이다 / plant reads this
    beta_c = V.beta_c;  %#ok<NASGU>  pi/2 = 동쪽으로 흐른다 / the current sets east
    sim(rig);
    z  = squeeze(W06.signals.values);  if size(z,1) < size(z,2), z = z.'; end
    tz = W06.time;
    dz = hypot(z(:,7) - z(:,4), z(:,8) - z(:,5));
    C  = [dz                     <= V.R_berth, ...
          abs(z(:,6) - z(:,9))   <= rad2deg(V.psi_tol), ...
          abs(z(:,2))            <= V.v_tol, ...
          abs(z(:,3))            <= V.r_tol];
    fprintf('\n    the four arrival terms, point hold at (%.0f, %.0f) m,  V_c = %3.1f m/s due east\n', ...
            z(end,7), z(end,8), Vc);
    fprintf('      %-22s %16s %16s %10s\n', 'term', 'true [% of run]', 'first true [s]', 'changes');
    for k = 1:4
        j = find(C(:,k), 1);
        if ~isempty(j), ft = tz(j); else, ft = NaN; end
        fprintf('      %-22s %16.1f %16.2f %10d\n', ...
                term{k}, 100*mean(C(:,k)), ft, sum(diff(C(:,k)) ~= 0));
    end
    fprintf('      all four at once       %16.1f %% of the run\n', 100*mean(all(C,2)));
    fprintf('      at the end             d = %6.3f m,  v = %7.4f m/s,  max |Y| %6.2f N of %5.2f N\n', ...
            dz(end), z(end,2), max(abs(z(:,11))), V.Y_max);
end

%% 7) 빌린 것을 되돌린다 / put the borrowed rig back
V_c    = V.V_c;         %#ok<NASGU>
beta_c = V.beta_c;      %#ok<NASGU>
Kp_pos = V.Kp_pos;      %#ok<NASGU>
set_param(rig, 'Dirty', 'off');
set_param(mdl, 'Dirty', 'off');
clear W06batch                      % 다음 Run 은 다시 그림을 그린다 / plots again
fprintf('\n');
