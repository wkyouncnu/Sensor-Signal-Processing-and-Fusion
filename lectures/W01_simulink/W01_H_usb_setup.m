function W01_H_usb_setup(id)
%W01_H_USB_SETUP  실물 조종기의 스로틀 축 · 러더 축과 그 방향을 찾아 W01_rc_usb.slx 에 적는다.
%
%   >> W01_H_usb_setup        % 조이스틱 1 번
%   >> W01_H_usb_setup(2)     % PC 에 조이스틱이 둘 이상이면 번호를 준다
%
%   모델 캔버스의 CALIBRATE 버튼도 이것을 부른다. 조종기마다 한 번이면 된다.
%
%   무엇을 하는가
%     조종기는 USB 로 붙으면 채널을 축(axis)으로 보낸다. 몇 번 축이 스로틀인지,
%     앞으로 밀면 + 인지 - 인지는 조종기와 채널 순서 설정(AETR, TAER …)마다 다르다.
%     그래서 창을 세 번 띄워 하나씩 묻는다.
%       1. 모든 스틱을 가운데에                    -> 기준값
%       2. 스로틀을 끝까지 앞으로                  -> 가장 많이 변한 축 = 스로틀, 변한 부호 = 방향
%       3. 스로틀은 가운데, 러더를 끝까지 오른쪽으로 -> 러더 축과 방향
%     찾은 값 js_thr, js_rud, js_sgn 을 모델 작업공간에 넣고 모델을 저장한다.
%
%   모드(Mode 1, 2)는 조종기 안에서 이미 적용되어 온다. 그래서 여기서 묻는 것은
%   "어느 손" 이 아니라 "어느 채널" 이다.

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
