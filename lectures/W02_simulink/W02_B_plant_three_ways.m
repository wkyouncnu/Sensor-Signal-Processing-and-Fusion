%% W02 · 실험 2-2 — 플랜트 하나, 세 가지 표현 / Experiment 2-2 — one plant, three ways
%  모델 W02_B_three_ways 를 두 번 돌린다: 1 N 계단 힘, 그리고 힘 없이 0.5 m 에서 놓기.
%  Runs W02_B_three_ways twice: a 1 N step force, then released from 0.5 m with no force.
%
%  세 줄 / the three rows (§2-2)
%      A  미분방정식 그대로 — 적분기 두 개 / the differential equation itself, two integrators
%      B  전달함수 1/(m s^2 + b s + k)   / the transfer function
%      C  상태공간 [위치; 속도]           / the state-space model [position; velocity]
%
%  출력에서 볼 것 / what to look for in the output
%      - 계단 힘: 세 줄의 차이가 1e-16 — 한 플랜트다. 모두 F/k = 0.5 m 에 선다.
%      - 0.5 m 에서 놓기: A 와 C 는 돌아오고, B 는 0 에 머문다 — 전달함수는 초기조건을 담지 못한다.
%      - Step force: the rows differ by 1e-16 — one plant. All settle at F/k = 0.5 m.
%      - Release from 0.5 m: A and C swing back; B stays at zero — a transfer
%        function has no place for an initial condition.
%
%  만드는 것 / produces: img/W02_result_three_ways.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 두 번 돌린다 / two runs
%  W02_read 는 이 모델에 대해 R.x_ode, R.x_tf, R.x_ss (세 줄의 위치) 를 돌려준다.
%  For this model W02_read returns R.x_ode, R.x_tf, R.x_ss: the position of each row.
A = W02_read('W02_B_three_ways');                                   % 계단 힘 / step force
B = W02_read('W02_B_three_ways', 'F_step', 0, 'x0_pos', 0.5);      % 놓기 / release

%% 2) 끝값과 차이를 찍는다 (둘째 줄은 t = 0 의 값) / print end values and differences (row 2 at t = 0)

fprintf('\n  W02 Experiment 2-2  one plant, three ways\n');
fprintf('    run                     ODE end   TF end   SS end   max|ODE-SS|  max|ODE-TF|\n');
fprintf('    1 N step force          %7.4f  %7.4f  %7.4f     %8.1e     %8.1e\n', A.x_ode(end), A.x_tf(end), ...
        A.x_ss(end), max(abs(A.x_ode - A.x_ss)), max(abs(A.x_ode - A.x_tf)));
fprintf('    released from 0.5 m     %7.4f  %7.4f  %7.4f     %8.1e     %8.1e\n', B.x_ode(1), B.x_tf(1), ...
        B.x_ss(1), max(abs(B.x_ode - B.x_ss)), max(abs(B.x_ode - B.x_tf)));
fprintf('    (second row: values at t = 0)\n');

%% 3) 그림: 왼쪽 계단 힘, 오른쪽 놓기 / figure: step force on the left, release on the right
f = lab_fig('W02 Exp 2-2  three ways', 1000, 520);
R = {A, B};  T = {'a 1 N step force at t = 1 s', ...
                  'no force, released from x = 0.5 m'};
for i = 1:2
    subplot(1,2,i); hold on; grid on;
    plot(R{i}.t, R{i}.x_ode, 'LineWidth', 5, 'Color', [0.75 0.75 0.75]);
    plot(R{i}.t, R{i}.x_ss, 'LineWidth', 1.8);
    plot(R{i}.t, R{i}.x_tf, '--', 'LineWidth', 1.8);
    xlabel('time [s]'); ylabel('position x [m]'); title(T{i});
    legend({'A  ODE, two integrators','C  state space','B  transfer function'}, 'Location','best');
end
exportgraphics(f, fullfile(here, 'img', 'W02_result_three_ways.png'), 'Resolution', 150);
