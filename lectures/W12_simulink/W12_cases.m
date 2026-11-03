function [C, n_cxl] = W12_cases(cfg)
%W12_CASES  이 주차가 **손으로** 주는 여섯 벌의 숫자. 한 벌이 여덟 개다.
%           The six sets of eight numbers this week gives by hand.
%
%   왜 따로 있는가 / why this is its own file
%       절 스크립트는 얇아야 한다 (§15-15). 여섯 경우는 표 셋과 그림이 **모두**
%       같은 것을 가리켜야 하므로 한 곳에 두고 셋이 함께 읽는다.
%
%   여섯 경우 / the six cases
%       V1  네 기 전진, 각 0            순수 전진. tilt4 가 1~5 주차 Otter 로 돌아간다
%       V2  좌현 전진 · 우현 후진, 각 0  제자리 선회를 기대하지만 **전진력이 남는다**
%       V3  네 기 전진, 각 +45          게걸음을 기대하지만 **모멘트가 남는다**
%       V4  선수 +45 · 선미 -45          횡력을 모으고 전진력을 지우려는 시도
%       V5  V4 에서 선미 회전수를 고쳐  전진력을 **정확히** 0 으로 만든다
%       V6  각을 70 도로 지시           서보가 45 도에서 자른다. 결과는 V3 와 같다
%
%       V2 와 V3 가 이 주차의 핵심이다. 둘 다 "대칭으로 주면 깨끗할 것" 이라는
%       짐작이 틀리는 자리이고, 틀리는 이유가 서로 다르다 — V2 는 **추력 곡선의
%       전진·후진 비대칭**, V3 는 **선수·선미 거리의 비대칭**(l_f=1.5, l_a=1.0).
%       배분기가 왜 필요한지가 여기서 나온다.
%
%   열 / the columns
%       {tag, n [rad/s] (4), delta [deg] (4), 한 줄 설명}
%
%   See also W12_V_OPENLOOP, W12_TAB_FORMULA, W12_TAB_REINT, W12_TAB_TRACK.

%  전진 추력을 **정확히** 지우는 후진 회전수. -60 이 아니다.
%  the astern speed that exactly cancels 60 rad/s ahead; it is not -60
n_cxl = -60 * sqrt(cfg.k_pos / cfg.k_neg);

C = { 'V1'  [ 60  60    60     60   ]  [  0   0    0    0 ]  'four ahead, no tilt'
      'V2'  [ 60 -60    60    -60   ]  [  0   0    0    0 ]  'port ahead, starboard astern'
      'V3'  [ 60  60    60     60   ]  [ 45  45   45   45 ]  'four ahead, all tilted +45'
      'V4'  [ 60  60   -60    -60   ]  [ 45  45  -45  -45 ]  'bow +45, stern -45, equal speed'
      'V5'  [ 60  60  n_cxl  n_cxl  ]  [ 45  45  -45  -45 ]  'bow +45, stern -45, surge cancelled'
      'V6'  [ 60  60    60     60   ]  [ 70  70   70   70 ]  'tilt commanded beyond the servo limit' };

end
