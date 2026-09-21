%% W02 · 절 I — 튜닝 순서를 따라가 본다 / Section I — the tuning order, step by step
%  모델 W02_I_tuning 에서 §2-9 의 순서를 그대로 밟는다:
%    1 P 만, Kp 는 단위로 (스프링 k = 2 N/m 의 다섯 배)   2 P 응답의 오버슛에서 감쇠비를 읽는다
%    3 오버슛이 더 줄지 않을 때까지 Kd 를 올린다         4 오차가 남으면 1 % 안에 3 초 안에 들 때까지 Ki
%    5 힘을 본다 (30 N 이 있다고 하자) — 넘으면 목표를 부드럽게
%  Follows §2-9 on W02_I_tuning: P only (Kp from the units), read zeta from the overshoot,
%  raise Kd until the overshoot stops falling, add Ki until inside 1 % in 3 s, then check the force.
%  만드는 것 / produces: img/W02_result_tuning.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
run1 = @(varargin) W02_read('W02_I_tuning', varargin{:});    % "run" 은 MATLAB 명령이라 쓰지 않는다
os   = @(R) step_metrics(R.t, R.y, mean(R.y(R.t > 9)), 1);   % 도달한 값 대비 오버슛 / vs the value reached

% 1-2
Kp = 5*2;  S1 = run1('Kp', Kp, 'Ki', 0, 'Kd', 0);  M1 = os(S1);
L = log(M1/100);
fprintf('\n  W02 I  the tuning order\n');
fprintf('    1-2  Kp = %g: overshoot %.1f %% -> damping ratio %.3f (formula %.3f): it rings, so D next\n', ...
        Kp, M1, -L/sqrt(pi^2 + L^2), 2/(2*sqrt(2 + Kp)));
% 3
Kd = 0;  M3 = M1;  S3 = S1;  T = M1;
while true
    Sn = run1('Kp', Kp, 'Ki', 0, 'Kd', Kd + 1);  Mn = os(Sn);  T(end+1) = Mn; %#ok<SAGROW>
    if Mn >= M3, break; end
    Kd = Kd + 1;  M3 = Mn;  S3 = Sn;
end
fprintf('    3    Kd = 0,1,...: overshoot %s %%  -> stops falling at Kd = %g\n', sprintf('%.2f ', T), Kd);
% 4
for Ki = 1:100
    S4 = run1('Kp', Kp, 'Ki', Ki, 'Kd', Kd);
    if settle1(S4) < 3, break; end
end
fprintf('    4    error left %.3f -> Ki = %g: inside 1 %% after %.2f s, overshoot %.2f %%\n', ...
        1 - mean(S3.y(S3.t > 9)), Ki, settle1(S4), step_metrics(S4.t, S4.y, 1, 1));
% 5
S5 = run1('Kp', Kp, 'Ki', Ki, 'Kd', Kd, 'ref_filter', 1);
fprintf('    5    peak force %.1f N against 30 N available -> smoothed setpoint: %.1f N, inside 1 %% after %.2f s\n', ...
        max(abs(S4.tau)), max(abs(S5.tau)), settle1(S5));

S = {S1, S3, S4, S5};
T = {sprintf('1-2  P only, K_p = %g', Kp), sprintf('3  + D, K_d = %g', Kd), ...
     sprintf('4  + I, K_i = %g', Ki), '5  setpoint smoothed'};
f = lab_fig('W02 I  tuning', 1150, 640);
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
