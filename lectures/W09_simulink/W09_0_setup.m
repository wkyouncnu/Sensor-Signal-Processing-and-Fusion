%% W09 · 실험 9-0 — 이번 주의 값들 / Experiment 9-0 — the parameters of this week
%
%  이 주차에는 새 값이 거의 없다. 2~8주차가 각각 고른 값을 한자리에 모았을 뿐이고,
%  새로 생긴 것은 **주차마다 하나씩의 스위치**다. 0 으로 두면 그 주차가 넣은 것을
%  빼고 같은 임무를 돌린다 — 그것이 §9-3 이 재는 것이다.
%  Almost nothing here is new: these are the values Weeks 2 to 8 each chose, put
%  in one place. What is new is one switch per week. Setting one to 0 flies the
%  same mission without what that week contributed, which is what §9-3 measures.
%
%  같은 값이 W09_vars.m 에도 있다 — verify_w09_integration 의 검사 1 이 대조한다.

clear

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

%% 임무 / the mission
WP_N = [60 60  0]';  WP_E = [ 0 60 60]';     % 세 지점 / three waypoints             [m]
R_arrive = 3;                             % 도착 반경 / the arrival radius        [m]
T_hold   = 30;                            % 유지 시간 / how long to hold          [s]
u_d      = 1.0;                           % 이동 속도 / the transit speed         [m/s]

%% 각 주차가 넣은 것 / what each week contributed — 0 이면 그 주차를 빼고 돈다
use_Ki_u  = 1;    % 3주차 / Week 3: the integral of the speed loop
use_ssa   = 1;    % 4주차 / Week 4: the shortest-angle wrap, ssa
use_Kd    = 1;    % 4주차 / Week 4: the derivative of the heading loop
use_ilos  = 1;    % 5주차 / Week 5: the integral of the guidance law
use_pass  = 1;    % 5주차 / Week 5: switching on the along-track test, not the circle alone
use_scale = 1;    % 6주차 / Week 6: scaling rather than clipping at the limits
use_notch = 1;    % 7주차 / Week 7: the wave filter
use_vane  = 1;    % 8주차 / Week 8: the bow set free while holding
hand_over = 1;    % 8주차 / Week 8: the integral handed over at a mode change

%% 3주차 · 속도 루프 / the speed loop
Kp_u = 200;  Ki_u = 200;

%% 4주차 · 선수각 루프 / the heading loop
Kp = 300;  Kd = 100;

%% 5주차 · 유도 / the guidance
Delta = 5;  kappa = 0.3;

%% 7주차 · 바다와 노치 / the sea and the notch
Hs = 0.3;  T0 = 2.0;  gamma_j = 3.3;  N_comp = 20;  sigma_psi = 3;
w0 = 2*pi/T0;
[w_i, a_i, phi_i, k_w] = wave_train(Hs, T0, gamma_j, N_comp, sigma_psi);
wave_on = 1;
phase_shift = 0;                          % 같은 스펙트럼의 다른 실현 / another realisation [rad]
phi_i = mod(phi_i + phase_shift, 2*pi);
zeta_n = 0.05;  zeta_d = 0.3;

%% 8주차 · 위치 루프 / the position loop
Kp_x = 30;  Ki_x = 3;  Kd_x = 60;  e_min = 0.3;

%% 한계 / the limits
cfg = otter_config('base');
X_max = 120;
N_max = min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X_max/2), ...
            2*cfg.y_pont*(X_max/2 + cfg.k_neg*cfg.n_min^2));
%  전진력이 0 일 때의 요 한계 — 6주차의 결합을 잊은 설계가 쓰는 값 (§9-3).
%  The yaw limit at zero surge, which a design that forgets the coupling would use.
N_open = 2*cfg.y_pont*cfg.k_pos*cfg.n_max^2;

%% 환경과 선체 / the environment and the hull
V_c = 0.3;  beta_c = pi/2;
y_pont = cfg.y_pont;  k_pos = cfg.k_pos;  k_neg = cfg.k_neg;
T_max  = cfg.k_pos*cfg.n_max^2;  T_min = -cfg.k_neg*cfg.n_min^2;
mp = 25;  rp = [0.05 0 -0.35]';
x0 = zeros(12,1);

h = 0.02;  T_final = 290;

fprintf(['\n  W09_0_setup\n' ...
         '    mission   %d waypoints, %g m legs;  arrive within %g m, hold %g s, transit at %g m/s\n' ...
         '    sea       Hs %.2f m, T0 %.1f s;  current %.2f m/s towards %.0f deg\n' ...
         '    switches  W3 %g  W4 %g %g  W5 %g %g  W6 %g  W7 %g  W8 %g %g\n' ...
         '    limits    |X| <= %g N,  |N| <= %.2f N m  (at zero surge it would be %.2f)\n\n'], ...
        numel(WP_N), hypot(WP_N(1),WP_E(1)), R_arrive, T_hold, u_d, Hs, T0, V_c, beta_c*180/pi, ...
        use_Ki_u, use_ssa, use_Kd, use_ilos, use_pass, use_scale, use_notch, use_vane, hand_over, ...
        X_max, N_max, N_open);
