function c = gnc_colour(stage)
%GNC_COLOUR  GNC 신호 사슬의 각 단계에 정해진 색.
%            The colour of one stage of the GNC signal chain.
%
%   c = gnc_colour('controller')
%
%   이 강의에서 색은 의미를 나르며 장식이 아니다. 모델 하나를 본 사람은 다른
%   모든 모델에서 초록 블록이 무엇인지 안다. 그래서 색을 임의로 고르지 않고
%   이 함수에서만 정한다.
%
%   Colour carries meaning in this course and is never decorative: a reader who
%   has seen one model knows what the green block is in every other one. That
%   is why colours are not chosen ad hoc but settled here and nowhere else.
%
%     command      white   what is asked for
%     reference    lilac   what is achievable, and how fast
%     controller   blue    the control law
%     allocation   sand    generalised force to shaft speed
%     plant        green   the vessel — otter.m, unchanged
%     measurement  grey    logging, scopes and the live view

switch lower(strtrim(stage))
    case 'command',     c = '[1.00 1.00 1.00]';
    case 'reference',   c = '[0.89 0.84 0.94]';
    case 'controller',  c = '[0.80 0.88 0.96]';
    case 'allocation',  c = '[0.96 0.87 0.70]';
    case 'plant',       c = '[0.81 0.93 0.81]';
    case 'measurement', c = '[0.93 0.93 0.93]';
    otherwise
        error('gnc_colour:stage', 'Unknown stage ''%s''.', stage);
end
end
