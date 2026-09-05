function add_otter_plant(mdl, name, pos, cfg)
%ADD_OTTER_PLANT  Insert the Otter USV motion model as a Simulink subsystem.
%
%   add_otter_plant(mdl, name, pos, cfg)
%
%     mdl   model name, already created with new_system
%     name  subsystem name, e.g. 'Otter plant'
%     pos   [x1 y1 x2 y2]
%     cfg   struct from otter_config; defaults to otter_config('base')
%
%   INTERFACE
%
%     cfg.input_mode = 'n'   Inport  1 : n   shaft speeds, cfg.n_thr x 1
%     cfg.input_mode = 'f'   Inport  1 : f   extended thrust vector
%                            Outport 1 : x   12 states
%
%   The hull is Fossen's otter.m from Tools/MSS/VESSELS, called UNCHANGED.
%   It is not written for code generation, so the call is declared extrinsic
%   and Simulink hands it back to MATLAB. The consequence is that the output
%   must be pre-sized, which is why the wrapper writes
%
%       xdot = zeros(12,1);
%       xdot = otter(...);
%
%   The state is produced by the integrator and fed back into the derivative
%   block. The integrator breaks the loop, so this is not an algebraic loop.
%
%   STATE VECTOR (otter.m, 12 x 1)
%
%       x = [ u v w p q r  x y z  phi theta psi ]'
%           |__ velocities in {b} __||_ position _||_ Euler angles _|
%
%   The integrator initial condition reads the base workspace variable x0, so
%   a script can start the vessel anywhere without rebuilding the model.
%
%   See also OTTER_CONFIG, OTTER_B.

if nargin < 4 || isempty(cfg),  cfg  = otter_config('base'); end
if nargin < 3 || isempty(pos),  pos  = [400 100 620 240];   end
if nargin < 2 || isempty(name), name = 'Otter plant';       end

switch cfg.input_mode
    case 'n', in_name = 'n';
    case 'f', in_name = 'f';
    otherwise, error('add_otter_plant:mode','cfg.input_mode must be ''n'' or ''f''.');
end

sub = [mdl '/' name];
add_block('built-in/Subsystem', sub, 'Position', pos);
clear_subsystem(sub);

%% ---- ports --------------------------------------------------------------
add_block('simulink/Sources/In1', [sub '/' in_name], 'Position',[ 40 143  70 157]);
add_block('simulink/Sinks/Out1',  [sub '/x'],        'Position',[700 143 730 157]);

%% ---- payload and current, read from the base workspace -----------------
K = {'mp','rp','V_c','beta_c'};
for i = 1:numel(K)
    add_block('simulink/Sources/Constant', [sub '/' K{i}], ...
              'Value', K{i}, 'Position', [40 200+40*i 150 226+40*i]);
end

%% ---- the hull -----------------------------------------------------------
blk = [sub '/Otter hull'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[330 100 520 340]);
set_mlfcn(blk, { ...
'function xdot = otter_hull(x, u_thr, mp, rp, V_c, beta_c)'
'% Fossen''s otter.m, called unchanged from Tools/MSS/VESSELS.'
'%'
'%   x       12 states, fed back from the integrator'
'%   u_thr   propeller shaft speeds [rad/s]'
'%'
'% otter.m is not written for code generation, so the call is extrinsic and'
'% xdot has to be pre-sized for Simulink to know the output width.'
'coder.extrinsic(''otter'');'
''
'xdot = zeros(12,1);'
'xdot = otter(x, u_thr, mp, rp, V_c, beta_c);'
'end'}, 'xdot', '[12 1]');

%% ---- integrator ---------------------------------------------------------
add_block('simulink/Continuous/Integrator', [sub '/states'], ...
          'InitialCondition','x0', 'Position',[580 132 615 168]);

%% ---- state feedback, through a tag so no line crosses the canvas -------
add_block('simulink/Signal Routing/Goto', [sub '/Go_x'], ...
          'GotoTag','x_state', 'Position',[650 137 700 163]);
add_block('simulink/Signal Routing/From', [sub '/Fr_x'], ...
          'GotoTag','x_state', 'Position',[240 107 290 133]);

%% ---- wiring -------------------------------------------------------------
L = @(a,b) add_line(sub, a, b, 'autorouting','smart');
L('Fr_x/1',        'Otter hull/1');
L([in_name '/1'],  'Otter hull/2');
for i = 1:numel(K), L([K{i} '/1'], sprintf('Otter hull/%d', i+2)); end
L('Otter hull/1',  'states/1');
L('states/1',      'Go_x/1');
L('states/1',      'x/1');

Simulink.BlockDiagram.arrangeSystem(sub);
end

% -------------------------------------------------------------------------
function clear_subsystem(sub)
b = find_system(sub, 'SearchDepth',1, 'LookUnderMasks','all', 'Type','Block');
for i = 1:numel(b)
    if ~strcmp(b{i}, sub), delete_block(b{i}); end
end
end
