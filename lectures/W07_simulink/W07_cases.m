function [S, n_sway] = W07_cases(cfg)
%W07_CASES  이 주차가 **손으로** 주는 여덟 벌의 숫자. 한 벌이 여덟 개다.
%           The eight sets of eight numbers this week gives by hand.
%
%   왜 따로 있는가 / why this is its own file
%       절 스크립트는 얇아야 한다 (§15-15). 여덟 시나리오는 표와 그림이 **모두**
%       같은 것을 가리켜야 하므로 한 곳에 두고 여럿이 함께 읽는다.
%
%   쌍마다 0 도가 다르다 / the zero differs per pair
%       선수 둘(1·2)은 앞을, 선미 둘(3·4)은 뒤를 보고 달려 있다. 그래서
%       delta = 0 은 선수 쌍에서 +x_b, 선미 쌍에서 -x_b 를 민다. 이 한 가지가
%       아래 여덟 줄의 부호를 전부 설명한다.
%       Units 1 and 2 face forward, units 3 and 4 face aft, so delta = 0 pushes
%       along +x_b for the bow pair and along -x_b for the stern pair.
%
%   여덟 시나리오 / the eight scenarios
%       S1  전진        각 0, 선수 정회전 · 선미 역회전       순수 전진
%       S2  후진        S1 의 회전수를 전부 뒤집는다           순수 후진, 크기가 같다
%       S3  우선회      네 기 같은 각 +45                     힘 0, 모멘트만
%       S4  좌선회      네 기 같은 각 -45                     S3 의 거울
%       S5  우횡이동    선수 +45 · 선미 -45, 회전수 같음       전진력 0, 모멘트 남음
%       S6  우횡이동    S5 에서 선미 회전수를 올린다           모멘트 0, 전진력 남음
%       S7  선회 전진   선수만 +45                             셋이 함께 나온다
%       S8  서보 한계   70 도를 지시한다                       결과가 S5 와 같다
%
%       S5 와 S6 가 이 주차의 핵심이다. 둘 중 **어느 쪽도 순수한 횡이동이
%       아니다** — 서보가 ±45 도까지만 돌아가므로 전진력과 모멘트를 **동시에**
%       0 으로 만들 수 없다. 배분기가 왜 필요한지가 여기서 나온다.
%       Neither S5 nor S6 is a pure sway: within +-45 deg the surge force and
%       the yaw moment cannot both be zeroed. That is the opening for Stage 2.
%
%   열 / the columns
%       {tag, n [rad/s] (4), delta [deg] (4), 지시 이름, 예상 기동}
%
%   See also W07_V_OPENLOOP, W07_TAB_FORMULA, W07_TAB_REINT, W07_TAB_TRACK,
%            W07_PLOT_SCENARIO, OTTER_TILT4, OTTER_B.

%  모멘트를 **정확히** 지우는 선미 회전수. T_a = 1.5 T_f 가 그 조건이고,
%  추력이 회전수의 제곱이므로 회전수는 sqrt(1.5) 배다.
%  the stern speed that exactly cancels the yaw moment: T_a = 1.5 T_f, and
%  thrust goes as the square of the speed, so the speed goes as sqrt(1.5)
n_sway = 60 * sqrt(cfg.l_f / cfg.l_a);

S = { ...
'S1' [ 60  60 -60 -60] [  0   0   0   0] 'surge ahead'  ...
     'runs straight ahead, no heading change: the hull settles at a steady u'
'S2' [-60 -60  60  60] [  0   0   0   0] 'surge astern' ...
     'runs straight astern with the SAME force magnitude as S1, mirrored'
'S3' [ 60  60  60  60] [ 45  45  45  45] 'yaw to starboard' ...
     'turns on the spot to starboard: no net force at all, only a moment'
'S4' [ 60  60  60  60] [-45 -45 -45 -45] 'yaw to port' ...
     'turns on the spot to port, the exact mirror of S3'
'S5' [ 60  60  60  60] [ 45  45 -45 -45] 'sway to starboard' ...
     'crabs to starboard with zero surge force, but keeps turning: l_f > l_a'
'S6' [ 60  60  n_sway  n_sway] [ 45  45 -45 -45] 'sway, moment cancelled' ...
     'crabs to starboard on a steady heading, but now drifts ASTERN'
'S7' [ 60  60 -60 -60] [ 45  45   0   0] 'turn while making way' ...
     'surge, sway and yaw at once: a turning circle, the most ship-like row'
'S8' [ 60  60  60  60] [ 70  70 -70 -70] 'tilt beyond the servo limit' ...
     'identical to S5 in every number: the servo gave 45 deg, not 70' };

end
