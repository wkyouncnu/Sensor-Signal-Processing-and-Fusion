%% W04 · 절 E — 각도의 되감김, 그리고 그것을 막는 한 줄의 계산
%  W04 · Section E — the wrap, and the one line of arithmetic that prevents it
%
%  실행 순서 / order of execution
%      W04_0_setup
%      W04_E_the_wrap
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 E 이며 §4-2 의 ssa 선택을 실험으로 확인한다.
%      This is section E of Part 2, and it tests the choice of ssa made in §4-2.
%
%  실험의 구성 / how the experiment is arranged
%      선수방위를 +170 도로 유지하다가 -170 도를 명령한다. 두 방위는 실제로는
%      20 도밖에 떨어져 있지 않다. 한 척은 20 도를 돌고, 다른 한 척은 반대 방향
%      으로 340 도를 돈다.
%
%      The heading is held at +170 deg and then -170 deg is commanded. The two
%      headings are in fact 20 deg apart. One vessel turns 20 deg; the other
%      turns 340 deg the other way.
%
%  무엇이 그 차이를 만드는가 / what makes the difference
%      뺄셈 하나이다. psi_d - psi 를 그대로 쓰면 -340 도가 나오고, 제어기는 그
%      숫자를 믿는다. ssa 는 그 각을 (-180, 180] 로 접어 +20 도로 만든다.
%
%          e = atan2(sin(psi_d - psi), cos(psi_d - psi))
%
%      각도는 실수가 아니라 원 위의 점이므로, 두 각의 차이를 뺄셈만으로 구하면
%      원을 한 바퀴 돌아온 답을 얻을 수 있다. 이 한 줄이 그것을 막는다.
%
%      A single subtraction. Taken literally, psi_d - psi is -340 deg, and the
%      controller believes it. The ssa wraps that angle into (-180, 180], where
%      it is +20 deg. An angle is a point on a circle rather than a real
%      number, so subtracting two of them can return an answer that has gone
%      the long way round; this one line prevents it.
%
%  만드는 것 / what it produces
%      표 하나와 img/W04_result_ssa.png
%      One table and img/W04_result_ssa.png

clear W LW i k swept
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W04_heading_control.slx')), W04_1_build_heading; end

V = W04_vars;

%% ---- the same command, with and without ssa ----------------------------
W     = cell(1,2);
LW    = {'with ssa','without ssa'};
swept = zeros(1,2);

fprintf('\n  W04 section E — the wrap: +170 deg held, then -170 deg commanded\n\n');
fprintf('    %-14s %18s %18s %18s\n', ...
        'ssa', 'peak |r| [deg/s]', 'total turn [deg]', 'settled psi [deg]');
fprintf('    %s\n', repmat('-', 1, 74));

for i = 1:2
    W{i}     = W04_read(run_sim('W04_heading_control', V, ...
                        'psi_1', 170, 'psi_2', -170, 't_up', 5, 't_dn', 25, ...
                        'T_final', 120, 'use_ssa', 2-i));
    k        = W{i}.t >= 25;                       % after the second command
    swept(i) = abs(W{i}.psi(end) - interp1(W{i}.t, W{i}.psi, 25));
    fprintf('    %-14s %18.3f %18.1f %18.2f\n', LW{i}, ...
            max(abs(W{i}.r(k))), swept(i), W{i}.psi(end));
end

fprintf(['\n    Both vessels end on the same heading. One turned %.0f deg to get\n' ...
         '    there and the other turned %.0f deg the other way, because\n' ...
         '    psi_d - psi = -170 - 170 = -340 deg is a perfectly valid number\n' ...
         '    and a perfectly wrong error. ssa maps it into (-pi, pi], giving\n' ...
         '    +20 deg. One line of arithmetic separates the two runs:\n' ...
         '\n        ssa(a) = atan2(sin a, cos a)\n'], swept(1), swept(2));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W04 E  the wrap', 1050, 400);

subplot(1,2,1); hold on;
yline(170,  'k:', 'HandleVisibility','off');
yline(-170, 'k:', 'HandleVisibility','off');
for i = 1:2, plot(W{i}.t, W{i}.psi, 'DisplayName', LW{i}); end
xlabel('time [s]'); ylabel('\psi  heading [deg]');
legend('Location','best');
title({'the same command, two journeys', ...
       sprintf('%.0f deg against %.0f deg swept', swept(1), swept(2))});

subplot(1,2,2); hold on; axis equal;
for i = 1:2, plot(W{i}.E, W{i}.N, 'DisplayName', LW{i}); end
plot(0, 0, 'ks', 'MarkerFaceColor','w', 'HandleVisibility','off');
xlabel('East [m]'); ylabel('North [m]');
title({'and two very different tracks', 'the long way round is a full circle'});

sgtitle('W04 E — an angle error is not a subtraction', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W04_result_ssa.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W04_result_ssa.png\n\n');
