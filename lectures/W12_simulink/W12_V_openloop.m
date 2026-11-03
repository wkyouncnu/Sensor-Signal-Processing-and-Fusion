%W12_V_OPENLOOP  여덟 개의 숫자를 손으로 주고 **예상한 대로 움직이는지** 본다.
%                Give eight numbers by hand and check the hull moves as predicted.
%
%   실행 / to run
%       cd lectures/W12_simulink
%       W12_1_build_openloop        % 한 번만. 모델을 만든다
%       W12_V_openloop              % 표 셋과 그림 하나
%
%   1단계의 질문 하나 / the one question of stage 1
%       추진기 넷에 축회전수와 틸팅 각을 **손으로** 주었을 때, 배가 받는 힘과
%       모멘트가 손으로 계산한 것과 같고 궤적이 그 힘으로 설명되는가.
%       제어기도 배분기도 없다 — 그것은 다음 단계다.
%
%   왜 검증이 **두 층**인가 / why the check has two layers
%       (1) 수식이 맞는가. 손으로 쓴 X, Y, N 을 `otter_tilt4` 의 가속도에서
%           거꾸로 잰 tau 와 견준다. 반올림오차 수준이어야 한다.
%       (2) 모델이 그 수식인가. 모델이 로그에 적은 서보 뒤의 입력을 그대로
%           `otter_tilt4` 에 먹여 Simulink **밖에서** 30 초를 다시 적분하고,
%           두 궤적을 견준다. 여기가 어긋나면 수식이 아니라 **배선**이 틀렸다.
%
%       (1) 만 하면 "함수는 맞는데 모델이 다른 것을 쓰고 있다" 를 못 잡고,
%           (2) 만 하면 "모델과 함수가 똑같이 틀렸다" 를 못 잡는다.
%
%   한 번 돌리고 셋이 읽는다 / six runs, read three ways
%       표 (1) 은 운항이 시작되는 **정지 상태**에서 힘을 재고, 표 (2) 는 여섯
%       운항을 **전부** 다시 적분하고, 표 (3) 은 그 여섯의 **끝**을 읽는다.
%       그래서 셋을 쪼개면 같은 궤적 여섯을 얻으려 배를 스물넷 번 돌려야 한다.
%       블록은 파일로 나뉘어 있다 — `W12_cases` · `W12_tab_formula` ·
%       `W12_tab_reint` · `W12_tab_track`, 강의 절이 쓰는 순서 그대로다.
%
%   See also W12_0_SETUP, W12_1_BUILD_OPENLOOP, W12_CASES, W12_TAB_FORMULA,
%            W12_TAB_REINT, W12_TAB_TRACK, W12_READ, W12_PLOT,
%            OTTER_TILT4, VERIFY_OTTER_TILT4, OTTER_B.

function W12_V_openloop()

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W12_openloop';
V   = W12_vars();
cfg = otter_config('quad_tilt');
[C, n_cxl] = W12_cases(cfg);

TAU = W12_tab_formula(C, V, cfg);       % (1) 수식이 맞는가
R   = W12_tab_reint(mdl, C, V);         % (2) 모델이 그 수식인가 — 여섯 번 돈다
W12_tab_track(C, R, TAU, cfg, n_cxl);   % (3) 그 힘이 만드는 운동

%  V6 을 점선으로 그린다. V6 은 V3 과 **같은 곡선**이고 (서보가 70 도를 45 도로
%  깎았으므로), 실선 둘을 겹쳐 그리면 뒤의 것이 앞의 것을 지워 한 곡선만 보인다.
%  점선이 실선 위에 얹혀야 "둘이 같다" 가 그림에서 읽힌다 / V6 is V3 with the
%  servo limit doing the work, so it is drawn dashed on top of the solid V3
STY = {'-', '-', '-', '-', '-', '--'};
LBL = cellfun(@(a,b) sprintf('%s  %s', a, b), C(:,1)', C(:,4)', ...
              'UniformOutput', false);

f = W12_plot(R, LBL, ...
    'W12 open loop  -  eight numbers given by hand, and the track they produce', STY);
exportgraphics(f, fullfile(here, 'img', 'W12_result_openloop.png'), ...
               'Resolution', 150);

fprintf('  figure written to img/W12_result_openloop.png\n\n');

end
