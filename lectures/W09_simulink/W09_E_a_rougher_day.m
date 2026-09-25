%% W09 · 실험 9-4 — 더 거친 날 / Experiment 9-4 — a rougher day
%
%  이 절이 묻는 것 / the question
%      기준 조건에서 맞춘 배를 **다른 날**에 내보내면 무엇이 먼저 나빠지는가?
%      그리고 7주차의 필터는 날이 거칠어질수록 더 버는가, 덜 버는가?
%      Send the same vessel out on a different day: what degrades first, and does
%      the filter of Week 7 earn more or less as the day gets worse?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 다섯 날 — 파랑이 만드는 선수각 표준편차 3~15 deg, 조류 0.3~1.1 m/s —
%         을 노치를 넣고 한 번, 빼고 한 번, 모두 열 번 돌린다.
%      ② 같은 지표로 재어 한 표에 쌓는다. 게인은 하나도 바꾸지 않는다.
%      ③ 날에 따른 네 지표의 변화를, 노치 유무를 함께, 그린다.
%      ① Five days, each run twice — with the notch and without — ten runs.
%      ② The same metrics, in one table. Not one gain is retuned.
%      ③ Plots four metrics against the day, filtered and unfiltered.
%
%  출력에서 볼 것 / what to look for in the output
%      - 먼저 나빠지는 것은 **움직임**이다: 요 각속도 3.96 -> 7.77 deg/s.
%      - 유지 오차 0.75 -> 1.39 m 는 조류가 만든 것이지 파랑이 만든 것이 아니다.
%      - 임무 시간은 오히려 **짧아진다** (278 -> 259 s): 조류가 둘째 다리를 밀어 준다.
%      - 노치는 어느 날에나 1.2~2.0 deg/s 를 덜어 낸다. 비율은 비슷하고 **양은 커진다**.
%      - What degrades first is motion, not accuracy; the current, not the sea,
%        is what moves the hold error; and the filter earns more in absolute terms
%        every day, while earning about the same fraction.
%
%  만드는 것 / produces: img/W09_result_weather.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 다섯 날, 두 번씩 / five days, twice each
clear M                  % 앞 절이 남긴 누적 변수를 비운다 / clear what an earlier section left
SIG = [3 6 9 12 15];   VC = [0.3 0.5 0.7 0.9 1.1];
fprintf('\n  W09 Experiment 9-4  the same vessel, five days  (no gain is changed)\n');
fprintf('    day  sigma  V_c  |      the notch in           |     the notch out\n');
fprintf('         [deg] [m/s] |   T[s]  y_e    r    dN  hold |   T[s]  y_e    r    dN  hold\n');
for i = 1:5
    s = sprintf('     %d  %5.0f %5.1f |', i, SIG(i), VC(i));
    for c = 1:2
        R = W09_read('W09_E_weather', 'sigma_psi',SIG(i), 'V_c',VC(i), ...
                     'use_notch', 2-c, 'T_final', 400);
        M(i,c) = W09_metrics(R);                                          %#ok<SAGROW>
        s = [s sprintf(' %6.1f %5.2f %5.2f %5.1f %5.2f |', M(i,c).T, M(i,c).ye, ...
                       M(i,c).r, M(i,c).Nhf, M(i,c).hold)];               %#ok<AGROW>
    end
    fprintf('%s\n', s);
end

%% 2) 날에 따른 네 지표 / the four metrics against the day
f = lab_fig('W09 Exp 9-4  a rougher day', 1000, 560);
P = {'ye', 'cross-track at the end of a leg [m]'; 'r', 'yaw rate, RMS [deg/s]'; ...
     'Nhf', 'fast part of the moment in a hold [N m]'; 'hold', 'hold error [m]'};
for k = 1:4
    subplot(2,2,k); hold on; grid on;
    plot(1:5, [M(:,1).(P{k,1})], 'o-', 'LineWidth', 1.8);
    plot(1:5, [M(:,2).(P{k,1})], 's--', 'LineWidth', 1.4);
    xlabel(sprintf('day   (\\sigma_\\psi = %s deg,  V_c = %s m/s)', ...
                   mat2str(SIG), mat2str(VC)));
    ylabel(P{k,2});  xticks(1:5);  xlim([0.8 5.2]);
    if k == 1, legend({'notch in', 'notch out'}, 'Location', 'northwest'); end
end
exportgraphics(f, fullfile(here, 'img', 'W09_result_weather.png'), 'Resolution', 150);
