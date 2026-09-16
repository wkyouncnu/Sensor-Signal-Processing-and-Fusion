function V = W01_vars(model)
%W01_VARS  1주차 모델이 필요로 하는 모든 변수를 하나의 구조체로 돌려준다.
%          Every variable a Week 1 model needs, returned as one struct.
%
%   V = W01_vars              개루프 기동 모델 / the open-loop manoeuvre model
%   V = W01_vars('current')   절 E 의 조류 모델 / the current model of section E
%
%   왜 W01_0_setup 과 따로 있는가 / why this is separate from W01_0_setup
%       W01_0_setup 은 같은 값들을 기본 작업공간에 채운다. 학생이 모델을 열고
%       Run 을 누르기만 하면 되게 하려는 것이다. 이 함수는 같은 값들을 구조체로
%       돌려준다. 절 스크립트가 run_sim 으로 값 하나만 바꾸어 여러 번 돌릴 때,
%       작업공간이 마지막 실행의 상태로 남지 않게 하려는 것이다. 값을 적어 두는
%       곳은 한 군데여야 하므로 둘은 같은 숫자를 읽는다. 2주차와 3주차도 같은 구조다.
%
%       W01_0_setup places the same values in the base workspace, so that
%       opening the model and pressing Run is enough. This function returns
%       them as a struct instead, so that a section script can vary one value
%       through run_sim without leaving the workspace in the state of the last
%       run. A gain must be written down in exactly one place, so both read
%       the same numbers. Weeks 2 and 3 are arranged the same way.
%
%   인자가 필요한 이유 / why there is an argument
%       두 모델은 필요한 시뮬레이션 길이와 궤적 표시 범위가 다르다. 하나는 130 m
%       에 걸쳐 S 자를 그리고, 다른 하나는 옆으로 밀리는 직선을 그린다. 인자가
%       그중 어느 쪽인지를 고른다.
%       The two models want different simulation lengths and different track
%       windows: one draws an S over 130 m, the other a straight line pushed
%       sideways. The argument selects between them.

if nargin < 1 || isempty(model), model = 'openloop'; end

mss_path();

%  ---- the manoeuvre -------------------------------------------------------
%  straight -> port -> straight -> starboard -> straight. Both propellers run
%  ahead throughout; a turn is a small DIFFERENCE between them, because
%  N = y_p (T_left - T_right).
V.n0      = 60;                 % common shaft speed [rad/s]  -> about 1.03 m/s
V.dn      = 3.5;                % differential [rad/s]        -> about 2.3 deg/s
V.t_phase = [30 60 90 120];     % port 30..60 s, starboard 90..120 s

%  ---- vessel and environment ---------------------------------------------
V.mp     = 25;                  % payload mass [kg]
V.rp     = [0.05 0 -0.35]';     % payload position in {b} [m]
V.V_c    = 0;                   % current speed [m/s]
V.beta_c = 0;                   % current direction [rad from north]
V.x0     = zeros(12,1);

%  ---- simulation ----------------------------------------------------------
V.h       = 0.02;
V.T_final = 150;

%  ---- live view (off; the section scripts plot at the end) ---------------
V.animate = 0;  V.animate_every = 0.5;
V.track_Nmin = -10;  V.track_Nmax = 140;
V.track_Emin = -85;  V.track_Emax =  25;

%  ---- section E: one command, changing water -----------------------------
if strcmpi(model, 'current')
    V = rmfield(V, {'dn','t_phase'});      % nothing steers in that model
    V.V_c     = 0.5;
    V.T_final = 120;
    V.track_Nmin = -20;  V.track_Nmax = 160;
    V.track_Emin = -80;  V.track_Emax =  80;
end
end
