function W07_plot_weights(cfg, wlist, sf, sp, md, H1, H2, shr1, shr2, outdir)
%W07_PLOT_WEIGHTS  §7-9 의 그림 — 가중행렬이 바꾸지 못하는 것(왼쪽)과
%  바꾸는 것(오른쪽). `W07_CA(9)` 이 부른다.
%
%  왼쪽 축에는 힘 둘(N), 오른쪽 축에는 각 하나(deg). 단위가 다른 것을
%  한 축에 올리면 30 N 과 30 deg 가 포개져 같은 곡선으로 보인다 — 나누어 그린다.
%
%  The figure of 7-9: what the weight matrix cannot change (left) and what it
%  can (right). Called from W07_CA(9). Two forces (N) go on the left axis and
%  one angle (deg) on the right: put on one axis, 30 N and 30 deg would lie on
%  top of each other and read as the same curve.

fig = figure('Color','w','Position',[80 80 920 340]);

subplot(1,2,1)
yyaxis left
semilogx(wlist, sf, 'd:', 'LineWidth',1.6,'MarkerFaceColor','auto'); hold on
semilogx(wlist, sp, 's-', 'LineWidth',1.8,'MarkerFaceColor','auto');
ylabel('force components  [N]');  ylim([0 40]);
yyaxis right
semilogx(wlist, md, 'o-', 'LineWidth',1.8,'MarkerFaceColor','auto'); hold on
yline(rad2deg(cfg.alpha_max(1)), '--', '45 deg servo limit', 'LineWidth',1.2, ...
      'LabelHorizontalAlignment','right','LabelVerticalAlignment','bottom','FontSize',8);
ylabel('max |\delta_i|  [deg]');  ylim([0 50]);
grid on;  xlabel('w  —  price put on the sideways component f_y');
legend({'\Sigma|f_y| (pinned by Y)','|f_x| spread','max |\delta_i|'}, ...
       'Location','northwest','FontSize',8);
title({'Pricing f_y cannot reduce the tilt:','\Sigma|f_y| is fixed, so f_x goes lopsided instead'}, ...
      'FontSize',9);

subplot(1,2,2)
bar([abs(H1.T); abs(H2.T)]');  grid on
set(gca,'XTickLabel',{'unit 1','unit 2','unit 3','unit 4'});
ylabel('|T_i|  [N]');  ylim([0 58]);
legend({sprintf('equal price  (aft %.0f %%)', shr1), ...
        sprintf('aft 5x dearer  (aft %.0f %%)', shr2)}, ...
       'Location','northwest','FontSize',8);
title({'What the price list can do:','move the load between units'},'FontSize',9);

W07_save_fig(fig, fullfile(outdir, 'img', 'W07_alloc_weights.png'));
end
