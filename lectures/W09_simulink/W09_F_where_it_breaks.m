%% W09 · 실험 9-5 — 어디에서 무너지는가 / Experiment 9-5 — where it breaks
%
%  이 절이 묻는 것 / the question
%      조류를 계속 세게 하면 이 배는 어디에서 임무를 놓치는가? 그리고 **무엇이**
%      먼저 바닥나는가 — 힘인가, 판정인가?
%      Raise the current until the mission is lost: what runs out first, the
%      force, or the test that decides a waypoint has been reached?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 120 N 이 사는 속도를 먼저 잰다 — 이것이 물리적 천장이다.
%      ② 조류 0.3~1.8 m/s 를 두 번씩 돈다: 5주차의 통과 판정을 넣고, 빼고.
%      ③ 두 곡선을 함께 그리고, 1.3 m/s 에서 둘이 갈라지는 항적을 겹쳐 놓는다.
%      ① Measures the speed that 120 N buys — the physical ceiling.
%      ② Sweeps the current from 0.3 to 1.8 m/s twice: with the along-track
%         arrival test of Week 5, and with the acceptance circle alone.
%      ③ Plots both, and the two tracks at the current where they part.
%
%  출력에서 볼 것 / what to look for in the output
%      - 수락반경만 쓰면 임무는 1.3 m/s 에서 **뚝 끊긴다** — 힘이 모자라서가 아니라
%        지점을 3.67 m 옆으로 스쳐 지나가 3 m 원 안에 들어가지 못했기 때문이다.
%      - 5주차의 통과 판정을 넣으면 같은 조류에서 291.2 s 에 임무가 끝난다.
%      - 진짜 천장은 120 N 이 사는 속도 1.547 m/s 다. 1.5 m/s 에서 유지 오차가
%        11.77 m 로 무너지고, 1.8 m/s 에서는 배가 조류에 실려 간다.
%      - The circle alone loses the mission at 1.3 m/s, by 0.67 m of geometry.
%      - The real ceiling is the speed 120 N buys, and the vessel meets it at 1.5 m/s.
%
%  만드는 것 / produces: img/W09_result_limits.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 120 N 이 사는 속도 / the speed that 120 N buys
FAR = {'WP_N',[3000 3000 0]', 'WP_E',[0 3000 3000]'};
R = W09_read('W09_F_limits', 'V_c',0, 'u_d',3, 'wave_on',0, FAR{:}, 'T_final',200);
j = R.t > 150;
fprintf('\n  W09 Experiment 9-5  where it breaks\n');
fprintf('    with X held at %.0f N and no current, the vessel settles at %.3f m/s\n', ...
        mean(R.X(j)), mean(R.u(j)));

%% 2) 조류 스윕, 두 판정 규칙 / the current sweep, under both arrival rules
clear MA MB sat near TRK % 앞 절이 남긴 누적 변수를 비운다 / clear what an earlier section left
VC = [0.3 0.6 0.9 1.2 1.3 1.5 1.8];
fprintf('    V_c    |  along-track test of Week 5      |  acceptance circle alone\n');
fprintf('   [m/s]   |   T [s]   y_e [m]  hold [m]  Xsat |   T [s]   closest pass to wp1 [m]\n');
for i = 1:numel(VC)
    A = W09_read('W09_F_limits', 'V_c',VC(i), 'use_pass',1, 'T_final',600);
    B = W09_read('W09_F_limits', 'V_c',VC(i), 'use_pass',0, 'T_final',600);
    MA(i) = W09_metrics(A);  MB(i) = W09_metrics(B);                       %#ok<SAGROW>
    sat(i) = 100*mean(abs(A.X) > A.V.X_max - 1e-6);                        %#ok<SAGROW>
    near(i) = min(hypot(A.V.WP_N(1) - B.N, A.V.WP_E(1) - B.E));            %#ok<SAGROW>
    TRK(i,:) = {A, B};                                                     %#ok<SAGROW>
    fprintf('    %4.2f   |  %6.1f    %6.2f    %6.2f   %3.0f%% |  %6.1f    %8.2f\n', ...
            VC(i), MA(i).T, MA(i).ye, MA(i).hold, sat(i), MB(i).T, near(i));
end

%% 3) 두 곡선과, 갈라지는 자리의 항적 / the two curves, and the tracks where they part
f = lab_fig('W09 Exp 9-5  where it breaks', 1050, 470);
subplot(1,2,1); hold on; grid on;
yyaxis left;  plot(VC, [MA.hold], 'o-', 'LineWidth', 1.8);  ylabel('hold error [m]');
set(gca, 'YScale', 'log');
yyaxis right; plot(VC, sat, 's--', 'LineWidth', 1.4);       ylabel('X at its limit [% of run]');
plot(VC(isnan([MB.T])), zeros(1, sum(isnan([MB.T]))), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
xline(mean(R.u(j)), 'k--', 'the speed 120 N buys');
xlabel('current [m/s]');  title('x = lost by the acceptance circle alone');
k = find(VC == 1.3);   A = TRK{k,1};  B = TRK{k,2};  V = A.V;
subplot(1,2,2); hold on; grid on; axis equal;
plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
plot(B.E, B.N, 'LineWidth', 1.3);  plot(A.E, A.N, 'LineWidth', 1.3);
viscircles([V.WP_E(1) V.WP_N(1)], V.R_arrive, 'Color', [.5 .5 .5], 'LineWidth', 0.8);
xlabel('east [m]');  ylabel('north [m]');  xlim([-25 95]);  ylim([-15 145]);
title(sprintf('at V_c = %.1f m/s, the circle is missed by %.2f m', VC(k), near(k) - V.R_arrive));
legend({'path','waypoints','circle only','along-track test'}, 'Location', 'northwest');
exportgraphics(f, fullfile(here, 'img', 'W09_result_limits.png'), 'Resolution', 150);
