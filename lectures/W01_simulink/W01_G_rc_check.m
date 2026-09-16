%% W01 · 절 G — 스틱 위치마다 요구한 힘, 실제로 낸 힘, 두 프로펠러, 그리고 응답
%  W01 · Section G — for each stick position: the force demanded, the force
%                    delivered, the two propellers, and the vessel's response
%
%  실행 / to run
%      W01_G_rc_check
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 G 이다. 절 F 까지는 프로펠러 회전수를 직접 지시했으나,
%      여기서부터는 원하는 힘을 지시하고 그 힘을 낼 회전수를 계산하게 한다.
%      이 계산이 추력 배분이며, 부록 A1 과 5주차가 본격적으로 다루는 주제이다.
%
%      This is section G of Part 2. Up to section F the propeller speeds were
%      commanded directly; from here on a force is commanded and the propeller
%      speeds that produce it are computed. That computation is control
%      allocation, the subject of Appendix A1 and of Week 5.
%
%  절차 / procedure
%      1. 추력 배분의 행렬을 출력한다. B 행렬과 그 역행렬을 보이고, 의사역행렬
%         pinv(B) 로 푼 해가 같은 답을 주는지 확인한다. 추진기가 둘이고 독립적으로
%         지시할 수 있는 축도 둘이므로, 이 경우 두 해가 일치해야 한다.
%      2. 스틱 위치 일곱 가지에 대해 W01_rc.slx 를 60 s 씩 돌린다. 실시간 페이싱과
%         실시간 화면은 끈다. 정지 상태에서 출발해 스틱을 그 자리에 60 s 동안
%         두고 있는 것과 같으며, 요구한 힘 tau_d, 두 축의 회전수 n, 실제로 낸 힘
%         tau_a, 그리고 정상상태의 u 와 r 을 표로 낸다.
%      3. 같은 스틱 입력을 Mode 1 과 Mode 2 로 각각 돌려 로그가 일치하는지 본다.
%      4. 도달 가능한 힘의 집합 위에 일곱 경우를 찍어 그린다.
%
%      1. Print the allocation arithmetic: the matrix B, its inverse, and a
%         check that the pseudo-inverse pinv(B) gives the same answer. With
%         two thrusters and two independently commandable axes the two
%         solutions must coincide.
%      2. For seven stick positions, run W01_rc.slx for 60 s each with pacing
%         and the live display disabled, which is equivalent to holding the
%         stick still for 60 s from rest. Tabulate the demanded force tau_d,
%         the two propeller speeds n, the force actually delivered tau_a, and
%         the steady-state u and r.
%      3. Run one stick position in Mode 1 and again in Mode 2 and compare the
%         logs.
%      4. Plot the seven cases on the attainable set of forces.
%
%  결과를 읽는 법 / how to read the result
%      - 도달 가능 집합 안에 있는 요구는 그대로 실현된다, 즉 tau_a = tau_d 이다.
%        집합 바깥의 요구는 잘려 나가고, 그때 두 값이 갈라진다.
%      - 전진만 지시했을 때 정상상태 속력은 u = tau_X / |X_u| 이다. 이것은
%        스틱 위치에 비례한다. 절 F 에서 회전수를 직접 지시했을 때 속력이 n 의
%        제곱을 따랐던 것과 대비된다. 지시하는 양이 힘으로 바뀌면 관계가 선형이 된다.
%
%      - A demand inside the attainable set is delivered unchanged, so that
%        tau_a equals tau_d. A demand outside it is clipped, and the two part
%        company.
%      - Under a pure ahead command the steady speed is u = tau_X / |X_u|,
%        which is proportional to the stick position. This contrasts with
%        section F, where the propeller speed was commanded directly and the
%        speed followed n squared. Commanding a force makes the relation
%        linear.
%
%  실습 시간에는 이 스크립트를 돌리지 않아도 된다. 모델을 열고 START 를 누른 뒤
%  스틱을 직접 움직여 보는 것이 절 G 의 본래 순서이다.
%  Running this script is not part of the laboratory exercise itself: section G
%  asks for the model to be opened, started, and driven with the stick.
%
%  만드는 것 / what it produces
%      img/W01_result_attainable.png, 그리고 강의노트 §G 의 표 둘.
%      img/W01_result_attainable.png and the two tables of section G.

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
