%% W02 · 절 G — 손으로 조립한 PID 와 Simulink 의 PID Controller 블록
%  W02 · Section G — the hand-built PID against Simulink's PID Controller block
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_G_block_vs_handbuilt
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 G 이다. 절 D 부터 F 까지는 제어기를 블록 아홉 개로 직접
%      조립해 썼다. 라이브러리 블록 하나로도 같은 일을 할 수 있으므로, 그 둘이
%      정말로 같은 제어기인지를 확인하는 자리이다.
%
%      This is section G of Part 2. Sections D to F used a controller
%      assembled from nine blocks by hand, although one library block can do
%      the same work. Here the two are compared to establish whether they are
%      in fact the same controller.
%
%  시험하는 주장과 그 단서 / the claim under test, and its qualification
%      주장  두 제어기는 같다.
%      단서  미분을 켜는 순간부터는 같지 않다.
%
%      두 경로가 갈라지는 지점은 §2-4 가 다룬 바로 그 자리이다. 라이브러리
%      블록은 자기 입력을 미분하는데 그 입력이 오차이고, 손으로 조립한 경로는
%      측정값을 미분한다. 두 형태는 되먹임 경로가 같아 극점이 같고, 설정값
%      경로가 달라 영점이 다르다.
%
%      The claim is that the two controllers are the same, and the
%      qualification is that they cease to be the same once the derivative is
%      switched on. The point at which they part is the one §2-4 examined: the
%      library block differentiates its own input, which here is the error,
%      whereas the hand-built path differentiates the measurement. The two
%      share a feedback path, and therefore their poles, but not their
%      setpoint path, and therefore not their zeros.
%
%  만드는 것 / what it produces
%      표 하나와 img/W02_result_block.png
%      One table and img/W02_result_block.png

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
