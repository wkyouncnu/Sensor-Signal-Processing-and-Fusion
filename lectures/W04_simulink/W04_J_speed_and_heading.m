%% W04 · 실험 4-8 — 두 안쪽 루프를 한꺼번에 / Experiment 4-8 — both inner loops at once
%
%  이 절이 묻는 것 / the question
%      선수각 루프와 속도 루프를 **같은 배에** 얹으면 서로를 방해하는가? 두 제어기가
%      요구하는 모멘트와 힘은 같은 두 프로펠러에서 나온다 — 하나가 많이 가져가면
%      다른 하나는 덜 가져간다. 명령을 둘 다 움직여 놓고 각자 따라가는지 본다.
%      Do the heading loop and the speed loop get in each other's way when they sit
%      on the same hull? The moment and the force they ask for come from the same
%      two propellers, so what one takes the other cannot have. Both commands are
%      moved and both loops are watched.
%
%  모델 / the model
%      W04_J_both   유도는 없다. 명령은 작업공간의 계단 둘이다 (W04_0_setup).
%                   No guidance: the commands are the two staircases of the setup.
%
%  출력에서 볼 것 / what to look for in the output
%      - 선수각은 계단마다 자리를 잡고 정상상태 오차가 없다. 적분기가 없는데도
%        그런 것은 요에 복원 모멘트가 없기 때문이다 (4-3 절).
%      - 속도도 각 계단을 지킨다. 이쪽은 **적분기가 있어야** 그렇다 — 항력은
%        복원력처럼 작용하므로 P 만으로는 명령에 못 닿는다 (3주차).
%      - 선회가 시작되는 순간 N 이 ±N_speed 에 닿고, 그동안 X 도 한계에 닿는다.
%        두 제어기가 동시에 한계를 요구하는 그 순간이 이 절의 요점이다.
%      - The heading settles with no steady error although there is no integrator;
%        the speed needs its integrator to do the same. At every corner N reaches
%        its limit and X reaches its own at the same time.
%
%  만드는 것 / produces: img/W04_result_both.png

%% 0) 준비 / setup
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

%% 1) 한 번 돌린다 / one run
evalin('base', 'W04_0_setup');
evalin('base', 'sim(''W04_J_both'');');
L = evalin('base', 'W04Jlog');
y = squeeze(L.signals.values);  if size(y,1) < size(y,2), y = y.'; end
t = L.time;
R = struct('psi_d', y(:,1), 'psi', y(:,2), 'u_d', y(:,3), 'u', y(:,4), ...
           'N', y(:,5), 'X', y(:,6));
V  = @(nm) evalin('base', nm);
hold_s = V('cmd_hold');  nseg = numel(V('u_d_steps'));

%% 2) 계단마다 잰다 / measured, one row per command step
fprintf('\n  W04 Experiment 4-8  both inner loops at once  (Kp = %g, Kd = %g, Kp_u = %g, Ki_u = %g)\n', ...
        V('Kp'), V('Kd'), V('Kp_u'), V('Ki_u'));
fprintf('    step   psi_d [deg]   psi end [deg]   u_d [m/s]   u end [m/s]   max |N| [N m]   max X [N]\n');
for k = 1:nseg
    j    = t >= (k-1)*hold_s & t < k*hold_s;         % 그 계단이 유지되는 구간 / the segment
    last = t >= k*hold_s - 2 & t < k*hold_s;         % 끝 2 초 = 자리잡은 값 / the settled value
    fprintf('     %d     %9.1f     %11.2f     %9.2f     %9.3f     %11.2f     %9.1f\n', ...
            k, mean(R.psi_d(j)), mean(R.psi(last)), mean(R.u_d(j)), mean(R.u(last)), ...
            max(abs(R.N(j))), max(R.X(j)));
end

%% 3) 두 한계에 얼마나 오래 붙어 있었는가 / how long each limit was held
fprintf('\n    the two limits, and how long each was reached\n');
fprintf('      |N| at N_speed = %5.2f N m  for %5.2f s\n', V('N_speed'), ...
        sum(abs(R.N) > V('N_speed') - 1e-6) * V('h'));
fprintf('      X   at X_max   = %5.1f N    for %5.2f s\n', V('X_max'), ...
        sum(R.X > V('X_max') - 1e-6) * V('h'));

%% 4) 그림 / the figure — StopFcn 이 부르는 것과 같은 함수다
W04_J_plot(here);
