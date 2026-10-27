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
%      ① 모델 넷을 일곱 벌로 돌린다.
%      ② 표 셋을 낸다: 임무 · 구동 · 자세. 지표 정의는 앞 절들과 **같다**.
%      ③ 단마다 그림 한 장(img/W06_r<단>_<이름>.png)과 전체 한 장을 남긴다.
%      ① Runs the four models in seven configurations.
%      ② Prints three tables -- the mission, the actuation, the attitude -- with
%         every metric defined as the section that introduced it defines it.
%      ③ Saves one figure per rung and one for the ladder as a whole.
%
%  출력에서 볼 것 / what to look for in the output
%      - 1 단과 4 단은 **같은 모델·같은 게인**이고 목표만 다르다. 1 단은 비스듬히,
%        4 단은 정북으로 간다. 그래서 4 단의 |v| 가 거의 0 이다.
%      - 2 단은 정동 13 m, 북으로는 0 — **순수 횡이동**이다. 선수추진기가 없으면
%        할 수 없는 과업이고, 그것이 이 주차가 추진기를 하나 더 다는 이유다.
%      - 3 단은 고리를 **걷어 낸** 단이다. 학부 과정은 여기서 추력곡선을 더하지만,
%        이 과정의 모델은 첫 단부터 배분과 곡선을 안에 들고 있으므로 거꾸로
%        고리를 떼어 곡선만 드러낸다 — 두 사다리가 방향이 반대인 자리는 여기뿐이다.
%      - 5 단과 7 단은 같은 선석에 자세만 달리 붙는다. 전진 접안이 횡력을 덜 쓴다.
%      - 8 단의 max |u| 는 제 천장 v_ned_max 0.350 에 묶인다. 좌표계를 바꾼 값이
%        완료 시각이다.
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
%  단 번호 · 이름 · 모델 · W06_vars 에서 덮어쓰는 값 · 목표 (N, E, psi[deg])
%  rung, name, model, what is overridden in W06_vars, and the target
L = {1 'point'  'W06_F_position'     {'N_d',10,'E_d',10,'psi_d_cmd',0,'T_final',120}, [10 10 0]
     2 'sway'   'W06_F_position'     {'N_d', 0,'E_d',13,'psi_d_cmd',0,'T_final',120}, [0 13 0]
     3 'thrust' 'W06_C_actuation'    {'X_cmd',40,'Y_cmd',15,'N_cmd',10,'T_final',20}, [NaN NaN NaN]
     4 'stop'   'W06_F_position'     {'N_d',12,'E_d',25,'psi_d_cmd',0,'T_final',120}, [12 25 0]
     5 'dock'   'W06_H_berth'        {'psi_berth',0,'bow_on',0,'T_final',150}, [V.berth_N V.berth_E 0]
     7 'front'  'W06_H_berth'        {'psi_berth',-pi/2,'bow_on',1,'T_final',150}, [V.berth_N V.berth_E -90]
     8 'ned'    'W06_I_position_ned' {'N_d',10,'E_d',10,'psi_d_cmd',0,'T_final',120}, [10 10 0]};

n = size(L,1);  Rs = cell(n,1);  M1 = nan(n,8);  M2 = nan(n,9);  M3 = nan(n,4);
nm = arrayfun(@(i) sprintf('%d %s  %s', L{i,1}, L{i,2}, L{i,3}), 1:n, 'UniformOutput', false);
ft = @(t,m) min([t(m); NaN]);          % 처음으로 참이 된 시각 / when it first held
for i = 1:n
    Rs{i} = W06_read(L{i,3}, L{i,4}{:});   R = Rs{i};
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
fprintf('\n  W06 Experiment 6-8  the rungs of the ladder, measured in one place\n');
fprintf(['\n    table 1, the mission\n    rung                             t to 0.5 m   phase 1   phase 2' ...
         '   phase 3   phase 4   d(end) [m]   psi err [deg]   last 10 s [m]\n']);
c = [nm; num2cell(M1.')];
fprintf('    %-31s %10.2f %9.2f %9.2f %9.2f %9.2f %12.3f %15.2f %15.3f\n', c{:});
fprintf(['\n    table 2, the actuation\n    rung                               |u|max   |v|max   |r|max' ...
         '      T_L      T_R      F_B    |n|max   path [m]   straight [m]\n']);
c = [nm; num2cell(M2.')];
fprintf('    %-31s %8.3f %8.3f %8.2f %8.1f %8.1f %8.1f %9.2f %10.2f %14.2f\n', c{:});
fprintf(['\n    table 3, the attitude\n    rung                             target N        E      psi' ...
         '      final N        E      psi   samples\n']);
c = [nm; num2cell(cell2mat(L(:,5)).'); num2cell(M3.')];
fprintf('    %-31s %8.3f %8.3f %8.2f %12.3f %8.3f %8.2f %9d\n', c{:});

%% 3) 사다리 전체 한 장 / the ladder on one chart
W06_fig_ladder(Rs, L, V, here);
