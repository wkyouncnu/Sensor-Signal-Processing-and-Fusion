function ok = verify_w06_allocation()
%VERIFY_W06_ALLOCATION  6주차(제어 배분)가 싣는 수와 식을 독립적으로 다시 확인한다.
%                       Recheck the numbers and equations of Week 6 (control allocation).
%
%   검사 / checks
%     1  W06_vars 와 W06_0_setup 의 값이 같다 / the two parameter files agree
%     2  블록이 쓰는 두 줄이 pinv(B) 와 같다 (§6-2, §6-3)
%        the block's two lines equal pinv(B), row for row
%     3  요구가 한계 안에 있으면 정사각 배분은 정확하다 — 시뮬레이션으로 (§6-2)
%        while the demand fits, the square rule delivers it exactly
%     4  전달된 횡력은 언제나 0 이고, 최소자승 잔차는 요구한 횡력과 같다 (§6-3)
%        the delivered sway is zero and the residual equals the sway demanded
%     5  비율 줄이기는 방향을 지키고 자르기는 지키지 않는다 (§6-6)
%        scaling keeps the direction of the demand; clipping does not

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W06_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w06_allocation\n\n');

V = W06_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(S.(f{1}), V.(f{1})), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W06_vars = W06_0_setup', isempty(bad), strjoin(bad, ', '));

B  = otter_B(otter_config('base'));
Bp = pinv(B);
hand = [0.5 0 1/(2*V.y_pont); 0.5 0 -1/(2*V.y_pont)];     % 블록의 두 줄 / the block's two lines
e2 = max(max(abs(Bp - hand)));
ok = report(ok, '2 the block''s two lines = pinv(B)', e2 < 1e-12, sprintf('%.1e', e2));

for n = {'W06_C_square','W06_D_pseudo','W06_F_limits'}
    if ~isfile(fullfile(wk, [n{1} '.slx'])), W06_1_build_allocation(n{1}); end
end
R = W06_read('W06_C_square');
at = @(R, f, t) interp1(R.t, R.(f), t);
e3 = max(abs([at(R,'Xa',20) - at(R,'Xd',20), at(R,'Na',20) - at(R,'Nd',20)]));
ok = report(ok, '3 the square rule is exact while it fits', e3 < 1e-9, sprintf('%.1e N', e3));

R = W06_read('W06_D_pseudo');
k = R.t > 5;
e4 = max(abs(R.Ya(k)));                                    % 전달된 횡력 / the sway delivered
r4 = max(abs(vecnorm([R.Xd(k) R.Yd(k) R.Nd(k)] - [R.Xa(k) R.Ya(k) R.Na(k)], 2, 2) - abs(R.Yd(k))));
ok = report(ok, '4 sway is dropped, and only sway', e4 < 1e-9 && r4 < 1e-6, ...
            sprintf('|Y| <= %.1e N, residual = |Y demanded| to %.1e', e4, r4));

Rc = W06_read('W06_F_limits', 'fit_mode', 0);
Rs = W06_read('W06_F_limits', 'fit_mode', 1);
want = at(Rc,'Xd',20)/at(Rc,'Nd',20);
gotc = at(Rc,'Xa',20)/at(Rc,'Na',20);
gots = at(Rs,'Xa',20)/at(Rs,'Na',20);
ok = report(ok, '5 scaling keeps the direction, clipping does not', ...
            abs(gots - want) < 1e-6 && abs(gotc - want) > 1, ...
            sprintf('demanded %.2f, scaled %.2f, clipped %.2f', want, gots, gotc));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W06_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i','V','f'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-48s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
