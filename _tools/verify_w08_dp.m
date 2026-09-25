function ok = verify_w08_dp()
%VERIFY_W08_DP  8주차(동적 위치제어와 임무 통합)가 싣는 수와 식을 다시 확인한다.
%               Recheck the numbers and equations of Week 8.
%
%   검사 / checks
%     1  W08_vars 와 W08_0_setup 의 값이 같다 / the two parameter files agree
%     2  이 선체는 옆으로 밀 수 없다: B 의 계급이 2 이고 둘째 행이 0 이다 (§8-1)
%     3  선수각을 고정하면 자리를 지키지 못한다 — 오차가 계속 자란다 (§8-2)
%        with the heading fixed the station cannot be held
%     4  선수각을 놓아 주면 지킨다. 유지하는 힘이 항력과 같다 (§8-3)
%        with the bow free it is held, and the force equals the drag
%     5  임무는 두 규칙으로만 움직인다: 반경 안이면 유지, 시간이 차면 다음 (§8-5)
%        the mission moves by its two rules, in the right order

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W08_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w08_dp\n\n');

V = W08_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(round(S.(f{1}), 12), round(V.(f{1}), 12)), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W08_vars = W08_0_setup', isempty(bad), strjoin(bad, ', '));

B = otter_B(otter_config('base'));
ok = report(ok, '2 the sway row of B is zero, rank 2', rank(B) == 2 && all(B(2,:) == 0), ...
            sprintf('rank %d, sway row [%g %g]', rank(B), B(2,1), B(2,2)));

for n = {'W08_C_fixed','W08_D_weathervane','W08_F_mission'}
    if ~isfile(fullfile(wk, [n{1} '.slx'])), W08_1_build_dp(n{1}); end
end
R = W08_read('W08_C_fixed');
ok = report(ok, '3 a fixed heading cannot hold the station', ...
            R.e(end) > 40 && max(abs(R.X)) < 1, ...
            sprintf('|e| = %.1f m after %.0f s, |X| <= %.2f N', R.e(end), R.t(end), max(abs(R.X))));

R = W08_read('W08_D_weathervane');
j = R.t > 150;  X_drag = R.V.V_c/0.012894;
ok = report(ok, '4 the bow set free holds it, with the drag force', ...
            mean(R.e(j)) < 0.5 && abs(mean(R.X(j)) - X_drag) < 2, ...
            sprintf('|e| %.3f m, X %.1f N against a drag of %.1f N', mean(R.e(j)), mean(R.X(j)), X_drag));

R = W08_read('W08_F_mission', 'T_final', 400);
ch = find(diff(R.mode) ~= 0) + 1;
seq = R.mode(ch)';
holds = zeros(1,0);
for k = 1:numel(R.V.WP_N)
    j = R.mode == 2 & R.N_d == R.V.WP_N(k) & R.E_d == R.V.WP_E(k);
    if any(j), holds(end+1) = sum(j)*R.V.h; end %#ok<AGROW>
end
ok = report(ok, '5 the mission runs hold-transit-hold-...-done', ...
            isequal(seq, [1 2 1 2 3]) && all(abs(holds - R.V.T_hold) < 0.5), ...
            sprintf('modes %s, holds %s s', mat2str(seq), mat2str(round(holds,1))));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W08_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i','cfg'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-44s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
