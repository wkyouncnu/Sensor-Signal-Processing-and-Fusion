%% W04 · 실험 4-5 — 튜닝 순서, 그리고 큰 선회 / Experiment 4-5 — the tuning order, and a big turn
%
%  이 절이 묻는 것 / the question
%      모델 없이 측정만으로 Kp, Kd, Ki 를 고르고, 모멘트 한계가 있을 때 되감기 이득 Kb 를
%      어떻게 고르는가?
%      How are Kp, Kd and Ki chosen from measurements alone, and how is the
%      back-calculation gain Kb chosen when the moment is limited?
%
%  요구 / the requirement
%      10 도 선회를 3 s 안에 2 % 안으로 오버슛 5 % 미만; 약한 프로펠러에도 오차 없음;
%      90 도 선회에서 되감김 없음.
%      A 10 deg turn inside 2 % within 3 s with overshoot below 5 %; no error with
%      a weak propeller; no windup in a 90 deg turn.
%
%  이 스크립트가 하는 일 / what this script does — 튜닝 순서 그대로 / the tuning order, step by step
%      1-2 단계  P 만: 오버슛 12.2 % — 울리므로 D 를 넣는다.
%      3 단계    Kd 를 25, 50, 100, 150 으로 올려 정착이 가장 빠른 값(100)을 고른다.
%      4 단계    약한 좌현 프로펠러(0.7)가 남긴 오차를 Ki = 20 으로 없앤다.
%      5 단계    Kb = 0, 0.05, 0.1, 1 을 세 선회(10 도, 약한 프로펠러, 90 도)에서 비교한다.
%      1~4 단계는 Kb = 0 으로 돌린다: Ki = 0 인데 Kb 가 켜져 있으면 되감기가 적분을 혼자 움직인다.
%      Steps 1-2  P only: 12.2 % overshoot — it rings, so D is added.
%      Step 3     raise Kd through 25, 50, 100, 150; keep the fastest settling (100).
%      Step 4     remove the error of a weak port propeller (0.7) with Ki = 20.
%      Step 5     compare Kb = 0, 0.05, 0.1, 1 on three turns (10 deg, weak
%                 propeller, 90 deg).
%      Steps 1 to 4 run with Kb = 0: with Ki = 0 and Kb on, back-calculation
%      alone would move the integral.
%
%  출력에서 볼 것 / what to look for in the output
%      - Kb = 0: 90 도 선회에서 적분이 쌓여 15.6 % 오버슛, 37 s.
%      - Kb = 1: 적분이 -250 N m 까지 끌려 내려가 배가 멈춰 선다, 48.5 s.
%      - Kb = 0.1: 90 도 선회가 PD 와 거의 같게 5.80 s, 오버슛 없음. 대신 약한 프로펠러의
%        보정은 9.38 s 로 느려진다 — Kb 는 절충이다.
%      - Kb = 0: the integral piles up in the 90 deg turn; 15.6 % overshoot, 37 s.
%      - Kb = 1: the integral is dragged to -250 N m and the vessel stalls; 48.5 s.
%      - Kb = 0.1: the 90 deg turn settles in 5.80 s without overshoot, almost as
%        PD alone; the weak-propeller correction slows to 9.38 s — a trade-off.
%
%  만드는 것 / produces: img/W04_result_tuning.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
m = 'W04_H_tuning';
%  M(R, 목표): 목표 기준 오버슛(음수는 0)과 정착시간 (맨 아래 함수)
%  M(R, target): overshoot (negative shown as 0) and settling time (function at the bottom)
M = @(R, target) metrics(R, target);

fprintf('\n  W04 Experiment 4-5  the tuning order on the heading\n');

%% 1-2) P 만 / P only
[Mp, ts] = M(W04_read(m, 'Kd', 0, 'Ki', 0, 'Kb', 0), 10);
fprintf('    1-2  Kp = 300 (10 deg asks 52 N m of the 70.8 available): overshoot %.1f %%, settle %.2f s: it rings, so D\n', Mp, ts);

%% 3) Kd 를 올린다 / raise Kd
fprintf('    3    Kd = ');
for Kd = [25 50 100 150]
    [Mp, ts] = M(W04_read(m, 'Kd', Kd, 'Ki', 0, 'Kb', 0), 10);
    fprintf('%g: %.2f %%, %.2f s   ', Kd, Mp, ts);
end
fprintf('-> Kd = 100 (fastest settling)\n');

%% 4) 약한 좌현 프로펠러와 Ki / a weak port propeller, and Ki
R = W04_read(m, 'Ki', 0, 'Kb', 0, 'port_eff', 0.7);
fprintf('    4    weak port propeller (0.7): PD leaves %.2f deg;', 10 - R.psi(end));
R = W04_read(m, 'Kb', 0, 'port_eff', 0.7);  [Mp, ts] = M(R, 10);
fprintf(' Ki = 20 removes it: %.3f deg left, settle %.2f s\n', 10 - R.psi(end), ts);

%% 5) 모멘트 한계와 Kb: 세 선회로 비교 / the moment limit and Kb, on three turns
fprintf('    5    the moment limit: Kb against three turns (settle [s], overshoot %%)\n');
fprintf('         Kb      10 deg turn        weak propeller     90 deg turn\n');
f = lab_fig('W04 Exp 4-5  tuning', 1000, 620);
for Kb = [0 0.05 0.1 1]
    [M1, t1] = M(W04_read(m, 'Kb', Kb), 10);                          % 10 도 선회 / 10 deg turn
    [M2, t2] = M(W04_read(m, 'Kb', Kb, 'port_eff', 0.7), 10);         % 약한 프로펠러 / weak propeller
    R = W04_read(m, 'Kb', Kb, 'psi_step', 90, 'T_final', 60);  [M3, t3] = M(R, 90);   % 90 도 선회 / 90 deg turn
    fprintf('         %-6g  %5.2f s  %5.2f %%   %5.2f s  %5.2f %%   %5.2f s  %5.2f %%\n', Kb, t1, M1, t2, M2, t3, M3);

    %  90 도 선회만 그린다: 위 선수각, 아래 적분항 / only the 90 deg turn is drawn
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_b = %g', Kb));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_b = %g', Kb));
end

%  비교용: 적분이 아예 없는 PD 의 90 도 선회 / for comparison: the 90 deg turn with PD alone
[Mp, ts] = M(W04_read(m, 'psi_step', 90, 'Ki', 0, 'Kb', 0, 'T_final', 60), 90);
fprintf('         PD alone, 90 deg turn: %.2f s, %.2f %%\n', ts, Mp);
fprintf('         final: Kp = 300, Kd = 100, Ki = 20, Kb = 0.1\n');

%% 6) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); yline(90, 'k--', 'HandleVisibility','off'); grid on; xlim([0 50]);
ylabel('\psi [deg]'); legend('Location','southeast'); title('a 90 deg turn: too little K_b overshoots, too much stalls short');
subplot(2,1,2); grid on; xlim([0 50]); ylabel('I [N m]'); xlabel('time [s]');
title('the integral: piled up (K_b = 0) or dragged far below zero (K_b = 1)');
exportgraphics(f, fullfile(here, 'img', 'W04_result_tuning.png'), 'Resolution', 150);

%% 목표 기준의 지표 / metrics against the target
function [Mp, ts] = metrics(R, target)
[Mp, ts] = step_metrics(R.t, R.psi, target, 5);
Mp = max(Mp, 0);
end
