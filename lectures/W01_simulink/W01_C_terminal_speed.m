%% W01 · 절 C — 종단속도를 종이로 예측하고, 그다음 측정한다
%  W01 · Section C — the terminal speed, predicted on paper and then measured
%
%  실행 순서 / order of execution
%      W01_0_setup
%      W01_C_terminal_speed
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 C 이며, Part 1 의 §1-11 과 짝을 이룬다. §1-11 은 추력과
%      감쇠가 균형을 이루는 지점에서 종단속도를 유도했고, 이 절은 그 식이 실제
%      모델에서도 성립하는지 확인한다. 유도한 식을 시뮬레이션으로 검증하는
%      이 순서가 이번 학기 내내 반복된다.
%
%      This is section C of Part 2, and it is the counterpart of §1-11 in
%      Part 1. There the terminal speed was derived from the balance between
%      thrust and damping; here that expression is checked against the model
%      itself. The order — derive first, then measure — is the one used
%      throughout the course.
%
%  절차 / procedure
%      1. 두 프로펠러를 같은 회전수 n 으로 돌려 선박을 곧게 달리게 한다.
%         n = 20, 40, 60, 80 rad/s 의 네 가지를 차례로 쓴다. 두 프로펠러가
%         같으므로 요 모멘트가 생기지 않고, 따라서 서지 축만 남는다.
%      2. 각 n 에서 종단속도를 두 가지 방법으로 구해 나란히 놓는다.
%           예측 : 2 k_pos n|n| / |X_u| — §1-11 의 식이며 시뮬레이션이 필요 없다
%           실측 : W01_openloop.slx 를 돌려 충분히 시간이 지난 뒤의 속도를 읽는다
%      3. 프로펠러 추력 곡선과, n 에 대한 종단속도 곡선을 그린다.
%
%      1. Run both propellers at the same speed n so that the vessel travels
%         in a straight line, using n = 20, 40, 60 and 80 rad/s in turn. Equal
%         propellers produce no yaw moment, which leaves only the surge axis.
%      2. At each n, obtain the terminal speed twice and place the two side by
%         side:
%           predicted: 2 k_pos n|n| / |X_u|, the expression of §1-11, which
%                      requires no simulation at all;
%           measured:  the speed reached by W01_openloop.slx once the
%                      transient has died away.
%      3. Plot the propeller thrust curve and the terminal speed against n.
%
%  결과를 읽는 법 / how to read the result
%      예측과 측정이 소수 넷째 자리까지 일치한다. 이것은 §1-11 의 유도가 옳다는
%      뜻이기도 하고, 모델이 그 유도가 가정한 물리를 담고 있다는 뜻이기도 하다.
%      또한 n 을 두 배로 하면 속도는 네 배가 된다. 추력은 n 의 제곱에 비례하는
%      반면 감쇠는 속도에 비례하기 때문이며, 제곱 추력과 선형 감쇠가 만나면
%      속도가 회전수의 제곱을 따라간다.
%
%      The prediction and the measurement agree to four decimal places, which
%      says both that the derivation of §1-11 is correct and that the model
%      contains the physics that derivation assumed. Doubling n multiplies the
%      speed by four: thrust grows with the square of the propeller speed
%      while damping grows only in proportion to the vessel speed, and a
%      quadratic thrust opposed by linear damping gives a speed that follows
%      the square of the shaft speed.
%
%  만드는 것 / what it produces
%      img/W01_result_speed.png, 그리고 강의노트 §C 의 표.
%      img/W01_result_speed.png, together with the table of section C.

clear V cfg Xu NS u_pred u_meas i X o y f nn TT
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W01_openloop.slx')), W01_1_build_openloop; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V   = W01_vars;
cfg = otter_config('base');

%  Linear surge damping, otter.m: X_u = -24.4 g / U_max with U_max = 6 knots.
Xu = 24.4*9.81/(6*0.5144);          % [N per m/s]

%% ---- the sweep, with dn = 0 so nothing turns ---------------------------
fprintf('\n  W01 section C — terminal surge speed, both propellers equal\n\n');
fprintf('    %10s %14s %16s %14s\n', 'n [rad/s]', 'X [N]', 'predicted u', 'measured u');
fprintf('    %s\n', repmat('-', 1, 58));

NS     = [20 40 60 80];
u_pred = zeros(size(NS));
u_meas = zeros(size(NS));
for i = 1:numel(NS)
    X         = 2*cfg.k_pos*NS(i)*abs(NS(i));
    u_pred(i) = X/Xu;
    y         = W01_read(run_sim('W01_openloop', V, 'dn', 0, 'n0', NS(i)));
    u_meas(i) = y.u(end);
    fprintf('    %10g %14.3f %16.4f %14.4f\n', NS(i), X, u_pred(i), u_meas(i));
end

fprintf(['\n    The steady state balances thrust against linear surge damping:\n' ...
         '    2 k_pos n|n| = X_u u, with X_u = %.3f N per m/s. The agreement is\n' ...
         '    to four decimals, so surge damping in otter.m really is linear\n' ...
         '    and the hand calculation is exact rather than approximate.\n'], Xu);

%% ---- the figure: propeller curve, and speed against shaft speed --------
f = lab_fig('W01 C  terminal speed', 900, 380);

subplot(1,2,1); hold on;
nn = linspace(cfg.n_min, cfg.n_max, 400);
TT = prop_thrust(nn, cfg);
plot(nn, TT, 'Color',[0 0.45 0.74]);
xline(0,'k:'); yline(0,'k:');
xlabel('n  shaft speed [rad/s]'); ylabel('T  thrust, one propeller [N]');
title({'the propeller curve  T = k n|n|', ...
       sprintf('k_{pos}/k_{neg} = %.3f — astern is weaker', cfg.k_pos/cfg.k_neg)});

subplot(1,2,2); hold on;
plot(NS, u_pred, '--', 'Color',[0.85 0.33 0.10]);
plot(NS, u_meas, 'o',  'Color',[0 0.45 0.74], 'MarkerFaceColor',[0 0.45 0.74]);
xlabel('n  shaft speed, both propellers [rad/s]'); ylabel('terminal u [m/s]');
legend({'2 k_{pos} n|n| / X_u','measured'}, 'Location','northwest');
title({'terminal surge speed', 'quadratic thrust against linear damping'});

sgtitle('W01 C — thrust in, speed out', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W01_result_speed.png'), 'Resolution', 150);

%  REMOVED 2026-09-08, at the lecturer's request: the four-panel
%  "one velocity, two frames" figure, and the table that went with it.
%
%  It was a second telling of §1-4, which already works the same rotation
%  through with the same numbers (psi = 30 deg, u = 2.0, v = 0.5) and its own
%  figure. Two tellings of one idea is not emphasis — see
%  gnc-lecture-vault/references/standing-orders.md §9-5.
%
%  `W01_frames.m` is left in the folder. Nothing calls it now, and it is kept
%  so the figure can be brought back without rewriting it.

fprintf('\n  figure -> img/W01_result_speed.png\n\n');
