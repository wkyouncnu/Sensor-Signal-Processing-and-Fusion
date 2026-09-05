function W01_1_build_openloop()
%W01_1_BUILD_OPENLOOP  Generate W01_openloop.slx from code.
%
%   >> W01_1_build_openloop
%
%   THE SIGNAL CHAIN
%
%   Every model in this course is laid out left to right in the same stages,
%   in the order used by the MSS demonstration models
%   (Tools/MSS/SIMULINK/mssSimulinkDemos/demoOtterUSVHeadingControl.slx):
%
%     command -> [reference] -> [controller] -> [allocation] -> plant -> measurement
%
%   Week 1 has no controller and no allocation, because there is no loop yet.
%   The stages that do exist keep their standard positions, so the plant sits
%   where the plant sits in every other week of the course.
%
%     [ Manoeuvre command ] --> n --> [ Otter USV ] --> x (12) --> [ Measurements ]
%       straight, port, starboard        otter.m, unchanged
%
%   THE MANOEUVRE
%
%   The command is a function of time, not a constant: run straight, turn to
%   port, run straight, turn to starboard, run straight. Both propellers turn
%   ahead throughout - nothing goes astern - and the turns are made by a small
%   difference between them.
%
%   A single constant command cannot show what this week is about. A straight
%   run alone never separates heading from course, and never exercises the
%   rotation matrix, because psi never changes. The S-shape does both, and it
%   is also the first thing anyone would drive a real USV through.
%
%   Setting dn = 0 in W01_0_setup.m collapses the manoeuvre back to a constant
%   command, which is how section C performs its terminal-speed sweep.
%
%   Each stage is a subsystem. The top level shows the chain and nothing else;
%   everything that makes a stage work lives inside it.
%
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

add_line(cmd, 'Clock/1', 'schedule/1', 'autorouting','smart');
for i = 1:numel(K)
    add_line(cmd, [K{i} '/1'], sprintf('schedule/%d', i+1), 'autorouting','smart');
end
add_line(cmd, 'schedule/1', 'n/1', 'autorouting','smart');

%% ---- 5. plant ----------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% ---- 6. measurement ----------------------------------------------------
add_measurement(m, P.measurement, 'W01');

%% ---- wiring ------------------------------------------------------------
L = @(a,b) add_line(m, a, b, 'autorouting','smart');
L('Manoeuvre command/1', 'Otter USV/1');
L('Otter USV/1',         'Measurements/1');

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
