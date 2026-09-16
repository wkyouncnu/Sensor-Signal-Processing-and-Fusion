function W01_E_build_current()
%W01_E_BUILD_CURRENT  조류 실험용 모델 W01_current.slx 를 코드로 생성한다.
%                     Generate W01_current.slx — the model in which the water moves.
%
%   실행 / to run
%       W01_E_build_current
%
%   강의에서의 위치 / place in the lecture
%       Part 2 절 E 가 쓰는 모델이며, Part 1 §1-13 의 유도를 눈으로 볼 수 있게
%       만든 것이다.
%       This is the model used by section E of Part 2, built so that the
%       derivation of §1-13 in Part 1 can be seen rather than only read.
%
%   왜 모델이 하나 더 필요한가 / why a second model
%       W01_openloop.slx 는 "프로펠러 명령이 무엇을 하는가" 에 답한다. 이 모델은
%       "물이 무엇을 하는가" 에 답하며, 선박이 한 번도 지시받지 않은 곳으로 가는
%       이 강의 최초의 모델이다.
%
%       명령은 가능한 한 단순하게 둔다. 두 프로펠러를 모두 n0 으로 놓고 실행이
%       끝날 때까지 유지하며 조향은 하지 않는다. 잔잔한 물에서는 궤적이 북쪽으로
%       곧게 뻗는다. 조류를 켜면 그렇지 않다.
%
%       W01_openloop.slx answers the question of what a propeller command
%       does. This model answers what the water does, and it is the first
%       model in the course in which the vessel goes somewhere it was never
%       told to go. The command is as simple as it can be: both propellers at
%       n0, held for the whole run, no steering. In still water the track is a
%       straight line to the north. With the current switched on it is not.
%
%   신호의 흐름 / the chain
%
%     Speed command --> [ Otter USV ] --> x (12) --> [ Measurements ]
%                            ^
%                            |  V_c, beta_c
%                     [ Ocean current ]  <-- 플랜트가 내부에서 하는 계산을
%                                            밖으로 꺼내 보이기 위한 단계
%
%       플랜트는 이미 V_c 와 beta_c 를 받으며, 계산은 otter.m 이 한다. Ocean
%       current 단계는 아무것도 구동하지 않는다. otter.m 이 79~81 행에서 수행하는
%       것과 같은 계산을 다시 하고 그 결과를 기록할 뿐이며, 그렇게 해야 유체력이
%       실제로 느끼는 상대속도가 숨은 중간값이 아니라 도면 위의 신호가 된다.
%
%       The plant already accepts V_c and beta_c, and otter.m does the work.
%       The Ocean current stage drives nothing: it repeats the computation
%       otter.m performs on lines 79-81 and logs it, so that the relative
%       velocity the hydrodynamics actually feels appears as a signal on the
%       diagram instead of remaining a hidden intermediate.
%
%   otter.m 이 조류를 다루는 방식 / what otter.m does with the current
%   (79~81 행, 그리고 184~203 행)
%
%     u_c  = V_c cos(beta_c - psi)        조류를 선체고정좌표계로 회전시킨 것.
%     v_c  = V_c sin(beta_c - psi)        psi 는 선박의 선수방위이다.
%     nu_r = nu - [u_c v_c 0 0 0 0]'      물에 대한 상대속도
%
%   그리고 결정적으로 / and then, crucially:
%
%     tau_damp, tau_crossflow, C  는 모두  nu_r 을 쓴다  <- 힘은 물을 느낀다
%     운동학  J * nu              는       nu  를 쓴다   <- 위치는 지면 위에서 움직인다
%
%       이 갈라짐이 물리의 전부이다. 옆으로 미는 힘이 전혀 없는데도 선박이 옆으로
%       밀려가는 것은, 힘의 균형과 위치의 적분이 서로 다른 속도로 쓰여 있기
%       때문이다.
%
%       That split is the whole of the physics. A vessel is carried sideways
%       by a current without any sideways force acting on it, because the
%       force balance and the position integral are written in two different
%       velocities.
%
%   다시 생성해도 안전하다. 기존 W01_current.slx 는 덮어쓴다.
%   Regenerating is safe: any existing W01_current.slx is overwritten.

m    = 'W01_current';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

P = gnc_chain({'command','reference','plant','measurement'}, ...
              'Height', struct('reference',120, 'measurement',120), 'Y', 120);

%% ---- 1. command --------------------------------------------------------
%  One constant, both propellers equal. Nothing steers in this model.
s = add_subsys(m, 'Speed command', P.command, {}, {'n'}, gnc_colour('command'));
add_block('simulink/Sources/Constant', [s '/n_cmd'], ...
          'Value','[n0; n0]', 'Position',[120 105 175 135]);
set_param([s '/n'], 'Position',[300 113 330 127]);
add_line(s, 'n_cmd/1','n/1','autorouting','on');

%% ---- 2. the current, made visible --------------------------------------
%  Takes the state, returns what otter.m computes internally.
c = add_subsys(m, 'Ocean current', P.reference, {'x'}, {'cur'}, gnc_colour('reference'));
set_param([c '/x'],   'Position',[ 50 113  80 127]);
set_param([c '/cur'], 'Position',[520 113 550 127]);

for i = 1:2
    K = {'V_c','beta_c'};
    add_block('simulink/Sources/Constant', [c '/' K{i}], ...
              'Value', K{i}, 'Position', [50 175+60*i 105 205+60*i]);
end

blk = [c '/current'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[220 80 380 300]);
set_mlfcn(blk, { ...
'function cur = current(x, V_c, beta_c)'
'%#codegen'
'%CURRENT  The two lines otter.m runs on its lines 79-81, made visible.'
'%'
'%  A current is given in NED by a speed and a direction. The hull does not'
'%  feel NED; it feels water flowing past it. So the current is rotated into'
'%  the body frame by the vessel''s own heading before it is subtracted.'
'%'
'%    u_c = V_c cos(beta_c - psi)'
'%    v_c = V_c sin(beta_c - psi)'
'%'
'%  beta_c is the direction the water FLOWS TOWARDS, measured from north.'
'%  With beta_c = 0 the water sets north; a vessel heading north then has a'
'%  FOLLOWING current and meets less resistance.'
'%'
'%  nu_r is what every hydrodynamic term in otter.m is evaluated at. nu is'
'%  what the kinematics integrates. The gap between them is the drift.'
'psi = x(12);'
'u   = x(1);'
'v   = x(2);'
''
'u_c = V_c * cos(beta_c - psi);'
'v_c = V_c * sin(beta_c - psi);'
''
'u_r = u - u_c;'
'v_r = v - v_c;'
''
'cur = [u_c; v_c; u_r; v_r];'}, 'cur', '[4 1]');

add_line(c, 'x/1',      'current/1', 'autorouting','on');
add_line(c, 'V_c/1',    'current/2', 'autorouting','on');
add_line(c, 'beta_c/1', 'current/3', 'autorouting','on');
add_line(c, 'current/1','cur/1',     'autorouting','on');

note_in(c, [50 330 560 470], strjoin({ ...
'THE CURRENT ENTERS AS A VELOCITY, NOT AS A FORCE'
''
'   u_c = V_c cos(beta_c - psi)      NED current, rotated into the body'
'   v_c = V_c sin(beta_c - psi)      frame by the vessel heading psi'
'   nu_r = nu - nu_c                 velocity through the water'
''
'otter.m evaluates damping, cross-flow drag and Coriolis at nu_r, but'
'integrates the position with nu. Forces feel the water; the track is'
'over the ground. Everything this model shows follows from that.'
''
'This stage drives nothing. It recomputes what the plant already does'
'so that u_r and v_r can be plotted.'}, newline));

%% ---- 3. plant ----------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% ---- 4. measurement ----------------------------------------------------
%  log = [u v r N E psi | nL nR | u_c v_c u_r v_r]
%
%  The command occupies columns 7 and 8 here exactly as it does in the
%  open-loop model, so W01_read.m can name the two shaft speeds the same way
%  in both. Putting the current's four columns after them, rather than at 7,
%  is the only reason the reader does not need to know which model produced
%  the log.
add_measurement(m, P.measurement, 'W01c', {'n','cur'}, ...
                struct('dash', true, 'weekName', 'input n  and  current'));

%% ---- wiring ------------------------------------------------------------
L = @(a,b) add_line(m, a, b, 'autorouting','smart');
L('Speed command/1', 'Otter USV/1');
L('Otter USV/1',     'Measurements/1');
L('Speed command/1', 'Measurements/2');
L('Otter USV/1',     'Ocean current/1');
L('Ocean current/1', 'Measurements/3');

%% ---- what the model is for ---------------------------------------------
note(m, [40 330 860 700], strjoin({ ...
'WEEK 1  -  WHAT AN OCEAN CURRENT DOES TO AN OPEN LOOP'
''
'The command never changes: both propellers at n0, no steering, for the'
'whole run. Only the water changes between runs.'
''
'   V_c      current speed        [m/s]'
'   beta_c   current direction    [rad from north, the way the water GOES]'
''
'HOW IT ENTERS THE MODEL   (otter.m lines 79-81)'
''
'   u_c  = V_c cos(beta_c - psi)'
'   v_c  = V_c sin(beta_c - psi)'
'   nu_r = nu - [u_c v_c 0 0 0 0]'''
''
'The current is rotated into the BODY frame first, because the hull feels'
'water flowing past it, not a compass direction. Then:'
''
'   damping, cross-flow drag, Coriolis   evaluated at nu_r'
'   kinematics  eta_dot = J(eta) nu      evaluated at nu'
''
'WHAT TO EXPECT'
''
'1  NO CURRENT.  The track is a straight line north. Y is structurally'
'   zero and nothing turns the vessel.'
''
'2  FOLLOWING or HEAD CURRENT (beta_c = 0 or 180 deg).  Still straight,'
'   but faster or slower over the ground. The vessel never notices - its'
'   speed THROUGH THE WATER is unchanged at settle.'
''
'3  BEAM or OBLIQUE CURRENT.  The track is no longer the heading. The'
'   vessel is pushed sideways with no sideways force, and the cross-flow'
'   drag on the now non-zero v_r produces a yaw moment that slowly turns'
'   the hull into the flow. Nothing commanded either.'
''
'Edit V_c and beta_c in W01_0_setup.m, or run W01_E_current_run for all.'}, newline));

set_param(m, 'StopFcn', 'W01_cur_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

mss_style(m);
save_system(m, out);

%  The block diagram belongs to the builder: it changes when the model changes
%  and not when a gain does. Exporting it here keeps it in step with the model.
export_diagram(m, fullfile(here, 'img'));
close_system(m, 0);
fprintf('  built  %s\n', out);
end

% -------------------------------------------------------------------------
function note(m, pos, txt)
h = Simulink.Annotation([m '/note']);
h.Text = txt;  h.Position = pos;
h.HorizontalAlignment = 'left';  h.BackgroundColor = 'lightBlue';
end

function note_in(sub, pos, txt)
h = Simulink.Annotation([sub '/note']);
h.Text = txt;  h.Position = pos;
h.HorizontalAlignment = 'left';  h.BackgroundColor = 'white';
end
