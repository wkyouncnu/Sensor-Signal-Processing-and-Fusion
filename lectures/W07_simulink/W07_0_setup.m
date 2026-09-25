%% W07 · 실험 7-0 — 이번 주의 값들 / Experiment 7-0 — the parameters of this week
%
%  학생이 손으로 고치는 유일한 파일이다. 모델의 어느 블록에도 숫자가 없다.
%  The only file edited by hand; no block holds a number.
%
%  무엇이 들어 있는가 / what is in it
%      바다 (유의파고·첨두주기·JONSWAP 첨두계수·성분 수·선수각 표준편차)
%      노치 필터 두 값 (깊이 zeta_n, 너비 zeta_d)
%      4주차의 오토파일럿 게인, 명령, 선체와 추진기, 조류
%      the sea, the two numbers of the notch, the Week 4 autopilot, the command,
%      the hull and its thrusters, and the current
%
%  같은 값이 W07_vars.m 에도 있다. 둘을 함께 고친다 — verify_w07_waves 의 검사 1 이 대조한다.
%  The same values live in W07_vars.m; edit both, and check 1 compares them.

clear

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

%% 바다 / the sea — JONSWAP
Hs        = 0.3;              % 유의파고 / significant wave height             [m]
T0        = 2.0;              % 첨두주기 / peak period                         [s]
gamma_j   = 3.3;              % JONSWAP 첨두 계수 / peak enhancement
N_comp    = 20;               % 성분 수 / number of components
sigma_psi = 3;                % 1차 파랑이 만드는 선수각의 표준편차 / std of the wave-induced heading [deg]
w0        = 2*pi/T0;          % 첨두 주파수 / peak frequency                   [rad/s]
wave_on   = 1;                % 0 이면 바다를 끈다 / 0 switches the sea off

%  스펙트럼에서 성분을 뽑는다. 위상은 정해져 있으므로 실행할 때마다 같은 바다다.
%  The components come from the spectrum; the phases are fixed, so the sea is
%  the same on every run (→ _tools/wave_train.m).
[w_i, a_i, phi_i, k_w] = wave_train(Hs, T0, gamma_j, N_comp, sigma_psi);

%% 노치 필터 / the notch filter
%     H(s) = (s^2 + 2 zeta_n w0 s + w0^2) / (s^2 + 2 zeta_d w0 s + w0^2)
%  zeta_n 이 작을수록 w0 에서 깊게 파이고, zeta_d 가 클수록 넓게 걸린다.
%  zeta_n = zeta_d 로 두면 H(s) = 1 이 되어 필터가 사라진다 — 끄는 방법이다.
zeta_n = 0.05;                % 깊이 / depth:  |H(j w0)| = zeta_n / zeta_d
zeta_d = 0.3;                 % 너비 / width

%% 선수각 오토파일럿 (4주차) / the heading autopilot of Week 4
cfg = otter_config('base');
Kp = 300;  Kd = 100;  Ki = 20;  Kb = 0.1;
X_ff  = 60;                   % 전진력 / surge force                           [N]
N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X_ff/2), ...
            2*cfg.y_pont*(X_ff/2 + cfg.k_neg*cfg.n_min^2));

%% 명령 / the command
psi_step = 10;                % 목표 선수각 / commanded heading                [deg]
t_step   = 5;                 % 계단 시각 / the instant of the step            [s]

%% 선체와 추진기 / hull and thrusters
y_pont = cfg.y_pont;  k_pos = cfg.k_pos;  k_neg = cfg.k_neg;
T_max  = cfg.k_pos*cfg.n_max^2;  T_min = -cfg.k_neg*cfg.n_min^2;
mp = 25;  rp = [0.05 0 -0.35]';
x0 = zeros(12,1);

%% 느린 외란 / the slow disturbance of §7-6 — 바람과 2차 파랑 표류
%  바람과 2차 파랑 표류는 파랑보다 훨씬 느리게 변하는 힘이다. 여기서는 요 모멘트
%  하나로 적고, 제어기 뒤에서 더한다 — 선체가 받는 것은 제어 모멘트와 그 합이다.
%  Wind and second-order wave drift vary far more slowly than the waves. Here they
%  are one yaw moment, added after the controller: the hull receives the sum.
N_slow = 15;                  % 평균 요 모멘트 / mean yaw moment               [N m]
T_slow = 60;                  % 그것이 변하는 주기 / the period it varies over [s]
V_c = 0;  beta_c = pi/2;

h = 0.02;  T_final = 60;

fprintf(['\n  W07_0_setup\n' ...
         '    sea       Hs = %.2f m, T0 = %.1f s  ->  w0 = %.3f rad/s;  %d components\n' ...
         '    response  the wave-induced heading has a standard deviation of %.1f deg\n' ...
         '    notch     zeta_n = %.2f, zeta_d = %.2f  ->  |H(j w0)| = %.3f (%.1f dB)\n' ...
         '    autopilot Kp = %g, Kd = %g, Ki = %g;  |N| <= %.2f N m\n\n'], ...
        Hs, T0, w0, N_comp, sigma_psi, zeta_n, zeta_d, zeta_n/zeta_d, ...
        20*log10(zeta_n/zeta_d), Kp, Kd, Ki, N_max);
