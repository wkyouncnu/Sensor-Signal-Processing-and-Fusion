function R = W06_read(model, varargin)
%W06_READ  모델을 한 번 돌리고 로그를 **이름 붙은 필드**로 돌려준다.
%          Run a model once and return the log with named fields.
%
%   R = W06_read(model)
%   R = W06_read(model, 'Kp_v', 300, 'Y_max', 20, ...)
%
%   열 번호를 세지 않는다. 로그의 열 순서는 `_tools/add_measurement` 이 정하고,
%   이 함수가 그것을 이름으로 바꾼다. 절 스크립트는 `R.v`, `R.F_B` 라고 쓴다 —
%   `y(:,2)` 라고 쓰지 않는다. 열이 하나 늘면 고칠 곳이 **이 파일 하나**다.
%   Column numbers are not counted anywhere else. The order is fixed by
%   _tools/add_measurement and turned into names here, so a section script says
%   R.v, not y(:,2). Adding one column changes this file only.
%
%   앞 여섯 열은 **온 과정이 같다** — `[u v r N E psi]`, psi 는 **도**
%
%   이것은 6주차가 고른 것이 아니라 `add_measurement` 이 모든 주차에 강제하는
%   계약이다. 그래서 한 주차의 로그를 읽는 코드가 다른 주차의 로그도 읽는다.
%   여섯 열 **뒤에** 그 주차가 더한 것이 붙고, 6주차가 더한 것이 열 열셋이다.
%   또 기록되는 작업공간 변수의 이름은 **태그 그대로** `W06` 이다 —
%   `W06log` 가 아니다.
%   The first six columns are the same in every week -- [u v r N E psi], with
%   psi in DEGREES. That is not Week 6's choice but the contract
%   add_measurement imposes on the whole course, so code that reads one week's
%   log reads another's. Each week appends its own columns AFTER those six, and
%   Week 6 appends thirteen. The logged workspace variable is named after the
%   tag itself -- W06, not W06log.
%
%   일곱 모델이 **같은 19 열**을 쓴다. 없는 신호는 NaN Constant 가 채운다 —
%   열 수가 모델마다 다르면 절 스크립트가 모델을 알아야 하고, 그러면 표 하나를
%   두 모델로 채울 수 없다.
%
%   마지막 두 열 `u_d` · `v_d` 는 **바깥 위치 고리가 지시한 속도**이고, 늘
%   **몸체 축**이다. 7 절의 NED 고리는 NED 성분으로 제어하지만, 기록되는 두
%   열은 한 번 돌려서 몸체로 맞춘다 — 그래서 `R.u` 와 `R.u_d` 를 바로 견주어
%   안쪽 고리의 추종을 볼 수 있다.
%   The last two columns are the velocity the OUTER loop asked for, always in
%   body axes, so R.u and R.u_d may be compared directly. The NED rung controls
%   in NED components but rotates once for the log.
%   All seven models log the SAME 19 columns; a NaN constant fills a signal a
%   model does not have. Differing widths would force a section script to know
%   which model it ran, and then one table could not be filled from two of them.
%
%   psi 와 psi_set 은 **둘 다 도**로 들어온다. 앞의 것은 add_measurement 안의
%   rad2deg 게인이, 뒤의 것은 모델 최상위의 rad2deg 게인이 바꾼다. 둘을 빼서
%   오차를 내는 자리가 많으므로 단위가 같아야 한다.
%   psi and psi_set both arrive in DEGREES -- the first through the rad2deg gain
%   inside add_measurement, the second through a rad2deg gain at the model's top
%   level. They are subtracted from each other in several places, so they must
%   share a unit.
%
%   THE THRUSTS ARE RECONSTRUCTED, NOT LOGGED
%
%   모델이 기록하는 것은 **축 회전수** n 이다 — 추진기에 실제로 보내는 값이다.
%   추력은 3주차의 곡선 T = k n|n| 으로 되돌린다. 배분기가 추력을 먼저 자른
%   뒤에 n 을 구하므로 n 은 언제나 [n_min, n_max] 안에 있고, 그 구간에서 이
%   곡선은 단조이므로 되돌리는 값이 배분기가 실제로 요구한 추력과 **정확히**
%   같다. k 의 분기(전진 k_pos, 후진 k_neg)는 배분기와 같은 식을 쓴다.
%   What the model records is the SHAFT SPEED n, which is what the thruster is
%   actually given. The thrust is recovered with the Week 3 curve T = k n|n|.
%   The allocation clips the thrust BEFORE inverting the curve, so n always lies
%   in [n_min, n_max], where the curve is monotone; the recovered value is
%   therefore exactly the thrust the allocation asked for. The k branch
%   (k_pos ahead, k_neg astern) is the one the allocation uses.
%
%   See also W06_VARS, W06_PLOT, W06_1_BUILD_BOW.

V = W06_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end

in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end

%  StopFcn 의 W06_plot 을 재운다. 절 스크립트는 그림을 스스로 그리고, 이 로그는
%  `out` 안에 있지 기본 작업공간에 있지 않다 — 기본 작업공간의 W06 은 사람이
%  Run 을 눌렀을 때의 **오래된** 것이다 / silence the StopFcn: this run's log is
%  inside `out`, and the base-workspace W06 is a stale one from a manual Run.
evalin('base', 'W06batch = true;');
c = onCleanup(@() evalin('base', 'clear W06batch'));
evalc('out = sim(in);');
clear c

L = out.W06;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

%  열 순서는 add_measurement 이 정한다 / the order add_measurement fixes:
%     1..6   온 과정의 계약 / the course-wide contract, psi in degrees
%     7..19  6주차가 더한 열 / the thirteen Week 6 appends
R.t = L.time;  R.V = V;
R.u     = y(:, 1);  R.v     = y(:, 2);  R.r       = y(:, 3);
R.N     = y(:, 4);  R.E     = y(:, 5);  R.psi     = y(:, 6);   % [deg]
R.N_set = y(:, 7);  R.E_set = y(:, 8);  R.psi_set = y(:, 9);   % [deg]
R.X_dem = y(:,10);  R.Y_dem = y(:,11);  R.N_dem   = y(:,12);
R.n_L   = y(:,13);  R.n_R   = y(:,14);  R.F_B     = y(:,15);
R.d     = y(:,16);  R.phase = y(:,17);
R.u_d   = y(:,18);  R.v_d   = y(:,19);                 % 몸체 / body axes

%  추력으로 되돌린다 / back to thrust, with the Week 3 curve
R.T_L = thrust(R.n_L, V.k_pos, V.k_neg);
R.T_R = thrust(R.n_R, V.k_pos, V.k_neg);

%  요구가 걸린 자리. 안쪽 루프의 포화는 힘에 걸리므로 힘으로 센다 (6-2 절)
%  where the demand was clipped: the inner loops saturate on force (6-2)
R.X_clip = abs(abs(R.X_dem) - V.X_max) < 1e-6;
R.Y_clip = abs(abs(R.Y_dem) - V.Y_max) < 1e-6;
end

% =========================================================================
function T = thrust(n, k_pos, k_neg)
%  T = k n|n|,  전진과 후진의 계수가 다르다 / different coefficients each way
k = k_pos*(n >= 0) + k_neg*(n < 0);
T = k .* n .* abs(n);
end
