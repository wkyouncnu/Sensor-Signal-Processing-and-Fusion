%% W05 · 실험 5-7 — 속도 제어와 경로 추종을 함께 / Experiment 5-7 — speed control and path following at once
%
%  이 절이 묻는 것 / the question
%      3주차의 속도 루프와 5주차의 유도를 **같은 배에** 얹으면 무엇이 달라지는가?
%      그리고 두 제어기가 요구한 힘 X 와 모멘트 N 이 어떻게 두 축의 회전수가 되는가?
%      What changes when the speed loop of Week 3 and the guidance of Week 5 sit on
%      the same hull, and how do the force X and the moment N they ask for become
%      the two shaft speeds?
%
%  비교하는 둘 / the two that are compared — 유도는 양쪽 다 ILOS, 게인도 같다
%      W05_G_tuning      전진력이 상수 X_ff = 60 N (5-6 절까지의 모든 모델)
%      W05_H_speed_path  전진력이 **속도 루프의 출력** — u_d = 1.0 m/s 를 지킨다
%      Guidance is ILOS in both, with the same gains. The only change is where the
%      surge force comes from.
%
%  출력에서 볼 것 / what to look for in the output
%      - 상수 힘은 0.767 m/s 를 낸다. 명령한 값이 아니라 **항력과 균형이 맞는 값**이다.
%        속도 루프는 1.000 m/s 를 지킨다 — 그러려면 직진에서 77.6 N 이 든다.
%      - 그래서 임무가 245 s 가 아니라 189 s 에 마지막 다리에 든다 (23 % 빠르다).
%      - 대신 요 모멘트의 한계가 **줄어든다**: X = 60 N 에서 70.85 N m 이던 것이
%        X = 120 N 에서 47.15 N m 이다. 힘과 모멘트가 같은 두 프로펠러를 나눠 쓰기 때문이다.
%      - 축 회전수는 양쪽 다 n_max = 103.93 rad/s 에 닿지만 넘지 않는다. 넘지 않는 것은
%        오토파일럿이 한계를 **지금의 X 에서 다시 계산**하기 때문이다.
%      - A constant force gives 0.767 m/s, which is not a commanded value but the one
%        that balances the drag. The loop holds 1.000 m/s, and that costs 77.6 N.
%      - The last leg therefore starts at 189 s instead of 245 s, 23 % sooner.
%      - The price is a smaller moment limit: 70.85 N m at X = 60 N against 47.15 N m
%        at X = 120 N, because force and moment share the same two propellers.
%
%  만드는 것 / produces: img/W05_result_speed_path.png

%% 0) 준비 / setup
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
clear RUN;  cfg = otter_config('base');
MDL = {'W05_G_tuning', 'W05_H_speed_path'};
LBL = {'constant force X_{ff} = 60 N', 'speed loop, u_d = 1.0 m/s'};
SHORT = {'a constant X_ff', 'the speed loop'};     % 표에 쓰는 짧은 이름 / for the table

%% 1) 같은 임무를 두 번 / the same mission, twice
fprintf('\n  W05 Experiment 5-7  speed control and path following at once\n');
fprintf('    surge force from    u mean [m/s]   last leg at [s]   mean |y_e| legs 2-4 [m]   X mean [N]\n');
for i = 1:2
    R = W05_read(MDL{i});
    j = R.wp >= 2;                                       % 첫 다리는 20 m 떨어져 출발한다 / leg 1 starts 20 m off
    k = find(R.wp == max(R.wp), 1);
    fprintf('    %-19s %8.3f   %15.1f   %22.3f   %10.2f\n', ...
            SHORT{i}, mean(R.u(j)), R.t(k), mean(abs(R.y_e(j))), mean(R.X));
    RUN{i} = R;
end

%% 2) 배분: 요구한 X 와 N 이 두 축으로 어떻게 나뉘는가 / how X and N split into the two shafts
fprintf('\n    배분 확인 / the allocation, checked by hand   (y_pont = %.4f m, k_pos = %.5f)\n', ...
        cfg.y_pont, cfg.k_pos);
fprintf('      case              X [N]    N [N m]   T_L [N]   T_R [N]   n_L      n_R     n_L by hand\n');
CASE = {'straight leg', RUN{2}.t > 35 & RUN{2}.t < 60; 'hardest turn', []};
[~, ih] = max(abs(RUN{2}.Nmom));  CASE{2,2} = ih;
for c = 1:2
    j = CASE{c,2};  if islogical(j), j = find(j); end
    X = mean(RUN{2}.X(j));  Nm = mean(RUN{2}.Nmom(j));
    T = [X/2 + Nm/(2*cfg.y_pont), X/2 - Nm/(2*cfg.y_pont)];
    nh = sign(T(1)) * sqrt(abs(T(1)) / (cfg.k_pos*(T(1)>=0) + cfg.k_neg*(T(1)<0)));
    fprintf('      %-15s %7.2f   %8.2f  %8.2f  %8.2f  %7.3f  %7.3f   %8.3f\n', ...
            CASE{c,1}, X, Nm, T(1), T(2), mean(RUN{2}.nL(j)), mean(RUN{2}.nR(j)), nh);
end

%% 3) 한계는 X 와 함께 줄어든다 / the moment limit shrinks as X grows
%    오토파일럿의 Saturation 은 **상수**다. 그 상수를 어디서 읽어야 하는가가 이 표다 —
%    그 모델이 요구할 수 있는 가장 큰 X 에서 읽는다.
%    The Saturation in the autopilot holds a constant; this table says where to read
%    it: at the largest surge force that model can ask for.
Nlim = @(X) min(2*cfg.y_pont*(cfg.k_pos*cfg.n_max^2 - X/2), 2*cfg.y_pont*(X/2 + cfg.k_neg*cfg.n_min^2));
V0 = W05_vars();
fprintf('\n    X [N]        '); fprintf('%8.0f', 0:20:140);
fprintf('\n    N_lim [N m]  '); fprintf('%8.2f', max(0, arrayfun(Nlim, 0:20:140)));
fprintf('\n    the constants the models hold:  N_max = N_lim(%g) = %.2f,  N_speed = N_lim(%g) = %.2f N m\n', ...
        V0.X_ff, V0.N_max, V0.X_max, V0.N_speed);

%% 4) 안티와인드업이 실제로 하는 일 / what the anti-windup actually does
%    Kb = 0 이면 되감기가 없다. 이 임무에서 전진력이 한계에 닿는 것은 출발 직후뿐이라
%    차이가 작지만, **0 이 아니다** — 그것이 안티와인드업을 재는 방법이다 (3주차 F 절).
%    Kb = 0 removes the back-calculation. On this mission the force only reaches its
%    limit just after the start, so the difference is small but not zero.
fprintf('\n    the anti-windup (back-calculation), measured\n');
fprintf('      Kb      X at its limit for [s]   speed overshoot [m/s]\n');
for kb = [1 0]
    Rb = W05_read('W05_H_speed_path', 'Kb', kb);
    fprintf('      %-5g   %18.2f   %18.4f\n', kb, ...
            sum(abs(Rb.X) > V0.X_max - 0.01)*Rb.V.h, max(Rb.u) - Rb.V.u_d);
end

%% 5) 그림 셋 / the three figures
W05_fig_speed_path(RUN, LBL, cfg, here);
