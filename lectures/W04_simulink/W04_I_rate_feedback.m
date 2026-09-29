%% W04 · 실험 4-3e — D 항을 어디서 얻는가 / Experiment 4-3e — where the D term comes from
%
%  이 절이 묻는 것 / the question
%      제동 항을 **자이로가 주는 회두율**에서 얻을 것인가, **오차를 미분해서**
%      얻을 것인가. 그리고 그 항의 부호는 왜 음이어야 하는가.
%      Take the braking term from the yaw rate a gyro already reports, or from
%      the derivative of the error? And why must its sign be negative?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 모델 W04_I_rate 를 d_form = 1, 2, 3 으로 세 번 돌린다. 바뀌는 것은
%         D 항의 출처 하나뿐이고, 배·게인·명령·해석기는 모두 같다.
%      ② 오버슛·상승·정착과 **요구한 D 항의 최대**를 한 표로 찍는다.
%      ③ 선수각 셋, |D| 셋(로그축), 그리고 부호를 뒤집었을 때의 회두율을 그린다.
%      ① Runs one model three times, changing only where the D term comes from.
%      ② Prints the step metrics and the largest D term each one demands.
%      ③ Plots the three headings, the three demands, and the yaw rate the
%         wrong sign settles into.
%
%  출력에서 볼 것 / what to look for in the output
%      - 1번과 2번은 **거의 같게 따라간다** (0.90 대 0.39 %, 1.74 대 1.72 s).
%        명령이 멈춰 있는 동안 두 항은 같은 것이기 때문이다.
%      - 그런데 요구한 크기는 17.03 N m 대 325.79 N m — **19 배**다. 90 도 계단에서는
%        33.27 대 2932.15 로 88 배가 된다. 한계는 70.85 N m 다.
%      - 3번(부호를 뒤집은 것)은 오버슛 38.59 % 이고 끝까지 정착하지 않는다.
%        발산하지도 않는다 — 7.23 deg/s 의 **한계 순환**에 들어간다. 예측은 7.70 deg/s.
%      - Forms 1 and 2 track almost identically and differ by a factor of 19 in
%        what they ask the propellers for; form 3 is a brake wired backwards.
%
%  만드는 것 / produces: img/W04_result_rate.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 같은 모델, 세 가지 D 항 / one model, three D terms
NAME = {'-Kd r   (rate, the gyro)', '+Kd Nf s/(s+Nf) e   (error)', '+Kd r   (sign flipped)'};
R = cell(1,3);
for d = 1:3, R{d} = W04_read('W04_I_rate', 'd_form', d); end
%  머리말의 게인은 **실제로 쓴 값**에서 읽는다. 작업공간에서 읽으면 앞 절 스크립트가
%  스윕하며 남긴 값이 찍힌다 / read the gains from the run itself: the workspace
%  still holds whatever the previous section script last swept to.
V = R{1}.V;
fprintf('\n  W04 Experiment 4-3e  where the D term comes from  (Kp = %g, Kd = %g, psi_d = %g deg)\n', ...
        V.Kp, V.Kd, V.psi_step);
fprintf('    d_form   D term                          overshoot   rise [s]   settle [s]   max |D| [N m]\n');
for d = 1:3
    [Mp, ts, tr] = step_metrics(R{d}.t, R{d}.psi, R{d}.V.psi_step, R{d}.V.t_step);
    if ts >= R{d}.V.T_final - R{d}.V.t_step - 1e-9, s = '  never'; else, s = sprintf('%7.2f', ts); end
    fprintf('      %d      %-30s %8.2f %% %9.2f %s %14.2f\n', d, NAME{d}, Mp, tr, s, max(abs(R{d}.D)));
end
r_c = (V.Kd/42.65 - 1)/10 * 180/pi;      % 뒤집힌 감쇠가 0 이 되는 회두율 / where flipped damping vanishes
r3  = gradient(R{3}.psi, R{3}.t);
fprintf('    the wrong sign settles into a limit cycle of %.2f deg/s;  |N_r|(1+10|r|) = Kd predicts %.2f\n', ...
        max(abs(r3(R{3}.t > 20))), r_c);

%% 2) 선수각, 요구한 D 항, 그리고 뒤집힌 부호가 만드는 순환
f = lab_fig('W04 Exp 4-3e  where the D term comes from', 1050, 560);
subplot(2,2,[1 3]); hold on; grid on;
for d = 1:3, plot(R{d}.t, R{d}.psi, 'LineWidth', 1.8); end
yline(V.psi_step, 'k--', 'HandleVisibility','off');
xlabel('time [s]');  ylabel('\psi [deg]');  legend(NAME, 'Location','southeast');
title('forms 1 and 2 lie on one another; form 3 is a brake wired backwards');
subplot(2,2,2); hold on; grid on;
for d = 1:3, semilogy(R{d}.t, abs(R{d}.D) + 1e-3, 'LineWidth', 1.4); end
set(gca,'YScale','log');  yline(V.N_max, 'r--', 'N_{max}');  ylim([1e-2 1e3]);
xlim([V.t_step-1 V.t_step+5]);  ylabel('|D| [N m]');  title('what each one asks the propellers for');
subplot(2,2,4); hold on; grid on;
plot(R{3}.t, r3, 'Color', [0.93 0.69 0.13], 'LineWidth', 1.4);
yline([-1 1]*r_c, 'k--');
xlabel('time [s]');  ylabel('r [deg/s]');
title(sprintf('form 3: a limit cycle at the rate where |N_r|(1+10|r|) = K_d  (%.1f deg/s)', r_c));
exportgraphics(f, fullfile(here, 'img', 'W04_result_rate.png'), 'Resolution', 150);
