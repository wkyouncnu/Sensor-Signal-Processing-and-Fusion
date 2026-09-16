function o = run_sim(model, V, varargin)
%RUN_SIM  기본 작업공간을 건드리지 않고 모델을 한 번 시뮬레이션한다.
%         One simulation of a model, with the variables in V, without touching
%         the base workspace.
%
%   o = run_sim('W02_surge_control', V)
%   o = run_sim('W02_surge_control', V, 'Kp', 500, 'Ki', 0)
%
%     model    이미 만들어져 있는 모델의 이름 / the model name, already built
%     V        모델이 필요로 하는 모든 변수의 구조체
%              a struct of every variable the model needs
%     ...      이 실행에서만 V 의 항목을 덮어쓰는 이름·값 쌍
%              name/value pairs overriding fields of V for this run only
%
%   왜 작업공간을 건드리지 않는가 / why the base workspace is left alone
%       절 스크립트는 게인 하나만 바꾸어 같은 모델을 여러 번 돌린다. 값을 기본
%       작업공간에 써 가며 돌리면 마지막 실행의 값이 남고, 그 뒤에 학생이 모델을
%       열어 Run 을 누르면 준비 스크립트가 넣어 둔 값이 아니라 스윕의 마지막
%       값으로 돈다. 그런 종류의 불일치는 원인을 찾기 어렵다.
%
%       A section script runs the same model several times, changing one gain
%       at a time. Writing those values into the base workspace would leave
%       the last of them behind, so that opening the model and pressing Run
%       afterwards would use the end of a sweep rather than what the setup
%       script put there. That kind of discrepancy is hard to trace.
%
%   Returns
%     o.t      time
%     o.y      the logged matrix, first six columns [u v r N E psi] as always
%
%   WHY EVERY WEEK USES THIS
%
%   Each section script needs to run the same model two or three times with one
%   gain changed. Doing that by assigning into the base workspace leaves the
%   workspace in the state of the LAST run, so a student who then presses Run in
%   Simulink gets something that does not match the figure they are looking at.
%   Simulink.SimulationInput keeps each run's variables to itself.
%
%   The logged variable is found by name rather than assumed: a model built by
%   add_measurement logs to a variable named after its tag, and this returns
%   whichever one the model produced.

in = Simulink.SimulationInput(model);

for i = 1:2:numel(varargin)
    V.(varargin{i}) = varargin{i+1};
end
fn = fieldnames(V);
for i = 1:numel(fn)
    in = in.setVariable(fn{i}, V.(fn{i}));
end

evalc('r = sim(in);');

%  Pull out whatever To Workspace produced, without needing to be told its name.
names = r.who;
log   = '';
for i = 1:numel(names)
    s = r.(names{i});
    if isstruct(s) && isfield(s,'signals') && isfield(s,'time')
        log = names{i};
        break
    end
end
if isempty(log)
    error('run_sim:noLog', ...
          ['%s produced no logged structure. Check that the model has a To ' ...
           'Workspace block with SaveFormat ''Structure With Time'' and that ' ...
           'ReturnWorkspaceOutputs is off.'], model);
end

W = r.(log);
y = squeeze(W.signals.values);
if size(y,1) < size(y,2), y = y.'; end

o.t   = W.time;
o.y   = y;
o.log = log;
end
