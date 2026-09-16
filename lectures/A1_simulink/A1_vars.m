function V = A1_vars()
%A1_VARS  A1_actuation.slx 가 필요로 하는 모든 변수를 하나의 구조체로.
%         Every variable A1_actuation.slx needs, in one struct.
%
%   2주차·3주차와 같은 구조이다. A1_0_setup 은 같은 값들을 기본 작업공간에 채워
%   학생이 모델을 열고 Run 을 누를 수 있게 하고, 이 함수는 같은 값들을 구조체로
%   돌려주어 run_sim 이 실행마다 하나씩 바꾸어 쓸 수 있게 한다.
%
%   The same arrangement as Weeks 2 and 3: A1_0_setup fills the base workspace
%   so that opening the model and pressing Run is enough, while this returns
%   the same numbers as a struct so that run_sim can vary one of them per run.

mss_path();
c = otter_config('base');

V.n_cmd   = [60; -60];
V.k_pos   = c.k_pos;  V.k_neg = c.k_neg;
V.n_max   = c.n_max;  V.n_min = c.n_min;
V.B_alloc = c.B;                     % the matrix under test

V.mp = 25;  V.rp = [0.05 0 -0.35]';
V.V_c = 0;  V.beta_c = 0;  V.x0 = zeros(12,1);

V.h = 0.02;  V.T_final = 60;

V.animate = 0;  V.animate_every = 0.5;
V.track_Nmin = -15;  V.track_Nmax = 15;
V.track_Emin = -15;  V.track_Emax = 15;
end
