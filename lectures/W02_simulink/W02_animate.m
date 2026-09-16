function W02_animate(u, v, r, N, E, psi, t)
%W02_ANIMATE  W02_surge_control.slx 의 실시간 화면.
%             Live view for W02_surge_control.slx.
%
%   모델의 Animate 블록이 매 스텝 부른다. 실제로 그리는 일은 이 강의의 모든
%   주차가 함께 쓰는 _tools/live_dash.m 이 한다.
%   Called at every step by the model's Animate block. The drawing itself is
%   done by _tools/live_dash.m, shared by every week of this course.
%
%   입력은 otter.m 이 쓰는 단위 그대로이다 — psi 는 rad, r 은 rad/s 이며,
%   도 단위로의 변환은 live_dash 안에서 한 번만 일어난다.
%   The inputs are in the units otter.m works in: psi in rad and r in rad/s,
%   with the conversion to degrees happening once, inside live_dash.
%
%   무엇을 보라는 것인가 / what to watch
%       이번 주에는 조향을 하지 않으므로 선박은 정북으로 달리고 선수방위는
%       움직이지 않는다. 그것이 요점이다. 이번에 닫는 고리는 속도 고리이고,
%       궤적은 고리를 닫는 일이 배가 어디를 향하는지가 아니라 얼마나 멀리
%       가는지를 바꾼다는 것을 보이기 위해 있다. 볼 것은 u 이며, 이번 주의
%       제어기가 움직일 수 있는 상태는 그것 하나뿐이다.
%
%       Nothing steers this week, so the vessel runs due north and the heading
%       never moves. That is the point: the loop being closed is the speed
%       loop, and the track is there to show that closing it changes how far
%       the vessel gets rather than where it points. The panel to watch is u,
%       the only state this week's controller can move.

o.tag   = 'W02';
o.name  = 'W02 live dashboard — surge speed control';
o.title = 'W02 surge speed control   (heading is not controlled this week)';
o.lim   = [base_var('track_Emin', -35), base_var('track_Emax', 35), ...
           base_var('track_Nmin',  -5), base_var('track_Nmax', 65)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
