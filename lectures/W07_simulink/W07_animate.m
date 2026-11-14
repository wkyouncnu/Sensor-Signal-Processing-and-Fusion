function W07_animate(u, v, r, N, E, psi, t)
%W07_ANIMATE  모델이 도는 동안 선체와 상태량과 궤적을 실시간으로 그린다.
%             Draw the vessel, its states and its track while the model runs.
%
%   W07_openloop.slx 안의 Animate 블록이 매 스텝 부른다. 손으로 부를 일은 없다.
%   실시간 화면의 내용을 바꾸려면 이 파일이 아니라 `_tools/live_dash.m` 을 고친다 —
%   그 파일은 이 강의의 모든 주차가 함께 쓴다.
%
%   입력은 `otter_tilt4` 가 쓰는 단위 그대로다. 단위 변환은 live_dash 안에서 한
%   번만 일어나므로 두 그림의 단위가 어긋날 수 없다.
%     u, v   전후·좌우 속도 [m/s]
%     r      요 각속도 [rad/s], 화면에는 deg/s 로 그린다
%     N, E   NED 위치 [m]
%     psi    선수방위 [rad], 화면에는 도로 접어서 그린다
%     t      시뮬레이션 시간 [s]
%
%   축 범위와 다시 그리는 간격은 기본 작업공간에서 읽는다. 1단계의 여섯 경우는
%   가는 방향이 제각각이므로(앞·옆·비스듬) 범위가 1주차보다 넓다.
%
%   See also LIVE_DASH, W07_0_SETUP, W07_PLOT.

o.tag   = 'W07';
o.name  = 'W07 live dashboard';
o.title = 'track   (bow = triangle, stern = square)';
o.lim   = [base_var('track_Emin', -60), base_var('track_Emax', 140), ...
           base_var('track_Nmin', -60), base_var('track_Nmax', 140)];
o.every = base_var('animate_every', 0.5);

live_dash(u, v, r, N, E, psi, t, o);
end
