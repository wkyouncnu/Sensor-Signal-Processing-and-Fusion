%% W05 · 실험 5-5a — 조류 속의 LOS / Experiment 5-5a — LOS in a current
%
%  이 절이 묻는 것 / the question
%      옆으로 미는 조류가 있으면 LOS 는 경로에 붙어 있는가? 그리고 그때 배가
%      **향하는 방향**과 **가는 방향**은 얼마나 벌어지는가?
%      Does LOS hold the line when a current pushes the vessel sideways, and how far
%      apart are the direction it points and the direction it travels?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W05_F_LOS 를 동쪽 조류 0.1, 0.2, 0.3, 0.4 m/s 로 한 번씩 돌린다.
%         경로는 북쪽으로 곧은 400 m 한 다리다.
%      ② 남는 횡방향 오차와 그때 유지한 선수각을 찍고, 옆에 Delta*tan(선수각) 을 적는다.
%      ③ 항적에서 **침로** chi = atan2(E_dot, N_dot) 를 계산해 선수각과 나란히 재고,
%         조류가 없을 때와 있을 때의 평균 |chi - psi| 를 찍는다 — 그것이 크랩각이다.
%      ① Runs W05_F_LOS in an eastward current of 0.1, 0.2, 0.3 and 0.4 m/s.
%      ② Prints the offset left and the heading held, next to Delta*tan(heading).
%      ③ Computes the course over ground from the track and reports mean |chi - psi|
%         with and without a current: that difference is the crab angle.
%
%  왜 침로를 **항적에서** 계산하는가 / why the course comes from the track
%      크랩각의 정의는 beta_c = atan(v/u) 이고 그러려면 **횡방향 속도 v** 를 재야 한다.
%      이 배의 로그에는 v 가 없다 (5-5 절 10b: 그것이 적분을 쓰는 이유 중 하나다).
%      대신 지나간 자리를 미분하면 **대지침로**가 나온다 - GNSS 가 COG 를 내는 방법과
%      같고, 선수각과의 차이가 곧 크랩각이다. 잴 수 있는 것으로 재는 것이다.
%      The definition needs v, which this vessel does not log - which is itself one of
%      the reasons section 5-5 reaches for an integral. Differentiating the track gives
%      the course over ground instead, exactly as a GNSS receiver does.
%
%  출력에서 볼 것 / what to look for in the output
%      - 배는 경로와 나란히, 그러나 옆으로 비켜서 달린다. 오차가 0 이 되지 않는다.
%      - 마지막 두 열이 mm 까지 같다: 남는 오차 = Delta * tan(유지한 선수각).
%      - 조류가 없으면 침로와 선수각이 거의 같고, 0.3 m/s 에서 20 도 넘게 벌어진다.
%      - The vessel settles parallel to the path but beside it; the error does not vanish.
%      - Without a current the course and the heading nearly coincide; at 0.3 m/s they
%        part by more than twenty degrees.
%
%  만드는 것 / produces: img/W05_result_course_vs_heading.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400};   % 곧은 경로, 400 s / a straight leg, 400 s

%% 1) 조류 네 가지 / four currents
fprintf('\n  W05 Experiment 5-5a  LOS in a current flowing east  (Delta = 5 m)\n');
fprintf('    V_c [m/s]   error left [m]   heading held [deg]   Delta*tan(heading) [m]\n');
for Vc = [0.1 0.2 0.3 0.4]
    R = W05_read('W05_F_LOS', L{:}, 'law', 2, 'V_c', Vc);      % 2 = LOS
    %  마지막 값 = 정상상태 / the last sample = the steady state
    fprintf('    %-9g   %14.3f   %18.1f   %22.3f\n', Vc, R.y_e(end), R.psi(end), 5*tand(abs(R.psi(end))));
end

%% 2) 침로와 선수각 / the course and the heading, with and without a current
%     침로는 항적의 미분이다. 출발 직후에는 배가 서 있어 방향이 없으므로 t > 100 s
%     에서만 잰다 - 그 구간은 이미 정상상태다 (위 표의 마지막 값과 같은 구간).
%     The course is the derivative of the track and is undefined while the vessel is
%     still at rest, so it is measured over t > 100 s, which is already steady.
CASE = [0, 0.3];
RUN  = cell(1,2);  CHI = cell(1,2);
fprintf('\n    the direction it points and the direction it goes  (measured over t > 100 s)\n');
fprintf('      V_c [m/s]   mean |chi - psi| [deg]   heading psi [deg]   course chi [deg]\n');
for i = 1:2
    R = W05_read('W05_F_LOS', L{:}, 'law', 2, 'V_c', CASE(i));
    chi = atan2d(gradient(R.E, R.t), gradient(R.N, R.t));      % 대지침로 / course over ground
    j   = R.t > 100;
    d   = atan2d(sind(chi - R.psi), cosd(chi - R.psi));        % (-180, 180] 로 감아서 / wrapped
    fprintf('      %-9g   %21.4f   %17.1f   %16.1f\n', ...
            CASE(i), mean(abs(d(j))), mean(R.psi(j)), mean(chi(j)));
    RUN{i} = R;  CHI{i} = chi;
end

%% 3) 그림 — 슬라이드의 "효과" 를 이 배로 / the figure
f = lab_fig('W05 5-5a  course and heading, with and without a current', 1000, 420);
TTL = {'no current:  the bow points where the vessel goes', ...
       'current 0.3 m/s to the east:  it does not'};
for i = 1:2
    subplot(1,2,i); hold on; grid on;
    plot(RUN{i}.t, RUN{i}.psi, 'Color',[0.85 0.33 0.10], 'LineWidth',1.6, 'DisplayName','\psi  heading');
    plot(RUN{i}.t, CHI{i},     '--', 'Color',[0 0.45 0.74], 'LineWidth',1.6, 'DisplayName','\chi  course');
    xline(100, 'k:', 'HandleVisibility','off');
    %  세로 범위를 잘라 내지 않는다: 출발점이 경로에서 20 m 동쪽이라 처음 30 초는
    %  뱃머리를 크게 돌린다. 그 구간을 숨기면 "왜 t > 100 s 에서 재는가" 가 안 보인다.
    %  The vertical range is not clipped: the vessel starts 20 m east of the path and
    %  swings hard for the first half-minute, which is why the measurement waits.
    xlim([0 RUN{i}.t(end)]);  ylim([-100 30]);
    xlabel('time [s]');  ylabel('angle [deg]');  legend('Location','southeast');
    title(TTL{i});
end
exportgraphics(f, fullfile(here, 'img', 'W05_result_course_vs_heading.png'), 'Resolution', 150);
