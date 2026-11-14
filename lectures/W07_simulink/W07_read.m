function R = W07_read(model, varargin)
%W07_READ  모델을 한 번 돌리고 로그를 **이름 붙은 필드**로 돌려준다.
%          Run a model once and return the log with named fields.
%
%   R = W07_read(model)
%   R = W07_read(model, 'n_cmd', [60 60 -60 -60]', 'd_cmd', d, ...)
%
%   열 번호를 세지 않는다. 로그의 열 순서는 `_tools/add_measurement` 이 정하고,
%   이 함수가 그것을 이름으로 바꾼다. 절 스크립트는 `R.delta(:,3)` 이라고 쓴다 —
%   `y(:,13)` 이라고 쓰지 않는다. 열이 하나 늘면 고칠 곳이 **이 파일 하나**다.
%
%   앞 여섯 열은 **온 과정이 같다** — `[u v r N E psi]`, psi 는 **도**.
%   7주차가 더하는 것은 여덟 열이고, 둘 다 네 폭의 벡터다.
%
%       1..6    u v r N E psi        psi 는 도 / in DEGREES
%       7..10   n(1) .. n(4)         축회전수 [rad/s], **서보 뒤의 값**
%       11..14  delta(1) .. delta(4) 틸팅 각 [rad], **서보 뒤의 값**
%
%   기록되는 것은 **서보를 지난 뒤**의 값이다 / what is logged is POST-SERVO
%     로그는 `servo limits` 서브시스템의 출력에서 갈라져 온다. 그래서 명령이
%     한계를 넘었을 때 기록된 값은 명령이 아니라 **배가 실제로 받은 것**이고,
%     각도에는 변화율 제한까지 들어 있다. 명령과 견주려면 `R.V.n_cmd` 와
%     `R.V.d_cmd` 가 같은 struct 안에 있다 — 포화를 보는 자리가 이것이다.
%     The log branches off the servo subsystem's outputs, so a command beyond a
%     limit is recorded as what the hull actually received, rate limit included.
%     The command itself is in R.V, which is how saturation is measured.
%
%   추력은 기록하지 않고 되돌린다 / the thrust is recovered, not logged
%     3주차의 곡선 T = k n|n| 이다. 기록된 n 은 서보 뒤의 값이라 언제나
%     [n_min, n_max] 안에 있고 그 구간에서 곡선이 단조이므로, 되돌린 값은
%     **선체가 실제로 받은** 추력과 정확히 같다. 전진과 후진의 계수가 다르다.
%
%   See also W07_VARS, W07_PLOT, W07_V_OPENLOOP, W07_1_BUILD_OPENLOOP.

V = W07_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end

%  StopFcn 의 W07_plot 을 재운다. 이 실행의 로그는 `out` 안에 있지 기본
%  작업공간에 있지 않다 — 기본 작업공간의 W07 는 사람이 Run 을 눌렀을 때의
%  **오래된** 것이다 / silence the StopFcn: this run's log is inside `out`
evalin('base', 'W07batch = true;');
c = onCleanup(@() evalin('base', 'clear W07batch'));
evalc('out = sim(in);');
clear c

L = out.W07;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

R.t = L.time;  R.V = V;
R.u   = y(:, 1);  R.v   = y(:, 2);  R.r   = y(:, 3);
R.N   = y(:, 4);  R.E   = y(:, 5);  R.psi = y(:, 6);     % [deg]
R.n     = y(:,  7:10);                                   % [rad/s], 서보 뒤
R.delta = y(:, 11:14);                                   % [rad],   서보 뒤

%  추력으로 되돌린다 / back to thrust, with the Week 3 curve
R.T = thrust(R.n, V.k_pos, V.k_neg);

%  서보가 명령을 깎았는가 / did a servo clip its command
R.n_clip = any(abs(abs(R.n(end,:))     - V.n_max)     < 1e-6 | ...
               abs(abs(R.n(end,:))     - abs(V.n_min))< 1e-6);
R.d_clip = any(abs(abs(R.delta(end,:)) - V.alpha_lim) < 1e-9);
end

% =========================================================================
function T = thrust(n, k_pos, k_neg)
%  T = k n|n|,  전진과 후진의 계수가 다르다 / different coefficients each way
k = k_pos*(n >= 0) + k_neg*(n < 0);
T = k .* n .* abs(n);
end
