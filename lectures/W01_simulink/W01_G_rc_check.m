%% W01 · 절 G — 스틱 위치마다 요구한 힘, 낸 힘, 두 프로펠러, 그리고 배의 응답
%
%      W01_G_rc_check
%
%  이 스크립트가 하는 일
%    1. 추력 배분의 행렬을 출력한다 — Bxn, 그 역행렬, 그리고 pinv(B) 로 푼 답과 같은지
%    2. 스틱 위치 일곱 가지로 W01_rc.slx 를 60 s 씩 돌린다 (Pacing, 실시간 화면 끔).
%       정지 상태에서 출발해 스틱을 그 자리에 60 s 동안 두었을 때와 같다.
%       요구한 힘 tau_d, 두 축 속도 n, 실제로 낸 힘 tau_a, 정상상태 u, r 을 표로 낸다
%    3. 같은 스틱을 Mode 1 과 Mode 2 로 돌려 로그가 같은지 본다
%    4. 도달 가능 집합 위에 일곱 경우를 그린다 : img/W01_result_attainable.png
%
%  무엇을 보라는 것인가
%    - 집합 안의 요구는 그대로 나온다 (tau_a = tau_d). 밖의 요구는 잘린다
%    - 전진만 할 때 u = tau_X / |X_u| — 스틱에 비례한다. §F 처럼 n 에 비례하는 게 아니다
%
%  학생은 이 스크립트를 돌릴 필요가 없다. 모델을 열고 START 를 누르면 된다.

clear m tx cfg C in y e i k s c dm Mv row lg f ax V Tc P
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
m = 'W01_rc';
if ~isfile(fullfile(here,[m '.slx'])), W01_G_build_rc; end
load_system(fullfile(here,[m '.slx']));
tx = [m '/RC transmitter/'];
mw = get_param(m, 'ModelWorkspace');
Bxn = mw.getVariable('Bxn');   Xmax = mw.getVariable('X_max');   Nmax = mw.getVariable('N_max');
Xu  = mw.getVariable('Xu_abs');
cfg = otter_config('base');
Tmax =  cfg.k_pos*cfg.n_max^2;   Tmin = -cfg.k_neg*cfg.n_min^2;

%% 1. 행렬
fprintf('\n  W01 section G — control allocation of the base Otter\n\n');
fprintf('    y_pont = %.3f m,  T_max = %.2f N,  T_min = %.2f N  (one propeller)\n', cfg.y_pont, Tmax, Tmin);
fprintf('    X_max  = 2 T_max        = %.2f N\n', Xmax);
fprintf('    N_max  = 2 y_pont |T_min| = %.2f N m\n', Nmax);
fprintf('    widest point of the set : X = T_max + T_min = %.2f N,  N = +-y_pont (T_max - T_min) = %.2f N m\n', ...
        Tmax + Tmin, cfg.y_pont*(Tmax - Tmin));
fprintf('    Bxn    = [%g %g; %g %g]\n', Bxn.');
fprintf('    Bxn^-1 = [%.4f %.4f; %.4f %.4f]\n', inv(Bxn).');
tq = [100; 20];
fprintf('    pinv(B)*[X;0;N] - Bxn^-1*[X;N] for X = 100, N = 20 : %.1e\n\n', ...
        max(abs(pinv(cfg.B)*[tq(1); 0; tq(2)] - Bxn\tq)));

%% 2. 스틱 일곱 가지
%        이름                      s_T    s_R
C = { '1  half ahead',             0.5,   0
      '2  full ahead',             1.0,   0
      '3  half ahead, half right', 0.5,   0.5
      '4  full right, no throttle',0.0,   1.0
      '5  full ahead, full right', 1.0,   1.0
      '6  full astern',           -1.0,   0
      '7  half ahead, half left',  0.5,  -0.5 };
fprintf('    %-27s %7s %7s %7s %7s %7s %7s %7s %8s %9s\n', 'stick (Mode 2)', ...
        'X_d', 'N_d', 'n_L', 'n_R', 'X_a', 'N_a', 'u', 'r', 'X_a/|X_u|');
fprintf('    %s\n', repmat('-', 1, 105));
R = zeros(size(C,1), 8);
for i = 1:size(C,1)
    y = run_case(m, tx, 2, C{i,2}, C{i,3});
    e = y(end,:);                              % [u v r N E psi nL nR Xd Nd Xa Na]
    R(i,:) = [e(9:10) e(7:8) e(11:12) e(1) rad2deg(e(3))];
    fprintf('    %-27s %7.1f %7.2f %7.2f %7.2f %7.1f %7.2f %7.4f %8.3f %9.4f\n', ...
            C{i,1}, R(i,:), e(11)/Xu);
end
fprintf('    (X, N in N and N m, n in rad/s, u in m/s, r in deg/s; values at t = 60 s)\n');

%% 3. Mode 1 과 Mode 2
y1 = run_case(m, tx, 1, 0.5, 0.5);
y2 = run_case(m, tx, 2, 0.5, 0.5);
fprintf('\n    Mode 1 against Mode 2, case 3 : largest difference in the whole log = %.1e\n\n', ...
        max(abs(y1(:) - y2(:))));
close_system(m, 0);

%% 4. 도달 가능 집합 위의 일곱 경우
Tc = [Tmax Tmax; Tmax Tmin; Tmin Tmin; Tmin Tmax];
V  = (Bxn * Tc.').';
f  = figure('Color','w', 'Position',[100 100 760 560]);
ax = axes(f);  hold(ax,'on');  grid(ax,'on');  box(ax,'on');
fill(ax, V([1:end 1],2), V([1:end 1],1), [0.88 0.88 0.88], 'EdgeColor',[0.45 0.45 0.45], ...
     'DisplayName','attainable set');
plot(ax, Nmax*[-1 1 1 -1 -1], Xmax*[-1 -1 1 1 -1], '--', 'Color',[0 0.45 0.74], ...
     'LineWidth',1.2, 'DisplayName','stick range');
for i = 1:size(C,1)
    plot(ax, [R(i,2) R(i,6)], [R(i,1) R(i,5)], '-', 'Color',[0.85 0.33 0.10], ...
         'LineWidth',1.2, 'HandleVisibility','off');
end
plot(ax, R(:,2), R(:,1), 'o', 'Color','k', 'MarkerSize',10, 'LineWidth',1.5, ...
     'DisplayName','demanded  \tau_d');
plot(ax, R(:,6), R(:,5), 'o', 'MarkerFaceColor',[0.85 0.33 0.10], 'MarkerEdgeColor','none', ...
     'MarkerSize',8, 'DisplayName','delivered  \tau_a');
for i = 1:size(C,1)
    text(ax, R(i,2) + 2.2, R(i,1) + 9, C{i,1}(1), 'FontSize',11, 'FontWeight','bold');
end
xline(ax, 0, 'k:', 'HandleVisibility','off');   yline(ax, 0, 'k:', 'HandleVisibility','off');
xlim(ax, 1.1*max(abs(V(:,2)))*[-1 1]);   ylim(ax, 1.15*Xmax*[-1 1]);   % 집합의 옆 꼭짓점까지
xlabel(ax, 'yaw moment  \tau_N  [N m]   (right = starboard)');
ylabel(ax, 'surge force  \tau_X  [N]   (up = ahead)');
title(ax, 'Seven stick positions on the attainable set of the base Otter', 'FontWeight','normal');
legend(ax, 'Location','northwest');                % 왼쪽 위는 집합 밖이라 비어 있다
exportgraphics(f, fullfile(here,'img','W01_result_attainable.png'), 'Resolution', 150);
fprintf('  figure -> img/W01_result_attainable.png\n\n');

% -------------------------------------------------------------------------
function y = run_case(m, tx, mode, sT, sR)
%  스틱 편각 (s_T, s_R) 을 채널 값으로 바꿔 한 번 돌린다. receiver 의 역함수 —
%  중립대 db 밖에서 c = 50 + sign(s) (db + |s| (50 - db)).
db = 3;
c  = @(s) 50 + sign(s) * (db + abs(s)*(50 - db)) * (s ~= 0);
thr = 'LY';  if mode == 1, thr = 'RY'; end
in = Simulink.SimulationInput(m);
in = in.setModelParameter('StopTime','60', 'EnablePacing','off');
in = in.setBlockParameter([tx 'mode'], 'Value', num2str(mode));
for k = {'LX','LY','RX','RY'}, in = in.setBlockParameter([tx k{1}], 'Value', '50'); end
in = in.setBlockParameter([tx thr],  'Value', num2str(c(sT), 10));
in = in.setBlockParameter([tx 'LX'], 'Value', num2str(c(sR), 10));
in = in.setVariable('animate', 0, 'Workspace', m);
o  = sim(in);
y  = o.get('W01rc');
if isstruct(y),            y = y.signals.values; end
if isa(y, 'timeseries'),   y = y.Data;           end
y = squeeze(y);
if size(y,1) < size(y,2),  y = y.';              end
end
