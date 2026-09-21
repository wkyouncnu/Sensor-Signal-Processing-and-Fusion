%% W04 · 절 G — +-180 도의 감김 / Section G — the wrap at +-180 deg
%
%  이 절이 묻는 것 / the question
%      170 도에서 -170 도로 가라고 하면 배는 20 도를 도는가, 340 도를 도는가?
%      Commanded from 170 deg to -170 deg, does the vessel turn 20 deg or 340 deg?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W04_G_wrap 에 5 s 에 170 도, 20 s 에 -170 도를 명령한다 (60 s).
%      ② use_ssa = 1 (오차를 감는다) 과 0 (감지 않는다) 으로 한 번씩 돌린다.
%      ③ 20 s 의 선수각, 60 s 의 선수각, 20 s 뒤에 돈 각을 찍고 그림으로 저장한다.
%         선수각은 감지 않은 값이라 어느 쪽으로 몇 도 돌았는지가 그대로 보인다.
%      ① Commands 170 deg at 5 s and -170 deg at 20 s to W04_G_wrap, for 60 s.
%      ② Runs with use_ssa = 1 (the error wrapped) and 0 (not wrapped).
%      ③ Prints the heading at 20 s and at 60 s and the turn after 20 s, and
%         plots it. The heading is not wrapped, so the direction and size of
%         the turn show directly.
%
%  출력에서 볼 것 / what to look for in the output
%      - use_ssa = 1: 20 도 돌아 190 도 (= -170 도) 에 선다.
%      - use_ssa = 0: 반대 방향으로 340 도를 돈다. 같은 명령에 17 배의 선회.
%      - use_ssa = 1: a 20 deg turn, ending at 190 deg (= -170 deg).
%      - use_ssa = 0: 340 deg the other way; seventeen times the turn for the same command.
%
%  만드는 것 / produces: img/W04_result_wrap.png

%% 0) 경로와 시나리오 / paths and the scenario
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
%  170 도, 그리고 20 s 에 -170 도, 60 s 동안 / 170 deg, then -170 deg at 20 s, for 60 s
S = {'psi_step', 170, 'psi_step2', -170, 't_step2', 20, 'T_final', 60};

%% 1) 표의 제목줄과 그림 / the table header and the figure
fprintf('\n  W04 G  170 deg, then -170 deg at t = 20 s\n');
fprintf('    use_ssa   heading at 20 s [deg]   heading at 60 s [deg]   turned after 20 s [deg]\n');
f = lab_fig('W04 G  wrap', 1000, 460);  hold on; grid on;

%% 2) 감을 때와 감지 않을 때 / with and without the wrap
for us = [1 0]
    R = W04_read('W04_G_wrap', S{:}, 'use_ssa', us);
    p20 = interp1(R.t, R.psi, 20);                  % 명령이 바뀌는 순간의 선수각 / heading when the command changes
    fprintf('    %-7g   %21.1f   %21.1f   %23.1f\n', us, p20, R.psi(end), abs(R.psi(end) - p20));
    plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('use\\_ssa = %g', us));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command');
yline([180 -180], ':', 'HandleVisibility','off');
ylabel('\psi, not wrapped [deg]'); xlabel('time [s]'); legend('Location','southwest');
title('-170 deg is 20 deg past 170 deg: ssa turns 20 deg, the raw error turns 340 deg the other way');
exportgraphics(f, fullfile(here, 'img', 'W04_result_wrap.png'), 'Resolution', 150);
