function c = W02_cols()
%W02_COLS  이번 주 로그의 열에 이름을 붙인다. 적분기 상태가 "열 번째 열" 이라는
%          것을 어느 스크립트도 외우지 않게 하려는 것이다.
%          Names for the columns of this week's log, so that no script has to
%          remember that the integrator state is "column ten".
%
%   c = W02_cols;
%   plot(R.t, R.y(:, c.u))
%
%   열의 순서 / the order of the columns
%       add_measurement 은 언제나 이 강의가 공유하는 여섯 열을 먼저 기록하고,
%       그 뒤에 이번 주가 요청한 열들을 요청한 순서대로 붙인다.
%       add_measurement always logs the six course-wide columns first, then
%       this week's extras in the order the builder asked for them:
%
%       add_measurement(m, P.measurement, 'W02', {'u_d','X_cmd','X_sat','I','n1'})
%
%   그 목록이 바뀌면 이 함수만 고친다. 열 번호가 흩어져 있으면 목록을 바꿀 때마다
%   어느 스크립트가 깨졌는지 찾아다녀야 한다.
%   If that list changes, change this function and nothing else. With column
%   numbers scattered through the scripts, every change to the list would mean
%   hunting for whatever it broke.

c.u     =  1;   % surge velocity          [m/s]   <- the controlled variable
c.v     =  2;   % sway velocity           [m/s]   structurally zero this week
c.r     =  3;   % yaw rate                [rad/s] zero, nothing steers
c.N     =  4;   % north position          [m]
c.E     =  5;   % east position           [m]
c.psi   =  6;   % heading                 [deg]
c.u_d   =  7;   % speed command           [m/s]
c.X_cmd =  8;   % force the controller ASKED for   [N]
c.X_sat =  9;   % force the propellers GAVE        [N]
c.I     = 10;   % integrator state        [N]      the state windup lives in
c.n1    = 11;   % left propeller speed    [rad/s]
end
