function S = W12_sweep_laws(B, cfg, P)
%W12_SWEEP_LAWS  §12-10 의 궤적 쓸기 — 요구 하나가 아니라 201 점에 법칙 여섯을
%  모두 걸어 보고 표를 찍는다. 절 스크립트(`W12_I_limits`)를 얇게 두기 위해
%  여기로 뺐다 (`vault_check.sh` §18, 실행 줄 45 이하).
%
%  통계는 **해가 나온 점에서만** 낸다. `quadprog`·`lsqlin` 은 실행 불가능한
%  마지막 반복값을 그럴듯한 숫자로 돌려주므로, `exit > 0` 으로 걸러야 수치다
%  (`standing-orders.md` §15-76).
%
%  돌려주는 것: S.t · S.mth · S.MD · S.ER · S.D1 · S.RHO · S.EF.

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
        [f, in] = W12_alloc(B, tau(:,k), char(S.mth(a)), P);
        H = W12_hw(B, f, cfg);
        S.MD(a,k)  = max(abs(rad2deg(H.delta)));
        S.D1(a,k)  = rad2deg(H.delta(1));
        S.ER(a,k)  = norm(H.tau - tau(:,k));
        S.RHO(a,k) = H.rho;
        S.EF(a,k)  = in.exit;
    end
end

fprintf('\n궤적  tau = [100 sin0.5t ; 60 cos0.3t ; 30 sin0.7t],  t = 0..20 s, %d 점\n\n', ...
        numel(S.t));
fprintf('  method     solved   wall broken   max|delta|   mean |tau err|   max |tau err|   rho<1\n');
fprintf('           [%% of k]      [%% of k]       [deg]             [N]             [N]   [%% of k]\n');
for a = 1:nm
    ok = S.EF(a,:) > 0;
    fprintf('  %-9s %8.1f %13.1f %12.2f %15.3f %15.3f %10.1f\n', S.mth(a), ...
        100*mean(ok), ...
        100*mean(S.MD(a,ok) > amax + 1e-6), max(S.MD(a,ok)), ...
        mean(S.ER(a,ok)), max(S.ER(a,ok)), 100*mean(S.RHO(a,ok) < 1-1e-9));
end
fprintf('\n  (벽·오차 통계는 **해가 나온 점에서만** 냈다 — qp 는 그러지 못한 점이 있다)\n');
end
