function vault_unify_ypont()
%VAULT_UNIFY_YPONT  프로펠러 모멘트 팔 기호를 y_p 에서 y_{\text{pont}} 으로 통일한다.
%
%      vault_unify_ypont
%
%  왜 (2026-09-14 전체 검토에서 발견)
%    - 같은 양이 W01 안에서 y_p 와 y_{\text{pont}} 두 가지로 쓰였고, A1 도 섞였다.
%      W03 는 y_p, W04 3-6 은 y_{\text{pont}}.
%    - y_p 는 W05 의 경로좌표계 위첨자 p ( y_e^p ) 와 글자가 같아 헷갈린다.
%    - otter.m:69 가 이 양을 y_pont 로 부른다. 코드가 이긴다 (standing-orders §11-1).
%
%  주의 — regexprep 의 치환 문자열에서 \t 는 탭 문자다. 그래서 역슬래시를 두 번 쓰고,
%  결과에 탭이 없는지와 $ 개수가 보존됐는지 assert 로 확인한다.

root = fileparts(fileparts(mfilename('fullpath')));
F = { 'W01_Vessel_Kinematics_and_the_Otter_Model.md'
      'W03_Surge_Speed_Control.md'
      'A1_Actuation_and_the_Control_Effectiveness_Matrix.md' };
pat = 'y_p(?![a-zA-Z{])';
rep = 'y_{\\text{pont}}';

fprintf('\n  y_p -> y_{\\text{pont}}\n\n');
for i = 1:numel(F)
    f  = fullfile(root, 'lectures', F{i});
    s0 = fileread(f);
    n  = numel(regexp(s0, pat));
    s1 = regexprep(s0, pat, rep);
    assert(sum(s1 == char(9)) == sum(s0 == char(9)), '%s: 탭이 생겼다', F{i});
    assert(sum(s1 == '$') == sum(s0 == '$'), '%s: $ 개수가 바뀌었다', F{i});
    assert(isempty(regexp(s1, pat, 'once')), '%s: y_p 가 남았다', F{i});
    assert(numel(strfind(s1, 'y_{\text{pont}}')) == numel(strfind(s0, 'y_{\text{pont}}')) + n, ...
           '%s: 치환 수가 맞지 않는다', F{i});
    fid = fopen(f, 'w', 'n', 'UTF-8'); fwrite(fid, s1); fclose(fid);
    fprintf('  %-52s %3d 곳\n', F{i}, n);
end
fprintf('\n');
end
