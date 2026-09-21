%% W02 · 절 H — 안티와인드업, 깊이 / Section H — anti-windup, in depth
%  모델 W02_H_antiwindup. 힘은 |tau| <= 2.5 N 이므로 스프링 k = 2 에 대해 닿을 수 있는 위치는 1.25 m 까지다.
%  목표를 닿을 수 없는 2 m 로 14 초 동안 두었다가(t = 1~15 s), 닿을 수 있는 0.5 m 로 내린다.
%  세 방식(없음, clamping, back-calculation)이 0.5 m 로 돌아오는 데 걸리는 시간을 잰다.
%  위 줄은 손으로 만든 back-calculation(Kb = 0 이면 없음), 아래 줄은 라이브러리 PID 블록이다.
%  W02_H_antiwindup. With |tau| <= 2.5 N and k = 2 N/m the mass can reach at most 1.25 m.
%  The target is held at an unreachable 2 m from t = 1 to 15 s, then lowered to a reachable 0.5 m.
%  How long does each scheme (none, clamping, back-calculation) take to come back?
%  만드는 것 / produces: img/W02_result_windup.png

%
%  출력에서 볼 것 / what to look for in the output
%      - 15 s 까지는 모든 방식이 1.25 m 에 있다: 목표에 닿을 수 없으니 차이가 보이지 않는다.
%      - 차이는 기억에 있다: 안티와인드업이 없으면 적분이 94 N 을 쌓아 (힘은 2.5 N 뿐)
%        목표가 0.5 m 로 내려가도 질량이 돌아오지 않는다 (Inf).
%      - clamping 은 4.41 s, back-calculation 은 4.06 s 에 돌아온다. 손으로 만든 것과 블록이
%        반올림 오차 안에서 같다. Kb 는 0.5 ~ 50 에서 크게 중요하지 않다.
%      - Until 15 s every scheme sits at 1.25 m: the target cannot be reached,
%        so no difference shows.
%      - The difference is the memory: without anti-windup the integral stores
%        94 N (the force can give 2.5 N) and the mass never returns (Inf).
%      - Clamping returns in 4.41 s, back-calculation in 4.06 s; hand-built and
%        block agree to round-off. Kb matters little between 0.5 and 50.

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  힘 한계 2.5 N, 1 s 에 2 m (닿을 수 없음), 15 s 에 0.5 m (닿을 수 있음), 30 s 동안
%  Force limit 2.5 N; 2 m at 1 s (unreachable), 0.5 m at 15 s (reachable); 30 s
S = {'tau_max',2.5, 'y_step',2, 't_step2',15, 'y_step2',0.5, 'T_final',30};

%% 1) 세 방식으로 돌린다 / run the three schemes
%  위 줄 (손으로 만든 back-calculation) 은 Kb 로, 아래 줄 (PID 블록) 은 block_mode 로 방식을 정한다.
%  The top row (hand-built back-calculation) is set by Kb; the bottom row (the
%  PID block) by block_mode.
R0 = W02_read('W02_H_antiwindup', S{:}, 'Kb', 0, 'block_mode', 'none');
R1 = W02_read('W02_H_antiwindup', S{:}, 'Kb', 2, 'block_mode', 'clamping');
R2 = W02_read('W02_H_antiwindup', S{:}, 'Kb', 2, 'block_mode', 'back-calculation');
ROW = {'none (block)',             R0.t, R0.y_blk
       'clamping (block)',         R1.t, R1.y_blk
       'back-calculation (block)', R2.t, R2.y_blk
       'none (by hand, Kb = 0)',   R0.t, R0.y
       'back-calc (by hand, Kb = 2)', R2.t, R2.y};

%% 2) 15 s 의 위치와 0.5 m 로 돌아오는 시간 / position at 15 s and the time to return to 0.5 m
%  back(t, y) (맨 아래 함수): 15 s 뒤 0.5 m 의 2 % 띠를 마지막으로 벗어난 시각
%  back(t, y) (at the bottom): the last exit from the 2 % band of 0.5 m after 15 s
fprintf('\n  W02 H  unreachable 2 m for 14 s, then a reachable 0.5 m  (|tau| <= 2.5 N)\n');
fprintf('    %-30s  y at 15 s [m]  back within 2 %% of 0.5 m after [s]\n', 'anti-windup');
for i = 1:size(ROW,1)
    fprintf('    %-30s  %12.3f  %14.2f\n', ROW{i,1}, interp1(ROW{i,2}, ROW{i,3}, 15), back(ROW{i,2}, ROW{i,3}));
end
fprintf('    by hand vs block, back-calculation: max |y diff| = %.2e\n', max(abs(R2.y - R2.y_blk)));
fprintf('    integrator at t = 15 s: %.1f N without anti-windup, %.2f N with back-calculation\n', ...
        interp1(R0.t, R0.I, 15), interp1(R2.t, R2.I, 15));

%% 3) 되감기 이득 Kb 를 바꿔 본다 / vary the back-calculation gain Kb
fprintf('\n    the back-calculation gain Kb (by hand)\n    Kb     back within 2 %% after [s]\n');
for Kb = [0.5 2 10 50]
    R = W02_read('W02_H_antiwindup', S{:}, 'Kb', Kb);
    fprintf('    %-5g  %10.2f\n', Kb, back(R.t, R.y));
end

%% 4) 그림: 위 위치, 아래 적분항 / figure: position on top, the integral below
f = lab_fig('W02 H  anti-windup', 1000, 720);
subplot(2,1,1); hold on;
plot(R0.t, R0.y_d, 'k--', 'DisplayName', 'setpoint');
plot(R0.t, R0.y_blk, 'LineWidth', 2, 'DisplayName', 'none');
plot(R1.t, R1.y_blk, 'LineWidth', 2, 'DisplayName', 'clamping');
plot(R2.t, R2.y_blk, 'LineWidth', 2, 'DisplayName', 'back-calculation');
yline(1.25, ':', 'the most the force can hold: 1.25 m', 'LabelHorizontalAlignment','left', 'HandleVisibility','off');
ylabel('position y [m]'); legend('Location','northeast'); grid on;
title('after t = 15 s the target is reachable again — without anti-windup the mass does not come back');
subplot(2,1,2); hold on;
plot(R0.t, R0.I, 'LineWidth', 2, 'DisplayName', 'integrator, none');
plot(R2.t, R2.I, 'LineWidth', 2, 'DisplayName', 'integrator, back-calculation');
ylabel('integral term I [N]'); xlabel('time [s]'); legend('Location','northwest'); grid on;
title('what the integrator stored while the force sat on its limit');
exportgraphics(f, fullfile(here, 'img', 'W02_result_windup.png'), 'Resolution', 150);

% -------------------------------------------------------------------------
function ts = back(t, y)
%  t = 15 s 뒤, 0.5 m 의 2 % 띠를 마지막으로 벗어난 때까지 / last exit from the 2 % band after 15 s
k = t >= 15;  t = t(k) - 15;  y = y(k);
o = find(abs(y - 0.5) > 0.01, 1, 'last');
if isempty(o), ts = 0; elseif o == numel(t), ts = inf; else, ts = t(o); end
end
