function verify_otter_bow()
%VERIFY_OTTER_BOW  otter_bow.m 이 otter.m 과 어긋나지 않는지 기계로 본다.
%
%   두 가지를 잰다. 둘 다 반올림오차 수준이어야 한다.
%
%     (a) 선수추진기를 끄면 옛 배다
%         otter_bow(x,[n1 n2 0],...)  ==  otter(x,[n1 n2],...)
%         선체·감쇠·복원력을 한 글자도 안 고쳤다는 것을 이것이 증명한다.
%
%     (b) 선수추진기를 켜면 옛 중첩과 같다
%         otter_bow(x,[n1 n2 n3],...) ==
%             otter(x,[n1 n2],...) + Minv*[0; T3; 0; 0; 0; l3*T3]  (1:6 행)
%         6주차가 지금까지 쓰던 tau_ext 중첩이 **정확했다**는 것과, 새 모델이
%         그것을 그대로 품었다는 것을 동시에 보인다.
%
%     (c) 포화 한계가 PPT 의 값과 맞는지
%
%   사용법
%       addpath(fullfile(root,'_tools')); mss_path(); verify_otter_bow
%
%   See also OTTER_BOW, OTTER, OTTER_M, VERIFY_CONSTANTS.

cfg = otter_config('bow_thruster');
bow = [cfg.l_f, cfg.k_bow, cfg.n_bow_max];

mp = 25;  rp = [0.05 0 -0.35]';  V_c = 0.0;  beta_c = pi/2;
[~, Minv] = otter_M(mp, rp);

fprintf('\n  verify_otter_bow  --  bow = [l3 %.4g, k3 %.6g, n3_max %.6g]\n\n', ...
        bow(1), bow(2), bow(3));

rng(7);
worst_a = 0;  worst_b = 0;

for trial = 1:200
    % 정지가 아닌 상태를 쓴다 — C, 감쇠, crossFlowDrag 가 모두 살아 있어야
    % 비교가 의미를 갖는다.
    x  = [ 1.2*randn; 0.4*randn; 0.05*randn
           0.05*randn; 0.05*randn; 0.3*randn
           20*randn;   20*randn;   0
           0.05*randn; 0.05*randn; pi*(2*rand-1) ];
    n1 = 80*(2*rand-1);
    n2 = 80*(2*rand-1);
    n3 = 50*(2*rand-1);

    % (a) 선수추진기를 끄면 옛 배다
    d_a = otter_bow(x, [n1 n2 0], mp, rp, V_c, beta_c, bow) ...
        - otter(    x, [n1 n2  ], mp, rp, V_c, beta_c);
    worst_a = max(worst_a, max(abs(d_a)));

    % (b) 켜면 옛 중첩과 같다
    T3  = bow(2) * n3 * abs(n3);
    sup = otter(x, [n1 n2], mp, rp, V_c, beta_c);
    sup(1:6) = sup(1:6) + Minv * [0; T3; 0; 0; 0; bow(1)*T3];
    d_b = otter_bow(x, [n1 n2 n3], mp, rp, V_c, beta_c, bow) - sup;
    worst_b = max(worst_b, max(abs(d_b)));
end

% (c) 포화. 한계를 넘겨 넣고 한계에서 넣은 것과 같은지 본다.
x0 = zeros(12,1);
d_c = max(abs( otter_bow(x0,[1e4 -1e4 1e4],mp,rp,V_c,beta_c,bow) ...
             - otter_bow(x0,[cfg.n_max cfg.n_min bow(3)],mp,rp,V_c,beta_c,bow) ));

fprintf('  (a) bow off  == otter.m                : %9.2e\n', worst_a);
fprintf('  (b) bow on   == old tau_ext superposed : %9.2e\n', worst_b);
fprintf('  (c) saturation clamps at the limits    : %9.2e\n', d_c);

tol = 1e-12;
ok  = (worst_a < tol) && (worst_b < tol) && (d_c < tol);

% 강의에 싣는 수치. 세 추진기가 각자 낼 수 있는 최대 힘.
fprintf('\n  T_max  %7.2f N   T_min %8.2f N   F_B_max %6.2f N\n', ...
        cfg.k_pos*cfg.n_max^2, -cfg.k_neg*cfg.n_min^2, bow(2)*bow(3)^2);

if ok
    fprintf('\n  PASS  (tol %.0e, %d random states)\n\n', tol, trial);
else
    error('verify_otter_bow:FAIL', 'otter_bow does not match otter.m');
end

end
