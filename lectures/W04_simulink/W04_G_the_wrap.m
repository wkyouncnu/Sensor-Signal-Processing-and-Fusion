%% W04 · 절 G — +-180 도의 감김 / Section G — the wrap at +-180 deg
%  W04_G_wrap: 170 도로 돈 뒤 20 s 에 -170 도를 명령한다. use_ssa = 1 과 0.
%  W04_G_wrap: turn to 170 deg, then command -170 deg at 20 s, with use_ssa = 1 and 0.
%  만드는 것 / produces: img/W04_result_wrap.png

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
S = {'psi_step', 170, 'psi_step2', -170, 't_step2', 20, 'T_final', 60};

fprintf('\n  W04 G  170 deg, then -170 deg at t = 20 s\n');
fprintf('    use_ssa   heading at 20 s [deg]   heading at 60 s [deg]   turned after 20 s [deg]\n');
f = lab_fig('W04 G  wrap', 1000, 460);  hold on; grid on;
for us = [1 0]
    R = W04_read('W04_G_wrap', S{:}, 'use_ssa', us);
    p20 = interp1(R.t, R.psi, 20);
    fprintf('    %-7g   %21.1f   %21.1f   %23.1f\n', us, p20, R.psi(end), abs(R.psi(end) - p20));
    plot(R.t, R.psi, 'LineWidth', 2, 'DisplayName', sprintf('use\\_ssa = %g', us));
end
plot(R.t, R.psi_d, 'k--', 'DisplayName', 'command');
yline([180 -180], ':', 'HandleVisibility','off');
ylabel('\psi, not wrapped [deg]'); xlabel('time [s]'); legend('Location','southwest');
title('-170 deg is 20 deg past 170 deg: ssa turns 20 deg, the raw error turns 340 deg the other way');
exportgraphics(f, fullfile(here, 'img', 'W04_result_wrap.png'), 'Resolution', 150);
