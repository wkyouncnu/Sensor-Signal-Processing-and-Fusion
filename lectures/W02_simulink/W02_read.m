function R = W02_read(model, varargin)
%W02_READ  모델 하나를 강의 기본값으로 한 번 돌리고, 신호를 이름으로 돌려준다.
%         Run one Week 2 model once with the lecture defaults; return named signals.
%
%   R = W02_read('W02_C_P', 'Kp', 10)
%   R = W02_read('W02_H_antiwindup', 'block_mode', 'none')   PID 블록의 안티와인드업 방식
%
%   R.t, R.y_d, R.y, R.tau, R.I, R.D   (두 줄 모델은 R.y_blk, R.tau_blk 도)

V = W02_vars();
in = Simulink.SimulationInput(model);
for i = 1:2:numel(varargin)
    if strcmp(varargin{i}, 'block_mode')
        in = in.setBlockParameter([model '/PID block'], 'AntiWindupMode', varargin{i+1});
    else
        V.(varargin{i}) = varargin{i+1};
    end
end
f = fieldnames(V);
for i = 1:numel(f), in = in.setVariable(f{i}, V.(f{i})); end
evalc('out = sim(in);');
L = out.W02log;
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end

%  열 순서는 모델의 Scope 와 같다: [위치 칸, 힘 칸]
%  Column order is the Scope's: [position panel, force panel]
R.t = L.time;  z = zeros(size(R.t));
switch size(y,2)
    case 3, R.y_d = y(:,1); R.y = y(:,2); R.tau = y(:,3); R.I = z; R.D = z;        % P
    case 4, R.y_d = y(:,1); R.y = y(:,2); R.tau = y(:,3); R.I = z; R.D = y(:,4);   % P + D
    case 5, R.y_d = y(:,1); R.y = y(:,2); R.tau = y(:,3); R.I = y(:,4); R.D = y(:,5);
    case 7, R.y_d = y(:,1); R.y = y(:,2); R.y_blk = y(:,3);                         % two rows
            R.tau = y(:,4); R.tau_blk = y(:,5); R.I = y(:,6); R.D = y(:,7);
end
R.V = V;
end
