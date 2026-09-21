function ok = verify_w04_heading()
%VERIFY_W04_HEADING  4주차(모델 없는 선수각 튜닝)가 싣는 수와 식을 독립적으로 다시 확인한다.
%                    Recheck the numbers and equations of Week 4 (model-free heading tuning).
%
%   검사 / checks
%     1  W04_vars 와 W04_0_setup 의 값이 같다 / the two parameter files agree
%     2  N_max = 70.85 N m 을 추진기 한계에서 다시 계산 (§4-1)
%        N_max recomputed from the propeller limits (§4-1)
%     3  T1, T2 가 X_ff 와 N 을 정확히 되돌려 준다: T1 + T2 = X_ff, y_pont (T1 - T2) = N
%        the thrust split returns X_ff and N exactly
%     4  ssa: atan2(sin e, cos e) 가 MSS ssa.m 과 같다 (-340 도 -> 20 도 포함)
%        the ssa of the models equals MSS ssa.m, including -340 deg -> 20 deg
%     5  PD 만으로 선수각 오차가 0 이다 (§4-3) / PD alone leaves no heading error

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W04_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w04_heading\n\n');

V = W04_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(S.(f{1}), V.(f{1})), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W04_vars = W04_0_setup', isempty(bad), strjoin(bad, ', '));

cfg = otter_config('base');
Th = cfg.k_pos*cfg.n_max^2;  Tl = -cfg.k_neg*cfg.n_min^2;
Nm = min(2*cfg.y_pont*(Th - 30), 2*cfg.y_pont*(30 - Tl));
ok = report(ok, '2 N_max = 70.85 N m', abs(Nm - 70.85) < 0.005 && abs(V.N_max - Nm) < 1e-12, sprintf('%.4f', Nm));

N = linspace(-70, 70, 15);  X = 60;  y = cfg.y_pont;
T1 = X/2 + N/(2*y);  T2 = X/2 - N/(2*y);
e3 = max(abs([T1 + T2 - X, y*(T1 - T2) - N]));
ok = report(ok, '3 thrust split returns X_ff and N', e3 < 1e-12, sprintf('%.1e', e3));

e = deg2rad([-340 -190 -10 0 10 170 190 340 720]);
d = max(abs(atan2(sin(e), cos(e)) - ssa(e)));
ok = report(ok, '4 atan2(sin, cos) = MSS ssa', d < 1e-12 && abs(rad2deg(atan2(sin(e(1)), cos(e(1)))) - 20) < 1e-9, ...
            sprintf('%.1e', d));

if ~isfile(fullfile(wk, 'W04_E_PD.slx')), W04_1_build_heading('W04_E_PD'); end
R = W04_read('W04_E_PD');
ok = report(ok, '5 PD leaves no heading error', abs(R.psi(end) - 10) < 0.05, sprintf('%.4f deg', 10 - R.psi(end)));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W04_0_setup.m''))');
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
