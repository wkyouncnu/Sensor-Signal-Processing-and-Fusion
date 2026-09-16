function y = W03_read(o)
%W03_READ  이번 주의 로그를 이름 붙은 필드로 바꾸고, 각도를 도 단위로 맞춘다.
%          Convert this week's log into named fields, with the angles in degrees.
%
%   y = W03_read(run_sim('W03_heading_control', V))
%   plot(y.t, y.psi)
%
%   왜 열 이름만 붙이지 않고 변환까지 하는가
%   why a conversion and not merely column names
%       add_measurement 은 이 강의가 공유하는 규약
%
%           [u v r N E psi | psi_d tau_N n1 n2]
%
%       에 따라 기록하되 단위는 모델이 쓰는 그대로이다. psi 는 add_measurement 이
%       이미 도로 바꾸어 주지만 r 은 rad/s 이고 psi_d 는 라디안이다. otter.m 과
%       제어기가 라디안으로 계산하기 때문이다. 선수방위를 다루는 주차는 처음부터
%       끝까지 도로 읽으므로, 그 변환을 이 한 곳에서 한 번만 한다.
%
%       add_measurement logs the contract shared by the whole course in the
%       units the model itself works in: psi has been converted to degrees
%       already, but r is in rad/s and psi_d in radians, because otter.m and
%       the controller compute in radians. A week about heading is read in
%       degrees throughout, so the conversion happens once, here, and nowhere
%       else.
%
%   행렬을 재배열해 돌려주지 않고 구조체를 돌려주는 이유는, 스크립트가 y(:,2) 가
%   아니라 y.psi 라고 쓸 수 있게 하기 위해서다. 읽는 사람이 열을 세지 않아도 된다.
%   A struct is returned rather than a reordered matrix so that a script can
%   say y.psi instead of y(:,2), and a reader never has to count columns.

y.u     = o.y(:,1);              % surge velocity        [m/s]
y.v     = o.y(:,2);              % sway velocity         [m/s]
y.r     = rad2deg(o.y(:,3));     % yaw rate              [deg/s]  <- converted
y.N     = o.y(:,4);              % north position        [m]
y.E     = o.y(:,5);              % east position         [m]
y.psi   = o.y(:,6);              % heading               [deg]    already degrees
y.psi_d = rad2deg(o.y(:,7));     % heading command       [deg]    <- converted
y.tau_N = o.y(:,8);              % commanded yaw moment  [N m]
y.n1    = o.y(:,9);              % left propeller        [rad/s]
y.n2    = o.y(:,10);             % right propeller       [rad/s]
y.t     = o.t;
end
