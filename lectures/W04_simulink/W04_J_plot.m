function W04_J_plot(saveTo)
%W04_J_PLOT  4-8 절의 그림 — 명령과 응답을 두 루프에 대해 나란히.
%            The figure of section 4-8: command against response, for both loops.
%
%   W04_J_plot            그림만 / draw only
%   W04_J_plot(folder)    그리고 folder/W04_result_both.png 로 저장 / and save
%
%   모델의 StopFcn 이 인자 없이 부른다. **Run 만 눌러도 그림이 뜬다** — 절 스크립트를
%   돌릴 필요가 없다. 로그는 기본 작업공간의 W04Jlog 다.
%   The model's StopFcn calls it with no argument, so pressing Run is enough; the
%   log is W04Jlog in the base workspace.
%
%   칸 / the panels
%     1  psi_d 와 psi [deg]   바깥에서 올 명령을 선수각 루프가 따라가는가
%     2  u_d 와 u [m/s]       같은 질문을 속도 루프에 대해
%     3  N 과 X               그 둘을 만들려고 두 제어기가 요구한 힘과 모멘트,
%                             그리고 각자의 한계. 한계에 닿는 순간이 어디인지 보인다

L = evalin('base', 'W04Jlog');
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = L.time;
R = struct('psi_d', y(:,1), 'psi', y(:,2), 'u_d', y(:,3), 'u', y(:,4), ...
           'N', y(:,5), 'X', y(:,6));
V = @(nm) evalin('base', nm);

f = lab_fig('W04 J  both inner loops at once', 980, 720);

subplot(3,1,1); hold on; grid on;
plot(t, R.psi_d, '--', 'Color',[0.85 0.33 0.10], 'LineWidth',1.5, 'DisplayName','\psi_d  commanded');
plot(t, R.psi,         'Color',[0    0.45 0.74], 'LineWidth',1.5, 'DisplayName','\psi  achieved');
ylabel('\psi  [deg]');  legend('Location','southeast');
title('the heading loop follows its command');

subplot(3,1,2); hold on; grid on;
plot(t, R.u_d, '--', 'Color',[0.85 0.33 0.10], 'LineWidth',1.5, 'DisplayName','u_d  commanded');
plot(t, R.u,         'Color',[0    0.45 0.74], 'LineWidth',1.5, 'DisplayName','u  achieved');
ylabel('u  [m/s]');  legend('Location','southeast');
title('the speed loop follows its own command, at the same time');

subplot(3,1,3); hold on; grid on;
plot(t, R.N, 'Color',[0.47 0.25 0.80], 'LineWidth',1.2, 'DisplayName','N  [N m]');
plot(t, R.X, 'Color',[0.47 0.67 0.19], 'LineWidth',1.2, 'DisplayName','X  [N]');
yline( V('N_speed'), ':', 'Color',[0.47 0.25 0.80], 'DisplayName','\pm N_{speed}');
yline(-V('N_speed'), ':', 'Color',[0.47 0.25 0.80], 'HandleVisibility','off');
yline( V('X_max'),   ':', 'Color',[0.47 0.67 0.19], 'DisplayName','X_{max}');
xlabel('time [s]');  ylabel('N , X');  legend('Location','southeast');
title('what the two controllers ask the same two propellers for');

if nargin > 0 && ~isempty(saveTo)
    exportgraphics(f, fullfile(saveTo, 'img', 'W04_result_both.png'), 'Resolution', 150);
end
end
