function W01_1_build_openloop()
%W01_1_BUILD_OPENLOOP  개루프 모델 W01_openloop.slx 를 코드로 생성한다.
%                      Generate the open-loop model W01_openloop.slx from code.
%
%   실행 / to run
%       W01_1_build_openloop
%
%   강의에서의 위치 / place in the lecture
%       Part 2 의 절 B 이다. 이번 주 실습이 쓰는 모델을 만드는 자리이며,
%       모델을 손으로 그리지 않고 스크립트로 만드는 이유도 여기서 설명된다.
%       This is section B of Part 2. It produces the model used by the rest of
%       the week, and is where the practice of generating models by script
%       rather than drawing them by hand is introduced.
%
%   신호의 흐름 / the signal chain
%       이 강의의 모든 모델은 MSS 데모 모델
%       (Tools/MSS/SIMULINK/mssSimulinkDemos/demoOtterUSVHeadingControl.slx)
%       과 같은 순서로, 왼쪽에서 오른쪽으로 배치한다.
%
%         command -> [reference] -> [controller] -> [allocation] -> plant -> measurement
%
%       1주차에는 되먹임 고리가 아직 없으므로 controller 와 allocation 단계가
%       비어 있다. 그러나 남은 단계들은 표준 위치를 그대로 지키므로, 플랜트는
%       다른 모든 주차에서와 같은 자리에 놓인다. 매주 같은 자리에서 같은 것을
%       찾을 수 있게 하려는 것이다.
%
%       Every model in this course is laid out left to right in the stages
%       above, in the order used by the MSS demonstration models. Week 1 has
%       no controller and no allocation because there is no loop yet, but the
%       stages that do exist keep their standard positions, so the plant sits
%       where the plant sits in every other week.
%
%         [ Manoeuvre command ] --> n --> [ Otter USV ] --> x (12) --> [ Measurements ]
%           직진·좌선회·우선회                otter.m 를 고치지 않고 그대로
%
%   기동의 내용 / the manoeuvre
%       명령은 상수가 아니라 시간의 함수이다. 직진 — 좌선회 — 직진 — 우선회 —
%       직진의 순서로 S 자를 그린다. 두 프로펠러 모두 전진 방향으로만 돌고,
%       선회는 둘 사이의 작은 회전수 차이로 만든다.
%
%       상수 명령 하나로는 이번 주의 주제를 보일 수 없다. 직진만 해서는 psi 가
%       변하지 않으므로 선수방위와 침로가 갈라지지 않고, 회전행렬도 쓰이지
%       않는다. S 자 기동은 그 둘을 모두 드러내며, 실제 무인수상정을 처음
%       물에 띄웠을 때 시켜 보는 기동이기도 하다.
%
%       The command is a function of time rather than a constant: straight,
%       port, straight, starboard, straight. Both propellers turn ahead
%       throughout, and the turns are made by a small difference between them.
%       A single constant command could not show what this week is about: with
%       psi held fixed, heading is never separated from course and the
%       rotation matrix is never exercised. The S-shape does both, and is also
%       the first manoeuvre anyone would drive a real USV through.
%
%       W01_0_setup 에서 dn = 0 으로 두면 이 기동은 상수 명령으로 되돌아간다.
%       절 C 의 종단속도 스윕이 바로 그 상태를 쓴다.
%       Setting dn = 0 in W01_0_setup collapses the manoeuvre back to a
%       constant command, which is the state section C sweeps in.
%
%   모델의 구조 / how the model is organised
%       각 단계는 서브시스템이다. 최상위 화면에는 사슬만 보이고, 각 단계를
%       실제로 동작시키는 것들은 모두 그 안에 들어 있다.
%       Each stage is a subsystem. The top level shows the chain and nothing
%       else; everything that makes a stage work lives inside it.
%
%   다시 생성해도 안전하다. 기존 W01_openloop.slx 는 덮어쓴다.
%   Regenerating is safe: any existing W01_openloop.slx is overwritten.

m    = 'W01_openloop';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));                 % ...\GradCourse
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

%% ---- the chain: command -> plant -> measurement -------------------------
P = gnc_chain({'command','plant','measurement'});

%% ---- 1. command --------------------------------------------------------
%  A stage, not a Constant block, because the command now depends on time.
%  Inside: Clock -> MATLAB Function -> n. Nothing else.
cmd = add_subsys(m, 'Manoeuvre command', P.command, {}, {'n'}, gnc_colour('command'));

add_block('simulink/Sources/Clock', [cmd '/Clock'], 'Position',[40 44 60 64]);
add_block('simulink/User-Defined Functions/MATLAB Function', [cmd '/schedule'], ...
          'Position',[190 30 330 170]);

%  The tunable numbers arrive as Constant blocks, exactly as mp, rp, V_c and
%  beta_c do in the plant stage. A MATLAB Function block created from code does
%  not acquire workspace parameters on its own, and wiring them in also puts
%  them on the canvas where they can be seen.
K = {'n0','dn','t_phase'};
for i = 1:numel(K)
    add_block('simulink/Sources/Constant', [cmd '/' K{i}], ...
              'Value', K{i}, 'Position', [40 74+40*i 100 104+40*i]);
end

%  The script goes in BEFORE the wiring. A MATLAB Function block created from
%  code has exactly one input until its function signature says otherwise, so
%  schedule/2 does not exist until set_mlfcn has run.
set_mlfcn([cmd '/schedule'], { ...
'function n = schedule(t, n0, dn, t_phase)'
'%#codegen'
'%SCHEDULE  Propeller command as a function of time.'
'%'
'%    straight -> port -> straight -> starboard -> straight'
'%'
'%  Both propellers stay ahead the whole time - nothing is ever reversed.'
'%  A turn is a small DIFFERENCE between the two shaft speeds, because the'
'%  yaw moment is N = y_p (T_left - T_right). More thrust on the left turns'
'%  the bow to starboard, so a PORT turn slows the LEFT propeller.'
'%'
'%  dn = 0 gives a constant command, which is what the terminal-speed sweep'
'%  in section C uses.'
''
'nL = n0;  nR = n0;'
'if t >= t_phase(1) && t < t_phase(2)'
'    nL = n0 - dn;   nR = n0 + dn;      % port      (bow swings to -psi)'
'elseif t >= t_phase(3) && t < t_phase(4)'
'    nL = n0 + dn;   nR = n0 - dn;      % starboard (bow swings to +psi)'
'end'
'n = [nL; nR];'}, 'n', '[2 1]');

%  A MATLAB Function block whose output is written n = [nL; nR] produces a
%  2-by-1 MATRIX signal, not a 2-element vector. The plant does not care, but
%  the log does: a Mux fed one matrix input makes its whole output a matrix,
%  and To Workspace then stores [8 x 1 x nT] instead of the [nT x 8] that the
%  logging contract in add_measurement promises. One Reshape keeps the promise.
add_block('simulink/Math Operations/Reshape', [cmd '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[380 78 420 122]);

add_line(cmd, 'Clock/1', 'schedule/1', 'autorouting','smart');
for i = 1:numel(K)
    add_line(cmd, [K{i} '/1'], sprintf('schedule/%d', i+1), 'autorouting','smart');
end
add_line(cmd, 'schedule/1',  'as vector/1', 'autorouting','smart');
add_line(cmd, 'as vector/1', 'n/1',         'autorouting','smart');

%% ---- 5. plant ----------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% ---- 6. measurement ----------------------------------------------------
%  Two things beyond the course-wide contract, both asked for by the lecturer:
%
%  .dash      the live view becomes ONE window holding the North-East track
%             with the hull drawn on it AND the six states u, v, r, x, y, psi
%             against time, in m, m/s, deg and deg/s, with psi wrapped to
%             (-180, 180]. It is drawn from inside the model by a MATLAB
%             Function block, not by a script run afterwards.
%
%  the input  n is branched into Measurements so it is logged and scoped
%             beside the states it produced. A model whose input is not on
%             screen cannot be read: the turns in u, v and r mean nothing
%             until the two shaft speeds that caused them are visible.
%
%  That leaves TWO scopes, which is the whole set: one for the input and one
%  for the velocities. Position and heading are in the dashboard window, so a
%  third scope would only repeat it.
%  A Simulink block name cannot contain a forward slash, so the scope's unit
%  is spelled out rather than written [rad/s].
add_measurement(m, P.measurement, 'W01', {'n'}, ...
                struct('dash', true, 'weekName', 'input  n  (rad per s)'));

%% ---- wiring ------------------------------------------------------------
L = @(a,b) add_line(m, a, b, 'autorouting','smart');
L('Manoeuvre command/1', 'Otter USV/1');
L('Otter USV/1',         'Measurements/1');
%  The command is branched, not re-generated: the scope must show the very
%  signal the plant received, not a second copy of it that could drift.
L('Manoeuvre command/1', 'Measurements/2');

%% ---- what the model is for ---------------------------------------------
%  Simulink annotations do not wrap at the Position width, so the text is
%  broken by hand. A single long paragraph stretches the exported PNG to
%  several thousand pixels and makes it useless in a document.
note(m, [40 300 800 640], strjoin({ ...
'WEEK 1  -  THE OTTER MOTION MODEL, OPEN LOOP'
''
'No controller and no allocation yet, so two stages of the standard'
'chain are missing. A propeller command enters on the left and twelve'
'states leave on the right. The plant is Fossen''s otter.m from'
'Tools/MSS/VESSELS, called unchanged.'
''
'THE MANOEUVRE   straight - port - straight - starboard - straight'
''
'Both propellers run ahead throughout. A turn is a small DIFFERENCE'
'between them, not a reversal:'
''
'   straight     n = [n0    ; n0   ]'
'   to port      n = [n0-dn ; n0+dn]'
'   to starboard n = [n0+dn ; n0-dn]'
''
'because N = y_p (T_left - T_right). More left thrust turns the bow'
'to starboard. Edit n0, dn and t_phase in W01_0_setup.m.'
''
'WHAT TO WATCH'
''
'1  TERMINAL SPEED.  On the straight legs u settles where thrust'
'   balances linear damping: 2 k_pos n|n| = X_u u.'
''
'2  THE EMPTY SWAY ROW.  Y is zero at every instant, bit for bit.'
'   Both propellers face forward, so no combination of them has a'
'   component across the hull. Geometry, not arithmetic.'
''
'3  SWAY WITHOUT A SIDE FORCE.  v is nevertheless non-zero in both'
'   turns, and changes SIGN between them. It comes from the hull'
'   rotating - the Coriolis term - not from any force Y. That is the'
'   crab angle, and Week 3 has to steer around it.'
''
'4  HEADING IS NOT COURSE.  In each turn the vessel points one way'
'   and travels another. The track alone cannot show this, which is'
'   why the hull is drawn along it.'
''
'THE LIVE VIEW, inside Measurements'
''
'Pressing Run opens a figure that draws the hull, its heading and its'
'track as the simulation proceeds. Set animate = 0 to switch it off.'}, newline));

%% ---- plot when the run finishes ----------------------------------------
%  Pressing Run must produce something to look at without any further command.
%  The Animate block inside Measurements draws the hull live, and StopFcn calls
%  W01_plot, which draws the same summary figure that section D exports.
set_param(m, 'StopFcn', 'W01_plot;');

%  R2024b packs To Workspace results into a single object called out unless
%  this is turned off. Turning it off puts W01 into the base workspace, which
%  is what StopFcn and the plotting scripts expect.
set_param(m, 'ReturnWorkspaceOutputs', 'off');

%  Every block gets the size MSS uses. Measured from the MSS demo models, not
%  invented - see _tools/mss_style.m. Applied last so it catches every block
%  regardless of which helper created it.
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
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end
