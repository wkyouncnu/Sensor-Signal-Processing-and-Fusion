function w07_lab_bench(mdl, x0)
%W07_LAB_BENCH  7주차 실습에 주어지는 부분 — 바다, 느린 외란, 배분, 선체.
%               What the Week 7 laboratory is given: the sea, the slow
%               disturbance, the allocation and the hull.
%
%   w07_lab_bench(mdl, x0)
%
%   왜 이것들을 주는가 / why these are given
%       7주차의 문제는 **계측 경로**를 만드는 것이다 — 파랑이 섞인 신호를 만들고,
%       거기서 따라갈 수 없는 부분만 덜어 내는 일. 바다를 다시 만들거나 6주차의
%       배분을 다시 쓰게 하면 시간이 그쪽으로 가고, 무엇보다 바다가 학생마다
%       달라지면 강의에서 잰 수치를 합격선으로 쓸 수 없다.
%
%       The Week 7 problems are about the measurement path: forming the signal
%       the sensor really produces, and taking out of it only the part that
%       cannot be followed. Rebuilding the sea or Week 6's allocation would
%       spend the hour elsewhere — and a sea that differed between students
%       would make the lecture's measured numbers useless as a pass mark.
%
%   주어지는 것 / what is provided
%
%       wave        t -> [psi_w ; r_w], one fixed realisation of a JONSWAP sea
%                   (wave_train). Tags psi_w and r_w, in deg and deg/s
%       step        the commanded heading. Tag psi_d, in deg
%       slow        the wind and second-order drift of 7-6. Tag N_dist, in N m
%       sum         N_ctrl + N_dist, so the disturbance enters where the sea
%                   puts it: on the hull, after the controller
%       allocation  Week 6's, unchanged
%       Otter USV   n -> twelve states. Tag x
%       xlog        the twelve states
%
%   주어지지 않는 것, 그래서 문제인 것 / what is withheld
%
%       the measurement, the notch, the autopilot, and the log flog.
%       Their moment is published back to the bench as the tag N_ctrl.
%
%   See also W07_P1_START, W07_CHECK, W07_S1_NOTCH.

%% ---- 바다 / the sea ----------------------------------------------------
add_block('simulink/Sources/Clock', [mdl '/clock'], 'Position', [x0 106 x0+20 126]);
blk = [mdl '/wave'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+70 60 x0+250 170]);
set_mlfcn(blk, { ...
'function [psi_w, r_w] = wave(t, w_i, a_i, phi_i, k_w, wave_on)'
'%#codegen'
'%  1차 파랑이 만드는 선수각과 그 변화율 / the wave-induced heading and its rate'
'%'
'%      psi_w(t) = k_w sum_i a_i sin(w_i t + phi_i)        [deg]'
'%      r_w(t)   = k_w sum_i a_i w_i cos(w_i t + phi_i)    [deg/s]'
'%'
'%  위상이 정해져 있으므로 이 바다는 매번 똑같다 — 강의의 표를 재현할 수 있다.'
'%  The phases are fixed, so this sea is the same on every run and the'
'%  lecture''s table can be reproduced.'
'psi_w = 0;  r_w = 0;'
'if wave_on ~= 0'
'    for i = 1:numel(w_i)'
'        psi_w = psi_w + k_w*a_i(i)*sin(w_i(i)*t + phi_i(i));'
'        r_w   = r_w   + k_w*a_i(i)*w_i(i)*cos(w_i(i)*t + phi_i(i));'
'    end'
'end'}, 'psi_w', '[1 1]');
mlfcn_params(blk, {'w_i','a_i','phi_i','k_w','wave_on'});
add_line(mdl, 'clock/1', 'wave/1', 'autorouting','smart');
WT = {'psi_w','r_w'};
for i = 1:2
    add_block('simulink/Signal Routing/Goto', [mdl '/' WT{i} ' out'], ...
              'GotoTag', WT{i}, 'Position', [x0+290 75+55*(i-1) x0+360 95+55*(i-1)]);
    add_line(mdl, sprintf('wave/%d', i), [WT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 명령 / the commanded heading --------------------------------------
add_block('simulink/Sources/Step', [mdl '/step'], ...
          'Time','t_step', 'Before','0', 'After','psi_step', ...
          'Position', [x0 210 x0+30 240]);
add_block('simulink/Signal Routing/Goto', [mdl '/psi_d out'], 'GotoTag','psi_d', ...
          'Position', [x0+70 215 x0+140 235]);
add_line(mdl, 'step/1', 'psi_d out/1', 'autorouting','smart');

%% ---- 느린 외란 / the slow disturbance of 7-6 ---------------------------
blk = [mdl '/slow'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+70 280 x0+250 380]);
set_mlfcn(blk, { ...
'function N_dist = slow(t, N_slow, T_slow)'
'%#codegen'
'%  바람과 2차 파랑 표류를 한 신호로 / wind and second-order drift, as one signal'
'%'
'%  파랑(w0 = 3.14 rad/s)보다 두 자리 느리다. 노치는 이것을 **통과시켜야** 한다 —'
'%  걸러 버리면 제어기가 모르는 사이에 배가 밀려난다.'
'%  Two decades below the waves. The notch must PASS this: filtered away, the'
'%  vessel would be pushed off heading without the controller ever seeing it.'
'N_dist = N_slow*(1 + 0.3*sin(2*pi*t/T_slow));'}, 'N_dist', '[1 1]');
mlfcn_params(blk, {'N_slow','T_slow'});
add_block('simulink/Signal Routing/From', [mdl '/clock for slow'], ...
          'GotoTag','t_now', 'Position', [x0-10 320 x0+50 340]);
add_block('simulink/Signal Routing/Goto', [mdl '/t_now out'], 'GotoTag','t_now', ...
          'Position', [x0+30 150 x0+90 170]);
add_line(mdl, 'clock/1', 't_now out/1', 'autorouting','smart');
add_line(mdl, 'clock for slow/1', 'slow/1', 'autorouting','smart');

%% ---- 제어기의 모멘트에 외란을 더해 선체로 / the controller, plus the push
add_sum(mdl, 'plus the sea', '++', [x0+470 330]);
add_block('simulink/Signal Routing/From', [mdl '/N_ctrl in'], 'GotoTag','N_ctrl', ...
          'Position', [x0+360 300 x0+430 320]);
add_line(mdl, 'N_ctrl in/1',  'plus the sea/1', 'autorouting','smart');
add_line(mdl, 'slow/1',       'plus the sea/2', 'autorouting','smart');

blk = [mdl '/allocation'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [x0+540 280 x0+740 400]);
set_mlfcn(blk, { ...
'function n = allocation(N, X_ff, y_pont, k_pos, k_neg, T_max, T_min)'
'%#codegen'
'%  6주차의 배분 그대로 / the allocation of Week 6, unchanged'
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
'n = [sign(T1)*sqrt(abs(T1)/k1); sign(T2)*sqrt(abs(T2)/k2)];'}, 'n', '[2 1]');
mlfcn_params(blk, {'X_ff','y_pont','k_pos','k_neg','T_max','T_min'});
add_line(mdl, 'plus the sea/1', 'allocation/1', 'autorouting','smart');

%% ---- 선체와 로그 / the hull and the state log --------------------------
add_otter_plant(mdl, 'Otter USV', [x0+800 300 x0+960 380], otter_config('base'));
set_param([mdl '/Otter USV'], 'BackgroundColor', gnc_colour('plant'));
add_line(mdl, 'allocation/1', 'Otter USV/1', 'autorouting','smart');
add_block('simulink/Signal Routing/Goto', [mdl '/x out'], 'GotoTag','x', ...
          'Position', [x0+1000 330 x0+1060 350]);
add_line(mdl, 'Otter USV/1', 'x out/1', 'autorouting','smart');
add_block('simulink/Sinks/To Workspace', [mdl '/xlog'], ...
          'VariableName','xlog', 'SaveFormat','Structure With Time', ...
          'Position', [x0+1000 420 x0+1070 460]);
add_block('simulink/Signal Routing/From', [mdl '/x for log'], 'GotoTag','x', ...
          'Position', [x0+900 430 x0+960 450]);
add_line(mdl, 'x for log/1', 'xlog/1', 'autorouting','smart');
end
