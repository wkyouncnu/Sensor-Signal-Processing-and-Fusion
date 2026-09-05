function verify_guidance()
%VERIFY_GUIDANCE  Check Week 4's guidance arithmetic against MSS, numerically.
%
%   >> verify_guidance
%
%   The course rule is that an equation is not published until it has been
%   checked five ways - dimension, limit, sign, number, source. This function
%   is the NUMBER and the SOURCE for the guidance laws: it runs our own
%   arithmetic and Fossen's side by side on the same inputs and reports the
%   largest disagreement.
%
%   WHAT IS CHECKED
%
%     1  crosstrack_err  against MSS crosstrackWpt.m          (cross-track)
%     2  crosstrack_err  against a brute-force projection     (along-track)
%     3  the LOS law at its three limits                      (limit, sign)
%     4  ILOS against MSS ILOSpsi.m, stepped together         (number)
%     5  the two switching criteria, where they disagree      (sign)
%
%   A failure prints the case and the size of the disagreement. Nothing is
%   plotted and nothing is written: this is a gate, not an experiment.

mss_path();
fprintf('\n  verify_guidance — Week 4 arithmetic against MSS\n\n');
fprintf('    %-46s %14s %10s\n', 'check', 'largest error', 'verdict');
fprintf('    %s\n', repmat('-', 1, 74));

ok = true;

%% ---- 1 & 2. the two errors, from one rotation --------------------------
%  A leg that is neither axis-aligned nor 45 deg, so no coincidence can hide
%  a transposed sine. Positions on both sides of it and beyond both ends.
wp_k    = [ 10  -5];
wp_next = [ 70  35];
NN = [-20 0 15 40 65 90 30 30]';
EE = [ 10 0 -5 20 30 55 60 -40]';

[x_e, y_e, pi_p] = crosstrack_err(NN, EE, wp_k, wp_next);

e1 = 0;
for i = 1:numel(NN)
    y_mss = crosstrackWpt(wp_next(1), wp_next(2), wp_k(1), wp_k(2), NN(i), EE(i));
    e1 = max(e1, abs(y_e(i) - y_mss));
end
ok = report('1  y_e against MSS crosstrackWpt.m', e1, 1e-12) && ok;

%  Along-track has no MSS scalar to compare with, so it is checked against the
%  definition it came from: the projection of the position error onto the unit
%  vector along the leg.
t  = (wp_next - wp_k) / norm(wp_next - wp_k);
e2 = max(abs(x_e - ((NN - wp_k(1))*t(1) + (EE - wp_k(2))*t(2))));
ok = report('2  x_e against the projection onto the leg', e2, 1e-12) && ok;

%  And the identity that says the rotation lost nothing.
e2b = max(abs(hypot(x_e, y_e) - hypot(NN - wp_k(1), EE - wp_k(2))));
ok = report('2b norm preserved by the rotation', e2b, 1e-12) && ok;

%% ---- 3. the LOS law at its limits --------------------------------------
Delta = 8;
los = @(ye) pi_p - atan(ye/Delta);

e3 = abs(los(0) - pi_p);                             % on the path -> along it
ok = report('3a y_e = 0  gives  psi_d = pi_p', e3, 1e-15) && ok;

e3b = abs((los(1e12) - pi_p) + pi/2);                % far to starboard -> -90
ok = report('3b y_e -> +inf gives pi_p - 90 deg', e3b, 1e-9) && ok;

e3c = abs((los(-1e12) - pi_p) - pi/2);               % far to port      -> +90
ok = report('3c y_e -> -inf gives pi_p + 90 deg', e3c, 1e-9) && ok;

%  Sign: a vessel to STARBOARD of the leg (y_e > 0) must be told to turn to
%  PORT, i.e. psi_d must fall below pi_p.
e3d = double( ~(los(5) < pi_p && los(-5) > pi_p) );
ok = report('3d sign: starboard error turns the bow to port', e3d, 0) && ok;

%% ---- 4. ILOS against MSS ILOSpsi.m -------------------------------------
%  Stepped together from the same initial condition. MSS keeps its state in
%  persistent variables, so it is cleared first and then driven one sample at
%  a time along a track that crosses the leg.
kappa = 0.5;  h = 0.02;  R = 5;
wpt.pos.x = [wp_k(1); wp_next(1)];
wpt.pos.y = [wp_k(2); wp_next(2)];

clear ILOSpsi
y_int = 0;                                   % our own copy of the state
e4    = 0;
for i = 1:200
    Ni = 15 + 0.20*i;                        % a track that closes on the leg
    Ei =  5 + 0.14*i;

    evalc('psi_mss = ILOSpsi(Ni, Ei, Delta, kappa, h, R, wpt);');   % it prints

    [~, ye_i] = crosstrack_err(Ni, Ei, wp_k, wp_next);
    Kp   = 1/Delta;
    Ki   = kappa*Kp;
    psi_ours = pi_p - atan(Kp*ye_i + Ki*y_int);
    y_int    = y_int + h * Delta*ye_i / (Delta^2 + (ye_i + kappa*y_int)^2);

    e4 = max(e4, abs(ssa(psi_ours - psi_mss)));
end
clear ILOSpsi
ok = report('4  ILOS against MSS ILOSpsi.m, 200 steps', e4, 1e-12) && ok;

%% ---- 5. the two switching criteria disagree, and here is where ---------
%  R short of the waypoint along the leg, but 2R to the side of it. The
%  along-track test fires; the circle test does not. If both fired, or
%  neither, the two criteria would not be worth distinguishing.
d   = norm(wp_next - wp_k);
nrm = [-sin(pi_p) cos(pi_p)];                       % unit normal to the leg
P   = wp_k + (d - R + 0.5)*t + 2*R*nrm;             % just inside the along-track band

%  A two-waypoint list has nowhere to advance to, so the two criteria are
%  compared as the raw tests rather than through wp_switch.
[x_eP, y_eP] = crosstrack_err(P(1), P(2), wp_k, wp_next);
hit_along  = (d - x_eP) < R;
hit_circle = hypot(P(1)-wp_next(1), P(2)-wp_next(2)) < R;
e5 = double( ~(hit_along && ~hit_circle) );
ok = report('5  along-track fires where the circle does not', e5, 0) && ok;
fprintf('        (that point is %.2f m short along the leg and %.2f m to the side)\n', ...
        d - x_eP, y_eP);

%% ---- verdict -----------------------------------------------------------
fprintf('\n');
if ok
    fprintf('  ALL CHECKS PASSED — the Week 4 arithmetic matches MSS.\n\n');
else
    error('verify_guidance:failed', 'At least one check failed. Do not publish.');
end
end

% -------------------------------------------------------------------------
function ok = report(name, err, tol)
ok = err <= tol;
if ok, verdict = 'ok'; else, verdict = 'FAIL'; end
fprintf('    %-46s %14.3e %10s\n', name, err, verdict);
end
