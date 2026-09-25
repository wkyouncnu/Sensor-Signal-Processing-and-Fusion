function W05_1_build_guidance(which)
%W05_1_BUILD_GUIDANCE  5주차 실습 모델 다섯 개를 코드로 만든다 — 절 하나에 모델 하나.
%                      Generate the five Week 5 models, one model per section.
%
%   실행 / to run
%       W05_1_build_guidance                 다섯 개 전부 / all five
%       W05_1_build_guidance('W05_D_LOS')    하나만 / one of them
%
%   모델 / the models
%       W05_C_atan2       다음 웨이포인트를 곧장 겨냥한다 / aim straight at the next waypoint
%       W05_D_LOS         LOS: 경로 위 Delta 앞의 점을 겨냥한다 / aim at a point Delta ahead on the path
%       W05_E_switching   LOS, 다섯 웨이포인트 임무 / LOS on the five-waypoint mission
%       W05_F_ILOS        ILOS: LOS + 적분 (조류에 맞선다) / LOS plus an integral, against a current
%       W05_G_tuning      ILOS, 임무 + 조류, 튜닝 순서 / ILOS, mission and current, the tuning order
%
%   모든 모델이 같은 모양이다 / every model has the same shape
%       guidance -> heading autopilot -> allocation -> Otter
%       세 블록은 모두 주석이 달린 MATLAB Function 이다. 두 번 누르면 식과 설명이 보인다.
%       The three blocks are commented MATLAB Functions; double-click to read them.
%       오른쪽: Scope (위: 횡방향 오차, 아래: 명령 선수각과 선수각) + XY Graph (항적).
%       On the right: a Scope (top: cross-track error; bottom: commanded and
%       actual heading) and an XY Graph that draws the track while it runs.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'_tools'), here);
evalin('base', 'W05_0_setup');

%  실험 하나에 모델 하나 (standing-orders §15-15). W05_F_LOS 는 W05_D_LOS 와 같은
%  LOS 법칙이지만 실험 5-5a 의 것이다 — 조류 속에서 LOS 가 남기는 오차를 재는 데 쓴다.
%  One model per experiment: W05_F_LOS carries the same LOS law as W05_D_LOS and
%  belongs to Experiment 5-5a, where the offset a current leaves is measured.
M = struct( ...
  'name',  {'W05_C_atan2','W05_D_LOS','W05_E_switching','W05_F_LOS','W05_F_ILOS','W05_G_tuning'}, ...
  'law',   {'atan2','LOS','LOS','LOS','ILOS','ILOS'}, ...
  'title', {'AIM AT THE NEXT WAYPOINT', 'LINE OF SIGHT, AND THE LOOK-AHEAD DISTANCE', ...
            'WAYPOINT SWITCHING ON A MISSION', 'LOS IN A CURRENT: THE OFFSET IT LEAVES', ...
            'A CURRENT, AND THE INTEGRAL (ILOS)', 'THE TUNING ORDER'}, ...
  'sec',   {'C','D','E','5-5a','F','G'});
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

%% 유도 / guidance
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/guidance'], ...
          'Position', [200 Y-80 420 Y+80]);
set_mlfcn([m '/guidance'], guidance_code(o.law), 'psi_d', '[1 1]', 'h');
mlfcn_params([m '/guidance'], {'WP_N','WP_E','Delta','R_switch','kappa','h'});
q = port_xy(m, 'guidance', 'Inport', 1);
from_at(m, 'x', [110 q(2)]);
route(m, 'From x', 1, 'guidance', 1, zeros(0,2));

%% 선수각 오토파일럿 / heading autopilot
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/heading autopilot'], ...
          'Position', [580 Y-50 760 Y+50]);
set_mlfcn([m '/heading autopilot'], autopilot_code(), 'N', '[1 1]');
mlfcn_params([m '/heading autopilot'], {'Kp','Kd','N_max'});
p1 = port_xy(m, 'guidance', 'Outport', 1);  a1 = port_xy(m, 'heading autopilot', 'Inport', 1);
route(m, 'guidance', 1, 'heading autopilot', 1, [500 p1(2); 500 a1(2)]);
a2 = port_xy(m, 'heading autopilot', 'Inport', 2);
add_block('simulink/Signal Routing/From', [m '/From x '], 'GotoTag','x', 'ShowName','off', ...
          'Position', [515 a2(2)-10 555 a2(2)+10]);
route(m, 'From x ', 1, 'heading autopilot', 2, zeros(0,2));
goto_at(m, {'guidance', 1}, [450 p1(2)], 'up', 'psi_d');
for i = 2:4                                   % y_e, aux, wp -> Goto 태그 / to Goto tags
    p = port_xy(m, 'guidance', 'Outport', i);
    tag = {'','y_e','aux','wp'};  tag = tag{i};
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' tag], 'GotoTag',tag, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [440 p(2)-9 485 p(2)+9]);
    route(m, 'guidance', i, ['Goto ' tag], 1, zeros(0,2));
end

%% 배분 / allocation
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/allocation'], ...
          'Position', [830 Y-30 1010 Y+30]);
set_mlfcn([m '/allocation'], allocation_code(), 'n', '[2 1]');
mlfcn_params([m '/allocation'], {'X_ff','y_pont','k_pos','k_neg'});
p = port_xy(m, 'heading autopilot', 'Outport', 1);  q = port_xy(m, 'allocation', 'Inport', 1);
set_param([m '/allocation'], 'Position', get_param([m '/allocation'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
route(m, 'heading autopilot', 1, 'allocation', 1, zeros(0,2));

%% Otter
cfg = otter_config('base');
add_otter_plant(m, 'Otter', [1080 Y-30 1180 Y+30], cfg);
set_param([m '/Otter'], 'BackgroundColor', gnc_colour('plant'));
p = port_xy(m, 'allocation', 'Outport', 1);  q = port_xy(m, 'Otter', 'Inport', 1);
set_param([m '/Otter'], 'Position', get_param([m '/Otter'], 'Position') + [0 1 0 1]*round(p(2) - q(2)));
q = port_xy(m, 'Otter', 'Inport', 1);
add_line(m, [p; q]);
p = port_xy(m, 'Otter', 'Outport', 1);
goto_at(m, {'Otter', 1}, [p(1)+30 p(2)], 'up', 'x');
add_block('simulink/Sinks/Terminator', [m '/end'], 'Position', [p(1)+70 p(2)-8 p(1)+86 p(2)+8]);
route(m, 'Otter', 1, 'end', 1, zeros(0,2));

measure(m, 1330);
note(m, o);
mss_style(m);
save_system(m, out);
print(['-s' m], '-dpng', '-r60', fullfile(here, 'img', [m '.png']));
n = check_overlaps(m);
close_system(m, 0);
fprintf('  built  %-20s (overlapping lines: %d)\n', [m '.slx'], n);
end

% =========================================================================
%  기록과 표시 / logging and display
%    readouts (MATLAB Function): psi_d, x -> 도 단위 선수각 둘, 북, 동 / two headings in degrees, north, east
%    Scope 위: 횡방향 오차 y_e,  아래: [psi_d psi] [deg];  XY Graph: 동쪽(가로) 대 북쪽(세로)
%    Scope top: cross-track error; bottom: [psi_d psi] [deg]; XY Graph: east (x) against north (y)
%    W05log = [y_e psi_d psi N E aux wp]  -> W05_read
function measure(m, X)
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/readouts'], ...
          'Position', [X+80 60 X+260 180]);
set_mlfcn([m '/readouts'], readouts_code(), 'psi_d_deg', '[1 1]');
q1 = port_xy(m, 'readouts', 'Inport', 1);  q2 = port_xy(m, 'readouts', 'Inport', 2);
from_at(m, 'psi_d', [X q1(2)], 'From psi_d');
from_at(m, 'x', [X q2(2)], 'From x r');
route(m, 'From psi_d', 1, 'readouts', 1, zeros(0,2));
route(m, 'From x r', 1, 'readouts', 2, zeros(0,2));
out = {'psi_d_deg','psi_deg','N','E'};
for i = 1:4
    p = port_xy(m, 'readouts', 'Outport', i);
    add_block('simulink/Signal Routing/Goto', [m '/Goto ' out{i}], 'GotoTag',out{i}, ...
              'TagVisibility','local', 'ShowName','off', 'Position', [X+290 p(2)-9 X+370 p(2)+9]);
    route(m, 'readouts', i, ['Goto ' out{i}], 1, zeros(0,2));
end

%  Scope: 위 y_e, 아래 [psi_d psi] / top y_e, bottom [psi_d psi]
S = X + 450;
add_block('simulink/Signal Routing/Mux', [m '/heading pair'], 'Inputs','2', 'Position', [S+100 100 S+105 160]);
add_block('simulink/Sinks/Scope', [m '/Scope'], 'NumInputPorts','2', 'Position', [S+180 50 S+230 150]);
try, set_param([m '/Scope'], 'LayoutDimensionsString','[2 1]', 'ShowLegend','on'); catch, end
s1 = port_xy(m, 'Scope', 'Inport', 1);
from_at(m, 'y_e', [S s1(2)], 'From y_e');
route(m, 'From y_e', 1, 'Scope', 1, zeros(0,2));
h1 = port_xy(m, 'heading pair', 'Inport', 1);  h2 = port_xy(m, 'heading pair', 'Inport', 2);
from_at(m, 'psi_d_deg', [S h1(2)], 'From psi_d_deg');
from_at(m, 'psi_deg', [S h2(2)], 'From psi_deg');
l1 = route(m, 'From psi_d_deg', 1, 'heading pair', 1, zeros(0,2));
l2 = route(m, 'From psi_deg', 1, 'heading pair', 2, zeros(0,2));
set_param(l1, 'Name','psi_d');  set_param(l2, 'Name','psi');
p = port_xy(m, 'heading pair', 'Outport', 1);  s2 = port_xy(m, 'Scope', 'Inport', 2);
route(m, 'heading pair', 1, 'Scope', 2, [S+140 p(2); S+140 s2(2)]);
set_param([m '/Scope'], 'Open','on');

%  XY Graph: 항적 / the track
add_block('simulink/Sinks/XY Graph', [m '/track'], 'Position', [S+180 210 S+230 270]);
set_param([m '/track'], 'xmin','-20', 'xmax','140', 'ymin','-20', 'ymax','140');
t1 = port_xy(m, 'track', 'Inport', 1);  t2 = port_xy(m, 'track', 'Inport', 2);
from_at(m, 'E', [S+60 t1(2)], 'From E');
from_at(m, 'N', [S+60 t2(2)], 'From N');
route(m, 'From E', 1, 'track', 1, zeros(0,2));
route(m, 'From N', 1, 'track', 2, zeros(0,2));

%  로그 / the log
tags = {'y_e','psi_d_deg','psi_deg','N','E','aux','wp'};
add_block('simulink/Signal Routing/Mux', [m '/log'], 'Inputs','7', 'Position', [S+400 40 S+405 320]);
for i = 1:7
    q = port_xy(m, 'log', 'Inport', i);
    from_at(m, tags{i}, [S+300 q(2)], ['From log ' tags{i}]);
    route(m, ['From log ' tags{i}], 1, 'log', i, zeros(0,2));
end
p = port_xy(m, 'log', 'Outport', 1);
add_block('simulink/Sinks/To Workspace', [m '/W05log'], 'VariableName','W05log', ...
          'SaveFormat','Structure With Time', 'Position', [S+450 p(2)-15 S+520 p(2)+15]);
route(m, 'log', 1, 'W05log', 1, zeros(0,2));
end

function C = readouts_code()
C = { ...
'function [psi_d_deg, psi_deg, N, E] = readouts(psi_d, x)'
'%#codegen'
'%READOUTS  Scope 와 XY Graph 에 보낼 값을 꺼낸다. 제어에는 쓰지 않는다.'
'%          Pick out what the Scope and the XY Graph show; not used for control.'
''
'% 1) 명령 선수각을 도로 / the commanded heading in degrees'
'psi_d_deg = psi_d * 180/pi;'
''
'% 2) 선수각은 x(12). 여러 번 돌면 360 도를 넘으므로 (-180, 180] 로 감아 psi_d 와 같은 범위로.'
'%    The heading is x(12); after turns it passes 360 deg, so it is wrapped into'
'%    (-180, 180], the range of psi_d.'
'psi_deg = atan2(sin(x(12)), cos(x(12))) * 180/pi;'
''
'% 3) 위치: 북 x(7), 동 x(8) / position: north x(7), east x(8)'
'N = x(7);  E = x(8);'
'end'};
end

% =========================================================================
%  MATLAB Function 코드 / the code of the MATLAB Function blocks
function C = guidance_code(law)
head = { ...
'function [psi_d, y_e, aux, wp] = guidance(x, WP_N, WP_E, Delta, R_switch, kappa, h)'
'%#codegen'
'%GUIDANCE  웨이포인트 목록과 배의 위치에서 명령 선수각 psi_d 를 만든다.'
'%          Make the commanded heading psi_d from the waypoint list and the position.'
'%'
'%   입력 x 는 Otter 의 12 상태 (위치 N = x(7), E = x(8)). 나머지는 작업공간 변수.'
'%   The input x is the Otter''s 12 states (position N = x(7), E = x(8));'
'%   the rest are workspace variables (W05_0_setup).'
'%'
'%   출력 / outputs'
'%     psi_d  명령 선수각 [rad] -> 선수각 오토파일럿 / commanded heading -> the autopilot'
'%     y_e    횡방향 오차 [m], 경로 오른쪽이 + / cross-track error, right of the path +'
'%     aux    ILOS 의 적분 상태 (다른 법칙은 0) / the ILOS integral (0 for other laws)'
'%     wp     지금 따라가는 다리 번호 / the leg being followed'
''
'% 0) 기억하는 값: 지금 다리 k, 적분 y_int. 블록이 가지고 있다가 실행마다 처음으로 돌아간다.'
'%    Remembered values: the leg k and the integral y_int. The block owns them,'
'%    and they start afresh on every run.'
'persistent k y_int'
'if isempty(k), k = 1; y_int = 0; end'
'N = x(7);  E = x(8);'
'n = numel(WP_N);'
''
'% 1) 지금 다리: 웨이포인트 k 에서 k+1 로. 그 방향이 경로 각 pi_p 다.'
'%    The active leg runs from waypoint k to k+1; its direction is the path angle pi_p.'
'kn = min(k+1, n);'
'Nk = WP_N(k);   Ek = WP_E(k);'
'Nn = WP_N(kn);  En = WP_E(kn);'
'pi_p = atan2(En - Ek, Nn - Nk);'
''
'% 2) 배의 위치를 경로 좌표로 돌린다: x_e = 다리를 따라 간 거리, y_e = 다리에서 옆으로 벗어난 거리.'
'%    Rotate the position into path coordinates: x_e = distance along the leg,'
'%    y_e = distance off it, to the side.'
'dN = N - Nk;  dE = E - Ek;'
'x_e =  dN*cos(pi_p) + dE*sin(pi_p);'
'y_e = -dN*sin(pi_p) + dE*cos(pi_p);'
''
'% 3) 다리 끝까지 R_switch 보다 적게 남으면 다음 다리로 (MSS 와 같은 판정).'
'%    With less than R_switch left to the end of the leg, move to the next leg'
'%    (the same test as MSS).'
'd = sqrt((Nn - Nk)^2 + (En - Ek)^2);'
'if (d - x_e) < R_switch && k < n-1'
'    k = k + 1;'
'end'
'wp = k;'
'aux = y_int;'
''};
switch law
    case 'atan2'
        body = { ...
'% 4) 법칙: 다음 웨이포인트를 곧장 겨냥한다. 점까지의 방향이지 선까지가 아니다.'
'%    The law: aim straight at the next waypoint. It points at a POINT, not at the LINE.'
'psi_d = atan2(En - E, Nn - N);'
'end'};
    case 'LOS'
        body = { ...
'% 4) 법칙 LOS: 경로 위에서 Delta 만큼 앞의 점을 겨냥한다.'
'%        psi_d = pi_p - atan(y_e / Delta)'
'%    pi_p 는 "경로와 나란히", atan 은 "벗어난 만큼 경로 쪽으로 기울여라".'
'%    y_e 가 작으면 atan(y_e/Delta) ~ y_e/Delta: 횡방향 오차에 대한 P 제어기, Kp = 1/Delta.'
'%    The law LOS: aim at the point Delta ahead on the path.'
'%    pi_p says "line up with the path"; the atan says "lean towards it by how'
'%    far off you are". For small y_e, atan(y_e/Delta) ~ y_e/Delta: a P'
'%    controller on the cross-track error with Kp = 1/Delta.'
'psi_d = pi_p - atan(y_e / Delta);'
'end'};
    case 'ILOS'
        body = { ...
'% 4) 법칙 ILOS: LOS 에 적분을 더한다 — 횡방향 오차에 대한 PI 제어기.'
'%        psi_d = pi_p - atan(y_e/Delta + (kappa/Delta) y_int)'
'%    조류가 배를 계속 밀면 LOS 는 오차를 남긴다 (P 가 남기는 오차와 같다). 적분이 그만큼을 맡는다.'
'%    The law ILOS: LOS plus an integral — a PI controller on the cross-track'
'%    error. A current that keeps pushing leaves an error with LOS alone (the'
'%    error P leaves); the integral takes it over.'
'psi_d = pi_p - atan(y_e/Delta + (kappa/Delta)*y_int);'
''
'% 5) 적분 갱신. 분모가 y_e 와 함께 커지므로 멀리 벗어나 있을 때는 거의 적분하지 않는다:'
'%    법칙 안에 들어 있는 안티와인드업이다 (Borhaug, Pavlov, Pettersen 2008).'
'%    Update the integral. The denominator grows with y_e, so it barely'
'%    integrates while far off the path: anti-windup built into the law.'
'y_int = y_int + h * Delta*y_e / (Delta^2 + (y_e + kappa*y_int)^2);'
'end'};
end
C = [head; body];
end

function C = autopilot_code()
C = { ...
'function N = autopilot(psi_d, x, Kp, Kd, N_max)'
'%#codegen'
'%AUTOPILOT  4주차 게인의 선수각 오토파일럿. 명령 선수각 psi_d 를 따라가도록 요 모멘트 N 을 낸다.'
'%           A heading autopilot with the Week 4 gains: the yaw moment N that follows psi_d.'
'%'
'%   이번 주에는 튜닝하지 않는다 — 그 앞의 유도 법칙만 바꾼다.'
'%   It is not retuned this week; only the guidance law in front of it changes.'
''
'% 1) 선수각 오차를 (-pi, pi] 로 감는다 (ssa, 4주차 §4-6).'
'%    Wrap the heading error into (-pi, pi] (ssa, Week 4 section 4-6).'
'psi = x(12);  r = x(6);'
'e = atan2(sin(psi_d - psi), cos(psi_d - psi));'
''
'% 2) P 는 오차에, D 는 측정한 요각속도 r 에. 명령이 계단으로 바뀌어도 킥이 없다.'
'%    P on the error, D on the measured yaw rate r: no kick when psi_d jumps.'
'N = Kp*e - Kd*r;'
''
'% 3) 두 프로펠러가 낼 수 있는 만큼으로 자른다 / limit to what the propellers can give'
'N = min(max(N, -N_max), N_max);'
'end'};
end

function C = allocation_code()
C = { ...
'function n = allocation(N, X_ff, y_pont, k_pos, k_neg)'
'%#codegen'
'%ALLOCATION  요 모멘트 N 을 두 프로펠러의 축 회전수 n 으로 (4주차와 같다).'
'%            The yaw moment N to the two shaft speeds n (as in Week 4).'
''
'% 1) 둘 다 X_ff 의 절반씩 밀고, 모멘트는 한쪽을 더, 다른 쪽을 덜 밀어 만든다.'
'%    Both push half of X_ff; the moment comes from pushing one side harder.'
'T = [X_ff/2 + N/(2*y_pont);      % 좌현 / port'
'     X_ff/2 - N/(2*y_pont)];     % 우현 / starboard'
''
'% 2) 프로펠러 곡선 T = k n|n| 을 n 에 대해 푼다 (앞 k_pos, 뒤 k_neg).'
'%    Solve the propeller curve T = k n|n| for n (k_pos ahead, k_neg astern).'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        n(i) =  sqrt( T(i) / k_pos);'
'    else'
'        n(i) = -sqrt(-T(i) / k_neg);'
'    end'
'end'
'end'};
end

% =========================================================================
function from_at(m, tag, at, name)
if nargin < 4, name = ['From ' tag]; end
add_block('simulink/Signal Routing/From', [m '/' name], 'GotoTag',tag, 'ShowName','off', ...
          'Position', round([at(1) at(2)-10 at(1)+75 at(2)+10]));
end

function goto_at(m, src, at, dirn, tag)
if strcmp(dirn, 'up'), dy = -38; else, dy = 38; end
at = round(at);
g = ['Goto ' tag];
add_block('simulink/Signal Routing/Goto', [m '/' g], 'GotoTag',tag, 'ShowName','off', ...
          'TagVisibility','local', 'Position', [at(1)+12 at(2)+dy-9 at(1)+72 at(2)+dy+9]);
route(m, src{1}, src{2}, g, 1, [at; at(1) at(2)+dy]);
end

function h = route(sys, src, sp, dst, dp, via)
a = port_xy(sys, src, 'Outport', sp);
b = port_xy(sys, dst, 'Inport', dp);
h = add_line(sys, [a; via; b]);
end

function note(m, o)
L = {sprintf('WEEK 5, SECTION %s  -  %s', o.sec, o.title), '', ...
     '   guidance -> heading autopilot (Week 4) -> allocation -> Otter', ...
     '   double-click a block to read its code and comments', ''};
switch o.law
    case 'atan2', L{end+1} = '   psi_d = atan2(E_next - E, N_next - N)';
    case 'LOS',   L{end+1} = '   psi_d = pi_p - atan(y_e / Delta)            a P controller on y_e, Kp = 1/Delta';
    case 'ILOS',  L{end+1} = '   psi_d = pi_p - atan(y_e/Delta + (kappa/Delta) y_int)   a PI controller on y_e';
end
L = [L, {'', 'Change Delta, R_switch, kappa or V_c in the Command Window and press Run:', ...
         'the Scope shows the cross-track error and the heading; the XY Graph draws the track.'}];
a = Simulink.Annotation([m '/note']);
a.Text = strjoin(L, newline);
a.Position = [40 330 760 470];
a.HorizontalAlignment = 'left';  a.BackgroundColor = 'lightBlue';
end
