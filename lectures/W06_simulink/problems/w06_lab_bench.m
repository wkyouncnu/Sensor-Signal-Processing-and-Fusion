function w06_lab_bench(mdl, x0)
%W06_LAB_BENCH  6주차 실습에 주어지는 부분 — 요구 시간표와 선체.
%               What the Week 6 laboratory is given: the demand timetable and the hull.
%
%   w06_lab_bench(mdl, x0)
%
%     mdl   이미 존재하는 모델 / a model that already exists
%     x0    캔버스에서 사슬이 시작하는 왼쪽 끝 [px]
%
%   왜 시간표와 선체를 주는가 / why these are given
%       6주차의 문제는 **배분기**를 만드는 것이다. 요구를 만드는 블록이나 선체를
%       다시 만들게 하면 시간이 그쪽으로 가고, 정작 이번 주의 내용에는 남지 않는다.
%       또 요구 신호가 학생마다 다르면 강의에서 잰 수치를 합격선으로 쓸 수 없다.
%
%       The Week 6 problems are about building the allocator. Rebuilding the
%       demand source or the hull would spend the hour elsewhere, and a demand
%       that differed between students would make the lecture's measured
%       numbers useless as a pass mark.
%
%   주어지는 것 / what is provided
%
%       demand      t -> [X_cmd ; N_cmd], a timetable set from the workspace
%                   (T_SW, X_SEQ, N_SEQ). Published as the tags X_cmd and N_cmd
%       Otter USV   n -> twelve states, unchanged otter.m
%       xlog        the twelve states
%
%   주어지지 않는 것, 그래서 문제인 것 / what is withheld, and is therefore the exercise
%
%       the allocator: [X_cmd ; N_cmd] -> [n1 ; n2], and the log alog
%
%   빈 자리를 채우는 Constant 하나가 꽂혀 있어 모델은 처음부터 컴파일된다. 지우고
%   자기 블록을 넣는다 / A Constant placeholder keeps the model compiling before
%   anything is built; delete it and put the allocator in its place.
%
%   왜 공유 함수인가 / why this is a shared function
%       출발 모델과 모범답안이 **같은 시험대**를 써야 한다. 그러지 않으면 결과의
%       차이가 배분기가 아니라 시험대에서 올 수 있다. 함수 하나를 양쪽이 부르면
%       그럴 수 없다 — 5주차 `w05_lab_vessel` 과 같은 이유다.
%
%   See also W06_P1_START, W06_CHECK, W06_S1_ALLOCATION.

%% ---- 요구 시간표 / the demand timetable --------------------------------
add_block('simulink/Sources/Clock', [mdl '/clock'], ...
          'Position', [x0 176 x0+20 196]);
blk = [mdl '/demand'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+70 120 x0+250 250]);
set_mlfcn(blk, { ...
'function tau_c = demand(t, T_SW, X_SEQ, N_SEQ)'
'%#codegen'
'%DEMAND  요구 시간표 / the demand timetable.'
'%'
'%  T_SW(i) 초부터 (X_SEQ(i), N_SEQ(i)) 를 요구한다. 세 벡터는 워크스페이스에'
'%  있고, W06_check 가 문제마다 다시 넣는다.'
'%  From T_SW(i) seconds the demand is (X_SEQ(i), N_SEQ(i)). The three vectors'
'%  live in the workspace and W06_check sets them for each problem.'
'k = 1;'
'for i = 1:numel(T_SW)'
'    if t >= T_SW(i), k = i; end'
'end'
'tau_c = [X_SEQ(k); N_SEQ(k)];'}, 'tau_c', '[2 1]');
mlfcn_params(blk, {'T_SW','X_SEQ','N_SEQ'});
add_line(mdl, 'clock/1', 'demand/1', 'autorouting','smart');

add_block('simulink/Signal Routing/Demux', [mdl '/split'], 'Outputs','2', ...
          'Position', [x0+290 140 x0+295 230]);
add_line(mdl, 'demand/1', 'split/1', 'autorouting','smart');
CM = {'X_cmd','N_cmd'};
for i = 1:2
    add_block('simulink/Signal Routing/Goto', [mdl '/' CM{i} ' out'], ...
              'GotoTag', CM{i}, 'Position', [x0+330 145+60*(i-1) x0+400 165+60*(i-1)]);
    add_line(mdl, sprintf('split/%d', i), [CM{i} ' out/1'], 'autorouting','smart');
    add_block('simulink/Signal Routing/From', [mdl '/' CM{i} ' in'], ...
              'GotoTag', CM{i}, 'Position', [x0+70 320+40*(i-1) x0+140 340+40*(i-1)]);
end

%% ---- 선체와 로그 / the hull and the state log --------------------------
add_otter_plant(mdl, 'Otter USV', [x0+640 150 x0+820 250], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position', [x0+880 180 x0+950 220]);
add_line(mdl, 'Otter USV/1', 'xlog/1', 'autorouting','smart');
end
