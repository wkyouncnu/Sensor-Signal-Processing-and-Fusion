function W01i_control(action)
%W01I_CONTROL  W01_interactive.slx 의 START · STOP 버튼이 부르는 함수.
%              The function called by the START and STOP buttons of
%              W01_interactive.slx.
%
%   W01i_control('start')   처음부터 다시 시작한다. 돌고 있으면 먼저 멈춘다
%                           restart from the beginning, stopping first if running
%   W01i_control('stop')    멈춘다 / stop
%
%   손으로 부를 일은 없다. 모델 캔버스의 두 버튼이 부른다.
%   There is no reason to call it by hand; the two buttons on the model canvas
%   call it.
%
%   왜 START 가 "처음부터" 인가 / why START means "from the beginning"
%     Simulink 는 Stop 뒤에 Run 을 누르면 t = 0 과 초기 상태 x0 = 0 에서 다시
%     시작한다. 배는 원점으로 돌아가고 궤적은 빈 화면이 된다. 이 버튼은 멈춤과
%     시작의 두 동작을 한 번에 한다. 도중에 잠시 세웠다가 이어 가려면 툴스트립의
%     Pause 와 Continue 를 쓴다. 그때는 초기화되지 않는다.
%
%     Pressing Run after Stop makes Simulink restart at t = 0 with the initial
%     state x0 = 0, so the vessel returns to the origin and the track window is
%     cleared. This button performs both actions, stop and start, at once. To
%     interrupt a run and resume it, the Pause and Continue commands on the
%     toolstrip are used instead; those do not reset anything.
%
%   왜 창 위치를 정하는가 / why the window position is set
%     버튼은 모델 창에 있고 그래프는 따로 뜬 창에 있다. 둘이 겹치면 버튼을 누를
%     때마다 모델 창이 앞으로 나와 그래프를 가린다. 그래서 모델 창을 화면 왼쪽
%     절반에 두고, 실시간 화면은 W01i_animate 가 오른쪽 절반에 둔다.
%
%     The buttons are on the model window and the plots are in a separate one.
%     Overlapping, the model window would come to the front at every button
%     press and hide the plots, so the model is placed on the left half of the
%     screen and W01i_animate places the live view on the right.

m = 'W01_interactive';
if ~bdIsLoaded(m), return; end

switch lower(action)
    case 'start'
        if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
            set_param(m, 'SimulationCommand', 'stop');
            t0 = tic;                                   % 완전히 멈출 때까지 기다린다
            while ~strcmp(get_param(m, 'SimulationStatus'), 'stopped') && toc(t0) < 5
                pause(0.05);
            end
        end
        ss = get(groot, 'ScreenSize');                  % [1 1 폭 높이]
        set_param(m, 'Location', [0 40 round(0.5*ss(3)) ss(4)-60]);   % [왼 위 오른 아래]
        set_param(m, 'ZoomFactor', 'FitSystem');
        set_param(m, 'SimulationCommand', 'start');

    case 'stop'
        if ~strcmp(get_param(m, 'SimulationStatus'), 'stopped')
            set_param(m, 'SimulationCommand', 'stop');
        end
end
end
