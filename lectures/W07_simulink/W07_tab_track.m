function W07_tab_track(S, k, R, TAU, cfg, n_sway)
%W07_TAB_TRACK  표 (3). 예상한 기동과 **잰 기동**을 나란히 놓고, 세 비대칭을 적는다.
%               Table (3): the expected manoeuvre beside the measured one.
%
%   W07_tab_track(S, k, R, TAU, cfg, n_sway)
%
%     S       `W07_cases` 의 **여덟 줄 전부**
%     k       이번에 돌린 줄 번호 / the rows actually run
%     R, TAU  그 줄들의 로그와 tau, 1..numel(k) 로 센다
%
%   왜 S 를 통째로 받는가 / why the whole set comes in
%       비대칭 설명은 S1 · S5 · S6 의 숫자를 **이름으로** 가리킨다. 하나만
%       돌렸을 때도 그 문장이 서야 하므로, 고르지 않은 줄의 tau 는 `W07_tau`
%       로 그 자리에서 구한다 — 시뮬레이션이 아니라 수식이므로 공짜다.
%       The asymmetry notes name S1, S5 and S6; when those rows were not run
%       their tau comes straight from the formula, which costs nothing.
%
%   무엇을 판정하는가 / what this decides
%       힘이 맞고 배선이 맞으면, 남는 질문은 **예상한 기동이 나왔는가**다.
%       U, 크랩각, 선회각속도, 선회반경을 t = 30 s 에서 읽어 `W07_cases` 가
%       적어 둔 예상과 한 줄씩 맞춘다.
%
%   세 비대칭 / the three asymmetries
%       ① 추력 곡선 — 전진과 후진의 계수가 다르다 (k_pos != k_neg)
%       ② 선수·선미 거리 — l_f = 1.50 m, l_a = 1.00 m
%       ③ 서보 — 70 도를 지시해도 45 도까지만 간다
%
%   See also W07_V_OPENLOOP, W07_CASES, W07_TAU, W07_TAB_FORMULA, W07_TAB_REINT.

nc = numel(k);

fprintf('  (3) the motion those forces produce, scenario by scenario\n\n');
fprintf('      every value is read at t = 30 s, by when all %d have settled\n\n', nc);
fprintf('    %-4s  %-27s %8s %11s %10s %11s\n', ...
        'case', 'command', 'U [m/s]', 'crab [deg]', 'r [deg/s]', 'radius [m]');
fprintf('    %s\n', repmat('-', 1, 76));

for c = 1:nc
    r    = R{c};
    U    = hypot(r.u(end), r.v(end));
    crab = rad2deg(atan2(r.v(end), r.u(end)));
    rr   = rad2deg(r.r(end));

    if abs(r.r(end)) > 1e-4, Rad = U / abs(r.r(end)); else, Rad = Inf; end

    fprintf('    %-4s  %-27s %8.3f %11.2f %10.3f %11s\n', ...
            S{k(c),1}, S{k(c),4}, U, crab, rr, radius_str(Rad));
end
fprintf('    %s\n\n', repmat('-', 1, 76));

%  예상은 표 밖으로 — 한 줄이 칸보다 길다 / the expectation goes below the table
fprintf('      expected manoeuvre, written down before the run\n');
for c = 1:nc
    fprintf('        %-4s %s\n', S{k(c),1}, S{k(c),5});
end
fprintf('\n');

t1 = tau_of(S, cfg, 'S1');
t5 = tau_of(S, cfg, 'S5');
t6 = tau_of(S, cfg, 'S6');

fprintf('      the three asymmetries this week turns on\n');
fprintf('        thrust curve   +60 rad/s gives %+7.3f N, -60 rad/s gives %+7.3f N, so\n', ...
        cfg.k_pos*60^2, -cfg.k_neg*60^2);
fprintf('                       the pair running forward carries %.2f times the pair\n', ...
        cfg.k_pos/cfg.k_neg);
fprintf('                       running astern -- and yet S1 and S2 reach the SAME\n');
fprintf('                       %+8.3f N, because the mirrored mounting swaps which\n', t1(1));
fprintf('                       pair is the one running astern\n');
fprintf('        the stations   l_f = %.2f m forward, l_a = %.2f m aft, so S5 crabs with\n', ...
        cfg.l_f, cfg.l_a);
fprintf('                       %+8.3f N m of yaw left over, and S6 cancels that moment\n', t5(3));
fprintf('                       at n = %.3f rad/s only by letting %+8.3f N of surge\n', ...
        n_sway, t6(1));
fprintf('                       appear: no EQUAL-thrust sway inside +-%.0f deg is yaw-free\n', ...
        rad2deg(cfg.alpha_max(1)));
fprintf('        the servo      S8 asks for 70 deg and is given %.0f deg, so its row of\n', ...
        rad2deg(cfg.alpha_max(1)));
fprintf('                       table (1) is S5''s row exactly\n\n');

end

% =========================================================================
function tau = tau_of(S, cfg, tag)
%TAU_OF  이름으로 가리킨 줄의 tau. 돌렸든 안 돌렸든 수식에서 나온다.
j   = find(strcmpi(S(:,1), tag), 1);
tau = W07_tau(S(j,:), cfg);
end

% =========================================================================
function s = radius_str(Rad)
if isinf(Rad), s = 'straight'; else, s = sprintf('%.2f', Rad); end
end
