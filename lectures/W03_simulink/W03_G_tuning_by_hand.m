%% W03 · 절 G — 2주차의 튜닝 순서를 Otter 에 / Section G — the Week 2 tuning order on the Otter
%
%  이 절이 묻는 것 / the question
%      배의 모델 없이, Scope 에서 잰 것만으로 세 게인을 어떻게 고르는가?
%      How are the three gains chosen from measurements alone, with no model
%      of the vessel?
%
%  요구 / the requirement
%      1.5 m/s 계단에 대해 3 s 안에 2 % 안으로, 오버슛 5 % 미만, 추력은 한계 안.
%      For a 1.5 m/s step: inside 2 % within 3 s, overshoot below 5 %, thrust
%      within its limit.
%
%  이 스크립트가 하는 일 / what this script does — 튜닝 순서 그대로 / the tuning order, step by step
%      1-2 단계  P 만 (Ki = 0, Kb = 0) 돌리고 오버슛·상승시간·남은 오차를 읽는다.
%      3 단계    울리지 않으므로 D 는 넣지 않는다 (절 E 에서 D 는 나빠지기만 했다).
%      4 단계    Ki 를 50, 100, 200 으로 올리며 요구를 처음 만족하는 값에서 멈춘다.
%      5 단계    힘을 본다: 계단 명령과 부드럽게 한 명령의 최대 추력과 한계에 붙은 시간.
%      Steps 1-2  run P alone (Ki = 0, Kb = 0) and read the overshoot, rise time
%                 and error left.
%      Step 3     no ringing, so no D (in section E, D only made things worse).
%      Step 4     raise Ki through 50, 100, 200 and stop at the first value that
%                 meets the requirement.
%      Step 5     look at the force: peak thrust and time on the limit, for the
%                 step command and for a smoothed one.
%
%  출력에서 볼 것 / what to look for in the output
%      - 최종 게인 Kp = 200, Ki = 200, Kd = 0, Kb = 1 — 오버슛 0.56 %, 정착 1.40 s.
%      - 계단 명령은 0.2 s 동안 추력 한계에 닿는다. 부드럽게 한 명령은 닿지 않고 대신 느리다.
%      - The final gains Kp = 200, Ki = 200, Kd = 0, Kb = 1: overshoot 0.56 %,
%        settled in 1.40 s.
%      - The step command touches the thrust limit for 0.2 s; the smoothed one
%        never does, and arrives later.
%
%  만드는 것 / produces: img/W03_result_tuning.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  M(R): 목표 1.5 기준의 오버슛과 정착시간 (맨 아래 함수). 1.5 에 못 닿으면 정착시간은 Inf.
%  M(R): overshoot and settling time against 1.5 (function at the bottom);
%  settling is Inf when 1.5 is never reached.
M = @(R) deal_metrics(R);

fprintf('\n  W03 G  the tuning order on the Otter\n');

%% 1-2) P 만: 되감기도 끈다 — Ki = 0 인데 Kb 가 켜져 있으면 되감기가 적분을 혼자 움직인다
%       P only, with back-calculation off too: with Ki = 0 and Kb on, back-calculation
%       alone would move the integral
R = W03_read('W03_G_tuning', 'Ki', 0, 'Kb', 0);                % P 만 / P only
[Mp, ~, tr] = step_metrics(R.t, R.u, R.u(end), 5);
fprintf('    1-2  Kp = 200: overshoot %.1f %%, rise %.2f s, error left %.3f m/s\n', max(Mp,0), tr, 1.5 - R.u(end));

%% 3) D 는 울림을 줄이는 항이다. 울림이 없으면 넣지 않는다
%     D reduces ringing; with no ringing it is left out
fprintf('    3    no ringing, so nothing for D to damp: Kd = 0 (section E: D only adds overshoot)\n');

%% 4) Ki 를 올리며 요구(3 s 안, 오버슛 5 % 미만)를 처음 만족하는 값에서 멈춘다
%     Raise Ki and stop at the first value meeting the requirement (3 s, below 5 %)
fprintf('    4    Ki = ');
for Ki = [50 100 200]
    R = W03_read('W03_G_tuning', 'Ki', Ki);  [Mp, ts] = M(R);
    fprintf('%g: %.2f s (%.1f %%)   ', Ki, ts, Mp);
    if ts <= 3 && Mp < 5, break; end
end
fprintf('-> Ki = %g\n', Ki);

%% 5) 힘을 본다: A = 계단 명령, B = 1/(s+1) 로 부드럽게 한 명령 (ref_filter = 1)
%     Look at the force: A = step command, B = command smoothed by 1/(s+1)
A = W03_read('W03_G_tuning');                                  % Kb = 1
B = W03_read('W03_G_tuning', 'ref_filter', 1);
[MpA, tsA] = M(A);  [MpB, tsB] = M(B);
fprintf('    5    force: %.1f N, on the thrust limit for %.2f s (anti-windup on); smoothed command: %.1f N, settle %.2f s\n', ...
        max(A.X), sum(A.X >= A.V.X_hi - 1e-6)*A.V.h, max(B.X), tsB);
fprintf('         final: Kp = 200, Ki = 200, Kd = 0, Kb = 1: overshoot %.2f %%, inside 2 %% after %.2f s\n', MpA, tsA);

%% 6) 그림: 위 속도, 아래 추력 / figure: speed on top, thrust below
f = lab_fig('W03 G  tuning', 1000, 620);
subplot(2,1,1); hold on; grid on;
plot(A.t, A.u, 'LineWidth', 2);  plot(B.t, B.u, 'LineWidth', 2);  plot(A.t, A.u_d, 'k--');
xlim([3 15]); ylabel('u [m/s]'); legend({'step command','smoothed command','command'}, 'Location','southeast');
title('the tuned loop: K_p = 200, K_i = 200, K_d = 0, K_b = 1');
subplot(2,1,2); hold on; grid on;
plot(A.t, A.X, 'LineWidth', 2);  plot(B.t, B.X, 'LineWidth', 2);  yline(A.V.X_hi, 'r:');
xlim([3 15]); ylabel('thrust X [N]'); xlabel('time [s]'); title('the step touches the thrust limit; the smoothed command never does');
exportgraphics(f, fullfile(here, 'img', 'W03_result_tuning.png'), 'Resolution', 150);

%% 목표 1.5 기준의 지표 / metrics against the command 1.5
function [Mp, ts, tr] = deal_metrics(R)
[Mp, ts, tr] = step_metrics(R.t, R.u, 1.5, 5);
Mp = max(Mp, 0);
if abs(R.u(end) - 1.5) > 0.03, ts = Inf; end                    % 1.5 에 못 닿음 / never reaches 1.5
end
