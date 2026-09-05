function tidy_all(root)
% TIDY_ALL  주차별 Simulink 모델을 모두 정리하고 결과를 표로 보고한다.
%
%   tidy_all                       % 기본 볼트 경로
%   tidy_all('<10-주차별-강의자료 경로>')
%
%   각 모델에 tidy_layout 을 적용한 뒤
%     - 블록 겹침 쌍
%     - 꺾인 선 개수
%   를 센다. 겹침 0 이 목표다.

if nargin < 1
    root = fullfile(fileparts(fileparts(mfilename('fullpath'))), '10-주차별-강의자료');
end
addpath(fileparts(mfilename('fullpath')));

folders = {'W06_0_simulink','W06_simulink','W07_simulink', ...
           'W08_simulink','W09_simulink'};

home = pwd;
fprintf('\n%-26s %6s %6s %6s %6s\n','모델','블록','겹침','선','꺾임');
fprintf('%s\n', repmat('-',1,54));
tot = [0 0 0 0];
for f = 1:numel(folders)
    d = fullfile(root, folders{f});
    if ~isfolder(d), continue; end
    files = dir(fullfile(d,'*.slx'));
    cd(d);
    for k = 1:numel(files)
        [~, m] = fileparts(files(k).name);
        try
            tidy_layout(m);
            s = statOne(m);
        catch err
            fprintf('%-26s  실패: %s\n', m, err.message);
            continue;
        end
        fprintf('%-26s %6d %6d %6d %6d\n', m, s(1), s(2), s(3), s(4));
        tot = tot + s;
    end
end
cd(home);
fprintf('%s\n', repmat('-',1,54));
fprintf('%-26s %6d %6d %6d %6d\n','합계', tot(1), tot(2), tot(3), tot(4));
end

% ---------------------------------------------------------------
function s = statOne(m)
wasOpen = bdIsLoaded(m);
if ~wasOpen, load_system(m); end
b = find_system(m,'SearchDepth',1,'Type','Block');
b = setdiff(b, {m});
P = cell2mat(cellfun(@(x) get_param(x,'Position'), b, 'UniformOutput',false));
ov = 0;
for i = 1:size(P,1)
    for j = i+1:size(P,1)
        a = P(i,:); c = P(j,:);
        if a(1)<c(3)-2 && c(1)<a(3)-2 && a(2)<c(4)-2 && c(2)<a(4)-2
            ov = ov + 1;
        end
    end
end
L = find_system(m,'SearchDepth',1,'FindAll','on','Type','line');
bent = 0;
for i = 1:numel(L)
    pts = get_param(L(i),'Points');
    if size(pts,1) > 2 && numel(unique(round(pts(:,2)))) > 1, bent = bent + 1; end
end
s = [numel(b) ov numel(L) bent];
if ~wasOpen, close_system(m, 0); end
end
