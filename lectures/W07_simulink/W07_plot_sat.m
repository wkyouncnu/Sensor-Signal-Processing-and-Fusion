function [f, R] = W07_plot_sat(A, t, ttl, pf)
%W07_PLOT_SAT  추진기 넷이 한계 안에 있었는가 — 네 칸으로 / did the four units
%              stay inside their limits, in four panels.
%
%   [f, R] = W07_plot_sat(A, t, ttl, pf)
%
%   왜 따로 둔 함수인가 / why this is its own function
%       닫힌 루프 두 모델이 **같은 질문**을 한다 — rpm·추력·틸팅각이 최대·최소
%       범위 안에 있었는가. 그림을 양쪽에 복사하면 한쪽만 고쳐진다 (§15-34).
%       Both closed-loop models ask the same question, so the figure lives here
%       once rather than being copied into two plot scripts.
%
%   입력 / inputs
%     A    배분기의 24 열 기록 / the allocator's record, n-by-24:
%            1-8  f = [fx1 fy1 … fx4 fy4]        배분기가 낸 힘 성분 [N]
%            9-12  n 명령 [rad/s]     13-16  n 깎인 뒤 [rad/s]
%           17-20  delta 명령 [rad]   21-24  delta 깎인 뒤 [rad]
%     t    같은 길이의 시각 [s] / the clock, same length
%     ttl  sgtitle 에 쓸 한 줄 / one line for the sgtitle
%     pf   PNG 경로. 비우면 저장하지 않는다 / the PNG path, '' to skip
%
%   출력 / outputs
%     f    그림 핸들 / the figure handle
%     R    최악값 한 벌 — 강의자료가 인용하는 수치가 여기서 나온다 / the worst
%          case of the run; every number the lecture quotes comes from here
%
%   한계를 어디서 읽는가 / where the limits come from
%       작업공간이다 — `n_max`·`n_min`·`alpha_lim`·`T_pos`·`T_neg`. 값을 이
%       파일에 적어 두면 `otter_config` 와 어긋날 수 있다. 없을 때의 기본값은
%       `quad_tilt` 형상의 값이다.
%       From the workspace, not from a copy kept here: a copy could drift from
%       otter_config. The defaults are the quad_tilt values.
%
%   왜 **부호 있는** 추력인가 / why the thrust is signed
%       한 추진기가 내는 힘은 `f = [fx fy]` 두 성분이고, 그 크기가 추력,
%       방향이 틸팅각이다. 그런데 추력 캡은 전진(`T_pos`) 과 후진(`T_neg`) 이
%       다르다 — 프로펠러가 뒤로 밀 때 더 약하다. 그래서 크기만 보면 안 되고
%       `sign(fx)·|f|` 로 **쪽까지** 본 뒤 그 쪽의 캡과 견준다 (§7-12).
%       One unit's force is two components whose magnitude is the thrust and
%       whose direction is the tilt angle. The cap differs ahead and astern, so
%       the magnitude alone is not enough: the side is taken from sign(fx) and
%       the signed thrust is compared against the cap on that side.
%
%   See also W07_PLOT_WPT, W07_PLOT_POSE, ADD_ALLOCATION_TILT4.

%  장부의 모양을 바로잡는다 / put the record into n-by-24 form
%       To Workspace 의 'Array' 는 **열벡터** 신호를 24-by-1-by-N 으로 적는다 —
%       Mux 가 받은 n·delta 가 4-by-1 행렬이기 때문이다. 누르지 않고 쓰면 열이
%       시각이 되어 숫자가 전부 말이 안 된다 (한 번 겪었다).
%       Array format writes a column-vector signal as 24-by-1-by-N, because what
%       the Mux receives are 4-by-1 matrices. Without the squeeze the columns
%       would be instants, and every number below would be nonsense.
A = squeeze(A);
if size(A, 1) == 24 && size(A, 2) ~= 24, A = A.'; end
assert(size(A, 2) == 24, 'W07:actCols', ...
       '배분기 장부가 24 열이 아니다 (%d) / the record is not 24 columns', size(A, 2));

m = min(numel(t), size(A, 1));
t = t(1:m);
A = A(1:m, :);

n_max = base_var('n_max',      103.931);
n_min = base_var('n_min',     -101.737);
a_lim = base_var('alpha_lim',   pi/4);
T_pos = base_var('T_pos',       119.682);
T_neg = base_var('T_neg',        66.708);

n_ask = A(:,  9:12);   n_got = A(:, 13:16);
d_ask = A(:, 17:20);   d_got = A(:, 21:24);

%  부호 있는 추력과 그 쪽의 캡 / the signed thrust and the cap on its side
T = zeros(m, 4);
for i = 1:4
    fx = A(:, 2*i-1);  fy = A(:, 2*i);
    sg = sign(fx);  sg(sg == 0) = 1;
    T(:,i) = sg .* hypot(fx, fy);
end
T_cap = (T >= 0)*T_pos + (T < 0)*T_neg;      % 그 표본이 견줄 캡 / the cap in force

%  이용률 — 한계의 몇 %. 100 을 넘은 적이 있으면 그 칸이 빨갛게 넘어간다
%  utilisation: what fraction of the limit was used, per quantity and sample
Un = 100 * max(n_got ./ ((n_got >= 0)*n_max + (n_got < 0)*abs(n_min)), [], 2);
Ut = 100 * max(abs(T) ./ T_cap, [], 2);
Ud = 100 * max(abs(d_got), [], 2) / a_lim;

R = struct();
R.n   = [min(n_got(:)),        max(n_got(:))];
R.T   = [min(T(:)),            max(T(:))];
R.d   = [min(rad2deg(d_got(:))), max(rad2deg(d_got(:)))];
R.use = [max(Un),  max(Ut),  max(Ud)];
%  한계에 **닿은** 표본과, 깎여서 **덜 나간** 표본은 다른 수다 / two counts:
%       닿았다 = 그 한계가 작동 중이었다. 깎였다 = 명령과 허용값이 달랐다.
%       법칙 4 는 벽을 풀이 안에 넣으므로, 벽에 붙어 있어도 깎이지는 않는다.
%       touched = the limit was active; clipped = asked and allowed differ.
%       Law 4 carries the walls inside the solve, so it can sit on a wall
%       without anything being clipped afterwards.
R.hit  = [sum(any(n_got >= n_max - 1e-6 | n_got <= n_min + 1e-6, 2)), ...
          sum(any(abs(T) >= T_cap - 1e-6, 2)), ...
          sum(any(abs(d_got) >= a_lim - 1e-9, 2))];
R.clip = [sum(any(abs(n_ask - n_got) > 1e-6, 2)), ...
          0, ...
          sum(any(abs(d_ask - d_got) > 1e-9, 2))];
R.lim = [n_min, n_max, -T_neg, T_pos, -rad2deg(a_lim), rad2deg(a_lim)];
R.steps = m;

%  표로 찍는다. 강의자료의 수치는 이 줄에서 나온다 / the lecture quotes these
fprintf('  %s\n', ttl);
fprintf('      what          worst value        limit            used   samples on it\n');
fprintf('   shaft speed  %7.2f .. %7.2f   %7.2f .. %7.2f %8.1f %%%12d\n', ...
        R.n, n_min, n_max, R.use(1), R.hit(1));
fprintf('   thrust       %7.2f .. %7.2f   %7.2f .. %7.2f %8.1f %%%12d\n', ...
        R.T, -T_neg, T_pos, R.use(2), R.hit(2));
fprintf('   tilt angle   %7.2f .. %7.2f   %7.2f .. %7.2f %8.1f %%%12d\n', ...
        R.d, -rad2deg(a_lim), rad2deg(a_lim), R.use(3), R.hit(3));
if all(R.hit == 0)
    fprintf('   no limit was reached: every sample has headroom on all three.\n');
else
    fprintf('   a limit was on at some samples, which is where the law earns its keep.\n');
end
if any(R.clip > 0)
    fprintf('   clipped after the solve: %d samples of n, %d of delta -- asked and\n', ...
            R.clip(1), R.clip(3));
    fprintf('   allowed differ there, so the hull got less than the allocator asked.\n');
else
    fprintf('   nothing was clipped after the solve: the law kept its own walls.\n');
end

%% ---- 네 칸 / the four panels -----------------------------------------
U = [0    0.45 0.74;        % 추진기 1 / unit 1
     0.85 0.33 0.10;        % 2
     0.47 0.67 0.19;        % 3
     0.49 0.18 0.56];       % 4
NM = {'unit 1','unit 2','unit 3','unit 4'};

f = lab_fig(['W07  ' ttl], 1180, 820);

%  (1) 축 회전수 / the shaft speeds
a = subplot(2,2,1, 'Parent', f);  hold(a,'on');  grid(a,'on');
for i = 1:4
    plot(a, t, n_got(:,i), '-', 'Color', U(i,:), 'LineWidth', 1.2, ...
         'DisplayName', NM{i});
end
yline(a, n_max, 'r--', 'n_{max}', 'FontSize', 8, 'HandleVisibility','off');
yline(a, n_min, 'r--', 'n_{min}', 'FontSize', 8, 'LabelHorizontalAlignment','left', 'HandleVisibility','off');
ylabel(a, 'n  [rad/s]');  xlabel(a, 'time [s]');
ylim(a, pad_to(n_got, [n_min n_max]));
%  범례는 축 **밖**에 둔다 — 안에 두면 한계선의 이름표(n_min·astern cap·-limit)
%  위에 앉는다 / the legend goes outside the axes: inside it sits on top of the
%  limit-line labels
legend(a, 'Location','southoutside', 'FontSize', 7, 'Orientation','horizontal', ...
       'Box','off', 'Color','none');
title(a, 'Shaft speed, against the rpm limits', 'FontSize', 9);

%  (2) 추력 / the thrust per unit
a = subplot(2,2,2, 'Parent', f);  hold(a,'on');  grid(a,'on');
for i = 1:4
    plot(a, t, T(:,i), '-', 'Color', U(i,:), 'LineWidth', 1.2, ...
         'DisplayName', NM{i});
end
yline(a,  T_pos, 'r--', 'ahead cap',  'FontSize', 8, 'HandleVisibility','off');
yline(a, -T_neg, 'r--', 'astern cap', 'FontSize', 8, 'LabelHorizontalAlignment','left', 'HandleVisibility','off');
yline(a, 0, 'k:', 'HandleVisibility','off');
ylabel(a, 'T  [N]');  xlabel(a, 'time [s]');
ylim(a, pad_to(T, [-T_neg T_pos]));
legend(a, 'Location','southoutside', 'FontSize', 7, 'Orientation','horizontal', ...
       'Box','off', 'Color','none');
title(a, 'Thrust per unit, against the two caps', 'FontSize', 9);

%  (3) 틸팅각 / the tilt angles
a = subplot(2,2,3, 'Parent', f);  hold(a,'on');  grid(a,'on');
for i = 1:4
    plot(a, t, rad2deg(d_got(:,i)), '-', 'Color', U(i,:), 'LineWidth', 1.2, ...
         'DisplayName', NM{i});
end
yline(a,  rad2deg(a_lim), 'r--', '+limit', 'FontSize', 8, 'HandleVisibility','off');
yline(a, -rad2deg(a_lim), 'r--', '-limit', 'FontSize', 8, 'LabelHorizontalAlignment','left', 'HandleVisibility','off');
yline(a, 0, 'k:', 'HandleVisibility','off');
ylabel(a, '\delta  [deg]');  xlabel(a, 'time [s]');
ylim(a, pad_to(rad2deg(d_got), rad2deg([-a_lim a_lim])));
legend(a, 'Location','southoutside', 'FontSize', 7, 'Orientation','horizontal', ...
       'Box','off', 'Color','none');
title(a, 'Tilt angle, against the servo limits', 'FontSize', 9);

%  (4) 이용률 셋을 한 축에 / the three utilisations on one axis
%      한계가 셋이면 단위도 셋이라 한 칸에 겹칠 수 없다. **한계의 몇 %** 로
%      바꾸면 셋이 같은 축에 오고, 100 선 하나가 판정선이 된다
%      three limits mean three units, which cannot share an axis; expressed as
%      a percentage of the limit they can, and one line at 100 is the verdict
a = subplot(2,2,4, 'Parent', f);  hold(a,'on');  grid(a,'on');
plot(a, t, Un, '-',  'Color', U(1,:), 'LineWidth', 1.3, 'DisplayName', 'shaft speed');
plot(a, t, Ut, '-',  'Color', U(2,:), 'LineWidth', 1.3, 'DisplayName', 'thrust');
plot(a, t, Ud, '-',  'Color', U(4,:), 'LineWidth', 1.3, 'DisplayName', 'tilt angle');
yline(a, 100, 'r--', 'the limit', 'FontSize', 8, 'HandleVisibility','off');
ylabel(a, 'worst unit, as % of its limit');  xlabel(a, 'time [s]');
ylim(a, [0 max(110, 1.1*max([Un; Ut; Ud]))]);
legend(a, 'Location','southoutside', 'FontSize', 7, 'Orientation','horizontal', ...
       'Box','off', 'Color','none');
title(a, sprintf('Headroom: worst %.0f %% of the rpm limit, %.0f %% of the cap, %.0f %% of the servo', ...
      R.use(1), R.use(2), R.use(3)), 'FontSize', 9);

sgtitle(f, ttl, 'FontSize', 11);

if ~isempty(pf)
    try
        exportgraphics(f, pf, 'Resolution', 150);
    catch
        print(f, pf, '-dpng', '-r150');
    end
    fprintf('    saved %s\n', pf);
end
end

% =========================================================================
function L = pad_to(D, lim)
%  한계선이 **늘 보이게** 축을 잡는다. 여유가 많은 운항에서 곡선에 맞춰 축을
%  좁히면 한계선이 그림 밖으로 나가고, 그러면 "안에 있었다" 가 그림에서 사라진다
%  the limit lines must always be visible: fitted to the curves alone they fall
%  off a run with plenty of headroom, and then the picture no longer shows that
%  the run stayed inside
D  = D(isfinite(D));
lo = min([D(:); lim(:)]);
hi = max([D(:); lim(:)]);
dd = max((hi - lo)*0.08, 1e-3);
L  = [lo - dd, hi + dd];
end
