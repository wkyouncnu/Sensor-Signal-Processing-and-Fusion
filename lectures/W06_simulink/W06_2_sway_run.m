%% W06 · 2 단 — 옆으로만 간다 / Rung 2 — pure sway
%
%  >> W06_2_sway_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_2_sway.slx` 를 **그대로** 돌린다. 캔버스의 명령은 N_d = 0,
%         E_d = 13 — 정동으로 13 m. 전진 성분이 없다.
%      ② 돌리는 동안 실시간 항적 창이 뜨고, 끝나면 StopFcn 이 그림을 그린다.
%      ③ 6-2 절이 센 한계 셋을 찍고, 그 가운데 **어느 것이** 먼저 걸리는지 잰다.
%      ④ 그 다음 천장 **위**를 본다. 닫힌 고리는 천장 위를 물어볼 수 없으므로
%         열린 루프 장치 `W06_3_thrust.slx` 를 빌려 Y 를 쓸어 간다.
%      ① Runs W06_2_sway.slx as it stands: 13 m due east, no surge component.
%      ② Live track while it runs, StopFcn panel when it stops.
%      ③ Prints the three ceilings of Section 6-2 and measures which one binds.
%      ④ Then sweeps Y past the ceiling on the open-loop rig, for the leak.
%
%  출력에서 볼 것 / what to look for
%      - 선수추진기는 정격 40 N 에 **닿지 않는다.** 먼저 걸리는 것은 선미쌍의
%        후진 한계이고, 그것이 횡력을 |T_min|/a = 35.13 N 에서 자른다.
%      - 그래서 이 모델의 Y 포화선은 40 이 아니라 35.13 이다. 6-2 절의 요점이
%        한 줄로 보이는 자리다.
%      - 쓸기 표에서 천장 아래 줄은 X = N = 0 이고, 천장 위 줄은 Y 는 나오는데
%        X 와 N 이 새어 나온다. 포화는 **시킨 축을 깎는 것이 아니라 시키지 않은
%        축으로 오차를 옮긴다.**

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>  run_alone 은 **없는 것만** 채운다

%% 1) 돌린다 / run it
mdl = 'W06_2_sway';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

%% 2) 로그를 읽는다 / read the log
V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = W06.time;
dist = hypot(y(:,7) - y(:,4), y(:,8) - y(:,5));

%% 3) 6-2 절의 수치 / the numbers of Section 6-2
fprintf('\n  W06 Rung 2  pure sway, and the limit that binds first  (%s)\n', mdl);
fprintf('    demand          (%6.2f, %6.2f) m\n', y(end,7), y(end,8));
fprintf('    reached         (%6.2f, %6.2f) m   final error %6.3f m\n', ...
        y(end,4), y(end,5), dist(end));
fprintf('    peak surge       u %6.3f m/s        peak sway  v %6.3f m/s (limit %4.2f)\n', ...
        max(abs(y(:,1))), max(abs(y(:,2))), V.v_lim);
fprintf('    peak demand      X %6.2f N          Y %6.2f N (limit %6.2f)\n', ...
        max(abs(y(:,10))), max(abs(y(:,11))), V.Y_max);
fprintf('    peak bow force   F_B %6.2f N        rating %6.2f N\n', ...
        max(abs(y(:,15))), V.F_B_max);
fprintf('    three ceilings on Y, and which one binds\n');
fprintf('      stern ASTERN   |Y| <= |T_min|/a = %6.2f/%5.3f = %7.4f N\n', ...
        abs(V.T_min), V.l_f/(2*V.y_pont), abs(V.T_min)/(V.l_f/(2*V.y_pont)));
fprintf('      stern AHEAD    |Y| <=  T_max /a = %6.2f/%5.3f = %7.4f N\n', ...
        V.T_max, V.l_f/(2*V.y_pont), V.T_max/(V.l_f/(2*V.y_pont)));
fprintf('      bow rating     |Y| <= F_B_max            = %7.4f N\n', V.F_B_max);
fprintf('      binding, and so W06_vars.Y_max           = %7.4f N\n', V.Y_max);
fprintf('    Y saturated      %4.1f %% of the run\n', ...
        100*mean(abs(abs(y(:,11)) - V.Y_max) < 1e-6));

%% 4) 천장 위에서는 무슨 일이 생기는가 / what happens above the ceiling
%  닫힌 고리는 천장 **위**를 물어볼 수 없다 — 포화가 고리 안에 있으므로 요구는
%  35.13 N 에서 잘린다. 그래서 천장을 넘는 요구는 열린 루프 장치에서 본다.
%  `W06_3_thrust.slx` 는 3 단의 장치이고, 여기서는 **계측기로** 빌려 쓴다 —
%  캔버스의 Y_cmd 하나만 쓸어 가며 돌리고, 끝나면 그대로 되돌린다.
%  The closed loop cannot ASK past the ceiling: its saturation is inside the
%  loop. The leak of steps 7-9 therefore has to be shown on the open-loop rig.
%  W06_3_thrust.slx is rung 3's apparatus, borrowed here as an instrument.
rig = 'W06_3_thrust';
load_system(rig);
animate  = 0;           %#ok<NASGU>
W06batch = 1;           %#ok<NASGU>  W06_plot 이 바로 돌아간다 / W06_plot returns at once
X0 = get_param([rig '/X_cmd'], 'Value');
Y0 = get_param([rig '/Y_cmd'], 'Value');
N0 = get_param([rig '/N_cmd'], 'Value');
set_param([rig '/X_cmd'], 'Value', '0');
set_param([rig '/N_cmd'], 'Value', '0');

a = V.l_f/(2*V.y_pont);
fprintf('\n    sweeping Y across the ceiling, open loop  (X = 0, N = 0)\n');
fprintf('      %8s %9s %9s %8s %8s %8s %8s %8s %8s %9s\n', ...
        'Y [N]', 'T_L', 'T_R', 'F_B', 'X', 'Y', 'N', 'X pred', 'N pred', 'psi(end)');
for Yd = [20 30 35 V.Y_max 40 50]
    set_param([rig '/Y_cmd'], 'Value', num2str(Yd));
    sim(rig);
    z = squeeze(W06.signals.values);  if size(z,1) < size(z,2), z = z.'; end
    nL = z(end,13);  nR = z(end,14);
    f  = [V.k_pos*nL^2*(nL >= 0) - V.k_neg*nL^2*(nL < 0)
          V.k_pos*nR^2*(nR >= 0) - V.k_neg*nR^2*(nR < 0)
          z(end,15)];
    tau = V.B*f;
    %  예측: 잘리지 않은 해를 각자의 한계로 자른 뒤 다시 B 를 곱한다 (7~8 단계)
    %  prediction: clip the unclipped solve, then push it back through B
    fp  = [min(max(-a*Yd, V.T_min), V.T_max)
           min(max( a*Yd, V.T_min), V.T_max)
           min(max(Yd, -V.F_B_max), V.F_B_max)];
    tp  = V.B*fp;
    fprintf('      %8.2f %9.2f %9.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %9.2f\n', ...
            Yd, f(1), f(2), f(3), tau(1), tau(2), tau(3), tp(1), tp(3), z(end,6));
end

%% 5) 캔버스를 되돌린다 / put the borrowed rig back
set_param([rig '/X_cmd'], 'Value', X0);
set_param([rig '/Y_cmd'], 'Value', Y0);
set_param([rig '/N_cmd'], 'Value', N0);
set_param(rig, 'Dirty', 'off');
clear W06batch                      % 다음 Run 은 다시 그림을 그린다 / plots again
fprintf('\n');
