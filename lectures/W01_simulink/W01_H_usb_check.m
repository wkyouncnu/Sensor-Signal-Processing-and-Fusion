%% W01 · 절 H — 실물 조종기 없이 확인할 수 있는 것 전부
%
%      W01_H_usb_check
%
%  이 스크립트가 하는 일
%    조종기가 없는 PC 에서도 §H 의 모델이 옳은지 본다. 조종기에서 모델로 들어오는
%    것은 Joystick Input 블록이 내는 축(axes) 벡터 하나뿐이다. 그래서 그 블록만 같은
%    모양의 Constant 로 바꾼 사본(임시 폴더)을 만들어 돌린다. 나머지는
%    W01_rc_usb.slx 그대로다.
%
%    1. 축 찾기 — W01rc_usb_axis 에 가짜 조종기의 읽기 값을 준다
%    2. 방향    — 스로틀 앞 = 전진, 뒤 = 후진, 러더 왼쪽 = 좌회전, 오른쪽 = 우회전
%    3. §G 와 같은가 — 같은 스틱이면 §G 표의 경우 7 과 같은 배여야 한다
%    4. 조종기가 달라도 — 축 순서가 다르거나(TAER) 방향이 뒤집힌 조종기도 설정만
%       맞으면 같은 배
%
%  확인하지 못하는 것
%    Joystick Input 블록이 실제 조종기를 읽는 부분. 조종기를 꽂고 CALIBRATE 뒤
%    START 로 확인한다 (강의 §H 의 판정 기준).

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
