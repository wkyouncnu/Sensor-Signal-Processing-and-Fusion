%W07_SECTOR_CHORDS_GEOM  figures/src/w07-sector-chords.tex 의 좌표를 계산한다.
%                        Computes the coordinates of figures/src/w07-sector-chords.tex.
%
%  `CLAUDE.md` §4-6-1 — 그림의 기하는 눈대중하지 않고 계산한다. 이 스크립트가
%  그 계산이고, 찍은 값을 `.tex` 에 그대로 옮긴다.
%  CLAUDE.md 4-6-1: a figure's geometry is computed, never eyeballed. This
%  script is that computation, and its printed numbers go into the .tex as they
%  are.
%
%  부채꼴은 `W07_alloc` 의 `cone_cap` 과 **같은 식**이다 / the sector is the one
%  cone_cap builds:
%      cos(th_j) x' + sin(th_j) y' <= R cos(alpha_max/M),
%      th_j = -alpha_max + (j - 0.5)*(2 alpha_max / M)

amax = deg2rad(45);        % 서보 벽 / the servo wall
M    = 3;                  % 현의 개수 / number of chords
R    = 2.30;               % 그림에서의 반지름 [cm] / drawing radius [cm]

fprintf('\nalpha_max = %.0f deg,  M = %d,  R(drawing) = %.2f cm\n\n', ...
        rad2deg(amax), M, R);

%% 현의 법선 각과 우변 / the chord normals and the right-hand side -----------
th = -amax + ((1:M) - 0.5)*(2*amax/M);
rhs = R*cos(amax/M);
fprintf('  chord normals  th_j = [%s] deg\n', ...
         strjoin(compose('%+.0f', rad2deg(th)), ' '));
fprintf('  right side     R cos(alpha_max/M) = R cos%.0f = %.5f cm  (%.4f R)\n\n', ...
         rad2deg(amax/M), rhs, rhs/R);

%% 다각형의 꼭짓점 / the polygon vertices ------------------------------------
%  이웃한 현 둘은 반지름 R 의 원 **위**에서 만난다 — 중점만 0.966 R 이다.
%  neighbouring chords meet ON the circle of radius R; only the midpoints are
%  at 0.966 R.
av = -amax + (0:M)*(2*amax/M);
fprintf('  vertices (all at radius R, so they touch the circle)\n');
for k = 1:numel(av)
    fprintf('    %+3.0f deg : (%+.5f, %+.5f)\n', ...
            rad2deg(av(k)), R*cos(av(k)), R*sin(av(k)));
end

%% 현의 중점 / the chord midpoints -------------------------------------------
fprintf('\n  chord midpoints (at %.4f R — the worst place)\n', cos(amax/M));
for j = 1:M
    fprintf('    %+3.0f deg : (%+.5f, %+.5f)\n', ...
            rad2deg(th(j)), rhs*cos(th(j)), rhs*sin(th(j)));
end
fprintf('\n  conservatism at mid-chord : 1 - cos%.0f = %.2f %%\n', ...
        rad2deg(amax/M), 100*(1 - cos(amax/M)));

%% 확대경 / the magnified detail callout -------------------------------------
%  현과 원호 사이의 틈은 R 의 3.4 % — 본문 폭에서 2 px 라 **보이지 않는다.**
%  보이지 않는 것을 숫자로만 주장하지 않는다 (`CLAUDE.md` §4-6): -30도 현의
%  중점을 확대해서 그 틈을 그린다.
%  The gap between chord and arc is 3.4 % of R, which is 2 px at body width --
%  invisible. A figure does not assert in numbers what it cannot show, so the
%  midpoint of the -30 deg chord is magnified.
gap  = R - rhs;              % 반지름 방향의 틈 / the radial gap
rsrc = (R + rhs)/2;          % 확대할 원의 중심 / centre of the source circle
mag  = 8;                    % 배율 / magnification
rlen = 0.62;                 % 확대경의 반지름 [cm] / lens radius [cm]
fprintf('  magnified detail callout\n');
fprintf('    radial gap R - R cos15 = %.5f cm  (%.4f R)\n', gap, gap/R);
fprintf('    source circle : centre at (%+.0f deg, %.5f),  radius %.5f cm\n', ...
        rad2deg(th(1)), rsrc, rlen/mag);
fprintf('    at x%d the gap draws as %.3f cm inside a lens of radius %.2f cm\n\n', ...
        mag, mag*gap, rlen);

%% 두 캡의 높이 / the two cap heights ----------------------------------------
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'_tools'));
cfg = otter_config('quad_tilt');
fprintf('\n  T_pos = k_pos n_max^2 = %.3f N   (ahead)\n',  cfg.k_pos*cfg.n_max^2);
fprintf('  T_neg = k_neg n_min^2 = %.3f N   (astern, %.0f %% of ahead)\n\n', ...
        cfg.k_neg*cfg.n_min^2, ...
        100*(cfg.k_neg*cfg.n_min^2)/(cfg.k_pos*cfg.n_max^2));
