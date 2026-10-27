%% W06 · 7 단 — 같은 부두에, 뱃머리를 대고 / Rung 7 — the same berth, bow on
%
%  >> W06_7_front_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_7_front.slx` 를 **그대로** 돌린다. 5 단과 블록이 하나도 다르지
%         않고, 캔버스의 숫자 **하나**만 다르다 — psi_berth = -pi/2.
%      ② 단계마다 걸린 시간을 재서, 그 한 숫자가 어느 구간을 늘리고 어느
%         구간을 줄였는지 본다.
%      ① Runs W06_7_front.slx as it stands: one canvas number differs from
%         rung 5, psi_berth = -pi/2.
%      ② Times the legs, to see which leg that one number lengthens.
%
%  출력에서 볼 것 / what to look for
%      - 접안 구간을 건너는 축이 바뀐다. 마지막 몇 미터를 횡이 아니라 전진으로
%        건너고, 전진의 한계는 횡의 한계보다 3.4 배 크다 (6-2 절).
%      - 대신 정렬 구간에서 배가 90 도를 돌아야 한다. 값은 공짜가 아니라
%        자리를 옮긴다 — 어느 쪽으로 옮겼는지는 아래 표가 말한다.

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>

%% 1) 돌린다 / run it
mdl = 'W06_7_front';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

%% 2) 로그를 읽는다 / read the log
V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = W06.time;
ph = y(:,17);

%% 3) 네 구간 / the four legs
P = {'1 TRANSIT', '2 ALIGN', '3 BERTH', '4 MOORED'};
fprintf('\n  W06 Rung 7  the same berth, bow on to the quay  (%s)\n', mdl);
fprintf('    berth (%5.2f, %5.2f) m,  psi_berth %6.1f deg  (rung 5 holds 0.0 deg)\n', ...
        V.berth_N, V.berth_E, y(end,9));
fprintf('      %-10s %9s %9s   %s\n', 'phase', 'entered', 'lasted', 'at the end of the leg');
for k = 1:4
    j = find(ph == k, 1);
    if isempty(j), continue; end
    e = find(ph == k, 1, 'last');
    fprintf('      %-10s %8.2fs %8.2fs   (%6.2f, %6.2f) m  psi %7.2f deg  u %6.3f  v %6.3f m/s\n', ...
            P{k}, t(j), t(e) - t(j), y(e,4), y(e,5), y(e,6), y(e,1), y(e,2));
end

%% 4) 어느 축으로 건넜는가 / which axis crossed the last metres
i3 = ph == 3;
if any(i3)
    fprintf('    across the BERTH leg:  peak |u| %6.3f m/s,  peak |v| %6.3f m/s\n', ...
            max(abs(y(i3,1))), max(abs(y(i3,2))));
    fprintf('                           peak |X| %6.2f N (limit %6.2f),  peak |Y| %6.2f N (limit %6.2f)\n', ...
            max(abs(y(i3,10))), V.X_max, max(abs(y(i3,11))), V.Y_max);
    fprintf('                           on the Y cap %4.1f %% of the leg\n', ...
            100*mean(abs(abs(y(i3,11)) - V.Y_max) < 1e-6));
end
fprintf('    the surge limit is %4.2f times the sway limit\n', V.X_max/V.Y_max);
fprintf('    final  position error %6.3f m   heading error %6.2f deg\n', ...
        hypot(y(end,4) - V.berth_N, y(end,5) - V.berth_E), y(end,6) - y(end,9));
fprintf('\n');
