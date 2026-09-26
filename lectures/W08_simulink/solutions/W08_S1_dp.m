function W08_S1_dp(mdl)
%W08_S1_DP  8주차 실습 세 문제의 모범답안 모델을 만든다.
%           Build the reference answer to all three Week 8 problems.
%
%   >> W08_S1_dp                 W08_S1.slx 를 만든다 / creates W08_S1.slx
%
%   세 문제가 한 블록에 들어간다 / all three problems live in one block
%       ①은 힘을 정하고 뱃머리에 정사영하는 부분, ②는 그 힘의 방향으로 뱃머리를
%       두는 한 줄, ③은 모드가 바뀔 때 적분을 비우는 한 줄이다. 어느 것도 새
%       제어기가 아니다 — 같은 제어기에 조건이 하나씩 붙을 뿐이다.
%       Problem 1 decides the force and projects it on the bow; Problem 2 is one
%       line that points the bow along that force; Problem 3 is one line that
%       empties the integral at a change of mode. None of them is a new
%       controller: they are conditions added to one.
%
%   See also W08_CHECK, W08_P1_START, W08_S_EXPECTED.

if nargin < 1 || isempty(mdl), mdl = 'W08_S1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%  출발 모델과 같은 시험대 / the same bench as the starting model
w08_lab_bench(mdl, 120);

%% ---- 제어기 / the controller -------------------------------------------
blk = [mdl '/controller'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [340 640 620 820]);
set_mlfcn(blk, controller_code(), 'X', '[1 1]', 'h');
mlfcn_params(blk, {'Kp_x','Ki_x','Kd_x','e_min','X_max','Kp','Kd','N_max', ...
                   'psi_fix','vane','X_ff','hand_over','h'});
for i = 1:3
    tag = {'p_d','x','mode'};  tag = tag{i};
    add_block('simulink/Signal Routing/From', [mdl '/' tag ' ctrl'], 'GotoTag', tag, ...
              'Position', [240 675+45*(i-1) 310 695+45*(i-1)]);
    add_line(mdl, [tag ' ctrl/1'], sprintf('controller/%d', i), 'autorouting','smart');
end
OT = {'X_ctrl','N_ctrl'};
for i = 1:2
    add_block('simulink/Signal Routing/Goto', [mdl '/' OT{i} ' out'], ...
              'GotoTag', OT{i}, 'Position', [680 680+60*(i-1) 750 700+60*(i-1)]);
    add_line(mdl, sprintf('controller/%d', i), [OT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 로그 / the log ----------------------------------------------------
add_block('simulink/Signal Routing/Mux', [mdl '/dlog mux'], 'Inputs','3', ...
          'Position', [830 660 835 780]);
add_line(mdl, 'controller/3', 'dlog mux/1', 'autorouting','smart');   % psi_d
add_line(mdl, 'controller/1', 'dlog mux/2', 'autorouting','smart');   % X
add_line(mdl, 'controller/2', 'dlog mux/3', 'autorouting','smart');   % N
add_block('simulink/Sinks/To Workspace', [mdl '/dlog'], ...
          'VariableName','dlog', 'SaveFormat','Structure With Time', ...
          'Position', [880 700 950 740]);
add_line(mdl, 'dlog mux/1', 'dlog/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/note']);
a.Text = strjoin({ ...
'WEEK 8 SOLUTION  -  ONE CONTROLLER, THREE CONDITIONS'
''
'   P1  how much force, in NED, and how much of it the bow can deliver'
'   P2  vane = 1: point the bow along that force, while the force is'
'       large enough for its direction to mean anything'
'   P3  mode == 1: push with X_ff and aim at the waypoint; hand_over: empty'
'       the integral when the mode changes'
''
'The integral is the only state here that does not respect modes, and that is'
'why it is the only one that has to be told about them.'}, newline);
a.Position = [340 880 1100 1040];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);
fprintf('\n  built %s   (overlapping lines: %d)\n\n', out, n);
end

% =========================================================================
function C = controller_code()
C = {
'function [X, N, psi_d_out] = controller(p_d, x, mode, Kp_x, Ki_x, Kd_x, e_min, X_max, Kp, Kd, N_max, psi_fix, vane, X_ff, hand_over, h)'
'%#codegen'
'%CONTROLLER  세 문제가 한 블록에 / all three problems, in one block.'
'psi = x(12);  u = x(1);  v = x(2);  r = x(6);'
'persistent In Ie'
'if isempty(In), In = 0;  Ie = 0; end'
'%'
'%  ── 문제 1a) 얼마의 힘이 어느 방향으로 / how much force, and where ────'
'%     위치 오차에 대한 PID 를 **북·동 두 방향 모두**에 대해 쓴다. 나오는 것은'
'%     추진기 이야기가 아니라 "이만큼의 힘이 이 방향으로 필요하다" 는 벡터다.'
'%     A PID on the position error, in both north and east. What comes out is'
'%     not yet a thruster: it is a vector saying how much force is wanted and'
'%     in which direction.'
'e_n = p_d(1) - x(7);  e_e = p_d(2) - x(8);'
'v_n = u*cos(psi) - v*sin(psi);        % 속도를 NED 로 / the velocity in NED'
'v_e = u*sin(psi) + v*cos(psi);'
'f_n = Kp_x*e_n + In - Kd_x*v_n;'
'f_e = Kp_x*e_e + Ie - Kd_x*v_e;'
'f   = hypot(f_n, f_e);'
'%'
'%  ── 문제 2) 그 힘의 방향으로 뱃머리를 / point the bow along that force ─'
'%     이 선체가 낼 수 있는 힘은 뱃머리 방향뿐이다 (6주차 §6-3: B 의 둘째 행이 0).'
'%     그러므로 필요한 힘 f 를 내려면 뱃머리가 f 를 향해야 한다. 조류가 밀면'
'%     적분이 상류 쪽 힘을 배우고, 뱃머리는 그것을 따라 조류에 맞선다.'
'%     The only force this hull can make points along its bow, so to deliver f'
'%     the bow must point along f. Under a current the integral learns an'
'%     upstream force and the bow follows it into the flow.'
'persistent psi_last'
'if isempty(psi_last), psi_last = psi; end'
'if vane ~= 0'
'    %  힘이 작으면 그 방향은 뜻을 잃는다 — 마지막 값을 붙들고 있는다.'
'    %  Too small a force has no meaningful direction: keep the last one.'
'    if f > e_min, psi_last = atan2(f_e, f_n); end'
'    psi_d = psi_last;'
'else'
'    %  문제 1: 선수각을 고정한다. f 가 뱃머리와 직각이면 한 뉴턴도 낼 수 없다.'
'    %  Problem 1 fixes the heading: when f lies across the bow, none of it'
'    %  can be made, and that is not the controller''s fault.'
'    psi_d = psi_fix*pi/180;'
'end'
'%'
'%  ── 문제 3) 이동 중이면 / in transit ──────────────────────────────────'
'if mode == 1, psi_d = atan2(e_e, e_n); end'
'%'
'%  ── 문제 1b) 뱃머리 방향의 성분만 추진기로 / only the along-bow part ──'
'%     X 는 f 를 뱃머리에 정사영한 것이다. 옆 성분은 아무도 낼 수 없고,'
'%     그것이 1번 문제가 재는 양이다.'
'X = f_n*cos(psi) + f_e*sin(psi);'
'if mode == 1'
'    X = X_ff;                                   % 이동 중에는 일정한 추진력'
'    if hand_over ~= 0, In = 0;  Ie = 0; end     % 유지를 깨끗한 적분으로 시작'
'end'
'X = min(max(X, -X_max), X_max);'
'%  적분은 힘이 한계에 있지 않을 때만 쌓는다 (2주차 §2-11)'
'%  Integrate only while there is room — the anti-windup of Week 2'
'if abs(X) < X_max - 1e-9'
'    In = In + h*Ki_x*e_n;'
'    Ie = Ie + h*Ki_x*e_e;'
'end'
'%'
'%  ── 요 모멘트: 4주차의 오토파일럿 그대로 / the Week 4 autopilot ───────'
'ee = atan2(sin(psi_d - psi), cos(psi_d - psi));'
'N  = Kp*ee - Kd*r;'
'N  = min(max(N, -N_max), N_max);'
'if mode == 3, X = 0;  N = 0; end                % 끝 / done'
'psi_d_out = psi_d*180/pi;'
};
end
