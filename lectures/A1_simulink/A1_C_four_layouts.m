%% A1 · section C — the column rule applied to four layouts
%
%      A1_0_setup
%      A1_C_four_layouts
%
%  No simulation. One rule, four thruster layouts, and the rank that follows.
%  Prints tables only; the figure for this appendix is section D's.

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
