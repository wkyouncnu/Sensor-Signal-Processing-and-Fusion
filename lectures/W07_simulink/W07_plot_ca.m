%W07_PLOT_CA  배분 사슬의 진단 그림 여섯 칸 — **고른 법칙이 제대로 돌았는가.**
%             Six panels that answer one question: did the law that was
%             selected actually work?
%
%   `W07_alloc_chain` 의 StopFcn 이 부른다. Run 을 누르면 그림이 뜬다.
%   Called from the StopFcn of W07_alloc_chain, so Run alone draws the figure.
%
%   여섯 칸이 무엇을 말하는가 / what the six panels say
%       1  요구한 tau 와 배가 실제로 받은 tau            맞혔는가
%          the demanded tau against the tau the hull received -- was it met
%       2  그 둘의 시간 이력                              언제부터 맞았는가
%          the same two over time -- when it settled
%       3  축회전수: 배분기가 지시한 값과 깎인 값          rpm 한계 안인가
%          shaft speed asked and allowed -- inside the rpm limits
%       4  서보 각: 지시한 값과 깎인 값                   각 한계 안인가
%          servo angle asked and allowed -- inside the angle limit
%       5  추진기별 추력과 전·후진 추력 캡                 추력 한계 안인가
%          thrust per unit against the two caps
%       6  위에서 본 추력 넷과 요구한 힘의 방향            방향이 맞는가
%          the four thrust vectors from above, with the demanded direction
%
%   로그 둘 / the two logs
%       W07ca_log  열이 열 / ten columns
%           1      t          [s]
%           2:4    tau_d      요구한 [X Y N]      / the demand
%           5:7    tau_act    실제로 나온 [X Y N] / what the hull received
%           8:10   u v r      선체 속도            / the hull velocities
%       W07ca_act  열이 스물넷 / twenty-four columns
%           1:8    f          배분기가 낸 여덟 성분 / the eight components
%           9:12   n 지시     [rad/s]  깎기 전 / asked, before the limit
%          13:16   n 허락     [rad/s]  깎은 뒤 / allowed, after it
%          17:20   delta 지시 [rad]
%          21:24   delta 허락 [rad]
%
%   조용히 돌리기 / running it quietly
%       작업공간에 `W07quiet = true` 가 있으면 그림도 표도 내지 않는다.
%       `W07_alloc_run` 이 여러 경우를 돌리며 **스스로** 그릴 때 쓴다.
%       With W07quiet = true on the workspace this file draws and prints
%       nothing: W07_alloc_run uses that while it sweeps and plots its own.
%
%   See also W07_2_BUILD_ALLOC, W07_ALLOC_RUN, QUAD_THRUST_PLAN, W07_0_SETUP.

if base_has('W07quiet') && evalin('base', 'logical(W07quiet)')
    return
end
if ~base_has('W07ca_log') || ~base_has('W07ca_act')
    return
end

L = squeeze_log(evalin('base', 'W07ca_log'), 10);
A = squeeze_log(evalin('base', 'W07ca_act'), 24);
if isempty(L) || isempty(A)
    return
end

% 배분은 대수식이므로 **마지막 표본 하나**가 그 법칙의 답이다. 시간 이력은
% 둘째 칸이 맡는다 / allocation is algebraic, so the last sample IS the answer
% of that law; panel 2 carries the history
t     = L(:,1);
tau_d = L(:,2:4);
tau_a = L(:,5:7);
e     = tau_a(end,:) - tau_d(end,:);

f     = A(end,  1:8).';
n_ask = A(end,  9:12).';
n_got = A(end, 13:16).';
d_ask = A(end, 17:20).';
d_got = A(end, 21:24).';

% 한계와 배치는 작업공간에서 읽는다 — 모델의 Saturation 블록이 읽는 그 이름들
% the limits come off the workspace: the very names the Saturation blocks read
n_max = base_num('n_max',      103.93);
n_min = base_num('n_min',     -101.74);
a_lim = base_num('alpha_lim',  pi/4);
T_pos = base_num('T_pos',      119.682);
T_neg = base_num('T_neg',       66.708);
if base_has('quad')
    q = evalin('base', 'quad');
else
    c = otter_config('quad_tilt');
    q = [c.pos ; c.alpha_max ; c.mount];
end

% 추력과 그 부호 / the thrust of each unit and its sign
sg = sign(f(1:2:7));  sg(sg == 0) = 1;
T  = sg .* hypot(f(1:2:7), f(2:2:8));
T_cap = (T >= 0)*T_pos - (T < 0)*T_neg;      % 그 부호에서의 캡 / the cap in force

hit_n = abs(n_ask - n_got) > 1e-6;
hit_d = abs(d_ask - d_got) > 1e-6;
hit_T = abs(T) > abs(T_cap) + 1e-6;

law_name = {'minimum norm', 'weighted minimum norm', ...
            'weighted, folded onto the servo limit', ...
            'servo limit and thrust cap as constraints'};
k = max(1, min(4, round(base_num('law', 1))));

% ------------------------------------------------------------------ figure
% 창을 하나만 쓴다 — 법칙 넷을 잇달아 돌려도 창이 쌓이지 않는다
% one window, reused: running four laws in a row does not stack four windows
fg = findall(0, 'Type', 'figure', 'Tag', 'W07ca');
if isempty(fg)
    fg = figure('Tag', 'W07ca', 'Color', 'w', 'Position', [60 40 1060 760]);
else
    fg = fg(1);  clf(fg);  figure(fg);
end
set(fg, 'Name', sprintf('W07  allocation chain  --  law %d', k));

cmp = {'X  [N]', 'Y  [N]', 'N  [N m]'};

% (1) 맞혔는가 / was the demand met
subplot(3,2,1);
bar([tau_d(end,:) ; tau_a(end,:)].'); grid on
set(gca, 'XTickLabel', {'X', 'Y', 'N'});
ylabel('force / moment');
legend({'demanded', 'delivered'}, 'Location', 'best', 'FontSize', 8);
title(sprintf('Demand met to %.3f N  (law %d)', norm(e), k), 'FontSize', 9);
for i = 1:3
    text(i, max(tau_d(end,i), tau_a(end,i)), sprintf(' %+.2f', e(i)), ...
         'FontSize', 8, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'bottom');
end

% (2) 시간 이력 / the history
subplot(3,2,2); hold on; grid on
cl = lines(3);
for i = 1:3
    plot(t, tau_d(:,i), '--', 'Color', cl(i,:), 'LineWidth', 1.2);
    plot(t, tau_a(:,i), '-',  'Color', cl(i,:), 'LineWidth', 1.6);
end
xlabel('t  [s]');  ylabel('tau');
title('Dashed: demanded.  Solid: delivered', 'FontSize', 9);
legend({'X dem', 'X del', 'Y dem', 'Y del', 'N dem', 'N del'}, ...
       'Location', 'eastoutside', 'FontSize', 7);

% (3) 축회전수 / the shaft speeds
subplot(3,2,3);
bar([n_ask n_got]); grid on; hold on
yline(n_max, 'r--', 'n_{max}', 'LineWidth', 1.2, 'FontSize', 8);
yline(n_min, 'r--', 'n_{min}', 'LineWidth', 1.2, 'FontSize', 8);
set(gca, 'XTickLabel', {'1', '2', '3', '4'});
xlabel('unit');  ylabel('n  [rad/s]');
legend({'asked', 'allowed'}, 'Location', 'best', 'FontSize', 8);
title(sprintf('Shaft speed  --  %d of 4 units clipped', sum(hit_n)), 'FontSize', 9);

% (4) 서보 각 / the servo angles
subplot(3,2,4);
bar(rad2deg([d_ask d_got])); grid on; hold on
yline( rad2deg(a_lim), 'r--', '+limit', 'LineWidth', 1.2, 'FontSize', 8);
yline(-rad2deg(a_lim), 'r--', '-limit', 'LineWidth', 1.2, 'FontSize', 8);
set(gca, 'XTickLabel', {'1', '2', '3', '4'});
xlabel('unit');  ylabel('delta  [deg]');
legend({'asked', 'allowed'}, 'Location', 'best', 'FontSize', 8);
title(sprintf('Servo angle  --  %d of 4 units clipped', sum(hit_d)), 'FontSize', 9);

% (5) 추력과 캡 / the thrust against its cap
subplot(3,2,5);
bar(T); grid on; hold on
yline( T_pos, 'r--', 'ahead cap',  'LineWidth', 1.2, 'FontSize', 8);
yline(-T_neg, 'r--', 'astern cap', 'LineWidth', 1.2, 'FontSize', 8);
set(gca, 'XTickLabel', {'1', '2', '3', '4'});
xlabel('unit');  ylabel('T  [N]');
title(sprintf('Thrust asked  --  %d of 4 units past the cap', sum(hit_T)), ...
      'FontSize', 9);

% (6) 위에서 본 추력 넷 / the four thrusts, from above
subplot(3,2,6);
quad_thrust_plan(q, T, d_got, tau_d(end,1:2), ...
                 'Red: thrust allowed.  Blue: demanded X and Y');

sgtitle(sprintf('law %d  --  %s', k, law_name{k}), 'FontSize', 11);

% ------------------------------------------------------------------- table
fprintf('\n  law %d   %s\n', k, law_name{k});
fprintf('  ----------------------------------------------------------------------------\n');
fprintf('  unit     T [N]   cap [N]    n asked   n allowed    d asked  d allowed   limit\n');
for i = 1:4
    tag = '-';
    if hit_n(i) && hit_d(i)
        tag = 'rpm+servo';
    elseif hit_n(i)
        tag = 'rpm';
    elseif hit_d(i)
        tag = 'servo';
    end
    fprintf('   %d    %8.2f %9.2f %10.2f %11.2f %10.2f %10.2f   %s\n', i, ...
            T(i), T_cap(i), n_ask(i), n_got(i), ...
            rad2deg(d_ask(i)), rad2deg(d_got(i)), tag);
end
fprintf('  ----------------------------------------------------------------------------\n');
fprintf('  tau demanded  [%8.3f %8.3f %8.3f]\n', tau_d(end,:));
fprintf('  tau delivered [%8.3f %8.3f %8.3f]   error %.3f N\n', ...
        tau_a(end,:), norm(e));
if sum(hit_n) + sum(hit_d) == 0
    fprintf('  no limit was reached, so the law delivered what it solved for\n');
else
    fprintf('  %d clip(s) stand between what was solved for and what the hull got\n', ...
            sum(hit_n) + sum(hit_d));
end
fprintf('\n');

% ------------------------------------------------------------------- save
here = fileparts(mfilename('fullpath'));
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end
pf = fullfile(here, 'img', sprintf('W07_alloc_chain_law%d.png', k));
try
    exportgraphics(fg, pf, 'Resolution', 150);
catch
    print(fg, pf, '-dpng', '-r150');
end
fprintf('    saved %s\n\n', pf);


% =========================================================================
function tf = base_has(nm)
%BASE_HAS  작업공간에 그 이름이 있는가 / is that name on the base workspace
tf = evalin('base', sprintf('exist(''%s'', ''var'')', nm)) == 1;
end

% =========================================================================
function v = base_num(nm, dflt)
%BASE_NUM  작업공간의 수 하나, 없으면 기본값 / one number, or a default
if base_has(nm)
    v = evalin('base', nm);
else
    v = dflt;
end
end

% =========================================================================
function M = squeeze_log(M, ncol)
%SQUEEZE_LOG  To Workspace 의 Array 는 행렬 신호를 n x 1 x N 으로 둔다.
%             열이 ncol 인 보통 행렬로 돌려 놓는다.
%             To Workspace puts a matrix signal as n x 1 x N; put it back as
%             N rows of ncol columns.
if ndims(M) == 3
    M = permute(M, [3 1 2]);
end
if isempty(M) || size(M, 2) < ncol
    M = [];
end
end
