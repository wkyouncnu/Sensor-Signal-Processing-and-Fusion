function W12_plot_chain(RR, cfg, outdir)
%W12_PLOT_CHAIN  §12-12 의 그림 둘 — ① 요구한 힘과 **받은 힘** ② 두 포화.
%                The two figures of 12-12: the demanded force against the force
%                actually received, and the two saturations.
%
%  RR   `W12_chain` 의 결과를 담은 cell. 법칙 하나가 한 칸
%       a cell array of W12_chain results, one law per cell
%
%  그림 하나에 한 가지만 묻는다 / one question per figure
%      ① 배가 **요구한 힘을 받았는가.** 점선이 요구, 실선이 운동모델에서 잰 것
%         Did the hull receive what was asked for? Dashed is the demand, solid
%         is what was measured out of the motion model
%      ② 한계를 넘은 곳이 어디인가. 회전수와 서보각을 한계선과 함께 그린다
%         Where the limits were crossed: shaft speed and servo angle, each
%         drawn against its own limit line
%
%  `W12_CA(12)` 이 부른다 / called from W12_CA(12)

t   = RR{1}.t;  nL = numel(RR);
cl  = lines(nL);
lbl = {'X  [N]', 'Y  [N]', 'N  [N m]'};

% 법칙 둘이 **같은 답**을 내는 일이 있다 (wpinv 와 clip). 먼저 그리는 것을 굵게
% 해서 뒤의 것이 그 위에 얹히게 한다 — 그러면 겹친 것이 테두리로 보인다.
% Two laws can give the SAME answer (wpinv and clip). Earlier laws are drawn
% thicker so a later one sits on top of them and the overlap shows as a halo.
lw  = linspace(3.0, 1.2, nL);

%% 그림 ① 요구한 힘과 받은 힘 / figure 1: demanded against received -----------
fig = figure('Color','w','Position',[60 60 860 620]);
for r = 1:3
    subplot(3,1,r); hold on; grid on
    h = gobjects(1, nL+1);
    for a = 1:nL
        h(a+1) = plot(t, RR{a}.act(r,:), 'LineWidth', lw(a), 'Color', cl(a,:));
    end
    % 요구는 **맨 위에** 그린다 — 맞춘 법칙이 가리지 않도록
    % the demand is drawn last, so a law that matches it cannot hide it
    h(1) = plot(t, RR{1}.cmd(r,:), 'k--', 'LineWidth', 1.4);
    ylabel(lbl{r});
    if r == 1
        nm = cellfun(@(R) R.method, RR, 'UniformOutput', false);
        legend(h, [{'demanded by the controller'}, nm], ...
               'Location','eastoutside','FontSize',8);
        title('What the controller asked for, and what the motion model produced');
    end
end
xlabel('t  [s]');
W12_save_fig(fig, fullfile(outdir, 'img', 'W12_chain_tau.png'));

%% 그림 ② 두 포화 / figure 2: the two saturations -----------------------------
fig = figure('Color','w','Position',[60 60 860 620]);

subplot(2,1,1); hold on; grid on
for a = 1:nL
    plot(t, RR{a}.n_cmd(3,:), 'LineWidth', lw(a), 'Color', cl(a,:));
end
yline(cfg.n_max, 'k--', 'LineWidth', 1.2);
yline(cfg.n_min, 'k--', 'LineWidth', 1.2);
text(t(end), cfg.n_max, '  n_{max}', 'FontSize', 8, 'VerticalAlignment','bottom');
text(t(end), cfg.n_min, '  n_{min}', 'FontSize', 8, 'VerticalAlignment','top');
ylabel('n_3  [rad/s]');
legend(cellfun(@(R) R.method, RR, 'UniformOutput', false), ...
       'Location','eastoutside','FontSize',8);
title(sprintf(['Shaft speed demanded of unit 3 — the limits are n_{max} = %.1f and ' ...
               'n_{min} = %.1f rad/s'], cfg.n_max, cfg.n_min));

subplot(2,1,2); hold on; grid on
for a = 1:nL
    plot(t, rad2deg(RR{a}.d_cmd(3,:)), 'LineWidth', lw(a), 'Color', cl(a,:));
end
am = rad2deg(cfg.alpha_max(1));
yline( am, 'k--', 'LineWidth', 1.2);
yline(-am, 'k--', 'LineWidth', 1.2);
ylabel('\delta_3  [deg]');  xlabel('t  [s]');
legend(cellfun(@(R) R.method, RR, 'UniformOutput', false), ...
       'Location','eastoutside','FontSize',8);
title(sprintf('Servo angle demanded of unit 3 — the limit is %.0f deg', am));

W12_save_fig(fig, fullfile(outdir, 'img', 'W12_chain_sat.png'));
end
