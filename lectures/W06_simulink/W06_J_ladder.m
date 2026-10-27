%% W06 · 실험 6-8 — 사다리를 한 자리에서 잰다 / Experiment 6-8 — the whole ladder in one place
%
%  이 절이 묻는 것 / the question
%      앞의 일곱 실험은 한 번에 하나씩 묻는다. 그래서 **어느 단에서 무엇이
%      달라졌는지**는 보이지 않는다. 단들을 연달아 돌려 한 표에 쌓으면 그것이
%      보인다 — 한 단에 새로 생기는 것은 하나뿐이므로, 줄과 줄 사이의 차이가 곧
%      그 하나가 한 일이다.
%      The experiments before this one each ask a single question, so what
%      changes from one rung of the ladder to the next is never in view. Running
%      the rungs back to back into one table puts it there: exactly one thing is
%      new on each rung, so the difference between two rows is what that one
%      thing did.
%
%  단 번호는 학부 캡스톤 과정의 것과 **같다** / the rungs are numbered as in the
%  undergraduate capstone course, so that the two ladders can be read side by
%  side. 6 단은 그 과정에서 5 단을 Gazebo·VRX 에 붙여 돌리는 단이고, 이 과정은
%  Otter 동역학만 다루므로 **6 단이 없다.** 그래서 도는 것은 1~5·7·8 의 일곱이다.
%  Rung 6 is the capstone's Gazebo/VRX twin of rung 5; this course runs the Otter
%  dynamics only, so rung 6 is deliberately absent and seven rungs run.
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 일곱을 차례로, **고친 것 없이 그대로** 돌린다. 단마다 제 모델이
%         있고, 무엇을 지시받았는지는 그 캔버스에 숫자로 박혀 있다.
%      ② 표 셋을 낸다: 임무 · 구동 · 자세. 지표 정의는 앞 절들과 **같다**.
%      ③ 단마다 그림 한 장(img/W06_r<단>_<이름>.png)과 전체 한 장을 남긴다.
%      ① Runs the seven models one after another, each exactly as it stands.
%         Every rung has its own model, and what that rung is told to do is a
%         number on its own canvas.
%      ② Prints three tables -- the mission, the actuation, the attitude -- with
%         every metric defined as the section that introduced it defines it.
%      ③ Saves one figure per rung and one for the ladder as a whole.
%
%  이 스크립트는 단 스크립트를 **대신하지 않는다.** `W06_1_point_run` 부터
%  `W06_8_ned_run` 까지가 절마다 그 절의 수치를 설명과 함께 찍고, 이것은 그
%  일곱을 한 표에 나란히 놓는다. 혼자 돌려도 되고 순서도 상관없다.
%  This does not replace the rung scripts. W06_1_point_run .. W06_8_ned_run each
%  print one section's numbers with the prose that reads them; this one lays all
%  seven side by side. It stands alone and needs no particular order.
%
%  출력에서 볼 것 / what to look for in the output
%      - 1 단과 4 단은 **같은 제어기·같은 게인**이고 목표만 다르다. 1 단은
%        비스듬히, 4 단은 정북으로 간다. 그래서 4 단의 |v| 가 거의 0 이다.
%      - 2 단은 정동 13 m, 북으로는 0 — **순수 횡이동**이다. 선수추진기가 없으면
%        할 수 없는 과업이고, 그것이 이 주차가 추진기를 하나 더 다는 이유다.
%      - 3 단은 고리를 **걷어 낸** 단이다. 학부 과정은 여기서 추력곡선을 더하지만,
%        이 과정의 모델은 첫 단부터 배분과 곡선을 안에 들고 있으므로 거꾸로
%        고리를 떼어 곡선만 드러낸다 — 두 사다리가 방향이 반대인 자리는 여기뿐이다.
%      - 5 단과 7 단은 같은 선석에 자세만 달리 붙는다. 전진 접안이 횡력을 덜 쓴다.
%      - 8 단은 축마다 자르지 않고 **속도의 크기**를 자른다. 그래서 같은 점을
%        1 단보다 늦게 잡는다. 좌표계를 바꾼 값이 완료 시각이다.
%      - 빈 칸(로그가 NaN 을 찍는 자리)은 그 단에 **그것이 없다**는 뜻이다.
%        The dash-shaped NaN entries are not failures: rung 3 has no target, no
%        distance to one and no phase, and only the berthing rungs have phases.
%
%  만드는 것 / produces: img/W06_r1_point.png … img/W06_r8_ned.png,
%                        img/W06_result_ladder.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
V = W06_vars();

%% 1) 사다리 / the ladder
%  단 번호 · 이름 · 모델 · 절 · 목표 (N, E, psi[deg])
%
%  **명령이 이 표에 없다.** 무엇을 지시하는가는 그 모델의 캔버스에 숫자로 박혀
%  있고, 이 표는 어느 모델을 도는가만 정한다. 목표 열은 지시가 아니라 **판정
%  기준**이다 — 도착한 자리를 견주기 위해 여기에 적어 둔다.
%  The demands are NOT in this table. What each rung is told to do is a number on
%  its own canvas; this table only says which model to run. The target column is
%  not a command but the yardstick the final position is held against.
L = {1 'point'  'W06_1_point'  '6-3', [10 10 0]
     2 'sway'   'W06_2_sway'   '6-2', [0 13 0]
     3 'thrust' 'W06_3_thrust' '6-1', [NaN NaN NaN]
     4 'stop'   'W06_4_stop'   '6-4', [12 25 0]
     5 'dock'   'W06_5_dock'   '6-5', [V.berth_N V.berth_E 0]
     7 'front'  'W06_7_front'  '6-6', [V.berth_N V.berth_E -90]
     8 'ned'    'W06_8_ned'    '6-7', [10 10 0]};

n = size(L,1);  Rs = cell(n,1);  M1 = nan(n,8);  M2 = nan(n,9);  M3 = nan(n,4);
%  단 이름은 번호와 짧은 이름만 든다. 모델 이름은 바로 위의 표가 이미 짝지어 두었고,
%  여기에 한 번 더 적으면 줄이 100 자를 넘어 **PDF 안에서 접힌다** — 접히면 열이
%  맞지 않아 표가 읽히지 않는다 (§15-66).
%  The rung name carries the number and the short name only. The table just above
%  already pairs each rung with its model, and repeating it here pushes the line
%  past 100 characters, where the PDF wraps it and the columns stop lining up.
nm = arrayfun(@(i) sprintf('%d %s', L{i,1}, L{i,2}), 1:n, 'UniformOutput', false);
ft = @(t,m) min([t(m); NaN]);          % 처음으로 참이 된 시각 / when it first held
for i = 1:n
    Rs{i} = W06_read(L{i,3});   R = Rs{i};
    %  임무가 없는 단은 로그의 d 가 NaN 이다 — 거리를 재는 것은 단계기이고,
    %  그 단에는 단계기가 없다. 목표가 있는 단이면 여기서 **같은 정의로** 잰다:
    %  설정값 열과 위치 열 사이의 거리 / the mission block is what measures d, and
    %  a rung without one logs NaN. Where there is a target, measure it here with
    %  the same definition -- the distance between the setpoint and the position.
    if all(isnan(R.d)) && ~any(isnan(L{i,5}))
        R.d = hypot(R.N_set - R.N, R.E_set - R.E);
        Rs{i} = R;
    end
    tail = R.t >= R.t(end) - 10;                       % 마지막 10 초 / the last 10 s
    M1(i,:) = [ft(R.t, R.d < 0.5), arrayfun(@(p) ft(R.t, R.phase >= p), 1:4), ...
                R.d(end), R.psi(end) - R.psi_set(end), mean(R.d(tail))];
    M2(i,:) = [max(abs(R.u)), max(abs(R.v)), rad2deg(max(abs(R.r))), ...
               max(abs(R.T_L)), max(abs(R.T_R)), max(abs(R.F_B)), ...
               max(max(abs(R.n_L)), max(abs(R.n_R))), ...
               sum(hypot(diff(R.N), diff(R.E))), hypot(R.N(end)-R.N(1), R.E(end)-R.E(1))];
    M3(i,:) = [R.N(end), R.E(end), R.psi(end), numel(R.t)];
    W06_fig_rung(R, L(i,:), V, here);
end

%% 2) 표 셋 / the three tables
%  머리글과 숫자 줄이 **같은 폭 목록**을 쓴다. 머리글을 손으로 띄어 쓰면 열이 하나
%  어긋나고, 그것을 눈으로 잡기 어렵다. 어느 줄도 100 자를 넘지 않아야 한다 —
%  PDF 본문이 186 mm 이고 고정폭 9 pt 이라 그보다 넓으면 접힌다 (§15-66).
%  The header and the number rows share ONE set of widths: a header spaced by hand
%  goes one column out of true and the eye does not catch it. No line may exceed
%  100 characters, because the PDF body is 186 mm at 9 pt monospaced.
fprintf('\n  W06 Experiment 6-8  the rungs of the ladder, measured in one place\n');

fprintf('\n    table 1, the mission\n');
fprintf('    %-9s %9s %9s %9s %9s %9s %10s %10s %11s\n', 'rung', 't 0.5 [s]', 'phase1', 'phase2', 'phase3', 'phase4', 'd(end)[m]', 'psi err', 'last 10 [m]');
c = [nm; num2cell(M1.')];
fprintf('    %-9s %9.2f %9.2f %9.2f %9.2f %9.2f %10.3f %10.2f %11.3f\n', c{:});

fprintf('\n    table 2, the actuation\n');
fprintf('    %-9s %7s %7s %7s %7s %7s %7s %8s %9s %9s\n', 'rung', '|u|max', '|v|max', '|r|max', 'T_L', 'T_R', 'F_B', '|n|max', 'path [m]', 'straight');
c = [nm; num2cell(M2.')];
fprintf('    %-9s %7.3f %7.3f %7.2f %7.1f %7.1f %7.1f %8.2f %9.2f %9.2f\n', c{:});

fprintf('\n    table 3, the attitude\n');
fprintf('    %-9s %8s %8s %8s %10s %8s %8s %8s\n', 'rung', 'target N', 'E', 'psi', 'final N', 'E', 'psi', 'samples');
c = [nm; num2cell(cell2mat(L(:,5)).'); num2cell(M3.')];
fprintf('    %-9s %8.3f %8.3f %8.2f %10.3f %8.3f %8.2f %8d\n', c{:});

%% 3) 사다리 전체 한 장 / the ladder on one chart
W06_fig_ladder(Rs, L, V, here);
