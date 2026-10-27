%% W06 · 8 단 — 같은 점을 NED 에서 잡는다 / Rung 8 — the same point, held in NED
%
%  >> W06_8_ned_run
%
%  이 스크립트가 하는 일 / what this script does
%      ① `W06_8_ned.slx` 를 **그대로** 돌린다. 캔버스의 명령은 1 단과 같다 —
%         N_d = 10 m, E_d = 10 m. 다른 것은 고리가 **어느 좌표계에서** 오차를
%         재는가 하나다.
%      ② 1 단과 견줄 수 있도록 같은 수치를 같은 이름으로 찍는다.
%      ① Runs W06_8_ned.slx as it stands, with the same demand as rung 1.
%      ② Prints the same quantities under the same names, so the two rungs
%         can be laid side by side.
%
%  출력에서 볼 것 / what to look for
%      - 끝 오차는 1 단과 같은 자리로 수렴한다. 두 좌표계가 **같은 평형점**을
%        갖기 때문이다.
%      - 다른 것은 가는 길이다. NED 고리는 축마다 자르지 않고 **속도의 크기**를
%        하나로 자르므로, 대각선으로 갈 때 두 축이 한 한계를 나눠 쓴다.
%        1 단에서는 u 와 v 가 **각각** 제 한계(0.80 · 0.35)까지 갈 수 있었다.
%        그래서 NED 쪽이 같은 점에 **늦게** 닿는다 — 아래 두 시각을 견준다.
%      - 속도의 크기는 v_ned_max 를 조금 **넘는다.** 자르는 것은 요구값이고,
%        속도 고리가 그 요구를 약간 앞질러 따라가기 때문이다 (4 단과 같은
%        2차 효과).
%      - 자르는 것이 **힘이 아니라 속도**라는 것도 아래에 보인다. 횡방향 요구
%        Y 가 Y_max 를 넘고 선수추진기가 제 정격 40 N 에 붙는다. 선체고정
%        고리(1 단)는 축마다 속도를 잘라서 그 자리를 피해 갔다.

%% 0) 경로, 그리고 화면을 켠 채로 / paths, with the live window on
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
animate = 1;            %#ok<NASGU>

%% 1) 돌린다 / run it
mdl = 'W06_8_ned';
load_system(mdl);
sim(mdl);               % InitFcn -> run_alone,  StopFcn -> W06_plot

%% 2) 로그를 읽는다 / read the log
V = W06_vars();
y = squeeze(W06.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = W06.time;
dist = hypot(y(:,7) - y(:,4), y(:,8) - y(:,5));
i05  = find(dist <= 0.5, 1);

%% 3) 6-7 절의 수치 / the numbers of Section 6-7
fprintf('\n  W06 Rung 8  the same point, held in NED  (%s)\n', mdl);
fprintf('    demand          (%6.2f, %6.2f) m\n', y(end,7), y(end,8));
fprintf('    reached         (%6.2f, %6.2f) m   final error %6.3f m\n', ...
        y(end,4), y(end,5), dist(end));
if ~isempty(i05)
    fprintf('    within 0.5 m at  %6.2f s\n', t(i05));
end
fprintf('    peak speed       u %5.3f   v %5.3f m/s\n', ...
        max(abs(y(:,1))), max(abs(y(:,2))));
fprintf('    peak SPEED MAGNITUDE  %5.3f m/s   (the NED loop limits this, not each axis: %4.2f)\n', ...
        max(hypot(y(:,1), y(:,2))), V.v_ned_max);
fprintf('    peak demand      X %6.2f N (limit %6.2f)   Y %6.2f N (limit %6.2f)\n', ...
        max(abs(y(:,10))), V.X_max, max(abs(y(:,11))), V.Y_max);
fprintf('    peak bow force   F_B %6.2f N  (rating %5.2f) - the cap here is on SPEED, not force\n', ...
        max(abs(y(:,15))), V.F_B_max);

%% 4) 같은 점을 선수각 45 도로 / the same point, with the bow at 45 degrees
%  명령 선수각은 캔버스의 Constant 가 **제 이름**으로 들고 있다 (psi_d_cmd).
%  그래서 돌리기 전에 작업공간에 값을 두면 블록 하나 고치지 않고 바뀐다.
%  1 단 스크립트가 똑같은 모양으로 찍는다 — 6-7 절의 네 줄짜리 표는 두 출력의
%  같은 줄을 나란히 놓은 것이다.
%  The heading Constant holds its own NAME, so a value placed in the workspace
%  before the run changes it without touching a block. Rung 1's script prints
%  this same block; Section 6-7 lays the two outputs side by side.
animate   = 0;          %#ok<NASGU>
W06batch  = 1;          %#ok<NASGU>  W06_plot 이 바로 돌아간다 / W06_plot returns at once
psi_d_cmd = deg2rad(45);
sim(mdl);

w   = squeeze(W06.signals.values);  if size(w,1) < size(w,2), w = w.'; end
tw  = W06.time;
dw  = hypot(w(:,7) - w(:,4), w(:,8) - w(:,5));
k05 = find(dw <= 0.5, 1);   if isempty(k05), s05 = NaN; else, s05 = tw(k05); end
if isempty(i05), t05 = NaN; else, t05 = t(i05); end
U   = hypot(y(:,1), y(:,2));
Uw  = hypot(w(:,1), w(:,2));

fprintf('\n  W06 Rung 8  the same point, two commanded headings  (NED outer loop)\n');
fprintf('    %-12s %14s %12s %14s %13s %13s\n', 'psi_d [deg]', ...
        't to 0.5 m [s]', 'd(end) [m]', 'max |U| [m/s]', 'max |X| [N]', 'max |Y| [N]');
fprintf('    %-12.0f %14.2f %12.3f %14.3f %13.2f %13.2f\n',  0, ...
        t05, dist(end), max(U),  max(abs(y(:,10))), max(abs(y(:,11))));
fprintf('    %-12.0f %14.2f %12.3f %14.3f %13.2f %13.2f\n', 45, ...
        s05, dw(end),   max(Uw), max(abs(w(:,10))), max(abs(w(:,11))));
fprintf('    the cap is on the MAGNITUDE, one value in any direction: %5.3f m/s\n', V.v_ned_max);

%  꼭짓점이 어디서 났는지 / where the psi 45 peak falls
j = find(Uw >= max(Uw), 1);
fprintf('    at the psi 45 peak, t = %5.2f s:  u %+6.3f  v %+6.3f m/s\n', tw(j), w(j,1), w(j,2));
fprintf('                                     N demanded %6.2f N m (N_max %5.2f) - inside the opening turn\n', ...
        w(j,12), V.N_max);
fprintf('    sway the NED PI never saw:  %5.2f demanded - %5.2f delivered = %5.2f N\n', ...
        max(abs(w(:,11))), max(abs(w(:,15))), max(abs(w(:,11))) - max(abs(w(:,15))));

psi_d_cmd = 0;          %#ok<NASGU>  명령을 되돌린다 / the command goes back
clear W06batch                      % 다음 Run 은 다시 그림을 그린다 / plots again
fprintf('\n');
