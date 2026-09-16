function f = export_diagram(mdl, folder)
%EXPORT_DIAGRAM  모델의 블록도를 강의노트가 싣는 PNG 로 저장한다.
%                Save a model's block diagram as the PNG the lecture embeds.
%
%   export_diagram('W02_surge_control')            -> ./img/W02_surge_control.png
%   export_diagram(mdl, '/path/to/img')
%
%   **빌더의 끝에서 부른다.** 절 스크립트에서 부르지 않는다.
%   블록도는 모델이 바뀔 때 바뀌지, 실험을 돌릴 때 바뀌지 않는다. 절 스크립트가
%   저장하게 두면 모델을 고친 뒤 실험을 돌리지 않은 동안 도면이 뒤처진다.
%   vault_check §6 이 그 뒤처짐을 세므로, 잡히면 그 주차를 다시 돌린다.
%
%   Call this at the end of the builder, not from a runner. A block diagram
%   changes when the model changes, not when an experiment is run; leaving the
%   save to a section script lets the diagram fall behind a model that has been
%   edited but not yet exercised. vault_check §6 counts that staleness, and
%   when it does, the week is run again.
%
%   The diagram depends on the builder and on nothing else: it does not change
%   when a gain changes, so regenerating it from every experiment script is
%   wasted work and leaves the figure's age depending on which script ran last.
%   The builder is also the only place that is guaranteed to have just produced
%   a correct model.
%
%   -r150 keeps a chain of five subsystems under the 2000 px the lecture PDF
%   can display, which vault_check enforces.

if nargin < 2 || isempty(folder), folder = fullfile(pwd, 'img'); end
if ~isfolder(folder), mkdir(folder); end

f = fullfile(folder, [mdl '.png']);

opened = false;
if ~bdIsLoaded(mdl), load_system(mdl); opened = true; end
print(['-s' mdl], '-dpng', '-r150', f);
if opened, close_system(mdl, 0); end
end
