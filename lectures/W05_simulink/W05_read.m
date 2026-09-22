function R = W05_read(model, varargin)
%W05_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 5 model once with the lecture defaults; return named signals.
%
%   R = W05_read('W05_D_LOS', 'Delta', 5)
%   R = W05_read('W05_D_LOS', 'WP_N', [0 300]', 'WP_E', [0 0]')    곧은 경로 하나 / one straight leg
%
%   R.t      시간 / time                                  [s]
%   R.y_e    횡방향 오차 (경로 오른쪽이 +) / cross-track error (right of the path +)  [m]
%   R.psi_d  명령 선수각 / commanded heading              [deg]
%   R.psi    선수각 / heading                             [deg]
%   R.N, R.E 위치 / position                              [m]
%   R.aux    ILOS 적분 상태 (다른 법칙은 0) / the ILOS integral state (0 for the others)
%   R.wp     현재 다리 번호 / the active leg
%
%   E0 를 바꾸면 초기상태 x0 도 함께 바꾼다 / changing E0 also changes the initial state x0.

V = W05_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
V.x0(8) = V.E0;
in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W05log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

%  열 순서는 모델의 log Mux 와 같다 / column order is the model's log Mux
R.t = L.time;  R.V = V;
R.y_e = y(:,1);  R.psi_d = y(:,2);  R.psi = y(:,3);
R.N = y(:,4);    R.E = y(:,5);      R.aux = y(:,6);  R.wp = y(:,7);
end
