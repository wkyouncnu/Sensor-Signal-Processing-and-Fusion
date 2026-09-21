function R = W02_read(o)
%W02_READ  W02_pid.slx 의 로그를 이름 붙은 필드로 나눈다.
%          Split the log of W02_pid.slx into named fields.
%
%   R = W02_read(run_sim('W02_pid', V))
%
%   왜 필요한가 / why this exists
%       로그는 아홉 열짜리 행렬 하나이다. 절 스크립트마다 "셋째 열이 무엇이었지"
%       를 세면 언젠가 하나가 틀리고, 틀린 열은 그럴듯한 곡선을 그리므로 잘
%       드러나지 않는다. 열 번호는 여기 한 곳에만 둔다.
%
%       The log is a single matrix of nine columns. If every section script
%       counts columns for itself, one of them will eventually be wrong, and a
%       wrong column still draws a plausible curve. The column numbers live
%       here and nowhere else.
%
%   열 / columns (the order of the Mux in Measurements)
%       1  y_d        목표 위치 / setpoint                               [m]
%       2  tau_blk    PID 블록 줄의 힘 / force, PID block row             [N]
%       3  tau        손으로 만든 줄의 힘 / force, hand-built row         [N]
%       4  y_blk      PID 블록 줄의 위치 / position, PID block row        [m]
%       5  y          손으로 만든 줄의 위치 / position, hand-built row    [m]
%       6  I          손으로 만든 줄의 적분항 / its integral term         [N]
%       7  D          손으로 만든 줄의 미분항 / its derivative term       [N]
%       8  y_m_blk    PID 블록 줄이 받는 측정값 / measurement, PID block row [m]
%       9  y_m        손으로 만든 줄이 받는 측정값 (위치 + 잡음)
%                     measurement, hand-built row: position plus noise    [m]

R.t       = o.t;
R.y_d     = o.y(:,1);
R.tau_blk = o.y(:,2);
R.tau     = o.y(:,3);
R.y_blk   = o.y(:,4);
R.y       = o.y(:,5);
R.I       = o.y(:,6);
R.D       = o.y(:,7);
R.y_m_blk = o.y(:,8);
R.y_m     = o.y(:,9);
end
