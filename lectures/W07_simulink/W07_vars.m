function V = W07_vars()
%W07_VARS  W07_0_setup 과 같은 값을 구조체로 / the values of W07_0_setup, as a struct.
%
%   파랑 성분(주파수·진폭·위상)은 _tools/wave_train.m 이 스펙트럼에서 만든다.
%   두 파일이 같은 함수를 부르므로 어긋날 수 없다.
%   The wave components come from _tools/wave_train.m; both files call it, so
%   they cannot drift apart.

cfg = otter_config('base');

%% 바다 / the sea — JONSWAP
V.Hs        = 0.3;     % 유의파고 / significant wave height            [m]
V.T0        = 2.0;     % 첨두주기 / peak period                        [s]
V.gamma_j   = 3.3;     % JONSWAP 첨두 계수 / peak enhancement
V.N_comp    = 20;      % 성분 수 / number of components
V.sigma_psi = 3;       % 1차 파랑이 만드는 선수각의 표준편차 / std of the wave-induced heading [deg]
V.w0        = 2*pi/V.T0;
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
V.wave_on   = 1;       % 0 이면 바다를 끈다 / 0 switches the sea off

%% 노치 필터 / the notch filter
V.zeta_n = 0.05;       % 깊이. 작을수록 깊다. zeta_d 와 같게 두면 필터가 1 이 된다
V.zeta_d = 0.3;        % 너비. 클수록 넓다 / width; larger is wider

%% 선수각 오토파일럿 (4주차) / the heading autopilot of Week 4
V.Kp = 300;  V.Kd = 100;  V.Ki = 20;  V.Kb = 0.1;
V.X_ff = 60;
V.N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - V.X_ff/2), ...
              2*cfg.y_pont*(V.X_ff/2 + cfg.k_neg*cfg.n_min^2));

%% 명령 / the command
V.psi_step = 10;       % 목표 선수각 / commanded heading               [deg]
V.t_step   = 5;        % 계단이 들어가는 시각 / the instant of the step [s]

%% 선체와 추진기 / hull and thrusters
V.y_pont = cfg.y_pont;  V.k_pos = cfg.k_pos;  V.k_neg = cfg.k_neg;
V.T_max = cfg.k_pos*cfg.n_max^2;  V.T_min = -cfg.k_neg*cfg.n_min^2;
V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.x0 = zeros(12,1);

%% 느린 외란 / the slow disturbance of §7-6 — 바람과 2차 파랑 표류
V.N_slow = 15;         % 평균 요 모멘트 / mean yaw moment                [N m]
V.T_slow = 60;         % 그것이 변하는 주기 / the period it varies over  [s]
V.V_c = 0;  V.beta_c = pi/2;

V.h = 0.02;  V.T_final = 60;
end
