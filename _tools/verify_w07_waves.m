function ok = verify_w07_waves()
%VERIFY_W07_WAVES  7주차(환경 하중과 파랑 필터)가 싣는 수와 식을 독립적으로 다시 확인한다.
%                  Recheck the numbers and equations of Week 7.
%
%   검사 / checks
%     1  W07_vars 와 W07_0_setup 의 값이 같다 / the two parameter files agree
%     2  파랑 하나가 스펙트럼과 맞는다: 4 sqrt(sum a^2/2) = Hs, 첨두가 w0 (§7-2)
%        the realisation matches its spectrum: the significant height and the peak
%     3  파랑은 평균이 0 이고, 그 변화율은 이 배의 최대 회두율에 맞먹는다 (§7-2)
%        the sea has zero mean, and its rate is of the order the vessel can turn at
%     4  노치의 w0 에서의 크기가 zeta_n/zeta_d 이다 — 식과 시뮬레이션 둘 다 (§7-4)
%        the notch reaches zeta_n/zeta_d at w0, by formula and in the model
%     5  노치를 걸면 같은 바다에서 모멘트와 선수각이 함께 좋아진다 (§7-4)
%        with the notch, both the moment and the true heading improve

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W07_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w07_waves\n\n');

V = W07_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if ~isfield(S, f{1}) || ~isequal(round(S.(f{1}), 12), round(V.(f{1}), 12))
        bad{end+1} = f{1}; %#ok<AGROW>
    end
end
ok = report(ok, '1 W07_vars = W07_0_setup', isempty(bad), strjoin(bad, ', '));

e2a = abs(4*sqrt(sum(V.a_i.^2)/2) - V.Hs);
[~, i] = max(V.a_i);
e2b = abs(V.w_i(i) - V.w0)/V.w0;
ok = report(ok, '2 the realisation matches its spectrum', e2a < 1e-12 && e2b < 0.05, ...
            sprintf('Hs %.4f m, peak component %.3f rad/s (w0 %.3f)', 4*sqrt(sum(V.a_i.^2)/2), V.w_i(i), V.w0));

for n = {'W07_C_wave','W07_D_no_filter','W07_E_notch'}
    if ~isfile(fullfile(wk, [n{1} '.slx'])), W07_1_build_waves(n{1}); end
end
R = W07_read('W07_C_wave');
ok = report(ok, '3 zero mean, and a rate the vessel cannot match', ...
            abs(mean(R.psi_w)) < 0.05 && std(R.r_w) > 10, ...
            sprintf('mean %.4f deg, rate std %.2f deg/s', mean(R.psi_w), std(R.r_w)));

s = tf('s');
H = (s^2 + 2*V.zeta_n*V.w0*s + V.w0^2)/(s^2 + 2*V.zeta_d*V.w0*s + V.w0^2);
e4 = abs(squeeze(bode(H, V.w0)) - V.zeta_n/V.zeta_d);
ok = report(ok, '4 |H(j w0)| = zeta_n / zeta_d', e4 < 1e-9, ...
            sprintf('%.4f vs %.4f', squeeze(bode(H, V.w0)), V.zeta_n/V.zeta_d));

Rn = W07_read('W07_D_no_filter');  Rf = W07_read('W07_E_notch');
jn = Rn.t > 20;  jf = Rf.t > 20;
ok = report(ok, '5 the notch improves both effort and heading', ...
            std(Rf.N(jf)) < std(Rn.N(jn)) && std(Rf.psi(jf)) < std(Rn.psi(jn)), ...
            sprintf('moment %.2f -> %.2f N m, heading %.3f -> %.3f deg', ...
                    std(Rn.N(jn)), std(Rf.N(jf)), std(Rn.psi(jn)), std(Rf.psi(jf))));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W07_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i','cfg'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-46s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
