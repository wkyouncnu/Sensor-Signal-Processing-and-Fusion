%% W05 · 실험 5-5c — 적분기 둘 / Experiment 5-5c — the two integrators
%
%  이 절이 묻는 것 / the question
%      ILOS 의 적분기를 **어떻게** 갱신하느냐가 결과를 얼마나 바꾸는가?
%      겨냥하는 식은 둘이 글자까지 같다. 다른 것은 한 줄뿐이다:
%          보통 적분 (교과서형)   y_int' = y_e
%          비선형 적분 (Borhaug)  y_int' = Delta y_e / (Delta^2 + (y_e + kappa y_int)^2)
%      How much does the way the integral is updated change the result? The
%      aiming expression is identical in the two laws; one line differs.
%
%  왜 묻는가 / why it matters
%      조류에 맞서려면 적분이 필요하다 (5-5 절). 그런데 적분은 **경로에서 멀 때도**
%      쌓인다. 이 임무는 경로에서 20 m 떨어져 출발하므로 첫 접근이 길고, 보통 적분은
%      그동안 크게 자란다. 비선형 적분은 분모가 y_e 와 함께 커져 멀리서는 거의 쌓지
%      않는다 - 법칙 안에 들어 있는 안티와인드업이다.
%      An integral is needed against a current, but it also grows while the vessel
%      is far from the path, and this mission starts 20 m off. The nonlinear update
%      barely integrates out there: anti-windup built into the law itself.
%
%  세 번 돌린다 / three runs, because two are not enough to be fair
%      A  비선형, kappa = 0.3          5-5 절이 쓰는 법칙 그대로
%      B  보통 적분, kappa = 0.3       **같은 이득**. 공평한 비교의 출발점이다
%      C  보통 적분, kappa = 0.05      보통 적분을 **그 나름대로 튜닝한** 것
%      B 만 보이면 "교과서형은 못 쓴다" 는 과장이 된다. C 가 그 법칙의 최선이고,
%      그것과 비교해도 비선형 쪽이 과도 구간에서 낫다 - 그것이 이 절의 결론이다.
%      Showing B alone would be a straw man: C is the plain integral tuned for
%      itself, and the nonlinear law still has the better transient.
%
%  출처 / sources
%      Fossen, Handbook (2021) 12.3.5 (증명 p. 362) · Borhaug, Pavlov & Pettersen
%      (2008) DOI 10.1109/CDC.2008.4739352 · Lekkas & Fossen (2014).
%      사용자의 2025년 강의자료 "2. USV 제어기 설계" 슬라이드 66-71 이 같은 비교를 한다.
%
%  만드는 것 / produces: img/W05_result_two_integrators.png

%% 0) 준비 / setup
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
V = W05_vars();
V_c = 0.3;  beta_c = pi/2;                 % 조류 / the current: 0.3 m/s towards east

%% 1) 같은 임무, 같은 조류, 적분기만 다르게 / one mission, one current, three integrators
CASE = { 'A  nonlinear   kappa = 0.3',    3, 0.30
         'B  plain       kappa = 0.3',    4, 0.30
         'C  plain       kappa = 0.05',   4, 0.05 };
R = cell(1,3);
fprintf('\n  W05 Experiment 5-5c  the two integrators  (current %.1f m/s towards east, Delta = %g m)\n', ...
        V_c, V.Delta);
fprintf('    run                        worst swing after the first crossing [m]   |y_e| mean over the last 100 s [m]\n');
for i = 1:3
    Ri = W05_read('W05_F_ILOS', 'law', CASE{i,2}, 'kappa', CASE{i,3}, ...
                  'V_c', V_c, 'beta_c', beta_c);
    ic = find(sign(Ri.y_e) ~= sign(Ri.y_e(1)), 1);        % 처음 경로를 가로지른 순간
    fprintf('    %-26s %32.2f %36.3f\n', CASE{i,1}, ...
            max(abs(Ri.y_e(ic:end))), mean(abs(Ri.y_e(Ri.t > Ri.t(end)-100))));
    R{i} = Ri;
end

%% 2) 그림 — 왼쪽 y_e(t), 오른쪽 항적 / the figure: y_e against time, and the track
f = lab_fig('W05 5-5c  the plain and the nonlinear integrator', 1120, 470);
C = [0.85 0.33 0.10; 0 0.45 0.74; 0.47 0.67 0.19];
STY = {'-', '-', '--'};

subplot(1,2,1); hold on; grid on;
for i = 1:3
    plot(R{i}.t, R{i}.y_e, STY{i}, 'Color', C(i,:), 'LineWidth', 1.5, 'DisplayName', CASE{i,1});
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('time [s]');  ylabel('y_e  [m]');  legend('Location','northeast', 'FontSize', 8);
title('one current, one aiming law, three integrators');

subplot(1,2,2); hold on; grid on; axis equal;
plot(V.WP_E, V.WP_N, 'k--', 'HandleVisibility','off');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 10, 'MarkerFaceColor','k', 'DisplayName','waypoints');
for i = 1:3
    plot(R{i}.E, R{i}.N, STY{i}, 'Color', C(i,:), 'LineWidth', 1.3, 'DisplayName', CASE{i,1}(1));
end
xlim([-25 135]); ylim([-15 105]);
xlabel('east [m]'); ylabel('north [m]'); legend('Location','southeast', 'FontSize', 8);
title('and what that does to the track');

exportgraphics(f, fullfile(here, 'img', 'W05_result_two_integrators.png'), 'Resolution', 150);
