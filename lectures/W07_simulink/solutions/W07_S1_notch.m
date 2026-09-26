function W07_S1_notch(mdl)
%W07_S1_NOTCH  7주차 실습 세 문제의 모범답안 모델을 만든다.
%              Build the reference answer to all three Week 7 problems.
%
%   >> W07_S1_notch                 W07_S1.slx 를 만든다 / creates W07_S1.slx
%
%   유일한 정답이 아니다 / not the only correct answer
%       체커는 도면이 아니라 물리를 본다. 다만 한 가지는 구조를 본다 — psi_f 가
%       psi_m 과 다른가. 필터가 루프 **안에** 있는지는 결과만으로 알 수 없기 때문이다.
%       The checker tests the physics, with one structural exception: it looks at
%       whether psi_f differs from psi_m, because no outcome alone can say
%       whether the filter is actually in the loop.
%
%   세 블록과 두 전달함수 / three blocks and two transfer functions
%       measurement   진짜 상태 + 파랑 = 센서가 내놓는 것
%       notch x2      따라갈 수 없는 것만 덜어 낸다. 선수각과 **회두율 둘 다**
%       autopilot     4주차의 법, 게인 그대로. 3번 문제에서 적분 한 항이 붙는다
%
%   See also W07_CHECK, W07_P1_START, W07_S_EXPECTED.

if nargin < 1 || isempty(mdl), mdl = 'W07_S1'; end

here = fileparts(mfilename('fullpath'));
week = fileparts(here);
root = fileparts(fileparts(week));
addpath(fullfile(root,'_tools'), week, fullfile(week,'problems'), here);
mss_path();

out = fullfile(here, [mdl '.slx']);
bdclose(mdl);
if isfile(out), delete(out); end

new_system(mdl);
set_param(mdl, 'SolverType','Fixed-step', 'Solver','ode4', ...
               'FixedStep','h', 'StartTime','0', 'StopTime','T_final', ...
               'ReturnWorkspaceOutputs','off');

%  출발 모델과 같은 시험대 / the same bench as the starting model
w07_lab_bench(mdl, 120);

%% ---- 계측 / what the sensor reports -----------------------------------
blk = [mdl '/measurement'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [220 600 420 720]);
set_mlfcn(blk, { ...
'function [psi_m, r_m] = measurement(x, psi_w, r_w)'
'%#codegen'
'%  제어기가 보는 것 = 배가 실제로 하는 것 + 1차 파랑'
'%  What the controller sees = what the vessel really does + the first-order wave'
'%'
'%  센서는 거짓말을 하지 않는다. 배가 정말로 그만큼 흔들리고 있고, 센서는 그것을'
'%  정직하게 잰다. 문제는 **제어기가 그 흔들림을 오차로 읽는다**는 것이다.'
'%  The sensor is not lying. The vessel really is oscillating and the sensor'
'%  reports it truthfully; the trouble is that the controller reads that'
'%  oscillation as error.'
'psi_m = x(12)*180/pi + psi_w;    % [deg]'
'r_m   = x(6)*180/pi  + r_w;      % [deg/s]'}, 'psi_m', '[1 1]');
for i = 1:3
    tag = {'x','psi_w','r_w'};  tag = tag{i};
    add_block('simulink/Signal Routing/From', [mdl '/' tag ' meas'], 'GotoTag', tag, ...
              'Position', [120 615+35*(i-1) 190 635+35*(i-1)]);
    add_line(mdl, [tag ' meas/1'], sprintf('measurement/%d', i), 'autorouting','smart');
end

%% ---- 노치 둘 / the notch, on both channels ----------------------------
%  회두율에도 건다. 파랑이 만드는 회두율은 11.6 deg/s 로, 이 배가 낼 수 있는
%  회두율과 맞먹는다 — 걸지 않으면 문제의 대부분이 그대로 남는다 (§7-4).
%  The rate is filtered too: the wave carries 11.6 deg/s of it, which is as much
%  as this vessel can produce. Leaving it in would leave most of the problem in.
NM = {'notch heading','notch rate'};  OUT = {'psi_f','r_f'};
for i = 1:2
    add_block('simulink/Continuous/Transfer Fcn', [mdl '/' NM{i}], ...
              'Numerator','[1 2*zeta_n*w0 w0^2]', 'Denominator','[1 2*zeta_d*w0 w0^2]', ...
              'Position', [470 590+70*(i-1) 570 650+70*(i-1)]);
    add_line(mdl, sprintf('measurement/%d', i), [NM{i} '/1'], 'autorouting','smart');
    add_block('simulink/Signal Routing/Goto', [mdl '/' OUT{i} ' out'], ...
              'GotoTag', OUT{i}, 'Position', [610 610+70*(i-1) 680 630+70*(i-1)]);
    add_line(mdl, [NM{i} '/1'], [OUT{i} ' out/1'], 'autorouting','smart');
end

%% ---- 오토파일럿 / the autopilot ---------------------------------------
blk = [mdl '/autopilot'];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, ...
          'Position', [760 580 990 720]);
set_mlfcn(blk, autopilot_code(), 'N', '[1 1]', 'h');
mlfcn_params(blk, {'Kp','Kd','Ki','Kb','N_max','h'});
for i = 1:3
    tag = {'psi_d','psi_f','r_f'};  tag = tag{i};
    add_block('simulink/Signal Routing/From', [mdl '/' tag ' ap'], 'GotoTag', tag, ...
              'Position', [660 600+38*(i-1) 730 620+38*(i-1)]);
    add_line(mdl, [tag ' ap/1'], sprintf('autopilot/%d', i), 'autorouting','smart');
end
add_block('simulink/Signal Routing/Goto', [mdl '/N_ctrl out'], 'GotoTag','N_ctrl', ...
          'Position', [1030 640 1100 660]);
add_line(mdl, 'autopilot/1', 'N_ctrl out/1', 'autorouting','smart');

%% ---- 로그 / the log ----------------------------------------------------
add_block('simulink/Signal Routing/Mux', [mdl '/flog mux'], 'Inputs','3', ...
          'Position', [1160 590 1165 710]);
add_line(mdl, 'measurement/1', 'flog mux/1', 'autorouting','smart');
add_block('simulink/Signal Routing/From', [mdl '/psi_f log'], 'GotoTag','psi_f', ...
          'Position', [1070 630 1140 650]);
add_line(mdl, 'psi_f log/1', 'flog mux/2', 'autorouting','smart');
add_line(mdl, 'autopilot/1', 'flog mux/3', 'autorouting','smart');
add_block('simulink/Sinks/To Workspace', [mdl '/flog'], ...
          'VariableName','flog', 'SaveFormat','Structure With Time', ...
          'Position', [1210 630 1280 670]);
add_line(mdl, 'flog mux/1', 'flog/1', 'autorouting','smart');

a = Simulink.Annotation([mdl '/note']);
a.Text = strjoin({ ...
'WEEK 7 SOLUTION  -  THE MEASUREMENT PATH'
''
'   measurement   psi_m = psi + psi_w      r_m = r + r_w'
'   notch x2      H(s) on BOTH channels. The wave carries 11.6 deg/s of yaw'
'                 rate; filtering the heading alone leaves most of it in'
'   autopilot     Week 4''s law, gains unchanged, plus the integral of P3'
''
'The filter is switched off by zeta_n = zeta_d, not by deleting a block:'
'H(s) is then 1 identically and this model reproduces the unfiltered one'
'exactly. That is what makes the comparison of Problem 1 fair.'}, newline);
a.Position = [220 780 1240 940];
a.HorizontalAlignment = 'left';
a.BackgroundColor = 'lightBlue';

mss_style(mdl);
save_system(mdl, out);
n = check_overlaps(mdl);
close_system(mdl, 0);
fprintf('\n  built %s   (overlapping lines: %d)\n\n', out, n);
end

% =========================================================================
function C = autopilot_code()
C = {
'function N = autopilot(psi_d, psi_f, r_f, Kp, Kd, Ki, Kb, N_max, h)'
'%#codegen'
'%AUTOPILOT  4주차의 법. 게인은 그대로다 — 바뀐 것은 **계측뿐**이다.'
'%           Week 4''s law, gains unchanged; only the measurement is different.'
'%'
'%  그것이 이 주차의 요점이다. 파랑을 다루려고 제어기를 다시 튜닝하지 않는다.'
'%  That is the point of the week: the sea is not answered by retuning.'
'e = (psi_d - psi_f)*pi/180;'
'e = atan2(sin(e), cos(e));            % 4주차의 최단각 / the wrap of Week 4'
'%'
'%  ── 문제 3: 적분 / the integral of Problem 3 ────────────────────────────'
'%  느린 외란은 노치를 그대로 통과한다 (§7-6 줄 2). 그러므로 루프가 그것을'
'%  맞설 수 있고, 맞서려면 오차 없이 맞설 수단 — 적분 — 이 있어야 한다.'
'%  파랑은 평균이 0 이므로 적분에 쌓이지 않는다. 그래서 노치와 적분이 서로를'
'%  망치지 않고 함께 산다.'
'%  The slow push passes the notch untouched, so the loop can oppose it — and'
'%  opposing it without error needs an integral. The wave has zero mean, so it'
'%  does not accumulate there: the two coexist.'
'persistent I'
'if isempty(I), I = 0; end'
'u = Kp*e + I - Kd*r_f*pi/180;'
'N = min(max(u, -N_max), N_max);'
'%  되감기 방지는 2주차 §2-11 의 back-calculation 그대로'
'%  Anti-windup by back-calculation, exactly as in Week 2 §2-11'
'I = I + h*(Ki*e + Kb*(N - u));'
};
end
