%% W01 · 절 F — 버튼 다섯 개를 하나씩 눌러 본 결과를 표로
%
%      W01_F_button_check
%
%  이 스크립트가 하는 일
%    W01_interactive.slx 는 사람이 버튼을 눌러 모는 모델이라 결과가 누를 때마다
%    다르다. 그래서 강의노트 §F 의 표는 이 스크립트가 만든다 — 정지 상태에서
%    출발해 버튼 하나를 40 s 동안 누르고 있었을 때와 같게, 버튼마다 한 번씩 돌린다.
%    실시간 속도 조절(Pacing)과 실시간 화면은 끈다. 몇 초면 끝난다.
%
%  무엇을 보라는 것인가
%    - AHEAD 의 u 는 §1-11 의 종단속도와 같다
%    - ASTERN 은 더 느리다. 후진 추력 계수 k_neg 가 k_pos 보다 작기 때문이다 (§1-10)
%    - PORT 와 STARBOARD 는 서로 거울상이다. v 와 r 의 부호만 바뀐다
%
%  학생은 이 스크립트를 돌릴 필요가 없다. 모델을 열고 Run 을 누르면 된다.

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
