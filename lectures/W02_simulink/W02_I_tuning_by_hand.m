%% W02 · 절 I — 튜닝 순서를 그대로 따라가 본다
%  W02 · Section I — the tuning order, followed step by step
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_I_tuning_by_hand
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 I 이며, §2-9 의 튜닝 순서를 이 플랜트에 그대로 적용한다. 순서는
%      제어조교(Ctrl튜브)의 "짬튜닝" 영상과 MATLAB Tech Talk "Understanding PID
%      Control" 4편·6편, 그리고 캡스톤디자인 6주차 F-6 절이 권하는 것과 같다.
%      Section I of Part 2. It applies the tuning order of §2-9 to this plant.
%      The order is the one recommended by the Ctrl-tube tuning video, parts 4
%      and 6 of the MATLAB Tech Talk "Understanding PID Control", and section
%      F-6 of the Capstone Design course, week 6.
%
%  무엇을 하는가 / what it does — 각 단계가 앞 단계의 측정으로 다음 값을 고른다
%                                  each step chooses from the previous measurement
%      1  P 만. Kp 의 크기를 단위로 정한다: 오차 1 m 에 힘 몇 N 이 알맞은가.
%         P only. The scale of Kp comes from the units: how many newtons for
%         one metre of error.
%      2  P 응답을 읽는다. 오버슛에서 감쇠비를 거꾸로 구한다. 출렁이면 D 가 필요하다.
%         Read the P response: back out the damping ratio from the overshoot.
%         If it rings, D is needed.
%      3  오버슛이 더 이상 줄지 않을 때까지 Kd 를 올린다. 미분항에는 최적이 있다.
%         Raise Kd until the overshoot stops falling: the derivative has an optimum.
%      4  남는 오차가 있으면 그때 Ki 를 더한다. 1 % 안에 3 초 안에 들어오게.
%         Only if an error remains, add Ki: inside 1 % within 3 s.
%      5  힘을 본다. 액추에이터가 낼 수 있는가. 아니면 목표를 부드럽게 한다.
%         Look at the force. Can the actuator deliver it? If not, smooth the setpoint.
%
%  만드는 것 / what it produces
%      단계별 표, img/W02_result_tuning.png

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
if ~isfile(fullfile(here,'W02_pid.slx')), W02_1_build_pid(); end

V = W02_vars();
k = V.pid_k;
TS_MAX = 3;       % 1 % 정착 목표 [s] / 1 % settling target
F_MAX  = 30;      % 이 예제에서 액추에이터가 낼 수 있다고 가정한 힘 [N]
                  % the force this example's actuator is assumed to deliver
%  이름을 run 으로 짓지 않는다. 스크립트는 기본 작업공간에서 돌므로 MATLAB 의 run
%  명령을 가려 버리고, 그 뒤에 run 으로 부르는 스크립트가 모두 깨진다 (실제로 깨졌다).
%  Not named "run": a script runs in the base workspace, so the name would hide
%  MATLAB's run command and break every script called with run afterwards. It did.
simrun = @(varargin) W02_read(run_sim('W02_pid', V, varargin{:}));

fprintf('\n  W02 section I — the tuning order, applied to G(s) = 1/(s^2 + 2 s + 2)\n');
fprintf('    targets: inside 1 %% of the setpoint within %g s, |tau| < %g N\n', TS_MAX, F_MAX);

%% ---- step 1: the scale of Kp from the units ------------------------------
%  오차는 m, 힘은 N 이다. 이 플랜트의 스프링은 이미 1 m 에 k = 2 N 으로 되민다.
%  제어기가 그보다 몇 배 센 스프링이 되어야 목표로 끌고 갈 수 있다. 다섯 배,
%  Kp = 10 N/m 에서 시작한다.
%  Error is in metres and force in newtons. The plant's own spring already
%  pushes back with k = 2 N per metre; the controller has to be a spring
%  several times stiffer to pull the mass to the setpoint. Start at five
%  times, Kp = 10 N/m.
Kp = 5*k;
S1 = simrun('Kp', Kp, 'Ki', 0, 'Kd', 0);
yss = mean(S1.y(S1.t > V.T_final - 1));
Mp1 = step_metrics(S1.t, S1.y, yss, V.t_step);

%% ---- step 2: read the P response ----------------------------------------
%  오버슛 Mp 에서 감쇠비: zeta = -ln(Mp) / sqrt(pi^2 + ln(Mp)^2)
L    = log(Mp1/100);
zeta = -L/sqrt(pi^2 + L^2);
fprintf(['\n    step 1  P only, Kp = %g N/m (five times the %g N/m the spring already provides)\n' ...
         '            overshoot %.1f %%, steady value %.3f, error left %.3f\n'], ...
        Kp, k, Mp1, yss, V.y_step - yss);
fprintf(['    step 2  read it: an overshoot of %.1f %% means a damping ratio of %.3f\n' ...
         '            (the model says b/(2 sqrt(k + Kp)) = %.3f). Well below 1: it rings,\n' ...
         '            so the next term is D, not I.\n'], ...
        Mp1, zeta, V.pid_b/(2*sqrt(k + Kp)));

%% ---- step 3: raise Kd while the overshoot keeps falling -----------------
%  미분항에는 최적이 있다. 오차를 미분하면 영점 -Kp/Kd 가 생기고, Kd 가 커질수록
%  그 영점이 원점으로 다가와 응답을 다시 밀어 올린다 (§2-4). 그래서 목표치를 정해
%  두고 올리지 않고, 오버슛이 더 이상 줄지 않는 곳에서 멈춘다.
%  The derivative has an optimum: differentiating the error adds a zero at
%  -Kp/Kd, which moves towards the origin as Kd grows and pushes the response
%  up again (§2-4). So Kd is not raised towards a target; it is raised until
%  the overshoot stops falling.
Kd = 0;  S3 = S1;  Mp3 = Mp1;  TRACE = [0 Mp1];
while true
    Sn = simrun('Kp', Kp, 'Ki', 0, 'Kd', Kd + 1);
    yn = mean(Sn.y(Sn.t > V.T_final - 1));
    Mn = step_metrics(Sn.t, Sn.y, yn, V.t_step);
    TRACE(end+1,:) = [Kd + 1, Mn]; %#ok<SAGROW>
    if Mn >= Mp3, break; end
    Kd = Kd + 1;  S3 = Sn;  Mp3 = Mn;
end
yss3 = mean(S3.y(S3.t > V.T_final - 1));
fprintf('    step 3  raise Kd in steps of 1 while the overshoot keeps falling:\n');
fprintf('              Kd        %s\n', sprintf('%7g', TRACE(:,1)));
fprintf('              overshoot %s   [%%]\n', sprintf('%7.2f', TRACE(:,2)));
fprintf(['            it stops falling after Kd = %g N s/m (%.2f %%). The error left is\n' ...
         '            still %.3f: D cannot touch it.\n'], Kd, Mp3, V.y_step - yss3);

%% ---- step 4: add Ki only because an error remains -----------------------
for Ki = 1:1:100
    S4 = simrun('Kp', Kp, 'Ki', Ki, 'Kd', Kd);
    ts4 = settle1(S4, V);
    if ts4 < TS_MAX, break; end
end
Mp4 = step_metrics(S4.t, S4.y, V.y_step, V.t_step);
fprintf(['    step 4  an error remains, so add Ki in steps of 1 until the response is\n' ...
         '            inside 1 %% of the setpoint within %g s: Ki = %g N/(m s),\n' ...
         '            settling in %.2f s with %.2f %% overshoot.\n'], TS_MAX, Ki, ts4, Mp4);

%% ---- step 5: the force --------------------------------------------------
F4 = max(abs(S4.tau));
S5 = simrun('Kp', Kp, 'Ki', Ki, 'Kd', Kd, 'ref_filter', 1);
F5 = max(abs(S5.tau));
[Mp5, ~] = step_metrics(S5.t, S5.y, V.y_step, V.t_step);
ts5 = settle1(S5, V);
fprintf(['    step 5  look at the force: the step asks for %.1f N, against %g N available.\n' ...
         '            The spike is the derivative kick. Smooth the setpoint (Tf = %g s):\n' ...
         '            the peak falls to %.1f N; overshoot %.2f %%, settles in %.2f s.\n'], ...
        F4, F_MAX, V.ref_Tf, F5, Mp5, ts5);

fprintf('\n    %-34s %8s %8s %8s %12s %12s %14s\n', 'stage', 'Kp', 'Kd', 'Ki', ...
        'overshoot', 'settle 1%', 'peak force');
fprintf('    %s\n', repmat('-', 1, 102));
ROWS = {'1-2  P only',             Kp, 0,  0,  Mp1, settle1(S1,V), max(abs(S1.tau))
        '3    P + D',              Kp, Kd, 0,  Mp3, settle1(S3,V), max(abs(S3.tau))
        '4    P + I + D',          Kp, Kd, Ki, Mp4, ts4,           F4
        '5    P + I + D, smoothed', Kp, Kd, Ki, Mp5, ts5,          F5};
for i = 1:size(ROWS,1)
    ts = ROWS{i,6};  if isinf(ts), tss = 'never'; else, tss = sprintf('%.2f s', ts); end
    fprintf('    %-34s %8g %8g %8g %11.2f%% %12s %12.1f N\n', ROWS{i,1:5}, tss, ROWS{i,7});
end
fprintf(['\n    Each step was chosen by the measurement of the one before it. That is\n' ...
         '    the point of the order: P shows what the plant is, D answers the ringing\n' ...
         '    P revealed, I answers the error P and D leave, and the force check\n' ...
         '    answers whether the hardware can do what the simulation promises.\n']);

%% ---- figure ------------------------------------------------------------
S = {S1, S3, S4, S5};
T = {sprintf('1-2  P only  (K_p = %g)', Kp), sprintf('3  P + D  (K_d = %g)', Kd), ...
     sprintf('4  P + I + D  (K_i = %g)', Ki), '5  the same, setpoint smoothed'};
f = lab_fig('W02 I  tuning', 1150, 700);
for i = 1:4
    subplot(2,4,i); hold on;
    plot(S{i}.t, S{i}.y_d, 'k--', 'LineWidth', 1);
    plot(S{i}.t, S{i}.y, 'Color', [0 0.45 0.74], 'LineWidth', 2);
    ylim([0 1.5]);  xlim([0 8]);  grid on;  title(T{i});
    if i == 1, ylabel('position [m]'); end
    subplot(2,4,4+i); hold on;
    plot(S{i}.t, S{i}.tau, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6);
    yline(F_MAX, 'k:', sprintf('%g N available', F_MAX), 'LabelHorizontalAlignment','right');
    xlim([0 8]);  grid on;  xlabel('time [s]');
    title(sprintf('peak %.1f N', max(abs(S{i}.tau))));
    if i == 1, ylabel('force \tau [N]'); end
end
exportgraphics(f, fullfile(here, 'img', 'W02_result_tuning.png'), 'Resolution', 150);

% -------------------------------------------------------------------------
function ts = settle1(S, V)
%  목표 1 m 의 1 % 띠를 마지막으로 벗어난 시각 (계단 시각부터). 끝까지 밖이면 inf.
%  Last instant outside the 1 % band around the setpoint, from the step; inf
%  if the response is still outside at the end.
out = find(abs(S.y - V.y_step) > 0.01*V.y_step & S.t >= V.t_step, 1, 'last');
if isempty(out), ts = 0;
elseif out == numel(S.t), ts = inf;
else, ts = S.t(out) - V.t_step;
end
end
