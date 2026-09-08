function w04_losgeo(outfile)
%W04_LOSGEO  figures/w04-los-geometry.svg 의 기하를 계산해서 TikZ 매크로로 낸다.
%
%   matlab -batch "addpath _tools; w04_losgeo"
%
%   배치는 Fossen 의 표준 그림을 따른다 — TTK 4190 Guidance, Navigation and
%   Control of Vehicles 강의노트, 그리고 Handbook (2021) 그림 12.x:
%   경로는 왼쪽 아래 p_i 에서 오른쪽 위 p_{i+1} 로 올라가고, 선박은 경로의
%   **우현쪽(화면에서 오른쪽 아래)** 에 있으며, 조준점은 수선의 발에서 경로를
%   따라 Delta 만큼 앞이다.
%
%   기호도 Fossen 을 따른다:
%
%       p_i^n, p_{i+1}^n     웨이포인트 (NED)
%       pi_p                 경로 접선각 = atan2(y_{i+1}-y_i, x_{i+1}-x_i)
%       x_e^p, y_e^p         경로좌표계에서의 along-track / cross-track 오차
%       Delta                look-ahead distance
%       chi_d                요구 침로각 = pi_p - atan(y_e^p / Delta)
%       chi, psi, beta_c     실제 침로각, 선수각, 크랩각.  chi = psi + beta_c
%       U                    대지속력 벡터
%
%   NED 는 x = North, y = East 다. 그림은 **East 를 화면 x, North 를 화면 y** 로
%   그리므로, 아래에서 내는 좌표는 전부 (East, North) 순서다.
%
%   숫자를 눈대중으로 찍지 않는다 (CLAUDE.md §4 규칙 6-1). 각과 길이가 서로
%   맞는지 마지막에 다시 재서 화면에 찍는다.

if nargin < 1 || isempty(outfile)
    root    = fileparts(fileparts(mfilename('fullpath')));
    outfile = fullfile(root, 'figures', 'src', 'w04-los-geometry-geo.tex');
end

% ---- 고른 값 ------------------------------------------------------------
pi_p  = 50;          % 경로 접선각 [deg from North]
xe    =  32;         % along-track 오차 [m]  (p_i 에서 수선의 발까지)
ye    =  16;         % cross-track 오차 [m]  (+ 는 경로의 우현쪽)
Delta =  38;         % look-ahead distance [m]
Lleg  = 100;         % 다리 길이 [m]
psi   =  14;         % 선수각 [deg]
beta  =   8;         % 크랩각 [deg]      ->  chi = psi + beta
SC    = 1.55;        % 1 m = 1.55 mm

chi   = psi + beta;
chi_d = pi_p - atand(ye/Delta);

% ---- 경로좌표계의 기저 (NED 성분) --------------------------------------
t = [cosd(pi_p); sind(pi_p)];        % 경로 방향        (N, E)
n = [-sind(pi_p); cosd(pi_p)];       % 경로의 우현 방향 (N, E)

p_i    = [0; 0];
p_next = p_i + Lleg  * t;
foot   = p_i + xe    * t;                 % 수선의 발
ves    = foot + ye   * n;                 % 선박
aim    = p_i + (xe + Delta) * t;          % 조준점

% ---- 세로 점선(x_n)이 경로와 만나는 점 ---------------------------------
%  선박을 지나는 **북쪽 방향** 점선이다. 경로와 만나는 곳에 pi_p 호를 놓는다.
s_cross = ves(2) / t(2);                  % East 가 같아지는 경로 매개변수
cross   = p_i + s_cross * t;

% ---- 검증 ---------------------------------------------------------------
losv  = aim - ves;
fprintf('  pi_p            = %7.3f deg\n', pi_p);
fprintf('  atan(ye/Delta)  = %7.3f deg\n', atand(ye/Delta));
fprintf('  chi_d (from 식) = %7.3f deg\n', chi_d);
fprintf('  chi_d (그림에서 잰 LOS 벡터) = %7.3f deg   차이 %.2e\n', ...
        atan2d(losv(2), losv(1)), abs(atan2d(losv(2),losv(1)) - chi_d));
fprintf('  수선 직각 확인  : (ves-foot).t = %.2e  (0 이어야 한다)\n', ...
        dot(ves - foot, t));
fprintf('  |ves-foot|      = %7.3f m   (= |y_e^p| = %g)\n', norm(ves-foot), abs(ye));
fprintf('  |aim-foot|      = %7.3f m   (= Delta   = %g)\n', norm(aim-foot), Delta);
fprintf('  |ves-aim|       = %7.3f m   (= sqrt(D^2+ye^2) = %.3f)\n', ...
        norm(losv), hypot(Delta, ye));
fprintf('  chi = psi+beta  = %g + %g = %g deg\n', psi, beta, chi);
assert(abs(dot(ves-foot,t)) < 1e-9, '수선이 직각이 아니다');
assert(abs(atan2d(losv(2),losv(1)) - chi_d) < 1e-9, 'LOS 벡터 각이 식과 다르다');

% ---- TikZ 매크로 --------------------------------------------------------
fid = fopen(outfile, 'w');  c = onCleanup(@() fclose(fid));
fprintf(fid, '%% figures/src/w04-los-geometry-geo.tex — 손으로 고치지 않는다.\n');
fprintf(fid, '%%\n%%   matlab -batch "addpath _tools; w04_losgeo"\n%%\n');
fprintf(fid, '%% Fossen TTK4190 의 표준 LOS 그림 배치. 좌표는 (East, North) 순이고\n');
fprintf(fid, '%% 단위는 mm (1 m = %g mm).\n\n', SC);

P = @(name, v) fprintf(fid, '\\def\\%s{(%.3f,%.3f)}\n', name, SC*v(2), SC*v(1));
P('WPi',    p_i);
P('WPnext', p_next);
P('Foot',   foot);
P('Ves',    ves);
P('Aim',    aim);
P('Cross',  cross);

%  TikZ 의 calc 로 중간점·연장점을 만들지 않는다. 매크로로 넘긴 좌표에
%  `!-0.08!` 같은 음수 계수를 물리면 pgf 의 계수 파서가 그대로 폭주한다
%  ("Paragraph ended before \tikz@cc@parse@factor was complete").
%  필요한 점을 전부 여기서 계산해서 내보내면 .tex 에는 산술이 남지 않는다.
P('PathA',  p_i    - 0.08*Lleg*t);        % 경로를 양쪽으로 조금 연장
P('PathB',  p_i    + 1.12*Lleg*t);
P('MidXe',  p_i    + 0.5*xe*t);           % x_e^p 이름표 자리
P('MidYe',  foot   + 0.5*ye*n);           % y_e^p
P('MidDel', foot   + (xe*0 + 0.5*Delta)*t + 0*n);   % Delta
P('MidLOS', ves    + 0.52*(aim - ves));   % LOS vector 이름표
%  수선의 발의 직각 표시 — 경로 반대방향으로 한 칸, 그 다음 선박 쪽으로 한 칸
d = 2.6/SC;                               % 화면 2.6 mm 를 m 로
P('RaA', foot - d*t);
P('RaB', foot - d*t + d*n);
P('RaC', foot + d*n);
%  조준점에서 내린 세로 점선의 아래 끝, 그리고 선박에서 그리로 가는 가로 점선
ybot = ves(1) - 26/SC;                    % 선박보다 26 mm 아래
P('DropA', [ybot; aim(2)]);
P('DropB', [ybot; ves(2)]);
%  그 만나는 곳의 직각 표시
e = 3.0/SC;
P('RbA', [ybot;        aim(2) - e]);
P('RbB', [ybot + e;    aim(2) - e]);
P('RbC', [ybot + e;    aim(2)]);
%  선박 위쪽 북쪽 점선의 끝
P('Xntop',  ves + [46/SC; 0]);

%  선박에서의 세 호와 그 이름표. 호마다 반지름이 다르고, 이름표는 그 호의
%  **가운데 각** 방향으로 반지름보다 조금 밖에 놓는다. 눈으로 자리를 잡으면
%  세 이름표가 LOS 벡터 위에 겹친다 — 실제로 처음에 그렇게 됐다.
%  화면각으로 계산한다: 화면각 = 90 - (북에서 잰 각).
arcs = {'Psi', psi, 20; 'Chi', chi, 26; 'Chid', chi_d, 33};
for a = 1:size(arcs,1)
    R  = arcs{a,3};
    sa = 90;  sb = 90 - arcs{a,2};              % 화면각 구간
    fprintf(fid, '\\def\\Rad%s{%.2f}\n', arcs{a,1}, R);
    fprintf(fid, '\\def\\ArcTop%s{(%.3f,%.3f)}\n', arcs{a,1}, ...
            SC*ves(2), SC*ves(1) + R);          % 호의 시작점 (북쪽)
    m  = 0.5*(sa + sb);
    fprintf(fid, '\\def\\Lab%s{(%.3f,%.3f)}\n', arcs{a,1}, ...
            SC*ves(2) + (R+4.2)*cosd(m), SC*ves(1) + (R+4.2)*sind(m));
end
%  크랩각 호는 psi 와 chi 사이, 반지름 14
mb = 0.5*((90-psi) + (90-chi));
fprintf(fid, '\\def\\ArcTopBeta{(%.3f,%.3f)}\n', ...
        SC*ves(2) + 14*cosd(90-psi), SC*ves(1) + 14*sind(90-psi));
fprintf(fid, '\\def\\LabBeta{(%.3f,%.3f)}\n', ...
        SC*ves(2) + 18.5*cosd(mb), SC*ves(1) + 18.5*sind(mb));

%  조준점의 각 호: 경로와 LOS 를 조준점에서 **뒤로** 본 구간. 그 가운데를
%  가리키는 화살표의 끝점도 함께 낸다.
Rc = 8.3;
c1 = (90 - pi_p)  + 180;
c2 = (90 - chi_d) + 180;
fprintf(fid, '\\def\\ArcTopCorr{(%.3f,%.3f)}\n', ...
        SC*aim(2) + Rc*cosd(c1), SC*aim(1) + Rc*sind(c1));
fprintf(fid, '\\def\\RadCorr{%.2f}\n', Rc);
fprintf(fid, '\\def\\ArcMidCorr{(%.3f,%.3f)}\n', ...
        SC*aim(2) + (Rc+1.6)*cosd(0.5*(c1+c2)), ...
        SC*aim(1) + (Rc+1.6)*sind(0.5*(c1+c2)));

%  선체 삼각형. TikZ 의 `rotate around` 에 맡기지 않고 꼭짓점을 여기서 돌린다 —
%  맡겼더니 선수가 **뒤를 향한** 채로 그려졌고, 화면에서 그것을 알아보기까지
%  확대를 두 번 해야 했다. 선수 방향 단위벡터는 psi 로 만든다 (NED 성분).
th = [cosd(psi); sind(psi)];              % 선수 방향 (N, E)
tn = [-sind(psi); cosd(psi)];             % 우현 방향
Lh = 6.0/SC;  Bh = 2.3/SC;                % 화면 길이 6.0 mm, 반폭 2.3 mm
P('HullBow',  ves + Lh*th);
P('HullStbd', ves - 0.42*Lh*th + Bh*tn);
P('HullPort', ves - 0.42*Lh*th - Bh*tn);

%  x_b 와 U 의 이름표. 화살표 끝보다 조금 더 나가되, 서로 다른 각이므로
%  자동으로 갈라진다. 눈으로 놓았을 때 x_b 가 psi 이름표 위에 얹혔다.
fprintf(fid, '\\def\\LabXb{(%.3f,%.3f)}\n', ...
        SC*ves(2) + 27.5*cosd(90-psi), SC*ves(1) + 27.5*sind(90-psi));
fprintf(fid, '\\def\\LabU{(%.3f,%.3f)}\n', ...
        SC*ves(2) + 41.0*cosd(90-chi),  SC*ves(1) + 41.0*sind(90-chi));

%  Delta 이름표는 수선의 발과 조준점 사이 0.72 지점에서 경로 왼쪽으로 비켜 둔다.
%  가운데(0.5)에 두면 pi_p 호와 겹친다.
P('LabDelta', foot + 0.72*Delta*t - (4.6/SC)*n);
%  pi_p 이름표는 x_n 점선의 왼쪽
fprintf(fid, '\\def\\LabPip{(%.3f,%.3f)}\n', SC*ves(2) - 4.0, SC*cross(1) + 3.0);
fprintf(fid, '\n');

%  화면각 = 90 - (북에서 잰 각).  TikZ 의 각은 동쪽에서 반시계로 잰다.
S = @(name, a) fprintf(fid, '\\def\\%s{%.4f}\n', name, 90 - a);
S('ScrPip',  pi_p);
S('ScrChid', chi_d);
S('ScrChi',  chi);
S('ScrPsi',  psi);
fprintf(fid, '\n');

%  본문에 그대로 박히는 값이므로 꼬리 0 을 달지 않는다. "50.0000 deg" 는
%  네 자리를 잰 것처럼 보이지만 실제로는 고른 값이다.
V = @(name, x) fprintf(fid, '\\def\\%s{%g}\n', name, x);
V('ValPip',   pi_p);
V('ValChid',  round(chi_d,2));
V('ValChi',   chi);
V('ValPsi',   psi);
V('ValBeta',  beta);
V('ValXe',    xe);
V('ValYe',    ye);
V('ValDelta', Delta);
V('ValCorr',  round(atand(ye/Delta), 2));
V('ValLOS',   round(hypot(Delta, ye), 2));
V('Scale',    SC);

fprintf('\nwrote %s\n', outfile);
end
