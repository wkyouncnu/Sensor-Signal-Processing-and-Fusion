function W04_animate(u, v, r, N, E, psi, t)
%W04_ANIMATE  W04_heading_control.slx 의 실시간 화면.
%             Live view for W04_heading_control.slx.
%
%   Measurements 안의 Animate 블록이 매 스텝 부른다. 실제로 그리는 일은 이 강의의
%   모든 주차가 함께 쓰는 _tools/live_dash.m 이 한다.
%   Called at every step by the Animate block inside Measurements. The drawing
%   itself is done by _tools/live_dash.m, shared by every week of this course.
%
%   입력은 otter.m 이 쓰는 단위 그대로이다 — psi 는 rad, r 은 rad/s 이며, 도
%   단위로의 변환은 live_dash 안에서 한 번만 일어난다.
%   The inputs are in the units otter.m works in, psi in rad and r in rad/s,
%   with the conversion to degrees happening once inside live_dash.
%
%   무엇을 보라는 것인가 / what to watch
%       선체에서 뻗어 나가는 점선이 명령한 선수방위이다. 실선으로 그린 실제
%       선수방위가 그 점선 위로 돌아 올라가는 것을 지켜보는 것이 이번 주의
%       전부이며, 오른쪽의 psi 칸이 같은 일을 시간 축 위에서 보여 준다. 볼 것은
%       오버슛의 크기, 정착까지 걸리는 시간, 그리고 두 번의 계단 명령이 양쪽
%       방향에서 똑같이 처리되는지이다.
%
%       The dashed ray leaving the hull is the commanded heading. Watching the
%       solid heading line swing onto the dashed one is the whole of this week,
%       and the psi panel on the right shows the same thing against time: the
%       overshoot, the settling, and whether the two step commands are answered
%       the same way in both directions.

o.tag   = 'W04';
o.name  = 'W04 live dashboard — heading control';
o.title = 'W04 heading control   (solid = heading, dashed = commanded)';
o.lim   = [base_var('track_Emin', -25), base_var('track_Emax', 25), ...
           base_var('track_Nmin', -10), base_var('track_Nmax', 40)];
o.every = base_var('animate_every', 0.5);

%  The commanded heading is rebuilt here from the setup variables rather than
%  passed in, so the Animate block keeps the port list every week uses.
t_up = base_var('t_up', 0);   t_dn = base_var('t_dn', inf);
p1   = base_var('psi_1', 0);  p2   = base_var('psi_2', 0);
if     t < t_up, o.psi_d = 0;
elseif t < t_dn, o.psi_d = deg2rad(p1);
else,            o.psi_d = deg2rad(p2);
end

live_dash(u, v, r, N, E, psi, t, o);
end
