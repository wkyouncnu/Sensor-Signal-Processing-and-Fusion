function W07_S_expected()
%W07_S_EXPECTED  모범답안이 내는 그림 셋을 다시 만든다.
%                Regenerate the three expected-result figures of the Week 7 lab.
%
%   >> W07_S_expected
%
%   만드는 것 / produces
%       ../problems/img/W07_P1_expected.png   the notch, and the effort it saves
%       ../problems/img/W07_P2_expected.png   what it costs, with the sea off
%       ../problems/img/W07_P3_expected.png   the slow part, and the integral

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();
img = fullfile(week, 'problems', 'img');
if ~isfolder(img), mkdir(img); end
if ~isfile(fullfile(here,'W07_S1.slx')), W07_S1_notch; end
V0 = defaults();

%% ---- 문제 1 · 노치와 그것이 아껴 주는 것 / the notch, and the effort saved
A = run_one('W07_S1', V0, 'zeta_n', V0.zeta_d);
B = run_one('W07_S1', V0, 'zeta_n', 0.05);
s = tf('s');
H = (s^2 + 2*0.05*V0.w0*s + V0.w0^2)/(s^2 + 2*V0.zeta_d*V0.w0*s + V0.w0^2);
w = logspace(-1, 1.3, 400);  mag = squeeze(bode(H, w));
f = lab_fig('W07 Problem 1  the notch', 1000, 620);
subplot(2,1,1); semilogx(w, 20*log10(mag), 'LineWidth', 2); grid on;
xline(V0.w0, 'r--', '\omega_0');  ylabel('|H| [dB]');  xlabel('frequency [rad/s]');
title(sprintf('%.1f dB at \\omega_0, and 0 dB where the vessel is steered', ...
              20*log10(0.05/V0.zeta_d)));
subplot(2,1,2); hold on; grid on; xlim([20 40]);
plot(A.t, A.N, 'Color', [0.7 0.7 0.7], 'LineWidth', 1.2, 'DisplayName', 'no filter');
plot(B.t, B.N, 'LineWidth', 1.4, 'DisplayName', 'notch');
yline([-1 1]*V0.N_max, 'r:', 'HandleVisibility','off');
ylabel('N [N m]');  xlabel('time [s]');  legend('Location','northeast');
title('the same sea, the same gains: what the propellers are asked for');
exportgraphics(f, fullfile(img, 'W07_P1_expected.png'), 'Resolution', 150);

%% ---- 문제 2 · 그 값 / what it costs -----------------------------------
V = V0;  V.wave_on = 0;  V.T_final = 40;
C = run_one('W07_S1', V, 'zeta_n', V.zeta_d);
D = run_one('W07_S1', V, 'zeta_n', 0.05);
f = lab_fig('W07 Problem 2  the cost', 1000, 460);
hold on; grid on; xlim([4 30]);
plot(C.t, C.psi, 'LineWidth', 2, 'DisplayName', 'no filter');
plot(D.t, D.psi, 'LineWidth', 2, 'DisplayName', 'notch');
yline(V.psi_step, 'k--', 'HandleVisibility','off');
xlabel('time [s]');  ylabel('\psi [deg]');  legend('Location','southeast');
title('a 10 deg turn in still water: the filter that helped in waves is in the way here');
exportgraphics(f, fullfile(img, 'W07_P2_expected.png'), 'Resolution', 150);

%% ---- 문제 3 · 느린 부분과 적분 / the slow part, and the integral -------
V = V0;  V.N_slow = 15;  V.T_final = 120;
E = run_one('W07_S1', V, 'zeta_n', 0.05, 'Ki', 0);
F = run_one('W07_S1', V, 'zeta_n', 0.05, 'Ki', 20);
f = lab_fig('W07 Problem 3  the slow part', 1000, 620);
subplot(2,1,1); hold on; grid on;
plot(E.t, E.psi, 'LineWidth', 1.8, 'DisplayName', 'P-D  (Ki = 0)');
plot(F.t, F.psi, 'LineWidth', 1.8, 'DisplayName', 'PI-D');
yline(V.psi_step, 'k--', 'HandleVisibility','off');
ylabel('\psi [deg]');  legend('Location','southeast');
title('a slow push: without an integral the vessel settles beside the command, not on it');
subplot(2,1,2); hold on; grid on;
plot(E.t, E.N, 'LineWidth', 1.2, 'DisplayName', 'P-D  (Ki = 0)');
plot(F.t, F.N, 'LineWidth', 1.2, 'DisplayName', 'PI-D');
ylabel('N [N m]');  xlabel('time [s]');  legend('Location','southeast');
title('both hold about -15 N m against it; only one does so without an error');
exportgraphics(f, fullfile(img, 'W07_P3_expected.png'), 'Resolution', 150);

fprintf('\n  three figures written to %s\n\n', img);
end

% =========================================================================
function V = defaults()
cfg = otter_config('base');
V.Hs = 0.3;  V.T0 = 2.0;  V.gamma_j = 3.3;  V.N_comp = 20;  V.sigma_psi = 3;
V.w0 = 2*pi/V.T0;  V.wave_on = 1;
V.zeta_n = 0.05;  V.zeta_d = 0.3;
V.Kp = 300;  V.Kd = 100;  V.Ki = 0;  V.Kb = 0.1;  V.X_ff = 60;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_ff/2), ...
              2*cfg.y_pont*(V.X_ff/2 + cfg.k_neg*cfg.n_min^2));
V.psi_step = 10;  V.t_step = 5;
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';  V.x0 = zeros(12,1);
V.N_slow = 0;  V.T_slow = 60;  V.V_c = 0;  V.beta_c = pi/2;
V.h = 0.02;  V.T_final = 60;
end

function y = run_one(mdl, V, varargin)
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
b = 'base';
f = fieldnames(V);
for i = 1:numel(f), assignin(b, f{i}, V.(f{i})); end
evalin(b, sprintf('bdclose(''%s'');', mdl));
load_system(mdl);
set_param(mdl,'StopTime','T_final','ReturnWorkspaceOutputs','off');
evalin(b, sprintf('sim(''%s'');', mdl));
S = evalin(b,'flog');   F = squeeze(S.signals.values);  if size(F,1)==3, F = F.'; end
X = squeeze(evalin(b,'xlog').signals.values);  if size(X,1)==12, X = X.'; end
y.t = S.time;  y.psi = X(:,12)*180/pi;
y.psi_m = F(:,1);  y.psi_f = F(:,2);  y.N = F(:,3);
end
