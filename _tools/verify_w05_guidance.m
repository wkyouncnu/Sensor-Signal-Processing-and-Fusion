function ok = verify_w05_guidance()
%VERIFY_W05_GUIDANCE  5주차(모델 없는 유도 튜닝)가 싣는 수와 식을 독립적으로 다시 확인한다.
%                     Recheck the numbers and equations of Week 5 (model-free guidance tuning).
%
%   검사 / checks
%     1  W05_vars 와 W05_0_setup 의 값이 같다 / the two parameter files agree
%     2  LOS 는 작은 오차에서 P 제어기다: |y_e| <= 0.2 Delta 이면 atan(y_e/Delta) 와 y_e/Delta 의
%        차이가 1.4 % 안 (§5-3) / LOS is a P controller for small errors
%     3  조류 속 LOS 의 남는 오차 = Delta tan(유지한 선수각) — 시뮬레이션으로 (§5-5)
%        the error LOS leaves in a current equals Delta tan(held heading), by simulation
%     4  ILOS 는 그 오차를 없앤다: 마지막 100 s 평균 < 0.05 m (§5-5)
%        ILOS removes it: mean over the last 100 s below 0.05 m
%     5  경로 좌표로의 회전이 MSS crosstrackWpt.m 과 같은 y_e 를 준다
%        the rotation into path coordinates gives the same y_e as MSS crosstrackWpt.m
%     5a law 플래그가 갈라진다: 넷이 서로 다르고 LOS 는 kappa 를 읽지 않는다 (5-1b 절)
%        the law flag branches: the three differ, and LOS never reads kappa
%     6  배분의 역: B [T_L; T_R] 이 원래의 [X; N] 을 되돌려 준다 (5-7 절)
%        the allocation inverse returns the (X, N) it came from
%     7  N_lim(X) 가 추력 한계에 닿되 넘지 않고, X* = T_max + T_min 에서 최대다 (5-7 절)
%        N_lim(X) touches the thrust limits without crossing, and peaks at T_max + T_min

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W05_simulink');
addpath(wk);  mss_path();
ok = true;
fprintf('\n  verify_w05_guidance\n\n');

%  `animate` 는 **일부러 다르다**: W05_0_setup 은 사람이 Run 을 누르는 파일이라 1,
%  W05_vars 는 절 스크립트가 한 번에 여러 번 돌리는 파일이라 0 이다 (§15-20).
%  화면에만 관계되는 값이고 어떤 수치에도 영향을 주지 않으므로 이 검사에서 뺀다.
%  animate differs on purpose: 1 in the file a person presses Run in, 0 in the file
%  the section scripts run in bulk. It affects no number, so it is excluded here.
SHOW = {'animate'};
V = W05_vars();  S = setup_values(wk);  bad = {};
for f = fieldnames(V)'
    if any(strcmp(f{1}, SHOW)), continue; end
    if ~isfield(S, f{1}) || ~isequal(S.(f{1}), V.(f{1})), bad{end+1} = f{1}; end %#ok<AGROW>
end
ok = report(ok, '1 W05_vars = W05_0_setup (animate excluded)', isempty(bad), strjoin(bad, ', '));

y = linspace(-0.2, 0.2, 41);                     % y_e / Delta
e2 = max(abs(atan(y) - y) ./ max(abs(y), eps));
ok = report(ok, '2 atan(y/D) ~ y/D within 1.4 % for |y| <= 0.2 D', e2 < 0.014, sprintf('%.2f %%', 100*e2));

L = {'WP_N', [0 400]', 'WP_E', [0 0]', 'T_final', 400, 'V_c', 0.3};
for n = {'W05_D_LOS','W05_F_ILOS'}
    if ~isfile(fullfile(wk, [n{1} '.slx'])), W05_1_build_guidance(n{1}); end
end
%  법칙을 **명시해 넘긴다**. 넘기지 않으면 W05_vars 의 기본값(ILOS)으로 돌아가
%  LOS 검사가 ILOS 를 재게 된다 - 실제로 그렇게 FAIL 이 났다 (2026-09-30).
%  The law is passed explicitly: without it the default from W05_vars (ILOS) is
%  used and this LOS check measures ILOS instead. That is how it first failed.
R = W05_read('W05_D_LOS', L{:}, 'law', 2);
pred = V.Delta*tand(abs(R.psi(end)));
ok = report(ok, '3 LOS error = Delta tan(heading) in a current', abs(R.y_e(end) - pred) < 0.01, ...
            sprintf('%.3f m vs %.3f m', R.y_e(end), pred));
R = W05_read('W05_F_ILOS', L{:}, 'law', 3);
m4 = mean(R.y_e(R.t > 300));
ok = report(ok, '4 ILOS removes it', abs(m4) < 0.05, sprintf('%.3f m', m4));

pts = [3 4; 10 -2; 50 7; -5 5];  e5 = 0;       % [N E] 몇 점 / a few points
for i = 1:size(pts,1)
    pi_p = atan2(60 - 0, 60 - 0);
    ye = -(pts(i,1))*sin(pi_p) + (pts(i,2))*cos(pi_p);
    ye_mss = crosstrackWpt(60, 60, 0, 0, pts(i,1), pts(i,2));
    e5 = max(e5, abs(ye - ye_mss));
end
ok = report(ok, '5 y_e = MSS crosstrackWpt', e5 < 1e-12, sprintf('%.1e m', e5));

%  5a  law 플래그가 실제로 갈라지는가. 세 법칙이 같은 임무에서 **서로 다른** 항적을
%      내야 하고, LOS(2) 는 kappa 를 아예 읽지 않아야 한다 - 그 가지에서 y_int = 0 이다.
%      Does the law flag actually branch? The three must differ on one mission, and
%      LOS must not read kappa at all: y_int is zero on that branch.
La = {'V_c', 0.3, 'T_final', 300};
RA = W05_read('W05_G_tuning', La{:}, 'law', 1);
RB = W05_read('W05_G_tuning', La{:}, 'law', 2);
RC = W05_read('W05_G_tuning', La{:}, 'law', 3);
RK = W05_read('W05_G_tuning', La{:}, 'law', 2, 'kappa', 10*V.kappa);
%  law = 4 는 보통 적분을 쓴 ILOS 다 (5-5c 절). 겨냥하는 식이 3 과 같으므로 **적분
%  상태만** 달라야 한다: 같은 임무에서 aux(= y_int) 가 다르고, 멀리서 더 빨리 자란다.
%  Law 4 is the plain integral: the aiming expression is law 3's, so the states
%  must differ, and the plain one must grow faster while the error is large.
RD = W05_read('W05_G_tuning', La{:}, 'law', 4);
c5a = max(abs(RA.y_e - RB.y_e)) > 1 && max(abs(RB.y_e - RC.y_e)) > 0.5 ...
      && isequal(RB.y_e, RK.y_e) && all(RB.aux == 0) && any(RC.aux ~= 0) ...
      && max(abs(RD.aux)) > max(abs(RC.aux));
ok = report(ok, '5a law = 1, 2, 3, 4 branch; LOS ignores kappa', c5a, ...
            sprintf('atan2-LOS %.2f m, LOS-ILOS %.2f m, kappa x10 moves LOS by %.1e m', ...
                    max(abs(RA.y_e-RB.y_e)), max(abs(RB.y_e-RC.y_e)), max(abs(RB.y_e-RK.y_e))));

%  6  §5-7 의 배분 역행렬. otter_B 가 낸 B 의 1·3 행에 [T_L; T_R] 을 곱하면 [X; N] 이
%     되돌아와야 한다 — 손으로 푼 T = X/2 +- N/(2 y_p) 가 맞는지 보는 것이다.
%     The allocation inverse of 5-7: feeding the hand solution back through B must
%     return the (X, N) it came from.
cfg = otter_config('base');  B = otter_B(cfg);  B = B([1 3], :);
XN  = [77.58 -0.52; 77.26 64.03; 120 -47.15]';        % 실험 5-7 이 실제로 낸 값 / from Experiment 5-7
T   = [XN(1,:)/2 + XN(2,:)/(2*cfg.y_pont); XN(1,:)/2 - XN(2,:)/(2*cfg.y_pont)];
e6  = max(max(abs(B*T - XN)));
ok  = report(ok, '6 allocation inverse: B [T_L;T_R] = [X;N]', e6 < 1e-10, sprintf('%.1e', e6));

%  7  §5-7 의 모멘트 한계. N_lim(X) 에서 나온 N 을 배분하면 두 추력이 정확히 한계에
%     닿고 넘지 않는다. 그리고 두 가지가 맞아야 한다: X = 60 에서 70.85 N m,
%     최댓값이 X* = T_max + T_min 에 있다.
%     The moment limit: allocating N_lim(X) must touch a thrust limit without
%     crossing it, give 70.85 N m at X = 60, and peak at X* = T_max + T_min.
Tmax = cfg.k_pos*cfg.n_max^2;  Tmin = -cfg.k_neg*cfg.n_min^2;
Nlim = @(X) min(2*cfg.y_pont*(Tmax - X/2), 2*cfg.y_pont*(X/2 - Tmin));
Xs = 0:1:140;  Ns = arrayfun(Nlim, Xs);
TT = [Xs/2 + Ns/(2*cfg.y_pont); Xs/2 - Ns/(2*cfg.y_pont)];
e7 = max(max(TT(:)) - Tmax, Tmin - min(TT(:)));           % 넘어선 양 / how far past a limit
[~, ipk] = max(Ns);
c7 = e7 < 1e-10 && abs(Nlim(60) - 70.85) < 0.01 && abs(Xs(ipk) - (Tmax + Tmin)) < 1;
ok = report(ok, '7 N_lim(X) touches the thrust limits, peaks at T_max+T_min', c7, ...
            sprintf('over by %.1e N; N_lim(60) = %.2f; peak at X = %g vs %.2f', ...
                    e7, Nlim(60), Xs(ipk), Tmax + Tmin));

%  8  임무의 끝 (2026-10-13). W05_H_speed_path 는 마지막 웨이포인트에 닿으면 속도
%     명령을 0 으로 내리고 stop_hold 초 뒤에 실행을 끝낸다. 재는 것은 셋이다:
%     ① 실행이 T_final 보다 **일찍** 끝났다  ② 마지막 위치가 마지막 웨이포인트에서
%     R_switch 안에 있다  ③ 명령이 0 이 된 뒤 실행이 stop_hold 만큼 더 돌았다.
%     The end of the mission: the run must end before T_final, the vessel must come
%     to rest within R_switch of the last waypoint, and the run must continue for
%     stop_hold seconds after the command went to zero.
V8 = W05_vars();
R8 = W05_read('W05_H_speed_path', 'law', 3);
d8 = hypot(R8.N(end) - V8.WP_N(end), R8.E(end) - V8.WP_E(end));
i8 = find(R8.u_d <= 0, 1);                                % 명령이 0 이 된 순간 / command to zero
t8 = R8.t(end) - R8.t(i8);
c8 = R8.t(end) < V8.T_final - 1 && d8 < V8.R_switch && abs(t8 - V8.stop_hold) < 2*V8.h;
ok = report(ok, '8 the mission ends at the last waypoint', c8, ...
            sprintf('ran %.1f s of %g; stopped %.2f m short; held %.2f s after the command', ...
                    R8.t(end), V8.T_final, d8, t8));

%  9  **구현이 식과 같은가** (2026-10-13, 사용자 질문: "알고리즘이 제대로 적용된 것인지").
%     앞의 검사들은 성질(정상상태 오차, 한계, 분기)을 본다. 이것은 블록 안의 코드가
%     강의에 적힌 **그 식 자체**인지를 본다: 로그의 위치 (N, E) 만 가지고 5-2·5-4·5-5 의
%     식으로 psi_d 를 **처음부터 다시 계산**해 모델이 실제로 낸 psi_d 와 비교한다.
%     같은 코드를 두 번 부르는 것이 아니라, 강의 본문의 수식을 여기에 손으로 옮겨 적어
%     돌린다 - 그래야 "문서와 모델이 같다" 는 말이 검사가 된다.
%     Earlier checks test properties; this one tests the implementation against the
%     written equations. Taking only the logged positions, psi_d is recomputed from
%     the expressions of sections 5-2, 5-4 and 5-5 - transcribed here by hand, not
%     called from the model - and compared with the psi_d the model produced.
V9 = W05_vars();
R9 = W05_read('W05_F_ILOS', 'law', 3, 'V_c', 0.3, 'beta_c', pi/2);
k9 = 1;  yint = 0;  n9 = numel(V9.WP_N);  psid = zeros(size(R9.t));
for i = 1:numel(R9.t)
    %  5-2: 다리 방향과 경로 좌표 / the leg angle and the path coordinates
    kn   = min(k9+1, n9);
    pi_p = atan2(V9.WP_E(kn) - V9.WP_E(k9), V9.WP_N(kn) - V9.WP_N(k9));
    dN   = R9.N(i) - V9.WP_N(k9);   dE = R9.E(i) - V9.WP_E(k9);
    x_e  =  dN*cos(pi_p) + dE*sin(pi_p);
    y_e  = -dN*sin(pi_p) + dE*cos(pi_p);
    %  5-4: 전환 / the switching test
    d9 = hypot(V9.WP_N(kn) - V9.WP_N(k9), V9.WP_E(kn) - V9.WP_E(k9));
    if (d9 - x_e) < V9.R_switch && k9 < n9-1, k9 = k9 + 1; end
    %  5-5: ILOS 의 법칙과 적분 / the law and its integral
    psid(i) = pi_p - atan(y_e/V9.Delta + (V9.kappa/V9.Delta)*yint);
    yint    = yint + V9.h * V9.Delta*y_e / (V9.Delta^2 + (y_e + V9.kappa*yint)^2);
end
%  모델의 psi_d 는 **도** 로 기록된다. 둘 다 (-180, 180] 로 감아서 비교한다.
e9 = max(abs(atan2d(sind(psid*180/pi - R9.psi_d), cosd(psid*180/pi - R9.psi_d))));
ok = report(ok, '9 the block computes the equations the lecture writes', e9 < 1e-9, ...
            sprintf('worst psi_d difference over the whole run: %.1e deg', e9));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

function S = setup_values(wk)
evalc('run(fullfile(wk, ''W05_0_setup.m''))');
w = whos;  S = struct();
for i = 1:numel(w)
    if ~ismember(w(i).name, {'here','root','wk','S','w','i','cfg'}), S.(w(i).name) = eval(w(i).name); end
end
end

function ok = report(ok, name, pass, detail)
fprintf('    %-50s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
