function R = W09_read(model, varargin)
%W09_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 9 model once with the lecture defaults; return named signals.
%
%   R = W09_read('W09_C_full', 'use_ilos', 0)
%
%   R.t     시간 [s]                      R.mode  1 이동 · 2 유지 · 3 끝
%   R.N, R.E  위치 [m]                    R.psi, R.psi_d  선수각 [deg]
%   R.y_e   횡방향 오차 (이동 중) [m]      R.u     전진속도 [m/s]
%   R.X     전진력 [N]                     R.Nm    요 모멘트 [N m]
%   R.e     유지 지점까지의 거리 [m]

V = W09_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
%  바다를 바꾸면 파랑 열과 노치의 중심 주파수를 다시 만든다 / rebuild the sea and w0
V.w0 = 2*pi/V.T0;
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
%  같은 스펙트럼의 다른 실현 — 위상만 한꺼번에 옮긴다 (§9-6)
%  Another realisation of the same spectrum: the phases, all shifted by one number.
V.phi_i = mod(V.phi_i + V.phase_shift, 2*pi);
if V.use_notch == 0, V.zeta_n = V.zeta_d; end      % 노치를 끄면 H(s) = 1 / off means unity
in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W09log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
R.t = L.time;  R.V = V;
R.mode = y(:,1);  R.N = y(:,2);   R.E = y(:,3);   R.psi = y(:,4);  R.psi_d = y(:,5);
R.y_e  = y(:,6);  R.u = y(:,7);   R.X = y(:,8);   R.Nm = y(:,9);   R.wp = y(:,10);

%  유지 지점까지의 거리 / the distance to the station being held
R.e = zeros(size(R.t));
for k = 1:numel(V.WP_N)
    j = R.wp == k;
    R.e(j) = hypot(V.WP_N(k) - R.N(j), V.WP_E(k) - R.E(j));
end
end
