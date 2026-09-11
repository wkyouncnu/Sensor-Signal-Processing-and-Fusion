function W01_G_build_rc()
%W01_G_BUILD_RC  W01_rc.slx 를 코드로 만든다 — RC 조종기로 모는 Otter, 추력 배분을 거쳐.
%
%   >> W01_G_build_rc
%
%   무엇을 만드는가
%     W01_interactive.slx (§F) 는 두 프로펠러 속도 n 을 직접 명령했다. 이 모델은
%     사람이 RC 조종기 스틱으로 "힘" 을 요구하고, 추력 배분(control allocation)이
%     그 힘을 n 으로 바꾼다. 신호 사슬은 MSS 데모와 같은 순서다 (gnc_chain).
%
%       RC transmitter --> Joystick --> Control allocation --> Otter USV --> Measurements
%       채널 넷 + 모드      스틱 -> 힘    힘 -> 추력 -> n        otter.m      로그, 실시간 화면
%       stick = [s_T; s_R]  tau_d = [X; N]  n = [n_L; n_R]
%
%   조종기 (강의 §G)
%     Mode 1 : 오른쪽 스틱 상하 = 스로틀,  왼쪽 스틱 좌우 = 러더
%     Mode 2 : 왼쪽 스틱 상하 = 스로틀,    왼쪽 스틱 좌우 = 러더
%     스로틀은 가운데가 정지, 위가 전진, 아래가 후진이다 (역회전 되는 ESC 와 같다).
%     슬라이더 하나가 조종기 채널 하나이고, 값 0 ~ 100 은 수신기 펄스 1000 ~ 2000 us 와
%     같은 역할을 한다. 50 이 가운데다.
%
%   추력 배분 (강의 §G, §1-10, 부록 A1)
%     [X; N] = Bxn [T_L; T_R],  Bxn = [1 1; y_p -y_p]   ->   T = Bxn^-1 tau_d
%     n = sign(T) sqrt(|T|/k),  k = k_pos (T >= 0), k_neg (T < 0)
%     n 을 [n_min, n_max] 로 자르고, 실제로 낸 힘 tau_a = Bxn k n|n| 을 함께 내보낸다
%
%   스크립트 없이 돈다. 변수는 모두 모델 작업공간에 있다 (standing-orders §8-4).
%   다시 만들어도 안전하다. 기존 W01_rc.slx 는 덮어쓴다.

m    = 'W01_rc';
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));                 % ...\GradCourse
out  = fullfile(here, [m '.slx']);

addpath(fullfile(root,'_tools'), here);
mss_path();
load_system('simulink_hmi_blocks');                % Radio Button
load_system('simulink_hmi_customizable_blocks');   % 세로 · 가로 슬라이더 — 조종기 스틱

cfg = otter_config('base');

bdclose(m);
if isfile(out), delete(out); end
new_system(m);

%  실시간(Pacing 1 배), Stop 까지 계속. BlockReduction 을 끄는 이유는 _tools/hmi_bind.m —
%  켜 두면 Constant 가 최적화로 사라져 실행 중에 바꿀 수 없는 경우가 생긴다.
set_param(m, 'SolverType','Fixed-step', 'Solver','ode4', 'FixedStep','h', ...
             'StartTime','0', 'StopTime','inf', ...
             'EnablePacing','on', 'PacingRate', 1, 'BlockReduction','off');

%% ---- 모델 작업공간 --------------------------------------------------------
%  플랜트가 읽는 값(mp … animate)과 추력 배분이 읽는 값. 배분의 값은 모두
%  otter_config 에서 온다 — 손으로 옮겨 적지 않는다.
Bxn   = cfg.B([1 3], :);                 % tau = B f 의 X, N 두 행. Y 행은 0 이라 뺀다
T_max =  cfg.k_pos * cfg.n_max^2;        % 한 프로펠러의 최대 전진 추력  119.68 N
T_min = -cfg.k_neg * cfg.n_min^2;        % 한 프로펠러의 최대 후진 추력  -66.71 N
mw = get_param(m, 'ModelWorkspace');
VV = struct('mp', 25, 'rp', [0.05 0 -0.35]', 'V_c', 0, 'beta_c', 0, ...
            'x0', zeros(12,1), 'h', 0.02, 'animate', 1, ...
            'k_pos', cfg.k_pos, 'k_neg', cfg.k_neg, ...
            'n_max', cfg.n_max, 'n_min', cfg.n_min, ...
            'Bxn', Bxn, 'Binv', inv(Bxn), ...
            'X_max', 2*T_max, ...                   % 스로틀 끝 = 두 프로펠러 최대 전진
            'N_max', 2*cfg.y_pont*abs(T_min), ...   % 러더 끝 = 전후진 힘이 0 인 채 낼 수 있는 최대 선회 모멘트
            'Xu_abs', 24.4*9.81/(6*0.5144));        % |X_u|, otter.m line 157 — 화면의 예측선
fn = fieldnames(VV);
for i = 1:numel(fn), assignin(mw, fn{i}, VV.(fn{i})); end

%% ---- the chain ------------------------------------------------------------
P = gnc_chain({'command','controller','allocation','plant','measurement'});
L = @(a,b) add_line(m, a, b, 'autorouting','smart');

%  1. command — 조종기와 수신기. 채널 네 개와 모드 스위치, 그리고 규칙 둘.
tx = add_subsys(m, 'RC transmitter', P.command, {}, {'stick'}, gnc_colour('command'));
CH = {'LX','LY','RX','RY'};
for i = 1:4
    add_block('simulink/Sources/Constant', [tx '/' CH{i}], 'Value','50', ...
              'Position', [40 20+60*i 90 44+60*i]);
end
add_block('simulink/Sources/Constant', [tx '/mode'], 'Value','2', 'Position',[40 330 90 354]);
add_block('simulink/Signal Routing/Mux', [tx '/channels'], 'Inputs','4', 'Position',[150 70 155 280]);
for i = 1:4, add_line(tx, [CH{i} '/1'], sprintf('channels/%d', i), 'autorouting','smart'); end

add_block('simulink/User-Defined Functions/MATLAB Function', [tx '/receiver'], ...
          'Position', [210 145 330 205]);
set_mlfcn([tx '/receiver'], { ...
'function s = receiver(c)'
'%#codegen'
'%RECEIVER  Four raw channels, 0..100 %, to four stick deflections, -1..+1.'
'%'
'%   c = [LX; LY; RX; RY]. A real receiver hands on a pulse of 1000..2000 us'
'%   per channel, 1500 us at the centre. The slider range 0..100 plays the'
'%   same role: 50 is the centre.'
'%'
'%   Inside +-db of the centre the output is exactly zero - the neutral zone'
'%   of an electronic speed controller - so a stick left near the centre'
'%   does not make the vessel creep.'
'db = 3;                                   % neutral zone [% of travel]'
'd  = c - 50;'
's  = sign(d) .* max(abs(d) - db, 0) / (50 - db);'
's  = min(max(s, -1), 1);'}, 's', '[4 1]');

add_block('simulink/User-Defined Functions/MATLAB Function', [tx '/Mode 1 or 2'], ...
          'Position', [390 170 510 250]);
set_mlfcn([tx '/Mode 1 or 2'], { ...
'function stick = mode_mix(s, mode)'
'%#codegen'
'%MODE_MIX  Pick the throttle and the rudder out of the four sticks.'
'%'
'%   s = [LX; LY; RX; RY], each -1..+1.'
'%   Mode 1 : throttle = right stick up-down (RY)'
'%   Mode 2 : throttle = left stick up-down  (LY)'
'%   In both modes the rudder is the left stick left-right (LX).'
'%   RX (aileron) and the up-down axis that is not the throttle (elevator)'
'%   have nothing to act on in a boat and are ignored.'
'if mode == 1'
'    thr = s(4);'
'else'
'    thr = s(2);'
'end'
'stick = [thr; s(1)];                      % [s_T; s_R]'}, 'stick', '[2 1]');
as_vector(tx, 'as vector', [560 190 600 230]);
add_line(tx, 'channels/1',    'receiver/1',    'autorouting','smart');
add_line(tx, 'receiver/1',    'Mode 1 or 2/1', 'autorouting','smart');
add_line(tx, 'mode/1',        'Mode 1 or 2/2', 'autorouting','smart');
add_line(tx, 'Mode 1 or 2/1', 'as vector/1',   'autorouting','smart');
add_line(tx, 'as vector/1',   'stick/1',       'autorouting','smart');

%  2. controller — 조이스틱. 스틱 [s_T; s_R] 를 힘 [X; N] 으로. 선박 DP 시스템의
%     조이스틱 모드가 하는 일과 같다: 스틱 편각에 비례하는 힘을 요구한다.
js = add_subsys(m, 'Joystick', P.controller, {'stick'}, {'tau_d'}, gnc_colour('controller'));
add_block('simulink/Math Operations/Gain', [js '/stick to force'], ...
          'Gain','diag([X_max N_max])', 'Multiplication','Matrix(K*u)', ...
          'Position', [150 55 230 95]);
add_line(js, 'stick/1',          'stick to force/1', 'autorouting','smart');
add_line(js, 'stick to force/1', 'tau_d/1',          'autorouting','smart');

%  3. allocation — 힘을 두 추력으로, 추력을 두 축 속도로, 그리고 실제로 낸 힘.
al = add_subsys(m, 'Control allocation', P.allocation, {'tau_d'}, {'n','tau_a'}, ...
                gnc_colour('allocation'));
add_block('simulink/Math Operations/Gain', [al '/B inverse'], ...
          'Gain','Binv', 'Multiplication','Matrix(K*u)', 'Position',[110 40 180 80]);
add_block('simulink/User-Defined Functions/MATLAB Function', [al '/thrust to n'], ...
          'Position', [230 35 350 85]);
set_mlfcn([al '/thrust to n'], { ...
'function n = thrust_to_n(T, k_pos, k_neg)'
'%#codegen'
'%THRUST_TO_N  Invert the propeller curve of sec. 1-10, one propeller at a time.'
'%'
'%   T = k n|n| with k = k_pos ahead and k_neg astern, so'
'%   n = sign(T) sqrt(|T| / k). The coefficient is chosen by the sign of the'
'%   demanded thrust, which is also the sign of the shaft speed.'
'n = zeros(2,1);'
'for i = 1:2'
'    if T(i) >= 0'
'        n(i) =  sqrt( T(i) / k_pos);'
'    else'
'        n(i) = -sqrt(-T(i) / k_neg);'
'    end'
'end'}, 'n', '[2 1]');
as_param([al '/thrust to n'], {'k_pos','k_neg'});
add_block('simulink/Discontinuities/Saturation', [al '/shaft limits'], ...
          'UpperLimit','n_max', 'LowerLimit','n_min', 'Position',[400 40 450 80]);
as_vector(al, 'n as vector', [500 40 540 80]);
add_block('simulink/User-Defined Functions/MATLAB Function', [al '/delivered thrust'], ...
          'Position', [230 135 350 185]);
set_mlfcn([al '/delivered thrust'], { ...
'function T = delivered_thrust(n, k_pos, k_neg)'
'%#codegen'
'%DELIVERED_THRUST  The thrust the propellers give at the saturated speed.'
'%'
'%   The same curve as otter.m lines 165-177. Below saturation this returns'
'%   the demanded thrust exactly; at saturation it returns less, and the'
'%   difference is what the operator asked for and did not get.'
'T = zeros(2,1);'
'for i = 1:2'
'    if n(i) > 0'
'        T(i) = k_pos * n(i) * abs(n(i));'
'    else'
'        T(i) = k_neg * n(i) * abs(n(i));'
'    end'
'end'}, 'T', '[2 1]');
as_param([al '/delivered thrust'], {'k_pos','k_neg'});
add_block('simulink/Math Operations/Gain', [al '/B'], ...
          'Gain','Bxn', 'Multiplication','Matrix(K*u)', 'Position',[400 140 450 180]);
as_vector(al, 'tau_a as vector', [500 140 540 180]);
add_line(al, 'tau_d/1',            'B inverse/1',        'autorouting','smart');
add_line(al, 'B inverse/1',        'thrust to n/1',      'autorouting','smart');
add_line(al, 'thrust to n/1',      'shaft limits/1',     'autorouting','smart');
add_line(al, 'shaft limits/1',     'n as vector/1',      'autorouting','smart');
add_line(al, 'n as vector/1',      'n/1',                'autorouting','smart');
add_line(al, 'shaft limits/1',     'delivered thrust/1', 'autorouting','smart');
add_line(al, 'delivered thrust/1', 'B/1',                'autorouting','smart');
add_line(al, 'B/1',                'tau_a as vector/1',  'autorouting','smart');
add_line(al, 'tau_a as vector/1',  'tau_a/1',            'autorouting','smart');

%  4. plant — W01_openloop 과 똑같은 선체.
add_otter_plant(m, 'Otter USV', P.plant, cfg);
set_param([m '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));

%  5. measurement — 태그 W01rc. 선체 상태 여섯 열 뒤에 n, tau_d, tau_a 를 기록한다.
add_measurement(m, P.measurement, 'W01rc', {'n','tau_d','tau_a'}, ...
                struct('dash', true, 'weekName', 'n, tau demanded, tau delivered'));

L('RC transmitter/1',     'Joystick/1');
L('Joystick/1',           'Control allocation/1');
L('Control allocation/1', 'Otter USV/1');
L('Otter USV/1',          'Measurements/1');
L('Control allocation/1', 'Measurements/2');
L('Joystick/1',           'Measurements/3');
L('Control allocation/2', 'Measurements/4');

mss_style(m);                            % Dashboard 블록은 이 뒤에 넣는다 (§8-4)

%% ---- 실시간 화면으로 가는 탭 ----------------------------------------------
%  요구한 힘, 낸 힘, n 의 지금 값은 실시간 화면의 제목에 숫자로 나온다. 그래서
%  캔버스에 Display 블록을 두지 않는다 — 세 신호가 이미 셋씩 갈라지고 있어서,
%  Display 셋을 더하면 선이 캔버스를 가로질러 얽힌다.
yD = P.command(4) + 110;
add_block('simulink/User-Defined Functions/MATLAB Function', [m '/to live view'], ...
          'Position', [P.measurement(1) yD P.measurement(3) yD+80]);
set_mlfcn([m '/to live view'], { ...
'function ok = to_live_view(tau_d, tau_a, n)'
'%#codegen'
'%TO_LIVE_VIEW  Hand the demand, the delivery and the shaft speeds to the live view.'
'%'
'%   The Animate block inside Measurements receives only the vessel states.'
'%   W01rc_animate reads these six numbers from here at every step.'
'coder.extrinsic(''setappdata'');'
'setappdata(0, ''W01rc_tap'', [tau_d(:); tau_a(:); n(:)]);'
'ok = 1;'}, 'ok', '1');
add_block('simulink/Sinks/Terminator', [m '/tap end'], ...
          'Position', [P.measurement(3)+40 yD+30 P.measurement(3)+60 yD+50]);
L('Joystick/1',           'to live view/1');
L('Control allocation/2', 'to live view/2');
L('Control allocation/1', 'to live view/3');
L('to live view/1',       'tap end/1');

%% ---- the transmitter : 몸체 그림 위에 스틱 넷과 모드 스위치 ---------------
%  몸체는 그림 주석이다. 주석은 블록 뒤에 그려지므로 슬라이더가 그 위에 얹힌다.
%  글자(스틱 이름, 모드별 역할)는 그림에 함께 그린다 — 블록 이름은 검은 글씨라
%  어두운 몸체 위에서 읽히지 않는다.
bx = 40;  by = yD + 220;  Wb = 720;  Hb = 470;
S = struct( ...                                   % 이름, 채널, 위치 (몸체 기준)
  'name', {'LY  left up-down', 'LX  left left-right', 'RY  right up-down', 'RX  right left-right'}, ...
  'ch',   {'LY', 'LX', 'RY', 'RX'}, ...
  'lib',  {'Vertical Slider', 'Horizontal Slider', 'Vertical Slider', 'Horizontal Slider'}, ...
  'pos',  {[80 60 160 270], [30 285 210 345], [560 60 640 270], [510 285 690 345]});
transmitter_body(m, [bx by bx+Wb by+Hb], S);
for i = 1:4
    blk = [m '/' S(i).name];
    add_block(['simulink_hmi_customizable_blocks/' S(i).lib], blk, ...
              'Position', S(i).pos + [bx by bx by], 'ShowName','off');
    hmi_bind(blk, [tx '/' S(i).ch]);
end
add_block('simulink_hmi_blocks/Radio Button', [m '/MODE'], ...
          'Position', [bx+255 by+95 bx+465 by+185]);
set_param([m '/MODE'], 'States', struct('Value', {1, 2}, ...
          'Label', {'MODE 1  (throttle right)', 'MODE 2  (throttle left)'}));
set_param([m '/MODE'], 'ButtonGroupName', 'MODE');
hmi_bind([m '/MODE'], [tx '/mode']);

%  버튼 셋 — 몸체 위쪽 줄
yB = by - 95;
image_button(m, 'START',  'sticks to neutral, from rest', [bx     yB bx+230 yB+75], ...
             [0.30 0.69 0.31], [0.12 0.40 0.12], 'W01rc_control(''start'')');
image_button(m, 'STOP',   'end the run',                  [bx+245 yB bx+475 yB+75], ...
             [0.85 0.26 0.20], [0.50 0.10 0.08], 'W01rc_control(''stop'')');
image_button(m, 'CENTRE', 'let go of the sticks',         [bx+490 yB bx+720 yB+75], ...
             [0.20 0.45 0.75], [0.08 0.22 0.45], 'W01rc_control(''centre'')');

%  안내문은 몸체 아래에 둔다. 오른쪽에 두면 캔버스가 넓어져 블록도 PNG 가
%  문서 한도 2000 px 를 넘는다 (vault_check §7).
note(m, [bx by+Hb+30 bx+Wb by+Hb+560], strjoin({ ...
'WEEK 1  -  AN RC TRANSMITTER, AND THE ALLOCATION BEHIND IT'
''
'1  Choose MODE 1 or MODE 2 on the transmitter.'
'2  Click START. Every stick goes to neutral and the vessel'
'   starts from rest. The live view opens on the right.'
'3  THROTTLE forward (up) = ahead, back (down) = astern,'
'   centre = stop.'
'      Mode 1 : throttle = RIGHT stick, up-down'
'      Mode 2 : throttle = LEFT stick,  up-down'
'4  RUDDER = LEFT stick, left-right, in both modes:'
'   left = turn to port, right = turn to starboard.'
'5  CENTRE releases every stick except the throttle,'
'   as the springs of a real transmitter do.'
''
'THE CHAIN'
'  stick [s_T ; s_R]   ->  Joystick   tau_d = [X_max s_T ; N_max s_R]'
'  tau_d [X ; N]       ->  B inverse  [T_L ; T_R]'
'  T                   ->  n = sign(T) sqrt(|T| / k)'
'  n, saturated        ->  Otter USV'
''
'WHAT TO WATCH  (live view, top right)'
'  open circle   demanded  tau_d'
'  orange dot    delivered tau_a'
'  apart = saturated: the sticks ask for more than the'
'  two propellers can give (sec. G, appendix A1-6)'}, newline));

%% ---- 모델을 열 때 경로를 스스로 잡는다 · 실행마다 탭을 비운다 -----------
set_param(m, 'PostLoadFcn', strjoin({ ...
    'p_ = fileparts(get_param(bdroot,''FileName''));' ...
    'addpath(p_, fullfile(fileparts(fileparts(p_)),''_tools''));' ...
    'mss_path(); clear p_'}, ' '));
set_param(m, 'StartFcn', 'if isappdata(0,''W01rc_tap''), rmappdata(0,''W01rc_tap''); end');
set_param(m, 'ReturnWorkspaceOutputs', 'off');

fprintf('  overlapping lines : %d\n', check_overlaps(m));
save_system(m, out);
export_diagram(m, fullfile(here, 'img'));
close_system(m, 0);
fprintf('  built  %s\n', out);
end

% -------------------------------------------------------------------------
function as_vector(sys, name, pos)
%  2x1 행렬 신호를 1-D 벡터로 편다. 로그의 Mux 는 벡터만 받는다 (W01_openloop 과 같은 규약).
add_block('simulink/Math Operations/Reshape', [sys '/' name], ...
          'OutputDimensionality','1-D array', 'Position', pos);
end

function as_param(blk, names)
%  MATLAB Function 의 인수 가운데 names 를 입력 포트가 아니라 파라미터로 바꾼다.
%  값은 모델 작업공간의 같은 이름 변수에서 온다 — 선이 늘지 않는다.
ch = find(sfroot, '-isa','Stateflow.EMChart', 'Path', blk);
for i = 1:numel(names)
    d = find(ch, '-isa','Stateflow.Data', 'Name', names{i});
    d.Scope = 'Parameter';
end
end

function transmitter_body(m, pos, S)
%  조종기 몸체 그림 — 둥근 어두운 판, 스틱 이름, 모드별 역할. 캔버스와 같은 크기로
%  그려 1:1 로 얹는다. 좌표는 몸체 왼쪽 위가 (0,0), 아래로 갈수록 y 가 커진다.
w = pos(3) - pos(1);   hgt = pos(4) - pos(2);
f  = figure('Visible','off', 'Color','w', 'Units','pixels', 'Position',[100 100 w hgt]);
ax = axes(f, 'Position',[0 0 1 1], 'YDir','reverse');
axis(ax,'off');  hold(ax,'on');  xlim(ax,[0 w]);  ylim(ax,[0 hgt]);
rectangle(ax, 'Position',[3 3 w-6 hgt-6], 'Curvature',[0.12 0.2], ...
          'FaceColor',[0.17 0.19 0.22], 'EdgeColor',[0.05 0.05 0.05], 'LineWidth',2);
txt = @(x,y,s,varargin) text(ax, x, y, s, 'Color','w', 'HorizontalAlignment','center', varargin{:});
txt(w/2, 30,  'RC TRANSMITTER', 'FontWeight','bold', 'FontSize',14);
txt(120, 30,  'LEFT STICK',  'FontWeight','bold', 'FontSize',11);
txt(w-120, 30, 'RIGHT STICK', 'FontWeight','bold', 'FontSize',11);
for i = 1:numel(S)                                   % 슬라이더 옆의 채널 이름
    p = S(i).pos;
    if startsWith(S(i).lib, 'Vertical')
        txt(p(1)-25, (p(2)+p(4))/2, S(i).ch, 'FontWeight','bold', 'FontSize',11);
    else
        txt((p(1)+p(3))/2, p(4)+14, S(i).ch, 'FontWeight','bold', 'FontSize',11);
    end
end
txt(w/2, 80, 'MODE switch', 'FontSize',10, 'Color',[0.8 0.8 0.8]);
c1 = [0.55 0.85 1.00];  c2 = [1.00 0.80 0.45];       % 스로틀 = 파랑, 러더 = 주황
L = { 'LY  up-down',      'THROTTLE in Mode 2  ·  elevator in Mode 1', c1
      'LX  left-right',   'RUDDER in both modes',                      c2
      'RY  up-down',      'THROTTLE in Mode 1  ·  elevator in Mode 2', c1
      'RX  left-right',   'aileron  ·  not used on a boat',            [0.7 0.7 0.7] };
for i = 1:4
    y = hgt - 78 + 17*(i-1);
    text(ax, 40,  y, L{i,1}, 'Color','w', 'FontSize',9, 'FontWeight','bold');
    text(ax, 170, y, L{i,2}, 'Color',L{i,3}, 'FontSize',9);
end
png = [tempname '.png'];
exportgraphics(f, png, 'Resolution', 96);
close(f);
h = Simulink.Annotation([m '/transmitter body']);
h.Position = pos;
h.setImage(png);
delete(png);
end

function note(m, pos, txt)
h = Simulink.Annotation([m '/note']);
h.Text = txt;
h.Position = pos;
h.HorizontalAlignment = 'left';
h.BackgroundColor = 'lightBlue';
end
