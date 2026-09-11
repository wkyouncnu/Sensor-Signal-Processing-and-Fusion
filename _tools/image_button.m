function h = image_button(mdl, label, sub, pos, face, edge, fcn)
%IMAGE_BUTTON  A button on the Simulink canvas — a rounded image with a click callback.
%
%   h = image_button(mdl, 'START', 'from the beginning', [40 300 300 380], ...
%                    [0.30 0.69 0.31], [0.12 0.40 0.12], 'W01i_control(''start'')')
%
%     mdl    model name
%     label  large text on the button, and the annotation name
%     sub    small second line, '' for none
%     pos    [x1 y1 x2 y2] on the canvas
%     face   fill colour, RGB
%     edge   border colour, RGB
%     fcn    MATLAB command run on a single click
%
%   WHY AN IMAGE ANNOTATION
%
%   Three ways of putting a button on the canvas were tried in R2024b:
%
%     Dashboard Callback Button   ClickFcn and text set from code are lost on save
%     text annotation + ClickFcn  the background colour is not saved, so the
%                                 button is drawn as blue link text
%     image annotation + ClickFcn both are saved; the picture travels inside
%                                 the .slx file
%
%   The PNG is drawn at the canvas size of pos, so it is shown at 1:1, and is
%   deleted after setImage has copied it into the model.

w  = pos(3) - pos(1);
ht = pos(4) - pos(2);
f  = figure('Visible','off', 'Color','w', 'Units','pixels', 'Position',[100 100 w ht]);
ax = axes(f, 'Position',[0 0 1 1]);
axis(ax,'off');  hold(ax,'on');  xlim(ax,[0 1]);  ylim(ax,[0 1]);
rectangle(ax, 'Position',[0.03 0.07 0.94 0.86], 'Curvature',[0.35 0.8], ...
          'FaceColor',face, 'EdgeColor',edge, 'LineWidth',2.5);
if isempty(sub)
    text(ax, 0.5, 0.50, label, 'HorizontalAlignment','center', ...
         'FontSize',18, 'FontWeight','bold', 'Color','w');
else
    text(ax, 0.5, 0.60, label, 'HorizontalAlignment','center', ...
         'FontSize',18, 'FontWeight','bold', 'Color','w');
    text(ax, 0.5, 0.27, sub,   'HorizontalAlignment','center', 'FontSize',10, 'Color','w');
end
png = [tempname '.png'];
exportgraphics(f, png, 'Resolution', 96);
close(f);

h = Simulink.Annotation([mdl '/' label]);
h.Position = pos;
h.setImage(png);
h.ClickFcn = fcn;
delete(png);
end
