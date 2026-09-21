function ok = verify_w03_speed()
%VERIFY_W03_SPEED  3주차(모델 없는 속도 튜닝)가 싣는 수를 독립적으로 다시 확인한다.
%                  Recheck the numbers of Week 3 (model-free speed tuning) independently.
%
%   ok = verify_w03_speed()
%
%   검사 / checks
%     1  W03_vars 와 W03_0_setup 의 값이 같다 / the two parameter files agree
%     2  추력 한계 [-133.42, 239.36] N 을 otter_config 에서 다시 계산 (§3-1)
%        the thrust limits recomputed from otter_config (§3-1)
%     3  열린 루프에서 잰 속도/힘 0.01289 가 1주차의 K_u = 1/X_u 와 같다 (§3-2)
%        the measured speed per newton equals Week 1's K_u = 1/X_u (§3-2)
%     4  적분이 멈춘 힘 116.3 N 이 1.5 m/s 를 1/K_u 로 나눈 값과 같다 (§3-3)
%        the integral's final force equals 1.5 m/s divided by K_u (§3-3)
%     5  '축 회전수' Fcn 식이 T = k n|n| 의 역함수이다 (앞·뒤 방향 모두)
%        the shaft-speed Fcn inverts T = k n|n|, forward and backward

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W03_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w03_speed\n\n');

%% 1
V = W03_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(S.(f{1}), V.(f{1})), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W03_vars = W03_0_setup', isempty(bad), strjoin(bad, ', '));

%% 2
cfg = otter_config('base');
lim = [-2*cfg.k_neg*cfg.n_min^2, 2*cfg.k_pos*cfg.n_max^2];
ok = report(ok, '2 thrust limits [-133.42, 239.36] N', all(abs(lim - [-133.42 239.36]) < 0.005), ...
            sprintf('[%.2f, %.2f]', lim));

%% 3
Xu = 24.4*9.81/(6*0.5144);  Ku = 1/Xu;                  % Week 1 §1-11
if ~isfile(fullfile(wk, 'W03_C_open_loop.slx')), W03_1_build_speed('W03_C_open_loop'); end
R = W03_read('W03_C_open_loop');
g = R.u(end)/V.X_open;
ok = report(ok, '3 measured u/X = Week 1 K_u', abs(g - Ku)/Ku < 1e-3, sprintf('%.6f vs %.6f', g, Ku));

%% 4
if ~isfile(fullfile(wk, 'W03_E_PID.slx')), W03_1_build_speed('W03_E_PID'); end
R = W03_read('W03_E_PID');
ok = report(ok, '4 integral = drag at 1.5 m/s', abs(R.I(end) - 1.5/Ku) < 0.2, ...
            sprintf('%.2f N vs %.2f N', R.I(end), 1.5/Ku));

%% 5
sg = @(u) sign(u);
n  = @(T) sg(T).*sqrt(abs(T)./(cfg.k_pos*(1 + sg(T))/2 + cfg.k_neg*(1 - sg(T))/2));
T  = [-60 -1 1 60 119.68];
k  = cfg.k_pos*(T > 0) + cfg.k_neg*(T < 0);
e5 = max(abs(k.*n(T).*abs(n(T)) - T));
ok = report(ok, '5 shaft-speed Fcn inverts T = k n|n|', e5 < 1e-9, sprintf('%.1e N', e5));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W03_0_setup.m''))');
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
