%% W01 · 절 H — 실물 조종기 없이 확인할 수 있는 것 전부
%  W01 · Section H — everything that can be checked without a transmitter
%
%  실행 / to run
%      W01_H_usb_check
%
%  강의에서의 위치 / place in the lecture
%      Part 2 절 H 에 딸린 확인 절차이다. 실습실에 조종기가 없는 학생도 모델이
%      옳은지 확인할 수 있어야 하므로, 하드웨어에 의존하는 부분과 그렇지 않은
%      부분을 갈라 놓는다.
%
%      This accompanies section H of Part 2. A student without a transmitter
%      must still be able to check that the model is correct, so the parts
%      that depend on hardware are separated from those that do not.
%
%  방법 / method
%      조종기에서 모델로 들어오는 것은 Joystick Input 블록이 내는 축 벡터 하나
%      뿐이다. 따라서 그 블록만 같은 모양의 Constant 로 바꾼 사본을 임시 폴더에
%      만들어 돌린다. 나머지는 W01_rc_usb.slx 그대로이므로, 이 사본이 옳게
%      동작하면 조종기를 뺀 전부가 옳다는 뜻이 된다.
%
%      The only thing a transmitter contributes to the model is the axis
%      vector produced by the Joystick Input block. A copy of the model is
%      therefore made in a temporary folder with that one block replaced by a
%      Constant of the same shape. Everything else is W01_rc_usb.slx
%      unchanged, so if the copy behaves correctly then everything except the
%      transmitter is correct.
%
%  확인하는 것 넷 / the four checks
%      1. 축 찾기. 가짜 조종기의 읽기 값을 W01rc_usb_axis 에 주고, 스로틀 축과
%         러더 축을 제대로 골라내는지 본다.
%      2. 방향. 스로틀을 앞으로 밀면 전진, 뒤로 당기면 후진, 러더를 왼쪽으로
%         밀면 좌회전, 오른쪽으로 밀면 우회전이어야 한다.
%      3. 절 G 와의 일치. 같은 스틱 위치를 주면 절 G 표의 경우 7 과 같은 배가
%         나와야 한다. 입력 장치를 바꾸어도 배는 달라지지 않는다는 뜻이다.
%      4. 조종기가 달라도 같은가. 축 순서가 다르거나(TAER) 방향이 뒤집힌
%         조종기라도 설정만 맞추면 같은 배가 나와야 한다.
%
%      1. Axis identification: given the readings of a synthetic transmitter,
%         W01rc_usb_axis must pick out the throttle and rudder axes.
%      2. Direction: throttle forward must be ahead and back astern, rudder
%         left must turn to port and right to starboard.
%      3. Agreement with section G: the same stick position must produce the
%         same vessel as case 7 of the section G table. Changing the input
%         device must not change the vessel.
%      4. Independence of the transmitter: a unit with a different channel
%         order (TAER) or reversed directions must give the same vessel once
%         it is configured.
%
%  확인하지 못하는 것 / what cannot be checked here
%      Joystick Input 블록이 실제 조종기를 읽는 부분. 이것은 조종기를 꽂고
%      CALIBRATE 를 거친 뒤 START 로 확인한다. 판정 기준은 강의노트 절 H 에 있다.
%      The part in which the Joystick Input block reads a real transmitter.
%      That requires the transmitter to be connected, CALIBRATE to be run, and
%      START to be pressed; the acceptance criteria are given in section H.

%  제 변수만 지운다. 그냥 clear 는 기본 작업공간을 비워서, 기본 작업공간 변수를 읽는
%  W01_openloop · W01_current 모델이 다음 실행에서 멈춘다 (실제로 겪었다).
clear here a0 a1 T i k s e m0 h f tx jb lh p ah C in y
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();

%% 1. 축 찾기
fprintf('\n  W01 section H — everything that can be checked without a transmitter\n\n');
rng(1);
a0 = 0.01*randn(8,1);                        % 스틱 가운데 — 조금씩 떨린다
T  = { 'AETR, throttle forward',  3, +1, []
       'AETR, rudder right',      4, +1, 3
       'TAER, throttle forward',  1, +1, []
       'throttle axis inverted',  3, -1, []
       'elevator axis inverted',  2, -1, [] };
fprintf('    %-26s %8s %8s %8s\n', 'axis finder (W01rc_usb_axis)', 'moved', 'found', 'sign');
for i = 1:size(T,1)
    a1 = a0;  a1(T{i,2}) = T{i,3} * 0.98;  a1(5) = a1(5) + 0.2;   % 다른 축도 조금 흔들린다
    [k, s] = W01rc_usb_axis(a0, a1, T{i,4});
    fprintf('    %-26s %8d %8d %+8d\n', T{i,1}, T{i,2}, k, s);
end
try
    W01rc_usb_axis(a0, a0 + 0.1);
    fprintf('    stick not moved            -> no error  (WRONG)\n');
catch e
    fprintf('    stick not moved            -> error: %s\n', e.message);
end

%% 2 ~ 4. 사본 모델
m0 = 'W01_rc_usb';  h = 'W01rch';
if ~isfile(fullfile(here,[m0 '.slx'])), W01_H_build_rc_usb; end
bdclose(h);  bdclose(m0);
load_system(fullfile(here,[m0 '.slx']));
f = fullfile(tempdir, [h '.slx']);
save_system(m0, f);                          % 이름이 W01rch 로 바뀐 사본. 원본은 그대로
tx = [h '/RC transmitter'];
jb = [tx '/Joystick Input'];
lh = get_param(jb, 'LineHandles');  delete_line(lh.Outport(lh.Outport > 0));
p  = get_param(jb, 'Position');     delete_block(jb);
delete_block(find_system(tx, 'SearchDepth',1, 'Regexp','on', 'Name','unused$'));
add_block('simulink/Sources/Constant', [tx '/fake axes'], 'Value','ax_test', 'Position', p);
add_line(tx, 'fake axes/1', 'USB receiver/1', 'autorouting','smart');
assignin(get_param(h,'ModelWorkspace'), 'ax_test', zeros(8,1));

ah = (3 + 0.5*47)/50;                        % 반 편각 s = 0.5 가 되는 축 값 (중립대 3 %)
%       이름                                   축 8 개                          js_thr js_rud js_sgn
C = { 'AETR, throttle full forward',   ax(3, 1,  4, 0),                    3, 4, [ 1 1]
      'AETR, throttle full back',      ax(3, -1, 4, 0),                    3, 4, [ 1 1]
      'AETR, half ahead, half left',   ax(3, ah, 4, -ah),                  3, 4, [ 1 1]
      'AETR, half ahead, half right',  ax(3, ah, 4, ah),                   3, 4, [ 1 1]
      'TAER, half ahead, half left',   ax(1, ah, 4, -ah),                  1, 4, [ 1 1]
      'throttle inverted, same sticks',ax(3, -ah, 4, -ah),                 3, 4, [-1 1] };
fprintf('\n    %-32s %8s %8s %8s %8s %9s %9s\n', 'fake transmitter', 's_T', 's_R', 'n_L', 'n_R', 'u [m/s]', 'r [deg/s]');
fprintf('    %s\n', repmat('-', 1, 90));
for i = 1:size(C,1)
    in = Simulink.SimulationInput(h);
    in = in.setModelParameter('StopTime','60', 'EnablePacing','off');
    in = in.setVariable('animate', 0,       'Workspace', h);
    in = in.setVariable('ax_test', C{i,2},  'Workspace', h);
    in = in.setVariable('js_thr',  C{i,3},  'Workspace', h);
    in = in.setVariable('js_rud',  C{i,4},  'Workspace', h);
    in = in.setVariable('js_sgn',  C{i,5},  'Workspace', h);
    y  = local_log(sim(in));
    e  = y(end,:);                           % [u v r N E psi nL nR Xd Nd Xa Na]
    fprintf('    %-32s %8.3f %8.3f %8.2f %8.2f %9.4f %9.3f\n', C{i,1}, ...
            e(9)/2/119.68, e(10)/52.70, e(7), e(8), e(1), rad2deg(e(3)));
end
fprintf('    (s_T = X_d / X_max, s_R = N_d / N_max;  values at t = 60 s)\n');
fprintf('    section G, case 7 (half ahead, half left) : u = 1.4542 m/s, r = -8.845 deg/s\n\n');
close_system(h, 0);
delete(f);

% -------------------------------------------------------------------------
function a = ax(k1, v1, k2, v2)
%  가짜 조종기의 축 여덟 개. 두 축에만 값을 넣고 나머지는 가운데.
a = zeros(8,1);  a(k1) = v1;  a(k2) = v2;
end

function y = local_log(o)
y = o.get('W01rc');
if isstruct(y),            y = y.signals.values; end
if isa(y, 'timeseries'),   y = y.Data;           end
y = squeeze(y);
if size(y,1) < size(y,2),  y = y.';              end
end
