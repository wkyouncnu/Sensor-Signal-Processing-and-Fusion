function R = W06_read(model, varargin)
%W06_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 6 model once with the lecture defaults; return named signals.
%
%   R = W06_read('W06_F_limits', 'fit_mode', 0)
%
%   R.t              시간 / time                                     [s]
%   R.Xd, R.Yd, R.Nd 요구한 일반화 힘 / the generalised force demanded   [N, N, N m]
%   R.Xa, R.Ya, R.Na 실제로 전달된 것 / what the thrusters delivered
%   R.T1, R.T2       추진기 추력 / the two thrusts                    [N]
%   R.u              전진속도 / surge speed                          [m/s]
%   R.r              회두율 / yaw rate                               [deg/s]
%   R.V              쓰인 값들 / the values used
%
%   전달된 힘은 배분기가 **요구한** 추력이 아니라 축이 실제로 돌아 낸 추력에서 계산한다.
%   그래서 6-5 의 잘못된 역곡선이 이 신호에 그대로 드러난다.
%   The delivered force is computed from the thrust the shafts actually produce,
%   not from the thrust the allocator asked for, so the wrong inverse curve of
%   §6-5 shows up in this signal.

V = W06_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W06log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

%  열 순서는 모델의 log Mux 와 같다 / column order is the model's log Mux
R.t = L.time;  R.V = V;
R.Xd = y(:,1);  R.Yd = y(:,2);  R.Nd = y(:,3);
R.Xa = y(:,4);  R.Ya = y(:,5);  R.Na = y(:,6);
R.T1 = y(:,7);  R.T2 = y(:,8);
R.u  = y(:,9);  R.r  = y(:,10);
end
