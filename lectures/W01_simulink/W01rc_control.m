function W01rc_control(action, m)
%W01RC_CONTROL  W01_rc.slx · W01_rc_usb.slx 의 캔버스 버튼이 부르는 함수.
%
%   W01rc_control('start')                 W01_rc : 스틱을 모두 가운데로 두고 처음부터 시작
%   W01rc_control('stop')                  멈춘다
%   W01rc_control('centre')                W01_rc : 스로틀을 뺀 스틱을 가운데로
%   W01rc_control('start', 'W01_rc_usb')   실물 조종기 : 스로틀이 가운데인지 보고 시작
%   W01rc_control('stop',  'W01_rc_usb')
%
%   손으로 부를 일은 없다. 모델 캔버스의 버튼이 부른다.
%
%   왜 START 가 스로틀을 보는가
%     실제 조종기도 켤 때 스로틀이 중립이 아니면 출발하지 않는다 (throttle check).
%     이 모델의 스로틀은 가운데가 정지이므로 배는 언제나 정지한 채 출발해야 한다.
%       W01_rc      화면 슬라이더라서 START 가 네 채널을 모두 50 으로 둔다
%       W01_rc_usb  실물 스틱은 코드로 옮길 수 없으므로, 가운데가 아니면 시작하지
%                   않고 창으로 알린다. 조종기가 없을 때도 창으로 알린다
%
%   왜 CENTRE 가 필요한가 (W01_rc 만)
%     실제 조종기의 스틱은 손을 떼면 스프링이 가운데로 되돌린다. 스로틀 축만
%     예외다. Dashboard 슬라이더에는 스프링이 없으므로 CENTRE 가 대신한다.
%     실물 조종기에는 스프링이 있으므로 W01_rc_usb 에는 CENTRE 가 없다.

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
