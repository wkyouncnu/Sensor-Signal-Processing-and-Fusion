function vault_shift_from(first, apply, only_sections)
%VAULT_SHIFT_FROM  주차 번호 first 이상을 한 칸씩 뒤로 민다 (n -> n+1).
%                  Shifts every week number from `first` onwards by one.
%
%   vault_shift_from(6)                  무엇이 바뀌는지만 로그로 보인다 (dry run)
%   vault_shift_from(6, true)            실제로 고쳐 쓴다
%   vault_shift_from(6, true, true)      규칙 6(맨 절 번호)만 다시 돌린다
%
%   왜 셋째 인자가 있는가
%     규칙 6 은 "그 파일 자기 주차의 절 번호" 를 민다. 그런데 파일 이름은
%     `vault_shift_files.sh` 가 **먼저** 바꿔 놓으므로, `lectures/W08_…md` 안에
%     들어 있는 절 번호는 아직 `7-x` 다. 처음 판은 새 이름에서 8 을 읽어 `8-x` 를
%     찾았고, 그런 토큰이 없어서 절 제목이 그대로 남았다 (2026-10-26).
%     규칙 1~5 를 두 번 돌리면 두 칸이 밀리므로, 고친 규칙 6 만 따로 돌린다.
%
%   왜 있는가 / why it exists
%     2026-09-21 의 `vault_shift_weeks` 는 "2주차 이후 전부" 로 **박혀 있었다.**
%     2026-10-26 에 선수추진기 위치제어가 새 6주차로 들어오면서 6주차 이후만
%     밀어야 했고, 같은 일이 또 생길 것이므로 시작 주차를 인자로 뺐다.
%     앞의 것은 그때의 기록으로 남겨 둔다 — 그 함수의 SKIP 목록은 그 한 번을
%     위한 것이어서 지금 그대로 쓰면 틀린다 (`W07_simulink/img` 를 건너뛰면
%     옛 7주차 문서의 그림 경로가 안 따라온다).
%
%   무엇을 바꾸는가 / what it rewrites (n >= first only)
%     W0n, w0n (파일·그림 접두사)       W06_vars -> W07_vars, w06- -> w07-
%     Week n, Weeks n to m, n주차        "Week 7" -> "Week 8"
%     §n-m  (강의 절 번호)               강의 파일: 전부. 문서(CLAUDE·PLAN·스킬):
%                                        바로 앞에 주차 토큰이 있을 때만
%     n-m   (맨 절 번호, "Section 7-2")  그 주차 **자기 파일 안에서만**
%     week: n  (YAML 프론트매터)
%
%   바꾸지 않는 줄 / lines left alone
%     캡스톤·연구실 MILS 를 가리키는 줄. 그쪽의 W06·W07 은 이 볼트의 주차가 아니다.
%     스킬 문서의 옛 사례 서술("7주차 55%", "10주차에 DP") — 지난 일의 기록이다.
%
%   아예 열지 않는 파일 / files not opened at all
%     `standing-orders.md` 와 그 본문인 `orders-*.md` 열둘 · `lecture-md.md` ·
%     `week_refs.sh` 는 **날짜가 붙은 일지**다.
%     "2026-09-05 에 W05 와 W06 의 순서를 바꿨다" 를 W07 로 고치면 그날 일어난 일이
%     아닌 것이 된다. 사용자 발언을 그대로 옮긴 줄까지 고쳐져서("W05주차 모두
%     동일해" -> "W5주차") 인용이 인용이 아니게 됐다. 지난 일은 그대로 두고
%     **새 날짜로 한 줄 더 적는다.** 살아 있는 참조(W10~W12 같은 예정 주차)는 손으로 고친다.
%     `_previous_version/` 은 옛 판의 사본이므로 그 판의 주차 번호가 맞다.
%     `vault_rename_tau_u` · `vault_unify_ypont` 의 `§11-1` 은 주차 절이 아니라
%     `standing-orders` 의 절 번호다 — 주차와 함께 움직이지 않는다.
%
%   .md 안의 LaTeX 을 sed 로 고치지 않는다는 규칙(CLAUDE.md §4-11) 때문에 MATLAB
%   으로 쓴다. 문자열 치환만 하고 역슬래시를 해석하지 않는다.

if nargin < 2, apply = false; end
if nargin < 3, only_sections = false; end
root = fileparts(fileparts(mfilename('fullpath')));
old  = cd(root);  cleanup = onCleanup(@() cd(old)); %#ok<NASGU>

[~, lsout] = system('git ls-files');
F = strsplit(strtrim(lsout), newline);
F = F(~cellfun(@isempty, regexp(F, '\.(md|m|sh|awk|tex|txt)$', 'once')));
F = F( cellfun(@isempty, regexp(F, ['MSS-master|svgzoom_profile|^_templates/|' ...
                    '_previous_version/|standing-orders\.md|orders-[a-z0-9-]+\.md|' ...
                    'lecture-md\.md|week_refs\.sh'], 'once')));
F = F(~ismember(F, {'_tools/vault_shift_weeks.m', '_tools/vault_shift_from.m', ...
                    '_tools/vault_shift_files.sh', ...
                    '_tools/vault_rename_tau_u.m', '_tools/vault_unify_ypont.m', ...
                    '_tools/tidy_all.m', '_tools/tidy_layout.m'}));

DOCS = '^(CLAUDE\.md|PLAN\.md|\.claude/)';
SKIP = ['캡스톤|[Cc]apstone|MILS|W12_LOS|학부|W07_0_offline|build_w07|' ...
        '7주차 55|10주차에 DP|type: week 일 때만'];

log = {};  nfile = 0;
for i = 1:numel(F)
    f = F{i};
    s = fileread(f, 'Encoding', 'UTF-8');
    isDoc = ~isempty(regexp(f, DOCS, 'once'));
    own   = own_week(f);
    L = regexp(s, '\n', 'split');
    changed = false;
    for k = 1:numel(L)
        a = L{k};
        if isempty(regexp(a, '[Ww]\d|Week|주차|§|\d-\d|week:', 'once')), continue; end
        if ~isempty(regexp(a, SKIP, 'once')), continue; end
        b = shift_line(a, isDoc, own, first, only_sections);
        if ~strcmp(a, b)
            L{k} = b;  changed = true;
            log{end+1} = sprintf('%s:%d\n  - %s\n  + %s', f, k, strtrim(a), strtrim(b)); %#ok<AGROW>
        end
    end
    if changed
        nfile = nfile + 1;
        if apply
            fid = fopen(f, 'w', 'n', 'UTF-8');  fwrite(fid, strjoin(L, newline));  fclose(fid);
        end
    end
end

out = fullfile(tempdir, 'vault_shift_from.log');
fid = fopen(out, 'w', 'n', 'UTF-8');  fprintf(fid, '%s\n', log{:});  fclose(fid);
fprintf('  %d lines in %d files %s. log: %s\n', numel(log), nfile, ...
        ternary(apply, 'rewritten', 'would change'), out);
end

% ---------------------------------------------------------------------------
function b = shift_line(a, isDoc, own, first, only_sections)
b = a;
if only_sections, b = shift_sections(b, own, first); return; end
%  1) 파일·그림 접두사: W06 -> W07, w06- -> w07-
b = rep(b, '(?<![A-Za-z0-9])([Ww])(0[1-9]|1[01])(?![0-9])', @(t) [t{1} nn(t{2}, first)]);
%  1b) 한 자리 형태 "W6" — 표 칸과 주석의 기여 표시 `use_scale (W6)` 가 이 꼴이다.
%      규칙 1 이 먼저 돌아 `W06` -> `W07` 을 만들어도 그 결과의 둘째 글자가 `0` 이므로
%      여기 걸리지 않는다. 그래서 두 번 밀리지 않는다. 뒤에 `_` 가 오면 파일 이름이라
%      규칙 1 의 몫이므로 비켜 둔다.
b = rep(b, '(?<![A-Za-z0-9_])W([6-9])(?![0-9_])', @(t) ['W' n1(t{1}, first)]);
%  2) "Week n", "Weeks n to m", "Weeks n, m and k"
b = rep(b, '(Weeks? )(\d+(?:(?:, | and | to | or |–|-)\d+)*)', @(t) [t{1} nlist(t{2}, first)]);
%  3) "n주차"
b = rep(b, '(?<!\d)(\d+)(주차)', @(t) [n1(t{1}, first) t{2}]);
%  4) YAML 프론트매터
b = rep(b, '^(week:\s*)(\d+)', @(t) [t{1} n1(t{2}, first)]);
%  5) "§n-m"
if isDoc
    b = rep(b, '((?:[Ww]\d\d`?|Week \d+|강의) ?)§ ?(\d+)(-\d)', @(t) [t{1} '§' n1(t{2}, first) t{3}]);
else
    b = rep(b, '(?<!md`? ?|md\) ?)§ ?(\d+)(-\d)', @(t) ['§' n1(t{1}, first) t{2}]);
end
%  6) 그 주차 자기 파일 안의 맨 절 번호 — 제목 "## 7-1.", "Experiment 7-2",
%     표 칸 "| 7-1 |". 긴 수·날짜·지수·§ 참조의 일부가 아닌 숫자-빼기-숫자만.
b = shift_sections(b, own, first);
end

% ---------------------------------------------------------------------------
function b = shift_sections(b, own, first)
%  파일 이름은 이미 밀려 있으므로 그 안의 절 번호는 아직 한 칸 앞이다.
%  `lectures/W08_…` 의 절은 `7-x` 이므로 own-1 을 찾아 own 으로 쓴다.
if own <= first, return; end
sect = own - 1;
%  sprintf 를 쓰지 않는다 — \w·\d 를 이스케이프로 먹어 치운다. 손으로 잇는다
%  뒤의 금지는 **숫자와 소수점만**이다. `(?![\d.])` 로 두면 절 제목
%  `## 6-0. Setting up` 의 마침표에 걸려 **제목이 하나도 안 바뀐다** (2026-10-26).
pat = ['(?<![\w.§\-^{/$])(' num2str(sect) ')(-\d{1,2}(?:-\d+)?[a-z]?)(?!\d|\.\d)'];
b = rep(b, pat, @(t) [n1(t{1}, first) t{2}]);
end

function s = rep(s, pat, fn)
%  regexprep 에 함수를 쓰려면: MATLAB 의 ${...} 는 지역함수를 못 보므로
%  토큰과 사이 글자를 따로 받아 손으로 잇는다.
[tok, parts] = regexp(s, pat, 'tokens', 'split');
if isempty(tok), return; end
out = parts{1};
for j = 1:numel(tok)
    out = [out fn(tok{j}) parts{j+1}]; %#ok<AGROW>
end
s = out;
end

function s = nn(d, first)
v = str2double(d);  s = sprintf('%02d', v + (v >= first && v <= 11));
end

function s = n1(d, first)
v = str2double(d);  s = sprintf('%d', v + (v >= first && v <= 11));
end

function s = nlist(t, first)
s = rep(t, '(\d+)', @(u) n1(u{1}, first));
end

function w = own_week(f)
t = regexp(f, '^lectures/W(\d\d)_', 'tokens', 'once');
if isempty(t), w = 0; else, w = str2double(t{1}); end
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
