function f = export_diagram(mdl, folder)
%EXPORT_DIAGRAM  Save a model's block diagram as the PNG the lecture embeds.
%
%   export_diagram('W02_surge_control')            -> ./img/W02_surge_control.png
%   export_diagram(mdl, '/path/to/img')
%
%   CALL THIS AT THE END OF THE BUILDER, not from a runner.
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
