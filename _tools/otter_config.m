function cfg = otter_config(name)
%OTTER_CONFIG  Actuator configuration of the Otter USV.
%
%   cfg = otter_config('base')          two fixed propellers, one per pontoon
%   cfg = otter_config('aft_azimuth')   two tilting stern thrusters      (Week 9)
%   cfg = otter_config('bow_thruster')  base + one bow tunnel thruster   (Week 10)
%   cfg = otter_config('quad_tilt')     four tilting thrusters, +-45 deg (Week 11)
%
%   All four configurations share the SAME hull. Only the actuator model and
%   the control effectiveness matrix B differ, so that any comparison between
%   them measures the actuation and nothing else.
%
%   FIELDS
%
%     name        the string above
%     n_thr       number of physical thrusters
%     tilt        1 x n_thr logical, true where the thruster can rotate
%     pos         2 x n_thr, thruster location in {b}, [x; y] in metres
%     dir         2 x n_thr, unit thrust direction for the FIXED thrusters
%     B           3 x n_cols control effectiveness matrix, tau = B * f
%     n_cols      columns of B: 1 per fixed thruster, 2 per tilting thruster
%     k_pos       thrust coefficient, forward, one propeller [N/(rad/s)^2]
%     k_neg       thrust coefficient, reverse
%     n_max       maximum shaft speed [rad/s]
%     n_min       minimum shaft speed [rad/s]
%     alpha_max   azimuth limit [rad], NaN for a fixed thruster
%     alpha_rlim  azimuth rate limit [rad/s], NaN for a fixed thruster
%     input_mode  'n' for shaft speeds (Week 1), 'f' for the extended thrust
%                 vector (Week 2 onward)
%
%   THE COLUMN RULE (Week 2). A thruster at (x, y) pushing along the unit
%   vector e = (e_x, e_y) contributes one column
%
%       [ e_x ; e_y ; x*e_y - y*e_x ]
%
%   A tilting thruster contributes TWO columns, one for each Cartesian
%   component of its thrust, which is what makes the allocation problem
%   linear in the unknowns. Every B below is DERIVED from this rule by
%   otter_B(); none is transcribed from another file. This project ships two
%   mutually negative B matrices elsewhere, and the column rule is the only
%   definition this course uses.
%
%   Geometry follows Tools/MSS/VESSELS/otter.m: the pontoons are at
%   y = +-y_pont = +-0.395 m. The bow and stern arms l_f and l_a are stated
%   per configuration below.
%
%   See also OTTER_B, ADD_OTTER_PLANT.

if nargin < 1 || isempty(name), name = 'base'; end

% --- hull geometry, from otter.m -----------------------------------------
y_pont = 0.395;          % half distance between the pontoons [m]
l_f    = 1.5;            % bow arm, used by the tilting configurations [m]
l_a    = 1.0;            % stern arm [m]

% --- propeller, from otter.m lines 93-96 ---------------------------------
cfg.k_pos = 0.02216/2;                        % positive bollard, one propeller
cfg.k_neg = 0.01289/2;                        % negative bollard, one propeller
cfg.n_max =  sqrt((0.5*24.4*9.81)/cfg.k_pos); % [rad/s]
cfg.n_min = -sqrt((0.5*13.6*9.81)/cfg.k_neg); % [rad/s]

cfg.name       = lower(name);
cfg.input_mode = 'f';

switch cfg.name
    case 'base'
        % Two propellers, one per pontoon, both fixed and facing forward.
        cfg.n_thr = 2;
        cfg.tilt  = [false false];
        cfg.pos   = [   0        0    ;      % x
                     -y_pont   y_pont ];     % y
        cfg.dir   = [   1        1    ;      % e_x
                        0        0    ];     % e_y
        cfg.alpha_max  = [NaN NaN];
        cfg.alpha_rlim = [NaN NaN];
        cfg.input_mode = 'n';                % Week 1 drives shaft speeds

    case 'aft_azimuth'
        % Week 9. The two pontoon thrusters move aft and gain a servo.
        cfg.n_thr = 2;
        cfg.tilt  = [true true];
        cfg.pos   = [ -l_a     -l_a   ;
                     -y_pont   y_pont ];
        cfg.dir   = [ NaN NaN ; NaN NaN ];   % set by the servo
        cfg.alpha_max  = deg2rad([45 45]);
        cfg.alpha_rlim = deg2rad([90 90]);

    case 'bow_thruster'
        % Week 10. The base hull plus one fixed transverse thruster forward.
        cfg.n_thr = 3;
        cfg.tilt  = [false false false];
        cfg.pos   = [   0        0      l_f ;
                     -y_pont   y_pont    0  ];
        cfg.dir   = [   1        1       0  ;
                        0        0       1  ];
        cfg.alpha_max  = [NaN NaN NaN];
        cfg.alpha_rlim = [NaN NaN NaN];

    case 'quad_tilt'
        % Week 11. Four thrusters, each on a servo limited to +-45 deg.
        cfg.n_thr = 4;
        cfg.tilt  = [true true true true];
        cfg.pos   = [  l_f      l_f     -l_a     -l_a  ;
                     -y_pont   y_pont  -y_pont  y_pont ];
        cfg.dir   = NaN(2,4);
        cfg.alpha_max  = deg2rad([45 45 45 45]);
        cfg.alpha_rlim = deg2rad([90 90 90 90]);

    otherwise
        error('otter_config:unknown', ...
              ['Unknown configuration ''%s''. Valid names are ' ...
               '''base'', ''aft_azimuth'', ''bow_thruster'', ''quad_tilt''.'], name);
end

cfg.y_pont = y_pont;
cfg.l_f    = l_f;
cfg.l_a    = l_a;
cfg.B      = otter_B(cfg);
cfg.n_cols = size(cfg.B, 2);
end
