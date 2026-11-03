function V = W12_vars()
%W12_VARS  12주차의 값 전부를 struct 하나로.
%          Every Week 12 value as one struct.
%
%   절 스크립트와 `W12_read` 가 쓴다. `W12_0_setup` 과 **같은 값**이고, 다른 것은
%   셋뿐이다 — 실시간 화면을 끄고(`animate = 0`), 현실 시간 진행을 끄고
%   (`pace = 0`), 더 짧게 돈다. 사람이 Run 을 누를 때와 스크립트가 여섯 경우를
%   돌릴 때 **물리는 같고 기다리는 시간만 다르다**.
%
%   Used by the section script and by W12_read. The values are those of
%   W12_0_setup with three exceptions: the live view is off, pacing is off and
%   the run is shorter. The physics is identical; only the waiting differs.
%
%   값을 두 군데 적지 않으려고 추진기 배치와 한계는 `otter_config` 에서 만든다.
%
%   See also W12_0_SETUP, W12_READ, W12_V_OPENLOOP.

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
end
