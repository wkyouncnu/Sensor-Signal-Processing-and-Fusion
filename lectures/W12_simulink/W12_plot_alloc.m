function W12_plot_alloc(cfg, H, tau_d, outdir)
%W12_PLOT_ALLOC  §12-8 의 그림 — 평면도 위의 네 추력 화살표와 요구한 힘.
%  절 스크립트(`W12_G_allocation`)를 얇게 두기 위해 그림만 여기로 뺐다
%  (`vault_check.sh` §18, 실행 줄 45 이하). 그리는 규칙은 §12-8 과 같다 —
%  추력은 빨강이고 축척이 하나, 요구한 힘은 파랑이고 **단위가 다르므로**
%  축척이 따로다. 둘을 한 축척으로 그리면 N 과 N·m 이 섞인다.

x = cfg.pos(1,:);  y = cfg.pos(2,:);  s = cfg.mount;
fig = figure('Color','w','Position',[80 80 520 640]);
hold on; axis equal; grid on

% 선체 외곽 — 두 폰툰. 가로축이 y_b 이므로 폭이 0.32, 길이가 3.35 다
for sy = [-1 1]
    rectangle('Position',[sy*0.395-0.16, -1.45, 0.32, 3.35], ...
              'Curvature',0.35,'EdgeColor',[.65 .65 .65],'FaceColor',[.95 .95 .95]);
end

sc  = 0.70/max(abs(H.T));                 % 추력 화살표 축척 [m/N]
sct = 0.70/norm(tau_d(1:2));              % tau 화살표는 따로 — 단위가 다르다
for i = 1:4
    % 추력 벡터를 선체축으로: s_i*[T cos d ; T sin d]
    vx = s(i)*H.T(i)*cos(H.delta(i));  vy = s(i)*H.T(i)*sin(H.delta(i));
    plot(y(i), x(i), 'ko','MarkerFaceColor','k','MarkerSize',6);
    quiver(y(i), x(i), sc*vy, sc*vx, 0, 'LineWidth',2,'Color',[.85 .2 .2], ...
           'MaxHeadSize',0.9);
    text(y(i)+0.10, x(i)-0.17, sprintf('%d:  %.0f N,  %.0f%c', ...
         i, H.T(i), rad2deg(H.delta(i)), char(176)), 'FontSize',9);
end

quiver(0, 0, sct*tau_d(2), sct*tau_d(1), 0, 'LineWidth',2.5, ...
       'Color',[.1 .3 .8], 'MaxHeadSize',0.9);
text(-0.62, 0.62, sprintf('\\tau_d = [%.0f N, %.0f N, %.0f Nm]', tau_d), ...
     'FontSize',10,'Color',[.1 .3 .8],'HorizontalAlignment','right');
text(-1.50, -1.80, {'red   thrust of each unit, to scale', ...
                    'blue  demanded X and Y, own scale'}, 'FontSize',9);
xlabel('y_b  (starboard) [m]');  ylabel('x_b  (bow) [m]');
title('Minimum-norm allocation');
xlim([-1.60 1.60]);  ylim([-2.1 2.5]);

W12_save_fig(fig, fullfile(outdir, 'img', 'W12_alloc_pinv.png'));
end
