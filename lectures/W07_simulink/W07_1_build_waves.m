function W07_1_build_waves(which)
%W07_1_BUILD_WAVES  7주차 모델을 코드로 만든다 — 실험 하나에 모델 하나.
%                   Generate the Week 7 models, one model per experiment.
%
%   모델 넷 / the four models
%       W07_C_wave       바다만. 배도 제어기도 없다 / the sea alone: no vessel, no controller
%       W07_D_no_filter  파랑 속의 선수각 루프, 필터 없음 / the heading loop in waves, unfiltered
%       W07_E_notch      같은 루프에 노치 필터 둘 / the same loop with two notch filters
%       W07_G_slow       노치와 적분, 그리고 느린 외란 / the notch, an integral, and a slow disturbance
%       W07_H_tuning     노치를 고르는 실험 7-7 의 모델 / the model of Experiment 7-7, where the notch is chosen
%
%   사슬 / the chain
%       command -> error -> autopilot -> moment limit -> allocation -> Otter
%       measurement: the true heading and rate PLUS the wave, then (optionally)
%       through the notch, and only then into the controller.
%       계측에 파랑이 **더해진 뒤** 제어기로 들어간다. 배가 파랑을 따라 움직이는
%       것이 아니라, 제어기가 파랑을 **오차로 본다**는 것이 이번 주의 그림이다.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W07_0_setup');

M = struct( ...
  'name',   {'W07_C_wave','W07_D_no_filter','W07_E_notch','W07_G_slow','W07_H_tuning'}, ...
  'loop',   {false, true, true, true, true}, ...
  'notch',  {false, false, true, true, true}, ...
  'integral',{false, false, false, true, false}, ...
  'title',  {'THE SEA ON ITS OWN', 'THE LOOP THAT CHASES THE WAVES', ...
             'THE SAME LOOP, WITH A NOTCH', 'THE SLOW PART, WHICH MUST NOT BE FILTERED', ...
             'CHOOSING THE WIDTH OF THE NOTCH'}, ...
  'sec',    {'7-2','7-3','7-4','7-6','7-7'});
if nargin == 1, M = M(strcmp({M.name}, which)); end
for k = 1:numel(M), build_one(M(k), here); end
end

% =========================================================================
function build_one(o, here)
m = o.name;
out = fullfile(here, [m '.slx']);
bdclose(m);
if isfile(out), delete(out); end
new_system(m);
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','T_final', 'ReturnWorkspaceOutputs','off');
Y = 200;

%% 바다 / the sea — 시간의 함수, 정해진 위상이므로 매번 같다
add_block('simulink/Sources/Clock', [m '/clock'], 'Position', [80 Y-10 100 Y+10]);
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/wave'], ...
          'Position', [160 Y-55 340 Y+55]);
set_mlfcn([m '/wave'], wave_code(), 'psi_w', '[1 1]');
mlfcn_params([m '/wave'], {'w_i','a_i','phi_i','k_w','wave_on'});
route(m, 'clock', 1, 'wave', 1, zeros(0,2));
goto_at(m, {'clock', 1}, port_xy(m, 'clock', 'Outport', 1), 'down', 't_now');
goto_at(m, {'wave', 1}, port_xy(m, 'wave', 'Outport', 1), 'up', 'psi_w');
q = port_xy(m, 'wave', 'Outport', 2);
add_block('simulink/Signal Routing/Goto', [m '/Goto r_w'], 'GotoTag','r_w', ...
          'TagVisibility','local', 'ShowName','off', 'Position', [380 q(2)-9 440 q(2)+9]);
route(m, 'wave', 2, 'Goto r_w', 1, zeros(0,2));

if ~o.loop
    log_wave(m, 560);
else
    build_loop(m, o, Y);
end
note(m, o);
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r60', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-18s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
function build_loop(m, o, Y)
YL = Y + 200;                                    % 루프는 바다 아래 줄에 / the loop, one row below

%% 명령 / the command
add_block('simulink/Sources/Step', [m '/step'], 'Position', [80 YL-15 110 YL+15], ...
          'Time','t_step', 'Before','0', 'After','psi_step');
goto_at(m, {'step', 1}, port_xy(m, 'step', 'Outport', 1), 'down', 'psi_d');

%% 계측: 진짜 상태 + 파랑 / the measurement: the true state plus the wave
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/measurement'], ...
          'Position', [190 YL-55 380 YL+55]);
set_mlfcn([m '/measurement'], measurement_code(), 'psi_m', '[1 1]');
for i = 1:3
    tag = {'x','psi_w','r_w'};  tag = tag{i};
    q = port_xy(m, 'measurement', 'Inport', i);
    from_at(m, tag, [100 q(2)], ['From m ' tag]);
    route(m, ['From m ' tag], 1, 'measurement', i, zeros(0,2));
end

%% 노치 필터 둘 (있는 모델만) / the two notch filters, where the model has them
X = 430;
OUT = {'psi_f','r_f'};
if o.notch
    NM = {'notch heading','notch rate'};
    for i = 1:2
        nm = NM{i};
        p = port_xy(m, 'measurement', 'Outport', i);
        add_block('simulink/Continuous/Transfer Fcn', [m '/' nm], ...
                  'Numerator','[1 2*zeta_n*w0 w0^2]', 'Denominator','[1 2*zeta_d*w0 w0^2]', ...
                  'Position', [X p(2)-22 X+90 p(2)+22]);
        route(m, 'measurement', i, nm, 1, zeros(0,2));
        goto_at(m, {nm, 1}, port_xy(m, nm, 'Outport', 1), 'up', OUT{i});
    end
else
    for i = 1:2
        p = port_xy(m, 'measurement', 'Outport', i);
        goto_at(m, {'measurement', i}, p, 'up', OUT{i});
    end
end

%% 오토파일럿 / the autopilot — 4주차의 것, 계측만 바뀌었다
XA = X + 160;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/autopilot'], ...
          'Position', [XA YL-55 XA+190 YL+55]);
set_mlfcn([m '/autopilot'], autopilot_code(o), 'N', '[1 1]', 'h');
p = {'Kp','Kd','N_max'};
if o.integral, p = [p {'Ki','Kb','h'}]; end
mlfcn_params([m '/autopilot'], p);
for i = 1:3
    tag = {'psi_d','psi_f','r_f'};  tag = tag{i};
    q = port_xy(m, 'autopilot', 'Inport', i);
    from_at(m, tag, [XA-100 q(2)], ['From a ' tag]);
    route(m, ['From a ' tag], 1, 'autopilot', i, zeros(0,2));
end
goto_at(m, {'autopilot', 1}, port_xy(m, 'autopilot', 'Outport', 1), 'down', 'N');

%% 느린 외란 (있는 모델만) / the slow disturbance, where the model has it
XB = XA + 260;
src = {'autopilot', 1};
if o.integral
    add_block('simulink/User-Defined Functions/MATLAB Function', [m '/slow'], ...
              'Position', [XA XL(YL)-140 XA+190 XL(YL)-60]);
    set_mlfcn([m '/slow'], slow_code(), 'N_dist', '[1 1]');
    mlfcn_params([m '/slow'], {'N_slow','T_slow'});
    from_at(m, 't_now', [XA-100 port_xy(m, 'slow', 'Inport', 1)*[0;1]], 'From slow t');
    route(m, 'From slow t', 1, 'slow', 1, zeros(0,2));
    add_sum(m, 'hull moment', '++', [XB-50 YL]);
    route(m, 'autopilot', 1, 'hull moment', 1, zeros(0,2));
    q = port_xy(m, 'hull moment', 'Inport', 2);
    route(m, 'slow', 1, 'hull moment', 2, [XA+230 port_xy(m,'slow','Outport',1)*[0;1]; XA+230 q(2)]);
    src = {'hull moment', 1};
    XB = XB + 20;
end
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [XB YL-40 XB+180 YL+40]);
set_mlfcn([m '/allocation'], allocation_code(), 'n', '[2 1]');
mlfcn_params([m '/allocation'], {'X_ff','y_pont','k_pos','k_neg','T_max','T_min'});
route(m, src{1}, src{2}, 'allocation', 1, zeros(0,2));
goto_at(m, {'allocation', 1}, port_xy(m, 'allocation', 'Outport', 1), 'down', 'n');

%% Otter
cfg = otter_config('base');
XO = XB + 240;
add_otter_plant(m, 'Otter', [XO YL-30 XO+100 YL+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
p = port_xy(m, 'allocation', 'Outport', 1);  q = port_xy(m, 'Otter', 'Inport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2)-q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
p = port_xy(m, 'Otter', 'Outport', 1);
goto_at(m, {'Otter', 1}, [p(1)+30 p(2)], 'down', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [p(1)+70 p(2)-8 p(1)+86 p(2)+8]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

log_loop(m, XO + 220, YL);
end

% =========================================================================
function log_wave(m, X)
%  바다만 있는 모델: 두 신호를 Scope 와 로그로 / the sea alone: two signals
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','2', 'Position', [X+120 160 X+125 260]);
add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','2', 'Position', [X+200 100 X+250 200]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[2 1]', 'ShowLegend','on'); catch, end
for i = 1:2
    tag = {'psi_w','r_w'};  tag = tag{i};
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tag, [X q(2)], ['From log ' tag]);
    route(m, ['From log ' tag], 1, 'log', i, zeros(0,2));
    s = port_xy(m, 'Scope', 'Inport', i);
    from_at(m, tag, [X+120 s(2)], ['From sc ' tag]);
    route(m, ['From sc ' tag], 1, 'Scope', i, zeros(0,2));
end
set_param([m '/Scope'], 'Open','on');
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W07log'], 'VariableName','W07log', ...
          'SaveFormat','Structure With Time', 'Position', [X+300 p(2)-15 X+370 p(2)+15]);
route(m, 'log', 1, 'W07log', 1, zeros(0,2));
end

% =========================================================================
function log_loop(m, X, YL)
%  readouts: 도 단위로 바꾸고 회전수를 나눈다 / degrees, and the two shaft speeds
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], ...
          'Position', [X YL-80 X+180 YL+80]);
set_mlfcn([m '/readouts'], readouts_code(), 'psi_deg', '[1 1]');
for i = 1:4
    tag = {'x','psi_m','psi_f','n'};  tag = tag{i};
    q = port_xy(m, 'readouts', 'Inport', i);
    from_at(m, tag, [X-90 q(2)], ['From ro ' tag]);
    route(m, ['From ro ' tag], 1, 'readouts', i, zeros(0,2));
end
out = {'psi_deg','psi_m_deg','psi_f_deg','n1','n2','r_deg'};
for i = 1:6
    q = port_xy(m, 'readouts', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' out{i}], 'GotoTag',out{i}, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [X+210 q(2)-9 X+280 q(2)+9]);
    route(m, 'readouts', i, ['Goto ' out{i}], 1, zeros(0,2));
end

%  Scope 셋: 선수각(명령·진짜·계측), 모멘트, 회전수 / three panels
S = X + 320;
add_block('simulink/Signal Routing/Mux', [m '/headings'], 'Inputs','3', 'Position', [S+110 100 S+115 200]);
add_block('simulink/Signal Routing/Mux', [m '/shafts'], 'Inputs','2', 'Position', [S+110 320 S+115 380]);
add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','3', 'Position', [S+190 120 S+240 260]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[3 1]', 'ShowLegend','on'); catch, end
for i = 1:3
    tag = {'psi_d','psi_deg','psi_m_deg'};  tag = tag{i};
    q = port_xy(m, 'headings', 'Inport', i);
    from_at(m, tag, [S q(2)], ['From h ' tag]);
    route(m, ['From h ' tag], 1, 'headings', i, zeros(0,2));
end
route(m, 'headings', 1, 'Scope', 1, [S+150 port_xy(m,'headings','Outport',1)*[0;1]; ...
                                     S+150 port_xy(m,'Scope','Inport',1)*[0;1]]);
q = port_xy(m, 'Scope', 'Inport', 2);
from_at(m, 'N', [S q(2)], 'From sc N');
route(m, 'From sc N', 1, 'Scope', 2, zeros(0,2));
for i = 1:2
    tag = {'n1','n2'};  tag = tag{i};
    q = port_xy(m, 'shafts', 'Inport', i);
    from_at(m, tag, [S q(2)], ['From s ' tag]);
    route(m, ['From s ' tag], 1, 'shafts', i, zeros(0,2));
end
route(m, 'shafts', 1, 'Scope', 3, [S+150 port_xy(m,'shafts','Outport',1)*[0;1]; ...
                                   S+150 port_xy(m,'Scope','Inport',3)*[0;1]]);
set_param([m '/Scope'], 'Open','on');

%  로그: [psi_d psi psi_m psi_f N n1 n2 r] / eight columns
tags = {'psi_d','psi_deg','psi_m_deg','psi_f_deg','N','n1','n2','r_deg'};
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','8', 'Position', [S+420 100 S+425 460]);
for i = 1:8
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [S+330 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W07log'], 'VariableName','W07log', ...
          'SaveFormat','Structure With Time', 'Position', [S+470 p(2)-15 S+540 p(2)+15]);
route(m, 'log', 1, 'W07log', 1, zeros(0,2));
end

% =========================================================================
function C = wave_code()
C = {
'function [psi_w, r_w] = wave(t, w_i, a_i, phi_i, k_w, wave_on)'
'%#codegen'
'%  1차 파랑이 만드는 선수각과 그 변화율 / the wave-induced heading and its rate'
'%'
'%  스펙트럼 하나를 성분 여럿의 합으로 적는다. 진폭은 JONSWAP 에서 나오고 (wave_train),'
'%  위상은 정해져 있으므로 이 바다는 매번 똑같다 — 강의의 표를 재현할 수 있다.'
'%  One spectrum, written as a sum of components: the amplitudes come from JONSWAP'
'%  and the phases are fixed, so this sea is the same on every run.'
'%'
'%      psi_w(t) = k_w * sum_i a_i sin(w_i t + phi_i)          [deg]'
'%      r_w(t)   = k_w * sum_i a_i w_i cos(w_i t + phi_i)      [deg/s]'
'%'
'%  k_w 는 진폭 [m] 을 선수각 [deg] 으로 바꾸는 배율이다. 이 주차는 그 응답을'
'%  유도하지 않고 **주어진 것으로** 둔다 — 표준편차 sigma_psi 로 적는다.'
'%  k_w turns a wave amplitude into a heading. This week does not derive that'
'%  response; it takes it as given, stated by its standard deviation.'
'psi_w = 0;  r_w = 0;'
'if wave_on ~= 0'
'    for i = 1:numel(w_i)'
'        psi_w = psi_w + k_w*a_i(i)*sin(w_i(i)*t + phi_i(i));'
'        r_w   = r_w   + k_w*a_i(i)*w_i(i)*cos(w_i(i)*t + phi_i(i));'
'    end'
'end'
};
end

% =========================================================================
function C = slow_code()
C = {
'function N_dist = slow(t, N_slow, T_slow)'
'%#codegen'
'%  느린 외란: 바람과 2차 파랑 표류 / the slow disturbance: wind and wave drift'
'%'
'%  파랑(w0 = 3.14 rad/s)보다 두 자리 느리다. 노치는 이것을 **통과시켜야** 한다 —'
'%  걸러 버리면 제어기가 모르는 사이에 배가 밀려난다.'
'%  Two orders of magnitude slower than the waves at w0 = 3.14 rad/s. The notch'
'%  must **pass** this: filtered away, the vessel would be pushed off heading'
'%  without the controller ever seeing it.'
'N_dist = N_slow*(1 + 0.3*sin(2*pi*t/T_slow));'
};
end

% =========================================================================
function y = XL(YL)
y = YL;
end

% =========================================================================
function C = measurement_code()
C = {
'function [psi_m, r_m] = measurement(x, psi_w, r_w)'
'%#codegen'
'%  제어기가 보는 것 = 배가 실제로 하는 것 + 1차 파랑'
'%  What the controller sees = what the vessel really does + the first-order wave'
'%'
'%  배는 파랑을 따라 흔들리고 센서는 그것을 정직하게 잰다. 제어기에게는 그 흔들림이'
'%  **오차**로 보인다 — 그것이 이번 주가 다루는 상황이다.'
'%  The vessel oscillates with the sea and the sensor reports it truthfully; to the'
'%  controller that oscillation looks like error, which is the subject of this week.'
'psi_m = x(12)*180/pi + psi_w;    % [deg]'
'r_m   = x(6)*180/pi  + r_w;      % [deg/s]'
};
end

% =========================================================================
function C = autopilot_code(o)
if o.integral
    sig = 'function N = autopilot(psi_d, psi_m, r_m, Kp, Kd, N_max, Ki, Kb, h)';
else
    sig = 'function N = autopilot(psi_d, psi_m, r_m, Kp, Kd, N_max)';
end
C = {
sig
'%#codegen'
'%  4주차의 오토파일럿. 게인은 그대로다 — 바뀐 것은 계측뿐이다.'
'%  The Week 4 autopilot, gains unchanged; only the measurement is different.'
'%'
'%      N = Kp ssa(psi_d - psi_m) - Kd r_m,   |N| <= N_max'
'e = (psi_d - psi_m)*pi/180;'
'e = atan2(sin(e), cos(e));            % 감김 / the wrap of Week 4'
};
if o.integral
C = [C; {
'%  적분: 느린 외란(조류)이 남기는 오차를 없앤다. 파랑은 평균이 0 이므로'
'%  적분이 그것을 쌓지 않는다 — 그래서 노치와 적분은 함께 쓸 수 있다.'
'%  The integral removes what a slow disturbance leaves. A wave has zero mean,'
'%  so the integral does not accumulate it: the notch and the integral coexist.'
'persistent I'
'if isempty(I), I = 0; end'
'u = Kp*e + I - Kd*r_m*pi/180;'
'N = min(max(u, -N_max), N_max);'
'I = I + h*(Ki*e + Kb*(N - u));        % 되감기 방지 / back-calculation'
}];
else
C = [C; {
'u = Kp*e - Kd*r_m*pi/180;'
'N = min(max(u, -N_max), N_max);'
}];
end
end

% =========================================================================
function C = allocation_code()
C = {
'function n = allocation(N, X_ff, y_pont, k_pos, k_neg, T_max, T_min)'
'%#codegen'
'%  6주차의 배분: 정사각 규칙, 비율로 줄이기, 그리고 곡선의 역'
'%  The allocation of Week 6: the square rule, scaling, and the inverse curve'
'T1 = X_ff/2 + N/(2*y_pont);'
'T2 = X_ff/2 - N/(2*y_pont);'
's = 1;'
'if T1 > T_max, s = min(s, T_max/T1); end'
'if T2 > T_max, s = min(s, T_max/T2); end'
'if T1 < T_min, s = min(s, T_min/T1); end'
'if T2 < T_min, s = min(s, T_min/T2); end'
'T1 = s*T1;  T2 = s*T2;'
'k1 = k_pos;  if T1 < 0, k1 = k_neg; end'
'k2 = k_pos;  if T2 < 0, k2 = k_neg; end'
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'
};
end

% =========================================================================
function C = readouts_code()
C = {
'function [psi_deg, psi_m_deg, psi_f_deg, n1, n2, r_deg] = readouts(x, psi_m, psi_f, n)'
'%#codegen'
'%  표시와 기록만 한다 / display and logging only'
'psi_deg   = x(12)*180/pi;    % 배의 진짜 선수각 / the true heading'
'psi_m_deg = psi_m;           % 계측값 (진짜 + 파랑) / the measurement'
'psi_f_deg = psi_f;           % 제어기가 쓰는 값 / what the controller uses'
'n1 = n(1);  n2 = n(2);'
'r_deg = x(6)*180/pi;'
};
end

% =========================================================================
function from_at(m, tag, at, name)
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -50; else, dy = 50; end
at = round(at);
g = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag',tag, 'ShowName','off', ...
          'TagVisibility','local', 'Position', [at(1)+12 at(2)+dy-9 at(1)+82 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

function h = route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
h = add_line(sys, [a; via; b]);
end

function note(m, o)
L = {sprintf('WEEK 7, SECTION %s  -  %s', o.sec, o.title), '', ...
     '   psi_w(t) = k_w sum a_i sin(w_i t + phi_i)      one realisation of a JONSWAP sea', ...
     '   the measurement is the true heading PLUS psi_w: to the controller it looks like error', ''};
if o.notch
    L{end+1} = '   notch H(s) = (s^2 + 2 zeta_n w0 s + w0^2)/(s^2 + 2 zeta_d w0 s + w0^2)';
    L{end+1} = '   |H(j w0)| = zeta_n/zeta_d.  Setting zeta_n = zeta_d makes H(s) = 1: the filter is off.';
else
    L{end+1} = '   there is no filter in this model: the controller acts on the measurement as it arrives';
end
L = [L, {'', 'Change Hs, T0, sigma_psi, zeta_n or zeta_d in the Command Window and press Run.'}];
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
a.Position = [80 30 860 150];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
