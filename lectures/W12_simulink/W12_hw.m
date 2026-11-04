function H = W12_hw(B, f, cfg)
%W12_HW  배분된 여덟 성분 f 를 **하드웨어가 받는 여덟 숫자**로 바꾼다.
%        Turns the eight allocated components f into the eight numbers the
%        hardware actually receives.
%
%  H = W12_HW(B, f, cfg)
%
%  f    8x1   [f_x1 f_y1 f_x2 f_y2 f_x3 f_y3 f_x4 f_y4]  단위축 성분 [N]
%                                                        unit-axis components
%  cfg        otter_config('quad_tilt')
%
%  H.T      1x4  축방향 추력 [N], 부호 있음 (음수 = 역추진)
%                axial thrust [N], signed (negative = astern)
%  H.delta  1x4  서보 각 [rad] / servo angle [rad]
%  H.n      1x4  축 회전수 [rad/s] — 추력 곡선의 역
%                shaft speed [rad/s], the inverse of the thrust curve
%  H.rho    1x1  추력 한계에 맞추려고 전체에 곱한 비율 (1 = 안 줄였다)
%                the factor applied to the whole of f to meet the thrust cap
%                (1 means nothing was reduced)
%  H.tau    3x1  **실제로 나오는** tau = B * (rho*f)
%                the tau that is actually produced
%  H.hit    1x4  그 단위가 서보 벽에 닿았는가 / did that unit reach the wall
%
%  두 한계가 서로 다르게 작용한다 — 강의 §12-10.
%  The two limits act differently, which is the point of 12-10.
%    서보 벽  |delta| <= alpha_max 는 **방향**을 바꾼다. 그래서 배분 안에서 푼다
%      the servo wall changes the DIRECTION, so it has to be solved inside the
%      allocation itself
%    추력 한계 |T| <= k n_max^2 는 **크기**만 바꾼다. f 를 한 번 곱해 끝낸다
%      (B 가 선형이므로 rho*f 는 rho*tau 를 낸다 — tau 의 방향이 보존된다)
%      the thrust cap changes only the MAGNITUDE, so one scaling of f settles
%      it: B is linear, so rho*f gives rho*tau and the direction of tau is kept

T  = zeros(1,4);  de = zeros(1,4);
for i = 1:4
    fx = f(2*i-1);  fy = f(2*i);
    s  = sign(fx);  if s == 0, s = 1; end
    T(i)  = s * hypot(fx, fy);
    de(i) = atan2(s*fy, s*fx);
end

H.hit = abs(abs(de) - cfg.alpha_max(:)') < 1e-6;

% 추력 한계 — 전진과 후진이 다르다 (k_pos ~= k_neg)
% the thrust cap: ahead and astern are not the same, because k_pos ~= k_neg
Tlim = (T >= 0) .* (cfg.k_pos*cfg.n_max^2) + (T < 0) .* (cfg.k_neg*cfg.n_min^2);
H.rho = min([1, Tlim ./ max(abs(T), eps)]);

Tr = H.rho * T;
k  = (Tr >= 0)*cfg.k_pos + (Tr < 0)*cfg.k_neg;

H.T     = Tr;
H.delta = de;
H.n     = sign(Tr) .* sqrt(abs(Tr) ./ k);
H.tau   = B * (H.rho * f(:));
end
