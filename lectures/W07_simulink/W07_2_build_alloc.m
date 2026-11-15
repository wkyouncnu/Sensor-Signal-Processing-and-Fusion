%W07_2_BUILD_ALLOC  배분 사슬 모델을 **코드로** 만든다. 법칙은 상수 하나가 고른다.
%                   Build the allocation chain from code; one constant selects
%                   the law.
%
%   실행 / to run
%       cd lectures/W07_simulink
%       W07_2_build_alloc           % W07_alloc_chain.slx 와 img/*.png 를 만든다
%       W07_0_setup                 % 값을 얹는다. 그 다음 Run 을 누른다
%
%   무엇을 만드는가 / what this builds
%       사슬이 넷이다 — **명령 tau_d → 배분 → 플랜트 → 계측**.
%       The chain has four stages: the demand tau_d, the allocation, the hull
%       and the measurement.
%
%       command        X · Y · N 세 Constant 와 **법칙 번호 `law`** 하나.
%                      네 가지 배분법을 파일 넷으로 두지 않고 이 상수 하나로
%                      고른다 (`law = 1 … 4`)
%                      three Constants for X, Y, N and one for the law number:
%                      the four laws are chosen here, not in four models
%       allocation     법칙 블록 넷 → Multiport Switch → `force to input` →
%                      한계 둘. 요구를 여덟 성분으로 나누고, 그것을 회전수와
%                      각으로 바꾸고, 구동장치가 할 수 있는 만큼으로 깎는다
%       Otter USV      `otter_tilt4.m`. 깎인 회전수와 각을 받고, **실제로 가해진
%                      tau 를 두 번째 출력으로 낸다**
%       Measurements   요구한 tau 와 실제로 나온 tau 를 한 Scope 에 겹쳐 그린다
%
%   법칙 하나에 블록 하나 / one law, one block
%       블록 넷이 나란히 서고 그 위의 Multiport Switch 가 `law` 를 읽어 하나를
%       고른다. 블록 안에서 다른 함수를 부르지 않으므로, 더블클릭한 학생이 보는
%       글자가 그 법칙의 전부다 (사용자 지시, 2026-11-14).
%       Four blocks stand side by side and the Multiport Switch above them reads
%       `law` to pick one. No block calls out to another function, so the script
%       a student sees on double-click is the whole law.
%
%   실제 tau 는 어디서 오는가 / where the delivered tau comes from
%       운동모델이 포화 뒤의 n 과 delta 로 **이미** [X Y N] 을 만든다. 그것을
%       포트로 내보내므로 같은 계산을 되풀이하는 블록이 필요 없다 (사용자 지시,
%       2026-11-14). 배분기는 요구를 그대로 낼 수 있다고 가정하고 풀지만 포화가
%       그 뒤에 있으므로 둘이 다를 수 있고, 그 차이가 이 주차의 결과다.
%       The motion model already forms [X Y N] from the clipped n and delta, so
%       it reports that as a second output and no block outside rebuilds it. The
%       allocator solves as if the demand could be delivered exactly; the
%       difference the saturations open up is this week's result.
%
%   절 스크립트는 따로다 / the section scripts are elsewhere
%       표와 그림은 `W07_alloc_run` 이 찍는다 (§7-8 … §7-11). 이 모델은 같은 네 법칙을
%       **연속시간 사슬 안에서** 돌려 보는 자리다.
%
%   See also W07_0_SETUP, W07_ALLOC_RUN, W07_PLOT_CA, OTTER_TILT4,
%            ADD_OTTER_PLANT, GNC_CHAIN.

m    = 'W07_alloc_chain';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

cfg = otter_config('quad_tilt');
out = fullfile(here, [m '.slx']);

bdclose(m);
if isfile(out), delete(out); end
new_system(m);

set_param(m, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', 'h', ...
             'StartTime', '0', 'StopTime', 'T_final');

P = gnc_chain({'command', 'allocation', 'plant', 'measurement'}, ...
              'Y', 120, 'Pitch', 300, ...
              'Height', struct('allocation', 320, 'plant', 162, 'measurement', 220), ...
              'Width',  struct('allocation', 170, 'plant', 130, 'measurement', 150));

% ---- command: 요구한 힘과 법칙 번호 / the demand and the law number -------
%  X · Y · N 은 제어기가 낼 것을 손으로 적은 것이다. 7주차는 제어기를 넣지
%  않고 배분만 본다 / the three Constants stand in for a controller
nm = {'X cmd', 'Y cmd', 'N cmd'};
for i = 1:3
    add_block('simulink/Sources/Constant', [m '/' nm{i}], ...
              'Value', sprintf('tau_cmd(%d)', i), ...
              'Position', [P.command(1) 120+52*(i-1) ...
                           P.command(1)+55 150+52*(i-1)]);
end
add_block('simulink/Signal Routing/Mux', [m '/tau d'], ...
          'Inputs', '3', 'DisplayOption', 'bar', 'Position', [200 120 205 264]);

add_block('simulink/Sources/Constant', [m '/law'], 'Value', 'law', ...
          'Position', [P.command(1) 360 P.command(1)+55 390]);

% ---- allocation ----------------------------------------------------------
%  배분기는 모델 셋이 함께 쓰는 도구다 — 이 비교 모델, 웨이포인트 추종, 위치 제어.
%  여기서는 법칙 넷을 다 실어 견준다 (standing order §15-34) /
%  the allocator is a shared tool used by three models; here all four laws
%  are carried so that they can be compared.
sa = add_allocation_tilt4(m, P.allocation, 1:4, 'W07ca_act');

% ---- plant ---------------------------------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);

% ---- measurement ---------------------------------------------------------
%  `add_measurement` 을 쓰지 않는다 / why not add_measurement
%      그 함수는 앞 여섯 열이 [u v r N E psi] 인 `W07_log` 를 만든다. 이 모델이
%      보는 것은 **요구한 tau 와 실제 tau** 이므로 열이 다르고, 같은 이름으로
%      기록하면 `W07_openloop_run` 의 열 해석이 깨진다. 그래서 로그 이름도 `W07ca_log`
%      로 따로 둔다 / this model logs a different set of columns, so it writes
%      a log of its own name rather than breaking the course-wide one
%  포트 순서는 플랜트가 정한다 / the plant fixes the port order
%      플랜트의 출력은 1 번이 상태 x, 2 번이 실제 tau 다. 받는 쪽도 그 순서로
%      두면 두 선이 서로 엇갈리지 않는다 / taking them in the same order keeps
%      the two lines from crossing
sm = add_subsys(m, 'Measurements', P.measurement, ...
                {'tau d', 'x', 'tau act'}, {}, gnc_colour('measurement'));

add_block('simulink/Signal Routing/Selector', [sm '/u v r'], ...
          'IndexOptions', 'Index vector (dialog)', 'Indices', '[1 2 3]', ...
          'InputPortWidth', '12', 'Position', [150 300 200 340]);
add_block('simulink/Sources/Clock', [sm '/t'], 'Position', [150 400 180 430]);

%  요구와 실제를 한 묶음으로 / the demand and the delivered force, side by side
add_block('simulink/Signal Routing/Mux', [sm '/compare'], ...
          'Inputs', '2', 'DisplayOption', 'bar', 'Position', [280 100 285 220]);
add_block('simulink/Signal Routing/Mux', [sm '/log'], ...
          'Inputs', '3', 'DisplayOption', 'bar', 'Position', [460 340 465 580]);

add_block('simulink/Sinks/Scope', [sm '/tau  demanded and delivered'], ...
          'NumInputPorts', '1', 'Position', [370 140 410 180]);
add_block('simulink/Sinks/To Workspace', [sm '/W07ca log'], ...
          'VariableName', 'W07ca_log', 'SaveFormat', 'Array', ...
          'SampleTime', '-1', 'Position', [560 440 630 480]);

row_feed(sm, 'compare', {'tau d', 'tau act'});
row_feed(sm, 'u v r',   {'x'});
row_feed(sm, 'log',     {'t', '', ''});
lane_line(sm, 'compare', 1, 'tau  demanded and delivered', 1, 330);
lane_line(sm, 'log',     1, 'W07ca log',                   1, 510);

%  로그로 가는 분기 둘. 통로를 서로 다르게 쓴다 / two branches, distinct lanes
elbow(sm, 'compare', 1, 'log', 2, 415);
elbow(sm, 'u v r',   1, 'log', 3, 435);

b = Simulink.Annotation([sm '/note']);
b.Text = strjoin({ ...
  'W07ca_log holds ten columns:  t,  tau_d(3),  tau_act(3),  u v r(3).', ...
  'The allocation subsystem writes a second log, W07ca_act, which holds what', ...
  'it asked of the actuators and what the limits allowed.', ...
  '', ...
  'The Scope draws the demand and the delivered force on one axis, which is', ...
  'the figure of 7-11: wherever the two separate, a limit is active.'}, newline);
b.Position = [40 640 640 740];
b.HorizontalAlignment = 'left';

% ---- wiring at the top level ---------------------------------------------
%  순서가 중요하다 / the order matters
%      Mux 를 allocation 의 포트 높이로 먼저 옮기고, **그 다음에** 상수 셋을
%      Mux 의 새 포트 높이로 옮긴다. 거꾸로 하면 Mux 가 움직이면서 이미 그은
%      선 셋이 꺾인다 / move the Mux first, then the Constants onto where its
%      ports ended up: the other order bends three lines that are already drawn
row_feed(m, 'allocation', {'tau d', 'law'});
row_feed(m, 'tau d',      {'X cmd', 'Y cmd', 'N cmd'});

lane_line(m, 'allocation', 1, 'Otter USV',    1, 545);
lane_line(m, 'allocation', 2, 'Otter USV',    2, 585);

%  플랜트가 상태와 **실제로 가해진 tau** 를 함께 낸다 / the hull reports both
lane_line(m, 'Otter USV',  1, 'Measurements', 2, 850);
lane_line(m, 'Otter USV',  2, 'Measurements', 3, 870);

%  요구한 tau 만 블록 **밑으로** 돌려 계측으로 보낸다
tap(m, 'tau d', 1, 'Measurements', 1, 250, 560, 900);

c = Simulink.Annotation([m '/note']);
c.Text = strjoin({ ...
  'W07 stage 2 -- CONTROL ALLOCATION.  One model, four laws.', ...
  '', ...
  'Inside `allocation` each law is a block of its own, and the constant `law`', ...
  'on the left selects one of them. The four laws of 7-8 to 7-11 are therefore', ...
  'compared without opening four models, and each can be read on its own:', ...
  '', ...
  '    law = 1    minimum norm                      f = B''(BB'')\\tau', ...
  '    law = 2    weighted minimum norm             W says what is expensive', ...
  '    law = 3    weighted, then folded onto the servo limit', ...
  '    law = 4    servo limit AND thrust cap as hard constraints', ...
  '', ...
  'X cmd, Y cmd and N cmd stand in for a controller: Week 7 asks only how a', ...
  'demand is split, not where the demand came from. The Scope inside', ...
  'Measurements draws the demand against what the hull actually received.'}, newline);
c.Position = [40 620 1100 800];
c.HorizontalAlignment = 'left';
c.BackgroundColor = 'lightBlue';

% ---- run-time behaviour --------------------------------------------------
set_param(m, 'StopFcn', 'W07_plot_ca;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

set_param(m, 'InitFcn', [ ...
    'addpath(fullfile(fileparts(fileparts(fileparts(' ...
        'get_param(bdroot, ''FileName'')))), ''_tools''), ' ...
        'fileparts(get_param(bdroot, ''FileName''))); ' ...
    'run_alone(''W07'', bdroot);']);

% ---- finish --------------------------------------------------------------
mss_style(m);
compact_layout(m, 60);
straighten_lines(m);
save_system(m, out);

print(['-s' m],  '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
print(['-s' sa], '-dpng', '-r45', fullfile(here, 'img', [m '_alloc.png']));
print(['-s' sm], '-dpng', '-r45', fullfile(here, 'img', [m '_meas.png']));
close_system(m, 0);

load_system(out);
nov = check_overlaps(m);
ndg = check_diagonals(m);
fprintf('\n  %s   overlaps %d   diagonals %d\n\n', m, nov, ndg);
close_system(m, 0);


% =========================================================================
function elbow(sys, src, sp, dst, dp, x)
%ELBOW  한 출력에서 갈라져 세로 통로 하나를 지나 다른 포트로 간다.
%       Branch off one output, through one vertical lane, into another port.
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport',  dp);
add_line(sys, [a; x a(2); x b(2); b]);
end

% =========================================================================
function tap(mdl, src, sp, dst, dp, x1, yl, x2)
%TAP  한 출력에서 갈라져 **블록 밑을 돌아** 다른 포트로 간다.
%     Branch off one output and reach another port BELOW the blocks.
a = port_xy(mdl, src, 'Outport', sp);
b = port_xy(mdl, dst, 'Inport',  dp);
add_line(mdl, [a; x1 a(2); x1 yl; x2 yl; x2 b(2); b]);
end
