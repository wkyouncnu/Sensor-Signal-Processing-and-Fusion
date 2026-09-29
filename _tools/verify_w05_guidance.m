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
%     6  배분의 역: B [T_L; T_R] 이 원래의 [X; N] 을 되돌려 준다 (5-7 절)
%        the allocation inverse returns the (X, N) it came from
%     7  N_lim(X) 가 추력 한계에 닿되 넘지 않고, X* = T_max + T_min 에서 최대다 (5-7 절)
%        N_lim(X) touches the thrust limits without crossing, and peaks at T_max + T_min

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W05_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w05_guidance\n\n');

%  `animate` 는 **일부러 다르다**: W05_0_setup 은 사람이 Run 을 누르는 파일이라 1,
%  W05_vars 는 절 스크립트가 한 번에 여러 번 돌리는 파일이라 0 이다 (§15-20).
%  화면에만 관계되는 값이고 어떤 수치에도 영향을 주지 않으므로 이 검사에서 뺀다.
%  animate differs on purpose: 1 in the file a person presses Run in, 0 in the file
%  the section scripts run in bulk. It affects no number, so it is excluded here.
SHOW = {'animate'};
V = W05_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if any(strcmp(f{1}, SHOW)), continue; end
    if ~isfield(S, f{1}) || ~isequal(S.(f{1}), V.(f{1})), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W05_vars = W05_0_setup (animate excluded)', isempty(bad), strjoin(bad, ', '));

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

%  6  §5-7 의 배분 역행렬. otter_B 가 낸 B 의 1·3 행에 [T_L; T_R] 을 곱하면 [X; N] 이
%     되돌아와야 한다 — 손으로 푼 T = X/2 +- N/(2 y_p) 가 맞는지 보는 것이다.
%     The allocation inverse of 5-7: feeding the hand solution back through B must
%     return the (X, N) it came from.
cfg = otter_config('base');  B = otter_B(cfg);  B = B([1 3], :);
XN  = [77.58 -0.52; 77.26 64.03; 120 -47.15]';        % 실험 5-7 이 실제로 낸 값 / from Experiment 5-7
T   = [XN(1,:)/2 + XN(2,:)/(2*cfg.y_pont); XN(1,:)/2 - XN(2,:)/(2*cfg.y_pont)];
e6  = max(max(abs(B*T - XN)));
ok  = report(ok, '6 allocation inverse: B [T_L;T_R] = [X;N]', e6 < 1e-10, sprintf('%.1e', e6));

%  7  §5-7 의 모멘트 한계. N_lim(X) 에서 나온 N 을 배분하면 두 추력이 정확히 한계에
%     닿고 넘지 않는다. 그리고 두 가지가 맞아야 한다: X = 60 에서 70.85 N m,
%     최댓값이 X* = T_max + T_min 에 있다.
%     The moment limit: allocating N_lim(X) must touch a thrust limit without
%     crossing it, give 70.85 N m at X = 60, and peak at X* = T_max + T_min.
Tmax = cfg.k_pos*cfg.n_max^2;  Tmin = -cfg.k_neg*cfg.n_min^2;
Nlim = @(X) min(2*cfg.y_pont*(Tmax - X/2), 2*cfg.y_pont*(X/2 - Tmin));
Xs = 0:1:140;  Ns = arrayfun(Nlim, Xs);
TT = [Xs/2 + Ns/(2*cfg.y_pont); Xs/2 - Ns/(2*cfg.y_pont)];
e7 = max(max(TT(:)) - Tmax, Tmin - min(TT(:)));           % 넘어선 양 / how far past a limit
[~, ipk] = max(Ns);
c7 = e7 < 1e-10 && abs(Nlim(60) - 70.85) < 0.01 && abs(Xs(ipk) - (Tmax + Tmin)) < 1;
ok = report(ok, '7 N_lim(X) touches the thrust limits, peaks at T_max+T_min', c7, ...
            sprintf('over by %.1e N; N_lim(60) = %.2f; peak at X = %g vs %.2f', ...
                    e7, Nlim(60), Xs(ipk), Tmax + Tmin));

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
