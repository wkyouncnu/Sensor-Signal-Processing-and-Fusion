function [k, s] = W01rc_usb_axis(a0, a1, skip)
%W01RC_USB_AXIS  두 번 읽은 축 값을 비교해 가장 많이 움직인 축과 그 방향을 찾는다.
%                Compare two readings of the axes and identify which one moved
%                most, and in which direction.
%
%   [k, s] = W01rc_usb_axis(a0, a1)         a0 은 스틱을 가운데에 둔 값,
%                                           a1 은 한 스틱을 끝까지 민 값
%                                           a0 with the sticks centred, a1 with
%                                           one stick pushed fully over
%   [k, s] = W01rc_usb_axis(a0, a1, skip)   skip 번 축은 후보에서 제외한다.
%                                           이미 스로틀로 정해 둔 축을 다시 고르지
%                                           않게 하려는 것이다
%                                           exclude axis skip from the search,
%                                           so that an axis already assigned to
%                                           the throttle is not chosen again
%
%     k   축 번호 / the axis number
%     s   민 쪽이 + 방향이면 +1, - 방향이면 -1
%         +1 if pushing over raises the value, -1 if it lowers it
%
%   누가 부르는가 / who calls this
%     W01_H_usb_setup 이 부른다. 조종기와 그 설정에 따라 축 순서(AETR, TAER 등)와
%     방향이 다르므로, 몇 번 축이 무엇인지 가정하지 않는다. 대신 사용자에게 스틱을
%     움직여 보라고 한 뒤 무엇이 움직였는지를 관찰한다. 장치의 규격을 믿는 대신
%     실제 동작을 측정하는 방식이며, 실물 장치를 다룰 때의 일반적인 태도이다.
%
%     W01_H_usb_setup calls it. Since the channel order (AETR, TAER and so on)
%     and the directions differ between transmitters and between
%     configurations, nothing is assumed about which axis carries what. The
%     user is asked to move a stick and the result is observed instead. This
%     is measurement in place of trust in a specification, which is the usual
%     posture when real hardware is involved.
%
%   판정 기준 / the acceptance threshold
%     가장 많이 움직인 축의 변화가 전체 폭(-1 에서 +1 까지, 즉 2)의 4분의 1 인
%     0.5 보다 작으면 스틱을 실제로 밀지 않은 것으로 보고 오류를 낸다. 잡음이나
%     손떨림을 스틱 입력으로 잘못 읽는 것을 막는다.
%
%     If the largest change is smaller than 0.5, a quarter of the full travel
%     from -1 to +1, the stick is taken not to have been moved and an error is
%     raised. This prevents noise or an unsteady hand from being read as a
%     deliberate input.

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
