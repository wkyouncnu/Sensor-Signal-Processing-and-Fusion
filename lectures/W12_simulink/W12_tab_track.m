function W12_tab_track(C, R, TAU, cfg, n_cxl)
%W12_TAB_TRACK  표 (3). 그 힘이 만드는 운동을 t = 30 s 에서 읽고, 세 비대칭을 적는다.
%               Table (3): the motion those forces produce, and the three asymmetries.
%
%   무엇을 판정하는가 / what this decides
%       힘이 맞고 배선이 맞으면, 남는 질문은 **그 힘으로 궤적이 설명되는가**다.
%       U, 크랩각, 선회각속도, 선회반경을 t = 30 s 에서 읽는다 — 그때면 여섯이
%       모두 정상상태다.
%
%   왜 돌리지 않는가 / why nothing is simulated here
%       표 (2) 가 남긴 로그 여섯을 **다시 읽는다.** 그래서 표 셋과 그림이
%       같은 여섯 번의 운항을 가리키고, 배는 여섯 번만 돈다.
%
%   세 비대칭 / the three asymmetries
%       ① 추력 곡선 — 전진과 후진의 계수가 다르다 (k_pos != k_neg)
%       ② 선수·선미 거리 — l_f = 1.50 m, l_a = 1.00 m, 그래서 xbar = 0.25 m
%       ③ 서보 — 70 도를 지시해도 45 도까지만 간다
%
%   See also W12_V_OPENLOOP, W12_CASES, W12_TAB_FORMULA, W12_TAB_REINT.

nc = size(C, 1);

fprintf('  (3) the motion those forces produce\n\n');
fprintf('      every value is read at t = 30 s, by when all six have settled\n\n');
fprintf('    %-4s  %8s  %10s  %10s  %15s\n', ...
        'case', 'U [m/s]', 'crab [deg]', 'r [deg/s]', 'turn radius [m]');
fprintf('    %s\n', repmat('-', 1, 59));

for c = 1:nc
    r = R{c};
    U    = hypot(r.u(end), r.v(end));
    crab = rad2deg(atan2(r.v(end), r.u(end)));
    rr   = rad2deg(r.r(end));

    if abs(r.r(end)) > 1e-4, Rad = U / abs(r.r(end)); else, Rad = Inf; end

    fprintf('    %-4s  %8.3f  %10.2f  %10.3f  %15s\n', ...
            C{c,1}, U, crab, rr, radius_str(Rad));
end
fprintf('    %s\n\n', repmat('-', 1, 59));

%  "무엇을 뜻하는가" 는 표 밖으로 / the reading goes below the table, not in it
fprintf('      how each row is read\n');
for c = 1:nc
    fprintf('        %-4s %s\n', C{c,1}, reading(C{c,1}));
end
fprintf('\n');

fprintf('      the three asymmetries this week turns on\n');
fprintf('        thrust curve   +60 rad/s gives %+7.3f N, -60 rad/s gives %+7.3f N\n', ...
        cfg.k_pos*60^2, -cfg.k_neg*60^2);
fprintf('                       so V2 keeps %+7.3f N of surge it did not ask for,\n', TAU(2,1));
fprintf('                       and the astern speed that cancels +60 is %+.3f rad/s\n', n_cxl);
fprintf('        the stations   l_f = %.2f m forward, l_a = %.2f m aft, so the four\n', ...
        cfg.l_f, cfg.l_a);
fprintf('                       tilted thrusters of V3 leave %+7.3f N m of yaw on an\n', TAU(3,3));
fprintf('                       otherwise clean crab\n');
fprintf('        the servo      V6 asks for 70 deg and is given %.0f deg, so its row\n', ...
        rad2deg(cfg.alpha_max(1)));
fprintf('                       of table (1) is V3''s row exactly\n\n');

end

% =========================================================================
function s = radius_str(Rad)
if isinf(Rad), s = 'straight'; else, s = sprintf('%.2f', Rad); end
end

% =========================================================================
function s = reading(tag)
%  표의 마지막 칸. 숫자가 아니라 **그 숫자를 어떻게 읽는가**를 적는다.
switch tag
    case 'V1', s = 'pure surge, the Otter of Weeks 1 to 5';
    case 'V2', s = 'turns, but drifts ahead while turning';
    case 'V3', s = 'force at 45 deg, hull crabs at 22, and yaws: l_f is not l_a';
    case 'V4', s = 'mostly sway, surge not yet cancelled';
    case 'V5', s = 'surge cancelled by the shaft speed, yaw still there';
    case 'V6', s = 'identical to V3: the servo refused the extra 25 deg';
    otherwise, s = '';
end
end
