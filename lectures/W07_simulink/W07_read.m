function R = W07_read(model, varargin)
%W07_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 7 model once with the lecture defaults; return named signals.
%
%   R = W07_read('W07_E_notch', 'zeta_n', 0.02)
%
%   파랑만 있는 모델 (W07_C_wave) / the sea on its own
%       R.psi_w  1차 파랑이 만드는 선수각 / the wave-induced heading   [deg]
%       R.r_w    그 변화율 / its rate                                  [deg/s]
%
%   루프가 있는 모델 / the models with a loop
%       R.psi_d  명령 / the command                                    [deg]
%       R.psi    배의 진짜 선수각 / the true heading                   [deg]
%       R.psi_m  계측값 = 진짜 + 파랑 / the measurement                [deg]
%       R.psi_f  제어기가 실제로 쓰는 값 / what the controller uses     [deg]
%       R.N      요 모멘트 / the yaw moment                            [N m]
%       R.n1, R.n2  회전수 / shaft speeds                              [rad/s]
%       R.r      진짜 회두율 / the true yaw rate                       [deg/s]

V = W07_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
%  파랑 성분은 스펙트럼 값이 바뀌면 다시 만든다 / rebuild the train if the sea changed
[V.w_i, V.a_i, V.phi_i, V.k_w] = wave_train(V.Hs, V.T0, V.gamma_j, V.N_comp, V.sigma_psi);
in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W07log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
R.t = L.time;  R.V = V;
if size(y,2) == 2
    R.psi_w = y(:,1);  R.r_w = y(:,2);
else
    R.psi_d = y(:,1);  R.psi = y(:,2);  R.psi_m = y(:,3);  R.psi_f = y(:,4);
    R.N = y(:,5);      R.n1 = y(:,6);   R.n2 = y(:,7);     R.r = y(:,8);
end
end
