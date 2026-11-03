%W12_1_BUILD_OPENLOOP  12주차 1단계 개루프 모델을 **코드로** 만든다.
%                      Build the Week 12 stage-1 open-loop model from code.
%
%   실행 / to run
%       cd lectures/W12_simulink
%       W12_1_build_openloop        % W12_openloop.slx 와 img/*.png 를 만든다
%       W12_0_setup                 % 값을 얹는다. 그 다음 Run 을 누른다
%
%   손으로 그리지 않는다 / nothing here is drawn by hand
%       블록·선·주석이 전부 이 파일에서 나온다. 그래서 도면이 깨졌을 때 고치는
%       자리가 하나이고, 열두 주차의 도면이 같은 규칙으로 놓인다.
%
%   무엇을 만드는가 / what this builds
%       사슬이 넷이다 — **명령 → 구동장치 한계 → 플랜트 → 계측**.
%       제어기도 배분기도 없다. 1단계의 질문이 "여덟 개의 숫자를 손으로 주었을 때
%       예상한 힘과 궤적이 나오는가" 뿐이기 때문이다.
%
%       command           캔버스의 Constant 여덟 개. 그림에서 어느 추진기에
%                         무엇을 지시했는지 **바로 읽힌다**
%       servo limits      축회전수 포화 · 틸팅 각 포화 · 틸팅 각속도 제한.
%                         `gnc_chain` 의 `allocation` 자리를 쓴다 — 이번 주차에
%                         이 자리에 있는 것은 **구동장치의 한계**이고, 배분은
%                         뒤에 와서 같은 자리에 들어간다. 플랜트가 열두 주차
%                         내내 같은 자리에 있게 하려는 것이다
%       Otter USV         `otter_tilt4.m`. 축회전수 넷과 각도 넷을 받아 tau 의
%                         1·2·6 행을 **함수 안에서** 만든다. tau_ext 중첩이 없다
%       Measurements      `add_measurement`. 앞 여섯 열은 온 과정의 계약이고,
%                         12주차가 여덟 열을 더한다 — n(4) 과 delta(4)
%
%   로그는 **서보 뒤에서** 갈라진다 / the log taps POST-SERVO
%       명령이 아니라 배가 실제로 받은 값을 기록한다. 그래서 70 도를 지시했을 때
%       기록된 각이 45 도이고, 그것이 포화를 보는 자리다. 한 출력에서 선 둘이
%       나가는 것은 **분기**이므로 `check_overlaps` 가 세지 않는다.
%
%   See also W12_0_SETUP, W12_V_OPENLOOP, OTTER_TILT4, ADD_OTTER_PLANT,
%            ADD_MEASUREMENT, GNC_CHAIN, VERIFY_OTTER_TILT4.

m    = 'W12_openloop';
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
              'Height', struct('allocation', 600, 'plant', 162, 'measurement', 200), ...
              'Width',  struct('allocation', 140, 'plant', 130, 'measurement', 140));

% ---- command: 여덟 개의 Constant / eight Constants on the canvas ---------
%  **이 여덟 블록이 1단계의 입력 전부다.** 블록 이름이 추진기 번호이고, 값이
%  `W12_0_setup` 의 벡터에서 그 번호의 원소를 집어 온다. 그래서 도면을 보면 어느
%  추진기에 무엇을 지시했는지 알 수 있고, V 절은 벡터 둘만 바꿔 여섯 경우를 돈다.
%  Eight blocks are the whole input of stage 1. The block name is the thruster
%  number and the value picks that element out of the setup's vector, so the
%  diagram says what each thruster was told while a section script sweeps two
%  variables.
for i = 1:4
    add_block('simulink/Sources/Constant', sprintf('%s/n%d', m, i), ...
              'Value', sprintf('n_cmd(%d)', i), ...
              'Position', [P.command(1) 100+52*(i-1) ...
                           P.command(1)+55 130+52*(i-1)]);
    add_block('simulink/Sources/Constant', sprintf('%s/delta%d', m, i), ...
              'Value', sprintf('d_cmd(%d)', i), ...
              'Position', [P.command(1) 420+52*(i-1) ...
                           P.command(1)+55 450+52*(i-1)]);
end

add_block('simulink/Signal Routing/Mux', [m '/n cmd'], ...
          'Inputs', '4', 'DisplayOption', 'bar', 'Position', [210 120 215 316]);
add_block('simulink/Signal Routing/Mux', [m '/delta cmd'], ...
          'Inputs', '4', 'DisplayOption', 'bar', 'Position', [210 420 215 616]);

% ---- servo limits: 구동장치가 할 수 있는 것 / what the actuator can do ----
%  순서가 중요하다 / the order matters
%    각도는 **먼저 깎고 그 다음 변화율을 건다.** 거꾸로 하면 변화율 제한이
%    한계 밖의 목표를 향해 올라가다 마지막에 잘려, 도달하는 시각이 달라진다.
%    The angle is clipped FIRST and rate-limited after. The other order ramps
%    toward a target outside the limit and is cut only at the end, which moves
%    the time of arrival.
sv = add_subsys(m, 'servo limits', P.allocation, ...
                {'n', 'delta'}, {'n sat', 'delta sat'}, gnc_colour('allocation'));

set_param([sv '/n'],         'Position', [ 40 100  70 120]);
set_param([sv '/delta'],     'Position', [ 40 300  70 320]);
set_param([sv '/n sat'],     'Position', [520 100 550 120]);
set_param([sv '/delta sat'], 'Position', [520 300 550 320]);

add_block('simulink/Discontinuities/Saturation', [sv '/shaft limit'], ...
          'UpperLimit', 'n_max', 'LowerLimit', 'n_min', ...
          'Position', [200  80 260 140]);
add_block('simulink/Discontinuities/Saturation', [sv '/servo limit'], ...
          'UpperLimit', 'alpha_lim', 'LowerLimit', '-alpha_lim', ...
          'Position', [200 280 260 340]);
add_block('simulink/Discontinuities/Rate Limiter', [sv '/servo rate'], ...
          'RisingSlewLimit', 'alpha_rate', 'FallingSlewLimit', '-alpha_rate', ...
          'Position', [340 280 420 340]);

add_line(sv, 'n/1',           'shaft limit/1');
add_line(sv, 'shaft limit/1', 'n sat/1');
add_line(sv, 'delta/1',       'servo limit/1');
add_line(sv, 'servo limit/1', 'servo rate/1');
add_line(sv, 'servo rate/1',  'delta sat/1');

a = Simulink.Annotation([sv '/note']);
a.Text = strjoin({ ...
  'The actuator, and nothing else.', ...
  '', ...
  'Four shaft speeds are clipped to [n_min, n_max]. Four tilt angles are', ...
  'clipped to +-alpha_lim and only then rate limited to alpha_rate: clipping', ...
  'first is what makes the angle arrive at the limit at the time the rate', ...
  'limit predicts.', ...
  '', ...
  'Stage 1 has no allocation. The eight numbers come straight from the', ...
  'canvas, and this stage says which of them the hull can actually be given.'}, ...
  newline);
a.Position = [40 400 560 500];
a.HorizontalAlignment = 'left';

% ---- plant: otter_tilt4 / the hull ---------------------------------------
add_otter_plant(m, 'Otter USV', P.plant, cfg);

% ---- measurement ---------------------------------------------------------
%  블록 이름에 '/' 를 쓸 수 없으므로 단위를 풀어 적는다 / a block name cannot
%  contain a slash, so the unit is spelled out
add_measurement(m, P.measurement, 'W12', {'n', 'delta'}, ...
                struct('dash', true, ...
                       'weekName', 'input  n  (rad per s)  and  delta  (rad)'));

% ---- wiring --------------------------------------------------------------
%  상수를 자기 포트의 행으로 옮겨서 연결한다 — 곧은 선은 겹칠 수 없다
row_feed(m, 'servo limits', {'n cmd', 'delta cmd'});
row_feed(m, 'n cmd',        {'n1', 'n2', 'n3', 'n4'});
row_feed(m, 'delta cmd',    {'delta1', 'delta2', 'delta3', 'delta4'});

lane_line(m, 'servo limits', 1, 'Otter USV',    1, 540);
lane_line(m, 'servo limits', 2, 'Otter USV',    2, 590);
lane_line(m, 'Otter USV',    1, 'Measurements', 1, 850);

%  로그로 가는 분기. 블록 밑으로 돌려 보내 플랜트를 지나가지 않게 한다
tap(m, 'servo limits', 1, 'Measurements', 2, 520, 790, 920);
tap(m, 'servo limits', 2, 'Measurements', 3, 570, 840, 890);

% ---- note on the canvas --------------------------------------------------
b = Simulink.Annotation([m '/note']);
b.Text = strjoin({ ...
  'W12 stage 1 -- four tilting thrusters, OPEN LOOP.', ...
  '', ...
  'There is no controller and no allocation in this model. The eight', ...
  'Constants on the left are given by hand in W12_0_setup, and the only', ...
  'question the model answers is whether the force, the moment and the', ...
  'resulting track are the ones computed by hand from those eight numbers.', ...
  '', ...
  'Thruster 1 and 2 are forward at x = +1.50 m, 3 and 4 aft at x = -1.00 m;', ...
  'the odd numbers are to port, at y = -0.395 m. Each angle is measured from', ...
  'the body x axis, counter-clockwise positive, so delta = 0 returns the', ...
  'Otter of Weeks 1 to 5 and delta = +90 deg pushes to starboard.', ...
  '', ...
  'The log branches off the servo outputs rather than off the Constants,', ...
  'which is why a command beyond a limit is recorded as what the hull', ...
  'received and not as what was asked for.'}, newline);
b.Position = [40 900 1080 1060];
b.HorizontalAlignment = 'left';
b.BackgroundColor = 'lightBlue';

% ---- run-time behaviour --------------------------------------------------
set_param(m, 'StopFcn', 'W12_plot;');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

%  Run 만 눌러도 돌게 한다 / make a bare Run work in a fresh session
set_param(m, 'InitFcn', [ ...
    'addpath(fullfile(fileparts(fileparts(fileparts(' ...
        'get_param(bdroot, ''FileName'')))), ''_tools''), ' ...
        'fileparts(get_param(bdroot, ''FileName''))); ' ...
    'run_alone(''W12'', bdroot);']);

% ---- finish --------------------------------------------------------------
mss_style(m);
compact_layout(m, 60);
straighten_lines(m);
save_system(m, out);

print(['-s' m],                 '-dpng', '-r45', fullfile(here, 'img', [m '.png']));
print(['-s' sv],                '-dpng', '-r45', fullfile(here, 'img', [m '_servo.png']));
print(['-s' m '/Otter USV'],    '-dpng', '-r45', fullfile(here, 'img', [m '_plant.png']));
print(['-s' m '/Measurements'], '-dpng', '-r45', fullfile(here, 'img', [m '_meas.png']));
close_system(m, 0);

%  **디스크의 파일로 다시 센다** — save_system 이 가지선의 점을 다시 쓴다
load_system(out);
nov = check_overlaps(m);
ndg = check_diagonals(m);
fprintf('\n  %s   overlaps %d   diagonals %d\n\n', m, nov, ndg);
close_system(m, 0);


% =========================================================================
function tap(mdl, src, sp, dst, dp, x1, yl, x2)
%TAP  한 출력에서 갈라져 **블록 밑을 돌아** 다른 포트로 간다.
%     Branch off one output and reach another port BELOW the blocks.
%
%  다섯 도막이고 전부 가로나 세로다. x1·yl·x2 를 손으로 주는 이유는 분기마다
%  **다른** 통로를 쓰게 하려는 것이다 — 두 분기가 같은 통로를 쓰면 겹친다.
a = port_xy(mdl, src, 'Outport', sp);
b = port_xy(mdl, dst, 'Inport',  dp);
add_line(mdl, [a; x1 a(2); x1 yl; x2 yl; x2 b(2); b]);
end
