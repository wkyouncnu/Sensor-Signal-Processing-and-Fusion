function W01rc_control(action, m)
%W01RC_CONTROL  W01_rc.slx 와 W01_rc_usb.slx 의 캔버스 버튼이 부르는 함수.
%               The function called by the canvas buttons of W01_rc.slx and
%               W01_rc_usb.slx.
%
%   W01rc_control('start')                 W01_rc : 스틱을 모두 가운데로 두고 시작
%                                          centre every stick, then start
%   W01rc_control('stop')                  멈춘다 / stop
%   W01rc_control('centre')                W01_rc : 스로틀을 뺀 스틱을 가운데로
%                                          centre every stick except the throttle
%   W01rc_control('start', 'W01_rc_usb')   실물 조종기 : 스로틀이 가운데인지 확인하고 시작
%                                          with a real transmitter: check the
%                                          throttle is centred, then start
%   W01rc_control('stop',  'W01_rc_usb')
%
%   손으로 부를 일은 없다. 모델 캔버스의 버튼이 부른다.
%   There is no reason to call it by hand; the buttons on the model canvas do.
%
%   왜 START 가 스로틀을 확인하는가 / why START checks the throttle
%     실제 조종기도 전원을 켤 때 스로틀이 중립이 아니면 출발하지 않는다. 이른바
%     스로틀 체크이며, 안전 장치이다. 이 모델의 스로틀은 가운데가 정지이므로 배는
%     언제나 정지한 상태에서 출발해야 한다.
%       W01_rc      화면 슬라이더이므로 START 가 네 채널을 모두 50 으로 되돌린다
%       W01_rc_usb  실물 스틱은 코드로 옮길 수 없으므로, 가운데가 아니면 시작하지
%                   않고 창으로 알린다. 조종기가 연결되어 있지 않을 때도 같다
%
%     A real transmitter refuses to arm if the throttle is not at neutral when
%     it is switched on. This is the throttle check, and it is a safety
%     interlock. Here the throttle centre is stop, so the vessel must always
%     start from rest. For W01_rc the sticks are on-screen sliders, so START
%     simply returns all four channels to 50. For W01_rc_usb a physical stick
%     cannot be moved by code, so the run is refused and a message is shown,
%     as it is when no transmitter is attached at all.
%
%   왜 CENTRE 가 필요한가 (W01_rc 에만 있다) / why CENTRE exists, and only in W01_rc
%     실제 조종기의 스틱은 손을 떼면 스프링이 가운데로 되돌린다. 스로틀 축만
%     예외이다. Dashboard 슬라이더에는 스프링이 없으므로 CENTRE 가 그 역할을 한다.
%     실물 조종기에는 스프링이 있으므로 W01_rc_usb 에는 이 버튼이 없다.
%
%     The sticks of a real transmitter are returned to centre by springs when
%     released, the throttle axis being the exception. Dashboard sliders have
%     no springs, so CENTRE does their work. W01_rc_usb has real springs and
%     therefore no such button.

if nargin < 2, m = 'W01_rc'; end
if ~bdIsLoaded(m), return; end
usb = strcmp(m, 'W01_rc_usb');
tx  = [m '/RC transmitter/'];
ch  = {'LX','LY','RX','RY'};

switch lower(action)
    case 'start'
        if usb && ~throttle_check(m), return; end
        if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
            set_param(m, 'SimulationCommand', 'stop');
            t0 = tic;                                   % 완전히 멈출 때까지 기다린다
            while ~strcmp(get_param(m, 'SimulationStatus'), 'stopped') && toc(t0) < 5
                pause(0.05);
            end
        end
        if ~usb
            for k = 1:4, set_param([tx ch{k}], 'Value', '50'); end
        end
        ss = get(groot, 'ScreenSize');                  % 모델은 왼쪽 절반, 그래프는 오른쪽 절반
        set_param(m, 'Location', [0 40 round(0.5*ss(3)) ss(4)-60]);
        set_param(m, 'ZoomFactor', 'FitSystem');
        set_param(m, 'SimulationCommand', 'start');

    case 'stop'
        if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
            set_param(m, 'SimulationCommand', 'stop');
        end

    case 'centre'
        if usb, return; end
        if str2double(get_param([tx 'mode'], 'Value')) == 1
            thr = 'RY';
        else
            thr = 'LY';
        end
        for k = 1:4
            if ~strcmp(ch{k}, thr), set_param([tx ch{k}], 'Value', '50'); end
        end
end
end

% -------------------------------------------------------------------------
function ok = throttle_check(m)
%  실물 조종기가 붙어 있고 스로틀이 가운데(편각 10 % 이내)인지 본다.
ttl = 'W01  USB transmitter';
mw  = get_param(m, 'ModelWorkspace');
id  = str2double(get_param([m '/RC transmitter/Joystick Input'], 'joyid'));
try
    j = vrjoystick(id);
catch e
    errordlg({sprintf('No transmitter on joystick %d:', id), e.message, '', ...
              'Connect it by USB in its USB joystick (HID) mode, then click START again.'}, ttl);
    ok = false;
    return
end
a = read(j);
close(j);
k = mw.getVariable('js_thr');
g = mw.getVariable('js_sgn');
if k > numel(a)
    errordlg(sprintf('The transmitter has %d axes but the throttle is set to axis %d. Click CALIBRATE.', ...
             numel(a), k), ttl);
    ok = false;
    return
end
s  = g(1) * a(k);
ok = abs(s) <= 0.1;
if ~ok
    errordlg(sprintf(['Throttle is not at the centre (%+.0f %% of travel).\n' ...
                      'Centre the throttle stick, then click START.'], 100*s), ttl);
end
end
