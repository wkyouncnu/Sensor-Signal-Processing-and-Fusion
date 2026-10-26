%% W06 · 실험 6-1 — 세 축을 따로 명령한다 / Experiment 6-1 — commanding the three axes one at a time
%
%  이 절이 묻는 것 / the question
%      B 가 정사각이고 계급이 3 이면 "세 축을 따로 쓸 수 있다" 가 수학이다.
%      선체에서도 그런가? 한 축만 요구했을 때 나머지 둘은 0 으로 남는가?
%      A square B of rank 3 says, as algebra, that the three axes are
%      independent. Does the hull agree? When one axis is demanded, do the other
%      two stay at zero?
%
%  이 스크립트가 하는 일 / what this script does
%      ① W06_C_actuation 을 네 가지 요구로 돌린다 — 전진만 · 횡만 · 선회만 · 셋 함께.
%      ② 배분기가 **실제로** 낸 힘을 축 회전수에서 되돌려 요구와 대조한다.
%      ③ 20 초 뒤의 u · v · r 과 궤적을 그린다.
%      ① Runs W06_C_actuation with four demands: surge only, sway only, yaw
%         only, and all three together.
%      ② Recovers the force the allocation ACTUALLY produced from the shaft
%         speeds and compares it against the demand.
%      ③ Prints u, v and r after 20 s and draws the four tracks.
%
%  출력에서 볼 것 / what to look for in the output
%      - 되돌린 힘이 요구와 **같다** (잔차 1.8e-15 ~ 1.4e-14 N). 자르지 않았으면 배분은 정확하다.
%      - 횡만 요구하면 v = 0.344 m/s 로 **옆으로** 간다. 저구동 선체가 할 수 없는 것이 이것이다.
%      - 그 횡이동을 선미 둘이 **서로 반대로** 만든다: n_L = -85.82, n_R = +65.45.
%        크기가 다른 것은 후진 계수가 작기 때문이고 (k_neg < k_pos), 6-2 절이 센다.
%      - 그런데 그 칸의 아래 그림에서 선수각이 **-3.00 도** 돌았다가 멈춘다. 배분은
%        N = 0 을 정확히 냈는데도 그렇다 — 축을 갈라 놓는 것은 **B** 이지 **M** 이
%        아니기 때문이다. 정지 상태에서 Y 를 걸면 감쇠가 아직 0 이라
%        M [v̇; ṙ] = [Y; 0] 이고, 부가질량 결합 M(2,6) = 12.25 가
%        ṙ = -2.588 deg/s² 를 만든다. v̇ 이 잦아들면 r 도 0 으로 돌아가므로
%        (최대 1.18 deg/s, 끝에서 -1.5e-07) 각도만 남는다. **열린 루프의 한계**이고,
%        6-6 절의 선수각 루프가 이것을 되돌린다.
%      - The recovered force equals the demand to between 1.8e-15 and 1.4e-14 N:
%        with nothing clipped, the allocation is exact.
%      - The sway-only demand gives v = 0.344 m/s: the hull moves SIDEWAYS, which
%        is what an under-actuated hull cannot do. The stern pair make that sway
%        by OPPOSING each other, n_L = -85.82 against n_R = +65.45, the
%        magnitudes differing because the astern coefficient is the smaller one,
%        k_neg < k_pos, as Section 6-2 counts.
%      - Yet the lower panel of that column shows the heading swinging to -3.00
%        deg and stopping, although the allocation delivered N = 0 exactly. What
%        separates the axes is B, not M. Applied from rest, with damping still
%        zero, M [vdot; rdot] = [Y; 0], and the added-mass coupling M(2,6) =
%        12.25 returns rdot = -2.588 deg/s^2. The rate peaks at 1.18 deg/s and
%        comes back to -1.5e-07 deg/s once vdot dies away, leaving the angle
%        behind. This is the limit of open loop; the heading loop of Section 6-6
%        takes it back.
%
%  만드는 것 / produces: img/W06_result_actuation.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 네 가지 요구 / four demands
D = {'surge only   X', [60  0  0]
     'sway only    Y', [ 0 25  0]
     'yaw only     N', [ 0  0 20]
     'all three',      [40 15 10]};
V = W06_vars();
fprintf('\n  W06 Experiment 6-1  three axes, commanded one at a time  (open loop, 20 s)\n');
fprintf('    demand [N, N, N m]      n_L      n_R     F_B [N]    delivered [N, N, N m]      residual     u       v      r [deg/s]\n');
Rs = cell(size(D,1), 1);
for i = 1:size(D,1)
    c = D{i,2}(:);
    Rs{i} = W06_read('W06_C_actuation', 'X_cmd', c(1), 'Y_cmd', c(2), 'N_cmd', c(3), ...
                     'T_final', 20);
    R = Rs{i};

    %  배분기가 **실제로** 낸 힘. 축 회전수를 추력으로 되돌려 (W06_read) 열 규칙
    %  B 로 다시 곱한다 — 요구를 그대로 믿지 않는다
    %  the force actually produced: the shaft speeds back through the thrust
    %  curve, then through the column rule B. The demand itself is not trusted
    tau = V.B * [R.T_L(end); R.T_R(end); R.F_B(end)];
    fprintf('    %-16s  %7.2f  %7.2f  %8.2f    %7.2f %7.2f %8.2f    %9.2e  %6.3f  %6.3f  %8.3f\n', ...
            D{i,1}, R.n_L(end), R.n_R(end), R.F_B(end), tau(1), tau(2), tau(3), ...
            norm(tau - c), R.u(end), R.v(end), R.r(end)*180/pi);
end

%% 2) 네 칸을 **같은 축척**으로 그린다 / four panels, one common scale
%  칸마다 축을 따로 맞추면 "제자리에서 돈다" 와 "15 m 를 간다" 가 같은 크기로 보인다.
%  Scaling each panel to its own track would draw "spins in place" and "runs 15 m"
%  at the same size, which is the opposite of what the figure has to say.
P = cell2mat(cellfun(@(R) [min(R.N) max(R.N) min(R.E) max(R.E)], Rs, 'Uni', 0));
c0 = [mean([min(P(:,1)) max(P(:,2))]), mean([min(P(:,3)) max(P(:,4))])];
half = max(max(P(:,2)) - min(P(:,1)), max(P(:,4)) - min(P(:,3)))/2 + 2;
%  아래 줄이 선수각이다. 선회만 요구한 칸은 배가 **제자리에서** 돌기 때문에 선체
%  표시 다섯이 한 점에 겹쳐 위 칸만으로는 회전이 보이지 않는다
%  The lower row is heading. In the yaw-only panel the hull does not translate,
%  so its five marks sit on one point and the turn is invisible from the track
f = lab_fig('W06 C  three axes', 1180, 560);
for i = 1:size(D,1)
    R = Rs{i};  c = D{i,2};
    subplot(2, 4, i); hold on; grid on; axis equal;
    plot(R.E, R.N, 'Color', [0 0.45 0.74], 'LineWidth', 1.3);
    track_ships({[R.N R.E R.psi*pi/180]}, [0 0.45 0.74], 'Marks', 5);
    xlim(c0(2) + [-half half]);  ylim(c0(1) + [-half half]);
    xlabel('east [m]');  if i == 1, ylabel('north [m]'); end
    title(sprintf('%s\n\\tau = [%g %g %g]', D{i,1}, c(1), c(2), c(3)));

    subplot(2, 4, i + 4); hold on; grid on;
    plot(R.t, R.psi, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.3);
    xlim([0 20]);  ylim([-30 210]);
    xlabel('time [s]');  if i == 1, ylabel('\psi [deg]'); end
end

%% 3) 그림을 저장한다 / save the figure
exportgraphics(f, fullfile(here, 'img', 'W06_result_actuation.png'), 'Resolution', 150);
