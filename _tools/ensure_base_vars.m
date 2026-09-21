function ensure_base_vars(V)
%ENSURE_BASE_VARS  그 주차의 변수가 기본 작업공간에 없으면 채워 넣는다.
%                  Put a week's variables into the base workspace if missing.
%
%   ensure_base_vars(W05_vars)
%
%   빌더가 왜 이것을 필요로 하는가 / why a builder needs this
%       이 강의의 모든 Constant 블록은 숫자가 아니라 **이름**을 담고 있다. 학생이
%       Every Constant block in this course holds a name, not a number, so that a
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
