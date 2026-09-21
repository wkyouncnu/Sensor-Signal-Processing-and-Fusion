function W02_plot(R)
%W02_PLOT  한 번의 실행을 그린다: 위치와 목표, 그리고 힘과 세 항.
%          Draw one run: position against setpoint, and the force with its
%          three terms.
%
%   W02_plot            모델의 StopFcn 이 부른다. Run 이 끝나면 저절로 뜬다
%                       called by the model's StopFcn when Run finishes
%   W02_plot(R)         W02_read 가 돌려준 실행 하나를 그린다
%                       draws one run returned by W02_read
%
%   그림 읽는 법 / how to read it
%       위 칸: 목표 y_d (검은 점선) 와 위치 y. 둘 사이의 간격이 오차 e 이다.
%       아래 칸: 제어기가 낸 힘 tau 와, 그것을 이루는 세 항 가운데 적분항 I 와
%       미분항 D. 비례항은 tau - I - D 이므로 따로 그리지 않는다.
%       Top: the setpoint y_d (black dashed) and the position y; the gap
%       between them is the error e. Bottom: the force tau and two of the three
%       terms it is made of, the integral I and the derivative D. The
%       proportional term is tau - I - D and is not drawn separately.

if nargin < 1
    %  run_sim 으로 돌린 실행은 로그를 작업공간이 아니라 결과 객체에 담는다.
    %  그때는 그릴 것이 없으므로 조용히 돌아간다 — 절 스크립트가 따로 그린다.
    %  A run made through run_sim keeps its log in the result object, not in
    %  the workspace; there is nothing to draw then, and the section script
    %  draws its own figure.
    if ~evalin('base', 'exist(''W02log'', ''var'')'), return; end
    o = evalin('base', 'W02log');
    y = squeeze(o.signals.values);
    if size(y,1) < size(y,2), y = y.'; end
    R = W02_read(struct('t', o.time, 'y', y));
end

f = lab_fig('W02  one run', 900, 560); %#ok<NASGU>
subplot(2,1,1); hold on;
plot(R.t, R.y_d, 'k--', 'LineWidth', 1.2);
plot(R.t, R.y, 'Color',[0 0.45 0.74], 'LineWidth', 2);
ylabel('position [m]');
legend({'y_d  setpoint','y  position'}, 'Location','southeast');
title('what the controller achieved');
grid on;

subplot(2,1,2); hold on;
plot(R.t, R.tau, 'Color',[0.85 0.33 0.10], 'LineWidth', 2);
plot(R.t, R.I, 'Color',[0.47 0.67 0.19], 'LineWidth', 1.4);
plot(R.t, R.D, 'Color',[0.49 0.18 0.56], 'LineWidth', 1.2);
ylabel('force [N]');  xlabel('time [s]');
legend({'\tau  total','I  integral term','D  derivative term'}, 'Location','northeast');
title('what it took');
grid on;
end
