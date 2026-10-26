function W07_fig_qp(S, B2, tau, here)
%W07_FIG_QP  7-7 절의 그림 / the figure of section 7-7.
%
%   W07_H_quadratic_program 이 부른다. 절 스크립트는 **돌리고 재는 것**까지이고
%   그리는 것은 여기다 - 실행 줄 45 개 규칙 (standing-orders §15-15). 7-8 절의 성능
%   판정에 쓸 계산 시간을 재면서 스크립트가 50 줄이 되었고, 그래서 떼어 냈다 (2026-10-13).
%   Called by W07_H_quadratic_program; the script runs and measures, this draws.
%
%   S    다섯 가지 배분 (name, T) / the five allocations
%   B2   X 와 N 의 두 행 / the X and N rows of B
%   tau  요구한 힘 / the demand
%   here 그림을 저장할 주차 폴더 / the week's folder

f = lab_fig('W07 Exp 7-7  constrained allocation', 1000, 460);
D = cell2mat(arrayfun(@(s) B2*s.T, S, 'UniformOutput', false));
bar(categorical({S.name}, {S.name}), D', 'grouped'); grid on;
yline(tau(1), 'k--', 'X demanded'); yline(tau(2), 'k:', 'N demanded');
legend({'X delivered [N]','N delivered [N m]'}, 'Location','northeast');
title('what each strategy gives up: the weights are where the engineering decision is stated');
exportgraphics(f, fullfile(here, 'img', 'W07_result_qp.png'), 'Resolution', 150);
end
