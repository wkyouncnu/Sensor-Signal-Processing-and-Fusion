function B = otter_B(cfg)
%OTTER_B  Control effectiveness matrix, built from the column rule.
%
%   B = otter_B(cfg)            cfg from otter_config
%   B = otter_B('quad_tilt')    shorthand
%
%   tau = B * f,  tau = [X ; Y ; N]
%
%   THE COLUMN RULE. A thruster at (x, y) in {b} that pushes along the unit
%   vector e = (e_x, e_y) contributes exactly one column
%
%       [ e_x ; e_y ; x*e_y - y*e_x ]
%
%   The third entry is the z component of the cross product r x F divided by
%   the thrust magnitude, so the column is the generalised force produced by
%   one newton from that thruster.
%
%   TILTING THRUSTERS contribute TWO columns. Writing the thrust in Cartesian
%   components rather than in polar form,
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
