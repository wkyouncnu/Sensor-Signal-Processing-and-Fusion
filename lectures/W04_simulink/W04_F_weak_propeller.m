%% W04 · 실험 4-3c — 좌현 프로펠러가 약할 때 / Experiment 4-3c — a weak port propeller
%
%  이 절이 묻는 것 / the question
%      선수각은 스스로 적분기인데, 그래도 I 가 필요한 경우가 있는가?
%      The heading already integrates. Is there still a case that needs I?
%
%  이 스크립트가 하는 일 / what this script does
%      1) PD 만 (Ki = 0) 으로, 좌현 프로펠러 효율 port_eff = 1, 0.7, 0.5 를 돌린다.
%         최종 선수각, 남은 오차, 그때의 요 모멘트를 찍는다.
%      2) 효율 0.7 에서 Ki = 0, 20, 50, 100 을 돌린다. 최종 선수각, 오버슛,
%         정착시간, 40 s 의 적분항을 찍고 그림으로 저장한다.
%      1) With PD only (Ki = 0), runs the port propeller at efficiency 1, 0.7
%         and 0.5; prints the final heading, the error left and the moment.
%      2) At efficiency 0.7, runs Ki = 0, 20, 50, 100; prints the final heading,
%         overshoot, settling time and the integral at 40 s, and plots them.
%
%  출력에서 볼 것 / what to look for in the output
%      - 약한 프로펠러는 좌우 추력을 어긋나게 해 배를 계속 돌리려 한다. 이를 막으려면
%        일정한 모멘트(4.19 N m)가 필요한데 PD 는 오차가 있어야만 그것을 낸다 -> 0.80 도가 남는다.
%      - Ki > 0 이면 적분항이 그 모멘트(4.15 ~ 4.20 N m)를 스스로 찾아 오차가 사라진다.
%      - Ki 가 크면 (50, 100) 오버슛이 생긴다. Ki = 20 이 가장 빠르다 (1.98 s).
%      - A weak propeller unbalances the thrust and keeps turning the vessel.
%        Holding the heading takes a steady moment (4.19 N m), which PD produces
%        only from error: 0.80 deg is left.
%      - With Ki > 0 the integral finds that moment itself (4.15 to 4.20 N m)
%        and the error goes.
%      - Too much Ki (50, 100) overshoots; Ki = 20 is the fastest (1.98 s).
%
%  만드는 것 / produces: img/W04_result_I.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) PD 만, 프로펠러 효율을 바꾼다 / PD only, propeller efficiency varied
fprintf('\n  W04 Experiment 4-3c  1) PD only (Kp = 300, Kd = 100), port propeller at reduced efficiency\n');
fprintf('    port_eff   final psi [deg]   error left [deg]   steady N [N m]\n');
for eff = [1 0.7 0.5]
    R = W04_read('W04_F_PID', 'Ki', 0, 'port_eff', eff);
    %  마지막 값 = 정상상태 / the last sample = the steady state
    fprintf('    %-8g   %15.3f   %16.3f   %14.2f\n', eff, R.psi(end), 10 - R.psi(end), R.N(end));
end

%% 2) 효율 0.7, 적분 게인을 바꾼다 / efficiency 0.7, integral gain varied
fprintf('\n  2) add the integral, port_eff = 0.7\n');
fprintf('    Ki     final psi [deg]   overshoot %%   settle [s]   I at 40 s [N m]\n');
f = lab_fig('W04 Exp 4-3c  integral', 1000, 620);
for Ki = [0 20 50 100]
    R = W04_read('W04_F_PID', 'Ki', Ki, 'port_eff', 0.7);
    [Mp, ts] = step_metrics(R.t, R.psi, 10, 5);
    if abs(R.psi(end) - 10) > 0.2, ts = Inf; end            % 10 도에 닿지 않음 / never reaches 10 deg
    fprintf('    %-5g  %15.3f   %11.2f   %10.2f   %15.2f\n', Ki, R.psi(end), max(Mp,0), ts, R.I(end));

    %  위: 선수각, 아래: 적분항 / top: heading, bottom: the integral term
    subplot(2,1,1); hold on; plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('K_i = %g', Ki));
    subplot(2,1,2); hold on; plot(R.t, R.I, 'LineWidth', 1.6, 'DisplayName', sprintf('K_i = %g', Ki));
end

%% 3) 그림을 다듬어 저장한다 / label the figure and save it
subplot(2,1,1); plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command'); grid on;
ylabel('\psi [deg]'); legend('Location','southeast'); title('a weak port propeller: PD stops short, the integral finishes the turn');
subplot(2,1,2); grid on; ylabel('I [N m]'); xlabel('time [s]');
title('every integral ends at the same moment: what the weak propeller fails to give');
exportgraphics(f, fullfile(here, 'img', 'W04_result_I.png'), 'Resolution', 150);
