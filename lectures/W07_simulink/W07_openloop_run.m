%W07_OPENLOOP_RUN  네 틸팅 추진기, 개루프 확인 — 이 한 파일이 1부 전체를 돌린다.
%                  Four tilting thrusters, open loop: this one file runs Part 1.
%
%   돌리는 법 / how to run it
%       명령창에서   W07_openloop_run
%
%   시나리오를 고르는 법 / choosing the scenarios
%       아래 `S` 목록의 **한 줄이 한 시나리오**다. 줄 앞에 `%` 를 붙이면 그
%       시나리오가 빠진다. 아무것도 주석 처리하지 않으면 여덟이 다 돌고,
%       S1 한 줄만 남기면 S1 만, S2 만 남기면 S2 만 돈다.
%       One line of S is one scenario. Put a % in front of a line and it drops
%       out; leave one line only and that scenario alone runs.
%
%   시뮬링크에서 직접 돌리려면 / to run it from Simulink instead
%       이 파일을 한 번 돌리면 **목록에 남은 첫 시나리오**의 n_cmd · d_cmd 가
%       기본 작업공간에 남는다. 그대로 `W07_openloop.slx` 를 열어 Run 을 누르면
%       같은 시나리오가 그대로 나온다. 모델을 고칠 일은 없다.
%       This file leaves the first selected scenario's n_cmd and d_cmd in the
%       base workspace, so pressing Run in W07_openloop reproduces that one.
%
%   이 파일은 **동역학을 풀지 않는다** / this file integrates nothing
%       시나리오마다 입력 여덟 개를 바꿔 모델에 넣고, 돌아온 로그를 읽어 표와
%       그림을 만드는 것이 전부다. 적분은 시뮬링크가 하고, 실제로 가해진 힘도
%       운동모델이 **둘째 출력**으로 돌려준다 — 여기서 다시 계산하지 않는다.
%       All this file does is set the eight inputs, run the model and read the
%       log it returns. Simulink integrates, and the force the hull received
%       comes out of the motion model itself as its second output.
%
%   이 파일이 하는 일 / what this file does
%       (1) 손으로 쓴 X, Y, N 을 모델이 기록한 tau 와 견준다
%       (2) t = 30 s 에서 U · 크랩각 · 선회각속도 · 선회반경을 읽는다
%       (3) 시나리오마다 그림 한 장, 그리고 여덟을 겹친 그림 한 장
%
%   See also W07_0_SETUP, W07_1_BUILD_OPENLOOP, W07_PLOT, W07_VARS.

close all;

%% 준비 / setup
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W07_openloop';
cfg = otter_config('quad_tilt');
V   = W07_vars();                  % 모든 값이 이 파일 하나에 있다 / every value
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end

%  모멘트를 **정확히** 지우는 선미 회전수. T_a = 1.5 T_f 가 조건이고 추력이
%  회전수의 제곱이므로 회전수는 sqrt(1.5) 배다 / the stern speed that cancels
%  the yaw moment: T_a = 1.5 T_f, and thrust goes as the square of the speed
ns = 60 * sqrt(cfg.l_f / cfg.l_a);

%% 시나리오 — 한 줄이 한 시나리오다. 주석 처리하면 빠진다
%            one line per scenario; comment a line out to drop it
%
%  쌍마다 0 도가 다르다 — 선수 둘(1·2)은 앞을, 선미 둘(3·4)은 뒤를 보고 달려
%  있다. 그래서 delta = 0 은 선수 쌍에서 +x_b, 선미 쌍에서 -x_b 를 민다.
%  이 한 가지가 아래 여덟 줄의 부호를 전부 설명한다 / units 1-2 face forward and
%  3-4 face aft, so delta = 0 pushes along +x_b at the bow and -x_b at the stern
%
%     tag    n [rad/s]            delta [deg]          무엇을 지시하는가
S = { ...
    'S1'  [ 60  60 -60 -60]  [  0   0   0   0]  'surge ahead'
    'S2'  [-60 -60  60  60]  [  0   0   0   0]  'surge astern'
    'S3'  [ 60  60  60  60]  [ 45  45  45  45]  'yaw to starboard'
    'S4'  [ 60  60  60  60]  [-45 -45 -45 -45]  'yaw to port'
    'S5'  [ 60  60  60  60]  [ 45  45 -45 -45]  'sway to starboard'
    'S6'  [ 60  60  ns  ns]  [ 45  45 -45 -45]  'sway, moment cancelled'
    'S7'  [ 60  60 -60 -60]  [ 45  45   0   0]  'turn while making way'
    'S8'  [ 60  60  60  60]  [ 70  70 -70 -70]  'tilt beyond the servo limit'
};

nc = size(S, 1);
assert(nc > 0, 'W07:noScenario', 'every line of S is commented out');

%% 고른 첫 시나리오를 기본 작업공간에 둔다 — 시뮬링크 Run 이 이것을 쓴다
%  the first selected scenario is left in the base workspace for Simulink Run
n_cmd = S{1,2}';
d_deg = S{1,3}';
d_cmd = deg2rad(d_deg);

fprintf('\n  W07 open loop  --  %d of 8 scenarios selected : %s\n', ...
        nc, strjoin(S(:,1)', ' '));
fprintf('  the base workspace now holds %s, so Run in %s reproduces it\n', ...
        S{1,1}, mdl);

%% (1) 손 수식과, 모델이 기록한 힘 / the hand formula against the logged force
%
%  로그의 열 / the columns of the log, fixed by _tools/add_measurement
%      1..6   u v r N E psi      psi 는 도 / psi in DEGREES
%      7..10  n(1..4)            [rad/s], **서보 뒤** / post-servo
%      11..14 delta(1..4)        [rad],   **서보 뒤** / post-servo
%      15..17 tau = [X; Y; N]    운동모델이 만든 값 / built by the motion model
R        = cell(1, nc);
TAU      = zeros(nc, 3);
NN       = zeros(nc, 4);
DD       = zeros(nc, 4);
RES      = zeros(nc, 1);
W07batch = true;  %#ok<NASGU>  % StopFcn 의 그림을 재운다 / silence the StopFcn

fprintf('\n  (1) the hand formula against the force the hull reports\n\n');
fprintf('      X = sum si Ti cos di,   Y = sum si Ti sin di\n');
fprintf('      N = sum si (xi sin di - yi cos di) Ti\n');
fprintf('      s = [%+d %+d %+d %+d], the mounting signs\n', cfg.mount);
fprintf('      tau is column 15 to 17 of the log: what otter_tilt4 built for\n');
fprintf('      itself out of the post-servo n and delta\n\n');
fprintf('    %-4s  %-25s  %-21s  %-26s  %7s  %s\n', 'case', 'n [rad/s] after servo', ...
        'delta [deg] clipped', '   X [N]    Y [N]  N [N m]', 'resid', 'clip');
fprintf('    %s\n', repmat('-', 1, 99));

for c = 1:nc
    %  한계로 깎는다 — 서보가 하는 것을 손으로 한 번 더 / clip, as the servo does
    n = min(max(S{c,2},             cfg.n_min),      cfg.n_max);
    d = min(max(deg2rad(S{c,3}), -cfg.alpha_max), cfg.alpha_max);

    %  추력은 3주차의 곡선 T = k n|n|, 전진과 후진의 계수가 다르다
    %  thrust from the Week 3 curve, with different coefficients each way
    T = (cfg.k_pos*(n >= 0) + cfg.k_neg*(n < 0)) .* n .* abs(n);

    %  거치 부호를 입혀 더한다 / summed with the mounting signs
    s = cfg.mount;
    X = sum(s .* T .* cos(d));
    Y = sum(s .* T .* sin(d));
    N = sum(s .* (cfg.pos(1,:) .* sin(d) - cfg.pos(2,:) .* cos(d)) .* T);

    %  같은 힘이 B 의 열 규칙에서도 나오는가 / the same force, out of B
    fcol = zeros(2*cfg.n_thr, 1);
    fcol(1:2:end) = T .* cos(d);
    fcol(2:2:end) = T .* sin(d);
    assert(max(abs(cfg.B*fcol - [X; Y; N])) < 1e-12, 'W07:columnRule', ...
           'the hand sum and B f disagree for %s', S{c,1});

    %  모델을 한 번 돌린다. 값은 전부 W07_vars 에서 오고, 이 시나리오의 입력
    %  여덟 개만 덮어쓴다 / one run of the model, only the eight inputs changed
    in = Simulink.SimulationInput(mdl);
    fn = fieldnames(V);
    for i = 1:numel(fn), in = in.setVariable(fn{i}, V.(fn{i})); end
    in = in.setVariable('n_cmd', S{c,2}');
    in = in.setVariable('d_cmd', deg2rad(S{c,3})');
    evalc('out = sim(in);');

    %  로그를 이름 붙은 필드로 / the log, read into named fields
    L = out.W07;
    y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
    r = struct();        % 작업공간에 같은 이름이 남아 있어도 덮어쓴다
                         % overwrite whatever r was before
    r.t   = L.time;
    r.u   = y(:, 1);  r.v   = y(:, 2);  r.r   = y(:, 3);
    r.N   = y(:, 4);  r.E   = y(:, 5);  r.psi = y(:, 6);      % [deg]
    r.n     = y(:,  7:10);
    r.delta = y(:, 11:14);
    r.tau   = y(:, 15:17);
    r.T = (V.k_pos*(r.n >= 0) + V.k_neg*(r.n < 0)) .* r.n .* abs(r.n);

    %  서보가 명령을 깎았는가 / did a servo clip its command
    r.n_clip = any(abs(abs(r.n(end,:))     - V.n_max)      < 1e-6 | ...
                   abs(abs(r.n(end,:))     - abs(V.n_min)) < 1e-6);
    r.d_clip = any(abs(abs(r.delta(end,:)) - V.alpha_lim)   < 1e-9);

    %  틸팅 각속도 제한이 있으므로 각이 도착한 **뒤**를 견준다. 그 전까지는
    %  모델이 지나가는 중의 각을 쓰고 있고, 손 수식은 도착한 각을 쓴다
    %  the servo rate limit means the angle arrives late; the comparison starts
    %  once it has arrived, since the hand formula uses the arrived angle
    t_s  = max(abs(d))/V.alpha_rate + 4*V.h;
    k    = r.t >= t_s;
    res  = max(max(abs(r.tau(k,:) - [X Y N])));

    TAU(c,:) = [X Y N];
    NN(c,:)  = n;
    DD(c,:)  = d;
    RES(c)   = res;
    R{c}     = r;

    fprintf(['    %-4s  [%5.1f %5.1f %5.1f %5.1f]  [%4.0f %4.0f %4.0f %4.0f]' ...
             '  %8.3f %8.3f %8.3f  %7.1e  n %d  d %d\n'], ...
            S{c,1}, n, rad2deg(d), X, Y, N, res, r.n_clip, r.d_clip);
end
fprintf('    %s\n', repmat('-', 1, 99));
fprintf('    worst %.1e N or N m over the %d scenarios, from t = %.2f s on\n\n', ...
        max(RES), nc, max(abs(DD(:)))/V.alpha_rate + 4*V.h);

clear W07batch                     % 사람이 Run 을 누를 때는 그림이 떠야 한다

%% (2) 그 힘이 만드는 운동 / the motion those forces produce
fprintf('  (2) the motion those forces produce, read at t = 30 s\n\n');
fprintf('    %-4s  %-27s %8s %11s %10s %11s\n', ...
        'case', 'command', 'U [m/s]', 'crab [deg]', 'r [deg/s]', 'radius [m]');
fprintf('    %s\n', repmat('-', 1, 76));

for c = 1:nc
    r    = R{c};
    U    = hypot(r.u(end), r.v(end));
    crab = rad2deg(atan2(r.v(end), r.u(end)));
    rr   = r.r(end);
    if abs(rr) > 1e-4
        rad_s = sprintf('%.2f', U/abs(rr));
    else
        rad_s = 'straight';
    end
    fprintf('    %-4s  %-27s %8.3f %11.2f %10.3f %11s\n', ...
            S{c,1}, S{c,4}, U, crab, rad2deg(rr), rad_s);
end
fprintf('    %s\n\n', repmat('-', 1, 76));

%  이 주차가 켜는 비대칭 셋 / the three asymmetries this week turns on
fprintf('      thrust curve   +60 rad/s gives %+7.3f N, -60 rad/s gives %+7.3f N\n', ...
        cfg.k_pos*60^2, -cfg.k_neg*60^2);
fprintf('      the stations   l_f = %.2f m forward, l_a = %.2f m aft\n', cfg.l_f, cfg.l_a);
fprintf('      the servo      +-%.0f deg, so 70 deg is given as %.0f deg\n\n', ...
        rad2deg(cfg.alpha_max(1)), rad2deg(cfg.alpha_max(1)));

%% (3) 그림 / the figures
for c = 1:nc
    r  = R{c};
    f  = lab_fig(sprintf('W07  %s  %s', S{c,1}, S{c,4}), 1240, 820);
    C1 = [0 0.45 0.74];

    %  왼쪽 3x2 — 상태량 여섯 / the six states, left
    P = { 1, r.u,          'u  surge [m/s]'
          2, r.v,          'v  sway [m/s]'
          4, rad2deg(r.r), 'r  yaw rate [deg/s]'
          5, r.psi,        '\psi  heading [deg]'
          7, r.N,          'x  North [m]'
          8, r.E,          'y  East [m]' };
    for k = 1:size(P,1)
        subplot(3,3,P{k,1});
        plot(r.t, P{k,2}, 'Color', C1, 'LineWidth', 1.5);
        grid on; xlabel('time [s]'); ylabel(P{k,3});
        xlim([r.t(1) r.t(end)]);
    end

    %  오른쪽 위 — 지시한 힘을 그림으로 되읽는다 / the command, drawn
    %      화면 가로가 y_b (우현이 오른쪽), 세로가 x_b (선수가 위) 다. 그래서
    %      N > 0 이 시계방향으로 보인다 / screen right is y_b, up is x_b
    subplot(3,3,3); hold on; grid off;
    T  = (cfg.k_pos*(NN(c,:) >= 0) + cfg.k_neg*(NN(c,:) < 0)) .* NN(c,:) .* abs(NN(c,:));
    Fx = cfg.mount .* T .* cos(DD(c,:));
    Fy = cfg.mount .* T .* sin(DD(c,:));
    xf = cfg.l_f + 0.25;  xa = -cfg.l_a - 0.25;  w = 0.145;
    for yc = [-cfg.y_pont, cfg.y_pont]
        patch([yc-w yc+w yc+w yc yc-w], [xa xa xf-0.30 xf xf-0.30], ...
              [0.90 0.94 0.90], 'EdgeColor', [0.35 0.45 0.35]);
    end
    plot([-cfg.y_pont cfg.y_pont], [0 0], '-', 'Color', [0.35 0.45 0.35]);
    plot([0 0], [xa xf], ':', 'Color', [0.6 0.6 0.6]);
    sc = 0.9 / 60;                                   % 60 N -> 0.9 m, 고정 축척
    for i = 1:4
        plot(cfg.pos(2,i), cfg.pos(1,i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
        if hypot(Fx(i), Fy(i)) > 1e-6
            quiver(cfg.pos(2,i), cfg.pos(1,i), sc*Fy(i), sc*Fx(i), 0, ...
                   'Color', [0.85 0.33 0.10], 'LineWidth', 1.6, 'MaxHeadSize', 2);
        end
        if cfg.pos(2,i) < 0, ha = 'right';  off = -0.26;
        else,                ha = 'left';   off =  0.26;
        end
        text(cfg.pos(2,i) + off, cfg.pos(1,i), sprintf('%d', i), 'FontSize', 9, ...
             'HorizontalAlignment', ha, 'VerticalAlignment', 'middle');
    end
    plot(0, 0, 'ks', 'MarkerFaceColor', 'w');
    xlabel('y_b  starboard [m]'); ylabel('x_b  ahead [m]');
    title({'the command, drawn', 'arrows are s_i T_i at \delta_i,   60 N = 0.9 m'}, ...
          'FontSize', 9);
    axis equal; xlim([-2.0 2.0]); ylim([xa-0.9 xf+0.9]);

    %  오른쪽 아래 — 궤적. 선체와 선수방위를 함께 그린다 (크랩각이 보여야 한다)
    %  the track, with the hull and its heading drawn along it
    ax = subplot(3,3,[6 9]); hold on; grid on;
    plot(r.E, r.N, 'Color', C1, 'LineWidth', 1.5);
    track_ships({[r.N r.E r.psi]}, C1, 'Marks', 5, 'Heading', 1.0);
    plot(0, 0, 'ks', 'MarkerFaceColor', 'w', 'HandleVisibility', 'off');
    xlabel('y  East [m]'); ylabel('x  North [m]');
    %  선체 글리프가 2 m 다. 제자리 선회는 0.1 m 밖에 움직이지 않으므로 보이는
    %  범위에 바닥을 둔다 / a floor on the view, or the glyph fills the panel
    cE = (max(r.E) + min(r.E))/2;  cN = (max(r.N) + min(r.N))/2;
    span = max([max(r.E)-min(r.E), max(r.N)-min(r.N), 5]);
    xlim(ax, cE + 0.58*span*[-1 1]);
    ylim(ax, cN + 0.58*span*[-1 1]);
    daspect(ax, [1 1 1]);
    title('track, hull drawn every few metres');

    %  제목 석 줄이 들어가도록 축 전체를 아래로 눌러 둔다 / make room for sgtitle
    for a = findall(f, 'Type', 'axes')'
        p = get(a, 'Position');
        set(a, 'Position', [p(1), p(2)*0.88, p(3), p(4)*0.88]);
    end
    sgtitle({sprintf('%s   %s', S{c,1}, S{c,4}), ...
             sprintf(['n = [%.1f %.1f %.1f %.1f] rad/s,   ' ...
                      '\\delta = [%.0f %.0f %.0f %.0f] deg,   ' ...
                      '\\tau = [%.3f N, %.3f N, %.3f N m]'], ...
                     S{c,2}, S{c,3}, TAU(c,:))}, ...
            'FontWeight', 'bold', 'FontSize', 11);

    png = fullfile(here, 'img', sprintf('W07_result_%s.png', S{c,1}));
    exportgraphics(f, png, 'Resolution', 150);
    fprintf('    saved %s\n', png);
end

%  여덟을 겹친 한 장. 여덟이 다 돌았을 때만 저장한다 — 강의자료가 쓰는 그림이다
%  the overlay, saved only when all eight ran: the lecture uses this one
if nc > 1
    LBL = cellfun(@(t, nm) sprintf('%s  %s', t, nm), S(:,1), S(:,4), ...
                  'UniformOutput', false);
    fo  = W07_plot(R, LBL', 'W07 four tilting thrusters, open loop — all scenarios');
    if nc == size(TAU,1) && nc == 8
        png = fullfile(here, 'img', 'W07_result_openloop.png');
        exportgraphics(fo, png, 'Resolution', 150);
        fprintf('    saved %s\n', png);
    end
end

fprintf('\n');
