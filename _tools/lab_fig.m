function h = lab_fig(name, w, hgt)
%LAB_FIG  One figure, in the course's house style.
%
%   lab_fig('W08 speed lab')            900 x 380, the default
%   lab_fig('W10 two hulls', 1000, 420)
%
%   Every lab runner draws through this so the figures a student gets from
%   run_W08 look like the ones in W08_TheSpeedLoop.mlx. Same size, same
%   grid, same line weight — the point is that the model and the Live
%   Script should not look like two different courses.

if nargin < 2 || isempty(w),   w   = 900; end
if nargin < 3 || isempty(hgt), hgt = 380; end

h = figure('Name', name, 'NumberTitle', 'off', 'Position', [60 60 w hgt], ...
           'Color', 'w');
set(h, 'DefaultAxesFontSize', 10, ...
       'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on', ...
       'DefaultAxesBox', 'on', ...
       'DefaultLineLineWidth', 2);
end
