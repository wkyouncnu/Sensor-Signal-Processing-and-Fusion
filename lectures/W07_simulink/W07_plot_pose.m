function [f, R] = W07_plot_pose(pf)
%W07_PLOT_POSE  위치·선수각 제어 한 번의 결과 — 명령과 실제를 나란히.
%               One position-and-heading run: the command beside what happened.
%
%   W07_plot_pose           모델의 StopFcn 이 이렇게 부른다 / the StopFcn path
%   W07_plot_pose(prefix)   PNG 까지 저장한다. 러너가 이렇게 부른다 / with PNGs
%   [f, R] = W07_plot_pose(…)  그림 핸들들과 수치 한 벌 / the handles and numbers
%
%   함수인 이유는 `W07_plot_wpt` 와 같다 — StopFcn 은 기본 작업공간에서 돌고,
%   그 공간에는 모델이 읽는 변수들이 있다.
%   A function for the same reason as W07_plot_wpt: the StopFcn runs in the base
%   workspace, where the model's own variables live.
%
%   무엇이 다른가 / what differs from the waypoint run
%       웨이포인트 추종은 **다리 위에 붙어 있는가**를 묻고, 여기서는 **한 자세에
%       서는가**를 묻는다. 그래서 수치도 다르다 — 횡방향 오차 대신 정착 시간과
%       남는 오차다. 가는 길이 10 m 뿐이므로 과도가 전부고, 정상상태는 **멈춘
%       상태를 유지하는 것**이다.
%       Waypoint following asks whether the vessel stays on a leg; this asks
%       whether it comes to rest at one pose. The numbers are therefore the
%       settling time and the error that remains.
%
%   읽는 로그 둘 / the two logs it reads
%       `W07pose`      상태와 명령, 25 열 (`add_measurement`)
%       `W07pose_act`  배분기의 24 열 기록 (`add_allocation_tilt4`)
%     로그 열 / the columns
%       1 u   2 v   3 r   4 N   5 E   6 psi [deg]
%       7-8 p_d [N E]   9 psi_d [deg]   10-11 nu_d [u_d v_d]
%       12-14 tau asked [X Y N]         15-17 tau applied [X Y N]
%
%   See also W07_PLOT_SAT, W07_POSE_RUN, W07POSE_ANIMATE, W07_4_BUILD_POSE.

if nargin < 1, pf = ''; end

if isempty(pf) && base_var('W07quiet', false)
    f = [];  R = struct();
    return
end

[t, y] = log_xy('W07pose', 25);
if isempty(t)
    fprintf('  W07_plot_pose: W07pose 로그가 없다. 먼저 모델을 돌린다.\n');
    f = [];  R = struct();
    return
end

u     = y(:,1);    v   = y(:,2);
N     = y(:,4);    E   = y(:,5);    psi   = y(:,6);
N_d   = y(:,7);    E_d = y(:,8);    psi_d = y(:,9);
u_d   = y(:,10);   v_d = y(:,11);
tau_a = y(:,12:14);                 tau   = y(:,15:17);

%  오차 셋 / the three errors
e_N = N_d - N;     e_E = E_d - E;
e_p = hypot(e_N, e_E);                       % 위치 오차의 크기 / the distance
e_h = wrap180(psi_d - psi);

%  정착 판정 / the settling test
%      "**그 뒤로 다시 벗어나지 않는** 첫 시각" 이다. 처음 들어온 시각으로 재면
%      지나쳤다가 되돌아온 운항도 빨라 보인다
%      the first instant after which the error never leaves the band again, not
%      the first instant it enters: the latter flatters an overshooting run
tol_p = 0.50;   tol_h = 2.00;                % m, deg
R = struct();
R.t_end  = t(end);
R.tol    = [tol_p, tol_h];
R.ts_p   = settle(t, e_p, tol_p);
R.ts_h   = settle(t, abs(e_h), tol_h);
R.fin    = [N(end), E(end), psi(end)];
R.cmd    = [N_d(end), E_d(end), psi_d(end)];
R.e_fin  = [e_p(end), e_h(end)];
R.e_over = [max(N) - max(N_d), max(E) - max(E_d)];
R.nu_max = [max(abs(u)), max(abs(v))];
R.nu_lim = [base_var('u_lim', 0.80), base_var('v_lim', 0.60)];
R.tau_max = [max(abs(tau(:,1))), max(abs(tau(:,2))), max(abs(tau(:,3)))];
%  요구가 의미 있는 표본에서만 센다 / only where a real demand was made:
%       선 뒤의 요구는 0.5 N 아래이고, 배분기는 그런 추진기를 0 에 세운다.
%       그 잔차를 "못 냈다" 고 세면 숫자가 그 사실만 말하게 된다.
%       Once the vessel is standing still the demand is under 0.5 N a unit and
%       the allocator holds those units at zero; counting that residue as a
%       shortfall would make the number report the deadband and nothing else.
big     = max(abs(tau_a), [], 2) > 2.0;
R.short = 0;
if any(big), R.short = max(max(abs(tau_a(big,:) - tau(big,:)))); end

fprintf('\n  W07 position and heading hold with allocation law 4\n');
fprintf('   run length                %8.2f s\n', R.t_end);
fprintf('   commanded pose             N %6.2f m   E %6.2f m   psi %6.2f deg\n', R.cmd);
fprintf('   reached pose               N %6.2f m   E %6.2f m   psi %6.2f deg\n', R.fin);
fprintf('   error at the end          %8.3f m    %6.3f deg\n', R.e_fin);
fprintf('   settling (never leaves)    %6.2f s to %.2f m   %6.2f s to %.2f deg\n', ...
        R.ts_p, tol_p, R.ts_h, tol_h);
fprintf('   overshoot past the target  N %6.3f m   E %6.3f m\n', R.e_over);
fprintf('   peak speed                 u %6.3f m/s (cmd cap %4.2f)   v %6.3f m/s (cmd cap %4.2f)\n', ...
        R.nu_max(1), R.nu_lim(1), R.nu_max(2), R.nu_lim(2));
fprintf('   peak force on the hull     X %6.2f N   Y %6.2f N   N %6.2f N m\n', R.tau_max);
fprintf('   worst |asked - applied|   %8.4f  N, over the samples asking above 2 N\n', R.short);

%% ---- 그림 1 — 명령 대 실제 / figure 1, command against actual ---------
C = palette();
f = lab_fig('W07  position and heading  -  command against actual', 1250, 780);

pan(f, 1, t, {N, N_d}, {'-','--'}, {C.act, C.cmd}, ...
    {'N  actual','N_d  command'}, 'north  [m]', ...
    'North: the position command and the position reached', false);

pan(f, 2, t, {E, E_d}, {'-','--'}, {C.act, C.cmd}, ...
    {'E  actual','E_d  command'}, 'east  [m]', ...
    'East: the same question on the other axis', false);

pan(f, 4, t, {psi, psi_d}, {'-','--'}, {C.act, C.cmd}, ...
    {'\psi  actual','\psi_d  command'}, '\psi  [deg]', ...
    'Heading: held independently of where the vessel goes', false);

pan(f, 5, t, {u, v, u_d, v_d}, {'-','-','--','--'}, {C.act, C.sway, C.act, C.sway}, ...
    {'u  actual','v  actual','u_d  outer loop','v_d  outer loop'}, 'u , v  [m/s]', ...
    'Speeds: the outer loop commands both, and sway is not zero', true);

pan(f, 7, t, {tau(:,1), tau(:,2), tau_a(:,1), tau_a(:,2)}, {'-','-','--','--'}, ...
    {C.act, C.sway, C.cmd, C.aux}, ...
    {'X applied','Y applied','X asked','Y asked'}, '\tau_X , \tau_Y  [N]', ...
    'Surge and sway force: asked by the loops, delivered by the units', true);

pan(f, 8, t, {tau(:,3), tau_a(:,3)}, {'-','--'}, {C.act, C.cmd}, ...
    {'N applied','N asked'}, '\tau_N  [N m]', ...
    'Yaw moment: asked and delivered', true);

ax = subplot(3, 3, [3 6 9], 'Parent', f);  hold(ax, 'on');
plot(ax, [E(1) E_d(end)], [N(1) N_d(end)], ':', 'Color', [0.55 0.55 0.55], ...
     'LineWidth', 1.0, 'DisplayName', 'straight line to the target');
plot(ax, E, N, '-', 'Color', C.act, 'LineWidth', 1.6, 'DisplayName', 'track');
track_ships({[N E psi]}, C.act, 'Marks', 9, 'MinLength', 0.60);
ghost(ax, N_d(end), E_d(end), psi_d(end));
plot(ax, E(1), N(1), 'ks', 'MarkerFaceColor', 'w', 'MarkerSize', 7, ...
     'HandleVisibility', 'off');
xlabel(ax, 'East [m]');  ylabel(ax, 'North [m]');
pad = 0.12 * max([max(E)-min(E), max(N)-min(N), 4]);
xlim(ax, [min([E; E_d])-pad-1.5, max([E; E_d])+pad+1.5]);
ylim(ax, [min([N; N_d])-pad-1.5, max([N; N_d])+pad+1.5]);
daspect(ax, [1 1 1]);
title(ax, {'Track from (0, 0) to the commanded pose', ...
           'the dashed hull is where the vessel was told to end'}, 'FontSize', 9);
legend(ax, 'Location', 'northwest', 'FontSize', 7, 'Box', 'off', 'Color', 'none');

sgtitle(f, sprintf(['W07 position and heading control, allocation law 4   ' ...
                    '|   target  N %.1f m,  E %.1f m,  \\psi %.1f deg'], ...
                   N_d(end), E_d(end), psi_d(end)), ...
        'FontSize', 11, 'FontWeight', 'bold');

savepng(f, pf, '_cmd');

%% ---- 그림 2 — 한계 / figure 2, the limits -----------------------------
A = base_var('W07pose_act', []);
if isempty(A)
    fprintf('   W07pose_act 가 없어 포화 그림은 건너뛴다.\n');
else
    [f2, Rs] = W07_plot_sat(A, t, 'position hold: are the four units inside their limits?', ...
                            sat_path(pf));
    f = [f, f2];
    R.sat = Rs;
end
end

% =========================================================================
function [t, y] = log_xy(nm, ncol)
t = [];  y = [];
if ~evalin('base', sprintf('exist(''%s'',''var'')', nm)), return; end
W = evalin('base', nm);
if ~isstruct(W) || ~isfield(W, 'signals'), return; end
y = squeeze(W.signals.values);
if size(y,1) < size(y,2), y = y.'; end
if size(y,2) < ncol, y = [];  return; end
t = W.time(:);
end

% -------------------------------------------------------------------------
function ts = settle(t, e, tol)
%  마지막으로 띠를 벗어난 다음 표본의 시각. 끝까지 벗어난 적이 없으면 0,
%  끝에도 밖이면 NaN / the sample after the last excursion; 0 if never outside,
%  NaN if still outside at the end
k = find(e > tol, 1, 'last');
if isempty(k)
    ts = 0;
elseif k == numel(t)
    ts = NaN;
else
    ts = t(k+1);
end
end

% -------------------------------------------------------------------------
function C = palette()
C = struct('act',  [0    0.45 0.74], ...
           'cmd',  [0.75 0.10 0.10], ...
           'sway', [0.85 0.33 0.10], ...
           'aux',  [0.49 0.18 0.56], ...
           'grey', [0.40 0.40 0.40]);
end

% -------------------------------------------------------------------------
function a = pan(f, k, t, D, S, CL, NM, yl, ttl, zero)
a = subplot(3, 3, k, 'Parent', f);  hold(a, 'on');  grid(a, 'on');
for i = 1:numel(D)
    plot(a, t, D{i}, S{i}, 'Color', CL{i}, 'LineWidth', 1.4, 'DisplayName', NM{i});
end
if zero, yline(a, 0, 'k:', 'HandleVisibility', 'off'); end
xlabel(a, 'time [s]');  ylabel(a, yl);
xlim(a, [0 t(end)]);
title(a, ttl, 'FontSize', 9);
legend(a, 'Location', 'best', 'FontSize', 7, 'Box', 'off', 'Color', 'none');
end

% -------------------------------------------------------------------------
function ghost(a, N, E, psi_deg)
%  명령된 자세를 **선체 모양으로** 그린다. 점 하나로 두면 45 도 선수각 명령이
%  그림에 없다 / the commanded pose as a hull, because a dot cannot show the
%  heading that was commanded
L = 2.00;  b = L*(1.08/2.00)/2;
P = [ 0.50*L  0 ; 0.20*L  b ; -0.50*L  b ; -0.50*L -b ; 0.20*L -b ];
c = cosd(psi_deg);  s = sind(psi_deg);
Nn = N + P(:,1)*c - P(:,2)*s;
Ee = E + P(:,1)*s + P(:,2)*c;
plot(a, [Ee; Ee(1)], [Nn; Nn(1)], '--', 'Color', [0.75 0.10 0.10], ...
     'LineWidth', 1.1, 'DisplayName', 'commanded pose');
plot(a, E, N, 'p', 'Color', [0.75 0.10 0.10], 'MarkerFaceColor', [1 0.85 0.85], ...
     'MarkerSize', 9, 'HandleVisibility', 'off');
end

% -------------------------------------------------------------------------
function e = wrap180(d)
e = mod(d + 180, 360) - 180;
end

% -------------------------------------------------------------------------
function p = sat_path(pf)
if isempty(pf), p = '';  else, p = [pf '_sat.png']; end
end

% -------------------------------------------------------------------------
function savepng(f, pf, suf)
if isempty(pf), return; end
p = [pf suf '.png'];
try
    exportgraphics(f, p, 'Resolution', 150);
catch
    print(f, p, '-dpng', '-r150');
end
fprintf('    saved %s\n', p);
end
