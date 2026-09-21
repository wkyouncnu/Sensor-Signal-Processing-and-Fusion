function vault_shift_weeks(apply)
%VAULT_SHIFT_WEEKS  주차 번호를 한 칸씩 뒤로 민다 (2주차 이후 전부 n -> n+1).
%                   Shifts every week number from 2 onwards by one (n -> n+1).
%
%   vault_shift_weeks()        무엇이 바뀌는지만 scratch 파일로 보인다 (dry run)
%   vault_shift_weeks(true)    실제로 고쳐 쓴다
%
%   vault_shift_weeks()        lists what would change, writes nothing
%   vault_shift_weeks(true)    rewrites the files
%
%   왜 있는가 / why it exists
%     2026-09-21, PID 입문을 새 2주차로 넣으면서 기존 W02(속도)·W03(선수각)·W04(유도)
%     와 계획상의 W05~W11 이 전부 한 칸씩 밀렸다. 파일 이름은 git mv 로 옮기고,
%     파일 **안의** 참조는 이 함수가 한 번에 고친다. 한 번의 정규식 치환으로 하므로
%     W02 -> W03 이 다시 W04 로 번지는 연쇄가 없다.
%
%     On 2026-09-21 a PID primer became the new Week 2, and the old W02 (surge),
%     W03 (heading), W04 (guidance) and the planned W05-W11 all moved back by one.
%     File names are moved with git mv; references INSIDE files are rewritten
%     here in a single regex pass, so W02 -> W03 never cascades into W04.
%
%   무엇을 바꾸는가 / what it rewrites (n >= 2 only; Week 1 and A1 stay)
%     W0n, w0n (파일·그림 접두사)            W02_vars -> W03_vars, w04- -> w05-
%     Week n, Weeks n to m, n주차              "Week 7" -> "Week 8"
%     §n-m  (강의 절 번호)                     course files: all, except after "*.md"
%                                              docs (CLAUDE, PLAN, skill): only when a
%                                              week token stands just before it
%     n-m   (맨 절 번호, "Section 4-7")        only inside week n's own files
%     ## n-m.  (절 제목)                       only inside week n's own lecture
%     week: n  (YAML 프론트매터)
%
%   바꾸지 않는 줄 / lines left alone
%     캡스톤·연구실 MILS 자료를 가리키는 줄. 그쪽의 W06, W07 은 이 볼트의 주차가 아니다.
%     Lines that point at the capstone course or the lab MILS project: their
%     W06, W07 are not weeks of this vault.
%
%   .md 안의 LaTeX 을 sed 로 고치지 않는다는 규칙(CLAUDE.md §4-11) 때문에 MATLAB 로
%   쓴다. 문자열 치환만 하고 역슬래시를 해석하지 않는다.
%   Written in MATLAB because of the no-sed-on-LaTeX rule (CLAUDE.md §4-11):
%   literal string work, backslashes are never interpreted.

if nargin < 1, apply = false; end
root = fileparts(fileparts(mfilename('fullpath')));
old  = cd(root);  cleanup = onCleanup(@() cd(old));

[~, ls] = system('git ls-files');
F = strsplit(strtrim(ls), newline);
F = F(~cellfun(@isempty, regexp(F, '\.(md|m|sh|awk|tex|txt)$', 'once')));
F = F( cellfun(@isempty, regexp(F, 'MSS-master|svgzoom_profile|^_templates/', 'once')));
F = F(~ismember(F, {'_tools/vault_shift_weeks.m', '_tools/tidy_all.m', '_tools/tidy_layout.m'}));

DOCS = '^(CLAUDE\.md|PLAN\.md|\.claude/)';
SKIP = ['캡스톤|[Cc]apstone|MILS|W12_LOS|학부|W07_0_offline|build_w07|W07_setup|' ...
        'W06_0_simulink|W08_simulink|W07_simulink/img|6주차 전|7주차 55|10주차에 DP|' ...
        'type: week 일 때만'];

log = {};  nfile = 0;
for i = 1:numel(F)
    f = F{i};
    s = fileread(f, 'Encoding', 'UTF-8');
    isDoc = ~isempty(regexp(f, DOCS, 'once'));
    own   = own_week(f);               % the week this file belongs to, or 0
    L = regexp(s, '\n', 'split');
    changed = false;
    for k = 1:numel(L)
        a = L{k};
        if isempty(regexp(a, '[Ww]\d|Week|주차|§|\d-\d|week:', 'once')), continue; end
        if ~isempty(regexp(a, SKIP, 'once')), continue; end
        b = shift_line(a, isDoc, own);
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

out = fullfile(tempdir, 'vault_shift_weeks.log');
fid = fopen(out, 'w', 'n', 'UTF-8');  fprintf(fid, '%s\n', log{:});  fclose(fid);
fprintf('  %d lines in %d files %s. log: %s\n', numel(log), nfile, ...
        ternary(apply, 'rewritten', 'would change'), out);
end

% ---------------------------------------------------------------------------
function b = shift_line(a, isDoc, own)
b = a;
% 1) file and figure prefixes: W02 -> W03, w04 -> w05
b = rep(b, '(?<![A-Za-z0-9])([Ww])(0[2-9]|1[01])(?![0-9])', @(t) [t{1} nn(t{2})]);
% 2) "Week n", "Weeks n to m", "Weeks n, m and k"
b = rep(b, '(Weeks? )(\d+(?:(?:, | and | to | or |–|-)\d+)*)', @(t) [t{1} nlist(t{2})]);
% 3) Korean "n주차"
b = rep(b, '(?<!\d)(\d+)(주차)', @(t) [n1(t{1}) t{2}]);
% 4) YAML front matter
b = rep(b, '^(week:\s*)(\d+)', @(t) [t{1} n1(t{2})]);
% 5) "§n-m" section references
if isDoc
    %  only with a week token right before it: "W03 §3-4", "`W02` §2-6", "Week 3 §3-4"
    b = rep(b, '((?:[Ww]\d\d`?|Week \d+|강의) ?)§ ?(\d+)(-\d)', @(t) [t{1} '§' n1(t{2}) t{3}]);
else
    b = rep(b, '(?<!md`? ?|md\) ?)§ ?(\d+)(-\d)', @(t) ['§' n1(t{1}) t{2}]);
end
% 6) bare "n-m" inside week n's own files: headings "## 4-1.", "Section 4-7",
%    table cells "| 2-1 |", "4-2 → 4-3". A digit-dash-digit that is not part
%    of a longer number, a date, an exponent or a § reference.
if own >= 2
    pat = sprintf('(?<![\\w.§\\-^{/$])(%d)(-\\d{1,2}(?:-\\d+)?[a-z]?)(?![\\d.])', own);
    b = rep(b, pat, @(t) [n1(t{1}) t{2}]);
end
end

function s = rep(s, pat, fn)
%  regexprep with a function for the replacement: MATLAB's ${...} cannot see
%  local functions, so the pieces are split and joined by hand.
[tok, parts] = regexp(s, pat, 'tokens', 'split');
if isempty(tok), return; end
out = parts{1};
for j = 1:numel(tok)
    out = [out fn(tok{j}) parts{j+1}]; %#ok<AGROW>
end
s = out;
end

function s = nn(d)
s = sprintf('%02d', str2double(d) + (str2double(d) >= 2));
end

function s = n1(d)
v = str2double(d);  s = sprintf('%d', v + (v >= 2 && v <= 11));
end

function s = nlist(t)
s = rep(t, '(\d+)', @(u) n1(u{1}));
end

function w = own_week(f)
%  lectures/W03_Heading_Control.md, lectures/W03_simulink/...  ->  3
t = regexp(f, '^lectures/W(\d\d)_', 'tokens', 'once');
if isempty(t), w = 0; else, w = str2double(t{1}); end
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
