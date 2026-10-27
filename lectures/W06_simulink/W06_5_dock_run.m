%% W06 · 5 단 — 단계를 밟아 접안한다 / Rung 5 — berthing, phase by phase
%
%  >> W06_5_dock_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_5_dock.slx` 를 **그대로** 돌린다. 캔버스의 접안 자세는
%         psi_berth = 0 — 선체가 부두와 **나란히** 눕고 마지막 몇 미터를
%         옆걸음으로 건넌다.
%      ② 상태기계가 찍은 단계 번호를 읽어 네 구간의 시각과 길이를 잰다.
%      ① Runs W06_5_dock.slx as it stands, with psi_berth = 0.
%      ② Reads the logged phase and times the four legs.
%
%  출력에서 볼 것 / what to look for
%      - 단계는 **빗장이 걸려** 있어 되돌아가지 않는다. 번호가 단조증가한다.
%      - 1 단계의 명령 선수각은 접근점 방위이고, 2 m 안에서 **평평해진다** —
%        분모가 0 으로 가는 자리에서 마지막 값을 들고 있기 때문이다.
%      - 4 단계에서 gate 가 0 이 되어 추력이 끊긴다. 그 뒤로는 관성만 남는다.

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>

%% 1) 돌린다 / run it
mdl = 'W06_5_dock';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

%% 2) 로그를 읽는다 / read the log
V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = W06.time;
ph = y(:,17);

%% 3) 네 구간 / the four legs
P = {'1 TRANSIT', '2 ALIGN', '3 BERTH', '4 MOORED'};
fprintf('\n  W06 Rung 5  berthing, phase by phase  (%s)\n', mdl);
fprintf('    berth (%5.2f, %5.2f) m,  approach (%5.2f, %5.2f) m,  psi_berth %5.1f deg\n', ...
        V.berth_N, V.berth_E, V.app_N, V.app_E, rad2deg(V.psi_berth));
fprintf('      %-10s %9s %9s   %s\n', 'phase', 'entered', 'lasted', 'at the end of the leg');
for k = 1:4
    j = find(ph == k, 1);
    if isempty(j), continue; end
    e = find(ph == k, 1, 'last');
    fprintf('      %-10s %8.2fs %8.2fs   (%6.2f, %6.2f) m  psi %6.2f deg  v %6.3f m/s\n', ...
            P{k}, t(j), t(e) - t(j), y(e,4), y(e,5), y(e,6), y(e,2));
end

%% 4) 어느 축으로 건넜는가 / which axis crossed the last metres
%  7 단이 똑같은 모양으로 찍는다. 6-6 절의 비교표는 **두 출력의 같은 줄**을
%  나란히 놓은 것이고, 그래서 두 스크립트가 같은 구간을 같은 정의로 재야 한다.
%  Rung 7 prints this same block. Section 6-6's comparison lays the two outputs
%  side by side, so both have to measure the same leg by the same definition.
i3 = ph == 3;
if any(i3)
    fprintf('    across the BERTH leg:  peak |u| %6.3f m/s,  peak |v| %6.3f m/s\n', ...
            max(abs(y(i3,1))), max(abs(y(i3,2))));
    fprintf('                           peak |X| %6.2f N (limit %6.2f),  peak |Y| %6.2f N (limit %6.2f)\n', ...
            max(abs(y(i3,10))), V.X_max, max(abs(y(i3,11))), V.Y_max);
    fprintf('                           on the Y cap %4.1f %% of the leg\n', ...
            100*mean(abs(abs(y(i3,11)) - V.Y_max) < 1e-6));
end

%% 5) 끝 자세 / the pose it ends in
fprintf('    phase is monotone (never falls back):  %d\n', all(diff(ph) >= 0));
fprintf('    final  position error %6.3f m   (tolerance %4.2f m)\n', ...
        hypot(y(end,4) - V.berth_N, y(end,5) - V.berth_E), V.R_berth);
fprintf('           heading  error %6.2f deg (tolerance %4.1f deg)\n', ...
        y(end,6) - rad2deg(V.psi_berth), rad2deg(V.psi_tol));
fprintf('           speeds   u %6.3f  v %6.3f m/s (tol %4.2f)   r %6.3f deg/s (tol %4.1f)\n', ...
        y(end,1), y(end,2), V.v_tol, y(end,3), rad2deg(V.r_tol));
fprintf('    |v| crossed v_tol %d times before MOORED\n', ...
        sum(abs(diff(abs(y(ph <= 3, 2)) <= V.v_tol)) > 0));
fprintf('\n');
