%% A1 · section F — an empty row in B is not an empty column in M inverse
%
%      A1_0_setup
%      A1_F_sway_without_force
%
%  The sway row of B is empty, so no command produces a sway FORCE. The vessel
%  nevertheless acquires a sway ACCELERATION the instant a yaw moment is
%  applied, because M(2,6) is not zero. Produces img/A1_result_coupling.png

clear V cfg y n1 n2 x0 f0 fa fb Xa Nb cX cN LB i o yy TZ tt kz f
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)),'_tools'), here);
mss_path();
if ~isfile(fullfile(here,'A1_actuation.slx')), A1_1_build_actuation; end
if ~isfolder(fullfile(here,'img')), mkdir(fullfile(here,'img')); end

V   = A1_vars;
cfg = otter_config('base');
y   = cfg.y_pont;

n1 = 60;
n2 = -n1*sqrt(cfg.k_pos/cfg.k_neg);       % the pure-moment command of section E

%% ---- probing the plant at rest -----------------------------------------
%  At nu = 0 the Coriolis matrix and both damping terms vanish, and the trim
%  term is the same in every call, so it cancels in the difference. What
%  survives is exactly M^-1 tau: the plant is a linear map at rest.
x0 = zeros(12,1);
f0 = otter(x0, [0;0],   V.mp, V.rp, 0, 0);
fa = otter(x0, [n1;n1], V.mp, V.rp, 0, 0);      % pure X
fb = otter(x0, [n1;n2], V.mp, V.rp, 0, 0);      % pure N
Xa = 2*cfg.k_pos*n1^2;                          % the X of that command  [N]
Nb = 2*y*cfg.k_pos*n1^2;                        % the N of that command  [N m]
cX = (fa(1:6) - f0(1:6))/Xa;
cN = (fb(1:6) - f0(1:6))/Nb;

LB = {'u dot [m/s^2]','v dot [m/s^2]','w dot [m/s^2]', ...
      'p dot [rad/s^2]','q dot [rad/s^2]','r dot [rad/s^2]'};

fprintf('\n  A1 section F — acceleration per unit generalised force, at rest\n\n');
fprintf('    %-22s %16s %16s\n', 'acceleration', 'per N of X', 'per N.m of N');
fprintf('    %s\n', repmat('-', 1, 58));
for i = 1:6
    fprintf('    %-22s %16.4e %16.4e\n', LB{i}, cX(i), cN(i));
end

fprintf(['\n    A PURE YAW MOMENT PRODUCES A SWAY ACCELERATION, %.4e m/s^2 per\n' ...
         '    N.m, with no sway force anywhere in the problem. M(2,6) = 12.25\n' ...
         '    kg.m is not zero because the payload puts the centre of gravity\n' ...
         '    0.153 m forward of the origin of {b}. Week 1 attributed the sway\n' ...
         '    velocity of a turn to the Coriolis term, and for the STEADY value\n' ...
         '    that is right: at nu dot = 0 the mass matrix leaves the balance.\n' ...
         '    This measurement is about the first instants, not the steady state.\n' ...
         '\n    Effective surge mass  1/(M^-1)_11 = %.4f kg     (M11 = 85.50)\n' ...
         '    Effective yaw inertia 1/(M^-1)_66 = %.4f kg.m^2 (M66 = 42.65)\n'], ...
         cN(2), 1/cX(1), 1/cN(6));

%% ---- the same coupling, seen in the simulation -------------------------
o  = run_sim('A1_actuation', V, 'n_cmd', [n1; n2]);
yy = A1_read(o);

%% ---- the figure --------------------------------------------------------
f = lab_fig('A1 F  coupling', 1000, 420);

subplot(1,2,1);
bar(categorical(LB, LB), [cX cN]);
ylabel('acceleration per unit generalised force');
legend({'per N of X','per N\cdotm of N'}, 'Location','best');
title({'the plant is a linear map at rest', '\nu dot = M^{-1} \tau'});
grid on;

%  Only the first instants. The coupling sets the INITIAL slope; after a
%  fraction of a second the Coriolis and cross-flow terms take over and the
%  sway velocity turns back. Plotting several seconds hides the agreement
%  that this panel exists to show.
TZ = 0.6;
subplot(1,2,2); hold on;
tt = linspace(0, TZ, 200);
plot(tt, cN(2)*Nb*tt, '--', 'Color',[0.85 0.33 0.10], 'LineWidth',1.6);
kz = yy.t <= TZ;
plot(yy.t(kz), yy.v(kz), 'Color',[0 0.45 0.74], 'LineWidth',1.6);
xlim([0 TZ]);
xlabel('time [s]'); ylabel('v  sway velocity [m/s]');
legend({'(M^{-1})_{26} N t   — the coupling alone','the plant'}, 'Location','southwest');
title({'sway from a pure yaw moment, first 0.6 s', ...
       sprintf('Y = 0 throughout; slopes agree to %.2f%%', ...
       100*abs(1 - (yy.v(2)/yy.t(2))/(cN(2)*Nb)))});

sgtitle('A1 F — an empty row in B is not an empty column in M^{-1}', 'FontWeight','bold');
exportgraphics(f, fullfile(here,'img','A1_result_coupling.png'), 'Resolution', 150);
fprintf('\n  figure -> img/A1_result_coupling.png\n\n');
