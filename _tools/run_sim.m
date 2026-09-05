function o = run_sim(model, V, varargin)
%RUN_SIM  One simulation of MODEL, with the variables in V, without touching
%         the base workspace.
%
%   o = run_sim('W02_surge_control', V)
%   o = run_sim('W02_surge_control', V, 'Kp', 500, 'Ki', 0)
%
%     model    model name, already built
%     V        struct of every variable the model needs
%     ...      name/value pairs that override fields of V for this run only
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
