%% W02 · 절 B-1 — 플랜트 하나, 세 가지 표현 / Section B-1 — one plant, three ways
%  모델 W02_B_three_ways 를 두 번 돌린다: 1 N 계단 힘, 그리고 힘 없이 0.5 m 에서 놓기.
%  Runs W02_B_three_ways twice: a 1 N step force, then released from 0.5 m with no force.
%  만드는 것 / produces: img/W02_result_three_ways.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

A = W02_read('W02_B_three_ways');                                   % 계단 힘 / step force
B = W02_read('W02_B_three_ways', 'F_step', 0, 'x0_pos', 0.5);      % 놓기 / release

fprintf('\n  W02 B-1  one plant, three ways\n');
fprintf('    run                     ODE end   TF end   SS end   max|ODE-SS|  max|ODE-TF|\n');
fprintf('    1 N step force          %7.4f  %7.4f  %7.4f     %8.1e     %8.1e\n', A.x_ode(end), A.x_tf(end), ...
        A.x_ss(end), max(abs(A.x_ode - A.x_ss)), max(abs(A.x_ode - A.x_tf)));
fprintf('    released from 0.5 m     %7.4f  %7.4f  %7.4f     %8.1e     %8.1e\n', B.x_ode(1), B.x_tf(1), ...
        B.x_ss(1), max(abs(B.x_ode - B.x_ss)), max(abs(B.x_ode - B.x_tf)));
fprintf('    (second row: values at t = 0)\n');

f = lab_fig('W02 B-1  three ways', 1000, 520);
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
