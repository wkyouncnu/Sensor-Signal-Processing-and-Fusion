%% W02 · 절 H — 안티와인드업, 깊이 / Section H — anti-windup, in depth
%  모델 W02_H_antiwindup. 힘은 |tau| <= 2.5 N 이므로 스프링 k = 2 에 대해 닿을 수 있는 위치는 1.25 m 까지다.
%  목표를 닿을 수 없는 2 m 로 14 초 동안 두었다가(t = 1~15 s), 닿을 수 있는 0.5 m 로 내린다.
%  세 방식(없음, clamping, back-calculation)이 0.5 m 로 돌아오는 데 걸리는 시간을 잰다.
%  위 줄은 손으로 만든 back-calculation(Kb = 0 이면 없음), 아래 줄은 라이브러리 PID 블록이다.
%  W02_H_antiwindup. With |tau| <= 2.5 N and k = 2 N/m the mass can reach at most 1.25 m.
%  The target is held at an unreachable 2 m from t = 1 to 15 s, then lowered to a reachable 0.5 m.
%  How long does each scheme (none, clamping, back-calculation) take to come back?
%  만드는 것 / produces: img/W02_result_windup.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
S = {'tau_max',2.5, 'y_step',2, 't_step2',15, 'y_step2',0.5, 'T_final',30};

R0 = W02_read('W02_H_antiwindup', S{:}, 'Kb', 0, 'block_mode', 'none');
R1 = W02_read('W02_H_antiwindup', S{:}, 'Kb', 2, 'block_mode', 'clamping');
R2 = W02_read('W02_H_antiwindup', S{:}, 'Kb', 2, 'block_mode', 'back-calculation');
ROW = {'none (block)',             R0.t, R0.y_blk
       'clamping (block)',         R1.t, R1.y_blk
       'back-calculation (block)', R2.t, R2.y_blk
       'none (by hand, Kb = 0)',   R0.t, R0.y
       'back-calc (by hand, Kb = 2)', R2.t, R2.y};

fprintf('\n  W02 H  unreachable 2 m for 14 s, then a reachable 0.5 m  (|tau| <= 2.5 N)\n');
fprintf('    %-30s  y at 15 s [m]  back within 2 %% of 0.5 m after [s]\n', 'anti-windup');
for i = 1:size(ROW,1)
    fprintf('    %-30s  %12.3f  %14.2f\n', ROW{i,1}, interp1(ROW{i,2}, ROW{i,3}, 15), back(ROW{i,2}, ROW{i,3}));
end
fprintf('    by hand vs block, back-calculation: max |y diff| = %.2e\n', max(abs(R2.y - R2.y_blk)));
fprintf('    integrator at t = 15 s: %.1f N without anti-windup, %.2f N with back-calculation\n', ...
        interp1(R0.t, R0.I, 15), interp1(R2.t, R2.I, 15));

fprintf('\n    the back-calculation gain Kb (by hand)\n    Kb     back within 2 %% after [s]\n');
for Kb = [0.5 2 10 50]
    R = W02_read('W02_H_antiwindup', S{:}, 'Kb', Kb);
    fprintf('    %-5g  %10.2f\n', Kb, back(R.t, R.y));
end

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
