%% W06 · 3 단 — 배분기를 열린 루프로 / Rung 3 — the allocation, in open loop
%
%  >> W06_3_thrust_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_3_thrust.slx` 를 **그대로** 한 번 돌린다. 캔버스의 명령은
%         X = 40 N, Y = 15 N, N = 10 N m — 세 축을 한꺼번에 준다.
%      ② 그 다음 캔버스의 Constant **셋만** 바꿔 가며 세 번 더 돌린다.
%         한 축씩 준 셋을 더하면 함께 준 하나와 같아야 한다 — 중첩 시험.
%      ③ 끝나면 캔버스 값을 되돌리고 모델을 깨끗한 채로 둔다.
%      ① Runs the model once at the canvas values, with the live view on.
%      ② Then re-runs it three times with one axis commanded at a time.
%      ③ Restores the canvas values and leaves the model unmodified.
%
%      고리가 없다. 명령이 그대로 배분기로 들어가므로 **역행렬이 푸는 것이
%      아니라 읽히는 것**임을 이 단에서 본다.
%      No loop is closed here: the demand goes straight into the allocation.
%
%  출력에서 볼 것 / what to look for
%      - 세 축을 하나씩 준 추력을 더한 것과 함께 준 추력의 차가 기계 정밀도다.
%        B 가 상수 행렬이므로 배분은 선형이고, 그래서 중첩이 성립한다.
%      - 축마다 도는 추진기가 다르다: 전진은 선미쌍이 같은 쪽으로, 선회는
%        반대쪽으로, 횡은 선수추진기 혼자.

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>

%% 1) 캔버스 그대로 한 번 / once, at the canvas values
mdl = 'W06_3_thrust';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
X0 = get_param([mdl '/X_cmd'], 'Value');
Y0 = get_param([mdl '/Y_cmd'], 'Value');
N0 = get_param([mdl '/N_cmd'], 'Value');

fprintf('\n  W06 Rung 3  the allocation, in open loop  (%s)\n', mdl);
fprintf('    canvas demand    X %6.2f N   Y %6.2f N   N %6.2f N m\n', ...
        y(end,10), y(end,11), y(end,12));
fprintf('    shafts           n_L %7.2f   n_R %7.2f rad/s   F_B %6.2f N\n', ...
        y(end,13), y(end,14), y(end,15));

%% 2) 한 축씩, 그리고 셋을 함께 / one axis at a time, then all three
%  애니메이션도 끝 그림도 꺼 둔다 — 같은 모델을 네 번 그릴 일이 아니고,
%  StopFcn 의 요약 칸이 네 번 끼어들면 아래 표를 읽을 수 없다.
%  `W06batch` 가 있는 동안 W06_plot 은 바로 돌아간다 / W06_plot returns at once
%  while W06batch exists, so the sweep prints only the table below.
animate  = 0;           %#ok<NASGU>
W06batch = 1;           %#ok<NASGU>
D = [str2double(X0) 0 0
     0 str2double(Y0) 0
     0 0 str2double(N0)
     str2double(X0) str2double(Y0) str2double(N0)];
L = {'surge only', 'sway only', 'yaw only', 'all three'};
Tr = zeros(4,3);        % 돌려받은 추력 [T_L T_R F_B] / the thrusts that came back

%  마지막 두 열은 **움직임**이다. 앞의 열들이 힘이 주문대로 나왔음을 보이고,
%  이 둘은 그 힘이 만든 운동이 주문과 다를 수 있음을 보인다 — N = 0 을 준 줄의
%  선수각이 0 이 아니면 그것은 배분기의 잘못이 아니라 M 의 비대각 항이다.
%  The last two columns are MOTION, not force. A row that commanded N = 0 and
%  still ends with a heading is not an allocation error: it is M_26.
fprintf('\n    demand -> thrust, one axis at a time\n');
fprintf('      %-12s %8s %8s %8s   %9s %9s %9s   %9s %9s\n', ...
        'case', 'X [N]', 'Y [N]', 'N [N m]', 'n_L', 'n_R', 'F_B [N]', ...
        'psi [deg]', '|r|max');
for k = 1:4
    set_param([mdl '/X_cmd'], 'Value', num2str(D(k,1)));
    set_param([mdl '/Y_cmd'], 'Value', num2str(D(k,2)));
    set_param([mdl '/N_cmd'], 'Value', num2str(D(k,3)));
    sim(mdl);
    z = squeeze(W06.signals.values);  if size(z,1) < size(z,2), z = z.'; end
    nL = z(end,13);  nR = z(end,14);
    Tr(k,1) = V.k_pos*nL^2*(nL >= 0) - V.k_neg*nL^2*(nL < 0);
    Tr(k,2) = V.k_pos*nR^2*(nR >= 0) - V.k_neg*nR^2*(nR < 0);
    Tr(k,3) = z(end,15);
    fprintf('      %-12s %8.2f %8.2f %8.2f   %9.2f %9.2f %9.2f   %9.2f %9.3f\n', ...
            L{k}, D(k,1), D(k,2), D(k,3), nL, nR, z(end,15), ...
            z(end,6), rad2deg(max(abs(z(:,3)))));
end

%% 3) 중첩 / superposition
res = sum(Tr(1:3,:), 1) - Tr(4,:);
fprintf('\n    superposition   T(X) + T(Y) + T(N) - T(X,Y,N)\n');
fprintf('      residual       T_L %10.3e   T_R %10.3e   F_B %10.3e  N\n', res);
fprintf('      tau from B     X %8.3f   Y %8.3f   N %8.3f  N, N m\n', V.B*Tr(4,:)');

%% 4) 캔버스를 되돌린다 / put the canvas back
set_param([mdl '/X_cmd'], 'Value', X0);
set_param([mdl '/Y_cmd'], 'Value', Y0);
set_param([mdl '/N_cmd'], 'Value', N0);
set_param(mdl, 'Dirty', 'off');
clear W06batch                      % 다음 Run 은 다시 그림을 그린다 / plots again
fprintf('\n');
