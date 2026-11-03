function TAU = W12_tab_formula(C, V, cfg)
%W12_TAB_FORMULA  표 (1). 손으로 쓴 X, Y, N 을 운동모델에서 거꾸로 잰 tau 와 견준다.
%                 Table (1): the hand formula against the motion model, at rest.
%
%   무엇을 판정하는가 / what this decides
%       **수식이 맞는가.** 배선은 보지 않는다 — 모델을 돌리지 않고 `otter_tilt4`
%       를 직접 두 번 불러 가속도의 차이에서 tau 를 되찾는다. 남는 차이가
%       반올림오차 수준(1e-13 아래)이어야 한다.
%
%   왜 손으로 한 번 더 깎는가 / why the clip is repeated here by hand
%       서보가 하는 일을 손으로 한 번 더 한다 — 모델이 깎은 값과 같은 값으로
%       재야 표의 두 열이 **같은 것**을 가리킨다.
%
%   표의 폭 / the width of the table
%       강의 `.md` 가 이 블록을 그대로 인용하고, PDF 본문 폭에 103 자까지만
%       들어간다. 그래서 자리수를 줄이고 "무엇을 뜻하는가" 열을 표 밖으로
%       내보냈다 / the lecture quotes this block verbatim and the PDF body fits
%       103 characters, so the table carries numbers only
%
%   See also W12_V_OPENLOOP, W12_CASES, W12_TAB_REINT, W12_TAB_TRACK, OTTER_B.

nc = size(C, 1);
Mm = otter_M(V.mp, V.rp);

fprintf('\n');
fprintf('  (1) hand formula against the motion model, at rest\n\n');
fprintf('      tau from the hand formula    X = sum Ti cos di\n');
fprintf('                                   Y = sum Ti sin di\n');
fprintf('                                   N = sum (xi sin di - yi cos di) Ti\n');
fprintf('      tau measured out of otter_tilt4''s acceleration, same state\n\n');
fprintf('    %-4s  %-25s  %-21s  %-26s  %7s\n', 'case', 'n [rad/s] after clip', ...
        'delta [deg] clipped', '   X [N]    Y [N]  N [N m]', 'resid');
fprintf('    %s\n', repmat('-', 1, 91));

x0    = zeros(12,1);
TAU   = zeros(nc, 3);
worst = 0;

for c = 1:nc
    n = min(max(C{c,2}, cfg.n_min), cfg.n_max);
    d = min(max(deg2rad(C{c,3}), -cfg.alpha_max), cfg.alpha_max);

    T = (cfg.k_pos*(n >= 0) + cfg.k_neg*(n < 0)) .* n .* abs(n);

    %  손 수식 / by hand, term by term
    X = sum(T .* cos(d));
    Y = sum(T .* sin(d));
    N = sum((cfg.pos(1,:) .* sin(d) - cfg.pos(2,:) .* cos(d)) .* T);

    %  열 규칙과 같은지 / the same thing through otter_B's column rule
    f = zeros(8,1);
    f(1:2:7) = T .* cos(d);
    f(2:2:8) = T .* sin(d);
    assert(max(abs(cfg.B*f - [X; Y; N])) < 1e-12, ...
           'W12:columnRule', 'the hand formula and otter_B disagree');

    %  운동모델에서 거꾸로 재기 / measured back out of the motion model
    xd_on  = otter_tilt4(x0, n,         d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    xd_off = otter_tilt4(x0, [0 0 0 0], d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    tau = Mm * (xd_on(1:6) - xd_off(1:6));

    res   = max(abs(tau([1 2 6]) - [X; Y; N]));
    worst = max(worst, res);
    TAU(c,:) = [X Y N];

    fprintf('    %-4s  [%5.1f %5.1f %5.1f %5.1f]  [%4.0f %4.0f %4.0f %4.0f]  %8.3f %8.3f %8.3f  %7.1e\n', ...
            C{c,1}, n, rad2deg(d), X, Y, N, res);
end
fprintf('    %s\n', repmat('-', 1, 91));
fprintf('    worst residual %.1e N or N m over the six cases\n\n', worst);

end
