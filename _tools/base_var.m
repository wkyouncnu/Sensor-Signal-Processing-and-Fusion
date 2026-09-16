function v = base_var(name, dflt)
%BASE_VAR  기본 작업공간의 변수를 읽되, 없으면 기본값을 돌려준다.
%          A variable from the base workspace, or a default when it is absent.
%
%   v = base_var('animate_every', 0.5)
%
%   실시간 화면 함수들이 쓴다. 그 함수들은 시뮬레이션이 도는 도중에 불리므로,
%   학생이 변수 하나를 지웠다는 이유로 실행이 멈추면 안 된다. 찾지 못한 값은
%   실행을 중단시키는 대신 **명시된 기본값**으로 물러난다.
%
%   Used by the live-view functions, which run inside a simulation and must not
%   fail because a variable has been cleared. Anything the live view needs but
%   cannot find falls back to a stated default rather than stopping the run.
%
%   기본값을 조용히 쓰는 것이 언제나 옳은 것은 아니다. 여기서 그것이 옳은 이유는
%   빠진 값이 **표시 방법**에 대한 것이지 물리에 대한 것이 아니기 때문이다.
%   게인이나 계수에는 이 방식을 쓰지 않는다 — 그런 값이 조용히 기본값으로
%   대체되면 틀린 결과가 맞는 얼굴로 나온다.
%
%   Falling back silently is not always right. It is right here because what
%   may be missing concerns how something is displayed and not what the physics
%   is. It is not done for gains or coefficients: a coefficient quietly
%   replaced by a default produces a wrong result wearing the face of a right
%   one.

if evalin('base', sprintf('exist(''%s'',''var'')', name))
    v = evalin('base', name);
else
    v = dflt;
end
end
