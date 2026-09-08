function w04_lab_vessel(mdl, x0)
%W04_LAB_VESSEL  The Week 3 vessel, given to the Week 4 laboratory.
%
%   w04_lab_vessel(mdl, x0)
%
%     mdl   model that already exists
%     x0    left edge of the chain on the canvas [px]
%
%   Builds  Heading autopilot -> Control allocation -> Otter USV -> logs,
%   with psi (state 12) and r (state 6) fed back to the autopilot as tags.
%   The autopilot's psi_d inport is left for the caller to wire.
%
%   WHY THIS IS A SHARED FUNCTION AND NOT COPIED TWICE
%
%   The starting model and the reference solution must contain the SAME
%   vessel, or a difference in the result could come from the vessel rather
%   than from the guidance. One function, called by both, makes that
%   impossible. It is the same reason the lecture's four guidance laws share
%   one autopilot bank.
%
%   THE LAW IS WEEK 3'S, UNCHANGED
%
%       tau_N = Kp ssa(psi_d - psi) - Kd r
%
%   That it needs no modification at all to accept a command from guidance
%   rather than from a human is the practical content of "guidance and
%   control are separate layers".
%
%   See also W04_P1_START, W04_S1_LOS.

%% ---- heading autopilot -------------------------------------------------
c = add_subsys(mdl, 'Heading autopilot', [x0 130 x0+150 250], ...
               {'psi_d','psi','r'}, {'tau_N'}, gnc_colour('controller'));
blk = [c '/law'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[240 60 420 220]);
set_mlfcn(blk, { ...
'function tau_N = law(psi_d, psi, r, Kp, Kd)'
'%#codegen'
'%LAW  Week 3''s heading autopilot, unchanged.'
'%'
'%  tau_N = Kp ssa(psi_d - psi) - Kd r'
'%'
'%  The wrap is not optional here: guidance produces commands anywhere in'
'%  (-pi, pi], so the +-180 deg seam is crossed on almost every mission.'
'e = mod(psi_d - psi + pi, 2*pi) - pi;'
'tau_N = Kp*e - Kd*r;'}, 'tau_N', '[1 1]');
%  The three inports sit at centres 80, 120 and 160. Constants at 108+42i put
%  Kp's centre on 162, two pixels from the r row, and the two lines overlap.
%  Start the ladder below the last inport instead.
KK = {'Kp','Kd'};
for i = 1:numel(KK)
    add_block('simulink/Sources/Constant', [c '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 130+42*i 150 154+42*i]);
    add_line(c, [KK{i} '/1'], sprintf('law/%d', i+3), 'autorouting','smart');
end
add_line(c, 'psi_d/1', 'law/1', 'autorouting','smart');
add_line(c, 'psi/1',   'law/2', 'autorouting','smart');
add_line(c, 'r/1',     'law/3', 'autorouting','smart');
add_line(c, 'law/1',   'tau_N/1', 'autorouting','smart');
set_param([c '/psi_d'], 'Position',[40  70  70  90]);
set_param([c '/psi'],   'Position',[40 110  70 130]);
set_param([c '/r'],     'Position',[40 150  70 170]);

%% ---- control allocation ------------------------------------------------
a = add_subsys(mdl, 'Control allocation', [x0+210 140 x0+360 240], ...
               {'tau_N','X_ff'}, {'n'}, gnc_colour('allocation'));
blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[250 60 420 220]);
set_mlfcn(blk, { ...
'function n = allocation(tau_N, X_ff, k_pos, k_neg, n_max, n_min, y_pont)'
'%#codegen'
'% Demanded surge force and yaw moment to two shaft speeds. Appendix A1.'
'T = [X_ff/2 + tau_N/(2*y_pont);'
'     X_ff/2 - tau_N/(2*y_pont)];'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        ni =  sqrt( T(i) / k_pos);'
'    else'
'        ni = -sqrt(-T(i) / k_neg);'
'    end'
'    n(i) = min(max(ni, n_min), n_max);'
'end'
'end'}, 'n', '[2 1]');
%  Offset so that no constant's centre lands on an inport row (90 or 140).
KA = {'k_pos','k_neg','n_max','n_min','y_pont'};
for i = 1:numel(KA)
    add_block('simulink/Sources/Constant', [a '/' KA{i}], ...
              'Value', KA{i}, 'Position', [90 78+34*i 150 102+34*i]);
    add_line(a, [KA{i} '/1'], sprintf('allocation/%d', i+2), 'autorouting','smart');
end
add_block('simulink/Math Operations/Reshape', [a '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[470 118 510 162]);
add_line(a, 'tau_N/1',     'allocation/1', 'autorouting','smart');
add_line(a, 'X_ff/1',      'allocation/2', 'autorouting','smart');
add_line(a, 'allocation/1','as vector/1',  'autorouting','smart');
add_line(a, 'as vector/1', 'n/1',          'autorouting','smart');
set_param([a '/tau_N'], 'Position',[ 40  80  70 100]);
set_param([a '/X_ff'],  'Position',[ 40 130  70 150]);

add_block('simulink/Sources/Constant', [mdl '/X_ff'], ...
          'Value','X_ff', 'Position',[x0+120 300 x0+180 330]);

%% ---- hull and logs -----------------------------------------------------
add_otter_plant(mdl, 'Otter USV', [x0+430 140 x0+620 250], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[x0+690 155 x0+760 195]);

add_line(mdl, 'Heading autopilot/1', 'Control allocation/1', 'autorouting','smart');
add_line(mdl, 'X_ff/1',              'Control allocation/2', 'autorouting','smart');
add_line(mdl, 'Control allocation/1','Otter USV/1',          'autorouting','smart');
add_line(mdl, 'Otter USV/1',         'xlog/1',               'autorouting','smart');

%% ---- the two feedbacks, as tags ---------------------------------------
add_block('simulink/Signal Routing/Selector', [mdl '/psi'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','12', ...
          'InputPortWidth','12', 'Position',[x0+660 330 x0+710 365]);
add_block('simulink/Signal Routing/Selector', [mdl '/r'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','6', ...
          'InputPortWidth','12', 'Position',[x0+660 390 x0+710 425]);
add_line(mdl, 'Otter USV/1', 'psi/1', 'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'r/1',   'autorouting','smart');

add_block('simulink/Signal Routing/Goto', [mdl '/psi out'], ...
          'GotoTag','psi_fb', 'Position',[x0+740 338 x0+790 358]);
add_block('simulink/Signal Routing/Goto', [mdl '/r out'], ...
          'GotoTag','r_fb',   'Position',[x0+740 398 x0+790 418]);
add_block('simulink/Signal Routing/From', [mdl '/psi in'], ...
          'GotoTag','psi_fb', 'Position',[x0-90 195 x0-40 215]);
add_block('simulink/Signal Routing/From', [mdl '/r in'], ...
          'GotoTag','r_fb',   'Position',[x0-90 235 x0-40 255]);
add_line(mdl, 'psi/1',    'psi out/1', 'autorouting','smart');
add_line(mdl, 'r/1',      'r out/1',   'autorouting','smart');
add_line(mdl, 'psi in/1', 'Heading autopilot/2', 'autorouting','smart');
add_line(mdl, 'r in/1',   'Heading autopilot/3', 'autorouting','smart');

%  Position is what guidance needs, so it is published as a tag too.
add_block('simulink/Signal Routing/Selector', [mdl '/pos'], ...
          'IndexOptions','Index vector (dialog)', 'Indices','[7 8]', ...
          'InputPortWidth','12', 'Position',[x0+660 450 x0+710 485]);
add_block('simulink/Signal Routing/Goto', [mdl '/pos out'], ...
          'GotoTag','pos_fb', 'Position',[x0+740 458 x0+790 478]);
add_line(mdl, 'Otter USV/1', 'pos/1',     'autorouting','smart');
add_line(mdl, 'pos/1',       'pos out/1', 'autorouting','smart');
end
