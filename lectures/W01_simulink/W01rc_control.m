function W01rc_control(action)
%W01RC_CONTROL  W01_rc.slx 의 START · STOP · CENTRE 버튼이 부르는 함수.
%
%   W01rc_control('start')    스틱을 모두 가운데로 두고 처음부터 시작한다
%   W01rc_control('stop')     멈춘다
%   W01rc_control('centre')   스로틀을 뺀 스틱을 가운데로 — 손을 뗀 것과 같다
%
%   손으로 부를 일은 없다. 모델 캔버스의 세 버튼이 부른다.
%
%   왜 START 가 스틱을 가운데로 두는가
%     실제 조종기도 켤 때 스로틀이 중립이 아니면 출발하지 않는다 (throttle check).
%     이 모델의 스로틀은 가운데가 정지이므로, START 는 네 채널을 모두 50 으로 둔다.
%     그래서 배는 언제나 원점에서 정지한 채 출발한다.
%
%   왜 CENTRE 가 필요한가
%     실제 조종기의 스틱은 손을 떼면 스프링이 가운데로 되돌린다. 스로틀 축만
%     예외다 — 마찰판이 있어 놓은 자리에 남는다. Dashboard 슬라이더에는 스프링이
%     없으므로, CENTRE 가 스프링 대신 스로틀이 아닌 세 채널을 50 으로 되돌린다.
%     어느 채널이 스로틀인지는 모드가 정한다 (Mode 1 : RY, Mode 2 : LY).

m = 'W01_rc';
if ~bdIsLoaded(m), return; end
tx = [m '/RC transmitter/'];
ch = {'LX','LY','RX','RY'};

switch lower(action)
    case 'start'
        if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
            set_param(m, 'SimulationCommand', 'stop');
            t0 = tic;                                   % 완전히 멈출 때까지 기다린다
            while ~strcmp(get_param(m, 'SimulationStatus'), 'stopped') && toc(t0) < 5
                pause(0.05);
            end
        end
        for k = 1:4, set_param([tx ch{k}], 'Value', '50'); end
        ss = get(groot, 'ScreenSize');                  % 모델은 왼쪽 절반, 그래프는 오른쪽 절반
        set_param(m, 'Location', [0 40 round(0.5*ss(3)) ss(4)-60]);
        set_param(m, 'ZoomFactor', 'FitSystem');
        set_param(m, 'SimulationCommand', 'start');

    case 'stop'
        if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
            set_param(m, 'SimulationCommand', 'stop');
        end

    case 'centre'
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
