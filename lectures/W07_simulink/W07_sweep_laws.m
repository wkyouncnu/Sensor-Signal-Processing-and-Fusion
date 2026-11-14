function S = W07_sweep_laws(B, cfg, P)
%W07_SWEEP_LAWS  §7-10 의 궤적 쓸기 — 요구 하나가 아니라 201 점에 법칙 여섯을
%  모두 걸어 보고 표를 찍는다. `W07_CA(10)` 이 부른다.
%
%  The trajectory sweep of 7-10: six laws are put not to one demand but to
%  201 of them, and the table is printed here. Called from W07_CA(10).
%
%  통계는 **해가 나온 점에서만** 낸다. `quadprog`·`lsqlin` 은 실행 불가능한
%  마지막 반복값을 그럴듯한 숫자로 돌려주므로, `exit > 0` 으로 걸러야 수치다
%  (`standing-orders.md` §15-76).
%
%  The statistics are taken ONLY at the points where a solution was found.
%  `quadprog` and `lsqlin` return the last infeasible iterate as a plausible
%  looking number, so nothing is a measurement until `exit > 0` has filtered
%  it.
%
%  돌려주는 것 / what is returned: S.t · S.mth · S.MD · S.ER · S.D1 · S.RHO · S.EF

amax  = rad2deg(P.alpha_max);
S.t   = linspace(0, 20, 201);
tau   = [100*sin(0.5*S.t); 60*cos(0.3*S.t); 30*sin(0.7*S.t)];
S.mth = ["pinv" "wpinv" "clip" "qp" "wls" "wls16"];
nm    = numel(S.mth);
S.MD  = zeros(nm, numel(S.t));  S.ER = zeros(nm, numel(S.t));
S.D1  = zeros(nm, numel(S.t));  S.EF = zeros(nm, numel(S.t));
S.RHO = ones(nm, numel(S.t));

for a = 1:nm
    for k = 1:numel(S.t)
        [f, in] = W07_alloc(B, tau(:,k), char(S.mth(a)), P);
        H = W07_hw(B, f, cfg);
        S.MD(a,k)  = max(abs(rad2deg(H.delta)));
        S.D1(a,k)  = rad2deg(H.delta(1));
        S.ER(a,k)  = norm(H.tau - tau(:,k));
        S.RHO(a,k) = H.rho;
        S.EF(a,k)  = in.exit;
    end
end

fprintf('\nthe demand  tau = [100 sin0.5t ; 60 cos0.3t ; 30 sin0.7t],  t = 0..20 s, %d points\n\n', ...
        numel(S.t));
fprintf('  method     solved    past limit   max|delta|   mean |tau err|   max |tau err|   rho<1\n');
fprintf('           [%% of pts]    [%% of pts]       [deg]             [N]             [N] [%% of pts]\n');
for a = 1:nm
    ok = S.EF(a,:) > 0;
    fprintf('  %-9s %8.1f %13.1f %12.2f %15.3f %15.3f %10.1f\n', S.mth(a), ...
        100*mean(ok), ...
        100*mean(S.MD(a,ok) > amax + 1e-6), max(S.MD(a,ok)), ...
        mean(S.ER(a,ok)), max(S.ER(a,ok)), 100*mean(S.RHO(a,ok) < 1-1e-9));
end
fprintf('\n  (the limit and error statistics are taken only where a solution was\n');
fprintf('   found -- qp fails to find one at some of the points)\n');
end
