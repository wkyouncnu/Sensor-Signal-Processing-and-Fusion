function ensure_base_vars(V)
%ENSURE_BASE_VARS  Put a week's variables into the base workspace if missing.
%
%   ensure_base_vars(W04_vars)
%
%   WHY A BUILDER NEEDS THIS
%
%   Every Constant block in this course holds a NAME, not a number, so that a
%   student edits WXX_0_setup.m and never opens a block. Simulink validates
%   the name the moment set_param writes it, which means the name has to
%   resolve in the base workspace WHILE THE MODEL IS BEING BUILT.
%
%   Run the builder in a fresh session and it fails on the first Constant:
%
%       Invalid setting for parameter 'Value' ... 'mp'
%
%   which reads like a corrupt model and is nothing of the kind. This puts
%   the defaults in place so the builder can finish.
%
%   IT DOES NOT OVERWRITE. A variable the student has already set is left
%   alone, so rebuilding a model never silently discards a changed gain.

fn = fieldnames(V);
for i = 1:numel(fn)
    if ~evalin('base', sprintf('exist(''%s'',''var'')', fn{i}))
        assignin('base', fn{i}, V.(fn{i}));
    end
end
end
