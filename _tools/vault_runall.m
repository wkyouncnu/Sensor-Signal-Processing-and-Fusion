function vault_runall(logfile, WK)
%VAULT_RUNALL  모든 주차의 절 스크립트를 실제로 돌려 본다.
%              Actually run every section script of every week.
%
%      vault_runall
%      vault_runall('run.log')
%      vault_runall('', {'W02','W03'})     주차 일부만 / only some weeks
%
%  왜 필요한가 / why this exists
%      문서를 고치다 보면 스크립트도 함께 고치게 되고, 그때 한두 개만 돌려 보고
%      넘어가기 쉽다. 학생은 전부 돌린다. 그래서 전부 돌려 본다.
%      Editing the notes leads to editing the scripts, and it is easy to run
%      one or two of them and move on. A student runs all of them, so all of
%      them are run here.
%
%  logfile 을 주면 모든 스크립트의 콘솔 출력을 그 파일에 모은다.
%  vault_number_audit 가 그 파일로 문서의 수치를 대조한다.
%  Given a logfile, every script's console output is collected into it, and
%  vault_number_audit checks the documents' numbers against that file.
%
%  diary 는 쓰지 않는다. MCP 로 부른 MATLAB 에서는 거의 잡히지 않았다 — 실제로
%  2026-09-14 에 44 개를 돌리고 26 바이트가 남았다. evalc 로 직접 받는다.
%  diary is not used: under MATLAB called through the MCP it captured almost
%  nothing — 44 scripts on 2026-09-14 left 26 bytes — so the output is taken
%  directly with evalc.
if nargin < 1, logfile = ''; end
LOG = {};
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

if nargin < 2 || isempty(WK), WK = {'W01','W02','W03','W04','W05','A1'}; end
%  '_check' 는 빼지 않는다. 학생용 채점기(problems/WXX_check.m)는 하위 폴더에 있어
%  이 목록(최상위 WXX_*.m)에 원래 안 잡히고, 최상위의 W01_F_button_check 같은 것은
%  **강의 절 스크립트**다 — 2026-09-14 까지 잘못 빼고 있었다.
%  '_usb_setup' 은 뺀다: 대화창을 띄워 실물 조종기 입력을 기다리므로 무인 실행에서 멈춘다.
SKIP = {'_start','_plot','_read','_vars','_animate','_cols','_expected','_usb_setup'};

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
            cmd = sprintf('run(''%s'');', fullfile(d, S(k).name)); %#ok<NASGU>
            out = evalc('evalin(''base'', cmd)');
            LOG{end+1} = sprintf('\n===== %s =====\n%s', nm, out); %#ok<AGROW>
            if isempty(logfile), fprintf('%s', out); end   % 로그 파일을 주면 화면엔 요약만
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

%% ---- 검증 도구: 강의에 적힌 상수·유도를 원천과 대조한다 ----------------
V = {'verify_constants','verify_w01_theory','verify_guidance','verify_alos', ...
     'verify_review_math','verify_w02_pid','verify_w03_derivative','verify_w03_antiwindup'};
fprintf('  ================ 검증 도구 ================\n\n');
for i = 1:numel(V)
    if ~exist(V{i}, 'file'), fprintf('  %-22s 없음\n', V{i}); continue; end
    try
        %  반환값이 있는 검증 함수는 그 값을 본다. verify_alos 는 대조 대상을
        %  못 찾으면 **오류 없이 false** 를 돌려준다 — 오류만 보면 OK 로 찍힌다.
        okv = true;
        if nargout(V{i}) > 0
            out = evalc('okv = feval(V{i});');
        else
            out = evalc('feval(V{i});');
        end
        LOG{end+1} = sprintf('\n===== %s =====\n%s', V{i}, out); %#ok<AGROW>
        if isequal(okv, false)
            fprintf('  %-22s FAIL  -> 함수가 false 를 반환했다 (대조 대상을 못 찾았거나 검사 불통과)\n', V{i});
            continue
        end
        fprintf('  %-22s OK\n', V{i});
    catch ME
        m = strrep(ME.message, newline, ' ');
        fprintf('  %-22s FAIL  -> %s\n', V{i}, m(1:min(140,end)));
    end
    close all
end
fprintf('\n');

%% ---- 그림 생성기 : 강의가 그 수치를 인용한다 ---------------------------
G = {'w01_euler_R','w04_ssa','w04_second_order','w05_losgeo'};
for i = 1:numel(G)
    if ~exist(G{i}, 'file'), continue; end
    try
        cmd = sprintf('%s;', G{i}); %#ok<NASGU>
        out = evalc('evalin(''base'', cmd)');
        LOG{end+1} = sprintf('\n===== %s =====\n%s', G{i}, out); %#ok<AGROW>
    catch ME
        fprintf('  %-22s FAIL  -> %s\n', G{i}, ME.message);
    end
end

if ~isempty(logfile)
    fid = fopen(logfile, 'w', 'n', 'UTF-8');
    fwrite(fid, strjoin(LOG, newline));  fclose(fid);
    d = dir(logfile);
    fprintf('  로그 -> %s  (%d bytes)\n\n', logfile, d.bytes);
end
end
