function W01i_animate(u, v, r, N, E, psi, t)
%W01I_ANIMATE  W01_interactive.slx 의 실시간 화면. 궤적 창이 배를 따라간다.
%
%   W01_interactive.slx 의 Animate 블록이 매 스텝 부른다. 손으로 부를 일은 없다.
%
%   W01_animate 와 같은 _tools/live_dash.m 를 쓴다 — 왼쪽에 궤적과 선체,
%   오른쪽에 u, v, r, x, y, psi. 한 가지만 더한다.
%
%   왜 창이 따라가는가
%     W01_openloop 은 시간표를 따르므로 배가 어디까지 갈지 미리 안다. 그래서
%     축을 처음에 한 번 정하면 된다. 버튼으로 모는 배는 어디로 갈지 모른다.
%     그래서 배가 창의 가장자리에서 20 % 안쪽으로 들어오면 창을 배 쪽으로
%     옮긴다. 창의 크기는 바꾸지 않는다 — 축척이 바뀌면 선체 그림의 크기가
%     바뀌어 속도를 눈으로 가늠할 수 없게 된다.
%
%   INPUTS  otter.m 의 단위 그대로 (u, v [m/s], r [rad/s], N, E [m], psi [rad], t [s])

persistent tLast

W = 120;                                    % 궤적 창의 한 변 [m]
o.tag   = 'W01i';
o.name  = 'W01 drive it yourself';
o.title = 'track — drive it with the buttons   (bow = triangle)';
o.lim   = [-W/2 W/2 -W/3 2*W/3];            % 처음에는 북쪽을 넉넉히
o.every = 0.25;                             % 다시 그리는 간격 [시뮬레이션 초]

live_dash(u, v, r, N, E, psi, t, o);

%  창 옮기기도 다시 그리는 간격에 맞춘다. 매 스텝 찾으면 느려진다.
if ~isempty(tLast) && t >= tLast && t - tLast < o.every, return; end
tLast = t;

f = findall(0, 'Type','figure', 'Name', o.name);
if isempty(f), return; end
ax = findobj(f(1), 'Type','axes');
for k = 1:numel(ax)
    %  궤적 축은 x 축 이름이 'East  [m]' 인 하나뿐이다 (live_dash 가 그렇게 짓는다).
    if strcmp(get(get(ax(k),'XLabel'),'String'), 'East  [m]')
        xl = xlim(ax(k));   yl = ylim(ax(k));   edge = 0.2*W;
        if E < xl(1)+edge || E > xl(2)-edge, xlim(ax(k), E + [-W/2 W/2]); end
        if N < yl(1)+edge || N > yl(2)-edge, ylim(ax(k), N + [-W/2 W/2]); end
        break
    end
end
end
