function ensure_base_vars(V)
%ENSURE_BASE_VARS  그 주차의 변수가 기본 작업공간에 없으면 채워 넣는다.
%                  Put a week's variables into the base workspace if missing.
%
%   ensure_base_vars(W05_vars)
%
%   빌더가 왜 이것을 필요로 하는가 / why a builder needs this
%       이 강의의 모든 Constant 블록은 숫자가 아니라 **이름**을 담고 있다. 학생이
%       Every Constant block in this course holds a name, not a number, so that a
%   student edits WXX_0_setup.m and never opens a block. Simulink validates
%   the name the moment set_param writes it, which means the name has to
%   resolve in the base workspace WHILE THE MODEL IS BEING BUILT.
%
%   Run the builder in a fresh session and it fails on the first Constant:
%
%       Invalid setting for parameter 'Value' ... 'mp'
%
%   which reads like a corrupt model and is nothing of the kind. This puts
%   the defaults in place so the builder can finish.
%
%   값은 학생의 것, 모양은 모델의 것 / the value is the student's, the shape
%   is the model's
%       이미 있는 변수의 **값**은 손대지 않는다. 학생이 Kp_pos 를 0.45 로 고쳤으면
%       다시 돌려도 0.45 로 돈다 — 그것이 이 함수가 있는 이유의 절반이다.
%       그러나 **모양**(크기와 클래스)은 학생의 것이 아니라 모델의 것이다. 블록은
%       그 모양으로 만들어졌고, 모양이 다르면 모델은 컴파일조차 되지 않는다.
%       A value already in the base workspace is left alone, so a gain the
%       student changed survives a rebuild. Its SHAPE is not the student's to
%       choose: the blocks were built around the seed's size and class, and a
%       different one stops the model from compiling at all.
%
%   왜 모양까지 보게 되었나 / why the shape is now checked
%       2026-10-27, `x0` 가 다른 주차의 작업에서 **6 x 1** 로 남아 있었고, 6 주차
%       모델 일곱이 모두 이 오류로 멈췄다:
%
%           'W06_1_point/Otter/states' 의 '1번 입력 포트' 에 대해 유효하지 않은
%           차원이 지정되었습니다 ... 'Otter hull' 의 '1번 출력 포트' 가 [12x1]
%
%       플랜트의 적분기는 초기값을 **이름**으로 읽는다 (`'InitialCondition','x0'`).
%       그래서 6 원소짜리 `x0` 가 12 원소짜리 `xdot` 과 만났고, 러너는 모델이
%       깨진 것처럼 보이는 메시지를 냈다. 채우지 않는 규칙이 그것을 살려 두었다.
%       A stale 6 x 1 `x0` left in the base workspace by another week's work broke
%       all seven Week 6 models, because the plant's Integrator reads its initial
%       condition BY NAME. Filling only what is missing kept the stale value alive.
%
%   바꿀 때는 **말하고** 바꾼다. 모양이 달라 새로 넣은 변수는 한 줄로 찍으므로,
%   학생이 일부러 모양을 바꾸었다면 (예: 웨이포인트를 하나 더 넣었다면) 그 줄을
%   보고 모델을 다시 빌드해야 한다는 것을 안다.
%   A replacement is printed, so a shape the student changed on purpose shows up
%   as one line telling them the model has to be rebuilt around it.

fn = fieldnames(V);
for i = 1:numel(fn)
    nm   = fn{i};
    seed = V.(nm);

    if ~evalin('base', sprintf('exist(''%s'',''var'')', nm))
        assignin('base', nm, seed);
        continue
    end

    have = evalin('base', nm);
    if isequal(size(have), size(seed)) && strcmp(class(have), class(seed))
        continue                      % 값은 학생의 것이다 / the value is theirs
    end

    assignin('base', nm, seed);
    fprintf(['  ensure_base_vars:  %s 가 %s 로 남아 있었다 - 이 주차의 모델은 ' ...
             '%s 를 쓰므로 새로 넣었다\n'], nm, shape_of(have), shape_of(seed));
end
end

% =========================================================================
function s = shape_of(v)
%  '12x1 double' 꼴 한 마디 / the size and class in one phrase
s = sprintf('%s %s', strjoin(string(size(v)), 'x'), class(v));
end
