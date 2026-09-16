function W01_H_build_rc_usb()
%W01_H_BUILD_RC_USB  실물 USB 조종기로 모는 모델 W01_rc_usb.slx 를 생성한다.
%                    Generate W01_rc_usb.slx, the same vessel driven by a real
%                    USB transmitter.
%
%   실행 / to run
%       W01_H_build_rc_usb
%
%   강의에서의 위치 / place in the lecture
%       Part 2 절 H 이다. 절 G 의 화면 조종기를 실물 조종기로 바꾸는 자리이며,
%       모델의 나머지를 하나도 바꾸지 않고 입력 장치만 교체할 수 있다는 것을
%       보이는 것이 목적이다.
%
%       This is section H of Part 2. The on-screen transmitter of section G is
%       replaced by a real one, and the point of the exercise is that the
%       input device can be exchanged without altering anything else.
%
%   어떻게 만드는가 / how it is built
%       W01_rc.slx 와 같은 빌더 W01_G_build_rc 를 'usb' 인자로 부른다. 달라지는
%       것은 맨 앞의 RC transmitter 블록 하나뿐이다.
%
%         절 G  화면 슬라이더 넷 + MODE 스위치 -> receiver -> Mode 1 또는 2 -> stick
%         절 H  Joystick Input (Simulink 3D Animation) -> USB receiver     -> stick
%
%       그 뒤의 Joystick, Control allocation, Otter USV, Measurements 는 한 줄도
%       다르지 않다. 그래서 두 모델은 같은 스틱 입력에 같은 배로 답하며,
%       W01_H_usb_check 가 그것을 확인한다.
%
%       The builder of W01_rc.slx, W01_G_build_rc, is called with the argument
%       'usb'. Only the RC transmitter block at the front differs; the
%       Joystick, Control allocation, Otter USV and Measurements stages behind
%       it are identical line for line. The two models therefore answer the
%       same stick input with the same vessel, which W01_H_usb_check verifies.
%
%   필요한 것 / what is required
%       Simulink 3D Animation, 그리고 USB 조이스틱(HID) 모드를 지원하는 조종기.
%       조종기가 없어도 모델은 만들어진다. 조종기를 요구하는 것은 실행(START)뿐이다.
%       Simulink 3D Animation, and a transmitter with a USB joystick (HID)
%       mode. The model can be built without a transmitter; only running it
%       requires one.
%
%   다시 생성하면 CALIBRATE 로 찾아 둔 축 설정이 기본값(AETR)으로 돌아간다.
%   Regenerating resets the axis assignment found by CALIBRATE to the default
%   AETR ordering.

W01_G_build_rc('usb');
end
