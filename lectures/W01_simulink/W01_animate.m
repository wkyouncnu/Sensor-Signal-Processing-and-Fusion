function W01_animate(u, v, r, N, E, psi, t)
%W01_ANIMATE  모델이 도는 동안 선체와 상태량과 궤적을 실시간으로 그린다.
%             Draw the vessel, its states and its track while the model runs.
%
%   W01_openloop.slx 안의 Animate 블록이 매 스텝 부른다. 손으로 부를 일은 없다.
%   실시간 화면의 내용을 바꾸려면 이 파일이 아니라 _tools/live_dash.m 을 고친다.
%   그 파일은 이 강의의 모든 주차가 함께 쓴다.
%
%   Called at every step by the Animate block inside W01_openloop.slx. There
%   is no reason to call it by hand. To change what the live view shows, edit
%   _tools/live_dash.m, which every week of this course shares.
%
%   입력 / inputs
%   otter.m 이 쓰는 단위 그대로 받는다. 단위 변환은 live_dash 안에서 한 번만
%   일어나므로 두 그림의 단위가 어긋날 수 없다.
%   The units are those otter.m works in; the conversion happens once, inside
%   live_dash, so no two figures can disagree.
%     u, v   전후·좌우 속도 [m/s] / surge and sway velocity [m/s]
%     r      요 각속도 [rad/s], 화면에는 deg/s 로 그린다
%            yaw rate [rad/s], drawn in deg/s
%     N, E   NED 좌표계에서의 위치 [m] / position in NED [m]
%     psi    선수방위 [rad], 북쪽에서 시계방향이 양. 화면에는 도로, (-180, 180]
%            범위로 접어서 그린다
%            heading [rad] from North, positive clockwise; drawn in degrees
%            and wrapped to (-180, 180]
%     t      시뮬레이션 시간 [s] / simulation time [s]
%
%   축 범위와 다시 그리는 간격은 기본 작업공간에서 읽는다. 따라서 보이는 창을
%   넓히려면 모델이 아니라 W01_0_setup 을 고친다.
%   The axis limits and the redraw interval are read from the base workspace,
%   so widening the window is an edit to W01_0_setup and not to the model.

o.tag   = 'W01';
o.name  = 'W01 live dashboard';
o.title = 'track   (bow = triangle, stern = square)';
o.lim   = [base_var('track_Emin', -80), base_var('track_Emax',  80), ...
           base_var('track_Nmin', -20), base_var('track_Nmax', 140)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
