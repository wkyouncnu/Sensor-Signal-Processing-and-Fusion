function B = otter_B(cfg)
%OTTER_B  제어 유효행렬을 열 규칙 하나에서 만든다.
%         Control effectiveness matrix, built from the column rule.
%
%   B = otter_B(cfg)            cfg 는 otter_config 이 준다 / cfg from otter_config
%   B = otter_B('quad_tilt')    줄여 쓴 형태 / shorthand
%
%   tau = B * f,  tau = [X ; Y ; N]
%
%   열 규칙 / the column rule
%       선체좌표계의 (x, y) 에 놓인 추진기가 단위벡터 e = (e_x, e_y) 방향으로
%       민다면, 그 추진기는 B 에 정확히 열 하나를 기여한다.
%       A thruster at (x, y) in {b} pushing along the unit vector
%       e = (e_x, e_y) contributes exactly one column:
%
%       [ e_x ; e_y ; x*e_y - y*e_x ]
%
%       배치가 달라져도 규칙은 달라지지 않는다. 추진기가 늘면 열이 늘고, 방향이
%       바뀌면 그 열이 바뀔 뿐이다. 그래서 배치마다 B 를 따로 외우지 않는다.
%       The rule does not change with the layout: another thruster adds another
%       column, and a different direction changes that column. There is no need
%       to memorise a B for each arrangement.
%
%       셋째 성분은 r x F 의 z 성분을 추력의 크기로 나눈 것이다. 따라서 이 열은
%       그 추진기가 1 뉴턴을 냈을 때 생기는 일반화 힘 그 자체이다.
%       The third entry is the z component of the cross product r x F divided
%       by the thrust magnitude, so the column is the generalised force
%       produced by one newton from that thruster.
%
%   방향을 바꿀 수 있는 추진기는 열을 둘 기여한다 / a tilting thruster
%   contributes two columns
%       추력을 극형식이 아니라 직교 성분으로 쓰면
%       Writing the thrust in Cartesian components rather than in polar form,
%
%       f_i = [ T_i cos(delta_i) ; T_i sin(delta_i) ] = [ f_ix ; f_iy ]
%
%   removes delta_i from the unknowns and makes tau = B f linear. The two
%   columns are the e = (1,0) and e = (0,1) columns of the same location.
%   This is Fossen (2011) section 12.3.4, the extended thrust vector.
%
%   Column order matches f. For a configuration with tilting thrusters,
%
%       f = [ ... f_ix  f_iy ... ]'
%
%   with the pair adjacent and in that order.
%
%   No B in this course is transcribed from another file. Every one is
%   produced here, so a change of geometry propagates by itself.

if ~isstruct(cfg), cfg = otter_config(cfg); end

cols = {};
for i = 1:cfg.n_thr
    x = cfg.pos(1,i);
    y = cfg.pos(2,i);
    if cfg.tilt(i)
        % two columns: the x component and the y component of this thruster
        cols{end+1} = colrule(x, y, [1; 0]);   %#ok<AGROW>
        cols{end+1} = colrule(x, y, [0; 1]);   %#ok<AGROW>
    else
        e = cfg.dir(:,i);
        e = e / norm(e);                       % a direction must be a unit vector
        cols{end+1} = colrule(x, y, e);        %#ok<AGROW>
    end
end
B = [cols{:}];
end

% -------------------------------------------------------------------------
function c = colrule(x, y, e)
c = [ e(1)
      e(2)
      x*e(2) - y*e(1) ];
end
