function R = W12_tab_reint(mdl, C, V)
%W12_TAB_REINT  표 (2). 모델을 여섯 번 돌리고, 같은 입력으로 **밖에서** 다시 적분한다.
%               Table (2): the Simulink model against the same equations, integrated outside it.
%
%   무엇을 판정하는가 / what this decides
%       **모델이 그 수식인가.** 표 (1) 은 수식만 본다 — "함수는 맞는데 모델이
%       다른 것을 쓰고 있다" 를 못 잡는다. 여기가 어긋나면 수식이 아니라
%       **배선**이 틀린 것이다.
%
%   왜 한 시각의 가속도를 견주지 않는가 / why one instant is not compared
%       로그는 12개 상태 가운데 여섯만 싣는다. w, p, q, z, phi, theta 는 없고,
%       횡력이 걸리면 선체가 기울어 그 여섯이 **0 이 아니다.** 없는 것을 0 으로
%       채워 otter_tilt4 를 부르면 다른 상태의 가속도가 나오므로, 한 점을
%       견주는 것으로는 배선을 판정할 수 없다.
%       The log carries six of the twelve states; with a sway force the hull
%       heels, so the missing six are not zero and a single-instant comparison
%       would be taken at a different state.
%
%   그래서 궤적 전체를 다시 적분한다 / the whole trajectory is integrated again
%       Simulink 밖에서, 같은 고정스텝 ode4 로, x0 에서 시작해 30 초를 다시
%       적분한다. 매 스텝의 (n, delta) 는 **모델이 실제로 쓴 값** — 로그에 남은
%       서보 뒤의 값 — 을 그대로 쓴다. 그러면 적분기도 입력도 같으니 남는 차이는
%       반올림오차뿐이어야 하고, 그것이 "모델의 배선이 이 수식과 같다" 는 뜻이다.
%
%   반환 / what comes back
%       R{c} — 여섯 번의 로그. 표 (3) 과 그림이 **이것을 다시 쓴다.**
%       그래서 배는 스물넷이 아니라 여섯 번만 돈다.
%
%   See also W12_V_OPENLOOP, W12_CASES, W12_TAB_FORMULA, W12_TAB_TRACK, W12_READ.

nc = size(C, 1);

fprintf('  (2) the Simulink model against the same equations, integrated outside it\n\n');
fprintf('      the same fixed-step ode4 and the same step %.3f s, started from x0,\n', V.h);
fprintf('      driven at every step by the (n, delta) the model actually applied —\n');
fprintf('      the post-servo values read back from the log\n\n');
fprintf('    case   max |dN| [m]  max |dE| [m]  max |dpsi| [deg]  max |du| [m/s]   clip\n');
fprintf('    %s\n', repmat('-', 1, 78));

R      = cell(1, nc);
worst2 = 0;

for c = 1:nc
    R{c} = W12_read(mdl, 'n_cmd', C{c,2}', 'd_cmd', deg2rad(C{c,3})', ...
                         'T_final', 30);

    r  = R{c};
    hs = r.t(2) - r.t(1);
    ns = numel(r.t);

    Xs = zeros(12, ns);
    Xs(:,1) = V.x0;
    for k = 1:ns-1
        nk = r.n(k,:);  dk = r.delta(k,:);
        g  = @(xx) otter_tilt4(xx, nk, dk, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
        g1 = g(Xs(:,k));
        g2 = g(Xs(:,k) + hs/2*g1);
        g3 = g(Xs(:,k) + hs/2*g2);
        g4 = g(Xs(:,k) + hs  *g3);
        Xs(:,k+1) = Xs(:,k) + hs/6*(g1 + 2*g2 + 2*g3 + g4);
    end

    dN   = max(abs(Xs(7,:)' - r.N));
    dE   = max(abs(Xs(8,:)' - r.E));
    dpsi = rad2deg(max(abs(ssa(Xs(12,:)' - deg2rad(r.psi)))));
    du   = max(abs(Xs(1,:)' - r.u));
    worst2 = max(worst2, max([dN dE du]));

    fprintf('    %-5s  %11.2e  %12.2e  %16.2e  %14.2e   n %d  d %d\n', ...
            C{c,1}, dN, dE, dpsi, du, r.n_clip, r.d_clip);
end
fprintf('    %s\n', repmat('-', 1, 78));
fprintf('    worst %.1e m or m/s over the six 30 s runs\n\n', worst2);

end
