%W07_ALLOC_RUN  7주차 제어배분 — §7-8 부터 §7-13 까지를 **이 파일 하나에서** 돈다.
%               Week 7 control allocation: 7-8 to 7-13, out of this one file.
%
%  고르는 법 / how to choose
%      아래 SEC 목록에서 **줄을 주석 처리하면 그 절은 돌지 않는다.** 아무것도
%      주석 처리하지 않으면 여섯 절이 차례로 돈다.
%      Comment a line out of the SEC list below and that section does not run.
%      With nothing commented out, all six sections run, in order.
%
%  시뮬링크에서 직접 / straight from Simulink
%      §7-13 은 모델 `W07_alloc_chain` 을 돈다. 이 스크립트가 한 번 돌고 나면
%      `law` 와 `tau_cmd` 가 작업공간에 남으므로, 모델을 열고 Run 을 누르는 것만
%      으로 같은 법칙이 다시 돈다. 다른 법칙을 보려면 작업공간의 `law` 를
%      1~4 로 바꾸고 Run 을 누른다. `.slx` 는 고치지 않는다.
%      Section 7-13 runs the model W07_alloc_chain. After this script has run
%      once, `law` and `tau_cmd` are left on the workspace, so opening the model
%      and pressing Run repeats the same law. To see another, change `law` on
%      the workspace to 1..4 and press Run. The .slx is never edited.
%
%  밖에 두는 것 / what is left outside this file
%      `W07_alloc`     배분 법칙 여덟 가지. 이 스크립트의 표(§7-8~§7-12)가 쓴다.
%                      모델은 이것을 부르지 않는다 — `allocation` 서브시스템의
%                      MATLAB Function 블록 넷이 법칙 1~4 를 **각자 안에서** 끝내고,
%                      Multiport Switch 가 `law` 로 하나를 고른다
%                      the eight laws, used by this script's tables. The model
%                      does not call it: four MATLAB Function blocks inside the
%                      allocation subsystem each hold one law, complete, and a
%                      Multiport Switch picks one of them with `law`
%      `otter_config` · `otter_tilt4` · `otter_M`   공용 플랜트 / shared plant
%      `W07_plot_ca`   §7-13 모델의 StopFcn / the StopFcn of the 7-13 model
%
%      그 밖의 계산과 그림은 전부 이 파일 안에 있다 — 표를 찍고 그림을 그리는
%      데 다른 `.m` 을 열 필요가 없다.
%      Everything else -- every table and every figure -- is in this file.
%
%  See also W07_OPENLOOP_RUN, W07_ALLOC, W07_0_SETUP.

close all;

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

cfg = otter_config('quad_tilt');
B   = cfg.B;
V   = W07_vars();
if ~isfolder(fullfile(here, 'img')), mkdir(fullfile(here, 'img')); end

% 여섯 절이 같은 설정을 쓴다 / every section uses the same settings
% 작업공간에 같은 이름이 남아 있어도 덮어쓴다 / overwrite whatever P was before
P           = struct();
P.W         = diag(repmat([1 10], 1, 4));   % 가로 성분이 열 배 비싸다 / f_y priced 10x
P.alpha_max = cfg.alpha_max(1);             % 서보 각 한계 / servo-angle limit
P.Q         = eye(3);                       % tau 오차의 가중 / weight on the tau error
P.eps_reg   = 1e-4;                         % 정칙화 / regularisation
P.T_pos     = cfg.k_pos * cfg.n_max^2;      % 전진 추력 한계 [N] / ahead thrust cap
P.T_neg     = cfg.k_neg * cfg.n_min^2;      % 후진 추력 한계 [N] / astern thrust cap
P.n_chord   = 3;                            % 추력 캡의 내접 현 수 / inscribed chords

%% 돌릴 절 — 줄을 주석 처리하면 그 절이 빠진다 / the sections to run ----------
%     한 줄이 한 절이다. `%` 하나로 절 하나가 빠진다
%     one line is one section; one % removes one section
SEC = { ...
    '7-8'   'the allocation problem and its minimum-norm solution'
    '7-9'   'the weight matrix W'
    '7-10'  'the servo-angle limit'
    '7-11'  'the time one solve takes'
    '7-12'  'two limits: the servo angle and the shaft speed'
    '7-13'  'the four laws inside one model'
};

%% §7-13 에서 돌릴 법칙 — 여기도 줄을 주석 처리해서 고른다 / the laws of 7-13 --
LAWS = { ...
    1  'minimum norm'
    2  'weighted minimum norm'
    3  'weighted, folded onto the servo limit'
    4  'servo limit and thrust cap as constraints'
};

assert(~isempty(SEC), 'W07:noSection', 'every line of SEC is commented out');
fprintf('\nW07 control allocation -- %d of 6 sections selected :', size(SEC,1));
fprintf(' %s', string(SEC(:,1)));
fprintf('\n');

%% (7-8) 해는 무한히 많고, 그 중 노름이 가장 작은 하나 / the minimum-norm one --
if any(strcmp(SEC(:,1), '7-8'))

tau_d = [80; 30; 20];
fprintf('\n=== 7-8  the allocation problem and its minimum-norm solution ===\n');
fprintf('B is %dx%d,  rank %d,  null space dimension %d\n', ...
        size(B,1), size(B,2), rank(B), size(B,2)-rank(B));
fprintf('demand  tau_d = [%.0f N, %.0f N, %.0f N m]\n', tau_d);

% 영공간 벡터를 더해도 같은 tau 가 나온다 / a null-space vector leaves tau unchanged
f0 = W07_alloc(B, tau_d, 'pinv');
Z  = null(B);
f1 = f0 + 40*Z(:,1);
fprintf('\n(1) two solutions that give the same tau\n');
fprintf('    minimum norm      ||f|| = %7.2f N   ||B f - tau|| = %.2e\n', ...
        norm(f0), norm(B*f0 - tau_d));
fprintf('    null space added        %7.2f N   %21.2e\n', ...
        norm(f1), norm(B*f1 - tau_d));
fprintf('    -> the same force costs the thrusters %.0f %% more\n', ...
        100*(norm(f1)/norm(f0) - 1));

fprintf('\n(2) minimum norm  f = B^T (B B^T)^{-1} tau\n');
fprintf('    unit      f_x [N]   f_y [N]\n');
fprintf('     %d      %9.3f %9.3f\n', [1:4; f0(1:2:7).'; f0(2:2:8).']);

% 여덟 성분을 여덟 명령으로 / the eight components, turned into eight commands
H = hw(B, f0, cfg);
fprintf('\n(3) hardware command\n');
fprintf('    unit     T [N]   delta [deg]    n [rad/s]   |delta|<=45?\n');
for i = 1:4
    fprintf('     %d    %8.3f %11.2f %12.2f        %s\n', i, H.T(i), ...
        rad2deg(H.delta(i)), H.n(i), ...
        string(abs(H.delta(i)) <= cfg.alpha_max(i)+1e-9));
end
fprintf('    rho = %.4f   (1 means the thrust limit was not reached)\n', H.rho);
fprintf('    tau achieved = [%.3f %.3f %.3f]   distance from the demand %.2e\n', ...
        H.tau, norm(H.tau - tau_d));

% 그림 — 평면도 위의 네 추력 화살표와 요구한 힘. 추력은 빨강이고 축척이 하나,
% 요구한 힘은 파랑이고 **단위가 다르므로** 축척이 따로다
% the figure: the four thrust arrows seen from above, with the demand. The
% thrusts are red on one scale, the demand is blue on a scale of its own
% because its units are different
xp = cfg.pos(1,:);  yp = cfg.pos(2,:);  sm = cfg.mount;
fig = figure('Color','w','Position',[80 80 520 640]);
hold on; axis equal; grid on
for sy = [-1 1]      % 두 폰툰. 가로축이 y_b 다 / two pontoons; y_b is horizontal
    rectangle('Position',[sy*0.395-0.16, -1.45, 0.32, 3.35], ...
              'Curvature',0.35,'EdgeColor',[.65 .65 .65],'FaceColor',[.95 .95 .95]);
end
sc  = 0.70/max(abs(H.T));       % 추력 화살표 축척 / thrust arrow scale [m/N]
sct = 0.70/norm(tau_d(1:2));    % tau 는 따로 / tau has its own
for i = 1:4
    vx = sm(i)*H.T(i)*cos(H.delta(i));  vy = sm(i)*H.T(i)*sin(H.delta(i));
    plot(yp(i), xp(i), 'ko','MarkerFaceColor','k','MarkerSize',6);
    quiver(yp(i), xp(i), sc*vy, sc*vx, 0, 'LineWidth',2,'Color',[.85 .2 .2], ...
           'MaxHeadSize',0.9);
    text(yp(i)+0.10, xp(i)-0.17, sprintf('%d:  %.0f N,  %.0f%c', ...
         i, H.T(i), rad2deg(H.delta(i)), char(176)), 'FontSize',9);
end
quiver(0, 0, sct*tau_d(2), sct*tau_d(1), 0, 'LineWidth',2.5, ...
       'Color',[.1 .3 .8], 'MaxHeadSize',0.9);
text(-0.62, 0.62, sprintf('\\tau_d = [%.0f N, %.0f N, %.0f Nm]', tau_d), ...
     'FontSize',10,'Color',[.1 .3 .8],'HorizontalAlignment','right');
text(-1.50, -1.80, {'red   thrust of each unit, to scale', ...
                    'blue  demanded X and Y, own scale'}, 'FontSize',9);
xlabel('y_b  (starboard) [m]');  ylabel('x_b  (bow) [m]');
title('Minimum-norm allocation');
xlim([-1.60 1.60]);  ylim([-2.1 2.5]);
savepng(fig, fullfile(here, 'img', 'W07_alloc_pinv.png'));

end

%% (7-9) 가중행렬은 값표다 / the weight matrix is a price list ----------------
if any(strcmp(SEC(:,1), '7-9'))

% B 의 둘째 줄이 [0 1 0 1 0 -1 0 -1] 이므로 Y 는 f_y 열만이 낸다. 따라서
% sum|f_y| 는 요구가 정한 값에 묶여 있고, f_y 를 비싸게 매겨도 줄지 않는다
% Row 2 of B is [0 1 0 1 0 -1 0 -1], so Y comes from the f_y columns alone. The
% sum of |f_y| is pinned by the demand; what the price list moves is who pays
tau_d = [80; 30; 20];
wlist = [1 3 10 30 100 300 1000];

fprintf('\n=== 7-9  the weight matrix W ===\n');
fprintf('demand tau_d = [%.0f N, %.0f N, %.0f N m],  W = diag([1 w 1 w 1 w 1 w])\n', tau_d);
fprintf('Y comes from the f_y columns alone (row 2 of B = [%s]) -> sum|f_y| is pinned\n\n', ...
        strtrim(sprintf('%g ', B(2,:))));
fprintf('       w   sum|f_y| [N]   f_x spread [N]   max|delta| [deg]   ||f|| [N]   ||B f - tau||\n');

md = zeros(size(wlist));  nf = md;  sf = md;  sp = md;
for j = 1:numel(wlist)
    f  = W07_alloc(B, tau_d, 'wpinv', struct('W', diag(repmat([1 wlist(j)], 1, 4))));
    H  = hw(B, f, cfg);
    fx = f(1:2:end);  fy = f(2:2:end);
    md(j) = max(abs(rad2deg(H.delta)));
    nf(j) = norm(f);
    sf(j) = sum(abs(fy));
    sp(j) = max(abs(fx)) - min(abs(fx));   % f_x 의 쏠림 / how skewed f_x is
    fprintf('  %6g %13.2f %16.2f %18.2f %12.2f %15.1e\n', ...
            wlist(j), sf(j), sp(j), md(j), nf(j), norm(B*f - tau_d));
end

% W 를 통째로 키워도 해가 같다 — 비율만이 뜻을 가진다
% scaling the whole of W changes nothing: only the ratios carry meaning
f_a = W07_alloc(B, tau_d, 'wpinv', struct('W', diag(repmat([1 10],1,4))));
f_b = W07_alloc(B, tau_d, 'wpinv', struct('W', 1000*diag(repmat([1 10],1,4))));
fprintf('\ndistance between the W and 1000*W solutions : %.2e N   (only ratios matter)\n', ...
        norm(f_a - f_b));

% 값표가 실제로 바꾸는 것 — 어느 추진기가 몫을 지는가
% what the price list does change: which unit carries the share
f2   = W07_alloc(B, tau_d, 'wpinv', struct('W', diag([1 10 1 10 5 50 5 50])));
H2   = hw(B, f2,  cfg);
H1   = hw(B, f_a, cfg);
shr1 = 100*sum(abs(H1.T(3:4)))/sum(abs(H1.T));
shr2 = 100*sum(abs(H2.T(3:4)))/sum(abs(H2.T));
fprintf('\nwhat the price list can change: who carries the share\n');
fprintf('  same price fore and aft : |T| = [%6.2f %6.2f %6.2f %6.2f] N   aft pair %.1f %%\n', ...
        abs(H1.T), shr1);
fprintf('  aft priced 5x dearer    : |T| = [%6.2f %6.2f %6.2f %6.2f] N   aft pair %.1f %%\n', ...
        abs(H2.T), shr2);
fprintf('\nwhat the price list cannot change: what the demand has already fixed\n');
fprintf('  sum|f_y| : %.2f N and %.2f N  (Y = %.0f N fixes it)\n', ...
        sum(abs(f_a(2:2:end))), sum(abs(f2(2:2:end))), tau_d(2));

% 그림 — 왼쪽은 바꾸지 못하는 것, 오른쪽은 바꾸는 것. 왼쪽 축에 힘(N),
% 오른쪽 축에 각(deg) — 한 축에 올리면 30 N 과 30 deg 가 포개진다
% the figure: what W cannot change (left) and what it can (right). Forces in N
% on the left axis, the angle in deg on the right: on one axis 30 N and 30 deg
% would lie on top of each other
fig = figure('Color','w','Position',[80 80 920 340]);
subplot(1,2,1)
yyaxis left
semilogx(wlist, sf, 'd:', 'LineWidth',1.6,'MarkerFaceColor','auto'); hold on
semilogx(wlist, sp, 's-', 'LineWidth',1.8,'MarkerFaceColor','auto');
ylabel('force components  [N]');  ylim([0 40]);
yyaxis right
semilogx(wlist, md, 'o-', 'LineWidth',1.8,'MarkerFaceColor','auto'); hold on
yline(rad2deg(cfg.alpha_max(1)), '--', '45 deg servo limit', 'LineWidth',1.2, ...
      'LabelHorizontalAlignment','right','LabelVerticalAlignment','bottom','FontSize',8);
ylabel('max |\delta_i|  [deg]');  ylim([0 50]);
grid on;  xlabel('w  —  price put on the sideways component f_y');
legend({'\Sigma|f_y| (pinned by Y)','|f_x| spread','max |\delta_i|'}, ...
       'Location','northwest','FontSize',8);
title({'Pricing f_y cannot reduce the tilt:','\Sigma|f_y| is fixed, so f_x goes lopsided instead'}, ...
      'FontSize',9);
subplot(1,2,2)
bar([abs(H1.T); abs(H2.T)]');  grid on
set(gca,'XTickLabel',{'unit 1','unit 2','unit 3','unit 4'});
ylabel('|T_i|  [N]');  ylim([0 58]);
legend({sprintf('equal price  (aft %.0f %%)', shr1), ...
        sprintf('aft 5x dearer  (aft %.0f %%)', shr2)}, ...
       'Location','northwest','FontSize',8);
title({'What the price list can do:','move the load between units'},'FontSize',9);
savepng(fig, fullfile(here, 'img', 'W07_alloc_weights.png'));

end

%% (7-10) 서보 각 한계 / the servo-angle limit -------------------------------
if any(strcmp(SEC(:,1), '7-10'))

amax     = rad2deg(P.alpha_max);
tau_hard = [15; 70; 10];              % 한계 밖의 요구 / a demand outside the limit

fprintf('\n=== 7-10  the servo-angle limit ===\n');
fprintf('a demand that exceeds it,  tau = [%.0f N, %.0f N, %.0f N m]\n', tau_hard);
fprintf('  (the sideways force is larger than the forward one -> the angle grows)\n\n');
fprintf('  method       max|delta| [deg]   ||B f - tau|| [N]   ||f|| [N]   QPs   exit\n');
for m = ["wpinv" "clip" "qp" "wls" "wls16"]
    [f, in] = W07_alloc(B, tau_hard, char(m), P);
    H = hw(B, f, cfg);
    fprintf('  %-10s %13.2f %18.3f %12.2f %6d %6d\n', m, ...
            max(abs(rad2deg(H.delta))), norm(H.tau - tau_hard), norm(f), ...
            in.ntried, in.exit);
end

% 추력 부호를 고정하면 각 한계가 직선 둘이 되어 QP 하나가 된다. 부호 조합이
% 열여섯 가지이므로 하나만 푸는 'qp' 는 틀릴 수 있고, 'wls16' 은 열여섯을
% 모두 풀어 가장 싼 것을 남긴다
% Fixing the thrust signs turns the angle limit into two straight lines, so the
% problem becomes one QP. There are sixteen sign combinations: 'qp' solves the
% one the closed form suggests, 'wls16' solves all sixteen and keeps the best
[~, i1] = W07_alloc(B, tau_hard, 'qp',    P);
[~, i2] = W07_alloc(B, tau_hard, 'wls16', P);
fprintf('\nsign combination from the closed form  sigma = [%2d %2d %2d %2d]  -> quadprog exit %d\n', ...
        i1.sigma, i1.exit);
fprintf('best of the sixteen combinations       sigma = [%2d %2d %2d %2d]  -> cost %.4f\n', ...
        i2.sigma, i2.cost);
fprintf('  -> the demand is feasible, but not with the sign combination the\n');
fprintf('     weighted minimum norm produced\n');

% 같은 법칙들을 요구 궤적 하나에 걸어 본다 — 요구 하나가 아니라 201 점이다
% the same laws over one trajectory: 201 demands rather than one
ts  = linspace(0, 20, 201);
tau = [100*sin(0.5*ts); 60*cos(0.3*ts); 30*sin(0.7*ts)];
mth = ["pinv" "wpinv" "clip" "qp" "wls" "wls16"];
nm  = numel(mth);
MD  = zeros(nm, numel(ts));  ER = zeros(nm, numel(ts));
D1  = zeros(nm, numel(ts));  EF = zeros(nm, numel(ts));
RHO = ones(nm, numel(ts));
for a = 1:nm
    for k = 1:numel(ts)
        [f, in] = W07_alloc(B, tau(:,k), char(mth(a)), P);
        H = hw(B, f, cfg);
        MD(a,k)  = max(abs(rad2deg(H.delta)));
        D1(a,k)  = rad2deg(H.delta(1));
        ER(a,k)  = norm(H.tau - tau(:,k));
        RHO(a,k) = H.rho;
        EF(a,k)  = in.exit;
    end
end

% 통계는 **해가 나온 점에서만** 낸다. `quadprog`·`lsqlin` 은 실행 불가능한
% 마지막 반복값을 그럴듯한 숫자로 돌려준다
% The statistics are taken ONLY where a solution was found: quadprog and lsqlin
% return the last infeasible iterate as a plausible looking number
fprintf('\nthe demand  tau = [100 sin0.5t ; 60 cos0.3t ; 30 sin0.7t],  t = 0..20 s, %d points\n\n', ...
        numel(ts));
fprintf('  method     solved    past limit   max|delta|   mean |tau err|   max |tau err|   rho<1\n');
fprintf('           [%% of pts]    [%% of pts]       [deg]             [N]             [N] [%% of pts]\n');
for a = 1:nm
    ok = EF(a,:) > 0;
    fprintf('  %-9s %8.1f %13.1f %12.2f %15.3f %15.3f %10.1f\n', mth(a), ...
        100*mean(ok), ...
        100*mean(MD(a,ok) > amax + 1e-6), max(MD(a,ok)), ...
        mean(ER(a,ok)), max(ER(a,ok)), 100*mean(RHO(a,ok) < 1-1e-9));
end
fprintf('\n  (the limit and error statistics are taken only where a solution was\n');
fprintf('   found -- qp fails to find one at some of the points)\n');

% 그림 — 해가 없는 구간은 NaN 으로 끊는다. qp 는 풀린 구간에서 wls16 과
% 겹치므로 굵게 그려 테두리로 보이게 한다
% the figure: stretches with no solution are broken with NaN. Where qp does
% solve it coincides with wls16, so it is drawn thick and the overlap shows
fig = figure('Color','w','Position',[60 60 820 560]);
cl = lines(nm);
lw = 1.5*ones(1,nm);  lw(strcmp(mth,'qp')) = 3.5;
subplot(2,1,1); hold on; grid on
hl = gobjects(1, nm+1);
for a = 1:nm
    d = D1(a,:);  d(EF(a,:) <= 0) = NaN;
    hl(a) = plot(ts, d, 'LineWidth',lw(a),'Color',cl(a,:));
end
yline( amax,'k--','LineWidth',1.2);
yline(-amax,'k--','LineWidth',1.2);
iq  = find(strcmp(mth,'qp'));
bad = ts(EF(iq,:) <= 0);
hl(nm+1) = plot(bad, -99*ones(size(bad)), 's', 'MarkerSize',3, ...
                'MarkerFaceColor',[.75 0 0], 'MarkerEdgeColor','none');
ylim([-105 100]);
ylabel('\delta_1  [deg]');
legend(hl, [cellstr(mth), {'qp: no solution'}], ...
       'Location','eastoutside','FontSize',8);
title(sprintf('Servo angle of unit 1 — the dashed lines are the %.0f deg limit', amax));
subplot(2,1,2); hold on; grid on
for a = 1:nm
    e = ER(a,:);  e(EF(a,:) <= 0) = NaN;
    plot(ts, e, 'LineWidth',lw(a),'Color',cl(a,:));
end
ylabel('|| \tau_{achieved} - \tau_{demanded} ||  [N]');  xlabel('t  [s]');
legend(mth,'Location','eastoutside','FontSize',8);
title('What each law pays for staying inside the limit');
savepng(fig, fullfile(here, 'img', 'W07_alloc_limits.png'));

end

%% (7-11) 한 번 푸는 데 걸리는 시간 / the time one solve takes ----------------
if any(strcmp(SEC(:,1), '7-11'))

ts     = linspace(0, 20, 101);
tau    = [100*sin(0.5*ts); 60*cos(0.3*ts); 30*sin(0.7*ts)];
mth    = ["pinv" "wpinv" "clip" "qp" "wls" "wls16" "fmincon"];
budget = 20000;                            % 50 Hz = 20 ms = 20000 us

for a = 1:numel(mth)                       % 첫 호출은 느리다 — 미리 한 번 돌린다
    W07_alloc(B, tau(:,1), char(mth(a)), P);   % warm-up: the first call is slow
end

fprintf('\n=== 7-11  the time one solve takes ===\n');
fprintf('%d demands allocated one after another.  the 50 Hz budget is %d us\n\n', ...
        numel(ts), budget);
fprintf('  method       QPs   mean [us]   max [us]   x pinv   budget used [%%]\n');

base = NaN;
for a = 1:numel(mth)
    e = zeros(1, numel(ts));  nq = 0;
    for k = 1:numel(ts)
        c = tic;  [~, in] = W07_alloc(B, tau(:,k), char(mth(a)), P);  e(k) = toc(c);
        nq = in.ntried;
    end
    mu = 1e6*mean(e);  mx = 1e6*max(e);
    if a == 1, base = mu; end
    fprintf('  %-10s %5d %11.1f %10.1f %8.0f %17.2f\n', ...
            mth(a), nq, mu, mx, mu/base, 100*mu/budget);
end

% 닫힌형이 빠른 이유 — B 가 상수이므로 8x3 행렬을 한 번만 만들면 된다
% why the closed form is fast: B is constant, so the 8x3 matrix is built once
Wi = P.W \ eye(8);
Kw = Wi * B.' / (B*Wi*B.');
e  = zeros(1, numel(ts));
fk = zeros(8,1);
for k = 1:numel(ts), c = tic; fk = Kw*tau(:,k); e(k) = toc(c); end
fprintf('\n  with one 8x3 matrix prepared in advance : %.2f us  (24 multiplies)\n', ...
        1e6*mean(e));
fprintf('  distance between Kw*tau and wpinv       : %.2e N\n', ...
        norm(fk - W07_alloc(B, tau(:,end), 'wpinv', P)));

end

%% (7-12) 한계가 둘이다 / there are two limits -------------------------------
if any(strcmp(SEC(:,1), '7-12'))

% |n| <= n_max 는 T = k n|n| 을 지나 추력 한계가 된다. 전진과 후진의 k 가
% 다르므로 한계의 높이도 둘이다
% |n| <= n_max becomes a thrust limit through T = k n|n|; k differs ahead and
% astern, so the two limits have different heights
fprintf('\n=== 7-12  two limits: the servo angle and the shaft speed ===\n\n');
fprintf('  the shaft speed limits are n_max = %+8.2f and n_min = %+8.2f rad/s\n', ...
        cfg.n_max, cfg.n_min);
fprintf('  through T = k n|n| those become thrust limits\n');
fprintf('      ahead   T <= k_pos n_max^2 = %.3f * %.2f^2 = %8.3f N\n', ...
        cfg.k_pos, cfg.n_max, P.T_pos);
fprintf('      astern  T <= k_neg n_min^2 = %.3f * %.2f^2 = %8.3f N\n', ...
        cfg.k_neg, abs(cfg.n_min), P.T_neg);
fprintf('  the astern limit is %.0f%% of the ahead limit, and that is what binds\n', ...
        100*P.T_neg/P.T_pos);
fprintf('  at delta = 0 the hull can therefore make at most\n');
fprintf('      X = 2 * %.2f + 2 * %.2f = %.2f N\n', ...
        P.T_pos, P.T_neg, 2*P.T_pos + 2*P.T_neg);

laws = ["wpinv" "clip" "wls16" "wls16cap"];

% 표 (1) 하나의 요구를 끝까지 / table 1: one demand, all the way through
tau1 = [300; 0; 0];
fprintf('\n  (1) one demand followed through the chain,  tau = [%.0f N, %.0f N, %.0f N m]\n\n', tau1);
fprintf('      pure surge, so units 1-2 push forward and units 3-4 must push astern\n');
fprintf('      the astern cap is the smaller one, and that is what binds\n\n');
fprintf('    %-9s %9s %9s %10s %7s %7s %12s\n', 'law', 'T fwd', 'T astern', ...
        'worst n', 'n clip', 'd clip', '|tau err|');
fprintf('    %-9s %9s %9s %10s %7s %7s %12s\n', '', '[N]', '[N]', ...
        '[rad/s]', '[units]', '[units]', '[N]');
fprintf('    %s\n', repmat('-', 1, 70));
for a = 1:numel(laws)
    R  = chain(B, cfg, V, P, tau1, char(laws(a)));
    Tf = max([R.T(R.T >= 0); 0]);
    Tr = min([R.T(R.T <  0); 0]);
    [~, iw] = max(abs(R.n_cmd));
    fprintf('    %-9s %9.2f %9.2f %10.1f %7d %7d %12.3f\n', laws(a), Tf, Tr, ...
            R.n_cmd(iw), sum(R.sat_n), sum(R.sat_d), norm(R.cmd - R.act));
end
fprintf('    %s\n', repmat('-', 1, 70));
fprintf('    the caps are %+7.2f N ahead and %+7.2f N astern\n', P.T_pos, -P.T_neg);

% 표 (2) 요구 궤적 하나에 전부 / table 2: the same laws over a trajectory
ts = linspace(0, 20, 201);
TC = [320*sin(0.5*ts); 60*cos(0.3*ts); 30*sin(0.7*ts)];
RR = cell(1, numel(laws));
fprintf('\n  (2) tau = [320 sin0.5t ; 60 cos0.3t ; 30 sin0.7t],  t = 0..20 s, %d points\n\n', numel(ts));
fprintf('    %-9s %9s %10s %10s %12s %12s %7s\n', 'law', 'max|d|', 'servo lim', ...
        'rpm lim', 'mean |err|', 'max |err|', 'no sol');
fprintf('    %-9s %9s %10s %10s %12s %12s %7s\n', '', '[deg]', '[% of t]', ...
        '[% of t]', '[N]', '[N]', '[pts]');
fprintf('    %s\n', repmat('-', 1, 75));
for a = 1:numel(laws)
    R = chain(B, cfg, V, P, TC, char(laws(a)));
    R.t = ts;  RR{a} = R;

    % 해가 없는 점은 통계에서 뺀다 / infeasible points are kept out
    ok = R.exit > 0;
    e  = vecnorm(R.cmd(:,ok) - R.act(:,ok));
    d  = R.d_cmd(:,ok);
    fprintf('    %-9s %9.2f %10.1f %10.1f %12.3f %12.3f %7d\n', laws(a), ...
            max(abs(rad2deg(d(:)))), 100*mean(any(R.sat_d(:,ok), 1)), ...
            100*mean(any(R.sat_n(:,ok), 1)), mean(e), max(e), sum(~ok));
end
fprintf('    %s\n', repmat('-', 1, 75));
fprintf('    the error is measured out of the motion model, not out of the allocator\n');
fprintf('    every statistic is taken over the points whose exitflag is positive\n');

% 표 (3) 새 법칙의 값 / table 3: what the new law costs in time.
%   §7-11 의 표에는 'wls16cap' 이 없다 — 그 절이 돌 때 없던 법칙이다. 캡 행이
%   단위마다 셋씩 더 붙으므로 **시간을 다시 잰다**
%   The 7-11 table has no 'wls16cap': it did not exist when that section ran.
%   The cap adds rows per unit, so the time is measured again rather than assumed
fprintf('\n  (3) allocation time over the same %d demands,  50 Hz budget = 20000 us\n\n', numel(ts));
fprintf('    %-9s %7s %11s %11s %16s\n', 'law', 'QPs', 'mean [us]', ...
        'max [us]', 'budget used [%]');
fprintf('    %s\n', repmat('-', 1, 58));
nq = struct('wpinv',0, 'clip',0, 'wls16',16, 'wls16cap',16);
for a = 1:numel(laws)
    lw = char(laws(a));
    el = zeros(1, numel(ts));
    for k = 1:numel(ts)
        c = tic;  W07_alloc(B, TC(:,k), lw, P);  el(k) = toc(c);
    end
    fprintf('    %-9s %7d %11.1f %11.1f %16.2f\n', lw, nq.(lw), ...
            1e6*mean(el), 1e6*max(el), 100*mean(el)/0.02);
end
fprintf('    %s\n', repmat('-', 1, 58));
fprintf('    the cap adds %d rows per unit, so wls16cap is wls16 plus that\n', P.n_chord);

% 그림 ① 요구한 힘과 받은 힘 / figure 1: demanded against received.
%   법칙 둘이 같은 답을 내는 일이 있다 (wpinv 와 clip). 먼저 그리는 것을 굵게
%   해서 겹친 것이 테두리로 보이게 한다
%   Two laws can give the same answer, so earlier ones are drawn thicker and
%   the overlap shows as a halo
nL  = numel(RR);
cl  = lines(nL);
lwv = linspace(3.0, 1.2, nL);
lbl = {'X  [N]', 'Y  [N]', 'N  [N m]'};
fig = figure('Color','w','Position',[60 60 860 620]);
for r = 1:3
    subplot(3,1,r); hold on; grid on
    % `h` 라고 쓰지 않는다 — 모델의 적분 간격이 그 이름을 쓴다
    % not named `h`: the model's step size already owns that name
    hp = gobjects(1, nL+1);
    for a = 1:nL
        y = RR{a}.act(r,:);  y(RR{a}.exit <= 0) = NaN;
        hp(a+1) = plot(ts, y, 'LineWidth', lwv(a), 'Color', cl(a,:));
    end
    % 요구는 맨 위에 그린다 — 맞춘 법칙이 가리지 않도록
    % the demand is drawn last, so a law that matches it cannot hide it
    hp(1) = plot(ts, RR{1}.cmd(r,:), 'k--', 'LineWidth', 1.4);
    ylabel(lbl{r});
    if r == 1
        nmv = cellfun(@(R) R.method, RR, 'UniformOutput', false);
        legend(hp, [{'demanded by the controller'}, nmv], ...
               'Location','eastoutside','FontSize',8);
        title('What the controller asked for, and what the motion model produced');
    end
end
xlabel('t  [s]');
savepng(fig, fullfile(here, 'img', 'W07_chain_tau.png'));

% 그림 ② 두 포화 / figure 2: the two saturations
fig = figure('Color','w','Position',[60 60 860 620]);
nmv = cellfun(@(R) R.method, RR, 'UniformOutput', false);
subplot(2,1,1); hold on; grid on
for a = 1:nL
    y = RR{a}.n_cmd(3,:);  y(RR{a}.exit <= 0) = NaN;
    plot(ts, y, 'LineWidth', lwv(a), 'Color', cl(a,:));
end
yline(cfg.n_max, 'k--', 'LineWidth', 1.2);
yline(cfg.n_min, 'k--', 'LineWidth', 1.2);
text(ts(end), cfg.n_max, '  n_{max}', 'FontSize', 8, 'VerticalAlignment','bottom');
text(ts(end), cfg.n_min, '  n_{min}', 'FontSize', 8, 'VerticalAlignment','top');
ylabel('n_3  [rad/s]');
legend(nmv, 'Location','eastoutside','FontSize',8);
title(sprintf(['Shaft speed demanded of unit 3 — the limits are n_{max} = %.1f and ' ...
               'n_{min} = %.1f rad/s'], cfg.n_max, cfg.n_min));
subplot(2,1,2); hold on; grid on
for a = 1:nL
    y = rad2deg(RR{a}.d_cmd(3,:));  y(RR{a}.exit <= 0) = NaN;
    plot(ts, y, 'LineWidth', lwv(a), 'Color', cl(a,:));
end
am = rad2deg(cfg.alpha_max(1));
yline( am, 'k--', 'LineWidth', 1.2);
yline(-am, 'k--', 'LineWidth', 1.2);
ylabel('\delta_3  [deg]');  xlabel('t  [s]');
legend(nmv, 'Location','eastoutside','FontSize',8);
title(sprintf('Servo angle demanded of unit 3 — the limit is %.0f deg', am));
savepng(fig, fullfile(here, 'img', 'W07_chain_sat.png'));

end

%% (7-13) 법칙 넷을 모델 하나에 / the four laws inside one model --------------
if any(strcmp(SEC(:,1), '7-13'))

assert(~isempty(LAWS), 'W07:noLaw', 'every line of LAWS is commented out');
mdl = 'W07_alloc_chain';
assert(isfile(fullfile(here, [mdl '.slx'])), 'W07:noModel', ...
       '%s.slx is missing -- run W07_2_build_alloc first', mdl);

fprintf('\n=== 7-13  the four laws inside one model ===\n');
fprintf('the demand is held at tau_cmd = [%.0f %.0f %.0f] for the whole run\n', V.tau_cmd);
fprintf('one Constant, `law`, picks the law. the .slx is the same for all four\n');

tau_cmd = V.tau_cmd;        % 모델의 Constant 가 읽는다 / read by the model Constant

% 돌리는 동안만 배치 깃발을 세운다 — 실시간 화면이 뜨지 않게 한다.
% 그림과 표는 StopFcn 의 `W07_plot_ca` 가 법칙마다 하나씩 낸다
% the batch flag is raised only while the loop runs, so the live view stays off.
% the table and the figure come from W07_plot_ca, the model's StopFcn
W07batch = true;  %#ok<NASGU>
for a = 1:size(LAWS, 1)
    law = LAWS{a,1};
    fprintf('\n  law %d  %s\n', law, LAWS{a,2});
    sim(mdl);
end
clear W07batch

% 마지막에 고른 법칙을 작업공간에 남긴다 — 모델을 열고 Run 을 누르면 이것이
% 다시 돈다. 다른 법칙은 `law` 를 바꾸고 Run 을 누르면 된다
% the law chosen last is left on the workspace: opening the model and pressing
% Run repeats it. For another law, change `law` and press Run
fprintf('\n  `law` = %d and `tau_cmd` are on the workspace.\n', law);
fprintf('  open %s.slx and press Run to repeat that law, or change `law` first.\n', mdl);

end

fprintf('\nW07 control allocation -- done\n\n');

% ========================================================================= %
% 이 파일 안에서만 쓰는 보조 함수 둘 / the two helpers used only in this file
% ========================================================================= %
function H = hw(B, f, cfg)
%HW  배분된 여덟 성분을 하드웨어가 받는 여덟 숫자로 (§7-8 유도 1~4행).
%    The eight allocated components, turned into the eight numbers the hardware
%    receives (7-8, derivation lines 1 to 4).
%
%    두 한계가 서로 다르게 작용한다 / the two limits act differently
%      각 한계  |delta| <= alpha_max 는 **방향**을 바꾼다 — 배분 안에서 푼다
%        the angle limit changes the DIRECTION, so it is solved inside the
%        allocation itself
%      추력 한계 |T| <= k n_max^2 는 **크기**만 바꾼다 — f 를 한 번 곱해 끝낸다
%        (B 가 선형이므로 rho*f 는 rho*tau 를 낸다)
%        the thrust cap changes only the MAGNITUDE, so one scaling settles it
T  = zeros(1,4);  de = zeros(1,4);
for i = 1:4
    fx = f(2*i-1);  fy = f(2*i);
    s  = sign(fx);  if s == 0, s = 1; end
    T(i)  = s * hypot(fx, fy);
    de(i) = atan2(s*fy, s*fx);
end
H.hit = abs(abs(de) - cfg.alpha_max(:)') < 1e-6;

% 추력 한계 — 전진과 후진이 다르다 (k_pos ~= k_neg)
% the thrust cap: ahead and astern are not the same, because k_pos ~= k_neg
Tlim  = (T >= 0) .* (cfg.k_pos*cfg.n_max^2) + (T < 0) .* (cfg.k_neg*cfg.n_min^2);
H.rho = min([1, Tlim ./ max(abs(T), eps)]);

Tr = H.rho * T;
k  = (Tr >= 0)*cfg.k_pos + (Tr < 0)*cfg.k_neg;
H.T     = Tr;
H.delta = de;
H.n     = sign(Tr) .* sqrt(abs(Tr) ./ k);
H.tau   = B * (H.rho * f(:));
end

% ========================================================================= %
function R = chain(B, cfg, V, P, tau_cmd, method)
%CHAIN  제어기 → 배분 → 하드웨어 → 운동모델. 요구한 힘과 **배가 실제로 받은
%       힘**을 나란히 돌려준다 (§7-12 유도 9~10행).
%       Controller to allocator to hardware to motion model. Returns the demand
%       and the force the hull ACTUALLY received, side by side (7-12, lines 9-10).
%
%  `otter_tilt4` 는 받은 n 과 delta 를 스스로 깎는다. 그래서 배분기가 낸 답이
%  한계를 넘으면 배는 요구와 다른 힘을 받고, 그 차이는 배분기의 장부에 적히지
%  않는다. 같은 상태에서 추진기를 켜고 한 번, n = 0 으로 한 번 불러 그 차이에
%  질량행렬을 곱하면 추진기가 만든 tau 다 — §7-2 가 쓴 방법과 같다.
%      tau = M (xdot|_on - xdot|_off)
%  otter_tilt4 clips the n and delta it is given, so an answer outside the limits
%  reaches the hull as a DIFFERENT force and nothing in the allocator's own
%  bookkeeping shows it. It is called twice in the same state -- thrusters on,
%  then n = 0 -- and the difference times the mass matrix is the thruster tau,
%  which is the method 7-2 already used.
K  = size(tau_cmd, 2);
Mm = otter_M(V.mp, V.rp);
x0 = V.x0;

R.t      = [];
R.method = method;
R.cmd    = tau_cmd;
R.act    = zeros(3, K);
R.n_cmd  = zeros(4, K);   R.n_act = zeros(4, K);
R.d_cmd  = zeros(4, K);   R.d_act = zeros(4, K);
R.T      = zeros(4, K);   R.exit  = zeros(1, K);
R.sat_n  = false(4, K);   R.sat_d = false(4, K);

for k = 1:K
    % ① 배분 / allocate
    [f, in] = W07_alloc(B, tau_cmd(:,k), method, P);
    R.exit(k) = in.exit;

    % ② 크기와 각 / magnitude and angle, per unit
    fx = f(1:2:end);  fy = f(2:2:end);
    s  = sign(fx);  s(s == 0) = 1;
    T  = s .* hypot(fx, fy);
    d  = atan2(s.*fy, s.*fx);

    % ③ 추력곡선을 거꾸로 / the thrust curve, inverted
    kk = cfg.k_pos*(T >= 0) + cfg.k_neg*(T < 0);
    n  = sign(T) .* sqrt(abs(T) ./ kk);

    % ④ 하드웨어가 깎는 자리 — 운동모델이 안에서 하는 것과 같은 깎기
    %    the same clip the motion model applies inside itself
    n_a = min(max(n, cfg.n_min), cfg.n_max);
    d_a = min(max(d, -cfg.alpha_max(:)), cfg.alpha_max(:));

    % ⑤ 운동모델에서 실제 tau 를 잰다. 깎지 않은 명령을 그대로 넘긴다 —
    %    깎는 것은 플랜트의 일이다 / clipping is the plant's job
    xd_on  = otter_tilt4(x0, n,         d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    xd_off = otter_tilt4(x0, [0 0 0 0], d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    tau    = Mm * (xd_on(1:6) - xd_off(1:6));

    R.act(:,k)   = tau([1 2 6]);
    R.T(:,k)     = T;
    R.n_cmd(:,k) = n;      R.n_act(:,k) = n_a;
    R.d_cmd(:,k) = d;      R.d_act(:,k) = d_a;
    R.sat_n(:,k) = abs(n - n_a) > 1e-9;
    R.sat_d(:,k) = abs(d - d_a) > 1e-9;
end
end

% ========================================================================= %
function savepng(fig, p)
%SAVEPNG  그림 하나를 150 dpi PNG 로. `exportgraphics` 가 없으면 `print`.
%         One figure as a 150 dpi PNG, falling back to print.
try
    exportgraphics(fig, p, 'Resolution', 150);
catch
    print(fig, p, '-dpng', '-r150');
end
fprintf('\n    saved %s\n', p);
end
