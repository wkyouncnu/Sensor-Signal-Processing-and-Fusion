function W12_plot_weights(cfg, wlist, sf, sp, md, H1, H2, shr1, shr2, outdir)
%W12_PLOT_WEIGHTS  §12-9 의 그림 — 값표가 못 하는 것(왼쪽)과 하는 것(오른쪽).
%  절 스크립트(`W12_H_weights`)를 얇게 두기 위해 그림만 여기로 뺐다
%  (`vault_check.sh` §18, 실행 줄 45 이하).
%
%  왼쪽 축에는 힘 둘(N), 오른쪽 축에는 각 하나(deg). 단위가 다른 것을
%  한 축에 올리면 30 N 과 30 deg 가 포개져 같은 곡선으로 보인다 — 나누어 그린다.
%
%  The figure of 12-9: what the price list cannot do (left) and what it can
%  (right). It sits in its own function to keep the section script thin
%  (vault_check.sh 18, at most 45 executable lines). Two forces (N) go on the
%  left axis and one angle (deg) on the right: put on one axis, 30 N and
%  30 deg would lie on top of each other and read as the same curve.

fig = figure('Color','w','Position',[80 80 920 340]);

subplot(1,2,1)
yyaxis left
semilogx(wlist, sf, 'd:', 'LineWidth',1.6,'MarkerFaceColor','auto'); hold on
semilogx(wlist, sp, 's-', 'LineWidth',1.8,'MarkerFaceColor','auto');
ylabel('force components  [N]');  ylim([0 40]);
yyaxis right
semilogx(wlist, md, 'o-', 'LineWidth',1.8,'MarkerFaceColor','auto'); hold on
yline(rad2deg(cfg.alpha_max(1)), '--', '45 deg servo wall', 'LineWidth',1.2, ...
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

W12_save_fig(fig, fullfile(outdir, 'img', 'W12_alloc_weights.png'));
end
