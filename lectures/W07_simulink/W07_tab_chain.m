function RR = W07_tab_chain(B, cfg, V, P, laws)
%W07_TAB_CHAIN  §7-12 의 표 둘 — ① 요구 하나를 법칙마다 끝까지 따라간다
%               ② 요구 궤적 201 점에 걸어 두 한계를 넘는 비율을 센다.
%               The two tables of 7-12: one demand followed through every law,
%               then a 201-point demand swept to count how often each limit is
%               exceeded.
%
%  돌려주는 것: `W07_chain` 결과의 cell (그림이 쓴다)
%  Returns a cell of W07_chain results, for the figures.
%
%  `W07_CA(12)` 이 부른다 / called from W07_CA(12)

%% 표 (1) 하나의 요구를 끝까지 / table 1: one demand, all the way through ------
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
    R  = W07_chain(B, cfg, V, P, tau1, char(laws(a)));
    Tf = max([R.T(R.T >= 0); 0]);
    Tr = min([R.T(R.T <  0); 0]);
    [~, iw] = max(abs(R.n_cmd));
    fprintf('    %-9s %9.2f %9.2f %10.1f %7d %7d %12.3f\n', laws(a), Tf, Tr, ...
            R.n_cmd(iw), sum(R.sat_n), sum(R.sat_d), norm(R.cmd - R.act));
end
fprintf('    %s\n', repmat('-', 1, 70));
fprintf('    the caps are %+7.2f N ahead and %+7.2f N astern\n', ...
        P.T_pos, -P.T_neg);

%% 표 (2) 요구 궤적 하나에 전부 / table 2: the same laws over a trajectory -----
t  = linspace(0, 20, 201);
TC = [320*sin(0.5*t); 60*cos(0.3*t); 30*sin(0.7*t)];
RR = cell(1, numel(laws));
fprintf('\n  (2) tau = [320 sin0.5t ; 60 cos0.3t ; 30 sin0.7t],  t = 0..20 s, %d points\n\n', numel(t));
fprintf('    %-9s %9s %10s %10s %12s %12s %7s\n', 'law', 'max|d|', 'servo lim', ...
        'rpm lim', 'mean |err|', 'max |err|', 'no sol');
fprintf('    %-9s %9s %10s %10s %12s %12s %7s\n', '', '[deg]', '[% of t]', ...
        '[% of t]', '[N]', '[N]', '[pts]');
fprintf('    %s\n', repmat('-', 1, 75));
for a = 1:numel(laws)
    R = W07_chain(B, cfg, V, P, TC, char(laws(a)));
    R.t = t;  RR{a} = R;

    % 해가 없는 점은 통계에서 뺀다. `quadprog` 은 실행 불가능해도 마지막 반복값을
    % 숫자로 돌려주므로, exitflag 를 읽지 않으면 그 값이 평균에 섞인다
    % Infeasible points are kept out of the statistics. quadprog returns its last
    % iterate as a plausible number even when there is no solution, so without
    % reading the exitflag that value would enter the mean.
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

%% 표 (3) 새 법칙의 값 / table 3: what the new law costs in time -------------
%  §7-11 의 표에는 'wls16cap' 이 없다 — 그 절이 돌 때 없던 법칙이다. 캡 행이
%  단위마다 M 개 더 붙으므로 **시간을 다시 잰다.** 지침: 수치는 실행 결과다.
%  The 7-11 table has no 'wls16cap': it did not exist when that section ran.
%  The cap adds M rows per unit, so the time is measured again rather than
%  assumed. Allocation only is timed here -- the motion model is not in the
%  loop, so this is comparable with the 7-11 figures.
fprintf('\n  (3) allocation time over the same %d demands,  50 Hz budget = 20000 us\n\n', numel(t));
fprintf('    %-9s %7s %11s %11s %16s\n', 'law', 'QPs', 'mean [us]', ...
        'max [us]', 'budget used [%]');
fprintf('    %s\n', repmat('-', 1, 58));
nq = struct('wpinv',0, 'clip',0, 'wls16',16, 'wls16cap',16);
for a = 1:numel(laws)
    lw = char(laws(a));
    el = zeros(1, numel(t));
    for k = 1:numel(t)
        tic;  W07_alloc(B, TC(:,k), lw, P);  el(k) = toc;
    end
    fprintf('    %-9s %7d %11.1f %11.1f %16.2f\n', lw, nq.(lw), ...
            1e6*mean(el), 1e6*max(el), 100*mean(el)/0.02);
end
fprintf('    %s\n', repmat('-', 1, 58));
fprintf('    the cap adds %d rows per unit, so wls16cap is wls16 plus that\n', P.n_chord);
end
