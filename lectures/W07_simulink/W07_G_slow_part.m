%% W07 · 실험 7-6 — 걸러서는 안 되는 부분 / Experiment 7-6 — the part that must not be filtered
%
%  이 절이 묻는 것 / the question
%      바다는 흔들기만 하지 않는다. 느리게 **밀기도** 한다. 그 부분은 어떻게 되는가?
%      The sea does not only shake the vessel; it also pushes it, slowly. What of that?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W07_G_slow 를 적분 없이(Ki = 0) 한 번, 적분과 함께 한 번 돌린다.
%         두 실행 모두 노치가 걸려 있고, 느린 요 모멘트 15 N m 가 선체에 더해진다.
%      ② 마지막 60 s 의 평균 선수각 오차와 평균 모멘트를 찍는다.
%      ③ 선수각과 모멘트를 그린다.
%      ① Runs W07_G_slow twice, with Ki = 0 and with the integral. Both have the
%         notch, and both receive a slow 15 N m yaw moment on the hull.
%      ② Prints the mean heading error and the mean moment over the last 60 s.
%      ③ Plots the heading and the moment.
%
%  출력에서 볼 것 / what to look for in the output
%      - 노치는 이 느린 외란을 **통과시킨다**: w0 에서만 내려가고 0.1 rad/s 에서는 1 이다.
%      - 적분이 없으면 3.07 도의 오차가 남는다. 300 x 3.07 도 = 16 N m 가 그 오차로 만든 힘이다.
%      - 적분을 켜면 0.08 도로 준다. 파랑은 평균이 0 이므로 적분이 그것을 쌓지 않는다.
%      - The notch **passes** this disturbance: it dips only at w0 and is unity at 0.1 rad/s.
%      - Without the integral a 3.07 deg error remains, which is what produces the
%        16 N m the vessel needs: 300 x 3.07 deg.
%      - With it the error falls to 0.08 deg. A wave has zero mean, so the
%        integral does not wind up on it.
%
%  만드는 것 / produces: img/W07_result_slow.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 적분 없이, 그리고 적분과 함께 / without the integral, and with it
fprintf('\n  W07 Experiment 7-6  a slow disturbance of %g N m, varying over %g s\n', ...
        subsref(W07_vars(), substruct('.','N_slow')), subsref(W07_vars(), substruct('.','T_slow')));
fprintf('    %-22s  mean heading error   mean moment   heading std\n', 'controller');
NAME = {'P-D  (Ki = 0)', 'PI-D'};  KI = [0 20];  RUN = cell(1,2);
for i = 1:2
    R = W07_read('W07_G_slow', 'Ki', KI(i), 'T_final', 120);
    RUN{i} = R;  j = R.t > 60;
    fprintf('    %-22s %14.3f deg %12.2f Nm %10.3f deg\n', NAME{i}, ...
            mean(R.psi(j)) - R.V.psi_step, mean(R.N(j)), std(R.psi(j)));
end

%% 2) 선수각과 모멘트 / the heading and the moment
fg = lab_fig('W07 Exp 7-6  the slow part', 1000, 620);
subplot(2,1,1); hold on; grid on;
for i = 1:2, plot(RUN{i}.t, RUN{i}.psi, 'LineWidth', 1.8, 'DisplayName', NAME{i}); end
yline(RUN{1}.V.psi_step, 'k--', 'HandleVisibility','off');
ylabel('\psi [deg]'); legend('Location','southeast');
title('a slow push: without an integral the vessel settles beside the command, not on it');
subplot(2,1,2); hold on; grid on;
for i = 1:2, plot(RUN{i}.t, RUN{i}.N, 'LineWidth', 1.2, 'DisplayName', NAME{i}); end
ylabel('N [N m]'); xlabel('time [s]'); legend('Location','southeast');
title('both hold about -15 N m against the disturbance; only one does it without an error');
exportgraphics(fg, fullfile(here, 'img', 'W07_result_slow.png'), 'Resolution', 150);
