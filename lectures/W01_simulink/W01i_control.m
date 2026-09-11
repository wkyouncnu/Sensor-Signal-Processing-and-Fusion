function W01i_control(action)
%W01I_CONTROL  W01_interactive.slx 의 START · STOP 버튼이 부르는 함수.
%
%   W01i_control('start')   처음부터 다시 시작한다 — 돌고 있으면 먼저 멈춘다
%   W01i_control('stop')    멈춘다
%
%   손으로 부를 일은 없다. 모델 캔버스의 두 버튼이 부른다.
%
%   왜 START 가 "처음부터" 인가
%     Simulink 는 Stop 뒤에 Run 을 누르면 t = 0, 초기 상태 x0 = 0 에서 다시
%     시작한다. 그래서 배는 원점으로, 궤적은 빈 화면으로 돌아간다. 이 버튼은
%     그 두 동작(멈춤 → 시작)을 한 번에 한다. 도중에 잠시 세우고 이어 가려면
%     툴스트립의 Pause / Continue 를 쓴다 — 그때는 초기화되지 않는다.
%
%   왜 창 위치를 정하는가
%     버튼은 모델 창에 있고 그래프는 따로 뜬 창에 있다. 둘이 겹치면 버튼을
%     누를 때마다 모델 창이 앞으로 나와 그래프를 가린다. 그래서 모델은 화면
%     왼쪽 절반, 실시간 화면은 오른쪽 절반에 둔다 (오른쪽은 W01i_animate 가 둔다).

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
