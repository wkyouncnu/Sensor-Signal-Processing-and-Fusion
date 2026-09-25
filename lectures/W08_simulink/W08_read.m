function R = W08_read(model, varargin)
%W08_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%          Run one Week 8 model once with the lecture defaults; return named signals.
%
%   R = W08_read('W08_D_weathervane', 'V_c', 0.5)
%
%   R.t          시간 / time                                     [s]
%   R.N_d, R.E_d 붙잡으려는 자리 / the station being held          [m]
%   R.N, R.E     배의 위치 / where the vessel is                   [m]
%   R.psi_d      명령 선수각 / the commanded heading               [deg]
%   R.psi        선수각 / the heading                              [deg]
%   R.X          전진력 / the surge force                          [N]
%   R.Nm         요 모멘트 / the yaw moment                        [N m]
%   R.mode       임무 모드 (1 이동, 2 유지, 3 끝) / the mission mode
%   R.e          위치 오차의 크기 / the distance from the station   [m]

V = W08_vars();
for i = 1:2:numel(varargin), V.(varargin{i}) = varargin{i+1}; end
in = Simulink.SimulationInput(model);
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W08log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
R.t = L.time;  R.V = V;
R.N_d = y(:,1);  R.E_d = y(:,2);  R.N = y(:,3);   R.E = y(:,4);
R.psi_d = y(:,5); R.psi = y(:,6); R.X = y(:,7);   R.Nm = y(:,8);  R.mode = y(:,9);
R.e = hypot(R.N_d - R.N, R.E_d - R.E);
end
