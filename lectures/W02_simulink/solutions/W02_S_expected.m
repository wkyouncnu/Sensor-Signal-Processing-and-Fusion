function W02_S_expected()
%W02_S_EXPECTED  문제지에 싣는 "올바른 모델이 내는 결과" 그림 셋을 모범답안으로 만든다.
%                Draw the three "what a correct model produces" figures of the
%                problem sheet, from the reference answer.
%
%   >> W02_S_expected
%
%   강의에서의 위치 / place in the lecture
%       2주차 실습 문제지(problems/README.md)의 그림 셋이다. 학생은 자기 모델의
%       결과를 이 그림과 겹쳐 보고, 수치는 W02_check 로 확인한다.
%       The three figures of the Week 2 problem sheet. A student compares their
%       own result with them by eye and checks the numbers with W02_check.
%
%   만드는 것 / what it produces
%       problems/img/W02_P1_expected.png, W02_P2_expected.png, W02_P3_expected.png

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
img  = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
if ~isfile(fullfile(here, 'W02_S1.slx')), W02_S1_pid_loop(); end
close all;

%% ---- P1 -----------------------------------------------------------------
f = lab_fig('W02 P1 expected', 900, 380);
col = [0 0.45 0.74; 0.85 0.33 0.10];
KP = [2 10];
subplot(1,2,1); hold on; grid on;
for i = 1:2
    y = run_one(struct('Kp',KP(i),'Ki',0,'Kd',0));
    plot(y.t, y.y, 'Color', col(i,:), 'LineWidth', 1.8, 'DisplayName', sprintf('K_p = %g', KP(i)));
    yline(KP(i)/(2 + KP(i)), ':', 'Color', col(i,:), 'LineWidth', 1.2, 'HandleVisibility','off');
end
plot(y.t, y.y_d, 'k--', 'DisplayName', 'setpoint');
xlabel('time [s]'); ylabel('position y [m]');
legend('Location','southeast');
title('P alone: steady value K_p/(k + K_p), never 1');
subplot(1,2,2); hold on; grid on;
for i = 1:2
    y = run_one(struct('Kp',KP(i),'Ki',0,'Kd',0));
    plot(y.t, y.tau, 'Color', col(i,:), 'LineWidth', 1.8);
end
xlabel('time [s]'); ylabel('force \tau [N]');
legend(compose('K_p = %g', KP), 'Location','northeast');
title('the force jumps to K_p at the step');
exportgraphics(f, fullfile(img, 'W02_P1_expected.png'), 'Resolution', 130);

%% ---- P2 -----------------------------------------------------------------
f = lab_fig('W02 P2 expected', 900, 380);
y = run_one(struct('Kp',10,'Ki',8,'Kd',6));
subplot(1,2,1); hold on; grid on;
plot(y.t, y.y_d, 'k--');  plot(y.t, y.y, 'Color', col(1,:), 'LineWidth', 1.8);
yline(1.01, ':');  yline(0.99, ':');
xlabel('time [s]'); ylabel('position y [m]');
title('K_p = 10, K_d = 6, K_i = 8: inside 1 % after 2.77 s');
subplot(1,2,2); hold on; grid on;
plot(y.t, y.tau, 'Color', col(2,:), 'LineWidth', 1.8);
xlim([0.8 3]);
xlabel('time [s]'); ylabel('force \tau [N]');
title(sprintf('the derivative kick: %.1f N at the step', max(abs(y.tau))));
exportgraphics(f, fullfile(img, 'W02_P2_expected.png'), 'Resolution', 130);

%% ---- P3 -----------------------------------------------------------------
f = lab_fig('W02 P3 expected', 900, 380);
KB = [0 2];  LB = {'K_b = 0  no anti-windup','K_b = 2  back-calculation'};
subplot(1,2,1); hold on; grid on;
for i = 1:2
    y = run_one(struct('Kp',10,'Ki',8,'Kd',4,'tau_max',2.5,'Kb',KB(i)));
    plot(y.t, y.y, 'Color', col(3-i,:), 'LineWidth', 1.8, 'DisplayName', LB{i});
end
plot(y.t, y.y_d, 'k--', 'DisplayName', 'setpoint');
xlabel('time [s]'); ylabel('position y [m]');  legend('Location','southeast');
title('same gains, |\tau| \leq 2.5 N');
subplot(1,2,2); hold on; grid on;
for i = 1:2
    y = run_one(struct('Kp',10,'Ki',8,'Kd',4,'tau_max',2.5,'Kb',KB(i)));
    plot(y.t, y.tau, 'Color', col(3-i,:), 'LineWidth', 1.8);
end
xlabel('time [s]'); ylabel('force \tau [N]');  legend(LB, 'Location','southeast');
title('time spent on the limit');
exportgraphics(f, fullfile(img, 'W02_P3_expected.png'), 'Resolution', 130);
fprintf('  wrote problems/img/W02_P1..P3_expected.png\n');
end

% -------------------------------------------------------------------------
function y = run_one(G)
b = 'base';
%  W02_0_setup 을 부르지 않는다: 그 첫 줄의 close all 이 그리고 있는 그림을 닫는다.
%  Not W02_0_setup: its first line, close all, would close the figure being drawn.
D = W02_vars();  d = fieldnames(D);
for i = 1:numel(d), assignin(b, d{i}, D.(d{i})); end
f = fieldnames(G);
for i = 1:numel(f), assignin(b, f{i}, G.(f{i})); end
load_system('W02_S1');
set_param('W02_S1', 'ReturnWorkspaceOutputs','off');
evalin(b, 'sim(''W02_S1'');');
S = evalin(b, 'ylog');
v = squeeze(S.signals.values);  if size(v,1) == 3 && size(v,2) ~= 3, v = v.'; end
y.t = S.time;  y.y_d = v(:,1);  y.tau = v(:,2);  y.y = v(:,3);
end
