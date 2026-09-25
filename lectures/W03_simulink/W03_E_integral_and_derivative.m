%% W03 · 실험 3-3b — I 를 더하고, D 를 시험한다 / Experiment 3-3b — add I, then try D
%
%  이 절이 묻는 것 / the question
%      P 가 남긴 속도 오차를 I 가 없앨 수 있는가? 그리고 2주차에서 감쇠기였던 D 는
%      속도 루프에서도 도움이 되는가?
%      Can I remove the speed error P leaves? And does D, a damper in Week 2,
%      help on a speed loop too?
%
%  이 스크립트가 하는 일 / what this script does
%      1) Kp = 200, Kd = 0 으로 두고 Ki = 0, 50, 100, 200, 400 을 돌린다.
%         40 s 의 속도, 오버슛, 정착시간, 40 s 의 적분항을 표로 찍는다.
%      2) Kp = Ki = 200 으로 두고 Kd = 0, 20, 50, 100 을 돌린다.
%         오버슛, 상승시간, 정착시간을 표로 찍는다.
%      1) With Kp = 200 and Kd = 0, runs Ki = 0, 50, 100, 200, 400 and prints
%         the speed and the integral at 40 s, the overshoot and the settling time.
%      2) With Kp = Ki = 200, runs Kd = 0, 20, 50, 100 and prints the
%         overshoot, the rise time and the settling time.
%
%  출력에서 볼 것 / what to look for in the output
%      - Ki > 0 이면 속도가 정확히 1.5 에 닿고, 적분항은 모두 116.3 N 에서 멈춘다.
%        이것이 1.5 m/s 에서의 항력이다 (절 C: 1.5 / 0.0129 = 116 N).
%      - Ki 가 너무 크면 (400) 오버슛이 생긴다.
%      - Kd 를 올릴수록 오버슛이 커지고 느려진다: 속도 루프에서 D 는 가속도에
%        반응해 배를 무겁게 만든 것처럼 작용한다.
%      - With Ki > 0 the speed reaches exactly 1.5, and every integral stops at
%        116.3 N: the drag at 1.5 m/s (section C: 1.5 / 0.0129 = 116 N).
%      - Too much Ki (400) overshoots.
%      - Raising Kd increases the overshoot and slows the loop: on a speed loop D
%        reacts to acceleration and acts as if the vessel were heavier.
%
%  만드는 것 / produces: img/W03_result_I.png, img/W03_result_D.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 적분 게인을 바꾼다 / vary the integral gain
fprintf('\n  W03 Experiment 3-3b  1) the integral  (Kp = 200, Kd = 0)\n');
fprintf('    Ki    u at 40 s   overshoot %%   settle [s]   I at 40 s [N]\n');
f = lab_fig('W03 Exp 3-3b  integral', 1000, 620);
for Ki = [0 50 100 200 400]
    %  Ki 만 바꿔 돌린다 (Kp = 200, Kd = 0 은 기본값)
    %  Run with only Ki changed (Kp = 200 and Kd = 0 are the defaults)
    R = W03_read('W03_E_PID', 'Ki', Ki);

    %  이번에는 목표 1.5 를 기준으로 잰다 — I 가 있으면 1.5 에 닿기 때문이다.
    %  This time measured against the command 1.5, which I reaches.
    [Mp, ts] = step_metrics(R.t, R.u, 1.5, 5);
    if Ki == 0, ts = Inf; end                       % 1.5 에 닿지 않는다 / never reaches 1.5
    fprintf('    %-4g  %9.4f   %11.1f   %10.2f   %13.1f\n', Ki, R.u(end), max(Mp,0), ts, R.I(end));

    %  위: 속도, 아래: 적분항 / top: speed, bottom: the integral term
    subplot(2,1,1); hold on; plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_i = %g', Ki));
end
subplot(2,1,1); plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); xlim([0 25]); grid on;
ylabel('u [m/s]'); legend('Location','southeast'); title('the integral removes the error; too much of it overshoots');
subplot(2,1,2); xlim([0 25]); grid on; ylabel('I [N]'); xlabel('time [s]');
title('every integral stops at the same force: the drag at 1.5 m/s');
exportgraphics(f, fullfile(here, 'img', 'W03_result_I.png'), 'Resolution', 150);

%% 2) 미분 게인을 바꾼다 / vary the derivative gain
fprintf('\n  2) the derivative  (Kp = 200, Ki = 200)\n');
fprintf('    Kd    overshoot %%   rise [s]   settle [s]\n');
f = lab_fig('W03 Exp 3-3b  derivative', 1000, 420);  hold on; grid on;
for Kd = [0 20 50 100]
    %  Kd 만 바꿔 돌린다 (Kp = Ki = 200 은 기본값)
    %  Run with only Kd changed (Kp = Ki = 200 are the defaults)
    R = W03_read('W03_E_PID', 'Kd', Kd);
    [Mp, ts, tr] = step_metrics(R.t, R.u, 1.5, 5);
    fprintf('    %-4g  %11.2f   %8.2f   %10.2f\n', Kd, max(Mp,0), tr, ts);
    plot(R.t, R.u, 'LineWidth', 2, 'DisplayName', sprintf('K_d = %g', Kd));
end
plot(R.t, R.u_d, 'k--', 'DisplayName', 'command'); xlim([3 15]);
ylabel('u [m/s]'); xlabel('time [s]'); legend('Location','southeast');
title('on a speed loop D makes it worse: more overshoot and slower');
exportgraphics(f, fullfile(here, 'img', 'W03_result_D.png'), 'Resolution', 150);
