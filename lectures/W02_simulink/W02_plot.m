function W02_plot(R)
%W02_PLOT  W02_read 가 돌려준 실행 하나를 그린다: 위치와 목표, 힘과 두 항.
%          Draw one run returned by W02_read: position and setpoint, force and two terms.
%
%   W02_plot(W02_read('W02_E_PID', 'Kp', 20))
%
%   모델을 Run 하면 캔버스의 Scope 가 같은 것을 보인다. 이 함수는 그것을 그림 파일로 남길 때 쓴다.
%   The model's own Scope shows the same when Run is pressed; this is for a saved figure.

lab_fig('W02  one run', 900, 560);
subplot(2,1,1); hold on;
plot(R.t, R.y_d, 'k--', 'LineWidth', 1.2);  plot(R.t, R.y, 'LineWidth', 2);
ylabel('position [m]'); legend({'y_d','y'}, 'Location','southeast'); grid on;
subplot(2,1,2); hold on;
plot(R.t, R.tau, 'LineWidth', 2);  plot(R.t, R.I, 'LineWidth', 1.4);  plot(R.t, R.D, 'LineWidth', 1.2);
ylabel('force [N]'); xlabel('time [s]'); legend({'\tau','I','D'}); grid on;
end
