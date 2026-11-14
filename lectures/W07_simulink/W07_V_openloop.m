%W07_V_OPENLOOP  여덟 개의 숫자를 손으로 주고 **예상한 대로 움직이는지** 본다.
%                Give eight numbers by hand and check the hull moves as predicted.
%
%   실행 / to run
%       cd lectures/W07_simulink
%       W07_1_build_openloop        % 한 번만. 모델을 만든다
%       W07_V_openloop              % 여덟 시나리오 전부
%       W07_V_openloop('S5')        % 하나만 — 그 한 장만 다시 뽑는다
%       W07_V_openloop({'S5','S6'}) % 둘만 — 비교할 둘을 고른다
%       W07_V_openloop(1:4)         % 번호로 골라도 된다
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
%   한 번 돌리고 셋이 읽는다 / run once, read three ways
%       표 (1) 은 운항이 시작되는 **정지 상태**에서 힘을 재고, 표 (2) 는 고른
%       운항을 **전부** 다시 적분하고, 표 (3) 은 그 운항들의 **끝**을 읽는다.
%       셋을 쪼개면 같은 궤적을 얻으려 배를 네 배로 돌려야 한다.
%
%   그림은 시나리오마다 한 장이다 / one figure per scenario
%       여덟을 한 칸에 겹쳐 그리면 곡선이 서로를 지운다. 그래서
%       `img/W07_result_S1.png` … `_S8.png` 가 각각 나오고, 겹쳐 그린
%       `W07_result_openloop.png` 은 **비교용으로만** 남는다.
%
%   See also W07_0_SETUP, W07_1_BUILD_OPENLOOP, W07_CASES, W07_PICK,
%            W07_TAB_FORMULA, W07_TAB_REINT, W07_TAB_TRACK, W07_READ,
%            W07_PLOT, W07_PLOT_SCENARIO, OTTER_TILT4, VERIFY_OTTER_TILT4.

function W07_V_openloop(pick)

if nargin < 1, pick = 'all'; end

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W07_openloop';
V   = W07_vars();
cfg = otter_config('quad_tilt');
[S, n_sway] = W07_cases(cfg);
k   = W07_pick(S, pick);                      % 고른 줄 / the chosen rows
Sk  = S(k, :);

TAU = W07_tab_formula(Sk, V, cfg);            % (1) 수식이 맞는가
R   = W07_tab_reint(mdl, Sk, V);              % (2) 모델이 그 수식인가
W07_tab_track(S, k, R, TAU, cfg, n_sway);     % (3) 그 힘이 만드는 운동

%  시나리오마다 한 장. 이름에 태그가 들어가 하나만 다시 돌려도 그 장만 바뀐다
for c = 1:numel(k)
    f   = W07_plot_scenario(R{c}, Sk(c,:), TAU(c,:), cfg);
    png = sprintf('W07_result_%s.png', Sk{c,1});
    exportgraphics(f, fullfile(here, 'img', png), 'Resolution', 150);
    fprintf('    %-4s %-27s img/%s\n', Sk{c,1}, Sk{c,4}, png);
end

%  겹쳐 그린 한 장은 **비교용**이다. 마지막 줄만 점선으로 — 서보가 깎은 S8 이
%  S5 와 같은 곡선이므로, 점선이 실선 위에 얹혀야 "둘이 같다" 가 읽힌다
if numel(k) > 1
    STY = repmat({'-'}, 1, numel(k));  STY{end} = '--';
    LBL = cellfun(@(a,b) sprintf('%s  %s', a, b), Sk(:,1)', Sk(:,4)', ...
                  'UniformOutput', false);
    f = W07_plot(R, LBL, ...
        'W07 open loop  -  all scenarios on one axes, for comparison only', STY);

    %  몇 개만 골라 돌렸을 때는 **저장하지 않는다.** 강의 `.md` 가 싣는 파일은
    %  여덟이 다 든 한 장이어야 하고, 부분 실행이 그것을 조용히 덮으면 문서의
    %  그림과 본문이 어긋난다 / a partial run draws the overlay but does not save
    %  it: the file the lecture embeds must be the one carrying all eight
    if numel(k) == size(S,1)
        exportgraphics(f, fullfile(here, 'img', 'W07_result_openloop.png'), ...
                       'Resolution', 150);
        fprintf('    %-4s %-27s img/W07_result_openloop.png\n', '--', 'all of them overlaid');
    else
        fprintf('    %-4s %-27s not saved: a partial run\n', '--', 'the overlay');
    end
end

fprintf('\n');

end
