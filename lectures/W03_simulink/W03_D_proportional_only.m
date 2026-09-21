%% W03 · 절 D — 비례제어와, 비례제어가 없애지 못하는 오차
%  W03 · Section D — proportional control, and the error it cannot remove
%
%  실행 순서 / order of execution
%      W03_0_setup
%      W03_D_proportional_only
%
%  강의에서의 위치 / place in the lecture
%      Part 2 의 절 D 이며 §3-2 와 짝을 이룬다. §3-2 는 이 플랜트가 0 형이어서
%      비례제어만으로는 설정값에 도달할 수 없음을 보이고 그 정상상태 오차의
%      크기까지 유도했다. 이 절은 게인을 세 가지로 바꾸어 가며 그 결론을 확인한다.
%
%      This is section D of Part 2, the counterpart of §3-2, where it was shown
%      that the plant is type 0 and that proportional action alone therefore
%      cannot reach the setpoint. Three gains are tried here against that
%      prediction.
%
%  실험의 구성 / how the experiment is arranged
%      설정값 하나에 비례게인 셋. 요점은 셋 중 어느 것도 설정값에 도달하지
%      못한다는 것이며, 게인을 스무 배로 올려도 사정이 달라지지 않는다는 것이다.
%      적분 동작이 필요한 이유가 여기서 나온다.
%
%      One setpoint and three proportional gains. The point is that none of
%      them reaches it, and that raising the gain twentyfold does not change
%      that. The need for integral action follows from this section.
%
%  만드는 것 / what it produces
%      표 하나와 img/W03_result_P.png
%      One table and img/W03_result_P.png

clear R KPS LBL i pred meas
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'W03_surge_control.slx')), W03_1_build_surge_control; end

V = W03_vars;
c = W03_cols;

%% ---- three proportional gains ------------------------------------------
%  Ki = 0 and Kd = 0, so this is a pure P controller. aw_mode = 0 because
%  with no integrator there is nothing to protect from windup.
KPS = [100 500 2000];
R   = cell(size(KPS));
LBL = cell(size(KPS));

fprintf('\n  W03 section D — proportional only, u_d = %g m/s\n\n', V.u_d1);
%  peak X_cmd is printed because the lecture quotes it. A number read off a
%  figure is not traceable to a runner, which is the rule this column keeps.
fprintf('    %8s %12s %14s %14s %12s %12s %14s\n', ...
        'Kp', 'Kp K_u', 'predicted u_ss', 'measured u_ss', 'error [%]', ...
        'X_ss [N]', 'peak X_cmd [N]');
fprintf('    %s\n', repmat('-', 1, 92));

for i = 1:numel(KPS)
    R{i}   = run_sim('W03_surge_control', V, ...
                     'Kp', KPS(i), 'Ki', 0, 'Kd', 0, 'aw_mode', 0, 'T_final', 30);
    pred   = V.u_d1 * KPS(i)*V.K_u/(1 + KPS(i)*V.K_u);   % final value theorem
    meas   = R{i}.y(end, c.u);
    LBL{i} = sprintf('K_p = %d', KPS(i));
    fprintf('    %8d %12.4f %14.4f %14.4f %12.2f %12.3f %14.1f\n', ...
            KPS(i), KPS(i)*V.K_u, pred, meas, ...
            100*(V.u_d1-meas)/V.u_d1, R{i}.y(end, c.X_sat), ...
            max(abs(R{i}.y(:, c.X_cmd))));
end

%  오차 백분율은 표에서 계산한 값을 그대로 다시 쓴다. 문장 안에 숫자를 손으로
%  적어 두면 게인을 바꾼 날 문장만 옛날 값으로 남는다.
%  The percentages below are taken from the table just computed. A number
%  typed into a sentence is a number that will still say the old value on the
%  day the gains change.
errP = 100*(V.u_d1 - cellfun(@(r) r.y(end, c.u), R))/V.u_d1;

fprintf(['\n    THE LOOP IS TYPE 0, SO PROPORTIONAL ACTION CANNOT REACH THE\n' ...
         '    SETPOINT AT ANY GAIN.\n' ...
         '\n      The plant contains no free integrator: its transfer function\n' ...
         '      K_u/(T_u s + 1) has no pole at the origin. With a proportional\n' ...
         '      controller the loop gain is finite at zero frequency, and the\n' ...
         '      final value theorem gives\n' ...
         '\n          u_ss / u_d = Kp K_u / (1 + Kp K_u) ,\n' ...
         '\n      which is smaller than one for every finite Kp. The four columns\n' ...
         '      above put that expression and the simulation side by side.\n' ...
         '\n    THE REASON IS PHYSICAL, NOT NUMERICAL.\n' ...
         '\n      Holding the vessel at u_d requires a steady force, because the\n' ...
         '      damping never stops opposing the motion. A proportional\n' ...
         '      controller produces force only in proportion to error, so it can\n' ...
         '      hold that force only by holding an error. Removing the error\n' ...
         '      would remove the force that sustains the speed.\n' ...
         '\n      Raising Kp from %g to %g shrinks the error from %.1f to %.1f per\n' ...
         '      cent, and cannot take it to zero: the required force is fixed, so\n' ...
         '      the error can only be made small in proportion as the gain is made\n' ...
         '      large. Section E adds the integrator, which supplies a steady\n' ...
         '      force at zero error and settles the matter.\n'], ...
         KPS(1), KPS(end), errP(1), errP(end));

%% ---- the figure --------------------------------------------------------
f = lab_fig('W03 D  proportional only', 950, 400);

subplot(1,2,1); hold on;
yline(V.u_d1, 'k:', 'DisplayName', 'setpoint');
for i = 1:numel(KPS), plot(R{i}.t, R{i}.y(:, c.u), 'DisplayName', LBL{i}); end
xlabel('time [s]'); ylabel('u  [m/s]');
legend('Location','southeast');
title({'the gap never closes', 'higher gain shrinks it and never removes it'});

subplot(1,2,2); hold on;
for i = 1:numel(KPS), plot(R{i}.t, R{i}.y(:, c.X_cmd), 'DisplayName', LBL{i}); end
xlabel('time [s]'); ylabel('X  demanded [N]');
title({'the force that error buys', 'a steady force needs a steady error'});

sgtitle('W03 D — proportional control on a type 0 plant', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','W03_result_P.png'), 'Resolution', 150);
fprintf('\n  figure -> img/W03_result_P.png\n\n');
