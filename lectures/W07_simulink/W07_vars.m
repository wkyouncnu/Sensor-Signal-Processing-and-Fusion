function V = W07_vars()
%W07_VARS  7주차의 값 전부를 struct 하나로.
%          Every Week 7 value as one struct.
%
%   러너 넷 — `W07_openloop_run` · `W07_alloc_run` · `W07_wpt_run` ·
%   `W07_pose_run` — 이 쓰고, `run_alone` 이 사람이 Run 을 눌렀을 때 **없는
%   변수만** 이것으로 채운다. `W07_0_setup` 과 **같은 값**이고, 다른 것은
%   둘뿐이다 — 실시간 화면을 끄고(`animate = 0`), 현실 시간 진행을 끈다
%   (`pace = 0`). 사람이 Run 을 누를 때와 스크립트가 여러 경우를 돌릴 때
%   **물리는 같고 기다리는 시간만 다르다**.
%
%   Used by the four run scripts and by run_alone, which fills only the
%   variables a fresh workspace is missing. The values are those of W07_0_setup
%   with two exceptions: the live view is off and pacing is off. The physics is
%   identical; only the waiting differs.
%
%   값을 두 군데 적지 않으려고 추진기 배치와 한계는 `otter_config` 에서 만든다.
%
%   See also W07_0_SETUP, W07_OPENLOOP_RUN, W07_ALLOC_RUN, W07_WPT_RUN,
%            W07_POSE_RUN.

cfg = otter_config('quad_tilt');

% --- 적재와 해류 / payload and current
V.mp     = 25;
V.rp     = [0.05 0 -0.35]';
V.V_c    = 0.0;
V.beta_c = pi/2;

% --- 추진기 배치와 한계 / stations and limits
V.quad       = [cfg.pos ; cfg.alpha_max ; cfg.mount];
V.alpha_lim  = cfg.alpha_max(1);
V.alpha_rate = cfg.alpha_rlim(1);
V.n_max      = cfg.n_max;
V.n_min      = cfg.n_min;
V.k_pos      = cfg.k_pos;
V.k_neg      = cfg.k_neg;

% --- 명령 / the command.  절 스크립트가 이 둘만 바꿔 여덟 경우를 만든다
V.n_cmd     = [60 60 60 60]';
V.d_cmd = deg2rad([45 45 45 45])';

% --- 제어배분 / control allocation (W07_alloc_chain)
%     `law` 하나가 법칙을 고른다 / one number selects the law
%       1 최소노름 · 2 가중 최소노름 · 3 가중 + 각 한계로 접기 · 4 두 한계를 제약으로
%     기본값 4 — §7-12 의 법칙 선택 표. 절 스크립트는 `set_vars` 로 저마다 덮어쓴다
%     the default is 4; each section of W07_alloc_run overrides it in set_vars
V.law       = 4;
V.tau_cmd   = [0; 40; 0];        % 순수 횡력 요구 / a pure sway demand, N and N m
V.B_alloc   = cfg.B;             % 3x8.  W03 의 열 규칙에서 나온 것
V.W_alloc   = diag(repmat([1 10], 1, 4));
V.Q_tau     = eye(3);
V.eps_reg   = 1e-4;
V.T_pos     = cfg.k_pos * cfg.n_max^2;   % 전진 추력 한계 / ahead thrust cap, N
V.T_neg     = cfg.k_neg * cfg.n_min^2;   % 후진 추력 한계 — 양수로 쓴다 / astern, N
V.n_chord   = 3;                 % 추력 캡을 내접 현 셋으로 본다 / three chords

% --- 닫힌 루프의 게인 / the closed-loop gains (W07_wpt_los · W07_pose_dp)
%     설명은 `W07_0_setup` 에 있다. 여기는 **같은 숫자**만 둔다
%     the reasoning is in W07_0_setup; only the numbers live here
V.Kp_u  = 200;   V.Ki_u = 200;
V.Kp_v  = 200;   V.Ki_v = 200;
V.Kb    = 1;
V.X_max = 120;
V.Y_max = 120;
V.Kp    = 300;   V.Kd   = 100;
V.N_lim = 150;

% --- 웨이포인트 추종 / waypoint following (W07_wpt_los)
V.WP_N        = [0  60  60   0   60]';
V.WP_E        = [0   0  60  60  120]';
V.Delta       = 5;
V.R_switch    = 3;
V.stop_at_end = 1;
V.stop_hold   = 15;
V.u_d         = 1.0;

% --- 위치와 선수각 / position and heading (W07_pose_dp)
V.p_d     = [10; 10];
V.psi_set = deg2rad(45);
V.Kp_pos  = 0.30;
V.u_lim   = 0.80;
V.v_lim   = 0.60;

% --- 시작 상태 / the start state
V.x0 = zeros(12,1);

% --- 실시간 화면은 끈다 / the live view is off in batch
V.animate       = 0;
V.animate_every = 0.5;
V.pace          = 0;
V.track_Emin    = -60;
V.track_Emax    =  140;
V.track_Nmin    = -60;
V.track_Nmax    =  140;

% --- 시뮬레이션 / the simulation
V.h       = 0.02;
V.T_final = 30;                  % 스크립트는 30 s, 사람이 누를 때는 60 s
V.T_wpt   = 400;                 % 웨이포인트 넷. Stop 블록이 먼저 선다
V.T_pose  = 60;                  % 10 m 를 가고 머무는 것까지 — 20 s 면 선다
end
