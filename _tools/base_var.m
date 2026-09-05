function v = base_var(name, dflt)
%BASE_VAR  A variable from the base workspace, or a default when it is absent.
%
%   v = base_var('animate_every', 0.5)
%
%   Used by the live-view functions, which run inside a simulation and must not
%   fail because a student cleared a variable. Anything the live view needs but
%   cannot find falls back to a stated default rather than stopping the run.

if evalin('base', sprintf('exist(''%s'',''var'')', name))
    v = evalin('base', name);
else
    v = dflt;
end
end
