function vault_runall()
%VAULT_RUNALL  모든 주차의 절 스크립트를 실제로 돌려 본다.
%
%      vault_runall
%
%  왜 필요한가. 문서를 고치다 보면 스크립트도 함께 고치게 되고, 그때 한두 개만
%  돌려 보고 넘어가기 쉽다. 학생은 전부 돌린다. 그래서 전부 돌려 본다.
%
%  주의 — 절 스크립트 대부분이 첫 줄에서 `clear` 를 부른다. 그래서 호출부의
%  변수가 지워지지 않도록 **함수 안에서** 돌리고, 목록은 persistent 가 아니라
%  이 함수의 지역 변수로 들고 있는다. (실제로 evalin 으로 돌렸다가 루프 변수가
%  지워져서 한 번 깨졌다, 2026-09-10.)
%
%  건너뛰는 것: 학생이 직접 부르지 않는 헬퍼 (_plot, _read, _vars, _animate,
%  _check, _start, _expected, _cols) 와, 모델을 여는 빌더가 아닌 파일.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'_tools'));  mss_path();

WK   = {'W01','W02','W03','W04','A1'};
SKIP = {'_start','_check','_plot','_read','_vars','_animate','_cols','_expected'};

names = {};  weeks = {};  stat = {};  msg = {};
for i = 1:numel(WK)
    d = fullfile(root, 'lectures', [WK{i} '_simulink']);
    if ~isfolder(d), continue; end
    S = dir(fullfile(d, [WK{i} '_*.m']));
    %  0_setup 을 맨 앞으로, 1_build 를 그 다음으로 정렬한다 — 절 스크립트가
    %  그 둘에 의존하기 때문이다.
    ord = cellfun(@(n) 1*contains(n,'_0_setup') + 2*contains(n,'_1_build'), {S.name});
    ord(ord == 0) = 3;
    [~, ix] = sort(ord);  S = S(ix);
    for k = 1:numel(S)
        nm = erase(S(k).name, '.m');
        if any(cellfun(@(p) contains(nm,p), SKIP)), continue; end
        old = pwd;  cd(d);
        try
            %  base 워크스페이스에서 돌린다. run() 을 여기서 부르면 스크립트
            %  첫 줄의 `clear` 가 **이 함수의** 누적 변수를 지운다 — 실제로
            %  그렇게 한 번 깨졌다. evalin 이면 지워지는 것은 base 쪽뿐이다.
            evalin('base', sprintf('run(''%s'');', fullfile(d, S(k).name)));
            weeks{end+1} = WK{i};  names{end+1} = nm; %#ok<AGROW>
            stat{end+1}  = 'OK';   msg{end+1}   = '';  %#ok<AGROW>
        catch ME
            weeks{end+1} = WK{i};  names{end+1} = nm; %#ok<AGROW>
            stat{end+1}  = 'FAIL'; msg{end+1}   = ME.message; %#ok<AGROW>
        end
        cd(old);  close all;
    end
end

fprintf('\n\n  ================ 전체 스크립트 실행 결과 ================\n\n');
fprintf('  %-5s %-40s %s\n', '주차', '스크립트', '결과');
fprintf('  %s\n', repmat('-', 1, 74));
nf = 0;
for i = 1:numel(names)
    fprintf('  %-5s %-40s %s\n', weeks{i}, names{i}, stat{i});
    if strcmp(stat{i}, 'FAIL')
        nf = nf + 1;
        m = strrep(msg{i}, newline, ' ');
        fprintf('        -> %s\n', m(1:min(140,end)));
    end
end
fprintf('\n  %d개 실행, 실패 %d개\n\n', numel(names), nf);
end
