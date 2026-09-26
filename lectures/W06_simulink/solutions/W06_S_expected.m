function W06_S_expected()
%W06_S_EXPECTED  모범답안이 내는 그림 셋을 다시 만든다.
%                Regenerate the three expected-result figures of the Week 6 lab.
%
%   >> W06_S_expected
%
%   만드는 것 / produces
%       ../problems/img/W06_P1_expected.png   the square rule
%       ../problems/img/W06_P2_expected.png   the curve, right and wrong
%       ../problems/img/W06_P3_expected.png   clipping against scaling
%
%   그림은 문제지에 실린다. 학생이 "맞게 만들었을 때 무엇이 보여야 하는가" 를
%   먼저 보고 시작하도록 / the figures go in the problem sheet, so that the
%   reader starts from what a correct model looks like.

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
img = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
cfg = otter_config('base');
if ~isfile(fullfile(here,'W06_S1.slx')), W06_S1_allocation; end

%% ---- 문제 1 · 제곱 규칙 / the square rule ------------------------------
A = run_one('W06_S1', [0 15 30], [100 100 100], [0 20 -20], 45, 1, cfg);
f = lab_fig('W06 Problem 1  the square rule', 960, 460);
subplot(2,1,1); hold on; grid on;
plot(A.t, A.Xc, '--', 'LineWidth', 2.2, 'Color', [.4 .4 .4]);
plot(A.t, A.X, 'LineWidth', 1.4);
plot(A.t, A.Nc, '--', 'LineWidth', 2.2, 'Color', [.75 .55 .3]);
plot(A.t, A.N, 'LineWidth', 1.4);
ylabel('force and moment');  ylim([-40 130]);
legend({'X demanded','X delivered','N demanded','N delivered'}, ...
       'Location','east', 'NumColumns', 2);
title('demanded and delivered lie on one another');
subplot(2,1,2); hold on; grid on;
plot(A.t, A.T1, 'LineWidth', 1.6);  plot(A.t, A.T2, 'LineWidth', 1.6);
plot(A.t, A.T1 + A.T2, 'k:', 'LineWidth', 1.6);
yline([cfg.k_pos*cfg.n_max^2, -cfg.k_neg*cfg.n_min^2], 'r--');
xlabel('time [s]');  ylabel('thrust [N]');  ylim([-90 140]);
legend({'T_1 port','T_2 starboard','T_1 + T_2','the limits'}, 'Location','east');
title('the sum is X; the difference times y_{pont} is N');
exportgraphics(f, fullfile(img, 'W06_P1_expected.png'), 'Resolution', 150);

%% ---- 문제 2 · 역곡선, 옳은 것과 틀린 것 / the curve, right and wrong ---
B = run_one('W06_S1', [0 15 30 45], [100 -100 0 0], [0 0 20 -20], 60, 1, cfg);
%  틀린 역곡선은 모델을 고치지 않고 여기서 계산한다: 축은 sqrt(|T|/k_pos) 로
%  돌지만 선체는 k_neg 를 곱한다 / the wrong inverse, worked out here rather
%  than by breaking the model: the shaft turns at sqrt(|T|/k_pos) and the hull
%  multiplies by k_neg.
w1 = wrong(B.T1, cfg);  w2 = wrong(B.T2, cfg);
f = lab_fig('W06 Problem 2  the inverse of the propeller curve', 960, 460);
subplot(2,1,1); hold on; grid on;
plot(B.t, B.Xc, '--', 'LineWidth', 2.2, 'Color', [.4 .4 .4]);
plot(B.t, B.X, 'LineWidth', 1.6);
plot(B.t, w1 + w2, 'LineWidth', 1.6);
ylabel('X [N]');  ylim([-130 130]);
legend({'demanded','k_{neg} astern (correct)','k_{pos} both ways'}, 'Location','southwest');
title('the astern leg falls to 0.582 of what was asked for');
subplot(2,1,2); hold on; grid on;
plot(B.t, B.Nc, '--', 'LineWidth', 2.2, 'Color', [.4 .4 .4]);
plot(B.t, B.N, 'LineWidth', 1.6);
plot(B.t, cfg.y_pont*(w1 - w2), 'LineWidth', 1.6);
xlabel('time [s]');  ylabel('N [N m]');  ylim([-28 28]);
title('and a pure yaw demand produces surge that nobody asked for');
exportgraphics(f, fullfile(img, 'W06_P2_expected.png'), 'Resolution', 150);

%% ---- 문제 3 · 자르기와 비율 줄이기 / clipping against scaling ----------
C = run_one('W06_S1', [0 15 30 45], [220 220 100 -220], [0 50 50 0], 60, 0, cfg);
D = run_one('W06_S1', [0 15 30 45], [220 220 100 -220], [0 50 50 0], 60, 1, cfg);
f = lab_fig('W06 Problem 3  clipping against scaling', 960, 460);
subplot(2,1,1); hold on; grid on;
plot(C.t, C.Xc, '--', 'LineWidth', 2.2, 'Color', [.4 .4 .4]);
plot(C.t, C.X, 'LineWidth', 1.6);  plot(D.t, D.X, 'LineWidth', 1.6);
ylabel('X [N]');  ylim([-240 240]);
legend({'demanded','clipping','scaling'}, 'Location','southwest');
title('clipping delivers more force');
subplot(2,1,2); hold on; grid on;
plot(C.t, C.Nc, '--', 'LineWidth', 2.2, 'Color', [.4 .4 .4]);
plot(C.t, C.N, 'LineWidth', 1.6);  plot(D.t, D.N, 'LineWidth', 1.6);
xlabel('time [s]');  ylabel('N [N m]');  ylim([-8 58]);
title('and less moment: what it gained in surge it took out of yaw');
exportgraphics(f, fullfile(img, 'W06_P3_expected.png'), 'Resolution', 150);

fprintf('\n  three figures written to %s\n\n', img);
end

% =========================================================================
function y = run_one(mdl, T_SW, X_SEQ, N_SEQ, T_final, fit_mode, cfg)
b = 'base';
assignin(b,'h',0.02);            assignin(b,'T_final',T_final);
assignin(b,'T_SW',T_SW(:));      assignin(b,'X_SEQ',X_SEQ(:));
assignin(b,'N_SEQ',N_SEQ(:));    assignin(b,'fit_mode',fit_mode);
assignin(b,'y_pont',cfg.y_pont); assignin(b,'k_pos',cfg.k_pos);
assignin(b,'k_neg',cfg.k_neg);   assignin(b,'n_max',cfg.n_max);
assignin(b,'n_min',cfg.n_min);
assignin(b,'T_max',cfg.k_pos*cfg.n_max^2);
assignin(b,'T_min',-cfg.k_neg*cfg.n_min^2);
assignin(b,'mp',25);             assignin(b,'rp',[0.05 0 -0.35]');
assignin(b,'V_c',0);             assignin(b,'beta_c',0);
assignin(b,'x0',zeros(12,1));
evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b,'alog');
A = squeeze(S.signals.values);  if size(A,1) == 4, A = A.'; end
y.t = S.time;
y.Xc = A(:,1);  y.Nc = A(:,2);
y.T1 = curve(A(:,3), cfg);  y.T2 = curve(A(:,4), cfg);
y.X  = y.T1 + y.T2;
y.N  = cfg.y_pont*(y.T1 - y.T2);
end

function T = curve(n, cfg)
k = cfg.k_pos*ones(size(n));  k(n < 0) = cfg.k_neg;
T = k .* n .* abs(n);
end

function Tw = wrong(T, cfg)
%  k_pos 로 축을 돌리고 선체가 k_neg 를 곱한다 / the shaft set by k_pos, the
%  hull answering with k_neg: the delivered thrust is (k_neg/k_pos) T astern.
Tw = T;
Tw(T < 0) = T(T < 0) * cfg.k_neg / cfg.k_pos;
end
