%% W04 · 절 F — 큰 선회가 오히려 오버슛이 적다. 선형 모델로는 나올 수 없는 결과이다
%  W04 · Section F — big turns overshoot less, which no linear model can do
%
%  실행 순서 / order of execution
%      W04_0_setup
%      W04_F_big_turns_overshoot_less
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 F 이며, §4-1 의 경고 — Nomoto 모델은 선형이지만 이 선체는
%      그렇지 않다 — 를 측정으로 보인다.
%      This is section F of Part 2, and it measures the warning given in §4-1:
%      Nomoto's model is linear and this hull is not.
%
%  실험의 구성 / how the experiment is arranged
%      계단의 크기를 넷으로 바꾸고 제어기는 하나로 둔다. 선형계라면 응답의
%      모양이 크기와 무관해야 하므로 오버슛 백분율이 네 경우 모두 같아야 한다.
%      실제로는 그렇지 않다.
%
%      Four step sizes and one controller. In a linear system the shape of the
%      response does not depend on its size, so the percentage overshoot would
%      be the same in all four cases. It is not.
%
%  왜 그런가 / why this happens
%      otter.m 의 요 감쇠는 각속도에 따라 커진다.
%      The yaw damping in otter.m grows with the turn rate:
%
%          Nh = Nr (1 + 10 |r|) r
%
%      큰 선회일수록 |r| 이 크고 따라서 감쇠도 크다. 선체가 자기의 큰 선회를
%      스스로 더 세게 감쇠시키는 셈이며, 그래서 오버슛이 줄어든다. 게인을
%      조정해서 얻은 결과가 아니라 선체의 성질이다.
%
%      A larger turn means a larger |r| and therefore more damping, so the hull
%      damps its own large turns more heavily and overshoots less. This is a
%      property of the hull rather than anything obtained by tuning.
%
%  만드는 것 / what it produces
%      표 하나와 img/W04_result_size.png
%      One table and img/W04_result_size.png

clear RS SZ LS MpS rpk i ts Kp0 mult
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_heading_control.slx')), W04_1_build_heading; end

V   = W04_vars;
Kp0 = 100.00;
SZ  = [5 20 60 120];

RS  = cell(size(SZ));  LS = cell(size(SZ));
MpS = zeros(size(SZ)); rpk = MpS;

fprintf('\n  W04 section F — step size, Kp = %.2f, Kd = 0\n\n', Kp0);
fprintf('    %10s %18s %16s %14s %16s\n', ...
        'step [deg]', 'peak |r| [deg/s]', 'overshoot [%]', 'ts 2% [s]', 'damping x');
fprintf('    %s\n', repmat('-', 1, 78));

for i = 1:numel(SZ)
    RS{i} = W04_read(run_sim('W04_heading_control', V, 'psi_1', SZ(i), 'psi_2', SZ(i), ...
                             'Kp', Kp0, 'Kd', 0, 'T_final', 60));
    [MpS(i), ts] = step_metrics(RS{i}.t, RS{i}.psi, SZ(i), V.t_up);
    rpk(i) = max(abs(RS{i}.r));
    LS{i}  = sprintf('%g deg', SZ(i));
    fprintf('    %10g %18.3f %16.2f %14.2f %16.2f\n', ...
            SZ(i), rpk(i), MpS(i), ts, 1 + 10*deg2rad(rpk(i)));
end

mult = 1 + 10*deg2rad(rpk(end));
fprintf(['\n    A larger step overshoots LESS, which no linear model can produce.\n' ...
         '    The yaw damping in otter.m is\n' ...
         '\n        Nh = Nr (1 + 10 |r|) r,\n' ...
         '\n    so at the peak rate of the %g deg step, %.3f deg/s = %.4f rad/s,\n' ...
         '    the damping is %.2f times its small-signal value. The design\n' ...
         '    equations of section D use Nr alone and are therefore a\n' ...
         '    SMALL-SIGNAL result: valid for the %g deg step and conservative\n' ...
         '    for the large ones.\n'], ...
         SZ(end), rpk(end), deg2rad(rpk(end)), mult, SZ(1));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 F  step size', 1050, 400);

subplot(1,2,1); hold on;
for i = 1:numel(SZ)
    plot(RS{i}.t, RS{i}.psi/SZ(i), 'DisplayName', LS{i});   % normalised
end
yline(1, 'k:', 'HandleVisibility','off');
xlabel('time [s]'); ylabel('\psi / step   [-]');
legend('Location','southeast');
title({'normalised, so the shapes can be compared', ...
       'a linear plant would put these four exactly on top of each other'});

subplot(1,2,2);
yyaxis left
plot(SZ, MpS, 'o-'); ylabel('overshoot [%]');
yyaxis right
plot(SZ, 1 + 10*deg2rad(rpk), 's--'); ylabel('damping multiplier  1 + 10|r|');
grid on; xlabel('step size [deg]');
title({'bigger step, more damping, less overshoot', ...
       sprintf('the multiplier reaches %.2f at %g deg', mult, SZ(end))});

sgtitle('W04 F — the hull damps its own large turns', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_size.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_size.png\n\n');
