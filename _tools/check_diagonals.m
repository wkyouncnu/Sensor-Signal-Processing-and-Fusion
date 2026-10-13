function n = check_diagonals(mdl, verbose)
%CHECK_DIAGONALS  모델 안의 **대각선 선분**을 센다. 0 이어야 그 모델이 끝난 것이다.
%                 Count diagonal line segments in a model; 0 is the finished state.
%
%   n = check_diagonals('W04_I_rate')        % 숫자만 / the count
%   check_diagonals('W04_I_rate', true)      % 어느 선인지 함께 / name the offenders
%
%   시뮬링크의 선은 점의 열이다. 이웃한 두 점이 x 도 y 도 함께 바뀌면 그 구간은
%   비스듬하게 그려지고, 도면을 읽는 눈이 거기서 멈춘다. 가로 아니면 세로여야 한다.
%   A Simulink line is a list of points. If two neighbouring points differ in both
%   x and y, that stretch is drawn at an angle and the eye stops there. Every
%   stretch must be horizontal or vertical.
%
%   분기선(Branch)도 함께 본다 — Goto 로 올라가는 가지가 대각선인 경우가 가장 흔하다.
%   Branches are walked too: a branch rising to a Goto is the commonest offender.
%
%   겹침은 check_overlaps 가 센다. 두 가지는 다른 결함이다.
%   check_overlaps counts crossings; these are different faults.

if nargin < 2, verbose = false; end
was = load_if_needed(mdl);

tol = 0.5;                                  % 픽셀 / pixels
L = find_system(mdl, 'FindAll','on', 'SearchDepth',99, 'Type','line');
n = 0;
for i = 1:numel(L)
    p = get_param(L(i), 'Points');
    if size(p,1) < 2, continue; end
    d = abs(diff(p, 1, 1));
    bad = find(d(:,1) > tol & d(:,2) > tol);
    n = n + numel(bad);
    if verbose && ~isempty(bad)
        src = get_param(L(i), 'SrcBlockHandle');
        if src > 0, nm = get_param(src, 'Name'); else, nm = '(branch)'; end
        for k = 1:numel(bad)
            fprintf('    대각선 / diagonal  %-22s  (%d,%d) -> (%d,%d)\n', nm, ...
                    round(p(bad(k),1)), round(p(bad(k),2)), ...
                    round(p(bad(k)+1,1)), round(p(bad(k)+1,2)));
        end
    end
end

if ~isempty(was), close_system(mdl, 0); end
end

% =========================================================================
function was = load_if_needed(mdl)
if bdIsLoaded(mdl), was = ''; else, load_system(mdl); was = mdl; end
end
