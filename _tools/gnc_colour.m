function c = gnc_colour(stage)
%GNC_COLOUR  The colour of one stage of the GNC signal chain.
%
%   c = gnc_colour('controller')
%
%   Colour carries meaning in this course and is never decorative. A reader who
%   has seen one model knows what the green block is in every other one.
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
