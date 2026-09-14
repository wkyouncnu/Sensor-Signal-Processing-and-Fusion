function vault_number_audit(logfile)
%VAULT_NUMBER_AUDIT  강의자료에 적힌 수치가 실제 실행 출력에 있는지 대조한다.
%
%      vault_runall                                   % 먼저 전부 돌리고 diary 로 받는다
%      vault_number_audit(fullfile(tempdir,'vault_runall_log.txt'))
%
%  왜 필요한가 (2026-09-14).
%    W02 §F 표가 back-calculation 을 339.0 / 464.1 / 3.640 으로 적고 있었는데
%    스크립트는 213.1 / 356.2 / 3.440 을 낸다. 16줄 아래 본문은 3.44 라고 쓴다.
%    게인을 바꾼 뒤 본문만 고치고 표를 안 고친 흔적이다. 이런 불일치는 8천 줄을
%    눈으로 읽어서는 다 못 찾는다. 그래서 센다.
%
%  무엇을 하는가
%    문서의 수식·표·본문에서 **소수점 이하 두 자리 이상**인 수를 전부 뽑아,
%    실행 로그(모든 절 스크립트 + 검증 도구의 콘솔 출력)에 같은 문자열이 있는지 본다.
%    반올림 자릿수가 달라도 잡히도록, 로그의 모든 수를 문서의 자릿수로 반올림해 비교한다.
%
%  결과를 읽는 법
%    "로그에 없음" 은 오류가 아니라 **손으로 볼 후보**다. 손 계산(cos 30 = 0.8660),
%    otter.m 상수, 문헌값, 그림 좌표는 로그에 없는 것이 정상이다.
%    후보 목록을 줄여 주는 것이 이 도구의 일이고, 판정은 사람이 한다.

if nargin < 1, logfile = fullfile(tempdir, 'vault_runall_log.txt'); end
root = fileparts(fileparts(mfilename('fullpath')));
L    = fileread(logfile);

%  로그의 모든 수 (부호 포함). 문서 쪽 자릿수에 맞춰 반올림해 비교한다.
tokL = regexp(L, '[-+]?\d+\.\d+(e[-+]?\d+)?', 'match');
valL = str2double(tokL);
valL = valL(isfinite(valL));

docs = dir(fullfile(root, 'lectures', '*.md'));
fprintf('\n  수치 대조 — 문서의 소수 두 자리 이상 수가 실행 로그에 있는가\n');
fprintf('  로그 수치 %d 개\n', numel(valL));

for d = 1:numel(docs)
    f   = fullfile(docs(d).folder, docs(d).name);
    %  CollapseDelimiters 를 끈다. 기본값(true)은 빈 줄이 연달아 오면 하나로 합쳐
    %  **줄 번호가 앞으로 당겨진다** — 918 행의 표가 659 행으로 보고됐다.
    txt = strsplit(fileread(f), newline, 'CollapseDelimiters', false);
    miss = {};
    nchk = 0;
    for i = 1:numel(txt)
        s = txt{i};
        %  링크·코드 경로·YAML 날짜 줄은 건너뛴다
        if startsWith(strtrim(s), {'date:','> | ','http'}) || contains(s, {'youtube','drive.google'})
            continue
        end
        tok = regexp(s, '(?<![\w.])[-−]?\d+\.\d{2,}(?![\w.])', 'match');
        for k = 1:numel(tok)
            t  = strrep(tok{k}, '−', '-');
            v  = str2double(t);
            if ~isfinite(v), continue; end
            nd = numel(extractAfter(t, '.'));
            nchk = nchk + 1;
            %  같은 자릿수로 반올림한 로그 값 중 일치하는 것이 있는가 (부호 무시도 허용)
            hit = any(abs(round(valL, nd) - v) < 0.5*10^(-nd)) || ...
                  any(abs(round(abs(valL), nd) - abs(v)) < 0.5*10^(-nd));
            if ~hit
                miss(end+1, :) = {i, t, strtrim(s(1:min(end,110)))}; %#ok<AGROW>
            end
        end
    end
    fprintf('\n  == %s : 수 %d 개 중 로그에 없음 %d 개\n', docs(d).name, nchk, size(miss,1));
    for j = 1:size(miss,1)
        fprintf('     %5d  %-10s %s\n', miss{j,1}, miss{j,2}, miss{j,3});
    end
end
fprintf('\n');
end
