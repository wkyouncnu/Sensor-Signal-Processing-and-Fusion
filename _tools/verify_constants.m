function T = verify_constants(verbose)
%VERIFY_CONSTANTS  Otter 의 관성행렬을 otter.m 으로부터 다시 만들고, 강의노트가
%                  인용하는 모든 수를 그것과 대조한다.
%                  Rebuild the Otter's inertia from otter.m and check every
%                  number the lecture notes quote against it.
%
%   verify_constants          표를 출력한다 / print the table
%   T = verify_constants(0)   조용히 돌려준다 / return it silently
%
%   왜 이 함수가 있는가 / why this exists
%       검증하지 않은 수식은 싣지 않는다는 것이 이 볼트의 규칙이다. 계수에
%       대해서는 그것이 곧 "기억이 아니라 원천과 대조한다" 는 뜻이다. 사람이
%       옮겨 적은 계수는 언젠가 한 자리가 틀리고, 틀린 자리는 결과가 크게
%       달라지기 전에는 눈에 띄지 않는다.
%
%       No equation is published in this vault until it has been checked. For
%       the coefficients that means checking against the source rather than
%       against memory: a coefficient copied by hand eventually loses a digit,
%       and a lost digit does not announce itself until something is badly
%       wrong.
%
%       MSS 가 갱신될 때마다 다시 돌리도록 만든 것이다. 2021 릴리스와 2024
%       재보정 사이에 실제로 바뀐 계수가 있다.
%       It is meant to be re-run whenever MSS is updated: coefficients did
%       change between the 2021 release and the 2024 recalibration.
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
         'k_pos'    'k_neg'    'n_max'  'n_min'   'T_u'   'K_u'    ...
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
    %  2026-09-14 수정. 예전 문구 "Quote M(6,6), never I_z - N_rdot" 은 I_z 가
    %  **어느 점 둘레인지** 말하지 않아서, W01/W03 의 "M66 = I_z - N_rdot (I_z 는
    %  원점 둘레)" 와 정면으로 부딪혔다. 둘 다 맞다 — 점이 다를 뿐이다. 그래서
    %  두 점의 값을 모두 찍고, 평행축 항으로 둘이 이어진다는 것을 보인다.
    Iz_CG = Ig(3,3);
    Iz_CO = Iz_CG + (m + mp)*rg(1)^2;
    fprintf('\n  I_z about the CG     = %.4f   ->  I_z - N_rdot = %.4f  (NOT M(6,6))\n', ...
            Iz_CG, Iz_CG - Nrdot);
    fprintf('  I_z about the origin = %.4f   ->  I_z - N_rdot = %.4f  = M(6,6) = %.4f\n', ...
            Iz_CO, Iz_CO - Nrdot, M(6,6));
    fprintf(['  the two differ by (m+mp) x_g^2 = %.4f, the parallel-axis term, because\n' ...
             '  the body origin is not the centre of gravity (x_g = %.6f m).\n' ...
             '  M66 = I_z - N_rdot holds with I_z about the ORIGIN of {b}.\n\n'], ...
            (m + mp)*rg(1)^2, rg(1));
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
