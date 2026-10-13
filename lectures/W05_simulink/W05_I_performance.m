%% W05 · 5-6 절의 성능 판정 / Section 5-6's performance table
%
%  이 절이 묻는 것 / the question
%      튜닝은 "어느 값이 가장 나은가" 에 답한다. 이 스크립트는 그 다음 질문에
%      답한다 — **그 결과가 쓸 만한가**, 그리고 무엇이 그 한계를 정하는가.
%      Tuning answers "which setting is best"; this answers "is the result any
%      good", and what decides the answer.
%
%  방법 / the method  (standing-orders §15-40)
%      수를 읽기 전에 **예측을 적는다.** 예측은 제어기가 아니라 **배**에서 나온다 —
%      선회반경, 추진기 한계, 시간 척도. 그 다음 같은 임무에서 재서 나란히 놓는다.
%      The prediction comes from the vessel, not from the guidance, and is written
%      before the measurement is read.
%
%  출력에서 볼 것 / what to look for in the output
%      - 직선 구간은 전부 기대대로다: 선수각 0.4 도 안, 횡방향 Delta/10 안.
%      - 한계는 **정확히 닿고 넘지 않는다**.
%      - 코너의 벗어남은 유도가 아니라 **선회반경**이 정한다.
%      - 큰 신호에서는 안쪽 루프가 바깥보다 느려진다 — 그것이 이 주차의 구속 조건이다.
%
%  만드는 것 / produces: 표만 (그림 없음) / a table only

%% 0) 준비 / setup
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);
V = W05_vars();  cfg = otter_config('base');
R = W05_read('W05_H_speed_path', 'law', 3);          % 5-7 절의 임무 / the mission of 5-7
L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400};

fprintf('\n  W05 section 5-6  the performance, predicted and measured\n');

%% 1) 직선 구간 — 안쪽 루프와 경로 유지 / the straight part of a leg
j = R.t > 90 & R.t < 125;                            % 두 번째 다리의 가운데 / mid-leg
e = atan2d(sind(R.psi_d - R.psi), cosd(R.psi_d - R.psi));
U = mean(R.u(j));
fprintf('    [1] straight leg, heading       mean |psi_d - psi| %6.2f deg      (expect well under 1)\n', mean(abs(e(j))));
fprintf('    [2] straight leg, path keeping  mean |y_e| %6.3f m, max %6.3f m   (expect inside Delta/10 = %.1f m)\n', ...
        mean(abs(R.y_e(j))), max(abs(R.y_e(j))), V.Delta/10);

%% 2) 속도 루프 / the speed loop
fprintf('    [3] speed loop                  95%% at %4.1f s, overshoot %6.4f m/s, steady error %6.4f m/s\n', ...
        R.t(find(R.u > 0.95*V.u_d, 1)), max(R.u) - V.u_d, mean(abs(R.u(j) - V.u_d)));

%% 3) 한계 — 닿되 넘지 않는가 / the limits, reached but not crossed
fprintf('    [4] limits                      |N| %6.2f / %6.2f,  X %6.2f / %6.2f,  n %7.2f / %7.2f,  min n %7.2f > %7.2f\n', ...
        max(abs(R.Nmom)), V.N_speed, max(R.X), V.X_max, ...
        max([R.nL; R.nR]), cfg.n_max, min([R.nL; R.nR]), cfg.n_min);

%% 4) 코너 — 선회반경이 벗어남을 정한다 / the corner, set by the turning circle
r  = gradient(unwrap(R.psi*pi/180), R.t);            % 회두율 [rad/s] / yaw rate
jc = R.t > 65 & R.t < 90;                            % 첫 코너 / the first corner
rm = max(abs(r(jc)));
fprintf('    [5] corner                      peak yaw rate %5.2f deg/s at %4.2f m/s -> R_turn %4.1f m;  excursion %5.2f m\n', ...
        rm*180/pi, mean(R.u(jc)), mean(R.u(jc))/rm, max(abs(R.y_e(R.t > 69 & R.t < 110))));

%% 5) 시간 척도 — 큰 신호에서 분리가 깨진다 / the separation, and where it fails
t = R.t(jc);  pd = unwrap(R.psi_d(jc)*pi/180)*180/pi;  ps = unwrap(R.psi(jc)*pi/180)*180/pi;
[~, i0] = max(abs(diff(pd)));  E0 = abs(pd(i0+1) - ps(i0+1));
i1 = find(abs(pd(i0+1:end) - ps(i0+1:end)) < 0.1*E0, 1) + i0;
fprintf('    [6] time scales                 corner command %4.0f deg, inner within 10%% after %4.2f s;  Delta/U %4.2f s\n', ...
        E0, t(i1) - t(i0), V.Delta/U);
