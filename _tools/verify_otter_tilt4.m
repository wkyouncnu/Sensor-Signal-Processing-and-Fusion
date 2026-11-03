function verify_otter_tilt4()
%VERIFY_OTTER_TILT4  otter_tilt4.m 이 otter.m 과 열 규칙에 어긋나지 않는지 본다.
%
%   다섯 가지를 잰다. 앞의 넷은 반올림오차 수준이어야 한다.
%
%     (a) 거치 부호가 선미 쌍의 힘을 **정확히 뒤집는다**
%         선미 둘은 뒤를 보고 달려 있어 delta = 0 이 -x_b 를 민다. 같은 명령을
%         거치 부호만 +1 로 둔 가상의 배와 견주면 tau 가 정확한 음수여야 한다.
%         두 가속도의 합이 추력 0 의 가속도의 두 배인지로 잰다.
%
%     (b) 각도를 0 으로 두고 **선수 둘만** 돌리면 옛 배다
%         otter_tilt4(x,[n1 n2 0 0],[0 0 0 0],...) == otter(x,[n1 n2],...)
%         선수 쌍은 0 도가 +x_b 여서 otter.m 과 미는 방향이 같다. 자리가
%         l_f = 1.5 m 앞인데도 같은 것은, delta = 0 이면 x 자리가 모멘트에
%         들어가지 않기 때문이다 (tau_N = -y T). x 자리는 **sin delta 를
%         통해서만** 들어온다 — 이 검사가 그것을 잰다. 선체·감쇠·복원력을
%         한 글자도 안 고쳤다는 것도 이것이 증명한다.
%
%     (c) tau 가 otter_B 의 열 규칙과 같다
%         otter_tilt4 의 가속도에서 거꾸로 tau 를 재어 cfg.B * f 와 견준다.
%         f = [T1 cos d1, T1 sin d1, ..., T4 cos d4, T4 sin d4]' 이다.
%         운동모델과 유도·배분이 **같은 B** 를 쓴다는 것이 이것으로 보장된다.
%
%     (d) 포화가 회전수와 각도 **양쪽**에 걸린다
%
%     (e) 강의에 싣는 수치 — 추력 곡선의 전진·후진 비대칭과, 그 때문에
%         대칭 명령이 전진력을 남긴다는 것
%
%   tau 를 어떻게 재는가 / how tau is measured
%     otter_tilt4 는 tau 를 돌려주지 않는다. 가속도가 tau 에 대해 아핀이므로
%     추력이 0 인 같은 상태의 가속도를 빼면 M \ tau 가 남고, 거기에 M 을 곱하면
%     tau 다. M 은 적재만으로 정해지는 상수여서 otter_M 의 것과 같다.
%     The acceleration is affine in tau, so subtracting the zero-thrust
%     acceleration at the same state leaves M \ tau; M is constant in the
%     payload alone, so otter_M's M is the same matrix.
%
%   사용법
%       addpath(fullfile(root,'_tools')); mss_path(); verify_otter_tilt4
%
%   See also OTTER_TILT4, OTTER, OTTER_BOW, OTTER_B, OTTER_M, OTTER_CONFIG.

cfg  = otter_config('quad_tilt');
quad = [cfg.pos ; cfg.alpha_max ; cfg.mount];
quad_fwd = quad;  quad_fwd(4,:) = 1;     % 넷이 다 앞을 보는 가상의 배 / all facing forward

mp = 25;  rp = [0.05 0 -0.35]';  V_c = 0.0;  beta_c = pi/2;
Mmat = otter_M(mp, rp);

fprintf(['\n  verify_otter_tilt4\n' ...
         '    stations   x = [%+.2f %+.2f %+.2f %+.2f] m\n' ...
         '               y = [%+.3f %+.3f %+.3f %+.3f] m\n' ...
         '    tilt limit +-%.0f deg each\n' ...
         '    B          %d x %d, rank %d, null space %d\n\n'], ...
        cfg.pos(1,:), cfg.pos(2,:), rad2deg(cfg.alpha_max(1)), ...
        size(cfg.B,1), size(cfg.B,2), rank(cfg.B), ...
        size(cfg.B,2) - rank(cfg.B));

rng(7);
worst_a = 0;  worst_b = 0;  worst_c = 0;
z4 = [0 0 0 0];

for trial = 1:200
    % 정지가 아닌 상태를 쓴다 — C, 감쇠, crossFlowDrag 가 모두 살아 있어야
    % 비교가 의미를 갖는다.
    x  = [ 1.2*randn; 0.4*randn; 0.05*randn
           0.05*randn; 0.05*randn; 0.3*randn
           20*randn;   20*randn;   0
           0.05*randn; 0.05*randn; pi*(2*rand-1) ];
    n1 = 80*(2*rand-1);
    n2 = 80*(2*rand-1);

    % (a) 거치 부호가 선미 쌍의 tau 를 정확히 뒤집는다. 같은 회전수를 선미
    %     둘에만 주고, 거치 부호만 +1 로 바꾼 가상의 배와 견준다. 가속도는
    %     tau 에 아핀이므로 두 가속도의 **합**이 추력 0 의 가속도의 두 배여야
    %     한다 — tau 하나가 다른 하나의 정확한 음수라는 뜻이다.
    xd_aft = otter_tilt4(x, [0 0 n1 n2], z4, mp, rp, V_c, beta_c, quad);
    xd_fwd = otter_tilt4(x, [0 0 n1 n2], z4, mp, rp, V_c, beta_c, quad_fwd);
    xd_nil = otter_tilt4(x, z4,          z4, mp, rp, V_c, beta_c, quad);
    d_a = (xd_aft + xd_fwd) - 2*xd_nil;
    worst_a = max(worst_a, max(abs(d_a)));

    % (b) 각도 0, 선수 둘만 — 자리가 앞인데도 같아야 한다
    d_b = otter_tilt4(x, [n1 n2 0 0], z4, mp, rp, V_c, beta_c, quad) ...
        - otter(      x, [n1 n2],         mp, rp, V_c, beta_c);
    worst_b = max(worst_b, max(abs(d_b)));

    % (c) 네 추진기를 임의로 돌려 tau 를 재고 열 규칙과 견준다
    n = [80*(2*rand(1,4)-1)];
    d = cfg.alpha_max .* (2*rand(1,4)-1);        % 한계 안에서만 / inside the limit

    xd_on  = otter_tilt4(x, n,         d,  mp, rp, V_c, beta_c, quad);
    xd_off = otter_tilt4(x, [0 0 0 0], d,  mp, rp, V_c, beta_c, quad);
    tau_meas = Mmat * (xd_on(1:6) - xd_off(1:6));

    T = zeros(1,4);
    for i = 1:4
        if n(i) > 0, T(i) = cfg.k_pos * n(i)*abs(n(i));
        else,        T(i) = cfg.k_neg * n(i)*abs(n(i));
        end
    end
    f = zeros(8,1);
    f(1:2:7) = T .* cos(d);
    f(2:2:8) = T .* sin(d);
    tau_rule = cfg.B * f;                        % [X Y N]'

    d_c = tau_meas([1 2 6]) - tau_rule;
    worst_c = max(worst_c, max(abs(d_c)));
end

% (d) 포화. 한계를 넘겨 넣고 한계에서 넣은 것과 같은지 본다. 회전수와 각도를
%     **함께** 넘긴다 — 둘 중 하나만 걸려도 이 값이 커진다.
x0 = zeros(12,1);
over  = otter_tilt4(x0, [1e4 -1e4 1e4 -1e4], [ 2  2 -2 -2], mp,rp,V_c,beta_c,quad);
atlim = otter_tilt4(x0, [cfg.n_max cfg.n_min cfg.n_max cfg.n_min], ...
                        [cfg.alpha_max(1) cfg.alpha_max(2) ...
                        -cfg.alpha_max(3) -cfg.alpha_max(4)], mp,rp,V_c,beta_c,quad);
d_d = max(abs(over - atlim));

fprintf('  (a) aft mounting sign flips tau exactly : %9.2e\n', worst_a);
fprintf('  (b) fore pair, delta 0 == otter.m       : %9.2e\n', worst_b);
fprintf('  (c) tau                == otter_B * f   : %9.2e\n', worst_c);
fprintf('  (d) saturation clamps n AND delta       : %9.2e\n', d_d);

tol = 1e-9;        % (c) 는 M 을 곱해 되돌리므로 (a)·(b) 보다 느슨하다
ok  = (worst_a < 1e-12) && (worst_b < 1e-12) && (worst_c < tol) && (d_d < 1e-12);

% (e) 강의에 싣는 수치 / the numbers the lecture quotes
n_ref  = 60;
T_fwd  =  cfg.k_pos * n_ref^2;
T_rev  = -cfg.k_neg * n_ref^2;
n_cxl  = -sqrt(T_fwd / cfg.k_neg);      % 전진 추력을 정확히 지우는 후진 회전수
fprintf(['\n  thrust at +-%.0f rad/s   %+7.3f N ahead, %+7.3f N astern' ...
         '  (k_neg/k_pos = %.4f)\n'], n_ref, T_fwd, T_rev, cfg.k_neg/cfg.k_pos);
fprintf('  cancelling astern speed  %+8.3f rad/s   (not %+.0f)\n', n_cxl, -n_ref);
fprintf('  limits                   %+8.3f .. %+.3f rad/s\n', cfg.n_min, cfg.n_max);

if ok
    fprintf('\n  PASS  (tol %.0e, %d random states)\n\n', tol, trial);
else
    error('verify_otter_tilt4:FAIL', ...
          'otter_tilt4 does not match otter.m or the column rule');
end

end
