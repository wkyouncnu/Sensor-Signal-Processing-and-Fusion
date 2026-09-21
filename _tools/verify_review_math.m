function ok = verify_review_math()
%VERIFY_REVIEW_MATH  2026-09-14 전체 검토에서 강의자료에 새로 실은 수치를 재현한다.
%
%      ok = verify_review_math()
%
%  CLAUDE.md §4-8: 문서의 모든 수치는 러너 출력까지 추적 가능해야 한다.
%  검토 중에 대화창에서 한 번 계산하고 끝낸 값은 추적이 안 되므로 여기로 옮겼다.
%  vault_runall 이 이 함수를 부르고, vault_number_audit 가 그 출력과 문서를 대조한다.
%
%  무엇을 재현하는가
%    1. W03 §3-6  back-calculation 의 고정점 I* 와 초과분 eps* = (Ki/Kaw) e
%                 "요구가 한계와 같아진다" 는 해석이 틀렸다는 표
%    2. W05 §5-9-6 ALOS 스케치의 잔여 교차항 때문에 dV > 0 인 띠의 폭,
%                 그리고 btilde = 17 deg, y_e = -1 cm 의 반례 값
%    3. W05 §H    운동학 부분만 적분했을 때 V 가 모든 표본에서 감소하는지,
%                 y_e 가 처음 음수가 되는 시각
%    4. W01/A1   x_g 가 정확히 0.153125 m 이고 그 곱들이 닫히는지

ok = true;
fprintf('\n  verify_review_math — 2026-09-14 검토에서 실은 수치\n');

%% 1. back-calculation 고정점 (W03 §3-6, §H 의 데모 플랜트)
Kp = 1.8; Ki = 4; r = 2; umax = 1;
fprintf('\n  1) back-calculation, G = 1/(s+1), |u|<=1, Kp=1.8, Ki=4, r=2\n');
fprintf('     %6s %10s %10s %12s %10s\n', 'Kaw', 'I* pred', 'I sim', 'X_cmd sim', 'excess');
for Kaw = [0.5 2 5 20]
    sat = @(x) min(max(x, -umax), umax);
    f = @(t,x) [ -x(1) + sat(Kp*(r-x(1)) + x(2)) ;
                  Ki*(r-x(1)) - Kaw*((Kp*(r-x(1)) + x(2)) - sat(Kp*(r-x(1)) + x(2))) ];
    [~, X] = ode45(f, [0 200], [0;0], odeset('RelTol',1e-9,'AbsTol',1e-11));
    e  = r - X(end,1);   Xc = Kp*e + X(end,2);
    Ip = umax - Kp*1 + (Ki/Kaw)*1;          % 문서의 식, e = 1
    fprintf('     %6.1f %10.3f %10.3f %12.2f %10.2f\n', Kaw, Ip, X(end,2), Xc, Xc - umax);
    ok = ok && abs(X(end,2) - Ip) < 5e-3 && abs((Xc - umax) - (Ki/Kaw)*e) < 5e-3;
end

%% 2. ALOS 잔여 교차항의 띠 (W05 §5-9-6)
U = 0.774; Dl = 8;
fprintf('\n  2) band where dV > 0 : 0 < |y_e| < Delta |bt - sin bt| / cos bt,  Delta = 8 m\n');
for bd = [5 17 40]
    bt = deg2rad(bd);
    fprintf('     btilde = %4.1f deg   width = %.3e m\n', bd, Dl*abs(bt - sin(bt))/cos(bt));
end
bt = deg2rad(17); ye = -0.01;
Vd = U*Dl*ye*(sin(bt)-bt)/sqrt(Dl^2+ye^2) - U*ye^2*cos(bt)/sqrt(Dl^2+ye^2);
fprintf('     counterexample btilde = 17 deg, y_e = -0.01 m, U = %.3f : dV = %+.2e\n', U, Vd);
ok = ok && Vd > 0;

%% 3. 운동학 ALOS 만 적분 (W05 §H)
g = 0.005; beta = deg2rad(15.74);
f = @(t,x) [ U*sin((beta - x(2)) - atan(x(1)/Dl)) ;  g*Dl*x(1)/sqrt(Dl^2 + x(1)^2) ];
[t, X] = ode45(f, linspace(0,500,50001), [0;0], odeset('RelTol',1e-10,'AbsTol',1e-12));
btv = beta - X(:,2);
V   = 0.5*X(:,1).^2 + U/(2*g)*btv.^2;
frac = 100*mean(diff(V) <= 1e-12);
k0  = find(X(:,1) < 0, 1);
fprintf('\n  3) kinematic ALOS only, %d samples: dV <= 0 in %.2f %%\n', numel(t), frac);
fprintf('     y_e first negative at t = %.1f s, btilde there = %+.2f deg\n', t(k0), rad2deg(btv(k0)));
both = X(:,1) < 0 & btv > 0;
wmax = max(Dl*abs(btv(both) - sin(btv(both)))./cos(btv(both)));
fprintf('     later opposite-sign samples: %d, widest band there %.1e m, inside band %d\n', ...
        sum(both), wmax, sum(abs(X(both,1)) < Dl*abs(btv(both)-sin(btv(both)))./cos(btv(both))));
ok = ok && frac == 100;

%% 4. x_g 와 그 곱 (W01 §1-9, A1 §A1-7)
xg = (55*0.2 + 25*0.05)/80;
fprintf('\n  4) x_g = %.6f m,  80 x_g = %.4f,  80 x_g^2 = %.4f\n', xg, 80*xg, 80*xg^2);
fprintf('     15.1021 + 25.6736 = %.4f ;  + 1.8758 = %.4f\n', 15.1021+25.6736, 15.1021+25.6736+1.8758);
fprintf('     W05 still-water U = X_ff/|X_u| = 60/77.5544 = %.4f m/s\n', 60/77.5544);

if ok, fprintf('\n  ALL CHECKS PASSED\n\n'); else, fprintf('\n  SOME CHECK FAILED\n\n'); end
end
