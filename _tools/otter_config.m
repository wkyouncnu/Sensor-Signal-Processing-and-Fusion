function cfg = otter_config(name)
%OTTER_CONFIG  Otter USV 의 추진기 구성.
%              Actuator configuration of the Otter USV.
%
%   cfg = otter_config('base')          폰툰마다 고정 프로펠러 하나씩
%                                       two fixed propellers, one per pontoon
%   cfg = otter_config('aft_azimuth')   방향을 바꿀 수 있는 선미 추진기 둘 (11주차)
%                                       two tilting stern thrusters (Week 11)
%   cfg = otter_config('bow_thruster')  기본 구성에 선수 터널 추진기 하나 (6주차)
%                                       base plus one bow tunnel thruster (Week 6)
%   cfg = otter_config('quad_tilt')     ±45 도로 기우는 추진기 넷 (12주차)
%                                       four tilting thrusters, ±45 deg (Week 12)
%
%   네 구성은 모두 **같은 선체**를 쓴다. 다른 것은 추진기 모델과 제어 유효행렬 B
%   뿐이다. 그래야 네 구성을 비교했을 때 그 차이가 구동장치의 차이이고 다른
%   무엇의 차이도 아니라고 말할 수 있다.
%
%   All four configurations share the same hull. Only the actuator model and
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
%                 vector (Week 3 onward)
%     ext_force   true when B can produce a sway force, so that the hull needs
%                 a second inport for the part otter.m cannot carry (Week 6)
%
%   THE COLUMN RULE (Week 3). A thruster at (x, y) pushing along the unit
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
        % Week 11. The two pontoon thrusters move aft and gain a servo.
        cfg.n_thr = 2;
        cfg.tilt  = [true true];
        cfg.pos   = [ -l_a     -l_a   ;
                     -y_pont   y_pont ];
        cfg.dir   = [ NaN NaN ; NaN NaN ];   % set by the servo
        cfg.alpha_max  = deg2rad([45 45]);
        cfg.alpha_rlim = deg2rad([90 90]);

    case 'bow_thruster'
        % Week 6. The base hull plus one fixed transverse thruster forward.
        % Three thrusters against three planar degrees of freedom: this is the
        % configuration at which the Otter becomes fully actuated.
        cfg.n_thr = 3;
        cfg.tilt  = [false false false];
        cfg.pos   = [   0        0      l_f ;
                     -y_pont   y_pont    0  ];
        cfg.dir   = [   1        1       0  ;
                        0        0       1  ];
        cfg.alpha_max  = [NaN NaN NaN];
        cfg.alpha_rlim = [NaN NaN NaN];
        cfg.input_mode = 'n';                % 선미 한 쌍은 축회전수로 들어간다

    case 'quad_tilt'
        % Week 12. Four thrusters, each on a servo limited to +-45 deg.
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

%  이 구성이 횡력을 낼 수 있는가 / can this configuration produce a sway force
%    `otter.m` 은 선미 프로펠러 **둘**만 받고 그 안에서 tau 를 만들며, 그 tau 의
%    둘째 성분은 언제나 0 이다. B 의 둘째 행에 0 이 아닌 것이 있으면 그 힘은
%    `otter.m` 안으로 들어갈 자리가 없다. 그때 `add_otter_plant` 가 포트를 하나
%    더 만들어 중첩으로 더한다 (6주차). 기본 구성은 B(2,:) = 0 이므로 1~5 주차
%    모델은 전혀 바뀌지 않는다.
cfg.ext_force = any(cfg.B(2,:) ~= 0);
end
