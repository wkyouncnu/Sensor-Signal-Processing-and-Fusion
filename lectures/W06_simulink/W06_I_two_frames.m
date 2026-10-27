%% W06 · 실험 6-7 — 같은 일을 두 좌표계에서 / Experiment 6-7 — the same job in two frames
%
%  이 절이 묻는 것 / the question
%      제어기는 **어느 좌표계에서** 돌아야 하는가? 추진기는 선체에 붙어 있으므로
%      힘은 반드시 선체 축으로 끝나야 하고, 목표는 부두 좌표로 주어지므로 오차는
%      NED 에서 시작한다. 그 사이에 회전행렬이 **한 번** 들어가야 하는데, 어디에
%      넣는가는 선택이다 — 바깥 고리의 **오차**에 넣거나, 안쪽 고리의 **속도와 힘**에
%      넣는다. 전자는 회전 하나, 후자는 **둘**이다. 둘은 같은 일을 하는가?
%      Where should the controller run? The thrusters are bolted to the hull, so
%      the force must end up in body axes; the target is given on the quay, so the
%      error starts in NED. One rotation has to sit somewhere in between, and
%      where is a choice: on the ERROR in the outer loop, or on the VELOCITY in
%      and the FORCE out of the inner loop. The first needs one rotation, the
%      second needs TWO. Do they do the same job?
%
%  이 스크립트가 하는 일 / what this script does
%      ① 두 모델을 **같은 과제**에 돌린다 — 목표 (10, 10) m, 선수각 0 도.
%         W06_F_position 은 선체고정 전략, W06_I_position_ned 는 NED 전략이다.
%      ② 같은 두 모델을 선수각 45 도로 한 번 더 돌린다. psi 가 0 이면 R(0) = I 라
%         회전이 **보이지 않는다** — 회전이 일을 하는 자리를 만들어야 한다.
%      ③ 도착 시각 · 남은 거리 · 최대 속력 · 요구 힘의 최댓값을 표로 낸다.
%      ① Runs the two models on the SAME job: the point (10, 10) m with the
%         heading held at 0. W06_F_position is the body-fixed strategy and
%         W06_I_position_ned the NED one.
%      ② Runs both again with the heading at 45 deg. At psi = 0 the rotation is
%         R(0) = I and therefore invisible; it has to be given something to do.
%      ③ Tables the arrival time, the distance left, the largest speed and the
%         largest force demand.
%
%  출력에서 볼 것 / what to look for in the output
%      - 넷 다 점에 선다 — d(end) 가 전부 **0.000 m** 다. 회전을 어디에 두는가는
%        고리가 닫히는지를 정하지 않는다. 둘 다 옳은 제어기다. 정하는 것은
%        **어떻게** 가는가다.
%      - 선체고정이 빠르다. 선수각 0 에서 0.5 m 안에 들기까지 42.68 초, NED 는
%        51.00 초다. 이유는 게인이 아니라 **천장의 모양**이다. 선체고정은 전후와
%        좌우를 **따로** 0.80 · 0.35 m/s 로 막으므로, 대각선에서는
%        hypot(0.80, 0.35) = 0.873 m/s 까지 갈 수 있다. 실측은 0.878 m/s 로
%        그 한계를 조금 넘는데, 안쪽 PI 가 자기 지령을 넘어서기 때문이다.
%      - NED 는 속도를 **크기로** 막고, 그 한계는 느린 축의 0.35 m/s 여야 한다.
%        축마다 0.35 를 걸면 대각선에서 0.495 m/s 가 되어 선체가 좌우로 낼 수 없는
%        속도를 지시한다. 그래서 봉우리가 0.363 m/s 다 — **첫째 대가**이고,
%        **봉우리에서** 2.4 배 느리다. 도착 시각의 차이는 그보다 훨씬 작은데,
%        이유는 바로 아래에 있다.
%      - **궤적의 모양이 다르다.** 축마다 거는 천장은 두 축을 다른 비율로 깎으므로
%        속도 지령의 **방향을 비튼다** — 선수각 0 의 선체고정 궤적은 북으로 먼저
%        가고 북위 10 m 에서 서쪽으로 꺾이는 **ㄱ 자**다. 45 도에서는 빠른 축이
%        북동을 보는데 갈 곳은 북서라, 이번에는 **반대쪽으로** 처져 돌아온다.
%        비트는 방향은 선수각이 정하지만 **비튼다는 것 자체는 늘 그렇다.**
%        크기로 거는 천장은 방향을 그대로 두고
%        크기만 줄이므로 NED 궤적은 목표까지 **직선**이다. 왼쪽 칸에서 바로 보인다.
%      - 그리고 선체고정이 빠른 것은 **처음 18.08 초뿐**이다. 그 뒤에는 북쪽 오차가
%        이미 닫혀 남은 것이 횡방향뿐이라 선체고정도 0.35 m/s 로 긴다. 8.32 초의
%        우위는 전 구간에서 번 것이 아니라 두 축이 함께 포화해 있던 그 처음 구간에서
%        번 것이고, ㄱ 자로 더 간 거리가 그중 일부를 도로 쓴다.
%      - 그런데 도착 시각을 다시 본다. NED 는 선수각 0 에서 51.00 초, 45 도에서도
%        **51.00 초** — 같은 초다. 선체고정은 42.68 초에서 49.36 초로 늦어진다.
%        크기로 거는 천장은 방향을 가리지 않으므로 NED 의 접근은 **선수각과
%        무관**하고, 선체고정은 빠른 축이 갈 방향과 어긋날 때마다 느려진다.
%        8.3 초였던 우위가 1.6 초로 줄어든다.
%      - **둘째 대가**는 마지막 칸에 있다. 선체고정의 횡력 요구는 35.13 N 에서
%        정확히 멈춘다 — Y_max 이고, 그 한계가 배분기보다 **한 블록 앞**에 서서
%        PI 가 그것을 본다. NED 의 PI 는 43.68 N 을 요구한다 — 선체가 낼 수 있는
%        것보다 8.55 N 많다. 한계는 그대로 지켜진다(배분기가 F_B 를 자른다).
%        다만 **한 블록 뒤**에서 지켜지고, 거기서는 안티와인드업 항을 만들 수 없다.
%        NED 제어기는 느낄 수 없는 벽에 적분을 쌓는다.
%      - max |X| 가 같은 이야기를 반대편에서 한다. 선체고정은 두 번 모두 전후력을
%        120.00 N 에서 포화시키고, NED 는 65.87 N 을 넘지 않는다. 속도 지령이 작아
%        전후 PI 가 밀릴 일이 없다.
%      - NED 의 봉우리는 §6-2 의 누출이 **아니다.** 선수각 0 에서 봉우리
%        (0.363 m/s, t = 3.18 s)는 요구와 실제가 **한 자리까지 같은** 순간에 나고
%        (초과 +0.00 N), 요구 요모멘트가 N_max 에 붙어 있던 시간은 0.0 % 다. 3.7 %
%        의 넘침은 안쪽 PI 가 자기 지령을 넘은 것뿐이고, 선체고정의 0.878 대 0.873
%        과 같은 종류다. 45 도에서는 다르다 — 봉우리(0.468 m/s, t = 1.38 s)가
%        **처음 선회** 안에 들어 있고, 그때 요구 요모멘트가 정확히
%        N_max = 52.70 N m 다. 셋을 함께 낼 수 없으므로 배분기가 추진기마다 자르고,
%        그 결과 전후력이 **요구와 반대 부호로** 나온다 — 요구 -54.27 N 에 실제
%        +28.94 N, 초과 +83.21 N. 봉우리는 위치고리의 것이 아니라 **선회의 과도**다.
%        최댓값 대 최댓값으로 재면 이 결론이 나오지 않는다.
%      - All four stop on the point: d(end) is 0.000 m in every case. Where the
%        rotation sits does not decide whether the loop closes -- both are correct
%        controllers. It decides HOW they get there.
%      - The body-fixed strategy is faster: 42.68 s to 0.5 m at psi = 0 against
%        51.00 s. The reason is the SHAPE of the ceiling, not the gains. Body-fixed
%        caps surge and sway separately at 0.80 and 0.35 m/s, so on a diagonal it
%        may travel hypot(0.80, 0.35) = 0.873 m/s. The run peaks at 0.878 m/s,
%        slightly over that bound, because the inner PI overshoots its own command.
%      - The NED strategy caps the speed by MAGNITUDE, and the limit has to be the
%        slower axis's 0.35 m/s: two per-axis caps at 0.35 would allow 0.495 m/s on
%        the diagonal, a sway speed the hull cannot make. Its peak is therefore
%        0.363 m/s -- the FIRST cost, and 2.4 times slower AT THE PEAK. The
%        arrival times are far closer than that, and the next two points say why.
%      - THE TRACKS HAVE DIFFERENT SHAPES. Per-axis caps trim the two axes by
%        different factors and therefore BEND the velocity command. At psi = 0 the
%        body-fixed track runs north first, then turns west along north = 10 m, an
%        L. At psi = 45 the fast axis points north-east while the way to go is
%        north-west, so it sags the OTHER way and comes back. The heading decides
%        which way it bends; THAT it bends is always true. A
%        magnitude cap leaves the direction alone and shrinks only the length, so
%        the NED track is a STRAIGHT LINE to the target. The left panel shows it.
%      - And the body-fixed run is faster only for its first 18.08 s. After that
%        the north error is already closed, nothing but sway is left, and it too
%        crawls at 0.35 m/s. The 8.32 s advantage is not earned across the run but
%        in that opening stretch where both axes are saturated at once -- and the
%        extra ground the L costs spends part of it back.
%      - Now read the arrival times again. The NED strategy takes 51.00 s at
%        psi = 0 AND 51.00 s at psi = 45 deg -- the same second. The body-fixed one
%        goes from 42.68 s to 49.36 s. A magnitude cap has no preferred direction,
%        so the NED approach is heading-independent by construction, while the
%        body-fixed one slows down whenever its fast axis is not aligned with the
%        way to go. The 8.3 s advantage narrows to 1.6 s.
%      - The SECOND cost is in the last column. The body-fixed sway demand stops
%        exactly at 35.13 N, which is Y_max, because that limit stands one block
%        UPSTREAM of the allocation where the PI can see it. The NED PI asks for
%        43.68 N -- 8.55 N more than the hull can make. The limit is still enforced,
%        since the allocation clips F_B, but it is enforced one block DOWNSTREAM,
%        where no anti-windup term can be formed from it. The NED controller
%        integrates against a wall it cannot feel.
%      - max |X| tells the same story from the other side. Body-fixed saturates
%        surge at 120.00 N in both runs; the NED one never passes 65.87 N. Its
%        velocity command is small enough that the surge PI is never pressed.
%      - The NED peak is NOT the leak of 6-2. At psi = 0 the peak (0.363 m/s at
%        t = 3.18 s) happens at an instant where demand and delivery agree to the
%        cent (excess +0.00 N), and the yaw demand spends 0.0 % of the run on
%        N_max; the 3.7 % overshoot is the inner PI passing its own command, the
%        same kind of thing as the body-fixed 0.878 against 0.873. At psi = 45 it
%        is different: the peak (0.468 m/s at t = 1.38 s) falls inside the OPENING
%        TURN, where the yaw demand sits at exactly N_max = 52.70 N m. All three
%        axes cannot be served at once, so the allocation clips per thruster and
%        the surge force comes out with the demand's OPPOSITE SIGN -- demanded
%        -54.27 N, delivered +28.94 N, an excess of +83.21 N. The peak belongs to
%        the turn, not to the position loop. Measuring maximum against maximum
%        does not reach this conclusion; the comparison must be made at a matched
%        time index.
%
%  만드는 것 / produces: img/W06_result_frames.png

%% 0) 경로 / paths
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), '_tools'), here);

V = W06_vars();
p_d = [10 10];                 % 목표 [N, E] / the target

%% 1) 두 전략 × 두 선수각 / two strategies, two headings
%  다섯째 칸은 선 모양이다. 선수각 45 도 쌍을 파선으로 둔다 — NED 의 두 곡선이
%  **겹치기 때문**이다. 둘 다 실선이면 뒤에 그린 것만 보이고, 독자는 겹친 것과
%  없는 것을 구별할 수 없다 / the fifth column is the line style: the psi = 45 pair
%  is dashed because the two NED curves COINCIDE. Drawn both solid, only the last
%  one would show, and a reader cannot tell an overlap from a missing curve
C = {'body-fixed, psi 0',  'W06_F_position',     0, [0    0.45 0.74], '-'
     'NED, psi 0',         'W06_I_position_ned', 0, [0.30 0.75 0.93], '-'
     'body-fixed, psi 45', 'W06_F_position',    45, [0.85 0.33 0.10], '--'
     'NED, psi 45',        'W06_I_position_ned',45, [0.93 0.69 0.13], '--'};
fprintf('\n  W06 Experiment 6-7  the point (%g, %g) m, held in two frames\n', p_d);
fprintf('    case                  t to 0.5 m [s]   d(end) [m]   max |U| [m/s]   max |X| [N]   max |Y| [N]\n');
Rs = cell(size(C,1), 1);
for i = 1:size(C,1)
    Rs{i} = W06_read(C{i,2}, 'N_d', p_d(1), 'E_d', p_d(2), ...
                     'psi_d_cmd', C{i,3}*pi/180, 'T_final', 120);
    R = Rs{i};
    k = find(R.d < 0.5, 1);                       % 처음으로 0.5 m 안에 든 때
    t_in = NaN;  if ~isempty(k), t_in = R.t(k); end
    fprintf('    %-19s   %12.2f   %10.3f   %13.3f   %11.2f   %11.2f\n', ...
            C{i,1}, t_in, R.d(end), max(hypot(R.u, R.v)), ...
            max(abs(R.X_dem)), max(abs(R.Y_dem)));
end
%  본문이 인용하는 두 수를 **로그에 남긴다** — 손으로 계산하지 않는다 (CLAUDE.md §4-8)
%  the two numbers the lecture quotes, printed so they are traceable, not derived by hand
fprintf('    speed ceilings: diagonal %.3f = hypot(%.2f, %.2f) m/s   by magnitude %.3f m/s\n', ...
        hypot(V.u_lim, V.v_lim), V.u_lim, V.v_lim, V.v_ned_max);
fprintf('    sway the NED PI never saw: %.2f - %.2f = %.2f N\n', ...
        max(abs(Rs{2}.Y_dem)), V.Y_max, max(abs(Rs{2}.Y_dem)) - V.Y_max);
%  선체고정이 **언제까지** 빠른지 — NED 천장을 1 % 넘겨 달린 마지막 시각.
%  그 뒤로는 선체고정도 0.35 다. 우위는 전 구간이 아니라 이 구간에서 번 것이다
%  how long the body-fixed run is actually faster: the last instant it runs more
%  than 1 % above the NED ceiling. After that it, too, is at 0.35
U1 = hypot(Rs{1}.u, Rs{1}.v);
fprintf('    body-fixed stays above the NED ceiling until t = %.2f s\n', ...
        Rs{1}.t(find(U1 > 1.01*V.v_ned_max, 1, 'last')));

%% 1b) NED 쪽 봉우리를 만든 것 / what makes the NED peak
%  NED 의 max |U| 는 자기 천장 0.350 보다 높다. 무엇이 그렇게 만드는지는 **같은
%  시각에서** 재야 한다 — 최댓값 대 최댓값은 서로 다른 순간의 수라, 그렇게 견주면
%  부호까지 틀린다(실제로 틀렸다). 그래서 요구와 실제를 **|U| 가 봉우리인 그
%  인덱스에서** 나란히 찍는다. 실제 힘은 로그의 축속도에서 되살리며, 규약은
%  W06_read 와 같다: X = T_L + T_R,  N = y_pont (T_L - T_R) + l_f F_B
%  the NED peak runs above its own 0.350 ceiling. What makes it has to be measured
%  AT ONE INSTANT: the maxima of demand and delivery fall at different times, so
%  comparing max against max gets even the sign wrong -- it did. Demand and
%  delivery are therefore printed at the index where |U| peaks. The delivered force
%  is rebuilt from the logged shaft speeds by the same rule W06_read uses
fprintf('    what makes the NED peak -- demand against delivery, at one instant\n');
for i = [2 4]
    R  = Rs{i};
    Xa = R.T_L + R.T_R;                                   % 실제 전후력 / delivered surge
    Na = V.y_pont*(R.T_L - R.T_R) + V.l_f*R.F_B;          % 실제 요모멘트 / delivered yaw
    [Up, kp] = max(hypot(R.u, R.v));
    onN = 100*mean(abs(abs(R.N_dem) - V.N_max) < 1e-6);   % 요구 요모멘트가 N_max 에 붙어 있던 비율
    [xe, ke] = max(Xa - R.X_dem);                         % 같은 시각의 전후 초과분, 최악
    fprintf('      %-19s peak |U| = %.3f m/s at t = %.2f s   (ceiling %.3f)\n', ...
            C{i,1}, Up, R.t(kp), V.v_ned_max);
    fprintf('        there:  u %+.3f  v %+.3f    X dem %+8.2f -> del %+8.2f (excess %+7.2f)    N dem %+8.2f -> del %+8.2f\n', ...
            R.u(kp), R.v(kp), R.X_dem(kp), Xa(kp), Xa(kp) - R.X_dem(kp), R.N_dem(kp), Na(kp));
    fprintf('        yaw demand on N_max for %.1f %% of the run;  worst same-instant surge excess %+.2f N at t = %.2f s\n', ...
            onN, xe, R.t(ke));
end

%% 2) 궤적 · 거리 · 속력 / the track, the distance and the speed
%  그리는 것은 W06_fig_frames 가 한다 (45 줄 규칙, §15-15)
W06_fig_frames(Rs, C, p_d, V, here);
