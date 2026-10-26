function [M, Minv] = otter_M(mp, rp)
%OTTER_M  Otter 의 6x6 질량행렬(강체 + 부가질량)을 otter.m 과 **같은 줄로** 다시 만든다.
%         Rebuild the Otter's 6x6 system inertia exactly as otter.m builds it.
%
%   [M, Minv] = otter_M()              이 강의가 쓰는 적재 (mp = 25 kg)
%   [M, Minv] = otter_M(mp, rp)        적재를 바꿀 때
%
%   왜 이 함수가 있는가 / why this exists
%       `otter.m` 은 추진기 **두 개**만 받는다 (2x1 축회전수). 선수추진기가 붙으면
%       횡력 Y 와 그에 딸린 모멘트가 생기는데, 그것을 `otter.m` 안으로 넣을 자리가
%       없다. 6주차는 그래서 **중첩**으로 더한다:
%
%           nu_dot = M \ (tau_prop + tau_damp + ... )          <- otter.m 이 계산한다
%           nu_dot = nu_dot + M \ tau_ext                      <- 여기서 더한다
%
%       `otter.m` 의 가속도는 tau 에 대해 **어파인**이므로 이 더하기는 근사가 아니다.
%       같은 상태 x 에서 감쇠·코리올리·복원은 똑같고, 바뀌는 것은 tau 뿐이다.
%       `add_otter_plant` 의 tau_ext 포트가 이 Minv 를 쓴다.
%
%       The Otter's hull function takes only the two stern propellers. A bow
%       thruster adds a sway force and its moment, and there is no argument to
%       pass them through. Week 6 therefore adds them by superposition: the
%       acceleration otter.m returns is affine in tau, so adding M\tau_ext is
%       exact, not an approximation - at the same state the damping, Coriolis
%       and restoring terms are identical and only tau differs.
%
%   왜 유한차분으로 재지 않는가 / why not finite differences
%       M 은 블록대각이 **아니다** — 무게중심이 원점에서 떨어져 있어 서지가 히브와
%       피치에 엮인다. 그래서 순수 서지 힘을 주고 가속도로 나누면 M(1,1) = 85.50 이
%       아니라 1/[inv(M)]_11 = 76.71 이 나온다. 10 % 가 틀리는데 수 자체에는
%       경고가 없다. `verify_constants.m` 의 같은 주석을 보라.
%
%   otter.m 의 55~120 행과 **보조를 맞춰야 한다.** MSS 가 그 줄을 바꾸면
%   `verify_constants` 가 먼저 알아차린다.

if nargin < 1 || isempty(mp), mp = 25;                 end
if nargin < 2 || isempty(rp), rp = [0.05 0 -0.35]';    end
mss_path();

%  ---- otter.m lines 55-120, reproduced --------------------------------
B   = 1.08;   L = 2.0;
m   = 55.0;   rg = [0.2 0 -0.2]';
R44 = 0.4*B;  R55 = 0.25*L;  R66 = 0.25*L;

Ig_CG = m * diag([R44^2, R55^2, R66^2]);
rg    = (m*rg + mp*rp)/(m + mp);
Ig    = Ig_CG - m*Smtrx(rg)^2 - mp*Smtrx(rp)^2;

MRB = Hmtrx(rg)' * [ (m+mp)*eye(3) zeros(3); zeros(3) Ig ] * Hmtrx(rg);

Xudot = -0.1*m;       Yvdot = -1.5*m;        Zwdot = -1.0*m;
Kpdot = -0.2*Ig(1,1); Mqdot = -0.8*Ig(2,2);  Nrdot = -1.7*Ig(3,3);

M    = MRB - diag([Xudot, Yvdot, Zwdot, Kpdot, Mqdot, Nrdot]);
Minv = inv(M);                                  %#ok<MINV>
end
