%% W06 · 1 단 — 한 점을 잡고 선다 / Rung 1 — holding a point
%
%  >> W06_1_point_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_1_point.slx` 를 **그대로** 돌린다. 명령은 캔버스의 Constant 에
%         박혀 있다 — N_d = 10 m, E_d = 10 m. 고칠 것이 없다.
%      ② 돌리는 동안 실시간 항적 창이 뜨고, 끝나면 StopFcn 이 그림을 그린다.
%      ③ 6-3 절이 예측한 수치를 재서 찍는다.
%      ④ 그 다음 **선수추진기를 꺼서** 한 번 더 돌린다. 완전구동이 무엇을
%         사 주는지는, 그것을 빼 보아야 보인다.
%      ① Runs W06_1_point.slx as it stands: the demand is on the canvas.
%      ② The live track window is up while it runs, and the StopFcn draws the
%         panel when it stops.
%      ③ Measures the numbers Section 6-3 predicts.
%      ④ Then runs it once more with the bow unit switched OFF, for the
%         two-row comparison: what being fully actuated actually buys.
%
%  선수추진기를 어떻게 끄는가 / how the bow unit is switched off
%      모델을 고치지 않는다. 배분기의 Saturation 은 한계를 **숫자가 아니라
%      식**으로 담고 있다 (`_tools/add_allocation3.m`) —
%
%          UpperLimit = '[ T_max;  T_max;  F_B_max]'
%
%      컴파일할 때 작업공간에서 `F_B_max` 를 읽으므로, 돌리기 **전에**
%      `F_B_max = 0` 을 작업공간에 두면 선수추진기의 허용 구간이 [0, 0] 이 되어
%      힘을 전혀 내지 못한다. 블록 하나 건드리지 않고 완전구동이 **빠진** 배가
%      된다. 끝나면 정격으로 되돌린다.
%      The allocation's Saturation holds its limits as EXPRESSIONS, resolved
%      from the base workspace at compile time. Setting F_B_max = 0 before the
%      run collapses the bow unit's allowance to [0, 0] -- the same hull, now
%      under-actuated -- without editing a single block. It is restored after.
%
%  시뮬링크에서 Run 을 눌러도 **똑같다.** 이 파일은 그 Run 을 명령창에서 한 번
%  더 누르고, 그 위에 표 하나를 더 찍을 뿐이다.
%  Pressing Run in Simulink does the same thing; this file only adds the table.
%
%  출력에서 볼 것 / what to look for
%      - 끝 오차가 0.05 m 아래로 떨어진다. 외측 비례 제어만으로 그렇게 된다 —
%        위치에 적분기가 없는데도 정상상태 오차가 없는 것은 내측 PI 가
%        속도 0 을 **정확히** 지키기 때문이다.
%      - 두 축 모두 제 한계에 닿는다. 그러나 **닿아 있는 시간**이 다르다 —
%        같은 대각선 이동인데 횡이 더 오래 붙어 있다. 한계가 3.4 배 작기
%        때문이다 (6-2 절). 아래 saturated 줄의 두 백분율이 그 차이다.

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>  run_alone 은 **없는 것만** 채운다

%% 1) 돌린다 / run it
mdl = 'W06_1_point';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

%% 2) 로그를 읽는다 / read the log
V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = W06.time;
dist = hypot(y(:,7) - y(:,4), y(:,8) - y(:,5));
i05  = find(dist <= 0.5, 1);

%% 3) 6-3 절의 수치 / the numbers of Section 6-3
fprintf('\n  W06 Rung 1  holding a point with three loops  (%s)\n', mdl);
fprintf('    demand          (%6.2f, %6.2f) m   heading %6.2f deg\n', ...
        y(end,7), y(end,8), y(end,9));
fprintf('    reached         (%6.2f, %6.2f) m   heading %6.2f deg\n', ...
        y(end,4), y(end,5), y(end,6));
fprintf('    final error      %6.3f m            heading %6.2f deg\n', ...
        dist(end), y(end,6) - y(end,9));
if ~isempty(i05)
    fprintf('    within 0.5 m at  %6.2f s\n', t(i05));
end
fprintf('    peak speed       u %5.3f m/s (limit %4.2f)   v %5.3f m/s (limit %4.2f)\n', ...
        max(abs(y(:,1))), V.u_lim, max(abs(y(:,2))), V.v_lim);
fprintf('    peak demand      X %6.2f N (limit %6.2f)   Y %6.2f N (limit %6.2f)\n', ...
        max(abs(y(:,10))), V.X_max, max(abs(y(:,11))), V.Y_max);
fprintf('    saturated        X %4.1f %% of the run   Y %4.1f %% - against a limit %.2f times smaller\n', ...
        100*mean(abs(abs(y(:,10)) - V.X_max) < 1e-6), ...
        100*mean(abs(abs(y(:,11)) - V.Y_max) < 1e-6), V.X_max/V.Y_max);

%% 4) 선수추진기를 빼고 한 번 더 / once more, with the bow unit off
%  같은 모델, 같은 명령, 같은 게인. 바뀌는 것은 배분기가 선수추진기에게
%  허락하는 구간 하나뿐이다. 그래서 두 줄의 차이는 **구동 배치**의 차이다.
%  Same model, same demand, same gains. The only change is the bow unit's
%  allowance, so the difference between the two rows is actuation alone.
if ~isempty(i05), t05 = t(i05); else, t05 = NaN; end
row1 = [t05, dist(end), y(end,6) - y(end,9), max(abs(y(:,2))), max(abs(y(:,11)))];

animate  = 0;           %#ok<NASGU>
W06batch = 1;           %#ok<NASGU>  W06_plot 이 바로 돌아간다 / W06_plot returns at once
F_B_max  = 0;           %  선수추진기 정지 / the bow unit is held at zero
sim(mdl);

z    = squeeze(W06.signals.values);  if size(z,1) < size(z,2), z = z.'; end
tz   = W06.time;
dz   = hypot(z(:,7) - z(:,4), z(:,8) - z(:,5));
j05  = find(dz <= 0.5, 1);
if ~isempty(j05), s05 = tz(j05); else, s05 = NaN; end
row2 = [s05, dz(end), z(end,6) - z(end,9), max(abs(z(:,2))), max(abs(z(:,11)))];

fprintf('\n  W06 Experiment 6-3  holding the point (%.0f, %.0f) m, heading %.0f deg\n', ...
        y(end,7), y(end,8), y(end,9));
fprintf('    %-18s %14s %12s %17s %15s %13s\n', 'case', ...
        't to 0.5 m [s]', 'd(end) [m]', 'psi error [deg]', 'max |v| [m/s]', 'max |Y| [N]');
fprintf('    %-18s %14.2f %12.3f %17.2f %15.3f %13.2f\n', 'three thrusters', row1);
fprintf('    %-18s %14.2f %12.3f %17.2f %15.3f %13.2f\n', 'bow unit off',    row2);
fprintf('    F_B peak            with the bow unit %6.2f N,  without it %6.2f N\n', ...
        max(abs(y(:,15))), max(abs(z(:,15))));

%% 5) 같은 점을 선수각 45 도로 / the same point, with the bow at 45 degrees
%  명령 선수각은 캔버스의 Constant 가 **제 이름**으로 들고 있다 (psi_d_cmd).
%  그래서 돌리기 전에 작업공간에 값을 두면 블록 하나 고치지 않고 바뀐다.
%  8 단 스크립트가 똑같은 모양으로 찍는다 — 6-7 절의 네 줄짜리 표는 두 출력의
%  같은 줄을 나란히 놓은 것이다.
%  The heading Constant holds its own NAME, so a value placed in the workspace
%  before the run changes it without touching a block. Rung 8's script prints
%  this same block; Section 6-7 lays the two outputs side by side.
F_B_max   = V.F_B_max;  %  먼저 정격을 되돌린다 / the rating goes back first
psi_d_cmd = deg2rad(45);
sim(mdl);

w   = squeeze(W06.signals.values);  if size(w,1) < size(w,2), w = w.'; end
tw  = W06.time;
dw  = hypot(w(:,7) - w(:,4), w(:,8) - w(:,5));
k05 = find(dw <= 0.5, 1);   if isempty(k05), r05 = NaN; else, r05 = tw(k05); end
U   = hypot(y(:,1), y(:,2));
Uw  = hypot(w(:,1), w(:,2));

fprintf('\n  W06 Rung 1  the same point, two commanded headings  (body-fixed outer loop)\n');
fprintf('    %-12s %14s %12s %14s %13s %13s\n', 'psi_d [deg]', ...
        't to 0.5 m [s]', 'd(end) [m]', 'max |U| [m/s]', 'max |X| [N]', 'max |Y| [N]');
fprintf('    %-12.0f %14.2f %12.3f %14.3f %13.2f %13.2f\n',  0, ...
        t05, dist(end), max(U),  max(abs(y(:,10))), max(abs(y(:,11))));
fprintf('    %-12.0f %14.2f %12.3f %14.3f %13.2f %13.2f\n', 45, ...
        r05, dw(end),   max(Uw), max(abs(w(:,10))), max(abs(w(:,11))));
fprintf('    the per-axis caps allow hypot(%4.2f, %4.2f) = %5.3f m/s on a diagonal\n', ...
        V.u_lim, V.v_lim, hypot(V.u_lim, V.v_lim));
fprintf('    at psi_d 0, |U| stays above the NED ceiling %4.2f m/s until t = %5.2f s\n', ...
        V.v_ned_max, t(find(U > V.v_ned_max, 1, 'last')));

%% 6) 명령과 정격을 되돌린다 / command and rating go back
psi_d_cmd = 0;          %#ok<NASGU>
F_B_max   = V.F_B_max;  %#ok<NASGU>
clear W06batch                      % 다음 Run 은 다시 그림을 그린다 / plots again
fprintf('\n');
