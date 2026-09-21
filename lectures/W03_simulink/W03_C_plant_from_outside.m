%% W03 · 절 C — 플랜트를 밖에서 본다 / Section C — the plant seen from outside
%
%  이 절이 묻는 것 / the question
%      제어기를 달기 전에, 이 배는 힘을 받으면 어떻게 움직이는가? 식을 쓰지 않고
%      계단 입력 하나로 알아낸다.
%      Before any controller: how does this vessel move when it is pushed?
%      Found with one step input, without writing an equation.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W03_C_open_loop 에 전진력 50, 100, 200 N 을 t = 5 s 에 계단으로 준다.
%      ② 각 경우의 최종 속도, 뉴턴당 속도, 최종 속도의 63 % 에 닿는 시각을 잰다.
%      ③ 세 속도 곡선을 한 그림에 그려 저장한다.
%      ① Applies 50, 100 and 200 N of surge force to W03_C_open_loop at t = 5 s.
%      ② Measures the final speed, the speed per newton, and the time to reach
%         63 % of the final speed.
%      ③ Draws the three speed curves in one figure and saves it.
%
%  출력에서 볼 것 / what to look for in the output
%      - 뉴턴당 속도가 세 경우 모두 같다 (0.01289): 속도는 힘에 비례한다.
%      - 63 % 시각도 모두 같다 (1.12 s): 이것이 이 배의 시정수다.
%      - 곡선에 오버슛이 없다: 1차 시스템이다.
%      - The speed per newton is the same in all three runs (0.01289): the speed
%        is proportional to the force.
%      - The 63 % time is the same too (1.12 s): the time constant of the vessel.
%      - No curve overshoots: a first-order system.
%
%  만드는 것 / produces: img/W03_result_open_loop.png

%% 0) 경로 / paths
%  이 파일이 있는 폴더(here)와 강의 공용 도구(_tools)를 MATLAB 경로에 올린다.
%  Put this folder (here) and the course tools (_tools) on the MATLAB path.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 표의 제목줄 / the header of the table
fprintf('\n  W03 C  the plant seen from outside (no controller)\n');
fprintf('    X [N]   final u [m/s]   u per newton [(m/s)/N]   time to 63 %% [s]\n');
f = lab_fig('W03 C  open loop', 1000, 480);  hold on; grid on;

%% 2) 세 가지 힘으로 한 번씩 돌린다 / one run for each of three forces
for X = [50 100 200]
    %  W03_read: 모델을 강의 기본값으로 돌리되 X_open 만 바꾸고, 기록된 신호를
    %  R.t (시간), R.u (속도), R.X (힘) 이름으로 돌려준다.
    %  W03_read runs the model with the lecture defaults, X_open changed, and
    %  returns the logged signals by name: R.t (time), R.u (speed), R.X (force).
    R = W03_read('W03_C_open_loop', 'X_open', X);

    %  계단이 들어간 t = 5 s 부터만 본다. t 는 계단 뒤의 시간이다.
    %  Look only from the step at t = 5 s on; t is the time after the step.
    k = R.t >= 5;  t = R.t(k) - 5;  u = R.u(k);

    %  최종 속도의 63.2 % 에 처음 닿는 시각 = 1차 시스템의 시정수.
    %  The first time the speed reaches 63.2 % of its final value = the time
    %  constant of a first-order system.
    t63 = t(find(u >= 0.632*u(end), 1));

    %  한 줄 출력: 힘, 최종 속도, 뉴턴당 속도, 63 % 시각.
    %  One line: force, final speed, speed per newton, 63 % time.
    fprintf('    %-5g   %13.3f   %22.5f   %16.2f\n', X, u(end), u(end)/X, t63);

    %  그림에 이 경우의 속도 곡선을 더한다 / add this run's speed curve to the figure
    plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('X = %g N', X));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
xlabel('time [s]'); ylabel('surge speed u [m/s]'); legend('Location','southeast');
title('a step force from t = 5 s: the speed rises without overshoot and levels off');
exportgraphics(f, fullfile(here, 'img', 'W03_result_open_loop.png'), 'Resolution', 150);
