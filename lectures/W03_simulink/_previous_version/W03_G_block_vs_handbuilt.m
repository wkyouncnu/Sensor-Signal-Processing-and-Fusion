%% W03 · 절 G — 손으로 조립한 PID 와 Simulink 의 PID Controller 블록
%  W03 · Section G — the hand-built PID against Simulink's PID Controller block
%
%  실행 순서 / order of execution
%      W03_0_setup
%      W03_G_block_vs_handbuilt
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
%      두 경로가 갈라지는 지점은 §3-4 가 다룬 바로 그 자리이다. 라이브러리
%      블록은 자기 입력을 미분하는데 그 입력이 오차이고, 손으로 조립한 경로는
%      측정값을 미분한다. 두 형태는 되먹임 경로가 같아 극점이 같고, 설정값
%      경로가 달라 영점이 다르다.
%
%      The claim is that the two controllers are the same, and the
%      qualification is that they cease to be the same once the derivative is
%      switched on. The point at which they part is the one §3-4 examined: the
%      library block differentiates its own input, which here is the error,
%      whereas the hand-built path differentiates the measurement. The two
%      share a feedback path, and therefore their poles, but not their
%      setpoint path, and therefore not their zeros.
%
%  만드는 것 / what it produces
%      표 하나와 img/W03_result_block.png
%      One table and img/W03_result_block.png

clear RB CASES i gap ex
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W03_surge_control.slx')), W03_1_build_surge_control; end

V = W03_vars;
c = W03_cols;

%% ---- the same gains, two implementations ------------------------------
CASES = { 'PI,  Kd = 0',   0
          'PID, Kd = 60', 60 };
RB  = cell(size(CASES,1), 2);
gap = zeros(size(CASES,1), 1);

fprintf('\n  W03 section G — hand-built PID against the library block\n\n');
fprintf('    %-16s %16s %16s %16s\n', 'case', 'max |u| gap', 'Mp hand [%]', 'Mp block [%]');
fprintf('    %s\n', repmat('-', 1, 70));

for i = 1:size(CASES,1)
    RB{i,1} = run_sim('W03_surge_control', V, 'Kp', V.Kp_d, 'Ki', V.Ki_d, ...
                      'Kd', CASES{i,2}, 'pid_mode', 0, 'T_final', 30);   % by hand
    RB{i,2} = run_sim('W03_surge_control', V, 'Kp', V.Kp_d, 'Ki', V.Ki_d, ...
                      'Kd', CASES{i,2}, 'pid_mode', 1, 'T_final', 30);   % the block
    gap(i)  = max(abs(RB{i,1}.y(:, c.u) - RB{i,2}.y(:, c.u)));
    fprintf('    %-16s %16.3e %16.2f %16.2f\n', CASES{i,1}, gap(i), ...
            step_metrics(RB{i,1}.t, RB{i,1}.y(:, c.u), V.u_d1, V.t_up), ...
            step_metrics(RB{i,2}.t, RB{i,2}.y(:, c.u), V.u_d1, V.t_up));
end

%  c_d = 1 로 두면 손으로 조립한 경로가 교과서형이 되어 라이브러리 블록과 같아진다.
%  두 경로가 같은 제어기라는 것을 가장 강하게 보이는 방법이므로 여기서 함께 잰다.
%  Setting c_d = 1 turns the hand-built path into the textbook form, which is
%  what the library block computes. It is the strongest available statement
%  that the two are one controller, so it is measured here alongside the rest.
gapW = max(abs(run_sim('W03_surge_control', V, 'Kp',V.Kp_d, 'Ki',V.Ki_d, ...
                       'Kd',60, 'c_d',1, 'pid_mode',0, 'T_final',30).y(:, c.u) - ...
                run_sim('W03_surge_control', V, 'Kp',V.Kp_d, 'Ki',V.Ki_d, ...
                       'Kd',60, 'pid_mode',1, 'T_final',30).y(:, c.u)));

fprintf(['\n    WITH THE DERIVATIVE SWITCHED OFF THE TWO ARE ONE CONTROLLER.\n' ...
         '\n      They agree to %.1e m/s, which is machine precision. Assembling\n' ...
         '      the controller from separate blocks is worth doing once, so that\n' ...
         '      the single library block is never a mystery afterwards: what is\n' ...
         '      inside it has been built, run, and measured against it.\n' ...
         '\n    WITH Kd = 60 THEY DIFFER BY %.2f m/s, AND NEITHER IS WRONG.\n' ...
         '\n      Section 3-4 names the single parameter that separates them. The\n' ...
         '      derivative acts on (c_d u_d - u), and the library block is the\n' ...
         '      c_d = 1 member of that family: it differentiates the error, so a\n' ...
         '      step in u_d passes straight through and produces a kick. The\n' ...
         '      hand-built path is set to c_d = 0 and differentiates the\n' ...
         '      measurement, which never steps.\n' ...
         '\n      This is testable rather than merely assertable. Setting c_d = 1\n' ...
         '      on the hand-built path, with Kd = 60 unchanged, brings the two to\n' ...
         '      within %.1e m/s of each other over the whole run. The difference\n' ...
         '      measured above is therefore not an implementation difference at\n' ...
         '      all, but a difference of setpoint weight.\n'], ...
         gap(1), gap(2), gapW);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W03 G  block against hand', 1000, 400);

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

sgtitle('W03 G — the same controller, until the derivative is switched on', ...
        'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W03_result_block.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W03_result_block.png\n\n');
