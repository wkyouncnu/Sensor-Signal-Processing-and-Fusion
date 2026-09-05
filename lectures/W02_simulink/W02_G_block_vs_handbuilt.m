%% W02 · section G — the hand-built PID against Simulink's PID Controller block
%
%      W02_0_setup
%      W02_G_block_vs_handbuilt
%
%  Both controllers are inside W02_surge_control.slx and pid_mode chooses.
%  The claim under test: they are the same controller. The qualification:
%  they stop being the same once the derivative is switched on.
%  Produces img/W02_result_block.png

clear RB CASES i gap ex
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W02_surge_control.slx')), W02_1_build_surge_control; end

V = W02_vars;
c = W02_cols;

%% ---- the same gains, two implementations ------------------------------
CASES = { 'PI,  Kd = 0',   0
          'PID, Kd = 60', 60 };
RB  = cell(size(CASES,1), 2);
gap = zeros(size(CASES,1), 1);

fprintf('\n  W02 section G — hand-built PID against the library block\n\n');
fprintf('    %-16s %16s %16s %16s\n', 'case', 'max |u| gap', 'Mp hand [%]', 'Mp block [%]');
fprintf('    %s\n', repmat('-', 1, 70));

for i = 1:size(CASES,1)
    RB{i,1} = run_sim('W02_surge_control', V, 'Kp', V.Kp_d, 'Ki', V.Ki_d, ...
                      'Kd', CASES{i,2}, 'pid_mode', 0, 'T_final', 30);   % by hand
    RB{i,2} = run_sim('W02_surge_control', V, 'Kp', V.Kp_d, 'Ki', V.Ki_d, ...
                      'Kd', CASES{i,2}, 'pid_mode', 1, 'T_final', 30);   % the block
    gap(i)  = max(abs(RB{i,1}.y(:, c.u) - RB{i,2}.y(:, c.u)));
    fprintf('    %-16s %16.3e %16.2f %16.2f\n', CASES{i,1}, gap(i), ...
            step_metrics(RB{i,1}.t, RB{i,1}.y(:, c.u), V.u_d1, V.t_up), ...
            step_metrics(RB{i,2}.t, RB{i,2}.y(:, c.u), V.u_d1, V.t_up));
end

fprintf(['\n    With Kd = 0 the two agree to %.1e m/s — machine precision. They\n' ...
         '    are the same algorithm, and the nine blue blocks are worth building\n' ...
         '    once so that the one library block is never a mystery.\n'], gap(1));

fprintf(['\n    With Kd = 60 they differ by %.2f m/s, and neither is wrong. The\n' ...
         '    library block differentiates its INPUT, which here is the error, so\n' ...
         '    a step in u_d passes straight through the derivative and produces a\n' ...
         '    kick. The hand-built path differentiates the MEASUREMENT, which\n' ...
         '    never steps. Simulink''s two-degree-of-freedom PID block exists to\n' ...
         '    let the two be weighted separately.\n'], gap(2));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W02 G  block against hand', 1000, 400);

for i = 1:size(CASES,1)
    subplot(1,2,i); hold on;
    yline(V.u_d1, 'k:', 'HandleVisibility','off');
    plot(RB{i,1}.t, RB{i,1}.y(:, c.u), 'LineWidth', 2.0, 'DisplayName','built by hand');
    plot(RB{i,2}.t, RB{i,2}.y(:, c.u), '--', 'LineWidth', 1.2, 'DisplayName','PID block');
    xlabel('time [s]'); ylabel('u  [m/s]'); legend('Location','southeast');
    if i == 1
        title({CASES{i,1}, sprintf('the curves differ by %.1e m/s', gap(i))});
    else
        title({CASES{i,1}, sprintf('the curves differ by %.2f m/s', gap(i))});
    end
end

sgtitle('W02 G — the same controller, until the derivative is switched on', ...
        'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_block.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W02_result_block.png\n\n');
