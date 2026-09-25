%% W09 · 실험 9-6 — 설계였나, 그날이었나 / Experiment 9-6 — the design, or the day?
%
%  이 절이 묻는 것 / the question
%      §9-2 부터 §9-5 까지의 수는 전부 **하나의 파랑 실현**에서 나왔다. 같은 스펙트럼의
%      다른 실현에서도 같은 결론이 나오는가? 아니면 그날 운이 좋았던 것인가?
%      Every number so far came from one realisation of the sea. Does the same
%      spectrum, realised differently, give the same conclusions — or was it luck?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 위상을 통째로 옮겨 같은 스펙트럼의 다섯 실현을 만든다 (phase_shift).
%         진폭도 주파수도 그대로다 — 바뀌는 것은 성분들이 만나는 방식뿐이다.
%      ② 각 실현에서 기준 임무와 use_vane 을 끈 임무를 돌린다.
%      ③ 다섯 항적을 겹치고, 두 경우의 유지 오차를 실현마다 찍는다.
%      ① Five realisations of one spectrum, made by shifting every phase by one
%         number: the same amplitudes at the same frequencies, met differently.
%      ② Each realisation is flown twice, with the weathervane and without.
%      ③ Overlays the five tracks and plots the hold error of both, per realisation.
%
%  출력에서 볼 것 / what to look for in the output
%      - 임무 시간 275.2~278.6 s, 유지 오차 0.732~0.757 m — 폭이 3.4 % 다.
%      - 뱃머리를 묶으면 어느 실현에서나 유지 오차가 다섯 배가 된다. §9-3 의 결론은
%        그날의 것이 아니라 설계의 것이다.
%      - 다섯 항적은 눈으로 구별되지 않는다. 파랑은 **움직임**을 만들지 경로를 만들지 않는다.
%      - The spread across realisations is 3.4 %, the ablation conclusion holds
%        in every one of them, and the five tracks are not distinguishable by eye.
%
%  만드는 것 / produces: img/W09_result_repeat.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 같은 스펙트럼, 다섯 실현 / one spectrum, five realisations
clear MA MB TRK          % 앞 절이 남긴 누적 변수를 비운다 / clear what an earlier section left
PH = [0 1.2 2.4 3.6 4.8];
fprintf('\n  W09 Experiment 9-6  the same spectrum, five realisations\n');
fprintf('    phase shift [rad]   T [s]   y_e [m]   r [deg/s]   hold [m]   hold, bow tied [m]\n');
for i = 1:numel(PH)
    A = W09_read('W09_C_full', 'phase_shift', PH(i));
    B = W09_read('W09_C_full', 'phase_shift', PH(i), 'use_vane', 0);
    MA(i) = W09_metrics(A);   MB(i) = W09_metrics(B);   TRK{i} = A;    %#ok<SAGROW>
    fprintf('           %4.1f         %5.1f     %5.2f       %5.2f      %6.3f          %6.3f\n', ...
            PH(i), MA(i).T, MA(i).ye, MA(i).r, MA(i).hold, MB(i).hold);
end
fprintf('    spread of the mission time  %.1f s;  of the hold error  %.3f m (%.1f %%)\n', ...
        max([MA.T]) - min([MA.T]), max([MA.hold]) - min([MA.hold]), ...
        100*(max([MA.hold]) - min([MA.hold]))/mean([MA.hold]));

%% 2) 겹친 항적과 실현별 유지 오차 / the tracks overlaid, and the hold error per realisation
f = lab_fig('W09 Exp 9-6  the design, or the day', 1000, 460);
V = TRK{1}.V;
subplot(1,2,1); hold on; grid on; axis equal;
plot([0; V.WP_E], [0; V.WP_N], 'k--');
plot(V.WP_E, V.WP_N, 'kp', 'MarkerSize', 11, 'MarkerFaceColor', 'k');
for i = 1:numel(PH), plot(TRK{i}.E, TRK{i}.N, 'LineWidth', 1.0); end
xlabel('east [m]');  ylabel('north [m]');
title('five seas of the same spectrum, five tracks');
subplot(1,2,2); hold on; grid on;
plot(PH, [MA.hold], 'o-', 'LineWidth', 1.8);
plot(PH, [MB.hold], 's--', 'LineWidth', 1.4);
xlabel('phase shift [rad]');  ylabel('hold error [m]');  ylim([0 4.5]);
title('the conclusion of §9-3, five times over');
legend({'the vessel of §9-2', 'the bow tied (use\_vane = 0)'}, 'Location', 'east');
exportgraphics(f, fullfile(here, 'img', 'W09_result_repeat.png'), 'Resolution', 150);
