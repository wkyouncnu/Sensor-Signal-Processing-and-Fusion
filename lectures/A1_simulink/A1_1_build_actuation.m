function A1_1_build_actuation()
%A1_1_BUILD_ACTUATION  구동 모델 A1_actuation.slx 를 코드로 만든다.
%                      Generate A1_actuation.slx from code.
%
%   실행 / to run
%       A1_1_build_actuation
%
%   신호의 흐름 / the signal chain
%       MSS 데모 모델과 같은 순서로 왼쪽에서 오른쪽으로 놓는다.
%       Left to right, in the order used by the MSS demonstration models:
%
%     Propeller command --> Thrust and B --> Otter USV --> Measurements
%            n              tau = B f          x
%
%   이 부록에는 제어기가 없다 / there is no controller in this appendix
%       가운데 단계는 순수한 구동이다. 축 회전수에서 추력으로, 추력에서 일반화
%       힘으로 가는 계산이며 그것이 이 부록의 주제이다. 같은 명령이 플랜트에도
%       그대로 들어가므로, 가운데 단계의 계산 결과를 선박이 실제로 하는 운동과
%       대조할 수 있다. 계산이 맞는지 계산으로 확인하는 것이 아니라 선체로
%       확인하는 셈이다.
%
%       The middle stage is pure actuation: shaft speed to thrust to
%       generalised force, which is the subject of this appendix. The same
%       command also reaches the plant, so the arithmetic of the middle stage
%       can be checked against what the vessel actually does — the check is
%       made against the hull rather than against more arithmetic.
%
%   다시 생성해도 안전하다. 기존 A1_actuation.slx 는 덮어쓴다.
%   Regenerating is safe: any existing A1_actuation.slx is overwritten.

m    = 'A1_actuation';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();                                   % locates MSS wherever it lives

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', ...
             'FixedStep','h', 'StartTime','0', 'StopTime','T_final');

P = gnc_chain({'command','allocation','plant','measurement'}, ...
              'Height', struct('allocation',120), 'Y', 120);
KK = {'k_pos','k_neg','n_max','n_min'};

%% ---- 1. command --------------------------------------------------------
add_block('simulink/Sources/Constant', [m '/n_cmd'], 'Value','n_cmd', ...
          'Position', P.command + [0 30 0 -30]);

%% ---- 2. thrust and B ---------------------------------------------------
a = add_subsys(m, 'Thrust and B', P.allocation, {'n'}, {'tau'}, ...
               gnc_colour('allocation'));

%  Saturation first, then the thrust curve. The order is not interchangeable:
%  saturating the THRUST would place the reverse limit at a force the
%  propeller can never produce, because k_pos and k_neg differ.
blk = [a '/thruster model'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position',[260 40 430 320]);
set_mlfcn(blk, { ...
'function f = thruster(n, k_pos, k_neg, n_max, n_min)'
'%#codegen'
'% Shaft speed to thrust, one propeller at a time.'
'%'
'%   T = k n|n|,  with k_pos going ahead and k_neg going astern.'
'%'
'% The saturation is applied to n and NOT to T. A propeller is limited by what'
'% the motor can turn, not by the force the naval architect would like.'
'f = zeros(2,1);'
'for i = 1:2'
'    ni = min(max(n(i), n_min), n_max);'
'    if ni >= 0'
'        f(i) = k_pos * ni * abs(ni);'
'    else'
'        f(i) = k_neg * ni * abs(ni);'
'    end'
'end'
'end'}, 'f', '[2 1]');

%  One row per input port, and the row is the port's own height. Simulink
%  spaces n input ports evenly down a block, so port k of the thruster block,
%  which spans y = 40 to 320, sits at
%
%      y = 40 + 280 (k - 0.5)/5 = 56k + 12
%
%  Placing each Constant on that line makes every connection a single straight
%  horizontal: no jogs, and no two signals sharing a vertical segment. The
%  block is drawn 280 tall rather than 200 so that the 56 px pitch leaves room
%  for each Constant's name underneath it.
yp = @(k) 56*k + 12;                          % centre of input port k
for i = 1:4
    add_block('simulink/Sources/Constant', [a '/' KK{i}], ...
              'Value', KK{i}, 'Position', [90 yp(i+1)-15 145 yp(i+1)+15]);
end

%  tau = B f. B is a Gain block in matrix mode and its value is B_alloc,
%  produced by otter_B from the column rule. Nothing here is transcribed.
add_block('simulink/Math Operations/Gain', [a '/B'], ...
          'Gain','B_alloc', 'Multiplication','Matrix(K*u)', ...
          'Position',[510 162 560 198]);

set_param([a '/n'],   'Position',[ 60  yp(1)-7  90  yp(1)+7]);
set_param([a '/tau'], 'Position',[640 173 670 187]);

La = @(x,y) add_line(a, x, y, 'autorouting','on');
La('n/1','thruster model/1');
for i = 1:4, La([KK{i} '/1'], sprintf('thruster model/%d', i+1)); end
La('thruster model/1','B/1');
La('B/1','tau/1');

%% ---- 3. plant ----------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%% ---- 4. measurement ----------------------------------------------------
add_measurement(m, P.measurement, 'A1', {'tau'}, ...
                struct('dash', true, 'weekName', 'A1  demanded tau'));

%% ---- wiring ------------------------------------------------------------
L = @(x,y) add_line(m, x, y, 'autorouting','smart');
L('n_cmd/1',      'Thrust and B/1');
L('n_cmd/1',      'Otter USV/1');
L('Otter USV/1',  'Measurements/1');
L('Thrust and B/1','Measurements/2');

%% ---- what the model is for ---------------------------------------------
note(m, [40 330 880 690], strjoin({ ...
'APPENDIX A1  -  ACTUATION AND THE CONTROL EFFECTIVENESS MATRIX'
''
'Two paths leave the same command. The upper path is this appendix''s'
'arithmetic: shaft speed -> thrust -> generalised force, tau = B f.'
'The lower path is the unmodified plant. They must agree.'
''
'THE COLUMN RULE'
''
'A thruster at (x, y) pushing along the unit vector e contributes'
'exactly one column of B:'
''
'        [ e_x ; e_y ; x e_y - y e_x ]'
''
'For the base Otter both propellers face forward at y = -+0.395,'
'so B = [1 1 ; 0 0 ; 0.395 -0.395].  Rank 2, and the middle row'
'is EMPTY. No propeller speed produces a sideways force.'
''
'THREE THINGS TO TRY'
''
'1  n_cmd = [60; 60].   Y stays at zero to machine precision.'
''
'2  n_cmd = [60; -60].  The command that looks like a pure turn.'
'   X is 16.686 N, not zero, because k_pos is not k_neg.'
''
'3  n_cmd = [60; -78.6701].  The command that IS a pure turn.'
'   X is zero AND N is 26 per cent LARGER than in case 2.'
''
'Rank 2 is the whole story of this course. Weeks 10 to 12 buy the'
'third rank back, one hull at a time, and measure what it costs.'}, newline));

%% ---- plot when the run finishes ----------------------------------------
set_param(m, 'StopFcn', 'A1_plot;');
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
