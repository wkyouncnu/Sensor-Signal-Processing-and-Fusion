%% W06 · 실험 6-5/6-6 — 단계로 접안한다 / Experiment 6-5/6-6 — berthing, phase by phase
%
%  이 절이 묻는 것 / the question
%      6-3 절의 고리 셋은 **한 점**을 잡는다. 접안은 점 하나가 아니다 — 먼 바다에서
%      접근점까지 가고, 거기서 돌고, 그 선수각을 지킨 채 벽으로 붙고, 붙은 뒤에는
%      추력을 끊어야 한다. 제어기를 한 줄도 고치지 않고 **목표점과 선수각을 언제
%      바꿔 줄 것인가**만 정하는 블록 하나로 그것이 되는가? 그리고 벽에 **옆으로**
%      붙는 것과 **뱃머리부터** 붙는 것은 무엇이 다른가?
%      The three loops of Section 6-3 hold ONE point. Berthing is not one point:
%      the hull must run to an approach point, turn there, close the last metres
%      on that heading, and then cut the thrust. This section asks whether a
%      single block that decides WHEN to move the target and the heading is
%      enough, with not one gain touched -- and what separates coming in
%      sideways from coming in bow-first.
%
%  이 스크립트가 하는 일 / what this script does
%      ① W06_H_berth 를 두 번 돌린다. 달라지는 것은 psi_berth 하나다 —
%         0 도(옆으로 붙는다)와 -90 도(뱃머리부터 붙는다).
%      ② 네 단계가 각각 언제 시작해 얼마나 걸렸는지, 그때 배가 어디 있었는지를
%         단계마다 한 줄로 낸다.
%      ③ 두 접안 자세를 한 표로 견준다 — 다리별 시간, **3 단계에서만** 재는 전후·
%         좌우 요구와 포화 비율, 마지막 거리, 계류 뒤의 떠내림.
%      ① Runs W06_H_berth twice. One thing differs: psi_berth, 0 deg (alongside)
%         and -90 deg (bow into the wall).
%      ② Prints one line per phase: when it began, how long it lasted, and where
%         the hull was at that instant.
%      ③ Tables the two attitudes against each other -- the time in each leg,
%         the surge and sway demands measured OVER PHASE 3 ALONE and how much of
%         that leg sat on the sway cap, the distance left, and the drift after
%         the gate closes.
%
%  출력에서 볼 것 / what to look for in the output
%      · 1 단계는 **두 경우가 같다** — 53.04 s. psi_berth 는 2 단계부터 비로소
%        쓰이므로, 두 열의 차이는 전부 뒤쪽 두 다리에서 나온다
%      · 넘어가는 순간 d 가 **1.49 m 에서 7.28 m 로 뛴다.** 배가 뒤로 간 것이
%        아니라 목표점이 접근점에서 안벽으로 바뀐 것이다. 제어기는 그대로다
%      · 2 단계: 2.62 s 대 5.50 s. 뱃머리부터 붙으려면 67.6 도를 더 돌아야 하고
%        그 값이 2.88 s 다
%      · 3 단계: 23.00 s 대 11.46 s. 옆으로 붙는 쪽은 7.28 m 를 **좌우로** 가며
%        35.13 N 포화에 눌려 있고, 뱃머리 쪽은 7.06 m 를 **전후로** 가며 120 N 을
%        쓴다. 11.54 s 가 거기서 갈린다
%      · 합: 78.66 s 대 70.00 s. 차이 8.66 s = 11.54 - 2.88 로 **정확히** 맞는다
%      · 둘 다 R_berth = 0.40 m 안에서 멈추고 선수각 오차는 0.00 도다.
%        4 단계에서 gate 가 0 이 되면 속도 명령이 0 이고, 남은 시간 내내 떠내림은
%        센티미터 급이다
%      · Phase 1 is IDENTICAL in both columns -- 53.04 s. psi_berth is not read
%        until phase 2, so every difference comes from the last two legs.
%      · At the hand-over d JUMPS from 1.49 m to 7.28 m. The hull did not move
%        backwards; the target was replaced, approach point by berth. Not one
%        gain changed.
%      · Phase 2: 2.62 s against 5.50 s. Bow-first must turn 67.6 deg further,
%        and that costs 2.88 s.
%      · Phase 3: 23.00 s against 11.46 s. Alongside crosses the last 7.28 m
%        SIDEWAYS, pinned on the 35.13 N sway cap; bow-first crosses 7.06 m
%        AHEAD on 120 N. That is where 11.54 s is won.
%      · Totals: 78.66 s against 70.00 s. The 8.66 s gap is 11.54 - 2.88 exactly.
%      · Both stop inside R_berth = 0.40 m with 0.00 deg of heading error. Once
%        the gate drops to 0 in phase 4 the velocity command is zero and the
%        hull drifts only centimetres for the rest of the run.
%
%  만드는 것 / produces: img/W06_result_berth.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

V  = W06_vars();
PH = {'1 TRANSIT', '2 ALIGN', '3 BERTH', '4 MOORED'};
C  = {'alongside', 0,     [0 0.45 0.74]
      'bow-first', -pi/2, [0.85 0.33 0.10]};
n  = size(C,1);
Rs = cell(n,1);   TE = nan(n,4);   DUR = nan(n,4);

%% 1) 네 단계 / the four phases
fprintf(['\n  W06 Experiment 6-5/6-6  berthing at (%g, %g) m from (%g, %g) m,' ...
         ' approach point (%g, %g) m\n'], V.berth_N, V.berth_E, V.x0(7), V.x0(8), ...
        V.app_N, V.app_E);
for i = 1:n
    %  psi_berth 를 **직접** 준다. bow_on 은 W06_vars·W06_0_setup 안에서
    %  psi_berth 를 고르는 편의 스위치일 뿐이고, 모델이 읽는 블록이 없다.
    %  W06_read 는 변수를 하나씩 setVariable 하므로 bow_on 을 바꿔도
    %  psi_berth 가 다시 계산되지 않는다 — 그래서 둘 다 준다.
    Rs{i} = W06_read('W06_H_berth', 'psi_berth', C{i,2}, ...
                     'bow_on', double(C{i,2} ~= 0), 'T_final', 150);
    R = Rs{i};
    fprintf(['\n    %s, psi_berth = %+.0f deg\n' ...
             '    phase        enters [s]   lasts [s]   N [m]   E [m]   psi [deg]' ...
             '   to berth [m]   d the loop sees [m]\n'], C{i,1}, rad2deg(C{i,2}));
    for p = 1:4
        k = find(R.phase >= p, 1);
        if isempty(k), fprintf('    %-11s   %10s\n', PH{p}, 'never'); continue, end
        TE(i,p) = R.t(k);
        kn = find(R.phase >= p+1, 1);
        if isempty(kn), DUR(i,p) = R.t(end) - R.t(k); else, DUR(i,p) = R.t(kn) - R.t(k); end
        fprintf('    %-11s   %10.2f   %9.2f   %5.2f   %5.2f   %9.2f   %12.3f   %18.3f\n', ...
                PH{p}, TE(i,p), DUR(i,p), R.N(k), R.E(k), R.psi(k), ...
                hypot(R.N(k) - V.berth_N, R.E(k) - V.berth_E), R.d(k));
    end
end

%% 2) 옆으로 붙는가, 뱃머리부터 붙는가 / alongside or bow-first
%   3 단계의 다리 시간은 6-4 절의 제동 법칙이 예측한다 — 속도 한계로 가는 구간
%   d/v_cap 에 멈추는 데 드는 1/Kp_pos 를 더한 것이다 / phase 3's length is
%   predicted by the braking law of Section 6-4: d/v_cap to run in, plus 1/Kp_pos
%   to stop.
fprintf(['\n    attitude    transit [s]   align [s]   turn asked [deg]   berth [s]' ...
         '   d/v_cap + 1/K_p,pos [s]   moored at [s]\n']);
for i = 1:n
    R = Rs{i};   k3 = find(R.phase >= 3, 1);
    vcap = V.u_lim*(C{i,2} ~= 0) + V.v_lim*(C{i,2} == 0);
    fprintf('    %-9s   %11.2f   %9.2f   %16.1f   %9.2f   %23.2f   %13.2f\n', ...
            C{i,1}, DUR(i,1), DUR(i,2), ...
            abs(rad2deg(C{i,2}) - R.psi(find(R.phase >= 2, 1))), DUR(i,3), ...
            R.d(k3)/vcap + 1/V.Kp_pos, TE(i,4));
end
fprintf(['\n    attitude    berth max |X| [N]   berth max |Y| [N]' ...
         '   on the Y cap [%% of leg]   berth max |u|   berth max |v|' ...
         '   d(end) [m]   drift [m]   psi err [deg]\n']);
for i = 1:n
    R = Rs{i};   m3 = R.phase == 3;   k4 = find(R.phase >= 4, 1);
    fprintf(['    %-9s   %17.2f   %17.2f   %22.1f   %13.3f   %13.3f   %10.3f' ...
             '   %9.3f   %13.2f\n'], C{i,1}, max(abs(R.X_dem(m3))), ...
            max(abs(R.Y_dem(m3))), 100*mean(R.Y_clip(m3)), max(abs(R.u(m3))), ...
            max(abs(R.v(m3))), hypot(R.N(end) - V.berth_N, R.E(end) - V.berth_E), ...
            R.d(end) - R.d(k4), rad2deg(atan2(sind(R.psi(end) - R.psi_set(end)), ...
                                              cosd(R.psi(end) - R.psi_set(end)))));
end
fprintf(['    the caps: X_max = %.0f N, Y_max = %.2f N, u_lim = %.2f m/s,' ...
         ' v_lim = %.2f m/s,  R_berth = %.2f m,  K_p,pos = %.2f\n'], V.X_max, ...
        V.Y_max, V.u_lim, V.v_lim, V.R_berth, V.Kp_pos);

%% 3) 그림 / the figure — 그리는 것은 W06_fig_berth 가 한다 (45 줄 규칙, §15-15)
W06_fig_berth(Rs, C, PH, TE, V, here);
