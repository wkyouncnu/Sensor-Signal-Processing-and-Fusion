function R = W03_read(model, varargin)
%W03_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 3 model once with the lecture defaults; return named signals.
%
%   R = W03_read('W03_D_P', 'Kp', 400)
%
%   R.t, R.u_d, R.u, R.X, R.I, R.D   (열린 루프 모델은 R.X, R.u 만 / open loop: R.X and R.u)

V = W03_vars();
in = Simulink.SimulationInput(model);
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W03log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

%  열 순서는 Scope 와 같다: [속도 칸, 힘 칸] / column order is the Scope's
R.t = L.time;  z = zeros(size(R.t));  R.V = V;
switch size(y,2)
    case 2, R.u = y(:,1);  R.X = y(:,2);                                  % open loop
            R.u_d = z; R.I = z; R.D = z;
    case 3, R.u_d = y(:,1); R.u = y(:,2); R.X = y(:,3); R.I = z; R.D = z; % P
    case 5, R.u_d = y(:,1); R.u = y(:,2); R.X = y(:,3); R.I = y(:,4); R.D = y(:,5);
end
end
