%% W02 · 절 C — 플랜트를 플랜트 자신으로부터 동정한다
%  W02 · Section C — identify the plant from the plant
%
%  실행 순서 / order of execution
%      W02_0_setup
%      W02_C_identify_plant
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 C 이며 §2-1 과 짝을 이룬다. §2-1 은 6자유도 모델에서 출발해
%      전진축만 남기고 그것을 1차계 두 개의 수 K_u 와 T_u 로 줄였다. 이 절은
%      그 두 수를 모델에서 직접 재어 유도가 옳았는지 확인한다.
%
%      This is section C of Part 2, the counterpart of §2-1. There the
%      six-degree-of-freedom model was reduced to the surge axis and then to
%      two numbers, the DC gain K_u and the time constant T_u. Here those two
%      numbers are measured from the model itself.
%
%  절차 / procedure
%      되먹임을 끊고(loop_closed = 0) 네 가지 일정한 힘을 차례로 가한 뒤, 각각의
%      정상상태 속력과 63.2 퍼센트 도달 시간을 잰다. 제어기가 붙기 전에 플랜트를
%      먼저 아는 것이 순서이며, 게인을 정하는 §2-3 이 이 두 수를 쓴다.
%
%      The loop is opened with loop_closed = 0, four constant forces are
%      applied in turn, and for each the settled speed and the time to reach
%      63.2 per cent of it are measured. Knowing the plant before attaching a
%      controller is the order of work, and §2-3 designs its gains from these
%      two numbers.
%
%  만드는 것 / what it produces
%      표 하나와 그림 하나 : img/W02_result_openloop.png
%      One table and one figure: img/W02_result_openloop.png
%
%  이것은 함수가 아니라 스크립트이다. 계산한 것이 모두 작업공간에 남으므로,
%  표에 나온 수를 그 자리에서 다시 들여다볼 수 있다.
%  This is a script rather than a function, so everything it computes remains
%  in the workspace and the numbers in the table can be examined afterwards.

clear R u_ol t63 XS i k
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W02_surge_control.slx')), W02_1_build_surge_control; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V = W02_vars;      % every variable the model needs
c = W02_cols;      % names for the log columns — no magic numbers below

%% ---- the four open-loop runs -------------------------------------------
%  loop_closed = 0 disconnects the controller and applies X_open directly, so
%  the same model that closes the loop later can identify the plant now.
XS   = [50 100 150 200];
u_ol = zeros(size(XS));
t63  = zeros(size(XS));
R    = cell(size(XS));

fprintf('\n  W02 section C — open-loop identification (loop_closed = 0)\n\n');
fprintf('    %10s %14s %14s %14s %14s\n', ...
        'X [N]', 'u_ss meas', 'u_ss = K_u X', 'T_u meas [s]', 'error [%]');
fprintf('    %s\n', repmat('-', 1, 72));

for i = 1:numel(XS)
    R{i}    = run_sim('W02_surge_control', V, ...
                      'loop_closed', 0, 'X_open', XS(i), 'T_final', 30);
    u_ol(i) = R{i}.y(end, c.u);
    k       = find(R{i}.y(:, c.u) >= 0.6321*u_ol(i), 1);   % the 63.2 % point
    t63(i)  = R{i}.t(k);
    fprintf('    %10g %14.4f %14.4f %14.4f %14.2f\n', ...
            XS(i), u_ol(i), V.K_u*XS(i), t63(i), 100*(u_ol(i)/(V.K_u*XS(i)) - 1));
end

%  1차계 예측과 실측 응답이 얼마나 다른지를 재 둔다. 시상수의 차이를 어떤
%  원인으로 돌리기 전에, 응답 자체가 1차계에서 얼마나 벗어나는지가 먼저다.
%  Measure how far the response departs from the first-order prediction. The
%  shape of the departure must be established before the difference in time
%  constant is attributed to anything.
dev = 0;
for i = 1:numel(XS)
    pred1 = V.K_u*XS(i)*(1 - exp(-R{i}.t/V.T_u));
    dev   = max(dev, max(abs(R{i}.y(:, c.u) - pred1))/(V.K_u*XS(i)));
end

fprintf(['\n    THE DC GAIN IS EXACT, AND THAT IS THE EASIER OF THE TWO.\n' ...
         '\n      In steady state acceleration is zero, so the equation of motion\n' ...
         '      collapses to X = |X_u| u and the plant really is u = K_u X with\n' ...
         '      K_u = 1/|X_u| = %.6f (m/s)/N. The four rows above agree with that\n' ...
         '      to the last figure printed, because a steady state involves no\n' ...
         '      mass, no added mass and no coupling to any other axis.\n' ...
         '\n    THE TIME CONSTANT IS CLOSE BUT NOT EXACT, AND THE REASON IS THAT\n' ...
         '    THE RESPONSE IS NOT QUITE FIRST ORDER.\n' ...
         '\n      The measured 63.2 per cent time averages %.4f s against the\n' ...
         '      first-order figure T_u = M11/|X_u| = %.4f s, an excess of %.2f per\n' ...
         '      cent. The excess is not an error in either number: the measured\n' ...
         '      curve departs from K_u X (1 - exp(-t/T_u)) by up to %.2f per cent\n' ...
         '      of its final value, so it is not an exponential and no single time\n' ...
         '      constant describes it exactly.\n' ...
         '\n      Section 2-1 reduced six degrees of freedom to one and kept only\n' ...
         '      the surge row. The model being measured here kept all six, and a\n' ...
         '      surge force applied away from the centre of gravity also excites\n' ...
         '      heave and pitch. An exact match was therefore not to be expected;\n' ...
         '      what matters for the design of 2-3 is that the discrepancy is a\n' ...
         '      few per cent and that the gain, which sets the steady state, is\n' ...
         '      exact.\n'], ...
         V.K_u, mean(t63), V.T_u, 100*(mean(t63)/V.T_u - 1), 100*dev);

fprintf(['\n    THE SPEED CEILING IS NOT AN ACCIDENT OF THE NUMBERS.\n' ...
         '\n      otter.m does not choose a maximum thrust and a damping\n' ...
         '      coefficient independently. It chooses the damping so that the\n' ...
         '      hull reaches its rated speed at full thrust:\n' ...
         '\n        X_max = 2 k_pos n_max^2 = 24.4 g = %.3f N exactly, and\n' ...
         '        X_u   = -24.4 g / U_max\n' ...
         '\n      The factor 24.4 g cancels, so u_max = X_max/|X_u| = U_max =\n' ...
         '      %.4f m/s exactly, which is 6 knots. The ceiling is a definition\n' ...
         '      rather than a measurement, and recognising that saves a search for\n' ...
         '      meaning in a number that has none.\n'], ...
         V.X_hi, V.X_hi*V.K_u);

%% ---- the figure --------------------------------------------------------
f = lab_fig('W02 C  open loop', 900, 380);

subplot(1,2,1); hold on;
for i = 1:numel(XS)
    plot(R{i}.t, R{i}.y(:, c.u), 'DisplayName', sprintf('X = %g N', XS(i)));
end
xlabel('time [s]'); ylabel('u  [m/s]');
legend('Location','southeast');
title({'open-loop step responses', 'first order, and the gain is linear in X'});

subplot(1,2,2); hold on;
plot(XS, V.K_u*XS, '--', 'DisplayName', 'K_u X  (predicted)');
plot(XS, u_ol, 'o', 'MarkerFaceColor','auto', 'DisplayName', 'measured');
xlabel('X  [N]'); ylabel('settled u  [m/s]');
legend('Location','northwest');
title({'DC gain', sprintf('K_u = %.6f (m/s)/N', V.K_u)});

sgtitle('W02 C — the plant, identified from the plant', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W02_result_openloop.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W02_result_openloop.png\n\n');
