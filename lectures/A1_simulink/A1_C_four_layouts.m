%% A1 · 절 C — 열 규칙을 네 가지 추진기 배치에 적용한다
%  A1 · Section C — the column rule applied to four thruster layouts
%
%  실행 순서 / order of execution
%      A1_0_setup
%      A1_C_four_layouts
%
%  이 절의 요점 / the point of this section
%      배분 행렬 B 를 배치마다 새로 외우지 않는다. 규칙은 하나뿐이다 — 추진기
%      하나가 B 의 열 하나이고, 그 열은 그 추진기가 단위 추력을 냈을 때 생기는
%      일반화 힘이다. 배치가 달라지면 열이 달라질 뿐 규칙은 그대로이다.
%      그리고 그 B 의 계수(rank)가 그 배치로 독립적으로 지시할 수 있는 축의
%      개수를 정한다.
%
%      The allocation matrix B is not memorised layout by layout. There is one
%      rule: each thruster is one column of B, and that column is the
%      generalised force produced when that thruster delivers unit thrust. A
%      different layout gives different columns and leaves the rule untouched.
%      The rank of B then fixes how many axes that layout can command
%      independently.
%
%  시뮬레이션을 하지 않는다 / no simulation here
%      계수와 도달 가능한 축의 개수는 행렬의 성질이므로 배를 띄우지 않고도
%      결정된다. 표만 출력하며, 이 부록의 그림은 절 D 가 만든다.
%      Rank and the number of reachable axes are properties of a matrix and
%      are settled without putting a vessel in the water. Tables only are
%      printed; the figure for this appendix is produced by section D.

clear NAMES i c cfg Bp
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();

cfg = otter_config('base');

%% ---- the rule, applied ------------------------------------------------
%  A thruster at (x, y) pointing along the unit vector e contributes the column
%      [ e_x ; e_y ; x e_y - y e_x ]
%  and a TILTING thruster contributes two, one per Cartesian component.
NAMES = {'base','aft_azimuth','bow_thruster','quad_tilt'};

fprintf('\n  A1 section C — the column rule applied to four layouts\n\n');
fprintf('    %-14s %8s %8s %8s %8s %16s\n', ...
        'configuration', 'thrust', 'cols', 'rank', 'null', 'max |B(2,:)|');
fprintf('    %s\n', repmat('-', 1, 70));
for i = 1:numel(NAMES)
    c = otter_config(NAMES{i});
    fprintf('    %-14s %8d %8d %8d %8d %16.3f\n', NAMES{i}, c.n_thr, c.n_cols, ...
            rank(c.B), c.n_cols - rank(c.B), max(abs(c.B(2,:))));
end

fprintf(['\n    Only the base layout has an empty sway row, and only the base\n' ...
         '    layout has rank 2. The two statements are the same statement.\n' ...
         '    A tilting thruster contributes TWO columns, one per Cartesian\n' ...
         '    component of its thrust, which is why aft_azimuth reaches rank 3\n' ...
         '    with the same two physical machines.\n']);

fprintf('\n    B(base) =\n');
fprintf('      %8.4f %8.4f\n', cfg.B');

%% ---- what a pseudo-inverse cannot do -----------------------------------
Bp = pinv(cfg.B);
fprintf('\n    A pseudo-inverse exists but cannot invent the missing row:\n');
fprintf('      pinv(B) * [0 1 0]'' = [%.3e ; %.3e]   -> no thrust asked for\n', Bp*[0;1;0]);
fprintf('      B * that            = [%.3e ; %.3e ; %.3e]\n', cfg.B*(Bp*[0;1;0]));
fprintf(['\n    Asking for a pure sway force returns the zero command, and the\n' ...
         '    zero command returns zero force. The least-squares solution is\n' ...
         '    correct and useless: it is the honest answer to an impossible\n' ...
         '    request. No allocation scheme can do better, because the\n' ...
         '    limitation is in the geometry and not in the arithmetic.\n\n']);
