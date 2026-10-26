function ok = verify_w06_actuation()
%VERIFY_W06_ACTUATION  6주차가 문서에 싣는 수를 전부 다시 센다.
%                      Re-derives every number Week 6 puts in print.
%
%   무엇을 보는가 / what it checks
%
%   ① 두 곳에 적힌 값이 **같은가** — `W06_vars` 와 `W06_0_setup`. 하나는 절
%      스크립트가 쓰고 하나는 사람이 Run 을 누를 때 쓰므로, 어긋나면 강의의
%      수치와 학생이 보는 화면이 달라진다. animate · pace · T_final 셋만
%      달라도 된다 (화면과 길이는 쓰는 쪽이 정한다).
%   ② 배분 행렬 B 를 **열 규칙에서 손으로 다시 쓴다.** `otter_B` 를 믿지 않는다.
%   ③ 6-2 절의 자르기 예측 — Y = Y_max 까지는 누출이 **정확히 0** 이고 그
%      위에서 0 이 아니라는 것. 대수로 보이고 수치로 확인한다.
%   ④ 6-1 절이 센 ṙ = -2.588 deg/s² — 축을 갈라 놓는 것은 B 이지 M 이 아니다.
%   ⑤ 6-7 절의 두 좌표계가 **같은 속도를 요구한다**는 것, 그리고 두 포화의
%      모양이 다르다는 것.
%   ⑥ `W06_read` 와 `W06_plot` 의 **열 순서가 같은가.** 둘은 같은 로그를
%      이름 없이 번호로 읽으므로, 어긋나면 그림이 조용히 거짓말을 한다.
%      `W06_plot` 의 주석이 "둘이 어긋나면 verify 가 잡는다" 고 약속한 것이다.
%
%   쓰는 법 / usage
%       verify_w06_actuation          %  표를 찍는다
%       ok = verify_w06_actuation;    %  전부 통과하면 true
%
%   See also VERIFY_W07_ALLOCATION, W06_VARS, OTTER_B, OTTER_CONFIG.

root = fileparts(fileparts(mfilename('fullpath')));
wk   = fullfile(root, 'lectures', 'W06_simulink');
addpath(fullfile(root, '_tools'), wk);  mss_path();
ok = true;
fprintf('\n  verify_w06_actuation\n\n');

V   = W06_vars();
cfg = otter_config('bow_thruster');

%% 1) 두 곳의 값이 같은가 / the two value files agree
%  animate · pace · T_final 은 쓰는 쪽이 정한다 — 절 스크립트는 화면을 끄고
%  짧게 돌리고, 사람이 Run 을 누를 때는 화면을 켜고 길게 돈다
S    = setup_values(wk);
FREE = {'animate', 'pace', 'T_final'};
bad  = {};
for f = fieldnames(V)'
    if ismember(f{1}, FREE), continue; end
    if ~isfield(S, f{1}) || ~isequaln(round(S.(f{1}), 10), round(V.(f{1}), 10))
        bad{end+1} = f{1};                                         %#ok<AGROW>
    end
end
ok = report(ok, '1  W06_vars = W06_0_setup', isempty(bad), ...
            sprintf('%d fields compared, %s', numel(fieldnames(V)) - numel(FREE), ...
                    ternary(isempty(bad), 'none differ', strjoin(bad, ', '))));

%% 2) B 를 열 규칙에서 손으로 다시 쓴다 / B rebuilt by hand from the column rule
%  열 하나는 추진기 하나다 — [힘의 x 성분; 힘의 y 성분; 그 힘이 중심에 주는 모멘트].
%  선미 둘은 전진 방향 e = [1 0]', 선수는 횡 방향 e = [0 1]'
Bhand = [        1              1          0
                 0              0          1
           V.y_pont       -V.y_pont     V.l_f ];
ok = report(ok, '2  B = the column rule, written by hand', ...
            max(abs(V.B(:) - Bhand(:))) < 1e-12 && isequal(V.B, otter_B(cfg)), ...
            sprintf('max |B - Bhand| = %.1e', max(abs(V.B(:) - Bhand(:)))));

%% 3) 정사각이고 계급이 셋 / square, and of rank three
ok = report(ok, '3  det B = 0.790000, rank B = 3', ...
            abs(det(V.B) - 0.79) < 1e-12 && rank(V.B) == 3 && isequal(size(V.B), [3 3]), ...
            sprintf('det = %.6f, rank = %d, size = %dx%d', ...
                    det(V.B), rank(V.B), size(V.B, 1), size(V.B, 2)));

%% 4) inv(B) 의 세 행 / the three rows of inv(B)
%  셋째 행이 [0 1 0] 인 것이 이 주차의 그림 한 장이다 — 선수추진기가 내야 할 힘은
%  요구한 횡력 **그대로**이고, 선미 둘이 그 힘의 모멘트를 지운다
a  = V.l_f/(2*V.y_pont);                 % 횡력 1 N 이 선미에 지우는 짐 / the lever
Ih = [ 0.5   -a     1/(2*V.y_pont)
       0.5    a    -1/(2*V.y_pont)
       0      1     0              ];
ok = report(ok, '4  inv(B) rows, the third one [0 1 0]', ...
            max(abs(V.Binv(:) - Ih(:))) < 1e-12, ...
            sprintf('lever a = %.6f, 1/(2 y_pont) = %.6f', a, 1/(2*V.y_pont)));

%% 5) 손으로 푼 배분법이 선형해와 같은가 / the hand-solved law equals the linear solve
%  강의가 적는 세 식이 inv(B) 와 **같은 것**이어야 한다. 난수 200 개로 본다
sv = rng(6);
E  = 0;
for i = 1:200
    t  = [240*rand - 120;  80*rand - 40;  110*rand - 55];
    uh = [ t(1)/2 - a*t(2) + t(3)/(2*V.y_pont)
           t(1)/2 + a*t(2) - t(3)/(2*V.y_pont)
           t(2)                              ];
    E  = max(E, norm(uh - V.B\t));
end
rng(sv);
ok = report(ok, '5  the hand-solved law = B \ tau  (200 demands)', E < 1e-12, ...
            sprintf('max error = %.3e N', E));

%% 6) 순수 횡력의 단위 열 / the unit column of a pure sway demand
%  Y = 1 N 만 요구했을 때 추진기 셋이 내야 할 것. 선미 둘이 **서로 반대로** 간다
us = V.Binv * [0; 1; 0];
ok = report(ok, '6  pure sway unit column = [-a; a; 1]', ...
            max(abs(us - [-a; a; 1])) < 1e-12, ...
            sprintf('[%.6f; %.6f; %.6f]', us));

%% 7) 추력과 모멘트의 한계 / the thrust and moment limits
T_max = cfg.k_pos*cfg.n_max^2;
T_min = -cfg.k_neg*cfg.n_min^2;
N_max = 2*cfg.y_pont*min(T_max, -T_min);
ok = report(ok, '7  T_max 119.6820, T_min -66.7080, N_max 52.6993', ...
            abs(T_max - V.T_max) < 1e-9 && abs(T_min - V.T_min) < 1e-9 && ...
            abs(N_max - V.N_max) < 1e-9 && abs(T_max - 119.6820) < 1e-3 && ...
            abs(T_min + 66.7080) < 1e-3, ...
            sprintf('%.4f N, %.4f N, %.4f N m', T_max, T_min, N_max));

%% 8) 횡력 한계 셋 가운데 묶이는 것 / which of the three sway limits binds
%  셋을 전부 센 다음 **가장 작은 것**이 Y_max 다. 선미를 후진시키는 쪽이 묶는다
cand = [abs(T_min)/a, T_max/a, V.F_B_max];        % 선미 후진 · 선미 전진 · 선수 정격
[Ymin, which] = min(cand);
ok = report(ok, '8  sway limits 35.1329 / 63.0325 / 40, the first binds', ...
            abs(cand(1) - 35.1329) < 1e-3 && abs(cand(2) - 63.0325) < 1e-3 && ...
            which == 1 && abs(Ymin - V.Y_max) < 1e-9, ...
            sprintf('%.4f (stern astern) / %.4f (stern ahead) / %.4f (bow) -> Y_max = %.4f N', ...
                    cand, V.Y_max));

%% 9) 자르기 예측 — Y_max 까지 누출이 0, 그 위에서는 아니다
%  the clipping prediction: no leak up to Y_max, a leak above it
%  횡력만 요구하면 이상적인 해는 T_L = -a Y, T_R = +a Y, F_B = Y 다. T_L 이 후진
%  한계에, F_B 가 정격에 걸리면 **만들지 않은 힘의 모멘트를 지운** 셈이 되어 그
%  차이가 전진과 선회로 샌다
Yq   = [20 30 35 V.Y_max 40 50];
leak = zeros(numel(Yq), 2);
for i = 1:numel(Yq)
    TL = max(-a*Yq(i), T_min);                % 후진 한계에 걸린다 / clipped astern
    FB = min(Yq(i), V.F_B_max);               % 정격에 걸린다 / clipped at the rating
    leak(i,:) = [TL + a*Yq(i), ...                                  % X 로 새는 양
                 V.y_pont*(TL - a*Yq(i)) + V.l_f*FB];               % N 으로 새는 양
end
below = Yq <= V.Y_max + 1e-9;
ok = report(ok, '9  the leak is 0 up to Y_max and not above it', ...
            max(max(abs(leak(below,:)))) < 1e-9 && min(max(abs(leak(~below,:)), [], 2)) > 1, ...
            sprintf('at Y = 50 N:  X leaks %+.2f N, N leaks %+.2f N m', leak(end,:)));

%% 10) 구동 계급 셋 / the three actuation ranks
%  이 주차의 정의가 여기서 수가 된다 — 평면 자유도는 셋이다
B0 = otter_B('base');  B3 = otter_B('bow_thruster');  B8 = otter_B('quad_tilt');
ok = report(ok, '10 ranks 2 (under) / 3 square (fully) / 3 of 8 (over)', ...
            rank(B0) == 2 && size(B0,2) == 2 && ...
            rank(B3) == 3 && size(B3,2) == 3 && ...
            rank(B8) == 3 && size(B8,2) == 8, ...
            sprintf('base %dx%d r%d, bow %dx%d r%d, quad_tilt %dx%d r%d', ...
                    size(B0), rank(B0), size(B3), rank(B3), size(B8), rank(B8)));

%% 11) 축을 갈라 놓는 것은 B 이지 M 이 아니다 / B separates the axes, M does not
%  정지 상태에서 Y = 25 N 만 걸면 배분은 N = 0 을 정확히 내는데도 선수각이 돈다.
%  부가질량 결합 M(2,6) 이 ṙ 을 만든다 — 6-1 절이 -2.588 deg/s² 라고 적은 것
[Mm, ~] = otter_M(V.mp, V.rp);
acc  = Mm([2 6], [2 6]) \ [25; 0];
rdot = acc(2)*180/pi;
ok = report(ok, '11 M(2,6) = 12.25 gives rdot = -2.588 deg/s^2', ...
            abs(Mm(2,6) - 12.25) < 1e-9 && abs(rdot + 2.588) < 1e-3, ...
            sprintf('M(2,2) = %.4f, M(2,6) = %.4f, M(6,6) = %.4f', ...
                    Mm(2,2), Mm(2,6), Mm(6,6)));

%% 12) 중첩 / superposition
%  셋을 따로 푼 해를 더한 것이 셋을 함께 푼 해와 같다. B 가 선형이라는 말이고,
%  6-1 절의 넷째 칸이 앞의 셋을 합한 것이라는 말이다
t1 = [60; 0; 0];  t2 = [0; 25; 0];  t3 = [0; 0; 20];
res = norm(V.Binv*(t1 + t2 + t3) - (V.Binv*t1 + V.Binv*t2 + V.Binv*t3));
ok = report(ok, '12 superposition residual < 1e-12', res < 1e-12, ...
            sprintf('%.3e', res));

%% 13) 회전행렬 / the rotation matrix
%  6-7 절이 쓰는 성질 셋과, 본문이 드는 30 도 예시
ps = deg2rad(30);
R  = [cos(ps) -sin(ps); sin(ps) cos(ps)];
pe = [1; 2];                              % 북으로 1 m, 동으로 2 m / 1 m N, 2 m E
pb = R'*pe;                               % 앞으로 얼마, 우현으로 얼마 / ahead, starboard
ok = report(ok, '13 R'' R = I, det R = 1, and the 30 deg example', ...
            max(max(abs(R'*R - eye(2)))) < 1e-12 && abs(det(R) - 1) < 1e-12 && ...
            max(max(abs(R' - inv(R)))) < 1e-12 && ...
            abs(pb(1) - 1.866) < 1e-3 && abs(pb(2) - 1.232) < 1e-3, ...
            sprintf('cos 30 = %.3f, sin 30 = %.3f, x_e = %.3f, y_e = %.3f', ...
                    cos(ps), sin(ps), pb));

%% 14) 접근점 / the approach point
%  부두에서 **바다 쪽으로** stand_off 만큼. 6-5 절의 1 단계가 가는 곳이다
ok = report(ok, '14 app = [berth_N; berth_E + stand_off]', ...
            abs(V.app_N - V.berth_N) < 1e-12 && ...
            abs(V.app_E - (V.berth_E + V.stand_off)) < 1e-12, ...
            sprintf('berth (%.1f, %.1f) + %.1f m  ->  (%.1f, %.1f)', ...
                    V.berth_N, V.berth_E, V.stand_off, V.app_N, V.app_E));

%% 15) 두 좌표계가 같은 속도를 요구한다 / the two frames ask for the same velocity
%  선체고정 바깥 고리는 **오차를 돌려** 게인을 걸고, NED 바깥 고리는 게인만 걸어
%  속도를 NED 로 낸다. 게인이 스칼라이므로 둘은 같은 것이다 — 포화 전까지.
%  nu_body = Kp R' p_e 를 NED 로 돌리면 R Kp R' p_e = Kp p_e 가 NED 의 요구다
dif = 0;
for psi = deg2rad(0:15:345)
    Rk = [cos(psi) -sin(psi); sin(psi) cos(psi)];
    dif = max(dif, norm(Rk*(V.Kp_pos*(Rk'*pe)) - V.Kp_pos*pe));
end
ok = report(ok, '15 body and NED ask the same velocity, before the cap', dif < 1e-12, ...
            sprintf('max difference over 24 headings = %.3e m/s', dif));

%% 16) 두 포화의 **모양**이 다르다 / the two caps are different shapes
%  축별 포화는 두 축을 다른 비로 깎아 **방향을 꺾고**, 크기 포화는 둘을 같은 비로
%  깎아 방향을 **지킨다.** 그래서 축별 둘을 모두 v_lim 으로 두어도 대각선에서는
%  v_lim 을 넘는다
nu    = [1; 1];                                  % 45 도 요구 / a demand at 45 deg
perax = [min(nu(1), V.u_lim); min(nu(2), V.v_lim)];
diag2 = hypot(V.v_lim, V.v_lim);                 % 축별 둘 다 0.35 일 때의 대각선
magc  = V.v_ned_max * nu/norm(nu);               % 크기 포화 / the magnitude cap
ok = report(ok, '16 per-axis bends the direction, magnitude keeps it', ...
            abs(norm(perax) - 0.8732) < 1e-3 && abs(diag2 - 0.4950) < 1e-3 && ...
            abs(atan2(perax(2), perax(1)) - pi/4) > deg2rad(15) && ...
            abs(atan2(magc(2), magc(1)) - pi/4) < 1e-12 && ...
            abs(norm(magc) - V.v_ned_max) < 1e-12, ...
            sprintf('diagonal %.4f, two 0.35 caps %.4f, magnitude %.4f m/s', ...
                    norm(perax), diag2, norm(magc)));

%% 17) 로그를 읽는 두 곳의 열 순서가 같은가 / the two readers agree on the columns
%  W06_read 는 `out` 에서, W06_plot 은 기본 작업공간에서 **같은 로그**를 번호로
%  읽는다. StopFcn 은 W06_read 를 부를 수 없으므로 열 순서가 두 번 적혀 있다
%  행의 **머리에만** 맞추면 안 된다 — 두 파일 모두 한 줄에 세 개를 적는다
%  (`u = y(:,1);  v = y(:,2);  r = y(:,3);`) / both files put three per line
A1 = columns_of(fullfile(wk, 'W06_read.m'), '(\w+)\s*=\s*y\(:,\s*(\d+)\)');
A2 = columns_of(fullfile(wk, 'W06_plot.m'), '(\w+)\s*=\s*y\(:,\s*(\d+)\)');
same = numel(A1) == 17 && numel(A2) == 17 && isequal(A1, A2) && ...
       ~any(cellfun(@isempty, A1));
ok = report(ok, '17 W06_read and W06_plot read the same 17 columns', same, ...
            sprintf('%d and %d names, %s', numel(A1), numel(A2), ...
                    ternary(isequal(A1, A2), 'identical', 'DIFFERENT')));

fprintf('\n  %s\n\n', ternary(ok, 'ALL CHECKS PASSED', '불일치 있음 — 위 FAIL 을 볼 것'));
end

% ------------------------------------------------------------------------
function S = setup_values(wk)                                      %#ok<INUSD>
%  설정 스크립트를 조용히 돌리고 그것이 만든 변수를 전부 걷는다 / run it, collect
%  wk 는 아래 evalc 문자열 안에서 쓴다 — 정적 검사기가 보지 못한다 / used inside evalc
evalc('run(fullfile(wk, ''W06_0_setup.m''))');
w = whos;  S = struct();
SKIP = {'here', 'root', 'wk', 'S', 'w', 'i', 'V', 'f', 'cfg', 'Mmat', 'SKIP'};
for i = 1:numel(w)
    if ~ismember(w(i).name, SKIP), S.(w(i).name) = eval(w(i).name); end
end
end

% ------------------------------------------------------------------------
function A = columns_of(file, pat)
%  `이름 = y(:, k)` 꼴을 걷어 k 순으로 이름을 늘어놓는다 / name per column, in order
txt = fileread(file);
tk  = regexp(txt, pat, 'tokens');
A   = cell(1, 0);
for i = 1:numel(tk)
    A{str2double(tk{i}{2})} = tk{i}{1};
end
end

% ------------------------------------------------------------------------
function ok = report(ok, name, pass, detail)
fprintf('    %-52s %-5s %s\n', name, ternary(pass, 'OK', 'FAIL'), detail);
ok = ok && pass;
end

% ------------------------------------------------------------------------
function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
