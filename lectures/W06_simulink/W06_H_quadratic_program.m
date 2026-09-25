%% W06 · 실험 6-7 — 제약이 있는 배분을 최적화로 / Experiment 6-7 — allocation as a constrained problem
%
%  이 절이 묻는 것 / the question
%      자르기도 비율 줄이기도 규칙일 뿐이다. 무엇을 포기할지 **직접 말할** 수는 없는가?
%      Clipping and scaling are rules. Can the choice of what to give up be stated instead?
%
%  이 스크립트가 하는 일 / what this script does
%      모델이 없다. 6-6 과 같은 한 순간의 요구를 다섯 가지로 배분해 본다.
%      ① 자르기 ② 비율 줄이기 ③~⑤ 가중치가 다른 제약 최소자승 (lsqlin).
%      최소자승은 min ||W^(1/2)(B T - tau)||, 추력 한계는 부등식 제약이다.
%      No model: the one demand of §6-6, allocated five ways — clipping, scaling,
%      and constrained least squares (lsqlin) with three weightings. The problem
%      is min ||W^(1/2) (B T - tau)|| subject to the thrust limits.
%
%  출력에서 볼 것 / what to look for in the output
%      - 가중치가 1:1 이면 요를 거의 전부 버린다 (N 50 -> 13.4). 1 N m 의 오차와
%        1 N 의 오차를 같게 셌기 때문이다 — 단위가 다른 둘을 더한 대가다.
%      - 요에 10 을 주면 비율 줄이기와 거의 같아진다. 100 을 주면 요를 지키고 전진을 버린다.
%      - 자르기는 어떤 가중치의 답도 아니다. 그저 방향이 달라진 결과다.
%      - With equal weights the yaw is almost entirely given up (50 -> 13.4 N m):
%        one newton-metre of error was counted the same as one newton.
%      - Weight 10 on yaw lands close to scaling; weight 100 keeps yaw and gives up surge.
%      - Clipping is not the answer to any weighting: it is simply a different direction.
%
%  만드는 것 / produces: img/W06_result_qp.png

%% 0) 경로와 문제 / paths and the problem
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
mss_path();
V = W06_vars();
B2  = [1 1; V.y_pont -V.y_pont];              % X 와 N 의 두 행 / the X and N rows of B
tau = [V.X_big; V.N_big];                     % 220 N, 50 N m — 6-6 의 t = 20 s 구간
lo  = [V.T_min; V.T_min];  hi = [V.T_max; V.T_max];
opt = optimoptions('lsqlin', 'Display', 'none');

%% 1) 다섯 가지 배분 / five allocations
T0 = B2\tau;                                                  % 한계를 무시한 해 / ignoring the limits
S(1).name = 'clip';   S(1).T = min(max(T0, lo), hi);
S(2).name = 'scale';  S(2).T = min(1, min(hi./max(T0,eps)))*T0;
w = [1 10 100];
for i = 1:3
    W = diag([1 w(i)]);
    S(i+2).name = sprintf('lsqlin, yaw weight %g', w(i));
    S(i+2).T = lsqlin(sqrt(W)*B2, sqrt(W)*tau, [], [], [], [], lo, hi, [], opt);
end
fprintf('\n  W06 Experiment 6-7  the same demand, five allocations   (demanded X %.0f N, N %.0f N m)\n', tau);
fprintf('    %-24s %8s %8s %9s %8s %7s\n', 'strategy', 'T1 [N]', 'T2 [N]', 'X [N]', 'N [N m]', 'X/N');
for i = 1:numel(S)
    d = B2*S(i).T;
    fprintf('    %-24s %8.2f %8.2f %9.2f %8.2f %7.2f\n', S(i).name, S(i).T, d, d(1)/d(2));
end
fprintf('    %-24s %8s %8s %9.2f %8.2f %7.2f\n', 'demanded', '', '', tau, tau(1)/tau(2));

%% 2) 전달된 힘을 막대로 / the delivered force as bars
f = lab_fig('W06 Exp 6-7  constrained allocation', 1000, 460);
D = cell2mat(arrayfun(@(s) B2*s.T, S, 'UniformOutput', false));
bar(categorical({S.name}, {S.name}), D', 'grouped'); grid on;
yline(tau(1), 'k--', 'X demanded'); yline(tau(2), 'k:', 'N demanded');
legend({'X delivered [N]','N delivered [N m]'}, 'Location','northeast');
title('what each strategy gives up: the weights are where the engineering decision is stated');
exportgraphics(f, fullfile(here, 'img', 'W06_result_qp.png'), 'Resolution', 150);
