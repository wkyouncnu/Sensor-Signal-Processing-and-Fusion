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

%% 1b) 두 규칙이 **무엇을 얼마나** 잃는가 — 크기와 방향으로 (성능 판정용, 2026-10-13)
%     요구한 힘을 벡터 [X; N] 로 보면, 전달된 것은 길이가 짧아지거나 방향이 돌아간다.
%     비율 줄이기는 방향을 정확히 지키고 길이를 더 잃는다. 자르기는 그 반대다.
%     Seen as a vector, the delivered force is either shorter or turned. Scaling keeps
%     the direction exactly and loses more length; clipping does the opposite.
cfg = otter_config('base');
B2  = [1 1; cfg.y_pont -cfg.y_pont];
d   = [Rc.V.X_big; Rc.V.N_big];                       % 한계를 넘는 요구 / the demand that does not fit
Td  = B2 \ d;
Tc  = min(max(Td, Rc.V.T_min), Rc.V.T_max);             % 자르기 / clipping
sc  = 1;
for i = 1:2
    if Td(i) > Rc.V.T_max, sc = min(sc, Rc.V.T_max/Td(i)); end
    if Td(i) < Rc.V.T_min, sc = min(sc, Rc.V.T_min/Td(i)); end
end
Ts  = sc*Td;                                    % 비율 줄이기 / scaling
ang = @(v) atan2d(v(2), v(1));
fprintf('\n    what each rule gives up, for the demand (%.0f N, %.0f N m)\n', d);
fprintf('      rule     magnitude delivered [%% of demand]   direction off by [deg]\n');
for C = {{'clip', B2*Tc}, {'scale', B2*Ts}}
    fprintf('      %-7s %28.1f %24.1f\n', C{1}{1}, ...
            100*norm(C{1}{2})/norm(d), abs(ang(C{1}{2}) - ang(d)));
end

%% 2) 그림 / the figure — 그리는 것은 W06_fig_limits 가 한다 (45 줄 규칙, §15-15)
W06_fig_limits(Rc, Rs, here);

% -------------------------------------------------------------------------
function s = rat(x, n)
%  힘의 방향을 한 수로: X/N. N 이 0 이면 방향이 정의되지 않는다.
%  The direction of the force as one number. Undefined when N is zero.
if abs(n) > 1e-6, s = sprintf('%6.2f', x/n); else, s = '    --'; end
end
