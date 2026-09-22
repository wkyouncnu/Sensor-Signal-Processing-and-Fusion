function ok = verify_w05_guidance()
%VERIFY_W05_GUIDANCE  5주차(모델 없는 유도 튜닝)가 싣는 수와 식을 독립적으로 다시 확인한다.
%                     Recheck the numbers and equations of Week 5 (model-free guidance tuning).
%
%   검사 / checks
%     1  W05_vars 와 W05_0_setup 의 값이 같다 / the two parameter files agree
%     2  LOS 는 작은 오차에서 P 제어기다: |y_e| <= 0.2 Delta 이면 atan(y_e/Delta) 와 y_e/Delta 의
%        차이가 1.4 % 안 (§5-3) / LOS is a P controller for small errors
%     3  조류 속 LOS 의 남는 오차 = Delta tan(유지한 선수각) — 시뮬레이션으로 (§5-5)
%        the error LOS leaves in a current equals Delta tan(held heading), by simulation
%     4  ILOS 는 그 오차를 없앤다: 마지막 100 s 평균 < 0.05 m (§5-5)
%        ILOS removes it: mean over the last 100 s below 0.05 m
%     5  경로 좌표로의 회전이 MSS crosstrackWpt.m 과 같은 y_e 를 준다
%        the rotation into path coordinates gives the same y_e as MSS crosstrackWpt.m

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W05_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w05_guidance\n\n');

V = W05_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(S.(f{1}), V.(f{1})), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W05_vars = W05_0_setup', isempty(bad), strjoin(bad, ', '));

y = linspace(-0.2, 0.2, 41);                     % y_e / Delta
e2 = max(abs(atan(y) - y) ./ max(abs(y), eps));
ok = report(ok, '2 atan(y/D) ~ y/D within 1.4 % for |y| <= 0.2 D', e2 < 0.014, sprintf('%.2f %%', 100*e2));

L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400, 'V_c', 0.3};
for n = {'W05_D_LOS','W05_F_ILOS'}
    if ~isfile(fullfile(wk, [n{1} '.slx'])), W05_1_build_guidance(n{1}); end
end
R = W05_read('W05_D_LOS', L{:});
pred = V.Delta*tand(abs(R.psi(end)));
ok = report(ok, '3 LOS error = Delta tan(heading) in a current', abs(R.y_e(end) - pred) < 0.01, ...
            sprintf('%.3f m vs %.3f m', R.y_e(end), pred));
R = W05_read('W05_F_ILOS', L{:});
m4 = mean(R.y_e(R.t > 300));
ok = report(ok, '4 ILOS removes it', abs(m4) < 0.05, sprintf('%.3f m', m4));

pts = [3 4; 10 -2; 50 7; -5 5];  e5 = 0;       % [N E] 몇 점 / a few points
for i = 1:size(pts,1)
    pi_p = atan2(60 - 0, 60 - 0);
    ye = -(pts(i,1))*sin(pi_p) + (pts(i,2))*cos(pi_p);
    ye_mss = crosstrackWpt(60, 60, 0, 0, pts(i,1), pts(i,2));
    e5 = max(e5, abs(ye - ye_mss));
end
ok = report(ok, '5 y_e = MSS crosstrackWpt', e5 < 1e-12, sprintf('%.1e m', e5));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W05_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i','cfg'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-50s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
