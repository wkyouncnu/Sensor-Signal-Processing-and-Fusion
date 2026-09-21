function W04_S1_heading_loop(mdl)
%W04_S1_HEADING_LOOP  4주차 세 문제를 모두 푸는 하나의 모델.
%                     Solution to all three Week 4 problems in one model.
%
%   >> W04_S1_heading_loop      W04_S1.slx 를 만든다 / builds W04_S1.slx
%   >> W04_check(1,'W04_S1')    1, 2, 3 을 차례로 / and 2, and 3
%
%   제어법칙 / the law — 강의 모델과 같은 식 / the same as the lecture's models
%
%       e     = ssa(psi_d - psi)       (use_ssa = 0 이면 감지 않음 / raw when use_ssa = 0)
%       tau_N = Kp e + Ki int(e) + Kd Nf s/(s + Nf) e
%
%   세 문제가 한 모델인 이유: 문제 1 은 Kd = 0, 문제 2 는 Kd > 0, 문제 3 은 use_ssa 만
%   바꾼다. 게인이 이름이므로 체커가 값을 넣어 한 모델로 셋을 모두 돌린다.
%   One model for three problems: problem 1 is Kd = 0, problem 2 Kd > 0, problem 3
%   changes only use_ssa. The gains are names, so the checker sets them.

if nargin < 1 || isempty(mdl), mdl = 'W04_S1'; end
here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end
new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
               'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
Y = 150;
P = @(name, lib, pos, varargin) add_block(lib, [mdl '/' name], 'Position', pos, varargin{:});
L = @(a, b) add_line(mdl, a, b, 'autorouting','smart');

P('step', 'simulink/Sources/Step', [30 Y-15 60 Y+15], 'Time','t_step', 'Before','0', 'After','psi_step');
P('deg to rad', 'simulink/Math Operations/Gain', [100 Y-18 150 Y+18], 'Gain','pi/180');
add_sum(mdl, 'e', '+-', [200 Y]);
P('ssa', 'simulink/User-Defined Functions/Fcn', [240 Y-15 300 Y+15], 'Expr','atan2(sin(u), cos(u))');
P('use_ssa', 'simulink/Sources/Constant', [250 Y+40 300 Y+60], 'Value','use_ssa');
P('which error', 'simulink/Signal Routing/Switch', [340 Y-20 370 Y+20], ...
  'Criteria','u2 > Threshold', 'Threshold','0.5');
P('Kp', 'simulink/Math Operations/Gain', [430 Y-78 480 Y-42], 'Gain','Kp');
P('D filter', 'simulink/Continuous/Transfer Fcn', [430 Y-18 490 Y+18], 'Numerator','[Kd*Nf 0]', 'Denominator','[1 Nf]');
P('Ki', 'simulink/Math Operations/Gain', [430 Y+42 480 Y+78], 'Gain','Ki');
P('I', 'simulink/Continuous/Integrator', [510 Y+45 540 Y+75]);
P('sum', 'simulink/Math Operations/Sum', [580 Y-20 600 Y+20], 'Inputs','+++', 'IconShape','rectangular');
L('step/1', 'deg to rad/1');  L('deg to rad/1', 'e/1');
L('e/1', 'ssa/1');  L('ssa/1', 'which error/1');  L('use_ssa/1', 'which error/2');  L('e/1', 'which error/3');
L('which error/1', 'Kp/1');  L('which error/1', 'D filter/1');  L('which error/1', 'Ki/1');
L('Ki/1', 'I/1');  L('Kp/1', 'sum/1');  L('D filter/1', 'sum/2');  L('I/1', 'sum/3');

add_alloc(mdl, [660 110 820 210]);
P('X_ff', 'simulink/Sources/Constant', [600 200 640 220], 'Value','X_ff');
add_otter_plant(mdl, 'Otter USV', [880 110 1060 220], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
L('sum/1', 'Control allocation/1');  L('X_ff/1', 'Control allocation/2');
L('Control allocation/1', 'Otter USV/1');
P('xlog', 'simulink/Sinks/To Workspace', [1120 100 1190 130], 'VariableName','xlog', 'SaveFormat','Structure With Time');
P('psi', 'simulink/Signal Routing/Selector', [1120 180 1160 210], 'Indices','12', 'InputPortWidth','12');
L('Otter USV/1', 'xlog/1');  L('Otter USV/1', 'psi/1');
P('Goto psi', 'simulink/Signal Routing/Goto', [1190 185 1240 205], 'GotoTag','psi_fb');
P('From psi', 'simulink/Signal Routing/From', [120 Y+60 170 Y+80], 'GotoTag','psi_fb');
L('psi/1', 'Goto psi/1');  L('From psi/1', 'e/2');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({'SOLUTION  -  ALL THREE WEEK 4 PROBLEMS IN ONE MODEL', '', ...
  '   e = ssa(psi_d - psi),   tau_N = Kp e + Ki int(e) + Kd Nf s/(s + Nf) e', '', ...
  'PROBLEM 1   Kd = 0: no error at any gain; overshoot grows with Kp.', ...
  'PROBLEM 2   Kd > 0: the derivative damps the heading; overshoot falls.', ...
  'PROBLEM 3   use_ssa = 1 turns 20 deg through the seam; 0 turns 340 deg.'}, newline);
a.Position = [40 300 700 400];  a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end

% =========================================================================
function add_alloc(mdl, pos)
a = add_subsys(mdl, 'Control allocation', pos, {'tau_N','X_ff'}, {'n'}, ...
               gnc_colour('allocation'));
blk = [a '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[250 60 420 220]);
set_mlfcn(blk, { ...
'function n = allocation(tau_N, X_ff, k_pos, k_neg, n_max, n_min, y_pont)'
'%#codegen'
'% Demanded surge force and yaw moment to two shaft speeds.'
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
%  Constants at 60+34i put k_neg's centre on y = 140, which is exactly where
%  the X_ff inport feeds the block: check_overlaps found the two drawn on top
%  of each other. Offsetting the ladder moves every constant off both inport
%  rows (90 and 140).
KK = {'k_pos','k_neg','n_max','n_min','y_pont'};
for i = 1:numel(KK)
    add_block('simulink/Sources/Constant', [a '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 78+34*i 150 102+34*i]);
    add_line(a, [KK{i} '/1'], sprintf('allocation/%d', i+2), 'autorouting','smart');
end
add_block('simulink/Math Operations/Reshape', [a '/as vector'], ...
          'OutputDimensionality','1-D array', 'Position',[470 118 510 162]);
add_line(a, 'tau_N/1',     'allocation/1', 'autorouting','smart');
add_line(a, 'X_ff/1',      'allocation/2', 'autorouting','smart');
add_line(a, 'allocation/1','as vector/1',  'autorouting','smart');
add_line(a, 'as vector/1', 'n/1',          'autorouting','smart');
set_param([a '/tau_N'], 'Position',[ 40  80  70 100]);
set_param([a '/X_ff'],  'Position',[ 40 130  70 150]);
end
