%% W07 · 실험 7-7 — 필터의 튜닝 순서 / Experiment 7-7 — the tuning order for the filter
%
%  이 절이 묻는 것 / the question
%      노치의 두 수를 무엇을 보고 고르는가?
%      What decides the two numbers of the notch?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 너비 zeta_d 를 다섯 값으로 바꿔 가며, 같은 바다에서 한 번(수고)과
%         바다를 끈 채 계단 한 번(값)을 돌린다.
%      ② 두 수치를 한 표에 놓는다 — 이것이 고르는 근거다.
%      ③ 수고 대 값의 맞바꿈 곡선을 그린다.
%      ① For five values of the width zeta_d, runs once in the sea (the effort)
%         and once with the sea off (the cost, as a step).
%      ② Puts the two numbers in one table: that is what the choice rests on.
%      ③ Plots the trade curve.
%
%  출력에서 볼 것 / what to look for in the output
%      - 넓을수록 파랑은 잘 지워지고 (모멘트 14.78 -> 7.61 N m) 계단은 나빠진다
%        (오버슈트 4.09 -> 42.32 %). 가운데가 답이다.
%      - 이 배의 답은 zeta_d = 0.3 이다: 모멘트를 18.85 에서 13.41 N m 로 줄이면서
%        오버슈트는 9 % 에 머문다.
%      - A wider notch removes more of the sea and hurts the step more.
%      - For this vessel the answer is zeta_d = 0.3: the moment falls from 18.85
%        to 13.41 N m while the overshoot stays at 9 %.
%
%  만드는 것 / produces: img/W07_result_tuning.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 너비를 다섯 값으로 / five widths
ZD = [0.2 0.3 0.5 0.7 1.0];  E = zeros(numel(ZD), 4);
fprintf('\n  W07 Experiment 7-7  choosing the notch  (zeta_n = 0.05 throughout)\n');
fprintf('    zeta_d   |H(j w0)|   moment std   heading std   overshoot   settle [s]\n');
for i = 1:numel(ZD)
    R = W07_read('W07_H_tuning', 'zeta_d', ZD(i));                       % 바다 속 / in the sea
    S = W07_read('W07_H_tuning', 'zeta_d', ZD(i), 'wave_on', 0, 'T_final', 40);   % 계단 / the step
    j = R.t > 20;
    [Mp, ts, ~] = step_metrics(S.t, S.psi, S.V.psi_step, S.V.t_step);
    E(i,:) = [std(R.N(j)) std(R.psi(j)) Mp ts];
    fprintf('    %5.2f  %10.3f %11.2f Nm %10.3f deg %9.2f %% %9.2f\n', ...
            ZD(i), R.V.zeta_n/ZD(i), E(i,1), E(i,2), Mp, ts);
end

%% 2) 맞바꿈 곡선 / the trade curve
fg = lab_fig('W07 Exp 7-7  the trade', 1000, 460);
yyaxis left;  plot(ZD, E(:,1), 'o-', 'LineWidth', 2); ylabel('moment std in the sea [N m]');
yyaxis right; plot(ZD, E(:,3), 's-', 'LineWidth', 2); ylabel('overshoot of a 10 deg step [%]');
grid on; xlabel('notch width \zeta_d');
title('wider removes more of the sea and costs more on a manoeuvre; 0.3 is this vessel''s answer');
exportgraphics(fg, fullfile(here, 'img', 'W07_result_tuning.png'), 'Resolution', 150);
