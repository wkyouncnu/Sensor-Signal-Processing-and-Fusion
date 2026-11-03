%W12_V_OPENLOOP  여덟 개의 숫자를 손으로 주고 **예상한 대로 움직이는지** 본다.
%                Give eight numbers by hand and check the hull moves as predicted.
%
%   실행 / to run
%       cd lectures/W12_simulink
%       W12_1_build_openloop        % 한 번만. 모델을 만든다
%       W12_V_openloop              % 표 셋과 그림 하나
%
%   1단계의 질문 하나 / the one question of stage 1
%       추진기 넷에 축회전수와 틸팅 각을 **손으로** 주었을 때, 배가 받는 힘과
%       모멘트가 손으로 계산한 것과 같고 궤적이 그 힘으로 설명되는가.
%       제어기도 배분기도 없다 — 그것은 다음 단계다.
%
%   왜 검증이 **두 층**인가 / why the check has two layers
%       (1) 수식이 맞는가. 손으로 쓴 X, Y, N 을 `otter_tilt4` 의 가속도에서
%           거꾸로 잰 tau 와 견준다. 반올림오차 수준이어야 한다.
%       (2) 모델이 그 수식인가. Simulink 가 로그에 적은 상태와 입력을 그대로
%           `otter_tilt4` 에 넣어 가속도를 구하고, 로그의 속도를 수치미분한
%           것과 견준다. 여기가 어긋나면 수식이 아니라 **배선**이 틀린 것이다.
%
%       (1) 만 하면 "함수는 맞는데 모델이 다른 것을 쓰고 있다" 를 못 잡고,
%           (2) 만 하면 "모델과 함수가 똑같이 틀렸다" 를 못 잡는다.
%
%   여섯 경우 / the six cases
%       V1  네 기 전진, 각 0            순수 전진. tilt4 가 1~5 주차 Otter 로 돌아간다
%       V2  좌현 전진 · 우현 후진, 각 0  제자리 선회를 기대하지만 **전진력이 남는다**
%       V3  네 기 전진, 각 +45          게걸음을 기대하지만 **모멘트가 남는다**
%       V4  선수 +45 · 선미 -45          횡력을 모으고 전진력을 지우려는 시도
%       V5  V4 에서 선미 회전수를 고쳐  전진력을 **정확히** 0 으로 만든다
%       V6  각을 70 도로 지시           서보가 45 도에서 자른다. 결과는 V3 와 같다
%
%       V2 와 V3 가 이 주차의 핵심이다. 둘 다 "대칭으로 주면 깨끗할 것" 이라는
%       짐작이 틀리는 자리이고, 틀리는 이유가 서로 다르다 — V2 는 **추력 곡선의
%       전진·후진 비대칭**, V3 는 **선수·선미 거리의 비대칭**(l_f=1.5, l_a=1.0).
%       배분기가 왜 필요한지가 여기서 나온다.
%
%   See also W12_0_SETUP, W12_1_BUILD_OPENLOOP, W12_READ, W12_PLOT,
%            OTTER_TILT4, VERIFY_OTTER_TILT4, OTTER_B.

function W12_V_openloop()

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, '_tools'), here);
mss_path();

mdl = 'W12_openloop';
V   = W12_vars();
cfg = otter_config('quad_tilt');
Mm  = otter_M(V.mp, V.rp);

%  전진 추력을 **정확히** 지우는 후진 회전수. -60 이 아니다.
%  the astern speed that exactly cancels 60 rad/s ahead; it is not -60
n_cxl = -60 * sqrt(cfg.k_pos / cfg.k_neg);

C = { 'V1'  [ 60  60    60     60   ]  [  0   0    0    0 ]  'four ahead, no tilt'
      'V2'  [ 60 -60    60    -60   ]  [  0   0    0    0 ]  'port ahead, starboard astern'
      'V3'  [ 60  60    60     60   ]  [ 45  45   45   45 ]  'four ahead, all tilted +45'
      'V4'  [ 60  60   -60    -60   ]  [ 45  45  -45  -45 ]  'bow +45, stern -45, equal speed'
      'V5'  [ 60  60  n_cxl  n_cxl  ]  [ 45  45  -45  -45 ]  'bow +45, stern -45, surge cancelled'
      'V6'  [ 60  60    60     60   ]  [ 70  70   70   70 ]  'tilt commanded beyond the servo limit' };
nc = size(C, 1);

% =========================================================================
%  (1) 수식 / the formula
% =========================================================================
%  서보가 하는 일을 손으로 한 번 더 한다 — 모델이 깎은 값과 같은 값으로 재야
%  표의 두 열이 같은 것을 가리킨다 / clip by hand exactly as the servo does, so
%  both columns of the table refer to the same commanded quantity
fprintf('\n');
fprintf('  (1) hand formula against the motion model, at rest\n\n');
fprintf('      tau from the hand formula    X = sum Ti cos di\n');
fprintf('                                   Y = sum Ti sin di\n');
fprintf('                                   N = sum (xi sin di - yi cos di) Ti\n');
fprintf('      tau measured out of otter_tilt4''s acceleration, same state\n\n');
fprintf('      case   n [rad/s] after clip            delta [deg] after clip   ');
fprintf('    X [N]      Y [N]    N [N m]   residual\n');
fprintf(['      ' repmat('-', 1, 112) '\n']);

x0  = zeros(12,1);
TAU = zeros(nc, 3);
NCL = zeros(nc, 4);
DCL = zeros(nc, 4);
worst = 0;

for c = 1:nc
    n = min(max(C{c,2}, cfg.n_min), cfg.n_max);
    d = min(max(deg2rad(C{c,3}), -cfg.alpha_max), cfg.alpha_max);
    NCL(c,:) = n;
    DCL(c,:) = d;

    T = (cfg.k_pos*(n >= 0) + cfg.k_neg*(n < 0)) .* n .* abs(n);

    %  손 수식 / by hand, term by term
    X = sum(T .* cos(d));
    Y = sum(T .* sin(d));
    N = sum((cfg.pos(1,:) .* sin(d) - cfg.pos(2,:) .* cos(d)) .* T);

    %  열 규칙과 같은지 / the same thing through otter_B's column rule
    f = zeros(8,1);
    f(1:2:7) = T .* cos(d);
    f(2:2:8) = T .* sin(d);
    assert(max(abs(cfg.B*f - [X; Y; N])) < 1e-12, ...
           'W12:columnRule', 'the hand formula and otter_B disagree');

    %  운동모델에서 거꾸로 재기 / measured back out of the motion model
    xd_on  = otter_tilt4(x0, n,         d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    xd_off = otter_tilt4(x0, [0 0 0 0], d, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
    tau = Mm * (xd_on(1:6) - xd_off(1:6));

    res   = max(abs(tau([1 2 6]) - [X; Y; N]));
    worst = max(worst, res);
    TAU(c,:) = [X Y N];

    fprintf('      %-5s  [%6.1f %6.1f %6.1f %6.1f]  [%5.1f %5.1f %5.1f %5.1f]  %9.3f %9.3f %9.3f  %8.1e\n', ...
            C{c,1}, n, rad2deg(d), X, Y, N, res);
end
fprintf(['      ' repmat('-', 1, 112) '\n']);
fprintf('      worst residual %.1e N or N m over the six cases\n\n', worst);

% =========================================================================
%  (2) 모델 / the model
% =========================================================================
%  왜 한 시각의 가속도를 견주지 않는가 / why one instant is not compared
%      로그는 12개 상태 가운데 여섯만 싣는다. w, p, q, z, phi, theta 는 없고,
%      횡력이 걸리면 선체가 기울어 그 여섯이 **0 이 아니다.** 없는 것을 0 으로
%      채워 otter_tilt4 를 부르면 다른 상태의 가속도가 나오므로, 한 점을
%      견주는 것으로는 배선을 판정할 수 없다.
%      The log carries six of the twelve states; with a sway force the hull
%      heels, so the missing six are not zero and a single-instant comparison
%      would be taken at a different state.
%
%  그래서 궤적 전체를 다시 적분한다 / the whole trajectory is integrated again
%      Simulink 밖에서, 같은 고정스텝 ode4 로, x0 에서 시작해 30 초를 다시
%      적분한다. 매 스텝의 (n, delta) 는 **모델이 실제로 쓴 값** — 로그에 남은
%      서보 뒤의 값 — 을 그대로 쓴다. 그러면 적분기도 입력도 같으니 남는 차이는
%      반올림오차뿐이어야 하고, 그것이 "모델의 배선이 이 수식과 같다" 는 뜻이다.
fprintf('  (2) the Simulink model against the same equations, integrated outside it\n\n');
fprintf('      the same fixed-step ode4 and the same step %.3f s, started from x0,\n', V.h);
fprintf('      driven at every step by the (n, delta) the model actually applied —\n');
fprintf('      the post-servo values read back from the log\n\n');
fprintf('      case   max |dN| [m]  max |dE| [m]  max |dpsi| [deg]  max |du| [m/s]   clip\n');
fprintf(['      ' repmat('-', 1, 92) '\n']);

R   = cell(1, nc);
LBL = cell(1, nc);
worst2 = 0;

for c = 1:nc
    R{c} = W12_read(mdl, 'n_cmd', C{c,2}', 'd_cmd', deg2rad(C{c,3})', ...
                         'T_final', 30);
    LBL{c} = sprintf('%s  %s', C{c,1}, C{c,4});

    r  = R{c};
    hs = r.t(2) - r.t(1);
    ns = numel(r.t);

    Xs = zeros(12, ns);
    Xs(:,1) = V.x0;
    for k = 1:ns-1
        nk = r.n(k,:);  dk = r.delta(k,:);
        g  = @(xx) otter_tilt4(xx, nk, dk, V.mp, V.rp, V.V_c, V.beta_c, V.quad);
        g1 = g(Xs(:,k));
        g2 = g(Xs(:,k) + hs/2*g1);
        g3 = g(Xs(:,k) + hs/2*g2);
        g4 = g(Xs(:,k) + hs  *g3);
        Xs(:,k+1) = Xs(:,k) + hs/6*(g1 + 2*g2 + 2*g3 + g4);
    end

    dN   = max(abs(Xs(7,:)' - r.N));
    dE   = max(abs(Xs(8,:)' - r.E));
    dpsi = rad2deg(max(abs(ssa(Xs(12,:)' - deg2rad(r.psi)))));
    du   = max(abs(Xs(1,:)' - r.u));
    worst2 = max(worst2, max([dN dE du]));

    fprintf('      %-5s  %12.2e  %12.2e  %16.2e  %14.2e   n %d  d %d\n', ...
            C{c,1}, dN, dE, dpsi, du, r.n_clip, r.d_clip);
end
fprintf(['      ' repmat('-', 1, 92) '\n']);
fprintf('      worst %.1e m or m/s over the six 30 s runs\n\n', worst2);

% =========================================================================
%  (3) 무엇을 보았는가 / what the six tracks show
% =========================================================================
fprintf('  (3) the motion those forces produce\n\n');
fprintf('      case    U [m/s]  crab [deg]  r [deg/s]   turn radius [m]   what it means\n');
fprintf(['      ' repmat('-', 1, 104) '\n']);

for c = 1:nc
    r = R{c};
    U    = hypot(r.u(end), r.v(end));
    crab = rad2deg(atan2(r.v(end), r.u(end)));
    rr   = rad2deg(r.r(end));

    if abs(r.r(end)) > 1e-4, Rad = U / abs(r.r(end)); else, Rad = Inf; end

    fprintf('      %-5s  %7.3f  %10.2f  %9.3f   %15s   %s\n', ...
            C{c,1}, U, crab, rr, radius_str(Rad), reading(C{c,1}));
end
fprintf(['      ' repmat('-', 1, 104) '\n\n']);

fprintf('      the three asymmetries this week turns on\n');
fprintf('        thrust curve   +60 rad/s gives %+7.3f N, -60 rad/s gives %+7.3f N\n', ...
        cfg.k_pos*60^2, -cfg.k_neg*60^2);
fprintf('                       so V2 keeps %+7.3f N of surge it did not ask for,\n', TAU(2,1));
fprintf('                       and the astern speed that cancels +60 is %+.3f rad/s\n', n_cxl);
fprintf('        the stations   l_f = %.2f m forward, l_a = %.2f m aft, so the four\n', ...
        cfg.l_f, cfg.l_a);
fprintf('                       tilted thrusters of V3 leave %+7.3f N m of yaw on an\n', TAU(3,3));
fprintf('                       otherwise clean crab\n');
fprintf('        the servo      V6 asks for 70 deg and is given %.0f deg, so its row\n', ...
        rad2deg(cfg.alpha_max(1)));
fprintf('                       of table (1) is V3''s row exactly\n\n');

% =========================================================================
%  그림 / the figure
% =========================================================================
%  V6 을 점선으로 그린다. V6 은 V3 과 **같은 곡선**이고 (서보가 70 도를 45 도로
%  깎았으므로), 실선 둘을 겹쳐 그리면 뒤의 것이 앞의 것을 지워 한 곡선만 보인다.
%  점선이 실선 위에 얹혀야 "둘이 같다" 가 그림에서 읽힌다 / V6 is V3 with the
%  servo limit doing the work, so it is drawn dashed on top of the solid V3
STY = {'-', '-', '-', '-', '-', '--'};

f = W12_plot(R, LBL, ...
    'W12 open loop  -  eight numbers given by hand, and the track they produce', STY);
exportgraphics(f, fullfile(here, 'img', 'W12_result_openloop.png'), ...
               'Resolution', 150);

fprintf('  figure written to img/W12_result_openloop.png\n\n');

end

% =========================================================================
function s = radius_str(Rad)
if isinf(Rad), s = 'straight'; else, s = sprintf('%.2f', Rad); end
end

% =========================================================================
function s = reading(tag)
%  표의 마지막 칸. 숫자가 아니라 **그 숫자를 어떻게 읽는가**를 적는다.
switch tag
    case 'V1', s = 'pure surge, the Otter of Weeks 1 to 5';
    case 'V2', s = 'turns, but drifts ahead while turning';
    case 'V3', s = 'force at 45 deg, hull crabs at 22, and yaws: l_f is not l_a';
    case 'V4', s = 'mostly sway, surge not yet cancelled';
    case 'V5', s = 'surge cancelled by the shaft speed, yaw still there';
    case 'V6', s = 'identical to V3: the servo refused the extra 25 deg';
    otherwise, s = '';
end
end
