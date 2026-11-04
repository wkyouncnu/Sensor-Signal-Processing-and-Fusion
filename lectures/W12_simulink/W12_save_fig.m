function W12_save_fig(fig, p)
%W12_SAVE_FIG  그림 하나를 150 dpi PNG 로 저장한다. 절 스크립트 공용.
%  `exportgraphics` 가 없는 릴리스에서는 `print` 로 떨어진다. 절 스크립트마다
%  같은 try/catch 를 베끼지 않기 위해 여기 하나로 둔다.
try
    exportgraphics(fig, p, 'Resolution', 150);
catch
    print(fig, p, '-dpng', '-r150');
end
fprintf('\n    saved %s\n', p);
end
