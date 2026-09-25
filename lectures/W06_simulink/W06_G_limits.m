%% W06 · 실험 6-6 — 요구가 한계를 넘을 때 / Experiment 6-6 — when the demand does not fit
%
%  이 절이 묻는 것 / the question
%      추진기가 낼 수 있는 것보다 큰 힘을 요구하면, 무엇을 포기할 것인가?
%      When more is demanded than the propellers have, what should be given up?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W06_F_limits 를 fit_mode = 0 (자르기) 과 1 (비율) 로 한 번씩 돌린다.
%      ② 구간마다 전달된 X 와 N, 그리고 **그 비율** X/N 을 찍는다. 비율이 방향이다.
%      ③ 두 실행의 항적 대신 힘을 겹쳐 그린다.
%      ① Runs W06_F_limits twice, clipping (fit_mode = 0) and scaling (1).
%      ② Prints the delivered X and N and **their ratio**, which is the direction.
%      ③ Plots the two runs on one axis.
%
%  출력에서 볼 것 / what to look for in the output
%      - 요구가 들어가는 구간에서는 두 방식이 같다. 한계에 닿아야 갈라진다.
%      - 자르면 더 큰 힘이 나오지만 (166.4 N 대 151.9 N) **방향이 달라진다**:
%        X/N 이 4.40 에서 5.78 로. 배는 요구한 것과 다른 쪽으로 간다.
%      - 비율로 줄이면 힘은 작지만 X/N = 4.40 이 그대로다.
%      - While the demand fits, the two agree; they part only at the limit.
%      - Clipping delivers more force (166.4 N against 151.9 N) but **changes the
%        direction**: X/N goes from 4.40 to 5.78. The vessel goes somewhere else.
%      - Scaling delivers less and keeps X/N at 4.40.
%
%  만드는 것 / produces: img/W06_result_limits.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 자르기와 비율 줄이기 / clipping and scaling
Rc = W06_read('W06_F_limits', 'fit_mode', 0);
Rs = W06_read('W06_F_limits', 'fit_mode', 1);
at = @(R, f, t) interp1(R.t, R.(f), t);
%  X/N 은 요구한 힘의 **방향**이다. N 이 0 인 구간에서는 뜻이 없으므로 -- 로 둔다 (맨 아래 함수).
%  X/N is the direction of the demand; where N is zero it has no meaning (see below).
fprintf('\n  W06 Experiment 6-6  past the limits  (one propeller: %.2f to %.2f N)\n', Rc.V.T_min, Rc.V.T_max);
fprintf('    t [s]   demanded X      N    X/N      clip X      N    X/N     scale X      N    X/N\n');
for t = [10 20 30 40]
    fprintf('    %5.0f  %10.1f %6.1f %s  %10.1f %6.1f %s  %10.1f %6.1f %s\n', t, ...
            at(Rc,'Xd',t), at(Rc,'Nd',t), rat(at(Rc,'Xd',t), at(Rc,'Nd',t)), ...
            at(Rc,'Xa',t), at(Rc,'Na',t), rat(at(Rc,'Xa',t), at(Rc,'Na',t)), ...
            at(Rs,'Xa',t), at(Rs,'Na',t), rat(at(Rs,'Xa',t), at(Rs,'Na',t)));
end

%% 2) 두 실행을 겹쳐 그린다 / the two runs on one axis
f = lab_fig('W06 Exp 6-6  clipping against scaling', 1000, 620);
subplot(2,1,1); hold on; grid on;
plot(Rc.t, Rc.Xd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'X demanded');
plot(Rc.t, Rc.Xa, 'LineWidth', 2, 'DisplayName', 'X, clipped');
plot(Rs.t, Rs.Xa, 'LineWidth', 2, 'DisplayName', 'X, scaled');
ylabel('surge force X [N]'); legend('Location','southwest');
title('neither can deliver what was asked; they give up different things');
subplot(2,1,2); hold on; grid on;
plot(Rc.t, Rc.Nd, 'k--', 'LineWidth', 1.6, 'DisplayName', 'N demanded');
plot(Rc.t, Rc.Na, 'LineWidth', 2, 'DisplayName', 'N, clipped');
plot(Rs.t, Rs.Na, 'LineWidth', 2, 'DisplayName', 'N, scaled');
ylabel('yaw moment N [N m]'); xlabel('time [s]'); legend('Location','southwest');
title('clipping keeps more surge and loses yaw; scaling keeps the ratio 4.40');
exportgraphics(f, fullfile(here, 'img', 'W06_result_limits.png'), 'Resolution', 150);

% -------------------------------------------------------------------------
function s = rat(x, n)
%  힘의 방향을 한 수로: X/N. N 이 0 이면 방향이 정의되지 않는다.
%  The direction of the force as one number. Undefined when N is zero.
if abs(n) > 1e-6, s = sprintf('%6.2f', x/n); else, s = '    --'; end
end
