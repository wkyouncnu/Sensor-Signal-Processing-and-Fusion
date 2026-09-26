function W07_P1_start(mdl)
%W07_P1_START  7주차 실습 문제의 출발 모델을 만든다.
%              Create the starting model for the Week 7 laboratory problems.
%
%   >> W07_P1_start                 W07_P1.slx 를 만든다 / creates W07_P1.slx
%   >> W07_P1_start('W07_P1_kim')   다른 이름으로 만든다 / another name
%
%   무엇을 주고 무엇을 주지 않는가
%   what this script gives, and what it withholds
%
%   바다와 선체와 6주차의 배분을 준다. 그 사이가 비어 있다 — **제어기가 무엇을
%   보는가**, 그리고 그중 무엇을 따라가야 하는가. 그것이 이번 주의 전부다.
%
%       wave + x --> [ your measurement ] --> [ your notch ] --> [ autopilot ] --> N
%
%   The sea, the hull and Week 6's allocation are given, with the space between
%   them empty: what the controller sees, and which part of it should be acted
%   on. That is the whole of this week.
%
%   주어지는 블록 / the blocks that are provided
%
%     wave        [psi_w ; r_w], one fixed realisation of a JONSWAP sea
%     step        the commanded heading, tag psi_d
%     slow        the wind and drift of 7-6, added to the hull after the controller
%     allocation  Week 6's, unchanged
%     Otter USV   n -> twelve states, tag x
%     xlog        the twelve states
%
%   없는 것, 그래서 문제인 것 / what is missing, and is therefore the exercise
%
%     the measurement, the notch, the autopilot, and the log flog
%
%   빈 자리를 Constant 0 이 채우고 있어 모델은 처음부터 돈다 (배는 명령을 무시하고
%   파랑 속에 떠 있을 뿐이다). 지우고 자기 블록을 그 자리에 넣는다.
%   A Constant 0 holds the place so the model runs from the start — the vessel
%   simply drifts, ignoring the command. Delete it and build in its place.
%
%   See also W07_CHECK, W07_0_SETUP, W07_S1_NOTCH.

if nargin < 1 || isempty(mdl), mdl = 'W07_P1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, here);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

w07_lab_bench(mdl, 120);

%  모델이 처음부터 돌도록 자리를 채우는 상수 / a placeholder so it runs at once
add_block('simulink/Sources/Constant', [mdl '/N placeholder'], ...
          'Value','0', 'Position', [300 500 440 540]);
add_block('simulink/Signal Routing/Goto', [mdl '/N_ctrl out'], 'GotoTag','N_ctrl', ...
          'Position', [490 510 560 530]);
add_line(mdl, 'N placeholder/1', 'N_ctrl out/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/brief']);
a.Text = strjoin({ ...
'WEEK 7 LABORATORY  -  BUILD THE MEASUREMENT PATH YOURSELF'
''
'The sea, the hull and Week 6''s allocation are given. What the controller'
'SEES is not. Delete the placeholder and build in its place.'
''
'PROBLEM 1   The measurement, and the notch. Form what the sensor really'
'            reports, then take out of it only what cannot be followed:'
''
'               psi_m = psi + psi_w            r_m = r + r_w'
''
'                       s^2 + 2 zeta_n w0 s + w0^2'
'               H(s) = ---------------------------- ,   zeta_n < zeta_d'
'                       s^2 + 2 zeta_d w0 s + w0^2'
''
'            on BOTH channels. Then Week 4''s autopilot, gains unchanged:'
''
'               N = Kp ssa(psi_d - psi_f) - Kd r_f,   |N| <= N_max'
''
'PROBLEM 2   What it costs. No building. Switch the sea off and give the same'
'            10 deg step, with the filter in and with zeta_n = zeta_d.'
''
'PROBLEM 3   The slow part must NOT be filtered. Add the integral of Week 4,'
'            with back-calculation, and meet a 15 N m push:'
''
'               u = Kp e + I - Kd r_f ;   N = sat(u) ;   I += h(Ki e + Kb(N-u))'
''
'THE MODEL MUST CONTAIN'
''
'   xlog   To Workspace, Structure With Time, the plant''s 12 states  (given)'
'   flog   To Workspace, Structure With Time, [psi_m ; psi_f ; N]'
'          -- the measurement, what the controller USES, and the moment it asks'
'             for, in deg, deg and N m'
''
'   psi_f is logged so that the checker can see WHETHER the filter is in the'
'   loop, not merely whether the vessel behaved. With zeta_n = zeta_d it must'
'   equal psi_m exactly, and that is how the comparison is kept honest.'
''
'CHECK YOUR WORK AT ANY TIME'
''
['   >> W07_check(1, ''' mdl ''')      and 2, and 3']
''
'DO NOT CHANGE the solver settings: fixed-step ode4 at h = 0.02 s.'}, newline);
a.Position = [120 600 1140 1080];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);

fprintf('\n  created %s   (overlapping lines: %d)\n', out, n);
fprintf('  open it, build Problem 1, then run:  W07_check(1, ''%s'')\n\n', mdl);
end
