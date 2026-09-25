%% W02 · 실험 2-12 — 튜닝 순서를 따라가 본다 / Experiment 2-12 — the tuning order, step by step
%  모델 W02_I_tuning 에서 §2-12 의 순서를 그대로 밟는다:
%    1 P 만, Kp 는 단위로 (스프링 k = 2 N/m 의 다섯 배)   2 P 응답의 오버슛에서 감쇠비를 읽는다
%    3 오버슛이 더 줄지 않을 때까지 Kd 를 올린다         4 오차가 남으면 1 % 안에 3 초 안에 들 때까지 Ki
%    5 힘을 본다 (30 N 이 있다고 하자) — 넘으면 목표를 부드럽게
%  Follows §2-12 on W02_I_tuning: P only (Kp from the units), read zeta from the overshoot,
%  raise Kd until the overshoot stops falling, add Ki until inside 1 % in 3 s, then check the force.
%
%  출력에서 볼 것 / what to look for in the output
%      - 1-2 단계: 오버슛 38.8 % 에서 읽은 감쇠비 0.289 가 공식값과 같다 — 울리므로 D.
%      - 3 단계: Kd 를 1 씩 올리면 오버슛이 38.77 -> 8.60 % 로 줄다가 Kd = 7 에서 다시 는다 -> Kd = 6.
%      - 4 단계: 남은 오차 0.167 -> Ki = 8 에서 2.77 s 안에 1 % 안.
%      - 5 단계: 응답은 합격인데 힘이 129.6 N (30 N 뿐) — 목표를 부드럽게 하면 13.9 N.
%      - Steps 1-2: the damping ratio 0.289 read from 38.8 % overshoot equals the
%        formula — it rings, so D.
%      - Step 3: raising Kd by 1 lowers the overshoot 38.77 -> 8.60 % until it
%        rises again at Kd = 7 -> Kd = 6.
%      - Step 4: error left 0.167 -> Ki = 8, inside 1 % after 2.77 s.
%      - Step 5: the response passes, but the force is 129.6 N against 30 N;
%        a smoothed setpoint brings it to 13.9 N.
%
%  만드는 것 / produces: img/W02_result_tuning.png

%% 0) 경로와 도우미 / paths and helpers
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  run1(...): W02_I_tuning 을 한 번 돌린다 ("run" 은 MATLAB 명령이라 이름으로 쓰지 않는다)
%  run1(...): one run of W02_I_tuning ("run" is a MATLAB command, so not used as a name)
%  os(R):     도달한 값 대비 오버슛 [%] / overshoot [%] against the value reached
run1 = @(varargin) W02_read('W02_I_tuning', varargin{:});    % "run" 은 MATLAB 명령이라 쓰지 않는다
os   = @(R) step_metrics(R.t, R.y, mean(R.y(R.t > 9)), 1);   % 도달한 값 대비 오버슛 / vs the value reached

%% 1-2) P 만. Kp 의 크기는 단위에서: 스프링 k = 2 N/m 의 다섯 배. 오버슛에서 감쇠비를 거꾸로 읽는다
%       P only. The scale of Kp from the units: five times the spring k = 2 N/m.
%       The damping ratio is read back from the overshoot
Kp = 5*2;  S1 = run1('Kp', Kp, 'Ki', 0, 'Kd', 0);  M1 = os(S1);
L = log(M1/100);
fprintf('\n  W02 Experiment 2-12  the tuning order\n');
fprintf('    1-2  Kp = %g: overshoot %.1f %% -> damping ratio %.3f (formula %.3f): it rings, so D next\n', ...
        Kp, M1, -L/sqrt(pi^2 + L^2), 2/(2*sqrt(2 + Kp)));
%% 3) Kd 를 1 씩 올리고, 오버슛이 더 줄지 않으면 멈춘다
%     Raise Kd by 1 and stop when the overshoot no longer falls
Kd = 0;  M3 = M1;  S3 = S1;  T = M1;
while true
    Sn = run1('Kp', Kp, 'Ki', 0, 'Kd', Kd + 1);  Mn = os(Sn);  T(end+1) = Mn; %#ok<SAGROW>
    if Mn >= M3, break; end
    Kd = Kd + 1;  M3 = Mn;  S3 = Sn;
end
fprintf('    3    Kd = 0,1,...: overshoot %s %%  -> stops falling at Kd = %g\n', sprintf('%.2f ', T), Kd);
%% 4) 오차가 남으므로 Ki 를 1 씩 올려, 3 s 안에 1 % 안에 드는 첫 값에서 멈춘다
%     An error is left, so raise Ki by 1 and stop at the first value inside 1 % within 3 s
for Ki = 1:100
    S4 = run1('Kp', Kp, 'Ki', Ki, 'Kd', Kd);
    if settle1(S4) < 3, break; end
end
fprintf('    4    error left %.3f -> Ki = %g: inside 1 %% after %.2f s, overshoot %.2f %%\n', ...
        1 - mean(S3.y(S3.t > 9)), Ki, settle1(S4), step_metrics(S4.t, S4.y, 1, 1));
%% 5) 힘을 본다 (30 N 이 있다고 하자). 넘으면 목표를 1/(0.3 s + 1) 로 부드럽게 (ref_filter = 1)
%     Look at the force (say 30 N is available); if exceeded, smooth the setpoint (ref_filter = 1)
S5 = run1('Kp', Kp, 'Ki', Ki, 'Kd', Kd, 'ref_filter', 1);
fprintf('    5    peak force %.1f N against 30 N available -> smoothed setpoint: %.1f N, inside 1 %% after %.2f s\n', ...
        max(abs(S4.tau)), max(abs(S5.tau)), settle1(S5));

%% 6) 그림: 네 단계, 위 위치, 아래 힘 / figure: four stages, position on top, force below
S = {S1, S3, S4, S5};
T = {sprintf('1-2  P only, K_p = %g', Kp), sprintf('3  + D, K_d = %g', Kd), ...
     sprintf('4  + I, K_i = %g', Ki), '5  setpoint smoothed'};
f = lab_fig('W02 Exp 2-12  tuning', 1150, 640);
for i = 1:4
    subplot(2,4,i); hold on; plot(S{i}.t, S{i}.y_d, 'k--'); plot(S{i}.t, S{i}.y, 'LineWidth', 2);
    ylim([0 1.5]); xlim([0 8]); grid on; title(T{i});  if i == 1, ylabel('position [m]'); end
    subplot(2,4,4+i); hold on; plot(S{i}.t, S{i}.tau, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6);
    yline(30, 'k:', '30 N available'); xlim([0 8]); grid on; xlabel('time [s]');
    title(sprintf('peak %.1f N', max(abs(S{i}.tau))));  if i == 1, ylabel('force \tau [N]'); end
end
exportgraphics(f, fullfile(here, 'img', 'W02_result_tuning.png'), 'Resolution', 150);

function ts = settle1(S)
%  1 % 띠를 마지막으로 벗어난 때 (t = 1 s 부터), 끝까지 밖이면 inf / last exit from the 1 % band
o = find(abs(S.y - 1) > 0.01 & S.t >= 1, 1, 'last');
if isempty(o), ts = 0; elseif o == numel(S.t), ts = inf; else, ts = S.t(o) - 1; end
end
