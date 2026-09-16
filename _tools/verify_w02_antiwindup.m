function ok = verify_w02_antiwindup()
%VERIFY_W02_ANTIWINDUP  표준 블록으로 다시 만든 안티와인드업이 예전 MATLAB
%                       Function 블록과 같은 수를 내는지 확인한다.
%                       Check that the anti-windup rebuilt from standard blocks
%                       reproduces the MATLAB Function block it replaced.
%
%      ok = verify_w02_antiwindup
%
%  ── 왜 이 파일이 있는가 / why this file exists ──────────────────────────
%  2026-09-16 에 Surge controller 안의 anti-windup 을 MATLAB Function 블록
%  하나에서 Sum·Product·Switch 로 풀어 썼다. 목적은 §2-6 이 설명하는 세 방식의
%  차이를 도면 위에 드러내는 것이었고, 동작을 바꾸려던 것이 아니다. 강의노트의
%  모든 수치가 예전 블록으로 측정된 것이므로, 바뀌지 않았음을 보여야 한다.
%
%  On 2026-09-16 the anti-windup inside the Surge controller was rebuilt from
%  sums, products and switches in place of a single MATLAB Function block. The
%  intention was to put the difference between the three schemes of §2-6 on
%  the canvas, not to change any behaviour. Every measurement in the lecture
%  notes was taken with the block that was removed, so it must be shown that
%  nothing moved.
%
%  ── 대조하는 값 / the reference values ─────────────────────────────────
%  아래 표는 강의노트 §F 에 실려 있는 값이며, 교체 이전의 모델이 낸 것이다.
%  여기서 다시 재어 같은 값이 나오는지 본다.
%  The table below is the one printed in section F of the lecture notes,
%  produced by the model as it stood before the replacement.

here = fileparts(mfilename('fullpath'));
addpath(here, fullfile(fileparts(here), 'lectures', 'W02_simulink'));
mss_path();

%           방식 / scheme        peak I [N]  peak X_cmd [N]  recovery [s]
REF = { 'none',             0,   3438.2,      3480.0,         13.980
        'clamping',         1,    197.8,       355.9,          3.400
        'back-calculation', 2,    213.1,       356.2,          3.440 };

%  강의노트가 소수 한 자리까지 싣고 있으므로 그 자리까지 맞으면 통과로 본다.
%  힘은 0.05 N, 시간은 0.0005 s 이내여야 한다.
%  The notes carry one decimal place for the forces and three for the time,
%  so agreement is required to half a unit in the last printed digit.
TOL_N = 0.05;   TOL_S = 0.0005;

V = W02_vars;
c = W02_cols;
V.u_d1 = 3.5;   V.u_d2 = 1.5;   V.t_up = 5;   V.t_dn = 40;   V.T_final = 90;

fprintf('\n  W02 §2-6 — 안티와인드업 회귀 검증 / anti-windup regression\n');
fprintf('  표준 블록으로 다시 만든 것이 예전 MATLAB Function 과 같은가\n');
fprintf('  does the block-built version match the MATLAB Function it replaced\n\n');
fprintf('    %-18s %12s %12s %12s %12s %12s %12s\n', ...
        'scheme', 'peak I ref', 'peak I now', 'peak X ref', 'peak X now', ...
        'rec ref', 'rec now');
fprintf('    %s\n', repmat('-', 1, 94));

ok = true;
for i = 1:size(REF,1)
    R  = run_sim('W02_surge_control', V, 'aw_mode', REF{i,2});
    pI = max(R.y(:, c.I));
    pX = max(R.y(:, c.X_cmd));
    rc = local_recovery(R.t, R.y(:, c.u), V.u_d2, V.t_dn);

    good = abs(pI - REF{i,3}) < TOL_N && abs(pX - REF{i,4}) < TOL_N && ...
           abs(rc - REF{i,5}) < TOL_S;
    ok   = ok && good;
    if good, mark = ''; else, mark = '  <-- 불일치 MISMATCH'; end
    fprintf('    %-18s %12.1f %12.1f %12.1f %12.1f %12.3f %12.3f%s\n', ...
            REF{i,1}, REF{i,3}, pI, REF{i,4}, pX, REF{i,5}, rc, mark);
end

%% ---- Ki = 0 일 때 역계산 항이 차단되는가 -------------------------------
%  적분기가 없는데 역계산 항이 살아 있으면, 존재하지 않는 상태를 충전한다.
%  예전 블록은 Ki ~= 0 으로 막았고, 새 도면에서는 'Ki live' 가 그 일을 한다.
%  With no integrator there is nothing to protect, and a live back-calculation
%  term would charge a state that is not there. The old block guarded this with
%  a test on Ki; on the new canvas the guard is the block named 'Ki live'.
R = run_sim('W02_surge_control', V, 'Ki', 0, 'aw_mode', 2);
Imax = max(abs(R.y(:, c.I)));
fprintf('\n    Ki = 0, aw_mode = 2 :  max|I| = %.3e   (0 이어야 한다 / must be zero)\n', Imax);
ok = ok && Imax < 1e-9;

%% ---- 클램핑의 얼어붙는 조건을 블록 논리 그대로 확인한다 ----------------
%  도면의 두 조건은  |sat| > 1e-9  과  e*sat > 0  이다. 예전 코드는 뒤의 것을
%  sign(e) == sign(sat) 으로 썼다. 두 표현이 같은 값을 주는지 격자로 확인한다.
%  The canvas tests |sat| > 1e-9 and e*sat > 0. The code it replaced wrote the
%  second as sign(e) == sign(sat). The two are checked against each other on a
%  grid that includes the zeros and the tolerance boundary.
g = [-3 -1 -1e-9 -1e-12 0 1e-12 1e-9 1 3];
agree = true;
for a = g
    for b = g
        oldF = abs(b) > 1e-9 && sign(a) == sign(b);
        newF = (abs(b) > 1e-9) && (a*b > 0);
        agree = agree && (oldF == newF);
    end
end
if agree, verdict = '일치한다 / agree'; else, verdict = '어긋난다 / DISAGREE'; end
fprintf('    클램핑 조건 %d 가지 조합에서 두 표현이 %s\n', numel(g)^2, verdict);
ok = ok && agree;

fprintf('\n');
if ok
    fprintf('  ALL CHECKS PASSED — 블록으로 바꾸어도 수치가 같다.\n\n');
else
    fprintf('  ***** 불일치 있음. 블록 배선을 다시 본다. *****\n\n');
end
end

% -------------------------------------------------------------------------
function tr = local_recovery(t, y, yf, t0)
%  §F 가 쓰는 정의 그대로 : t0 이후, 2 퍼센트 띠를 마지막으로 벗어난 시각.
%  The definition section F uses: after t0, the last instant outside a 2 per
%  cent band on the new setpoint.
k = t >= t0;
t = t(k) - t0;  y = y(k);
out = find(abs(y - yf) > 0.02*abs(yf), 1, 'last');
if isempty(out), tr = 0; else, tr = t(min(out+1, numel(t))); end
end
