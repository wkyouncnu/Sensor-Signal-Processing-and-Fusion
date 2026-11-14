function R = W07_chain(B, cfg, V, P, tau_cmd, method)
%W07_CHAIN  제어기 → 배분 → 하드웨어 → 운동모델. 요구한 힘과 **배가 실제로 받은
%           힘**을 나란히 돌려준다.
%           Controller to allocator to hardware to motion model. Returns the
%           demanded force and the force the hull ACTUALLY received, side by side.
%
%  R = W07_CHAIN(B, cfg, V, P, tau_cmd, method)
%
%  쇠사슬의 고리 다섯 / the five links of the chain
%      ① tau_cmd      제어기가 내놓은 [X;Y;N]. 이 함수는 그것을 그대로 받는다
%                     what the controller asked for; taken as given here
%      ② f = alloc    배분기가 여덟 성분으로 쪼갠다          `W07_alloc`
%                     the allocator splits it into eight components
%      ③ (T, delta)   단위마다 크기와 각으로 되돌린다
%                     turned back into a magnitude and an angle per unit
%      ④ n            추력곡선을 거꾸로 풀어 회전수로        n = sign(T) sqrt(|T|/k)
%                     the thrust curve inverted into a shaft speed
%      ⑤ tau_act      **운동모델이 실제로 만든 힘.** 여기서 포화가 일어난다
%                     the force the motion model actually produced
%
%  왜 ⑤ 를 재야 하는가 / why link 5 has to be measured, not assumed
%      `otter_tilt4` 는 받은 n 과 delta 를 **스스로 깎는다** — n 을
%      [n_min, n_max] 으로, delta 를 ±alpha_max 으로. 그래서 배분기가 낸 답이
%      한계를 넘으면 배는 **요구와 다른 힘**을 받고, 그 차이는 배분기의 장부에
%      적히지 않는다. 그 차이를 보려면 운동모델에서 직접 재야 한다.
%      otter_tilt4 clips what it is given: n into [n_min, n_max] and delta onto
%      +-alpha_max. If the allocator's answer is outside the limits the hull gets
%      a DIFFERENT force from the one demanded, and nothing in the allocator's
%      own bookkeeping shows it. Measuring it means measuring the model.
%
%  어떻게 재는가 / how it is measured
%      `otter_tilt4` 는 tau 를 돌려주지 않고 가속도만 돌려준다. 그래서 같은
%      상태에서 두 번 부른다 — 추진기를 켜고 한 번, n = 0 으로 한 번 — 그 차이에
%      질량행렬을 곱하면 추진기가 만든 tau 다. 7주차가 §7-2 에서 이미 이 방법으로
%      손 수식을 검증했다 (`W07_tab_formula`).
%          tau = M (xdot|_on - xdot|_off)
%      otter_tilt4 returns accelerations, not tau, so it is called twice in the
%      same state: once with the thrusters on and once with n = 0. The difference
%      times the mass matrix is the thruster tau. Week 7 already verified the
%      hand formula this way in 7-2.
%
%  돌려주는 것 / what comes back  (각 행이 한 성분, 각 열이 한 시각)
%      R.t        시각 [s]
%      R.cmd      요구한 tau   3 x K   / the demanded tau
%      R.act      실제 tau     3 x K   / the tau the hull received
%      R.n_cmd    배분기가 요구한 회전수  4 x K  / the shaft speed demanded
%      R.n_act    운동모델이 쓴 회전수    4 x K  / the shaft speed actually used
%      R.d_cmd    배분기가 요구한 서보각 [rad] 4 x K
%      R.d_act    운동모델이 쓴 서보각   [rad] 4 x K
%      R.T        단위별 추력 [N]        4 x K  / the per-unit thrust
%      R.sat_n    회전수가 깎인 단위 (논리) 4 x K / where the shaft speed was clipped
%      R.sat_d    서보각이 깎인 단위 (논리) 4 x K / where the servo angle was clipped
%      R.exit     배분기의 exitflag      1 x K
%      R.method   쓴 법칙의 이름
%
%  See also W07_ALLOC, W07_HW, W07_PLOT_CHAIN, W07_CA, W07_TAB_FORMULA.

K  = size(tau_cmd, 2);
Mm = otter_M(V.mp, V.rp);
x0 = V.x0;

R.t      = [];
R.method = method;
R.cmd    = tau_cmd;
R.act    = zeros(3, K);
R.n_cmd  = zeros(4, K);   R.n_act = zeros(4, K);
R.d_cmd  = zeros(4, K);   R.d_act = zeros(4, K);
R.T      = zeros(4, K);   R.exit  = zeros(1, K);
R.sat_n  = false(4, K);   R.sat_d = false(4, K);

for k = 1:K
    % ② 배분 / allocate
    [f, in] = W07_alloc(B, tau_cmd(:,k), method, P);
    R.exit(k) = in.exit;

    % ③ 크기와 각 / magnitude and angle, per unit
    fx = f(1:2:end);  fy = f(2:2:end);
    s  = sign(fx);  s(s == 0) = 1;
    T  = s .* hypot(fx, fy);
    d  = atan2(s.*fy, s.*fx);

    % ④ 추력곡선을 거꾸로 / the thrust curve, inverted
    kk = cfg.k_pos*(T >= 0) + cfg.k_neg*(T < 0);
    n  = sign(T) .* sqrt(abs(T) ./ kk);

    % 하드웨어가 깎는 자리 — 운동모델이 안에서 하는 것과 같은 깎기 / the same clip
    n_a = min(max(n, cfg.n_min), cfg.n_max);
    d_a = min(max(d, -cfg.alpha_max(:)), cfg.alpha_max(:));

    % ⑤ 운동모델에서 실제 tau 를 잰다 / measure the tau the model produced.
    %    깎지 않은 명령을 그대로 넘긴다 — 깎는 것은 플랜트의 일이다
    %    The unclipped command is passed straight in: clipping is the plant's job
    xd_on  = otter_tilt4(x0, n,         d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    xd_off = otter_tilt4(x0, [0 0 0 0], d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    tau    = Mm * (xd_on(1:6) - xd_off(1:6));

    R.act(:,k)   = tau([1 2 6]);
    R.T(:,k)     = T;
    R.n_cmd(:,k) = n;      R.n_act(:,k) = n_a;
    R.d_cmd(:,k) = d;      R.d_act(:,k) = d_a;
    R.sat_n(:,k) = abs(n - n_a) > 1e-9;
    R.sat_d(:,k) = abs(d - d_a) > 1e-9;
end
end
