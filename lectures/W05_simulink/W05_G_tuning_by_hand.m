%% W05 · 실험 5-6 — 유도 법칙의 튜닝 순서 / Experiment 5-6 — the tuning order for the guidance law
%
%  이 절이 묻는 것 / the question
%      모델 없이, 임무 위에서 잰 것만으로 Delta, R_switch, kappa 를 어떤 순서로 고르는가?
%      In what order are Delta, R_switch and kappa chosen, from measurements on
%      the mission alone?
%
%  순서 / the order — 2주차의 P -> I 순서와 같다 / the same P -> I order as Week 2
%      1 단계  Delta (P 게인): 곧은 경로에서 빠르되 흔들리지 않는 값 — 실험 5-3 의 결과, 5 m.
%      2 단계  R_switch: 모퉁이에서 가장 덜 벗어나는 값 — 실험 5-4 의 결과, 3 m.
%      3 단계  조류가 있으면 오차가 남는다 -> kappa (I 게인) 를 올리며 다리마다 남는 오차를 본다.
%      Step 1  Delta (the P gain): fast without swinging on a straight leg — section D, 5 m.
%      Step 2  R_switch: the smallest excursion at the corners — section E, 3 m.
%      Step 3  a current leaves an error -> raise kappa (the I gain) and watch
%              the error left on each leg.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 임무 + 동쪽으로 0.3 m/s 조류. kappa = 0 (LOS), 0.1, 0.3, 0.5, 1 로 돌린다.
%      ② 다리마다 (다리에 들어선 뒤 25 s 부터) 평균 |y_e| 를 찍는다.
%      ③ LOS 와 고른 ILOS 의 항적을 그린다.
%      ① The mission with a 0.3 m/s current flowing east; kappa = 0 (LOS), 0.1,
%         0.3, 0.5 and 1.
%      ② Prints the mean |y_e| on each leg, from 25 s after entering it.
%      ③ Draws the tracks of LOS and of the chosen ILOS.
%
%  출력에서 볼 것 / what to look for in the output
%      - LOS 는 조류를 가로지르는 셋째·넷째 다리에서 2.14 m, 1.38 m 를 남긴다 (둘째 다리는 조류와 나란해 거의 0).
%      - kappa = 0.1 은 60 m 다리에서는 너무 느리다 (둘째~넷째 합 3.10 m).
%        합이 가장 작은 것은 0.3 (0.92 m) 이고 0.5 (0.93 m) 가 거의 같으며, 1 은 다시 커진다 (1.07 m).
%        실험 5-5 에서 kappa 가 클수록 반대쪽으로 더 넘어갔으므로 둘 중 작은 0.3 을 고른다.
%      - 첫째 다리 값은 출발점이 20 m 떨어져 있어 크다 — 다리 사이 비교에서는 뺀다.
%      - LOS leaves 2.14 m and 1.38 m on legs 3 and 4, which cross the current
%        (almost none on leg 2, which runs with it).
%      - kappa = 0.1 is too slow for 60 m legs (3.10 m summed over legs 2 to 4).
%        The smallest sum is 0.3 (0.92 m), with 0.5 almost equal (0.93 m) and
%        1 larger again (1.07 m). Experiment 5-5 showed a larger kappa overshoots
%        more, so the smaller of the two, 0.3, is chosen.
%      - Leg 1 is large because the start is 20 m off; it is left out of the comparison.
%
%  만드는 것 / produces: img/W05_result_tuning.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
S = {'V_c', 0.3, 'T_final', 450};                  % 임무 + 조류 / the mission and the current

%% 1) kappa 다섯 가지 / five values of kappa
fprintf('\n  W05 Experiment 5-6  the tuning order  (Delta = 5 m, R_switch = 3 m, current 0.3 m/s east)\n');
fprintf('    kappa   mean |y_e| on legs 1, 2, 3, 4 [m]   sum of legs 2-4 [m]   last waypoint at [s]\n');
for kap = [0 0.1 0.3 0.5 1]
    R = W05_read('W05_G_tuning', S{:}, 'kappa', kap);          % kappa = 0 이면 LOS 와 같다 / 0 is LOS

    %  다리 경계 = 다리 번호가 바뀐 곳 / leg boundaries = where the leg number changes
    b = [1; find(diff(R.wp) > 0); numel(R.t)];
    m = zeros(1, numel(b) - 1);
    for j = 1:numel(b) - 1
        seg = b(j) + round(25/R.V.h) : b(j+1);                 % 들어선 뒤 25 s 부터 / from 25 s in
        m(j) = mean(abs(R.y_e(seg)));
    end
    k = find(hypot(R.N - 60, R.E - 120) < 3, 1);
    fprintf('    %-5g   %8.2f %6.2f %6.2f %6.2f   %19.2f   %20.1f\n', kap, m, sum(m(2:4)), R.t(k));
    if kap == 0,   A = R; end                                   % LOS
    if kap == 0.3, B = R; end                                   % 고른 값 / the choice
end

%% 2) 그림: LOS 와 ILOS (kappa = 0.3) 의 항적 / figure: tracks of LOS and ILOS (kappa = 0.3)
f = lab_fig('W05 G  tuning', 1000, 560);  hold on;
V = W05_vars();  COL = lines(2);
plot(V.WP_E, V.WP_N, 'k--o', 'MarkerFaceColor', 'k', 'DisplayName', 'path');
plot(A.E, A.N, 'Color', COL(1,:), 'LineWidth', 2, 'DisplayName', 'LOS');
plot(B.E, B.N, 'Color', COL(2,:), 'LineWidth', 2, 'DisplayName', 'ILOS, \kappa = 0.3');
track_ships({[B.N B.E B.psi]}, COL(2,:), 'Marks', 8);
quiver(100, 10, 12, 0, 0, 'Color', [0.2 0.4 0.8], 'LineWidth', 2, 'MaxHeadSize', 1, 'DisplayName', 'current 0.3 m/s');
axis equal; grid on; xlim([-10 130]); ylim([-10 70]);
xlabel('east [m]'); ylabel('north [m]'); legend('Location','southeast');
title('a current from the west: LOS sits beside each leg, ILOS on it');
exportgraphics(f, fullfile(here, 'img', 'W05_result_tuning.png'), 'Resolution', 150);
