%% W03 · 절 F — 닿을 수 없는 속도 / Section F — an unreachable speed
%
%  이 절이 묻는 것 / the question
%      추진기가 낼 수 있는 것보다 빠른 속도를 명령하면 적분항은 무엇을 하는가?
%      그리고 되감기(back-calculation) 이득 Kb 는 무엇을 바꾸는가?
%      What does the integral do when the command is faster than the thrusters
%      can go? And what does the back-calculation gain Kb change?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W03_F_windup 에 5 s 에 3.5 m/s (Otter 는 약 3.1 m/s 가 최대),
%         30 s 에 1.5 m/s 를 명령한다. 60 s 동안 돌린다.
%      ② Kb = 0, 0.2, 1, 5 로 한 번씩 돌려, 30 s 의 속도와 적분항, 1.5 m/s 의
%         2 % 안으로 돌아오는 데 걸린 시간, 그 뒤의 최저 속도를 찍는다.
%      ③ 속도(위)와 적분항(아래)을 그려 저장한다.
%      ① Commands 3.5 m/s at 5 s (the Otter tops out near 3.1 m/s) and 1.5 m/s
%         at 30 s to W03_F_windup, for 60 s.
%      ② Runs Kb = 0, 0.2, 1, 5 and prints the speed and integral at 30 s, the
%         time to return within 2 % of 1.5 m/s, and the lowest speed after it.
%      ③ Plots the speed (top) and the integral (bottom) and saves the figure.
%
%  출력에서 볼 것 / what to look for in the output
%      - 30 s 까지 네 경우의 속도는 같다 (추력이 같으니 배도 같다).
%      - Kb = 0 이면 적분항이 2747 N 까지 쌓이고, 명령이 내려가도 11 s 동안
%        돌아오지 못한다 — 감속 명령을 무시하는 배다.
%      - Kb = 1 이면 1.38 s 에 돌아온다. Kb = 5 는 너무 세게 비워서 1.405 m/s 까지 처진다.
%      - Until 30 s the four runs are identical: the same thrust, the same vessel.
%      - At Kb = 0 the integral piles up 2747 N and the vessel takes 11 s to
%        return after the command drops: a vessel ignoring an order to slow down.
%      - Kb = 1 returns in 1.38 s. Kb = 5 drains the integral too hard and the
%        speed dips to 1.405 m/s.
%
%  만드는 것 / produces: img/W03_result_windup.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  3.5 m/s 명령, 30 s 에 1.5 m/s 로, 60 s 동안 / 3.5 m/s, then 1.5 m/s at 30 s, for 60 s
S = {'u_step', 3.5, 't_step2', 30, 'u_step2', 1.5, 'T_final', 60};

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W03 F  3.5 m/s from 5 s (unreachable), 1.5 m/s from 30 s\n');
fprintf('    Kb     u at 30 s   I at 30 s [N]   back within 2 %% of 1.5 m/s after [s]   lowest u [m/s]\n');
f = lab_fig('W03 F  windup', 1000, 620);

%% 2) 되감기 이득 네 가지 / four back-calculation gains
for Kb = [0 0.2 1 5]
    R = W03_read('W03_F_windup', S{:}, 'Kb', Kb);

    %  30 s (명령이 내려간 순간) 뒤만 본다 / look only after 30 s, when the command drops
    k = R.t >= 30;  t = R.t(k) - 30;  u = R.u(k);

    %  1.5 의 2 % (0.03 m/s) 밖에 마지막으로 있었던 시각 = 돌아오는 데 걸린 시간
    %  The last time outside 2 % of 1.5 (0.03 m/s) = the time taken to return
    back = t(find(abs(u - 1.5) > 0.03, 1, 'last'));
    fprintf('    %-5g  %9.3f   %13.1f   %37.2f   %14.3f\n', Kb, interp1(R.t, R.u, 30), ...
            interp1(R.t, R.I, 30), back, min(u));

    %  위: 속도, 아래: 적분항 / top: speed, bottom: the integral term
    subplot(2,1,1); hold on; plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_b = %g', Kb));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_b = %g', Kb));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); grid on;
ylabel('u [m/s]'); legend('Location','northeast'); title('the same thrust, the same top speed; what differs is the return');
subplot(2,1,2); grid on; ylabel('I [N]'); xlabel('time [s]');
title('without anti-windup (K_b = 0) the integral piles up thousands of newtons');
exportgraphics(f, fullfile(here, 'img', 'W03_result_windup.png'), 'Resolution', 150);
