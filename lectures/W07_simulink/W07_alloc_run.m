%W07_ALLOC_RUN  7주차 제어배분 — **모델을 돌려서** §7-8 부터 §7-12 까지를 낸다.
%               Week 7 control allocation: 7-8 to 7-12, all of it by running
%               the model.
%
%  이 파일이 **하지 않는** 일 / what this file does NOT do
%      배분 법칙을 다시 구현하지 않는다. 법칙 넷은 `W07_alloc_chain.slx` 의
%      `allocation` 서브시스템 안에 **MATLAB Function 블록 넷**으로 들어 있고,
%      Multiport Switch 가 `law` 로 하나를 고른다. 이 스크립트는 작업공간의
%      `law` 와 `tau_cmd` 와 가중값을 바꾸고 `sim` 을 부를 뿐이다
%      (사용자 지시, 2026-11-14).
%      It does not re-implement a single allocation law. The four laws live in
%      four MATLAB Function blocks inside the allocation subsystem of
%      W07_alloc_chain.slx, and a Multiport Switch picks one with `law`. This
%      script only changes `law`, `tau_cmd` and the weights on the workspace
%      and calls sim.
%
%      그래서 강의자료의 모든 수치는 **학생이 Run 을 눌러서 보는 그 블록**에서
%      나온다. 스크립트와 모델이 어긋날 자리가 없다.
%      Every number in the lecture therefore comes out of the very block the
%      student sees on Run. There is no second implementation to drift.
%
%  고르는 법 / how to choose
%      아래 SEC 목록에서 **줄을 주석 처리하면 그 절은 돌지 않는다.** 아무것도
%      주석 처리하지 않으면 여섯 절이 차례로 돈다.
%      Comment a line out of the SEC list below and that section does not run.
%      With nothing commented out, all six sections run, in order.
%
%  왜 `sim` 이 전부 스크립트 본문에 있는가 / why every sim sits in the script body
%      `sim` 을 **함수 안에서** 부르면 To Workspace 블록의 로그가 그 함수의
%      작업공간에 생긴다. 그러면 모델의 StopFcn (`W07_plot_ca`) 이 기준
%      작업공간에서 로그를 찾지 못해 그림이 뜨지 않는다. 그래서 이 파일은
%      값을 놓는 일(`set_vars`) 과 읽는 일(`read_logs`) 만 함수로 두고,
%      `sim` 은 **본문에서** 부른다 — 스크립트의 작업공간이 곧 기준 작업공간이다.
%      Called from inside a function, sim leaves the To Workspace logs in that
%      function's workspace, where the model's StopFcn cannot find them. Only
%      placing the values (set_vars) and reading the logs (read_logs) are
%      functions here; every sim is called from the script body, whose
%      workspace IS the base workspace.
%
%  시뮬링크에서 직접 / straight from Simulink
%      이 스크립트가 한 번 돌고 나면 `law` 와 `tau_cmd` 가 작업공간에 남는다.
%      모델을 열고 Run 을 누르면 같은 법칙이 다시 돌고, `W07_plot_ca` 가 진단
%      그림 여섯 칸을 띄운다. 다른 법칙을 보려면 작업공간의 `law` 를 1~4 로
%      바꾸고 Run 을 누른다. `.slx` 는 고치지 않는다.
%      After this script has run once, `law` and `tau_cmd` are left on the
%      workspace. Open the model, press Run, and the same law runs again with
%      the six diagnostic panels of W07_plot_ca. To see another law, set `law`
%      to 1..4 on the workspace and press Run. The .slx is never edited.
%
%  밖에 두는 것 / what is left outside this file
%      `W07_alloc_chain.slx`  법칙 넷과 하드웨어 한계 / the laws and the limits
%      `otter_config` · `otter_B`                공용 형상 / shared geometry
%      `W07_vars`      그 주차의 값 한 벌 / the week's settings
%      `W07_plot_ca`   모델의 StopFcn — 진단 그림 여섯 칸 / the six panels
%      `quad_thrust_plan`   위에서 본 추력 그림 / the plan view
%
%  See also W07_OPENLOOP_RUN, W07_2_BUILD_ALLOC, W07_PLOT_CA, W07_0_SETUP.

close all;

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W07_alloc_chain';
assert(isfile(fullfile(here, [mdl '.slx'])), 'W07:noModel', ...
       '%s.slx 가 없다. 먼저 W07_2_build_alloc 를 돌린다 / build it first', mdl);

cfg = otter_config('quad_tilt');
V   = W07_vars();
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end

%  모델이 읽는 이름을 작업공간에 한 번 깔아 둔다 / the names the model reads
push_vars(V);
animate  = 0;        % 화면을 그리지 않는다 / no live window
pace     = 0;        % 현실 시간으로 기다리지 않는다 / no real-time pacing
W07batch = true;     % run_alone 이 animate 를 올리지 않게 / keep it quiet
W07quiet = true;     % StopFcn 의 그림을 끈다 / the StopFcn draws nothing

B     = cfg.B;
aft   = cfg.pos(1,:) < 0;                      % 선미 쌍 / the aft pair
quadq = [cfg.pos ; cfg.alpha_max ; cfg.mount];

%  돌리는 시간 — 배분은 대수식이므로 짧아도 된다 / allocation is algebraic
T_SWEEP = 1;        % 표를 뽑는 동안 / while tables are being measured
T_SHOW  = 5;        % 그림에 시간축이 보여야 하는 절 / where a history is drawn

law_name = {'minimum norm', 'weighted minimum norm', ...
            'weighted, folded onto the servo limit', ...
            'servo limit and thrust cap as constraints'};

%% 돌릴 절 — 줄을 주석 처리하면 그 절이 빠진다 / the sections to run ----------
%     한 줄이 한 절이다. `%` 하나로 절 하나가 빠진다
%     one line is one section; one % removes one section
SEC = { ...
    '7-8'   'the minimum-norm solution, straight out of the block'
    '7-9'   'the weight matrix W, swept'
    '7-10'  'the servo-angle limit: law 2 against law 3'
    '7-11'  'the thrust cap as well: law 4, and how Q and eps are tuned'
    '7-12'  'the four laws side by side, out of one model'
};

tau_nom  = [  0 ;  40 ;  0];    % 순수 횡방향 — 서보 한계를 건드린다 / servo-binding
tau_hard = [340 ;  60 ; 25];    % 추력 캡까지 건드린다 / thrust-cap-binding

want = @(s) any(strcmp(s, SEC(:,1)));
fprintf('\n==== W07 allocation, run from the model %s ====\n', mdl);
fprintf('  sections: %s\n', strjoin(SEC(:,1).', ', '));

%% §7-8  최소 노름 해 — 블록이 그 공식을 그대로 쓰는가 ----------------------
if want('7-8')
hdr('7-8', 'the minimum-norm solution, straight out of the block');
T_final = T_SWEEP;

set_vars(1, tau_nom);  sim(mdl);  R1 = read_logs(1);

%  블록이 유도의 공식을 그대로 쓰는지 본다 / does the block use the formula
%      f = B' * inv(B*B') * tau_d                     (§7-8)
f_hand = B.' * ((B * B.') \ tau_nom);
fprintf('  the block and  f = B''(BB'')^-1 tau_d  agree to %.3e N\n', ...
        max(abs(R1.f - f_hand)));
fprintf('  ||f|| from the block         %8.4f N\n', norm(R1.f));
fprintf('  ||f|| from the hand solution %8.4f N\n', norm(f_hand));

unit_table(R1, 'law 1, minimum norm');

fig = figure('Color', 'w', 'Position', [60 60 980 640]);
subplot(2,2,1);
quad_thrust_plan(quadq, R1.T, R1.d_ask, tau_nom(1:2).', ...
                 'What law 1 asked for, before any limit');
subplot(2,2,2);
bar(R1.f); grid on
set(gca, 'XTick', 1:8, 'XTickLabel', ...
    {'f_{x1}','f_{y1}','f_{x2}','f_{y2}','f_{x3}','f_{y3}','f_{x4}','f_{y4}'});
ylabel('[N]');
title(sprintf('The eight components,  ||f|| = %.2f N', norm(R1.f)), 'FontSize', 9);
subplot(2,2,3);
bar(rad2deg([R1.d_ask R1.d_got])); grid on; hold on
yline( rad2deg(V.alpha_lim), 'r--', '+limit', 'FontSize', 8);
yline(-rad2deg(V.alpha_lim), 'r--', '-limit', 'FontSize', 8);
set(gca, 'XTickLabel', {'1','2','3','4'});
xlabel('unit'); ylabel('delta [deg]');
legend({'asked','allowed'}, 'Location', 'best', 'FontSize', 8);
title('Every unit asks for more tilt than the servo has', 'FontSize', 9);
subplot(2,2,4);
bar([R1.tau_d ; R1.tau_a].'); grid on
set(gca, 'XTickLabel', {'X','Y','N'});
legend({'demanded','delivered'}, 'Location', 'best', 'FontSize', 8);
title(sprintf('A yaw of %+.2f N m arrives that was never asked for', ...
      R1.tau_a(3)), 'FontSize', 9);
sgtitle('7-8  minimum norm: the solution, and what the servo limit does to it', ...
        'FontSize', 11);
savepng(fig, fullfile(here, 'img', 'W07_alloc_pinv.png'));
end

%% §7-9  가중 행렬 W — 값을 바꿔 가며 모델을 다시 돈다 ----------------------
if want('7-9')
hdr('7-9', 'the weight matrix W, swept');
T_final = T_SWEEP;

%  (가) 가로 성분의 값만 올린다 / (a) raise the price of the sideways component
w_list = [1 3 10 30 100 300 1000];
S      = zeros(numel(w_list), 5);
for i = 1:numel(w_list)
    set_vars(2, tau_nom, struct('W_alloc', diag(repmat([1 w_list(i)], 1, 4))));
    sim(mdl);
    R  = read_logs(2);
    fx = R.f(1:2:7);  fy = R.f(2:2:8);
    S(i,:) = [sum(abs(fy)), max(fx) - min(fx), ...
              rad2deg(max(abs(R.d_ask))), norm(R.f), norm(R.e)];
end
fprintf('  (a) the price of the sideways component\n');
fprintf('        w_y    sum|f_y|   spread|f_x|   worst delta     ||f||   tau err\n');
for i = 1:numel(w_list)
    fprintf('   %9.0f %10.2f %12.2f %13.2f %9.2f %9.3f\n', w_list(i), S(i,:));
end

%  (나) 선미 쌍만 비싸게 한다 / (b) price the aft pair dearer
c_list = [1 2 5 10 20];
Sa     = zeros(numel(c_list), 3);
for i = 1:numel(c_list)
    d = repmat([1 10], 1, 4);
    d(repelem(aft, 2)) = d(repelem(aft, 2)) * c_list(i);
    set_vars(2, tau_nom, struct('W_alloc', diag(d)));
    sim(mdl);
    R   = read_logs(2);
    mag = hypot(R.f(1:2:7), R.f(2:2:8));
    Sa(i,:) = [100 * sum(mag(aft)) / sum(mag), norm(R.f), norm(R.e)];
end
fprintf('  (b) the aft pair priced c times the forward pair\n');
fprintf('          c   aft share [%%]      ||f||    tau err\n');
for i = 1:numel(c_list)
    fprintf('   %10.0f %13.1f %10.2f %10.3f\n', c_list(i), Sa(i,:));
end
set_vars(2, tau_nom, struct('W_alloc', V.W_alloc));

fig = figure('Color', 'w', 'Position', [60 60 980 400]);
subplot(1,2,1);
yyaxis left
semilogx(w_list, S(:,2), 'o-', 'LineWidth', 1.6); hold on
semilogx(w_list, S(:,1), ':',  'LineWidth', 1.6);
ylabel('[N]');
yyaxis right
semilogx(w_list, S(:,3), 's-', 'LineWidth', 1.6); hold on
yline(rad2deg(V.alpha_lim), 'r--', 'servo limit', 'FontSize', 8);
ylabel('worst |delta|  [deg]');
grid on; xlabel('price of the sideways component,  w_y');
legend({'spread of |f_x|', 'sum |f_y|, pinned by the demand', ...
        'worst |delta|'}, 'Location', 'northwest', 'FontSize', 7);
title('Pricing f_y cannot move sideways thrust -- it buys back angle', 'FontSize', 9);

subplot(1,2,2);
semilogx(c_list, Sa(:,1), 'o-', 'LineWidth', 1.6); grid on; hold on
yline(50, 'k:', 'an even share', 'FontSize', 8);
xlabel('the aft pair priced c times the forward pair');
ylabel('aft share of the total thrust  [%]');
ylim([0 60]);
title('Pricing one pair against the other does move load', 'FontSize', 9);
sgtitle('7-9  what the weight matrix can and cannot move', 'FontSize', 11);
savepng(fig, fullfile(here, 'img', 'W07_alloc_weights.png'));
end

%% §7-10  서보 각 한계 — 법칙 2 와 법칙 3 ----------------------------------
if want('7-10')
hdr('7-10', 'the servo-angle limit: law 2 against law 3');
T_final = T_SWEEP;

set_vars(2, tau_nom);  sim(mdl);  R2 = read_logs(2);
set_vars(3, tau_nom);  sim(mdl);  R3 = read_logs(3);
unit_table(R2, 'law 2, weighted minimum norm');
unit_table(R3, 'law 3, weighted and folded onto the servo limit');

fprintf('  what the fold costs and what it buys\n');
fprintf('        law   worst delta asked   clipped units   tau error [N]\n');
for R = [R2 R3]
    fprintf('   %10d %18.2f %15d %15.3f\n', R.law, ...
            rad2deg(max(abs(R.d_ask))), sum(abs(R.d_ask - R.d_got) > 1e-9), ...
            norm(R.e));
end

fig = figure('Color', 'w', 'Position', [60 60 980 640]);
RR = [R2 R3];
for j = 1:2
    subplot(2,2,j);
    bar(rad2deg([RR(j).d_ask RR(j).d_got])); grid on; hold on
    yline( rad2deg(V.alpha_lim), 'r--', '+limit', 'FontSize', 8);
    yline(-rad2deg(V.alpha_lim), 'r--', '-limit', 'FontSize', 8);
    set(gca, 'XTickLabel', {'1','2','3','4'});
    xlabel('unit'); ylabel('delta [deg]');
    legend({'asked','allowed'}, 'Location', 'best', 'FontSize', 8);
    title(sprintf('law %d -- %s', RR(j).law, law_name{RR(j).law}), 'FontSize', 9);
end
subplot(2,2,3);
bar([R2.tau_d ; R2.tau_a ; R3.tau_a].'); grid on
set(gca, 'XTickLabel', {'X','Y','N'});
legend({'demanded','law 2','law 3'}, 'Location', 'best', 'FontSize', 8);
title('What the hull received', 'FontSize', 9);
subplot(2,2,4);
bar([norm(R2.e) norm(R3.e)]); grid on
set(gca, 'XTickLabel', {'law 2','law 3'});
ylabel('||tau delivered - tau demanded||  [N]');
title('Folding the solution onto the limit is not free', 'FontSize', 9);
sgtitle('7-10  a limit the solver never saw, and a fold that respects it', ...
        'FontSize', 11);
savepng(fig, fullfile(here, 'img', 'W07_alloc_limits.png'));
end

%% §7-11  두 한계 모두 — 법칙 4, 그리고 Q 와 eps -----------------------------
if want('7-11')
hdr('7-11', 'the thrust cap as well: law 4, and how Q and eps are tuned');
T_final = T_SWEEP;
Q_tau   = eye(3);  %#ok<NASGU>
eps_reg = 1e-4;  %#ok<NASGU>

%  (가) 네 법칙을 같은 두 명령에 걸어 본다 / (a) four laws, two demands
fprintf('  (a) the same demand through each of the four laws\n');
fprintf('      demand                   law   tau error [N]   clipped units\n');
RH = [];
for d = 1:2
    tt = [tau_nom tau_hard];
    tt = tt(:,d);
    for k = 1:4
        set_vars(k, tt);  sim(mdl);  R = read_logs(k);
        fprintf('   [%5.0f %5.0f %5.0f] %9d %15.3f %13d\n', tt, k, norm(R.e), ...
                sum(abs(R.d_ask - R.d_got) > 1e-9) + ...
                sum(abs(R.n_ask - R.n_got) > 1e-9));
        if d == 2, RH = [RH R];  end                              %#ok<AGROW>
    end
end

%  (나) eps 를 바꾼다 / (b) the regularisation
fprintf('  (b) law 4 at the hard demand, eps swept\n');
fprintf('          eps     tau error [N]      ||f|| [N]\n');
for ep = [1e-8 1e-6 1e-4 1e-2 1e0]
    set_vars(4, tau_hard, struct('eps_reg', ep));
    sim(mdl);
    R = read_logs(4);
    fprintf('   %12.0e %15.4f %14.2f\n', ep, norm(R.e), norm(R.f));
end
eps_reg = 1e-4;

%  (다) Q 를 바꾼다 / (c) the weight on the three components of the error
fprintf('  (c) law 4 at the hard demand, Q swept\n');
fprintf('      diag(Q)              X err      Y err      N err     norm\n');
Qs = {eye(3), diag([1 1 10]), diag([10 10 1]), diag([1 1 100])};
for i = 1:numel(Qs)
    set_vars(4, tau_hard, struct('Q_tau', Qs{i}));
    sim(mdl);
    R = read_logs(4);
    fprintf('   [%4.0f %4.0f %4.0f] %14.3f %10.3f %10.3f %8.3f\n', ...
            diag(Qs{i}), R.e, norm(R.e));
end
Q_tau = eye(3);
set_vars(4, tau_hard, struct('Q_tau', Q_tau, 'eps_reg', eps_reg));

fig = figure('Color', 'w', 'Position', [60 60 980 640]);
subplot(2,2,1);
bar([RH.T].'); grid on; hold on
yline( V.T_pos, 'r--', 'ahead cap',  'FontSize', 8);
yline(-V.T_neg, 'r--', 'astern cap', 'FontSize', 8);
set(gca, 'XTickLabel', {'law 1','law 2','law 3','law 4'});
ylabel('T per unit  [N]');
title('The thrust each law asked of the four units', 'FontSize', 9);
subplot(2,2,2);
bar(rad2deg([RH.d_ask].')); grid on; hold on
yline( rad2deg(V.alpha_lim), 'r--', '+limit', 'FontSize', 8);
yline(-rad2deg(V.alpha_lim), 'r--', '-limit', 'FontSize', 8);
set(gca, 'XTickLabel', {'law 1','law 2','law 3','law 4'});
ylabel('delta asked  [deg]');
title('What each law asked of the servos', 'FontSize', 9);
subplot(2,2,3);
bar(arrayfun(@(R) norm(R.e), RH)); grid on
set(gca, 'XTickLabel', {'law 1','law 2','law 3','law 4'});
ylabel('||tau delivered - tau demanded||  [N]');
title(sprintf('Demand [%g %g %g]', tau_hard), 'FontSize', 9);
subplot(2,2,4);
quad_thrust_plan(quadq, RH(4).T, RH(4).d_got, tau_hard(1:2).', ...
                 'Law 4: inside both limits, and still on the demand');
sgtitle('7-11  two limits at once, and what they cost each law', 'FontSize', 11);
savepng(fig, fullfile(here, 'img', 'W07_chain_sat.png'));
end

%% §7-12  법칙 넷을 한 모델에서 ---------------------------------------------
if want('7-12')
hdr('7-12', 'the four laws side by side, out of one model');
T_final  = T_SHOW;
W07quiet = false;  %#ok<NASGU>  % StopFcn 이 진단 그림 여섯 칸을 낸다 / six panels each

RS = [];
for k = 1:4
    set_vars(k, tau_nom);
    sim(mdl);
    RS = [RS read_logs(k)];                                       %#ok<AGROW>
end
W07quiet = true;

fprintf('  every row below came out of the same .slx, with `law` changed\n');
fprintf('        law     X [N]     Y [N]   N [N m]   error [N]   servo   rpm\n');
for R = RS
    fprintf('   %10d %9.3f %9.3f %9.3f %11.3f %7d %5d\n', R.law, R.tau_a, ...
            norm(R.e), sum(abs(R.d_ask - R.d_got) > 1e-9), ...
            sum(abs(R.n_ask - R.n_got) > 1e-9));
end

fig = figure('Color', 'w', 'Position', [60 60 980 400]);
subplot(1,2,1);
bar([RS(1).tau_d ; vertcat(RS.tau_a)].'); grid on
set(gca, 'XTickLabel', {'X','Y','N'});
legend({'demanded','law 1','law 2','law 3','law 4'}, ...
       'Location', 'northwest', 'FontSize', 7);
ylabel('force / moment');
title(sprintf('Demand [%g %g %g] through each law', tau_nom), 'FontSize', 9);
subplot(1,2,2);
bar(arrayfun(@(R) norm(R.e), RS)); grid on
set(gca, 'XTickLabel', {'law 1','law 2','law 3','law 4'});
ylabel('||tau delivered - tau demanded||  [N]');
title('The same model, the same demand, four answers', 'FontSize', 9);
sgtitle('7-12  one model, four laws, chosen by the Constant `law`', 'FontSize', 11);
savepng(fig, fullfile(here, 'img', 'W07_chain_tau.png'));

fprintf('\n  which law to use\n');
fprintf('    1  no limit is near            -- the cheapest, and the baseline\n');
fprintf('    2  one axis costs more         -- same price, shapes the solution\n');
fprintf('    3  the servo limit is reached  -- cheap, but the demand is missed\n');
fprintf('    4  any limit is reached        -- meets the demand, costs the most\n');
end

fprintf('\n==== done.  `law` = %d and `tau_cmd` are on the workspace;\n', law);
fprintf('     open %s and press Run to see that law again. ====\n\n', mdl);


% =========================================================================
function hdr(sec, txt)
%HDR  절 머리 / one section heading
fprintf('\n---- %s  %s %s\n', sec, txt, repmat('-', 1, max(0, 56 - numel(txt))));
end

% =========================================================================
function push_vars(V)
%PUSH_VARS  `W07_vars` 의 값을 작업공간에 올린다 — 모델이 이 이름들을 읽는다
%           put the W07_vars settings on the base workspace, where the model
%           resolves every Constant and every block parameter
fn = fieldnames(V);
for i = 1:numel(fn)
    assignin('base', fn{i}, V.(fn{i}));
end
end

% =========================================================================
function set_vars(law, tau, ov)
%SET_VARS  다음 `sim` 이 쓸 값을 작업공간에 놓는다 / the values the next sim uses
%
%   법칙은 모델 안에 있다. 여기서 하는 일은 `law` 와 `tau_cmd` (그리고 필요하면
%   가중값) 를 놓고, 지난 로그를 지우는 것뿐이다.
%   The law is in the model. All that happens here is that `law`, `tau_cmd` and
%   any overrides are placed on the workspace and the previous logs are cleared.
assignin('base', 'law',     law);
assignin('base', 'tau_cmd', tau(:));
if nargin > 2
    fn = fieldnames(ov);
    for i = 1:numel(fn)
        assignin('base', fn{i}, ov.(fn{i}));
    end
end
evalin('base', 'clear W07ca_log W07ca_act');
end

% =========================================================================
function R = read_logs(law)
%READ_LOGS  방금 돈 `sim` 의 로그 둘을 한 구조체로 / the two logs of the last sim
L = pull('W07ca_log', 10);
A = pull('W07ca_act', 24);
assert(~isempty(L) && ~isempty(A), 'W07:noLog', ...
       '로그가 비었다 / the model produced no log');

R.law    = law;
R.steps  = size(L, 1);
R.t      = L(:,1);
R.hist_d = L(:,2:4);
R.hist_a = L(:,5:7);
R.tau_d  = L(end, 2:4);
R.tau_a  = L(end, 5:7);
R.e      = R.tau_a - R.tau_d;

R.f     = A(end,  1:8 ).';
R.n_ask = A(end,  9:12).';
R.n_got = A(end, 13:16).';
R.d_ask = A(end, 17:20).';
R.d_got = A(end, 21:24).';

%  부호 있는 추력 — 배분기가 지시한 쪽 / the signed thrust the allocator asked for
sg = sign(R.f(1:2:7));
sg(sg == 0) = 1;
R.T = sg .* hypot(R.f(1:2:7), R.f(2:2:8));
end

% =========================================================================
function M = pull(nm, ncol)
%PULL  작업공간의 로그를 행렬로 / one log off the workspace, as a matrix
if evalin('base', sprintf('exist(''%s'', ''var'')', nm)) ~= 1
    M = [];  return
end
M = evalin('base', nm);
if ndims(M) == 3
    M = permute(M, [3 1 2]);
end
if isempty(M) || size(M, 2) < ncol
    M = [];
end
end

% =========================================================================
function unit_table(R, ttl)
%UNIT_TABLE  추진기 넷을 한 표로 / the four units, one row each
fprintf('  %s\n', ttl);
fprintf('      unit    T [N]   delta asked   delta allowed    n asked   n allowed\n');
for i = 1:4
    fprintf('   %7d %8.2f %13.2f %15.2f %10.2f %11.2f\n', i, R.T(i), ...
            rad2deg(R.d_ask(i)), rad2deg(R.d_got(i)), R.n_ask(i), R.n_got(i));
end
fprintf('      tau demanded  [%8.3f %8.3f %8.3f]\n', R.tau_d);
fprintf('      tau delivered [%8.3f %8.3f %8.3f]   error %.3f N\n', ...
        R.tau_a, norm(R.e));
end

% =========================================================================
function savepng(fig, p)
%SAVEPNG  그림 하나를 150 dpi 로 / one figure at 150 dpi
try
    exportgraphics(fig, p, 'Resolution', 150);
catch
    print(fig, p, '-dpng', '-r150');
end
fprintf('    saved %s\n', p);
end
