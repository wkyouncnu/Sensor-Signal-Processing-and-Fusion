function vault_rename_tau_u()
%VAULT_RENAME_TAU_U  서지 시상수를 tau_u 에서 T_u 로 바꾼다 (문서와 코드 동시).
%
%      vault_rename_tau_u
%
%  왜 — 기호 하나가 두 가지를 뜻하고 있었다 (2026-09-10, standing-orders §10-1).
%
%    tau       otter.m 158,166,168 : tau, tau_damp, tau_crossflow
%              전부 **일반화 힘** [N, N.m]
%    tau_N     W03/W04 : 요 모멘트 [N.m]      <- 위와 같은 뜻, 옳다
%    tau_u     W01/W02 : 서지 **시상수** [s]  <- 혼자 다른 뜻
%
%  otter.m 은 시상수를 T_yaw / T_sway 로 쓰고 추력은 Thrust 로 쓴다. 볼트의
%  verify_constants.m 도 이미 T_yaw 를 쓴다. 그래서 **코드 규약을 따른다**:
%
%    tau_*   일반화 힘        (바꾸지 않는다)
%    T_<말>  시상수           T_u, T_sway, T_yaw
%    T_<숫자> 추력            T_1, T_2   (A1 과 W03 3-6 의 배분)
%
%  문서와 코드를 **같이** 바꾼다. 한쪽만 바꾸면 강의가 보여 주는 콘솔 출력이
%  학생이 실제로 보는 출력과 달라진다 — beta_c 에서 겪은 것과 같은 종류의 결함.

root = fileparts(fileparts(mfilename('fullpath')));

F = { fullfile(root,'lectures','W01_Vessel_Kinematics_and_the_Otter_Model.md')
      fullfile(root,'lectures','W02_Surge_Speed_Control.md')
      fullfile(root,'lectures','W03_Heading_Control.md')
      fullfile(root,'_tools','verify_constants.m')
      fullfile(root,'lectures','W02_simulink','W02_vars.m')
      fullfile(root,'lectures','W02_simulink','W02_0_setup.m')
      fullfile(root,'lectures','W02_simulink','W02_1_build_surge_control.m')
      fullfile(root,'lectures','W02_simulink','W02_C_identify_plant.m')
      fullfile(root,'lectures','W02_simulink','W02_E_integral_and_derivative.m') };

tot = 0;
fprintf('\n  tau_u -> T_u\n\n');
for i = 1:numel(F)
    if ~isfile(F{i}), fprintf('  [없음] %s\n', F{i}); continue; end
    s  = fileread(F{i});
    n0 = numel(strfind(s, 'tau_u'));
    if n0 == 0, continue; end

    %  \tau_u  ->  T_u   (LaTeX)   그리고  tau_u -> T_u  (식별자·본문)
    %  순서가 중요하다: 백슬래시가 붙은 쪽을 먼저 없애야 T_u 앞에 \ 가 남지 않는다
    s = strrep(s, '\tau_u', 'T_u');
    s = strrep(s, 'tau_u',  'T_u');

    n1 = numel(strfind(s, 'tau_u'));
    assert(n1 == 0, '%s 에 tau_u 가 남았다', F{i});
    %  \T_u 같은 사고가 없어야 한다
    assert(isempty(strfind(s, '\T_u')), '%s 에 \\T_u 가 생겼다', F{i});

    fid = fopen(F{i}, 'w', 'n', 'UTF-8');  fwrite(fid, s);  fclose(fid);
    [~, nm, ex] = fileparts(F{i});
    fprintf('  %-42s %3d 곳\n', [nm ex], n0);
    tot = tot + n0;
end
fprintf('\n  합계 %d 곳\n\n', tot);
end
