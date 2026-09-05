function T = verify_constants(verbose)
%VERIFY_CONSTANTS  Rebuild the Otter's inertia from otter.m and check every
%                  number the lecture notes quote against it.
%
%   verify_constants          print the table
%   T = verify_constants(0)   return it silently
%
%   WHY THIS EXISTS
%
%   The vault rule is that no equation is published until it has been checked
%   (standing-orders.md §3-3). For the coefficients that means checking against
%   the source, not against memory. This function does that, and it is meant to
%   be re-run whenever MSS is updated.
%
%   WHY NOT MEASURE IT BY FINITE DIFFERENCE
%
%   The obvious check - apply a known force, read the acceleration, divide - is
%   wrong, and wrong in a way that looks plausible. otter.m integrates
%
%       nu_dot = M \ (tau - ...)
%
%   with a 6x6 M that is NOT block diagonal: the CG offset couples surge to
%   heave and pitch. So a pure surge force gives
%
%       udot = [inv(M)]_11 * X,   not   X / M(1,1)
%
%   and the ratio X/udot returns 1/[inv(M)]_11 = 76.71 kg rather than
%   M(1,1) = 85.50 kg. The difference is 10 per cent and there is nothing in
%   the number itself to warn that it is the wrong quantity. The lecture wants
%   the MATRIX ENTRY, so the matrix is rebuilt here line by line as otter.m
%   builds it (otter.m lines 55-120), and read directly.
%
%   The reconstruction below must be kept in step with otter.m. If MSS changes
%   those lines, this function is the thing that notices.

if nargin < 1, verbose = true; end
mss_path();

%  ---- otter.m lines 55-120, reproduced ---------------------------------
g   = 9.81;   rho = 1025;   L = 2.0;   B = 1.08;
m   = 55.0;   rg  = [0.2 0 -0.2]';
R44 = 0.4*B;  R55 = 0.25*L;  R66 = 0.25*L;
T_yaw = 1;    Umax = 6 * 0.5144;
B_pont = 0.25;  y_pont = 0.395;  Cb_pont = 0.4;
mp = 25;      rp = [0.05 0 -0.35]';          % the payload this course uses

Ig_CG = m * diag([R44^2, R55^2, R66^2]);
rg    = (m*rg + mp*rp)/(m+mp);
Ig    = Ig_CG - m*Smtrx(rg)^2 - mp*Smtrx(rp)^2;

MRB = Hmtrx(rg)' * [ (m+mp)*eye(3) zeros(3); zeros(3) Ig ] * Hmtrx(rg);
Xudot = -0.1*m;      Yvdot = -1.5*m;      Zwdot = -1.0*m;
Kpdot = -0.2*Ig(1,1); Mqdot = -0.8*Ig(2,2); Nrdot = -1.7*Ig(3,3);
M = MRB - diag([Xudot, Yvdot, Zwdot, Kpdot, Mqdot, Nrdot]);

k_pos = 0.02216/2;   k_neg = 0.01289/2;
n_max =  sqrt((0.5*24.4*g)/k_pos);
n_min = -sqrt((0.5*13.6*g)/k_neg);
Xu    = -24.4*g/Umax;
Nr    = -M(6,6)/T_yaw;

%  ---- what the notes claim, and what the source says -------------------
name  = {'M11'      'M66'      'x_g'    'X_u'     'N_r'     'U_max'  ...
         'k_pos'    'k_neg'    'n_max'  'n_min'   'tau_u'   'K_u'    ...
         'Nomoto T' 'Nomoto K' 'M(2,2)' 'M(2,6)'};
src   = [ M(1,1)     M(6,6)     rg(1)    Xu        Nr        Umax     ...
          k_pos      k_neg      n_max    n_min     M(1,1)/abs(Xu)  1/abs(Xu) ...
          M(6,6)/abs(Nr)  1/abs(Nr)  M(2,2)  M(2,6) ];
note  = [ 85.50      42.65      0.153   -77.5544  -42.65    3.0864   ...
          0.011080   0.006445   103.93  -101.74   1.1025    0.012894 ...
          1.0000     0.023446   162.50  12.25 ];

T = table(name(:), src(:), note(:), abs(src(:)-note(:)), ...
          'VariableNames', {'quantity','from_otter_m','in_the_notes','difference'});

if verbose
    fprintf('\n  Otter constants — source of truth is otter.m, rebuilt here\n\n');
    disp(T);
    bad = T.difference > 0.5*10.^(-numDecimals(note))';
    if any(bad)
        fprintf(2, '\n  MISMATCH in: %s\n', strjoin(T.quantity(bad)', ', '));
    else
        fprintf('  every quoted value agrees with otter.m to its printed precision\n');
    end

    fprintf('\n  3-DOF inertia, rows and columns [1 2 6]:\n\n');
    S = M([1 2 6],[1 2 6]);
    fprintf('      %10.4f %10.4f %10.4f\n', S');
    fprintf(['\n  The first row and column are zero to machine precision. That is\n' ...
             '  port-starboard symmetry, and it is what makes the surge reduction\n' ...
             '  of W02 2-1 exact rather than approximate.\n']);
    fprintf('\n  I_z - Nrdot = %.4f, but M(6,6) = %.4f — they differ by %.4f\n', ...
            Ig(3,3)-Nrdot, M(6,6), M(6,6)-(Ig(3,3)-Nrdot));
    fprintf(['  because the body origin is not the centre of gravity (x_g = %.4f m).\n' ...
             '  Quote M(6,6), never I_z - N_rdot.\n\n'], rg(1));
end
end

function d = numDecimals(v)
%NUMDECIMALS  Decimals printed for each quoted value, so the tolerance for
%             "agrees" is the precision the note actually claims.
d = zeros(size(v));
for i = 1:numel(v)
    s = strtrim(sprintf('%.10g', v(i)));
    k = strfind(s, '.');
    if isempty(k), d(i) = 0; else, d(i) = numel(s) - k; end
end
end
