function W01_S3_current(mdl)
%W01_S3_CURRENT  1주차 문제 3 의 모범답안 — 조류 속의 선박.
%                Solution to Week 1, Problem 3: the vessel in a current.
%
%   >> W01_S3_current         W01_S3.slx 를 만든다 / builds W01_S3.slx
%   >> W01_check(3,'W01_S3')  채점한다 / checks it
%
%   문제가 요구한 것 / what the problem asked
%       옆에서 오는 조류에 선박을 두고, 항적이 선수방위에서 얼마나 벗어나는지
%       측정할 것. 문제지는 새 블록이 필요 없다고 밝혀 두었고, 바로 그것이
%       이 문제의 요점이다. 조류는 이미 otter.m 안에 들어 있다.
%
%       Put the vessel in a beam current and measure how far its track leaves
%       its heading. The problem statement says no new blocks are needed, and
%       that is the point of it: the current is already inside otter.m.
%
%   왜 모델에 더할 것이 없는가 / why there is nothing to add to the model
%       조류는 힘이 아니라 속도이다. 운동방정식의 오른편에 더해지는 것이 없다.
%       otter.m 은 조류를 선체고정좌표계로 회전시킨 뒤 속도에서 뺀다 (79~81 행).
%
%       A current is a velocity, not a force: nothing is added to the
%       right-hand side of the equation of motion. otter.m rotates the current
%       into the body frame and subtracts it, on lines 79 to 81:
%
%       u_c  = V_c cos(beta_c - psi)
%       v_c  = V_c sin(beta_c - psi)
%       nu_r = nu - [u_c v_c 0 0 0 0]'
%
%       이후 모든 유체력 항은 물에 대한 상대속도 nu_r 로 계산된다. 예외는
%       204 행의 운동학이다.
%       Every hydrodynamic term is then computed from nu_r, the velocity
%       through the water. The kinematics on line 204 are the exception:
%
%       eta_dot = J(eta) nu          <- nu_r 이 아니라 nu / nu, not nu_r
%
%       이 하나의 비대칭이 현상의 전부이다. 선체가 느끼는 것은 nu_r 이므로 선체에
%       작용하는 힘은 달라지지 않는다. 그러나 위치는 nu 를 적분하므로 선박은 물에
%       실려 간다. 조류는 밀지 않으면서 배를 옮긴다.
%
%       That single asymmetry is the whole phenomenon. The hull feels nu_r, so
%       the forces on it do not change; the position integrates nu, so the
%       vessel is carried along by the water. A current moves a vessel without
%       pushing it.
%
%   돌리기 전에 예측할 숫자 / the numbers to predict before running
%       옆에서 V_c = 0.5 m/s 의 조류가 오고 선박이 물에 대해 1.0286 m/s 로 나아갈
%       때, 대지속도는 두 벡터의 합이다.
%       With V_c = 0.5 m/s on the beam and the vessel making 1.0286 m/s through
%       the water, the velocity over the ground is the vector sum:
%
%       대지속력 ground speed  ~  sqrt(1.0286^2 + 0.5^2)  =  1.144 m/s
%       표류각   drift         ~  atan(0.5 / 1.0286)      =  25.9 deg
%
%       절 E 의 측정값은 1.1091 m/s 와 25.81 도이다. 표류각은 잘 맞고, 속력은
%       단순한 합보다 조금 작다. 선체가 흐름 쪽으로 약 4 도 돌아서기 때문이며,
%       그만큼 옆에서 오던 조류의 일부가 앞에서 오는 성분으로 바뀐다. 횡류 항력이
%       v_r 에 작용하는데 그 작용선이 원점을 지나지 않으므로, 아무도 지시하지
%       않은 요 모멘트가 생긴다.
%
%       Section E measures 1.1091 m/s and 25.81 deg. The drift agrees closely;
%       the speed is a little below the naive sum because the hull also
%       weathervanes some 4 deg into the flow, which turns part of the current
%       from beam-on to head-on. Cross-flow drag acts on v_r and its line of
%       action does not pass through the origin, so it produces a yaw moment
%       although none was commanded.
%
%   See also W01_CHECK, W01_S1_OPENLOOP, W01_S2_MANOEUVRE.

if nargin < 1 || isempty(mdl), mdl = 'W01_S3'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'));
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%  Identical to Solution 1. The current enters through V_c and beta_c, which
%  the plant subsystem already reads as Constant blocks, so the canvas does
%  not change at all between still water and a 0.5 m/s beam current.
add_block('simulink/Sources/Constant', [mdl '/n command'], ...
          'Value','[n0 ; n0]', 'Position',[120 200 200 240]);
add_otter_plant(mdl, 'Otter USV', [320 160 540 280], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position',[660 200 730 240]);
add_block('simulink/Sinks/Scope', [mdl '/states'], 'Position',[660 290 690 320]);

add_line(mdl, 'n command/1', 'Otter USV/1', 'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'xlog/1',      'autorouting','smart');
add_line(mdl, 'Otter USV/1', 'states/1',    'autorouting','smart');
set_param([mdl '/states'], 'Open','on');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'SOLUTION 3  -  THE VESSEL IN A CURRENT'
''
'The canvas is IDENTICAL to Solution 1. Nothing was added, because a'
'current is a velocity and not a force.'
''
'   otter.m 79-81   nu_r = nu - [u_c v_c 0 0 0 0]''      forces use nu_r'
'   otter.m 204     eta_dot = J(eta) nu                 position uses nu'
''
'That one asymmetry is the entire phenomenon: the hull feels the water'
'flowing past it, and the ground sees the vessel carried along by it.'
''
'   V_c = 0.5 m/s on the beam   ->   drift  25.81 deg'
'                                    ground speed  1.1091 m/s'
''
'The heading also drifts about 4 deg with no yaw command at all: cross-'
'flow drag acts on v_r and its line of action misses the origin, so it'
'makes a moment. The vessel weathervanes into the flow.'}, newline);
a.Position = [110 380 700 620];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
close_system(mdl, 0);
fprintf('  built  %s\n', out);
end
