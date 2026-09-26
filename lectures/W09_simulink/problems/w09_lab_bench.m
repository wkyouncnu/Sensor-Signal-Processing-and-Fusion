function w09_lab_bench(mdl, x0)
%W09_LAB_BENCH  9주차 실습에 주어지는 부분 — 2~8주차 전부.
%               What the Week 9 laboratory is given: Weeks 2 to 8, entire.
%
%   w09_lab_bench(mdl, x0)
%
%   왜 거의 전부를 주는가 / why almost everything is given
%       9주차는 **새 법칙을 만들지 않는다.** 여덟 주차를 한 배에 얹고, 각 주차가
%       무엇을 벌었는지 재는 주차다. 그러므로 실습이 다시 만들 것도 제어기가
%       아니다 — 어느 주차의 것도 아닌 한 조각, **임무 논리**다.
%
%       Week 9 adds no new law: it assembles the eight and measures what each
%       was worth. So the thing the laboratory builds is not a controller
%       either. It is the one piece that belongs to no single week — the
%       mission logic — and the two decisions inside it.
%
%   주어지는 것 / what is provided
%
%       wave          7주차의 바다 / the sea of Week 7. Tags psi_w, r_w
%       measurement   psi_m = psi + psi_w, r_m = r + r_w
%       notch x2      7주차의 필터 / the filter of Week 7. Tags psi_f, r_f
%       controller    3~5·8주차의 네 루프가 한 블록에 / the four loops of Weeks
%                     3, 4, 5 and 8, with one switch each. Tags tau, psi_d, y_e
%       allocation    6주차 / Week 6, with use_scale
%       Otter USV     1주차 / Week 1. Tag x
%       xlog, plog    the twelve states, and [psi_d ; y_e ; X ; N]
%
%   주어지지 않는 것, 그래서 문제인 것 / what is withheld
%
%       the mission: [wp ; mode] from the vessel's position, and the log slog.
%       The controller reads both as the tags wp and mode.
%
%   See also W09_P1_START, W09_CHECK, W09_S1_MISSION.

Y = 440;

%% ---- 7주차 · 바다 / the sea of Week 7 ---------------------------------
add_block('simulink/Sources/Clock', [mdl '/clock'], 'Position', [x0 Y-190 x0+20 Y-170]);
blk = [mdl '/wave'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+70 Y-240 x0+250 Y-140]);
set_mlfcn(blk, { ...
'function [psi_w, r_w] = wave(t, w_i, a_i, phi_i, k_w, wave_on)'
'%#codegen'
'%  7주차의 바다 그대로 / the sea of Week 7, unchanged'
'psi_w = 0;  r_w = 0;'
'if wave_on ~= 0'
'    for i = 1:numel(w_i)'
'        psi_w = psi_w + k_w*a_i(i)*sin(w_i(i)*t + phi_i(i));'
'        r_w   = r_w   + k_w*a_i(i)*w_i(i)*cos(w_i(i)*t + phi_i(i));'
'    end'
'end'}, 'psi_w', '[1 1]');
mlfcn_params(blk, {'w_i','a_i','phi_i','k_w','wave_on'});
add_line(mdl, 'clock/1', 'wave/1', 'autorouting','smart');
add_block('simulink/Signal Routing/Goto', [mdl '/t_now out'], 'GotoTag','t_now', ...
          'Position', [x0+30 Y-120 x0+90 Y-100]);
add_line(mdl, 'clock/1', 't_now out/1', 'autorouting','smart');
WT = {'psi_w','r_w'};
for i = 1:2
    add_block('simulink/Signal Routing/Goto', [mdl '/' WT{i} ' out'], ...
              'GotoTag', WT{i}, 'Position', [x0+290 Y-225+50*(i-1) x0+360 Y-205+50*(i-1)]);
    add_line(mdl, sprintf('wave/%d', i), [WT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 7주차 · 계측과 노치 / the measurement and the notch ---------------
blk = [mdl '/measurement'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+70 Y-70 x0+250 Y+50]);
set_mlfcn(blk, { ...
'function [psi_m, r_m] = measurement(x, psi_w, r_w)'
'%#codegen'
'%  제어기가 보는 것 = 배가 하는 것 + 1차 파랑 (7주차 §7-2)'
'psi_m = x(12)*180/pi + psi_w;'
'r_m   = x(6)*180/pi  + r_w;'}, 'psi_m', '[1 1]');
for i = 1:3
    tag = {'x','psi_w','r_w'};  tag = tag{i};
    add_block('simulink/Signal Routing/From', [mdl '/' tag ' meas'], 'GotoTag', tag, ...
              'Position', [x0-20 Y-60+38*(i-1) x0+50 Y-40+38*(i-1)]);
    add_line(mdl, [tag ' meas/1'], sprintf('measurement/%d', i), 'autorouting','smart');
end
NM = {'notch heading','notch rate'};  OUT = {'psi_f','r_f'};
for i = 1:2
    add_block('simulink/Continuous/Transfer Fcn', [mdl '/' NM{i}], ...
              'Numerator','[1 2*zeta_n*w0 w0^2]', 'Denominator','[1 2*zeta_d*w0 w0^2]', ...
              'Position', [x0+300 Y-75+80*(i-1) x0+390 Y-25+80*(i-1)]);
    add_line(mdl, sprintf('measurement/%d', i), [NM{i} '/1'], 'autorouting','smart');
    add_block('simulink/Signal Routing/Goto', [mdl '/' OUT{i} ' out'], ...
              'GotoTag', OUT{i}, 'Position', [x0+430 Y-60+80*(i-1) x0+500 Y-40+80*(i-1)]);
    add_line(mdl, [NM{i} '/1'], [OUT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 3~5·8주차 · 제어기 / the four loops -------------------------------
XC = x0 + 560;
blk = [mdl '/controller'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [XC Y-110 XC+240 Y+110]);
set_mlfcn(blk, controller_code(), 'tau', '[2 1]', 'h');
mlfcn_params(blk, {'WP_N','WP_E','Delta','kappa','u_d','Kp_u','Ki_u', ...
                   'Kp','Kd','Kp_x','Ki_x','Kd_x','e_min','X_max','N_max','N_open', ...
                   'use_Ki_u','use_ssa','use_Kd','use_ilos','use_scale','use_vane', ...
                   'hand_over','h'});
for i = 1:5
    tag = {'x','psi_f','r_f','wp','mode'};  tag = tag{i};
    add_block('simulink/Signal Routing/From', [mdl '/' tag ' ctrl'], 'GotoTag', tag, ...
              'Position', [XC-100 Y-95+45*(i-1) XC-30 Y-75+45*(i-1)]);
    add_line(mdl, [tag ' ctrl/1'], sprintf('controller/%d', i), 'autorouting','smart');
end
CT = {'tau','psi_d','y_e'};
for i = 1:3
    add_block('simulink/Signal Routing/Goto', [mdl '/' CT{i} ' out'], ...
              'GotoTag', CT{i}, 'Position', [XC+290 Y-90+70*(i-1) XC+360 Y-70+70*(i-1)]);
    add_line(mdl, sprintf('controller/%d', i), [CT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 6주차 · 배분 / the allocation -------------------------------------
XB = XC + 420;
blk = [mdl '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [XB Y-50 XB+180 Y+50]);
set_mlfcn(blk, alloc_code(), 'n', '[2 1]');
mlfcn_params(blk, {'y_pont','k_pos','k_neg','T_max','T_min','use_scale'});
add_line(mdl, 'controller/1', 'allocation/1', 'autorouting','smart');

%% ---- 1주차 · Otter -----------------------------------------------------
XO = XB + 250;
add_otter_plant(mdl, 'Otter USV', [XO Y-40 XO+150 Y+40], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'allocation/1', 'Otter USV/1', 'autorouting','smart');
add_block('simulink/Signal Routing/Goto', [mdl '/x out'], 'GotoTag','x', ...
          'Position', [XO+190 Y-10 XO+250 Y+10]);
add_line(mdl, 'Otter USV/1', 'x out/1', 'autorouting','smart');

%% ---- 로그 / the logs ---------------------------------------------------
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position', [XO+190 Y+90 XO+260 Y+130]);
add_block('simulink/Signal Routing/From', [mdl '/x for log'], 'GotoTag','x', ...
          'Position', [XO+90 Y+100 XO+160 Y+120]);
add_line(mdl, 'x for log/1', 'xlog/1', 'autorouting','smart');

%  로그는 **태그에서** 받는다. 출력 포트에서 가지를 치면 세 가닥이 한 열을
%  같이 내려가 선이 겹친다 — check_overlaps 가 0 이어야 끝난 것이다 (CLAUDE.md §5).
%  The log reads the TAGS. Branching off the output ports sends three strands
%  down one column and they overlap; check_overlaps must be 0.
add_block('simulink/Signal Routing/Mux', [mdl '/plog mux'], 'Inputs','3', ...
          'Position', [XB+140 Y+190 XB+145 Y+330]);
PT = {'psi_d','y_e','tau'};
for i = 1:3
    add_block('simulink/Signal Routing/From', [mdl '/' PT{i} ' log'], ...
              'GotoTag', PT{i}, 'Position', [XB+40 Y+200+55*(i-1) XB+110 Y+220+55*(i-1)]);
    add_line(mdl, [PT{i} ' log/1'], sprintf('plog mux/%d', i), 'autorouting','smart');
end
add_block('simulink/Sinks/To Workspace', [mdl '/plog'], ...
          'VariableName','plog', 'SaveFormat','Structure With Time', ...
          'Position', [XB+190 Y+240 XB+260 Y+280]);
add_line(mdl, 'plog mux/1', 'plog/1', 'autorouting','smart');
end

% =========================================================================
function C = controller_code()
%  9주차 강의의 controller 블록 그대로 / the lecture's controller block, verbatim
C = {
'function [tau, psi_d_out, y_e_out] = controller(x, psi_f, r_f, wp, mode, WP_N, WP_E, Delta, kappa, u_d, Kp_u, Ki_u, Kp, Kd, Kp_x, Ki_x, Kd_x, e_min, X_max, N_max, N_open, use_Ki_u, use_ssa, use_Kd, use_ilos, use_scale, use_vane, hand_over, h)'
'%#codegen'
'%  여덟 주차가 한 블록에. 모드에 따라 어느 줄이 도는지가 달라질 뿐이다.'
'%  Eight weeks in one block; the mode decides which lines run.'
'psi = x(12);  u = x(1);  v = x(2);'
'psi_m = psi_f*pi/180;  r_m = r_f*pi/180;      % 노치를 지난 계측 (7주차)'
'k = wp;  y_e = 0;'
'persistent I_u y_int In Ie psi_last'
'if isempty(I_u), I_u = 0; y_int = 0; In = 0; Ie = 0; psi_last = psi; end'
'if mode == 1'
'    %  ── 이동 / transit ────────────────────────────────────────────────'
'    if k > 1, N0 = WP_N(k-1);  E0 = WP_E(k-1);  else, N0 = 0;  E0 = 0;  end'
'    pi_p = atan2(WP_E(k) - E0, WP_N(k) - N0);'
'    y_e  = -(x(7) - N0)*sin(pi_p) + (x(8) - E0)*cos(pi_p);'
'    if use_ilos ~= 0'
'        psi_d = pi_p - atan((y_e + kappa*y_int)/Delta);'
'        y_int = y_int + h*Delta*y_e/(Delta^2 + (y_e + kappa*y_int)^2);'
'    else'
'        psi_d = pi_p - atan(y_e/Delta);'
'    end'
'    eu = u_d - u;'
'    X  = Kp_u*eu + I_u;'
'    X  = min(max(X, -X_max), X_max);'
'    if use_Ki_u ~= 0 && abs(X) < X_max - 1e-9, I_u = I_u + h*Ki_u*eu; end'
'    if hand_over ~= 0, In = 0;  Ie = 0; end'
'    psi_last = psi_d;'
'else'
'    %  ── 유지 / hold ──────────────────────────────────────────────────'
'    e_n = WP_N(k) - x(7);  e_e = WP_E(k) - x(8);'
'    v_n = u*cos(psi) - v*sin(psi);  v_e = u*sin(psi) + v*cos(psi);'
'    f_n = Kp_x*e_n + In - Kd_x*v_n;'
'    f_e = Kp_x*e_e + Ie - Kd_x*v_e;'
'    if use_vane ~= 0'
'        if hypot(f_n, f_e) > e_min, psi_last = atan2(f_e, f_n); end'
'        psi_d = psi_last;'
'    else'
'        psi_d = psi_last;'
'    end'
'    X = f_n*cos(psi) + f_e*sin(psi);'
'    X = min(max(X, -X_max), X_max);'
'    if abs(X) < X_max - 1e-9'
'        In = In + h*Ki_x*e_n;  Ie = Ie + h*Ki_x*e_e;'
'    end'
'    I_u = 0;'
'end'
'%  ── 4주차: 선수각 / the heading loop ─────────────────────────────────'
'if use_ssa ~= 0'
'    ee = atan2(sin(psi_d - psi_m), cos(psi_d - psi_m));'
'else'
'    ee = psi_d - psi_m;'
'end'
'N  = Kp*ee;'
'if use_Kd ~= 0, N = N - Kd*r_m; end'
'N_lim = N_max;'
'if use_scale == 0, N_lim = N_open; end'
'N  = min(max(N, -N_lim), N_lim);'
'if mode == 3, X = 0;  N = 0; end'
'tau = [X; N];  psi_d_out = psi_d*180/pi;  y_e_out = y_e;'
};
end

% =========================================================================
function C = alloc_code()
C = {
'function n = allocation(tau, y_pont, k_pos, k_neg, T_max, T_min, use_scale)'
'%#codegen'
'%  6주차의 배분 / the allocation of Week 6'
'T1 = tau(1)/2 + tau(2)/(2*y_pont);'
'T2 = tau(1)/2 - tau(2)/(2*y_pont);'
'if use_scale ~= 0'
'    s = 1;'
'    if T1 > T_max, s = min(s, T_max/T1); end'
'    if T2 > T_max, s = min(s, T_max/T2); end'
'    if T1 < T_min, s = min(s, T_min/T1); end'
'    if T2 < T_min, s = min(s, T_min/T2); end'
'    T1 = s*T1;  T2 = s*T2;'
'else'
'    T1 = min(max(T1, T_min), T_max);'
'    T2 = min(max(T2, T_min), T_max);'
'end'
'k1 = k_pos;  if T1 < 0, k1 = k_neg; end'
'k2 = k_pos;  if T2 < 0, k2 = k_neg; end'
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'
};
end
