function h = lab_fig(name, w, hgt)
%LAB_FIG  이 강의의 공통 서식을 가진 그림 창 하나를 연다.
%         One figure, in the course's house style.
%
%   lab_fig('W02 C  open loop')          900 x 380, 기본 크기 / the default
%   lab_fig('W04 G  current', 1250, 470)
%
%   모든 절 스크립트가 이것을 거쳐 그린다. 크기도, 격자도, 선 굵기도 같아지므로
%   학생이 직접 돌려 얻은 그림과 강의노트에 실린 그림이 같은 강의의 것으로 보인다.
%   서식이 제각각이면 읽는 사람은 매번 그림을 다시 해석해야 하고, 그 노력은
%   내용과 아무 상관이 없다.
%
%   Every section script draws through this, so the size, the grid and the line
%   weight are the same everywhere and a figure a student produces looks like
%   the one printed in the notes. Where the styling varies, a reader has to
%   reinterpret each figure, and that effort has nothing to do with the
%   content.

if nargin < 2 || isempty(w),   w   = 900; end
if nargin < 3 || isempty(hgt), hgt = 380; end

h = figure('Name', name, 'NumberTitle', 'off', 'Position', [60 60 w hgt], ...
           'Color', 'w');
set(h, 'DefaultAxesFontSize', 10, ...
       'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on', ...
       'DefaultAxesBox', 'on', ...
       'DefaultLineLineWidth', 2);
end
