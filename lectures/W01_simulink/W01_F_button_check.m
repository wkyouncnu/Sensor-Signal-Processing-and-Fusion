%% W01 · 절 F — 다섯 개의 조종 버튼을 하나씩 눌러 정상상태를 측정한다
%  W01 · Section F — the five drive buttons, each measured on its own
%
%  실행 순서 / order of execution
%      W01_0_setup
%      W01_F_button_check
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 F 에 해당한다. 대화형 모델 W01_interactive.slx 를 소개한
%      바로 다음 자리이며, §1-10 의 추력 계수와 §1-11 의 종단속도가 사람이
%      직접 조종하는 모델에서도 그대로 성립하는지 확인한다.
%
%      This is section F of Part 2. It follows the introduction of the
%      interactive model W01_interactive.slx, and confirms that the thrust
%      coefficients of §1-10 and the terminal speed of §1-11 continue to hold
%      when the vessel is driven by hand.
%
%  이 스크립트가 필요한 이유 / why the measurement is scripted
%      대화형 모델은 사람이 버튼을 누르는 순간에 따라 결과가 달라지므로, 그대로
%      두면 강의노트에 실을 표를 재현할 수 없다. 버튼을 누르는 행위를 스크립트가
%      대신하여, 언제 돌려도 같은 표가 나오도록 한다.
%
%      The interactive model responds to when a button is pressed, so its
%      output cannot be reproduced from one run to the next. The script presses
%      the buttons instead, which makes the table in the lecture notes
%      repeatable.
%
%  절차 / procedure
%      1. 모델을 불러오고, 슬라이더의 초기 회전수 n0 와 증분 dn 을 모델 자체에서
%         읽는다. 값을 이 파일에 다시 적지 않는다.
%      2. 버튼 다섯 개에 해당하는 mode 값을 차례로 넣어, 정지 상태에서 출발해
%         40 s 동안 그 버튼을 계속 누르고 있는 것과 같은 시뮬레이션을 돌린다.
%         실시간 페이싱과 실시간 화면은 꺼서 몇 초 만에 끝나게 한다.
%      3. t = 40 s 의 속도 [u v r] 과 두 프로펠러의 회전수를 표로 적고, 선회
%         버튼에 대해서는 크랩각 beta = atan2(v, u) 를 함께 적는다.
%
%      1. Load the model and read the slider's initial propeller speed n0 and
%         its increment dn from the model itself, so that the numbers are not
%         written down twice.
%      2. For each of the five buttons, apply the corresponding mode value and
%         simulate 40 s from rest, which is equivalent to holding that button
%         down for 40 s. Real-time pacing and the live display are disabled, so
%         the whole sweep takes a few seconds.
%      3. Record the velocities [u v r] and both propeller speeds at t = 40 s,
%         together with the crab angle beta = atan2(v, u) for the turning
%         buttons.
%
%  결과를 읽는 법 / how to read the result
%      - AHEAD 의 u 는 §1-11 이 예측한 종단속도 2 k_pos n0^2 / |X_u| 와 같다.
%        추력이 감쇠와 균형을 이룬 상태이다.
%      - ASTERN 의 속력은 그보다 작다. 후진 추력 계수 k_neg 가 전진 계수 k_pos
%        보다 작기 때문이며, 두 값은 §1-10 의 표에 있다.
%      - PORT 와 STARBOARD 는 서로 거울상이다. u 는 같고 v 와 r 의 부호만 바뀐다.
%
%      - The AHEAD speed equals the terminal speed 2 k_pos n0^2 / |X_u|
%        predicted in §1-11, the state in which thrust balances damping.
%      - ASTERN is slower, because the astern thrust coefficient k_neg is
%        smaller than the ahead coefficient k_pos. Both are tabulated in §1-10.
%      - PORT and STARBOARD are mirror images: u is unchanged and only the
%        signs of v and r differ.
%
%  만드는 것 / what it produces
%      강의노트 §F 의 표를 명령창에 출력한다. 그림 파일은 만들지 않는다.
%      The table of section F, printed to the command window. No figure file.
%
%  실습 시간에는 이 스크립트를 돌리지 않아도 된다. 모델을 열고 Run 을 누른 뒤
%  버튼을 직접 눌러 보는 것이 절 F 의 본래 순서이다.
%  Running this script is not part of the laboratory exercise itself: section F
%  asks for the model to be opened, run, and driven by hand.

clear m cfg n0 dn Xu Bt i in y e bt
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
m = 'W01_interactive';
if ~isfile(fullfile(here,[m '.slx'])), W01_F_build_interactive; end
load_system(fullfile(here,[m '.slx']));

cfg = otter_config('base');
n0  = str2double(get_param([m '/Drive command/n0'], 'Value'));     % 슬라이더의 처음 값
dn  = str2double(get_param([m '/Drive command/dn'], 'Value'));
Xu  = 24.4*9.81/(6*0.5144);                                        % |X_u|, otter.m line 157

%        버튼          mode 값 (Radio Button 이 Constant 'mode' 에 쓰는 값)
Bt = { 'AHEAD',        1
       'ASTERN',       2
       'PORT',         3
       'STARBOARD',    4
       'STOP',         0 };

fprintf('\n  W01 section F — each button held for 40 s from rest, n0 = %g, dn = %g rad/s\n\n', n0, dn);
fprintf('    %-10s %7s %7s %10s %10s %11s %11s\n', ...
        'button', 'n_L', 'n_R', 'u [m/s]', 'v [m/s]', 'r [deg/s]', 'beta [deg]');
fprintf('    %s\n', repmat('-', 1, 72));
for i = 1:size(Bt,1)
    in = Simulink.SimulationInput(m);
    in = in.setModelParameter('StopTime','40', 'EnablePacing','off');
    in = in.setBlockParameter([m '/Drive command/mode'], 'Value', num2str(Bt{i,2}));
    in = in.setVariable('animate', 0, 'Workspace', m);
    y  = local_log(sim(in));
    e  = y(end,:);                                  % [u v r N E psi nL nR] at t = 40 s
    if any(Bt{i,2} == [3 4]), bt = sprintf('%11.2f', atan2d(e(2), e(1)));
    else,                     bt = sprintf('%11s', '-');
    end
    fprintf('    %-10s %7.1f %7.1f %10.4f %10.4f %11.3f %s\n', ...
            Bt{i,1}, e(7), e(8), e(1), e(2), rad2deg(e(3)), bt);
end

fprintf('\n    predicted AHEAD   u =  2 k_pos n0^2 / |X_u| = %+.4f m/s   (sec. 1-11)\n', ...
        2*cfg.k_pos*n0^2/Xu);
fprintf('    predicted ASTERN  u = -2 k_neg n0^2 / |X_u| = %+.4f m/s   (k_neg < k_pos, sec. 1-10)\n\n', ...
        -2*cfg.k_neg*n0^2/Xu);
close_system(m, 0);

% -------------------------------------------------------------------------
function y = local_log(o)
%  To Workspace 가 남긴 로그를 [시간 x 열] 행렬로. 열 순서는 add_measurement 의 규약.
y = o.get('W01i');
if isstruct(y),            y = y.signals.values; end
if isa(y, 'timeseries'),   y = y.Data;           end
y = squeeze(y);
if size(y,1) < size(y,2),  y = y.';              end
end
