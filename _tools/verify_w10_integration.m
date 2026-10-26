function ok = verify_w10_integration()
%VERIFY_W10_INTEGRATION  10주차(통합)가 싣는 수와 주장을 다시 확인한다.
%                        Recheck the numbers and the claims of Week 10.
%
%   검사 / checks
%     1  W10_vars 와 W10_0_setup 의 값이 같다 / the two parameter files agree
%     2  기준 임무가 끝난다: 세 다리, 세 번의 유지, 277.7 s (§10-2)
%        the reference mission completes, in the order it was written
%     3  ssa 를 빼면 3주차 다리의 이음매에서 한 바퀴를 돌고 임무를 놓친다 (§10-3)
%        without ssa the vessel turns a whole revolution at the seam
%     4  7주차의 결합을 잊으면 명령한 모멘트가 나오지 않는다 (§10-3)
%        forgetting the coupling of Week 7 loses the commanded moment
%     5  수락반경만으로는 1.3 m/s 에서 지점을 스쳐 지나가 임무를 놓친다 (§10-5)
%        the acceptance circle alone misses the waypoint at 1.3 m/s
%     6  같은 스펙트럼의 다섯 실현이 5 % 안에서 같은 답을 준다 — 실측 3.4 % (§10-6)
%        five realisations of one spectrum agree to within five per cent

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W10_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w10_integration\n\n');

V = W10_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(round(S.(f{1}), 12), round(V.(f{1}), 12)), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W10_vars = W10_0_setup', isempty(bad), strjoin(bad, ', '));

for n = {'W10_C_full','W10_D_ablation','W10_F_limits'}
    if ~isfile(fullfile(wk, [n{1} '.slx'])), W10_1_build_vessel(n{1}); end
end

R = W10_read('W10_C_full');  M = W10_metrics(R);
ch  = find(diff(R.mode) ~= 0) + 1;
seq = R.mode(ch)';
ok = report(ok, '2 the reference mission completes', ...
            isequal(seq, [2 1 2 1 2 3]) && M.legs == 3 && abs(M.T - 277.7) < 1, ...
            sprintf('modes %s, %d holds, done at %.1f s', mat2str(seq), M.legs, M.T));

A = W10_read('W10_D_ablation', 'use_ssa', 0);
j = A.wp == 3;  turns = (max(A.psi(j)) - min(A.psi(j)))/360;
ok = report(ok, '3 without ssa the seam costs a whole turn', ...
            turns > 1 && isnan(W10_metrics(A).T), ...
            sprintf('%.2f revolutions on leg 3, the mission unfinished', turns));

B = W10_read('W10_D_ablation', 'use_scale', 0);
ok = report(ok, '4 forgetting the Week 7 coupling loses the moment', ...
            W10_metrics(B).Nerr > 10*M.Nerr, ...
            sprintf('%.1f N m commanded and not produced, against %.1f N m with it', ...
                    W10_metrics(B).Nerr, M.Nerr));

C = W10_read('W10_F_limits', 'V_c', 1.3, 'use_pass', 0, 'T_final', 600);
D = W10_read('W10_F_limits', 'V_c', 1.3, 'use_pass', 1, 'T_final', 600);
near = min(hypot(C.V.WP_N(1) - C.N, C.V.WP_E(1) - C.E));
ok = report(ok, '5 the circle alone is missed at 1.3 m/s', ...
            near > C.V.R_arrive && isnan(W10_metrics(C).T) && ~isnan(W10_metrics(D).T), ...
            sprintf('closest pass %.2f m to a %.1f m circle; the along-track test finishes at %.1f s', ...
                    near, C.V.R_arrive, W10_metrics(D).T));

hold_e = zeros(1,5);  PH = [0 1.2 2.4 3.6 4.8];
for i = 1:5, hold_e(i) = W10_metrics(W10_read('W10_C_full', 'phase_shift', PH(i))).hold; end
spread = (max(hold_e) - min(hold_e))/mean(hold_e);
ok = report(ok, '6 five realisations agree to within 5 %', spread < 0.05, ...
            sprintf('hold error %.3f to %.3f m, a spread of %.1f %%', ...
                    min(hold_e), max(hold_e), 100*spread));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W10_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i','cfg'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-48s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
