function W01_H_build_rc_usb()
%W01_H_BUILD_RC_USB  W01_rc_usb.slx 를 만든다 — 실물 USB 조종기로 모는 W01_rc.
%
%   >> W01_H_build_rc_usb
%
%   W01_rc.slx (§G) 와 같은 빌더 W01_G_build_rc 를 'usb' 로 부른다. 다른 것은
%   맨 앞 RC transmitter 블록 하나뿐이다.
%
%     §G  화면 슬라이더 넷 + MODE 스위치 -> receiver -> Mode 1 or 2      -> stick
%     §H  Joystick Input (Simulink 3D Animation)  -> USB receiver       -> stick
%
%   그 뒤의 Joystick · Control allocation · Otter USV · Measurements 는 한 줄도
%   다르지 않다. 그래서 두 모델은 같은 스틱에 같은 배로 답한다 (W01_H_usb_check).
%
%   필요한 것 : Simulink 3D Animation, USB 조이스틱(HID) 모드가 있는 조종기.
%   조종기가 없어도 모델은 만들어진다. 실행(START)만 조종기를 요구한다.
%   다시 만들면 CALIBRATE 로 찾은 축 설정이 기본값(AETR)으로 돌아간다.

W01_G_build_rc('usb');
end
