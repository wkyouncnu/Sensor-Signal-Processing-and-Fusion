function [s, ins] = add_guidance(m, pos, laws)
%ADD_GUIDANCE  유도 서브시스템. **법칙 하나에 MATLAB Function 하나**이고,
%              그 모델이 쓰는 법칙만 들어간다.
%              The guidance subsystem: one MATLAB Function per law, and only
%              the laws the model actually uses.
%
%   [s, ins] = add_guidance(m, [300 30 520 610], 2)        LOS 만 / LOS alone
%   [s, ins] = add_guidance(m, pos, [3 4])                 두 적분기를 비교 / compare
%   [s, ins] = add_guidance(m, pos, [1 2 3])               셋을 비교 / compare three
%
%     laws   1 atan2 · 2 LOS · 3 ILOS(비선형 적분) · 4 ILOS(보통 적분)
%     ins    만들어진 입력 포트의 이름, 포트 순서대로. 최상위가 이것을 보고
%            Constant 를 붙인다 / the inport names in port order, so the caller
%            knows what to feed
%
%   왜 이렇게 바꿨는가 / why this replaced the single block
%       (사용자 지시, 2026-10-14: "W05_C_atan2.slx 예제에는 atan2 기반 guidance만
%       나오면 좋을 것 같아 ... 알고리즘을 각각 다 개발하고 ... subsystem으로 만들고
%       ... 외부 입력 값에 law를 받아서 ... 결정하면 좋을 것 같아")
%
%       법칙 넷을 한 블록에 넣고 if 로 고르면, atan2 절의 모델을 열어도 LOS 와
%       ILOS 의 코드가 같이 보인다. 그 절이 아직 설명하지 않은 것이 화면에 있으면
%       학생은 자기가 무엇을 읽어야 하는지 알 수 없다. 블록을 쪼개면 **그 절의
%       모델에는 그 절의 법칙만** 있고, 비교하는 절에서는 법칙들이 **나란히**
%       놓여 서로 다른 점이 도면에 보인다.
%
%       Four laws in one block, chosen by `if`, meant that opening the model of
%       the atan2 section also showed the code of LOS and ILOS. A section whose
%       model displays what the section has not yet explained leaves the reader
%       unable to tell what to read. Split into blocks, the model of a section
%       carries only that section's law, and a comparing section puts the laws
%       side by side so the difference is visible on the diagram.
%
%       **h 를 포함해 모든 값이 포트로 들어온다.** 예전에는 h 가 mlfcn_params 로
%       숨은 파라미터였고, 그러면 적분식의 스텝 크기가 도면에 없었다. 5-5 절은
%       바로 그 적분을 설명하는 절이다.
%       Every value, h included, now arrives through a port. As a hidden
%       parameter the step size of the integral did not appear on the diagram
%       at all, and 5-5 is the section about that integral.
%
%   상태 / the state
%       서브시스템은 `state` 를 받아 `state next` 를 낸다. 최상위의 Unit Delay 가
%       한 스텝 들고 있다. 상태의 폭은 **법칙이 정한다** — 적분을 쓰는 법칙이
%       없으면 [k; n_after] 둘이고, 있으면 [k; y_int; n_after] 셋이다. 적분 상태가
%       ILOS 모델에서만 나타나는 것이 5-5 절의 요점이고, 그것이 도면에 보인다.
%       The width of the state is decided by the laws: two components without an
%       integral law, three with one. That the integral state appears only in
%       the ILOS models is the point of 5-5, and here it can be seen.

laws = sort(laws(:)');

useDelta = any(laws >= 2);
useKappa = any(laws >= 3);
useInt   = any(laws >= 3);
useLaw   = numel(laws) > 1;

LEG = 'the active leg';

%  입력 포트. 순서는 읽는 순서다 — 배, 경로, 경로의 계수, 임무, 수치, 상태.
%  The inports, in reading order: the vessel, the path, the path's coefficients,
%  the mission, the numerics, the state.
ins = {'x','WP_N','WP_E'};
if useDelta, ins{end+1} = 'Delta';    end
ins{end+1} = 'R_switch';
if useKappa, ins{end+1} = 'kappa';    end
if useLaw,   ins{end+1} = 'law';      end
ins  = [ins, {'stop_at_end','stop_hold','h','state'}];
outs = {'psi_d','y_e','aux','wp','gate','stop','state next'};

%  블록의 **높이는 포트 수가 정한다.** 부르는 쪽은 중심선만 주고, 여기서 52 px
%  간격이 나오도록 중심을 유지한 채 위아래로 늘린다. 52 px 는 row_feed 의 최소
%  간격이고, 그보다 좁으면 밖에 세우는 Constant 들이 서로 닿는다.
%  The height follows the number of ports: the caller gives a centreline and the
%  block grows about it until the pitch is 52 px, which is row_feed's minimum —
%  any closer and the Constants outside begin to touch.
hgt = max(pos(4) - pos(2), 40 + 52*(numel(ins) - 1));
yc  = round((pos(2) + pos(4))/2);
pos = [pos(1) yc - round(hgt/2) pos(3) yc + round(hgt/2)];

s = add_subsys(m, 'guidance', pos, ins, outs, gnc_colour('reference'));

% -------------------------------------------------------------------------
%  위쪽 띠: 법칙 칸과 그것만 쓰는 입력들.
%  The top band: the law column and the inports only it uses.
TOPIN = {};
if useDelta, TOPIN{end+1} = 'Delta'; end
if useKappa, TOPIN{end+1} = 'kappa'; end
TOPIN{end+1} = 'h';
if useLaw,   TOPIN{end+1} = 'law';   end
for j = 1:numel(TOPIN)
    y = 40 + 52*(j-1);
    set_param([s '/' TOPIN{j}], 'Position', [60 y 90 y+20]);
end
yTop = 40 + 52*numel(TOPIN) + 40;

T  = law_table();
yb = yTop;
for i = 1:numel(laws)
    L   = T(laws(i));
    hgt = max(60, 40 + 34*(numel(L.in) - 1));
    add_block('simulink/User-Defined Functions/MATLAB Function', [s '/' L.name], ...
              'Position', [720 yb 1000 yb+hgt]);
    set_mlfcn([s '/' L.name], L.code, 'psi_d', '[1 1]', 'h');
    yb = yb + hgt + 50;
end
yLawBot = yb - 50;

% -------------------------------------------------------------------------
%  아래쪽 띠: 경로의 기하와 다리 전환. 법칙이 무엇이든 이것은 같다.
%  The lower band: path geometry and leg switching, the same whatever the law.
yLegs = yLawBot + 100;
yC    = yLegs - 50;                 % 두 띠 사이의 통로 / the corridor between them
add_block('simulink/User-Defined Functions/MATLAB Function', [s '/' LEG], ...
          'Position', [300 yLegs 620 yLegs+456]);
set_mlfcn([s '/' LEG], leg_code(), 'pi_p', '[1 1]', 'h');
row_feed(s, LEG, {'x','WP_N','WP_E','R_switch','stop_at_end','stop_hold','','',''});
lane_line(s, 'h', 1, LEG, 7, 200);

%  상태를 풀고 다시 묶는다 / unpack the state and pack it again
nSt = 2 + useInt;
add_block('simulink/Signal Routing/Demux', [s '/unpack state'], ...
          'Outputs', num2str(nSt), 'ShowName', 'off', ...
          'Position', [150 yLegs+500-15*nSt 155 yLegs+500+15*nSt]);
q = port_xy(s, 'unpack state', 'Inport', 1);
set_param([s '/state'], 'Position', [60 q(2)-10 90 q(2)+10]);
add_line(s, [port_xy(s, 'state', 'Outport', 1); q]);

add_block('simulink/Signal Routing/Mux', [s '/pack state'], ...
          'Inputs', num2str(nSt), 'ShowName', 'off', ...
          'Position', [1120 yLegs+410-25*nSt 1125 yLegs+410+25*nSt]);

lane_line(s, 'unpack state', 1,   LEG, 8, 160);
lane_line(s, 'unpack state', nSt, LEG, 9, 168);

% -------------------------------------------------------------------------
%  법칙에 신호를 넣는다. 통로 x 를 신호마다 하나씩 못박아 둔다 — 같은 x 를 두 신호가
%  쓰면 도면이 있지도 않은 연결을 주장한다.
%  Feed the laws. One named corridor per signal: two signals sharing an x make
%  the diagram claim a connection that does not exist.
LA = struct('to_wp',628, 'pi_p',636, 'y_e',644, 'y_int_p',652, ...
            'Delta',660, 'kappa',668, 'h',676);
for i = 1:numel(laws)
    L = T(laws(i));
    for p = 1:numel(L.in)
        switch L.in{p}
            case 'to_wp', lane_line(s, LEG, 3, L.name, p, LA.to_wp);
            case 'pi_p',  lane_line(s, LEG, 1, L.name, p, LA.pi_p);
            case 'y_e',   lane_line(s, LEG, 2, L.name, p, LA.y_e);
            case 'y_int_p'
                a = port_xy(s, 'unpack state', 'Outport', 2);
                b = port_xy(s, L.name, 'Inport', p);
                add_line(s, [a; 176 a(2); 176 yC; LA.y_int_p yC; LA.y_int_p b(2); b]);
            otherwise
                lane_line(s, L.in{p}, 1, L.name, p, LA.(L.in{p}));
        end
    end
end

%  쓰지 않는 양은 Terminator 로 보낸다. 지우지 않는다 — **이 법칙이 그것을 쓰지
%  않는다**는 것이 도면에서 읽히는 것이 낫다.
%  What a law does not use goes to a Terminator rather than being removed: that
%  this law ignores it is worth reading off the diagram.
if ~any(laws == 1)
    term_at(s, 'to_wp: only atan2 uses it', LEG, 3);
end
if all(laws == 1)
    term_at(s, 'pi_p: only the line-following laws use it', LEG, 1);
end

% -------------------------------------------------------------------------
%  psi_d 를 고른다 / choose psi_d
if useLaw
    add_block('simulink/Signal Routing/Multiport Switch', [s '/psi_d switch'], ...
              'DataPortOrder', 'Specify indices', ...
              'DataPortIndices', ['{' ilist(laws, ',') '}'], ...
              'Inputs', num2str(numel(laws)), ...
              'Position', [1060 yTop+20 1080 yTop+60+30*numel(laws)]);
    lane_line(s, 'law', 1, 'psi_d switch', 1, 1046);
    for i = 1:numel(laws)
        lane_line(s, T(laws(i)).name, 1, 'psi_d switch', 1+i, 998+8*i);
    end
    psiSrc = {'psi_d switch', 1};
else
    psiSrc = {T(laws).name, 1};
end

%  적분 상태를 고른다. 적분을 쓰지 않는 법칙은 **0 을 넣는다** — 그 법칙이 돌 때
%  적분기가 서 있다는 것이 Constant 하나로 보인다.
%  Choose the integral state. A law without an integral contributes a zero, so
%  that the integrator stands still under that law is visible as one Constant.
if useInt
    intLaws  = laws(laws >= 3);
    zeroLaws = laws(laws <  3);
    src = {};  idx = {};
    if ~isempty(zeroLaws)
        yz = yLawBot + 20;
        add_block('simulink/Sources/Constant', [s '/no integral'], 'Value', '0', ...
                  'Position', [720 yz 800 yz+26]);
        src{end+1} = {'no integral', 1};
        idx{end+1} = ['[' ilist(zeroLaws, ' ') ']'];
    end
    for i = 1:numel(intLaws)
        src{end+1} = {T(intLaws(i)).name, 2};
        idx{end+1} = sprintf('%d', intLaws(i));
    end
    if numel(src) > 1
        add_block('simulink/Signal Routing/Multiport Switch', [s '/integral switch'], ...
                  'DataPortOrder', 'Specify indices', ...
                  'DataPortIndices', ['{' strjoin(idx, ',') '}'], ...
                  'Inputs', num2str(numel(src)), ...
                  'Position', [1060 yLawBot-60-30*numel(src) 1080 yLawBot-20]);
        lane_line(s, 'law', 1, 'integral switch', 1, 1046);
        for i = 1:numel(src)
            lane_line(s, src{i}{1}, src{i}{2}, 'integral switch', 1+i, 1022+8*i);
        end
        auxSrc = {'integral switch', 1};
    else
        auxSrc = src{1};
    end
else
    yz = yLawBot + 20;
    add_block('simulink/Sources/Constant', [s '/no integral'], 'Value', '0', ...
              'Position', [1100 yz 1180 yz+26]);
    auxSrc = {'no integral', 1};
end

% -------------------------------------------------------------------------
%  다음 상태를 묶는다 / pack the next state
lane_line(s, LEG, 7, 'pack state', 1, 1086);
if useInt
    lane_line(s, auxSrc{1}, auxSrc{2}, 'pack state', 2, 1094);
    lane_line(s, LEG, 8, 'pack state', 3, 1102);
else
    lane_line(s, LEG, 8, 'pack state', 2, 1102);
end

%  출력 / the outputs
out_at(s, 'psi_d',      psiSrc{1}, psiSrc{2});
out_at(s, 'y_e',        LEG, 2);
out_at(s, 'aux',        auxSrc{1}, auxSrc{2});
out_at(s, 'wp',         LEG, 4);
out_at(s, 'gate',       LEG, 5);
out_at(s, 'stop',       LEG, 6);
out_at(s, 'state next', 'pack state', 1);
end

% =========================================================================
function t = ilist(v, sep)
%ILIST  정수 벡터를 '1,2,3' 또는 '1 2' 로 / an integer vector as a list
t = strjoin(arrayfun(@(z) sprintf('%d', z), v, 'UniformOutput', false), sep);
end

% =========================================================================
function out_at(s, name, src, k)
%OUT_AT  출력 포트를 공급 포트의 높이로 옮기고 곧은 선 하나로 잇는다.
%        Move the outport onto the height of what feeds it, and wire straight.
a = port_xy(s, src, 'Outport', k);
set_param([s '/' name], 'Position', [1210 a(2)-10 1240 a(2)+10]);
add_line(s, [a; port_xy(s, name, 'Inport', 1)]);
end

% =========================================================================
function term_at(s, name, src, k)
a = port_xy(s, src, 'Outport', k);
add_block('simulink/Sinks/Terminator', [s '/' name], ...
          'Position', [1140 a(2)-8 1156 a(2)+8]);
add_line(s, [a; port_xy(s, name, 'Inport', 1)]);
end

% =========================================================================
function T = law_table()
%LAW_TABLE  네 법칙. 이름 · 입력 이름(포트 순서) · 코드.
%           The four laws: name, input names in port order, and code.
%
%   블록 이름이 곧 법칙의 이름이다. W05_plot 의 law_name 이 **모델에서 이 이름을
%   읽어** 그림 제목을 쓴다 — 법칙 하나만 든 모델에는 law 플래그가 없기 때문이다.
%   The block name is the name of the law, and W05_plot reads it from the model
%   to title the figure: a model holding one law carries no `law` flag.

T(1).name = 'aim at the waypoint';
T(1).in   = {'to_wp'};
T(1).code = { ...
'function psi_d = aim_at_waypoint(to_wp)'
'%#codegen'
'%AIM_AT_WAYPOINT  법칙 1 — 다음 웨이포인트를 곧장 겨냥한다.'
'%                 Law 1: aim straight at the next waypoint.'
'%'
'%   to_wp 는 배에서 다음 웨이포인트까지의 벡터를 NE 로 적은 것이다.'
'%   to_wp is the vector from the vessel to the next waypoint, written in NE.'
'%'
'%   이 법칙은 **점**을 겨냥한다. 경로라는 선은 쓰지 않는다 - pi_p 도 y_e 도'
'%   들어오지 않는다. 그래서 배는 웨이포인트에 닿기는 하지만 다리 위에 있을'
'%   이유가 없고, 조류가 밀면 밀린 채로 점을 향한다.'
'%   It aims at a POINT. The line between the waypoints is never used: neither'
'%   pi_p nor y_e is an input here. The vessel therefore reaches the waypoint'
'%   without any reason to be on the leg, and a current carries it off the leg'
'%   while it still points at the point.'
'psi_d = atan2(to_wp(2), to_wp(1));'
'end'};

T(2).name = 'LOS';
T(2).in   = {'pi_p','y_e','Delta'};
T(2).code = { ...
'function psi_d = los(pi_p, y_e, Delta)'
'%#codegen'
'%LOS  법칙 2 — 경로 위에서 Delta 만큼 앞의 점을 겨냥한다.'
'%     Law 2: aim at the point Delta ahead on the path.'
'%'
'%         psi_d = pi_p - atan(y_e / Delta)'
'%'
'%   두 항이 각각 할 일이 있다. pi_p 는 "경로와 나란히 서라", atan 은 "벗어난'
'%   만큼 경로 쪽으로 기울여라".'
'%   The two terms each have a job: pi_p says "line up with the path", the atan'
'%   says "lean towards it by how far off you are".'
'%'
'%   y_e 가 작으면 atan(y_e/Delta) ~ y_e/Delta 이므로, 이것은 횡방향 오차에'
'%   대한 **P 제어기**이고 이득은 Kp = 1/Delta 다. Delta 를 줄이면 이득이'
'%   커진다 - P 제어기와 똑같이 빨라지다가 떨린다.'
'%   For small y_e, atan(y_e/Delta) ~ y_e/Delta: a P controller on the'
'%   cross-track error with Kp = 1/Delta. A smaller Delta is a larger gain, and'
'%   behaves like one - quicker, then oscillatory.'
'psi_d = pi_p - atan(y_e / Delta);'
'end'};

T(3).name = 'ILOS';
T(3).in   = {'pi_p','y_e','Delta','kappa','h','y_int_p'};
T(3).code = { ...
'function [psi_d, y_int_n] = ilos(pi_p, y_e, Delta, kappa, h, y_int_p)'
'%#codegen'
'%ILOS  법칙 3 — LOS 에 적분을 더한다. 횡방향 오차에 대한 PI 제어기.'
'%      Law 3: LOS plus an integral - a PI controller on the cross-track error.'
'%'
'%         psi_d = pi_p - atan( y_e/Delta + (kappa/Delta) y_int )'
'%'
'%   왜 필요한가 / why it is needed'
'%     조류가 배를 **계속** 옆으로 밀면 LOS 는 오차를 남긴다. P 제어기가 일정한'
'%     외란 아래에서 오차를 남기는 것과 같은 이유다: 오차가 0 이면 기울임도 0 이'
'%     되어 조류를 상쇄할 각이 남지 않는다. 적분이 그 각을 맡는다.'
'%     A current that keeps pushing leaves an error with LOS alone, for the same'
'%     reason a P controller does under a constant disturbance: at zero error'
'%     there is no lean left to cancel the current. The integral takes it over.'
'%'
'%   적분 상태는 포트로 들어오고 포트로 나간다 - 캔버스의 Unit Delay 가 한 스텝'
'%   들고 있다. 이 주차의 핵심인 상태가 블록 안에 숨지 않는다.'
'%   The integral state enters and leaves through ports; the Unit Delay on the'
'%   canvas holds it for one step, so the state this week is about is not hidden'
'%   inside the block.'
'psi_d = pi_p - atan(y_e/Delta + (kappa/Delta)*y_int_p);'
'%'
'%   적분 갱신. 분모가 y_e 와 함께 커지므로 멀리 벗어나 있을 때는 거의 적분하지'
'%   않는다 - **법칙 안에 들어 있는 안티와인드업**이다'
'%   (Borhaug, Pavlov, Pettersen 2008, DOI 10.1109/CDC.2008.4739352).'
'%   The denominator grows with y_e, so it barely integrates while far off the'
'%   path: anti-windup built into the law itself.'
'y_int_n = y_int_p + h * Delta*y_e / (Delta^2 + (y_e + kappa*y_int_p)^2);'
'end'};

T(4).name = 'ILOS, plain integral';
T(4).in   = {'pi_p','y_e','Delta','kappa','h','y_int_p'};
T(4).code = { ...
'function [psi_d, y_int_n] = ilos_plain(pi_p, y_e, Delta, kappa, h, y_int_p)'
'%#codegen'
'%ILOS_PLAIN  법칙 4 — 보통 적분을 쓴 ILOS (교과서가 적는 형태).'
'%            Law 4: ILOS with a plain integral, as a textbook would write it.'
'%'
'%         psi_d = pi_p - atan( y_e/Delta + (kappa/Delta) y_int ),  dy_int = y_e'
'%'
'%   겨냥하는 식은 법칙 3 과 **글자까지 같다.** 다른 것은 맨 아래 한 줄,'
'%   적분기의 갱신식뿐이다. 그래서 둘을 같은 임무에 돌리면 차이는 전부'
'%   적분기에서 온 것이다.'
'%   The aiming expression is identical to law 3, character for character. The'
'%   only difference is the last line, the integrator update, so a difference'
'%   between the two runs comes entirely from the integrator.'
'%'
'%   적분기가 오차를 **그대로** 쌓는다. 경로에서 멀리 떨어져 있을 때도 가까이'
'%   있을 때와 같은 속도로 쌓이므로, 첫 접근처럼 y_e 가 큰 구간에서 적분이 크게'
'%   자라고, 그 뒤 풀리면서 배를 경로 **반대쪽으로** 넘긴다.'
'%   The integral accumulates the error as it stands, at the same rate far from'
'%   the path as near it, so a long first approach winds it up and the unwinding'
'%   carries the vessel past the path.'
'psi_d = pi_p - atan(y_e/Delta + (kappa/Delta)*y_int_p);'
'y_int_n = y_int_p + h * y_e;'
'end'};
end

% =========================================================================
function C = leg_code()
%LEG_CODE  경로의 기하와 다리 전환. **법칙이 무엇이든 이것은 같다** - 그래서
%          법칙 블록 밖에 따로 있다.
%          Path geometry and leg switching: the same whatever the law, which is
%          why it sits outside the law blocks.
C = { ...
'function [pi_p, y_e, to_wp, wp, gate, stop, k_n, n_after_n] = active_leg(x, WP_N, WP_E, R_switch, stop_at_end, stop_hold, h, k_p, n_after_p)'
'%#codegen'
'%ACTIVE_LEG  어느 다리를 따라가는 중인가, 그 다리에서 얼마나 벗어났는가,'
'%            그리고 다음 다리로 넘어갈 때가 되었는가.'
'%            Which leg is being followed, how far off it the vessel is, and'
'%            whether it is time to move to the next leg.'
'%'
'%   유도 법칙이 무엇이든 이 계산은 같다. 법칙은 여기서 나온 pi_p 와 y_e 로'
'%   **겨냥하는 방법**만 정한다.'
'%   This is the same for every guidance law; a law only decides how to aim,'
'%   given the pi_p and y_e computed here.'
'%'
'%   입력 x 는 Otter 의 12 상태 (위치 N = x(7), E = x(8)).'
'%   The input x is the Otter 12 states, with position N = x(7), E = x(8).'
'%'
'%   출력 / outputs'
'%     pi_p       지금 다리의 방향 [rad] / the direction of the active leg'
'%     y_e        그 다리에서 옆으로 벗어난 거리 [m], 오른쪽이 +'
'%                distance off that leg, to the right positive'
'%     to_wp      배에서 다음 웨이포인트까지의 벡터 [dN; dE] - 법칙 1 만 쓴다'
'%                the vector to the next waypoint; only law 1 uses it'
'%     wp         지금 따라가는 다리 번호 / the leg being followed'
'%     gate       속도 명령에 곱하는 0/1. 임무가 끝나면 0 이 되어 배가 선다'
'%                0/1 multiplying the speed command: 0 once the mission is over'
'%     stop       시뮬레이션을 끝내라는 0/1 / 0/1 asking the run to end'
''
'% 0) 기억하는 값 둘이 **포트로 들어온다**: 지금 다리 k, 도착 뒤 스텝 수.'
'%    둘 다 **직전 스텝의** 값이다 - 캔버스의 Unit Delay 가 들고 있다가 돌려준다.'
'%    The two remembered values arrive through ports, and both are the values of'
'%    the PREVIOUS step: the Unit Delay on the canvas held them.'
'%'
'%    순서가 persistent 판과 비트 단위로 같게 만든다 / the order makes this exact'
'%      pi_p, x_e, y_e 와 to_wp 는 **옛** 다리로, wp 와 gate 는 **새** 다리로'
'%      구한다. 그래서 한 스텝의 모든 출력이 (x, 직전 상태) 만의 함수다.'
'%      The errors and to_wp come from the OLD leg, wp and the gate from the NEW'
'%      one, so every output of a step is a function of (x, previous state).'
'k = round(k_p);'
'n = numel(WP_N);'
'%    신호로 들어온 지표를 범위 안에 가둔다. 실제로 도달하는 값 위에서는 항등이다.'
'%    Clamp the index that arrives as a signal; the identity map on every value'
'%    it can actually take.'
'if k < 1, k = 1; end'
'if k > n-1, k = n-1; end'
'n_after = n_after_p;'
'N = x(7);  E = x(8);'
''
'% 1) 지금 다리: 웨이포인트 k 에서 k+1 로. 그 방향이 경로 각 pi_p 다.'
'%    The active leg runs from waypoint k to k+1; its direction is pi_p.'
'kn = min(k+1, n);'
'Nk = WP_N(k);   Ek = WP_E(k);'
'Nn = WP_N(kn);  En = WP_E(kn);'
'pi_p = atan2(En - Ek, Nn - Nk);'
''
'% 2) 배의 위치를 경로 좌표로 돌린다: x_e = 다리를 따라 간 거리,'
'%    y_e = 다리에서 옆으로 벗어난 거리.'
'%    Rotate the position into path coordinates: x_e along the leg, y_e off it.'
'dN = N - Nk;  dE = E - Ek;'
'x_e =  dN*cos(pi_p) + dE*sin(pi_p);'
'y_e = -dN*sin(pi_p) + dE*cos(pi_p);'
''
'%    법칙 1 이 쓰는 벡터. 선이 아니라 점을 겨냥하는 법칙이라 이것만 필요하다.'
'%    The vector law 1 uses: it aims at a point, not at the line, so this is all'
'%    it needs.'
'to_wp = [Nn - N; En - E];'
''
'% 3) 다리 끝까지 R_switch 보다 적게 남으면 다음 다리로 (MSS 와 같은 판정).'
'%    With less than R_switch left to the end of the leg, move on (as MSS does).'
'd = sqrt((Nn - Nk)^2 + (En - Ek)^2);'
'near_end = (d - x_e) < R_switch;'
'if near_end && k < n-1'
'    k = k + 1;'
'    near_end = false;          % 새 다리는 방금 시작했다 / the new leg has just begun'
'end'
'wp = k;'
''
'% 4) 임무의 끝. **마지막 다리**에서 같은 판정이 참이 되면 더 갈 곳이 없다.'
'%    다음 다리로 넘어가는 대신 속도 명령을 0 으로 내리고, stop_hold 초 뒤에'
'%    실행을 끝낸다. 그 몇 초는 배가 서는 모습을 보기 위한 것이다.'
'%    stop_at_end = 0 이면 둘 다 하지 않는다.'
'%    The end of the mission: when the same test becomes true on the LAST leg'
'%    there is nowhere to switch to, so the speed command is taken to zero and'
'%    the run ends stop_hold seconds later - seconds that are there so the'
'%    vessel can be seen slowing down. With stop_at_end = 0 neither happens.'
'arrived = near_end && k == n-1;'
'if arrived'
'    n_after = n_after + 1;'
'end'
'gate = 1;'
'stop = 0;'
'if stop_at_end > 0.5'
'    if n_after > 0'
'        gate = 0;'
'    end'
'    if n_after * h > stop_hold'
'        stop = 1;'
'    end'
'end'
''
'% 5) 다음 스텝으로 넘길 상태 / the state handed to the Unit Delay'
'k_n       = k;'
'n_after_n = n_after;'
'end'};
end
