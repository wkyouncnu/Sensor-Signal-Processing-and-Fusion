function W12_plot_limits(S, amax, outdir)
%W12_PLOT_LIMITS  §12-10 의 그림 — 벽과 그 대가. `W12_sweep_laws` 의 결과를 받는다.
%  절 스크립트(`W12_I_limits`)를 얇게 두기 위해 그림만 여기로 뺐다
%  (`vault_check.sh` §18, 실행 줄 45 이하).
%
%  해가 없는 구간은 `NaN` 으로 끊는다 — 실행 불가능한 반복값을 선으로 이으면
%  풀린 것처럼 보인다 (`standing-orders.md` §15-76).
%
%  The figure of 12-10: the wall, and what it costs. It takes the result of
%  W12_sweep_laws, and sits in its own function to keep the section script
%  thin (vault_check.sh 18, at most 45 executable lines). Stretches with no
%  solution are broken with NaN: joining infeasible iterates with a line makes
%  them look solved (standing-orders.md 15-76).

t = S.t;  mth = S.mth;  nm = numel(mth);
fig = figure('Color','w','Position',[60 60 820 560]);
cl = lines(nm);
% qp 는 해가 나오는 구간에서 wls16 과 겹친다 — 굵게 그려 테두리로 보이게 한다.
% where qp does find a solution it coincides with wls16, so it is drawn thick
% and the overlap shows as a halo
lw = 1.5*ones(1,nm);  lw(strcmp(mth,'qp')) = 3.5;

subplot(2,1,1); hold on; grid on
hl = gobjects(1, nm+1);
for a = 1:nm
    ok = S.EF(a,:) > 0;  d = S.D1(a,:);  d(~ok) = NaN;
    hl(a) = plot(t, d, 'LineWidth',lw(a),'Color',cl(a,:));
end
yline( amax,'k--','LineWidth',1.2);
yline(-amax,'k--','LineWidth',1.2);
% qp 가 해를 못 낸 순간을 바닥에 찍는다 — 그 구간에서 qp 곡선이 사라진다
% the instants where qp found no solution are marked along the bottom, since
% the qp curve itself is absent there
iq  = find(strcmp(mth,'qp'));
bad = t(S.EF(iq,:) <= 0);
hl(nm+1) = plot(bad, -99*ones(size(bad)), 's', 'MarkerSize',3, ...
                'MarkerFaceColor',[.75 0 0], 'MarkerEdgeColor','none');
ylim([-105 100]);
ylabel('\delta_1  [deg]');
legend(hl, [cellstr(mth), {'qp: no solution'}], ...
       'Location','eastoutside','FontSize',8);
title(sprintf('Servo angle of unit 1 — the dashed lines are the %.0f deg wall', amax));

subplot(2,1,2); hold on; grid on
for a = 1:nm
    ok = S.EF(a,:) > 0;  e = S.ER(a,:);  e(~ok) = NaN;
    plot(t, e, 'LineWidth',lw(a),'Color',cl(a,:));
end
ylabel('|| \tau_{achieved} - \tau_{demanded} ||  [N]');  xlabel('t  [s]');
legend(mth,'Location','eastoutside','FontSize',8);
title('What each law pays for staying inside the wall');

W12_save_fig(fig, fullfile(outdir, 'img', 'W12_alloc_limits.png'));
end
