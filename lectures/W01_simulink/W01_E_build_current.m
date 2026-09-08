function W01_E_build_current()
%W01_E_BUILD_CURRENT  Generate W01_current.slx — what an ocean current does.
%
%   >> W01_E_build_current
%
%   WHY A SECOND MODEL
%
%   W01_openloop.slx answers "what does a propeller command do". This one
%   answers "what does the WATER do", and it is the first model in the course
%   in which the vessel goes somewhere it was never told to go.
%
%   The command is the simplest possible: both propellers at n0, held for the
%   whole run, no steering. With still water the track is a straight line to
%   the north. Switch the current on and it is not.
%
%   THE CHAIN
%
%     Speed command --> [ Otter USV ] --> x (12) --> [ Measurements ]
%                            ^
%                            |  V_c, beta_c
%                     [ Ocean current ]  <-- computes what the plant does
%                                            internally, so it can be SEEN
%
%   The plant already takes V_c and beta_c; otter.m does the work. The Ocean
%   current stage does not drive anything - it recomputes the same two lines
%   otter.m runs on line 79-81 and logs them, so the relative velocity that
%   the hydrodynamics actually feels becomes a signal on the diagram instead
%   of a hidden intermediate.
%
%   WHAT otter.m DOES WITH THE CURRENT   (lines 79-81, then 184-203)
%
%     u_c  = V_c cos(beta_c - psi)        the current, rotated into the body
%     v_c  = V_c sin(beta_c - psi)        frame; psi is the vessel's heading
%     nu_r = nu - [u_c v_c 0 0 0 0]'      relative (through-the-water) velocity
%
%   and then, crucially:
%
%     tau_damp, tau_crossflow, C   all use  nu_r     <- forces feel the WATER
%     the kinematics  J * nu       uses     nu       <- position moves over GROUND
%
%   That split is the whole physics. A vessel is pushed sideways by a current
%   without any sideways force acting on it, because the force balance and the
%   position integral are written in different velocities.
%
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
                struct('weekName', 'input n  and  current'));

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
