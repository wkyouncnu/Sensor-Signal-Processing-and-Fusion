function W06_S1_allocation(mdl)
%W06_S1_ALLOCATION  6주차 실습 세 문제의 모범답안 모델을 만든다.
%                   Build the reference answer to all three Week 6 problems.
%
%   >> W06_S1_allocation            W06_S1.slx 를 만든다 / creates W06_S1.slx
%
%   유일한 정답이 아니다 / not the only correct answer
%       체커는 도면이 아니라 **물리**를 본다. 같은 수를 내는 다른 도면은 모두
%       통과한다. 이 파일이 답하는 것은 "무엇을 만드는가" 가 아니라 "왜 그렇게" 다.
%       The checker tests the physics, not the diagram. Any drawing that
%       produces the same numbers passes. What this file argues is not what to
%       build but why it is built this way.
%
%   세 문제가 한 블록에 들어간다 / all three problems live in one block
%       ① 제곱 규칙과 역곡선 ② 부호에 맞는 k ③ 한계에서의 두 규칙.
%       ②는 ①의 두 줄이고 ③은 그 앞에 붙는 한 단계다. 셋을 나누면 학생이
%       "세 개를 만들었다" 고 생각하게 되는데, 실제로는 하나를 세 번 고친 것이다.
%       Problem 2 is two lines of Problem 1 and Problem 3 is one step in front
%       of it. Splitting them into three blocks would suggest three things were
%       built, when one thing was corrected twice.
%
%   See also W06_CHECK, W06_P1_START, W06_S_EXPECTED.

if nargin < 1 || isempty(mdl), mdl = 'W06_S1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%  출발 모델과 **같은 시험대**를 쓴다. 함수 하나를 양쪽이 부르므로 결과의 차이가
%  시험대에서 올 수 없다 / the same bench as the starting model, by construction
w06_lab_bench(mdl, 120);

%% ---- 배분기 / the allocator -------------------------------------------
blk = [mdl '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [500 140 740 300]);
set_mlfcn(blk, alloc_code(), 'n', '[2 1]');
mlfcn_params(blk, {'y_pont','k_pos','k_neg','T_max','T_min','fit_mode'});
add_line(mdl, 'X_cmd in/1', 'allocation/1', 'autorouting','smart');
add_line(mdl, 'N_cmd in/1', 'allocation/2', 'autorouting','smart');

add_block('simulink/Math Operations/Reshape', [mdl '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position', [790 195 830 235]);
add_line(mdl, 'allocation/1', 'as vector/1', 'autorouting','smart');
add_line(mdl, 'as vector/1',  'Otter USV/1', 'autorouting','smart');

%% ---- 요구와 회전수를 한 로그로 / the command and the shaft speeds, logged
add_block('simulink/Signal Routing/Mux', [mdl '/alog mux'], 'Inputs','3', ...
          'Position', [900 380 905 500]);
for i = 1:2
    tag = {'X_cmd','N_cmd'};  tag = tag{i};
    add_block('simulink/Signal Routing/From', [mdl '/' tag ' log'], ...
              'GotoTag', tag, 'Position', [810 385+40*(i-1) 880 405+40*(i-1)]);
    add_line(mdl, [tag ' log/1'], sprintf('alog mux/%d', i), 'autorouting','smart');
end
add_line(mdl, 'as vector/1', 'alog mux/3', 'autorouting','smart');
add_block('simulink/Sinks/To Workspace', [mdl '/alog'], ...
          'VariableName','alog', 'SaveFormat','Structure With Time', ...
          'Position', [950 420 1020 460]);
add_line(mdl, 'alog mux/1', 'alog/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/note']);
a.Text = strjoin({ ...
'WEEK 6 SOLUTION  -  ONE BLOCK, THREE PROBLEMS'
''
'   P1  the square rule            T = [X/2 + N/(2y) ;  X/2 - N/(2y)]'
'   P3  the limit step, first      clip each, or scale both by one s <= 1'
'   P2  the curve, with the k that belongs to the SIGN of the thrust'
''
'The order matters: the limit is a limit on THRUST, so it is applied before'
'the curve, not to the shaft speeds after it. Clamping n instead would give'
'the same answer for clipping and the wrong one for scaling, because scaling'
'is linear in T and the curve is not.'}, newline);
a.Position = [120 560 1040 700];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);
fprintf('\n  built %s   (overlapping lines: %d)\n\n', out, n);
end

% =========================================================================
function C = alloc_code()
C = {
'function n = allocation(X_cmd, N_cmd, y_pont, k_pos, k_neg, T_max, T_min, fit_mode)'
'%#codegen'
'%ALLOCATION  요구한 힘을 두 축의 회전수로 / a demanded force to two shaft speeds.'
'%'
'%  세 단계다. 순서가 내용의 일부다.'
'%  Three steps, and the order is part of the content.'
'%'
'%  ── 1) 제곱 규칙 (문제 1, §6-2) ────────────────────────────────────────'
'%     X = T1 + T2 와 N = y_pont (T1 - T2) 를 T 에 대해 푼 것뿐이다.'
'%     게인이 없다. 배분은 제어기가 아니라 **역**이고, 역에는 오차가 없다.'
'%     Nothing but X = T1 + T2 and N = y_pont(T1 - T2), solved for T. There is'
'%     no gain here: allocation is an inverse, not a controller, and an inverse'
'%     has no error to act on.'
'T1 = X_cmd/2 + N_cmd/(2*y_pont);'
'T2 = X_cmd/2 - N_cmd/(2*y_pont);'
'%'
'%  ── 2) 한계 (문제 3, §6-6) ─────────────────────────────────────────────'
'%     **곡선보다 먼저** 온다. 한계는 추력의 한계이지 회전수의 한계가 아니다.'
'%     회전수를 자르면 자르기는 같은 답을 주지만 비율 줄이기는 틀린 답을 준다 —'
'%     비율은 T 에 대해 선형이고 곡선은 아니기 때문이다.'
'%     This comes BEFORE the curve. The limit is a limit on thrust. Clamping the'
'%     shaft speed instead gives the same answer for clipping and the wrong one'
'%     for scaling, because scaling is linear in T and the curve is not.'
'if fit_mode == 0'
'    %  자르기: 각각 따로. 쌍이 달라지므로 **방향이 바뀐다**.'
'    %  Clipping, one thrust at a time: the pair changes, so the direction turns.'
'    T1 = min(max(T1, T_min), T_max);'
'    T2 = min(max(T2, T_min), T_max);'
'else'
'    %  비율 줄이기: 둘을 **같은 수**로. X 와 N 이 모두 T 에 선형이므로'
'    %  둘 다 s 배가 되고 비율 X/N 은 그대로 남는다.'
'    %  Scaling by one factor: X and N are both linear in T, so both are'
'    %  multiplied by s and the ratio X/N survives exactly.'
'    s = 1;'
'    if T1 > T_max, s = min(s, T_max/T1); end'
'    if T2 > T_max, s = min(s, T_max/T2); end'
'    if T1 < T_min, s = min(s, T_min/T1); end'
'    if T2 < T_min, s = min(s, T_min/T2); end'
'    T1 = s*T1;  T2 = s*T2;'
'end'
'%'
'%  ── 3) 프로펠러 곡선의 역 (문제 2, §6-5) ───────────────────────────────'
'%     T = k n |n| 의 역은 n = sign(T) sqrt(|T|/k) 인데, **그 k 가 추력의'
'%     부호에 속한 k 여야 한다.** 앞으로 갈 때는 두 계수가 같은 답을 주므로'
'%     이 잘못은 시운전에서 살아남는다. 뒤로 갈 때만 드러난다.'
'%     The inverse needs the k that belongs to the SIGN of the thrust. Ahead,'
'%     both coefficients agree, which is why this error survives a sea trial:'
'%     it shows only when something runs astern.'
'T = [T1; T2];'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        n(i) =  sqrt( T(i) / k_pos);'
'    else'
'        n(i) = -sqrt(-T(i) / k_neg);'
'    end'
'end'
};
end
