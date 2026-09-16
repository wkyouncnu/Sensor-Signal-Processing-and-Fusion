function W01c_animate(u, v, r, N, E, psi, t)
%W01C_ANIMATE  W01_current.slx 의 실시간 화면 — 조류 속의 개루프 운항.
%              Live view for W01_current.slx, the open loop in a current.
%
%   Measurements 안의 Animate 블록이 매 스텝 부른다. 실제로 그리는 일은 이 강의의
%   모든 주차가 함께 쓰는 _tools/live_dash.m 이 한다.
%   Called at every step by the Animate block inside Measurements. The drawing
%   itself is done by _tools/live_dash.m, shared by every week of this course.
%
%   무엇을 보라는 것인가 / what to watch
%       명령은 한 번도 바뀌지 않고 조향도 하지 않는데 궤적이 선수방위에서 벗어나
%       휘어진다. 궤적 위에 선체를 함께 그리는 이유가 바로 이것이다. 선수가
%       가리키는 방향과 배가 실제로 가는 방향 사이의 각이 표류이고, 그것은 선체에
%       작용한 힘 때문이 아니라 물이 움직이기 때문에 생긴다. 절 E 가 이 각을 잰다.
%
%       The command never changes and the vessel never steers, yet the track
%       bends away from the heading. The hull is drawn on the track for that
%       reason: the angle between where the bow points and where the vessel
%       goes is the drift, and it is produced by the water moving rather than
%       by any force on the hull. Section E measures it.
%
%   이력 / history
%       2026-09-08 까지 이 파일이 없었다. W01_E_build_current 는 처음부터
%       W01c_animate 를 부르는 Animate 블록을 만들었고 W01_0_setup 도 처음부터
%       animate = 1 로 두었으나, 정작 함수가 없었다. 그래서 W01_current.slx 를
%       열고 Run 을 누르면 정의되지 않은 함수 오류가 났다. 절 스크립트만 그것을
%       피했는데, 스윕 전에 animate = 0 으로 두기 때문이다. 4주차에도 같은 구멍이
%       있었다. 스크립트만 돌려 보고 모델을 열어 보지 않으면 놓치는 종류의 결함이다.
%
%       This wrapper did not exist until 2026-09-08. W01_E_build_current had
%       always created an Animate block calling W01c_animate, and W01_0_setup
%       had always set animate = 1, but the function itself was absent, so
%       opening W01_current.slx and pressing Run raised an undefined-function
%       error. Only the section script escaped it, because it sets animate = 0
%       before sweeping. Week 4 had the same hole. It is the kind of defect
%       that survives as long as the scripts are run but the model is not
%       opened.

o.tag   = 'W01c';
o.name  = 'W01 live dashboard — ocean current';
o.title = 'track in a current   (bow = triangle; the track leaves the heading)';
o.lim   = [base_var('track_Emin', -60), base_var('track_Emax', 60), ...
           base_var('track_Nmin', -10), base_var('track_Nmax', 140)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
