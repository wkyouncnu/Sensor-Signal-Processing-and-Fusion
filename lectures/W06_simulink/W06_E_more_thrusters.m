%% W06 · 실험 6-4 — 추진기가 요구보다 많을 때 / Experiment 6-4 — more thrusters than demands
%
%  이 절이 묻는 것 / the question
%      해가 없는 경우는 6-3 에서 보았다. 해가 **무한히 많으면** 어느 것을 고르는가?
%      Section 6-3 had no exact solution. When there are infinitely many, which one is chosen?
%
%  이 스크립트가 하는 일 / what this script does
%      모델이 없다. 명령창 계산 몇 줄이다 — 선체는 10주차의 선미 방위추진기 배치다.
%      ① 그 배치의 B (3 x 4) 를 열 규칙으로 만들고 계급을 본다.
%      ② 같은 요구에 대해 ① 최소노름해 ② 영공간으로 옮긴 다른 정확해 ③ 가중해를 낸다.
%      ③ 셋 모두 tau 를 정확히 내는지, 노름은 어떻게 다른지 찍는다.
%      No model: a few lines in the Command Window, for the aft-azimuth layout of Week 10.
%      ① Builds its B (3 x 4) from the column rule and reads the rank.
%      ② For one demand: the least-norm solution, another exact one shifted along
%         the null space, and a weighted solution.
%      ③ Prints that all three deliver tau exactly, and how their norms differ.
%
%  출력에서 볼 것 / what to look for in the output
%      - 계급이 3 이고 열이 4 이므로 영공간의 차원은 1 이다. 정확해가 한 줄로 늘어선다.
%      - 세 해 모두 잔차가 0 이다. 다른 것은 **무엇을 아끼는가** 뿐이다.
%      - 영공간 방향은 성분 2 와 4 만 건드린다: 전진·요 배분은 이미 정해져 있고,
%        자유로운 것은 횡력을 두 추진기가 어떻게 나눌지뿐이다.
%      - rank 3 with 4 columns leaves a one-dimensional family of exact solutions.
%      - All three have zero residual; they differ only in what they spare.
%      - The null direction moves components 2 and 4 alone: the surge and yaw
%        shares are already fixed, and only the sway share is free.

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
mss_path();

%% 1) 배치와 그 B / the layout and its B
B = otter_B(otter_config('aft_azimuth'));       % 방위추진기 둘 = 열 넷 / two azimuth units, four columns
tau = [100; 30; 20];                            % X [N], Y [N], N [N m]
fprintf('\n  W06 Experiment 6-4  more thrusters than demands  (B is %d x %d, rank %d)\n', size(B), rank(B));
fprintf('    the null space of B has dimension %d\n', size(null(B), 2));

%% 2) 세 가지 해 / three solutions
f0 = pinv(B)*tau;                               % 최소노름 / least norm
f1 = f0 + 20*null(B);                           % 영공간으로 20 만큼 옮긴 것 / shifted along the null space
W  = diag([1 1 4 4]);                           % 뒤 추진기가 네 배 비싸다 / the aft unit costs four times as much
fw = W\B'*((B/W*B')\tau);                       % 가중 최소노름 / weighted least norm
fprintf('    %-22s %8s %8s %8s %8s   |f|     residual\n', 'solution', 'f1x', 'f1y', 'f2x', 'f2y');
for c = {{'least norm  (pinv)', f0}, {'shifted along null', f1}, {'weighted, W = 1,1,4,4', fw}}
    fprintf('    %-22s %8.2f %8.2f %8.2f %8.2f %7.2f   %8.1e\n', c{1}{1}, c{1}{2}, norm(c{1}{2}), norm(B*c{1}{2} - tau));
end
