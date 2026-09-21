function R = W04_read(model, varargin)
%W04_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 4 model once with the lecture defaults; return named signals.
%
%   R = W04_read('W04_D_P', 'Kp', 300)
%
%   R.t, R.psi_d, R.psi [deg], R.N, R.I, R.D [N m]  (열린 루프는 R.psi, R.N 만 / open loop: R.psi and R.N)
%   N_max 는 X_ff 가 바뀌면 다시 계산한다 / N_max is recomputed when X_ff changes.

V = W04_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
if any(strcmp(varargin(1:2:end), 'X_ff')) && ~any(strcmp(varargin(1:2:end), 'N_max'))
    V.N_max = min(2*V.y_pont*(V.T_hi - V.X_ff/2), 2*V.y_pont*(V.X_ff/2 - V.T_lo));
end
in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W04log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

%  열 순서는 Scope 와 같다: [선수각 칸, 모멘트 칸] / column order is the Scope's
R.t = L.time;  z = zeros(size(R.t));  R.V = V;
switch size(y,2)
    case 2, R.psi = y(:,1); R.N = y(:,2); R.psi_d = z; R.I = z; R.D = z;        % open loop
    case 3, R.psi_d = y(:,1); R.psi = y(:,2); R.N = y(:,3); R.I = z; R.D = z;   % P
    case 4, R.psi_d = y(:,1); R.psi = y(:,2); R.N = y(:,3); R.I = z; R.D = y(:,4);   % PD
    case 5, R.psi_d = y(:,1); R.psi = y(:,2); R.N = y(:,3); R.I = y(:,4); R.D = y(:,5);
end
end
