function W01_H_usb_setup(id)
%W01_H_USB_SETUP  실물 조종기의 스로틀 축과 러더 축, 그리고 그 방향을 찾아
%                 W01_rc_usb.slx 에 적어 둔다.
%                 Identify the throttle and rudder axes of a real transmitter,
%                 and their directions, and record them in W01_rc_usb.slx.
%
%   실행 / to run
%       W01_H_usb_setup        조이스틱 1 번 / the first joystick
%       W01_H_usb_setup(2)     조이스틱이 둘 이상이면 번호를 준다
%                              a number is given when more than one is attached
%
%       모델 캔버스의 CALIBRATE 버튼도 이것을 부른다. 조종기마다 한 번만 하면 된다.
%       The CALIBRATE button on the model canvas calls this as well. It needs
%       to be done once per transmitter.
%
%   강의에서의 위치 / place in the lecture
%       Part 2 절 H 의 준비 단계이다. 실물 장치를 붙일 때 가장 먼저 하는 일이
%       보정이라는 점을 보이는 자리이기도 하다.
%       This is the preparation step of section H of Part 2, and it also shows
%       that calibration is the first task when real hardware is attached.
%
%   무엇을 하는가 / what it does
%       조종기를 USB 로 연결하면 각 채널이 축(axis)으로 전달된다. 몇 번 축이
%       스로틀인지, 앞으로 밀었을 때 값이 커지는지 작아지는지는 조종기와 채널
%       순서 설정(AETR, TAER 등)에 따라 다르다. 그래서 창을 세 번 띄워 차례로 묻는다.
%         1. 모든 스틱을 가운데에             -> 기준값을 잡는다
%         2. 스로틀을 끝까지 앞으로           -> 가장 크게 변한 축이 스로틀이고,
%                                              변한 부호가 방향이다
%         3. 스로틀은 가운데, 러더를 오른쪽으로 -> 같은 방법으로 러더 축과 방향
%       찾아낸 js_thr, js_rud, js_sgn 을 모델 작업공간에 넣고 모델을 저장한다.
%
%       A transmitter connected over USB presents each channel as an axis.
%       Which axis carries the throttle, and whether pushing forward raises or
%       lowers its value, depends on the unit and on its channel order (AETR,
%       TAER and so on). Three prompts resolve this:
%         1. all sticks centred, to establish a reference;
%         2. throttle pushed fully forward — the axis that moves most is the
%            throttle, and the sign of the movement is its direction;
%         3. throttle centred and rudder pushed fully right, which identifies
%            the rudder axis and direction the same way.
%       The results js_thr, js_rud and js_sgn are written to the model
%       workspace and the model is saved.
%
%   모드 1 과 모드 2 의 구분은 조종기 안에서 이미 적용되어 들어온다. 따라서 여기서
%   묻는 것은 어느 손으로 조종하는지가 아니라 어느 채널이 무엇인지이다.
%   The distinction between Mode 1 and Mode 2 is applied inside the
%   transmitter itself, so what is asked here is which channel carries what,
%   not which hand holds which stick.

if nargin < 1, id = 1; end
m    = 'W01_rc_usb';
here = fileparts(mfilename('fullpath'));
ttl  = 'W01  USB transmitter';

try
    j = vrjoystick(id);
catch e
    errordlg({sprintf('Joystick %d could not be opened:', id), e.message, '', ...
              'Connect the transmitter by USB, select its USB joystick (HID) mode,', ...
              'and try again.'}, ttl);
    return
end
cleanup = onCleanup(@() close(j));

a0 = ask(j, ttl, 'Put EVERY stick at the centre, the throttle too. Then press OK.');
a1 = ask(j, ttl, 'Push the THROTTLE fully FORWARD (up) and hold it. Then press OK.');
a2 = ask(j, ttl, 'Throttle back to the centre. Push the RUDDER fully RIGHT and hold it. Then press OK.');
try
    [kt, st] = W01rc_usb_axis(a0, a1);
    [kr, sr] = W01rc_usb_axis(a0, a2, kt);
catch e
    errordlg({e.message, '', 'Run CALIBRATE again and hold each stick at its end.'}, ttl);
    return
end

if ~bdIsLoaded(m), load_system(fullfile(here, [m '.slx'])); end
if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
    errordlg('Stop the simulation first, then calibrate.', ttl);
    return
end
mw = get_param(m, 'ModelWorkspace');
assignin(mw, 'js_thr', kt);
assignin(mw, 'js_rud', kr);
assignin(mw, 'js_sgn', [st sr]);
set_param([m '/RC transmitter/Joystick Input'], 'joyid', num2str(id));
save_system(m);
msgbox(sprintf(['Throttle = axis %d, forward is %s.\nRudder = axis %d, right is %s.\n\n' ...
                'Saved in %s.slx.'], kt, sgn(st), kr, sgn(sr), m), ttl);
end

% -------------------------------------------------------------------------
function a = ask(j, ttl, txt)
%  창을 띄워 기다린 뒤, OK 를 누른 순간의 축 값을 읽는다.
uiwait(msgbox(txt, ttl, 'modal'));
a = read(j);
end

function s = sgn(x)
if x > 0, s = 'positive'; else, s = 'negative'; end
end
