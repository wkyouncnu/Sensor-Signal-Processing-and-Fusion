%% W01 · 절 E — 같은 명령, 세 가지 조류
%
%      W01_0_setup
%      W01_E_current_run
%
%  이 스크립트가 하는 일 — 세 단계
%    1. W01_current.slx 를 네 번 돌린다. 명령은 네 번 모두 같다:
%       두 프로펠러 모두 n0, 조향 없음. 바뀌는 것은 물뿐이다.
%         잔잔한 물 · 0.5 m/s 조류가 뒤에서 · 옆에서 · 앞에서
%    2. 각 실행의 대지속도 · 항적각 · 선수각을 표로 찍는다
%    3. 조류마다 한 칸씩, 세 칸을 한 줄에 그린다. 세 칸의 축은 똑같고,
%       잔잔한 물의 궤적을 회색으로 깔고, 조류의 방향과 크기를 화살표로 둔다
%
%  무엇을 보라는 것인가
%    명령은 한 번도 바뀌지 않았는데 궤적은 바뀐다. 차이는 전부 물이 만든 것이다.
%    뒤 · 앞 조류는 속도만 바꾸고, 옆 조류만 방향을 바꾼다 — 선수는 여전히 북쪽인데.
%
%  만드는 것 : img/W01_result_current.png
%
%  2026-09-11 — 네 궤적을 한 칸에 겹쳐 그리던 것을 세 칸으로 나눴다 (교수자 요청).
%  겹쳐 그리면 북쪽으로 가는 세 궤적이 한 선 위에 포개져서 구별되지 않았다.

clear V CASES R M i o y f k ax L0 tl allN allE pad bc Lc x0 y0 GREY COL
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_current.slx')), W01_E_build_current; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W01_vars('current');

%% ---- 1. 네 번 돌린다 — 명령은 같고 물만 다르다 --------------------------
%        이름                   조류 속도 [m/s]   물이 향하는 방향 beta_c [deg, 북에서 시계방향]
CASES = { 'still water',        0.0,               0
          'following current',  V.V_c,             0
          'beam current',       V.V_c,            90
          'head current',       V.V_c,           180 };

fprintf('\n  W01 section E — what an ocean current does to an open loop\n');
fprintf('\n  command: both propellers at n0 = %g rad/s, no steering, %g s\n', V.n0, V.T_final);
fprintf('  the command is the SAME in all four runs. Only the water changes.\n\n');
fprintf('    %-18s %14s %14s %14s\n', 'current', 'ground speed', 'track [deg]', 'heading [deg]');
fprintf('    %s\n', repmat('-', 1, 62));

R = cell(size(CASES,1),1);
M = zeros(size(CASES,1), 3);
for i = 1:size(CASES,1)
    o    = run_sim('W01_current', V, 'V_c', CASES{i,2}, 'beta_c', deg2rad(CASES{i,3}));
    y    = W01_read(o);
    R{i} = y;
    k    = y.t >= 0.8*V.T_final;                     % 마지막 5분의 1 — 과도응답이 끝난 뒤
    M(i,:) = [ hypot(mean(diff(y.N(k))), mean(diff(y.E(k))))/V.h, ...   % 대지속도
               atan2d(y.E(end) - y.E(1), y.N(end) - y.N(1)), ...         % 항적각
               mean(y.psi(k)) ];                                         % 선수각
    fprintf('    %-18s %14.4f %14.2f %14.2f\n', CASES{i,1}, M(i,:));
end

fprintf(['\n    Same shaft speed, same thrust, no steering — and four different\n' ...
         '    answers. A following current adds %.2f m/s over the ground and a\n' ...
         '    head current takes the same amount away. The beam current carries\n' ...
         '    the vessel %.1f deg off its own heading with no sideways force.\n'], ...
        V.V_c, M(3,2) - M(3,3));

%% ---- 2. 세 칸에 공통인 축 --------------------------------------------------
%  세 칸의 축을 똑같이 둬야 "얼마나 멀리 갔는가" 와 "얼마나 옆으로 밀렸는가" 를
%  칸끼리 눈으로 비교할 수 있다. 네 궤적 전부를 담는 상자를 한 번 구한다.
%  왼쪽에 25 m 를 더 두는 것은 조류 화살표를 궤적과 겹치지 않게 놓을 자리다.
allN = cellfun(@(y) y.N, R, 'UniformOutput', false);  allN = vertcat(allN{:});
allE = cellfun(@(y) y.E, R, 'UniformOutput', false);  allE = vertcat(allE{:});
pad  = 12;
L0   = [min(allE)-pad-25, max(allE)+pad, min(allN)-pad, max(allN)+pad];

%% ---- 3. 세 칸 — 조류 하나에 한 칸 ----------------------------------------
GREY = [0.55 0.55 0.55];
COL  = [0 0.45 0.74; 0.85 0.33 0.10; 0.49 0.18 0.56];     % 뒤 · 옆 · 앞
f  = lab_fig('W01 E  three currents', 1180, 560);
tl = tiledlayout(f, 1, 3, 'TileSpacing','compact', 'Padding','compact');

for i = 2:4
    ax = nexttile(tl);  hold(ax,'on');  grid(ax,'on');  axis(ax,'equal');  axis(ax, L0);

    %  회색 : 같은 명령, 잔잔한 물. 비교의 기준선이다.
    plot(ax, R{1}.E, R{1}.N, '-', 'Color', GREY, 'LineWidth', 1.4);
    %  색 : 같은 명령, 이 칸의 조류.
    plot(ax, R{i}.E, R{i}.N, '-', 'Color', COL(i-1,:), 'LineWidth', 2.0);
    axes(ax);                                              %#ok<LAXES> track_ships 는 gca 에 그린다
    track_ships({[R{1}.N R{1}.E R{1}.psi], [R{i}.N R{i}.E R{i}.psi]}, ...
                [GREY; COL(i-1,:)], 'Marks', 5);

    %  조류 화살표. beta_c 는 물이 "향하는" 방향이고 북에서 시계방향이다.
    %  그리는 좌표는 (East, North) 이므로 성분은 (sin, cos) 이다.
    %  길이는 1 m/s 에 50 m — 세 칸이 같은 축척이라 크기도 비교된다.
    bc = deg2rad(CASES{i,3});   Lc = 50*CASES{i,2};
    x0 = L0(1) + 16;            y0 = L0(4) - 30;
    quiver(ax, x0 - 0.5*Lc*sin(bc), y0 - 0.5*Lc*cos(bc), Lc*sin(bc), Lc*cos(bc), 0, ...
           'Color',[0.10 0.55 0.75], 'LineWidth', 2.6, 'MaxHeadSize', 0.9);
    %  글자는 왼쪽 정렬로 축 안쪽에서 시작한다. 가운데 정렬이면 축 밖으로 나간다.
    text(ax, L0(1) + 3, y0 - 0.5*Lc - 9, sprintf('current %.1f m/s', CASES{i,2}), ...
         'HorizontalAlignment','left', 'Color',[0.10 0.55 0.75], 'FontSize', 9);

    xlabel(ax, 'East  [m]');
    if i == 2, ylabel(ax, 'North  [m]'); end
    Mi = M(i,:);  Mi(abs(Mi) < 0.05) = 0;                  % 제목에 -0.0 이 찍히지 않게
    title(ax, {sprintf('%s,  \\beta_c = %d°', CASES{i,1}, CASES{i,3}), ...
               sprintf('ground speed %.2f m/s,  track %.1f°,  heading %.1f°', Mi)}, ...
          'FontWeight','normal', 'FontSize', 10);
end
title(tl, {'the same command in every panel — both propellers at 60 rad/s, no steering', ...
           'grey: still water   ·   colour: with the current   ·   arrow: where the water goes'}, ...
      'FontSize', 11);

exportgraphics(f, fullfile(here,'img','W01_result_current.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W01_result_current.png\n\n');
