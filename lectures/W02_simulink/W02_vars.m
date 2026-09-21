function V = W02_vars()
%W02_VARS  W02_pid.slx 가 필요로 하는 모든 변수를 하나의 구조체로.
%          Every variable W02_pid.slx needs, in one struct.
%
%   무엇을 위한 파일인가 / what this file is for
%       W02_0_setup 과 같은 값을 담는다. 두 파일이 따로 있는 이유는 쓰임이
%       다르기 때문이다. W02_0_setup 은 값을 기본 작업공간에 올려서 학생이 모델을
%       열고 Run 만 누르면 되게 한다. 이 함수는 같은 값을 구조체로 돌려주고, 절
%       스크립트는 run_sim 으로 그중 하나만 바꾸어 돌린다. 그래야 스윕이 끝난
%       뒤에도 작업공간이 마지막 실행의 값으로 남지 않는다.
%
%       It holds the same values as W02_0_setup, for a different use. The setup
%       script puts them in the base workspace so that opening the model and
%       pressing Run is enough. This function returns them as a struct, and the
%       section scripts pass it to run_sim with one value changed, so that a
%       sweep does not leave the workspace holding the values of its last run.
%
%   두 파일의 값이 어긋나면 / if the two files disagree
%       학생이 Run 으로 본 그림과 강의에 실린 그림이 달라진다. 값을 고칠 때는
%       두 곳을 함께 고친다. verify_w02_pid 가 두 파일을 대조한다.
%       A figure produced with Run would then differ from the one printed in the
%       notes. Change both together; verify_w02_pid compares the two.

V.pid_m = 1;   V.pid_b = 2;   V.pid_k = 2;

V.Kp = 10;     V.Ki = 8;      V.Kd = 4;     V.Nf = 20;
V.d_filtered = 1;

V.y_step = 1;  V.t_step = 1;
V.ref_filter = 0;  V.ref_Tf = 0.3;

V.tau_max = 1e6;   V.Kb = 2;

V.noise_std = 0;   V.noise_ts = 0.01;

V.T_final = 10;    V.h = 1e-3;
end
