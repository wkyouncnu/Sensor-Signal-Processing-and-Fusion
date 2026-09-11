function [k, s] = W01rc_usb_axis(a0, a1, skip)
%W01RC_USB_AXIS  두 번 읽은 축 값에서 가장 많이 움직인 축과 그 방향을 찾는다.
%
%   [k, s] = W01rc_usb_axis(a0, a1)         a0 스틱을 가운데에 둔 값, a1 한 스틱을 민 값
%   [k, s] = W01rc_usb_axis(a0, a1, skip)   skip 번 축은 빼고 찾는다 (이미 스로틀로 정한 축)
%
%     k   축 번호
%     s   +1 이면 민 쪽이 + 방향, -1 이면 민 쪽이 - 방향
%
%   W01_H_usb_setup 이 부른다. 조종기와 설정마다 축 순서(AETR, TAER …)와 방향이
%   다르므로, 번호를 가정하지 않고 "움직여 보라" 고 한 뒤 무엇이 움직였는지 본다.
%
%   가장 많이 움직인 축의 변화가 전체 폭(-1 ~ +1, 곧 2)의 1/4 인 0.5 보다 작으면
%   스틱을 밀지 않은 것으로 보고 에러를 낸다.

if nargin < 3, skip = []; end
d = a1(:) - a0(:);
d(skip) = 0;
[big, k] = max(abs(d));
if big < 0.5
    error('W01rc_usb_axis:still', ...
          'No axis moved by more than a quarter of its travel (largest %.2f, axis %d).', big, k);
end
s = sign(d(k));
end
