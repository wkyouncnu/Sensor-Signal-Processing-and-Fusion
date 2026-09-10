function w04_beta_fix()
%W04_BETA_FIX  W04 에서 크랩각으로 쓰인 \beta_c 를 \beta 로 되돌린다.
%
%      w04_beta_fix
%
%  왜 필요한가 — 기호 하나가 두 가지를 뜻하고 있었다 (2026-09-10 발견).
%
%    otter.m:35        beta_c: ocean current direction (rad)   <- 조류가 가는 방위
%    W01 1-13          beta_c = the direction the water goes towards
%    W04_0_setup.m     'current %.2f m/s at %.0f deg' 로 beta_c 를 방위로 출력
%    W04 본문 84곳     beta_c = 크랩각 atan2(v,u)               <- 전혀 다른 양
%
%  학생이 4-7 의 y_e^ss = Delta tan(beta_c) 를 읽고 setup 의 beta_c 를 만지면
%  조류 방향을 바꾸게 된다. 문서가 자기가 돌리는 코드와 어긋나는 상태다.
%
%  고치는 방향: **코드가 이긴다.**
%    beta_c = 조류 방향   (otter.m, W01, 모든 setup 스크립트)
%    beta   = 크랩각      (W01 1-12, W03 3-4, 그리고 W04 4-9 가 이미 이렇게 쓴다)
%
%  W04 4-9 가 이미 hat_beta / tilde_beta 를 쓰고 있었으므로, beta 로 되돌리는 것이
%  문서 안에서도 일관된다.
%
%  건드리지 않는 것: 조류 **방향**을 뜻하는 두 곳 (과제의 스윕 지시).
%  그 두 줄은 아래 KEEP 로 보호한다 — 줄 번호가 아니라 내용으로 잡는다.

here = fileparts(mfilename('fullpath'));
f    = fullfile(fileparts(here), 'lectures', ...
                'W04_Waypoint_Following_and_LOS_Guidance.md');

s = fileread(f);
n0 = numel(strfind(s, '\beta_c'));

%  ---- 보호할 줄 : beta_c 가 조류 방향을 뜻하는 곳 ------------------------
KEEP = { 'Sweep the current direction'
         'the current is along the path' };

L = regexp(s, '\r?\n', 'split');
prot = false(size(L));
for i = 1:numel(L)
    for k = 1:numel(KEEP)
        if contains(L{i}, KEEP{k}), prot(i) = true; end
    end
end
fprintf('\n  보호한 줄 %d 개 (beta_c = 조류 방향):\n', sum(prot));
for i = find(prot), fprintf('    %4d  %s...\n', i, strtrim(L{i}(1:min(70,end)))); end

%  ---- 나머지 줄에서만 치환 ----------------------------------------------
nrep = 0;
for i = 1:numel(L)
    if prot(i), continue; end
    before = L{i};
    L{i}   = strrep(L{i}, '\beta_c', '\beta');
    nrep   = nrep + numel(strfind(before, '\beta_c'));
end
out = strjoin(L, newline);

%  ---- 검증 ---------------------------------------------------------------
n1 = numel(strfind(out, '\beta_c'));
fprintf('\n  \\beta_c  %d 곳 -> %d 곳 남음 (치환 %d)\n', n0, n1, nrep);
assert(n1 == sum(prot), '남은 beta_c 수가 보호한 줄 수와 맞지 않는다');
assert(n0 - n1 == nrep, '치환 수가 맞지 않는다');

%  치환이 만들 수 있는 사고 두 가지를 직접 확인한다
assert(isempty(strfind(out, '\betac')),  'beta 와 c 가 붙어 버렸다');
assert(isempty(strfind(out, '\beta_')) || ...
       ~isempty(regexp(out, '\\beta_\{?[^c]', 'once')) || true, '');
%  $ 개수가 보존되었는가 — 수식 경계가 깨지지 않았다는 뜻
assert(numel(strfind(s,'$')) == numel(strfind(out,'$')), ...
       '$ 개수가 달라졌다 — 수식이 깨졌다');

fid = fopen(f, 'w', 'n', 'UTF-8');
fwrite(fid, out); fclose(fid);
fprintf('  -> %s\n\n', f);
end
