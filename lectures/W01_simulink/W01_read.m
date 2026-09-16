function y = W01_read(o)
%W01_READ  이번 주의 로그를 이름 붙은 필드로 바꾸고, 각도를 도 단위로 맞춘다.
%          Convert this week's log into named fields, with the angles in degrees.
%
%   y = W01_read(run_sim('W01_openloop', V))
%   plot(y.t, y.psi)
%
%   왜 열 이름만 붙이지 않고 변환까지 하는가
%   why a conversion and not merely column names
%       add_measurement 은 이 강의 전체가 공유하는 규약
%
%           [u v r N E psi | ...]
%
%       에 따라 로그를 남기되, 단위는 모델이 쓰는 그대로이다. psi 는
%       add_measurement 이 이미 도로 바꾸어 주지만 r 은 rad/s 로 남는다.
%       otter.m 이 라디안으로 계산하기 때문이다. 1주차는 처음부터 끝까지 도로
%       읽으므로, 그 변환을 이 한 곳에서 한 번만 한다. 변환이 여러 곳에 흩어지면
%       그림마다 단위가 달라질 수 있다.
%
%       add_measurement logs the contract shared by the whole course in the
%       units the model itself works in: psi has already been converted to
%       degrees, but r remains in rad/s because otter.m computes in radians.
%       Week 1 is read in degrees throughout, so the conversion is done once,
%       here. Scattered across several scripts it would eventually let two
%       figures disagree.
%
%   조류 모델의 추가 열 / the extra columns of the current model
%       조류 모델은 자기 몫의 네 열을 덧붙인다. 그 열들은 그 모델이 남긴 로그에만
%       있으므로 필드도 그때만 생긴다. 따라서 개루프 실행 결과에서 y.u_r 을 찾으면
%       잘못된 값이 아니라 분명한 오류가 난다.
%       The current model appends four columns of its own. They exist only in
%       logs that model produced, so the corresponding fields appear only
%       then, and asking for y.u_r after an open-loop run raises a clear error
%       rather than returning a wrong number.

y.u   = o.y(:,1);                % surge velocity, over ground   [m/s]
y.v   = o.y(:,2);                % sway velocity,  over ground   [m/s]
y.r   = rad2deg(o.y(:,3));       % yaw rate                      [deg/s]  <- converted
y.N   = o.y(:,4);                % north position                [m]
y.E   = o.y(:,5);                % east position                 [m]
y.psi = o.y(:,6);                % heading                       [deg]    already degrees
y.t   = o.t;

%  The crab angle is the whole point of Week 1's track figure, so it is
%  computed here rather than in three separate scripts.
y.beta = atan2d(y.v, y.u);       % crab angle  beta = atan2(v, u)  [deg]
y.chi  = y.psi + y.beta;         % course over ground              [deg]

%  The heading is read straight from the log, which does not wrap it: otter.m
%  integrates psi and a vessel that turns twice reaches 720 deg. Every figure
%  that shows psi as a compass bearing wraps it, and does so with this one
%  expression so that no two of them disagree at the boundary.
%
%      psi_wrapped = mod(psi + 180, 360) - 180      ->  (-180, 180]
%
%  Exactly 180 deg maps to -180 deg. That is the only point where the two
%  forms differ, and it is why the unwrapped y.psi is kept as well: a turn
%  rate computed by differencing the WRAPPED angle has a spurious 360 deg
%  jump in it, so anything differentiated must use y.psi and not y.psi_w.
y.psi_w = mod(y.psi + 180, 360) - 180;             % heading, wrapped [deg]

%  The two shaft speeds, present whenever the model logged its own input.
%  The open-loop model logs 8 columns, the current model 12; in both the
%  command occupies 7 and 8, so the test is on the columns being there at
%  all and not on the total width.
if size(o.y, 2) >= 8
    y.nL = o.y(:,7);             % port propeller command           [rad/s]
    y.nR = o.y(:,8);             % starboard propeller command      [rad/s]
end

if size(o.y, 2) >= 12
    y.u_c = o.y(:,9);            % current, surge component in {b}   [m/s]
    y.v_c = o.y(:,10);           % current, sway  component in {b}   [m/s]
    y.u_r = o.y(:,11);           % relative surge, u - u_c           [m/s]
    y.v_r = o.y(:,12);           % relative sway,  v - v_c           [m/s]
end
end
