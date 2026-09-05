function w01_euler_R(outfile)
%W01_EULER_R  figures/w01-euler.svg 의 네 칸 기하를 계산해서 TikZ 매크로로 낸다.
%
%   w01_euler_R                     기본 위치에 쓴다
%   w01_euler_R('some/file.tex')    다른 곳에 쓴다
%
%   3차원 그림은 눈대중으로 기울이지 않는다 (CLAUDE.md §4 규칙 6-1). 네 칸의
%   좌표축·갑판·회전호를 여기서 실제 회전행렬로 계산해 TikZ 좌표로 적어 두고,
%   .tex 는 그것을 \input 해서 그리기만 한다. 사영 자체는 TikZ 가 한다 —
%   w01-euler.tex 의 x/y/z 기저가 w01-6dof.tex 와 같은 정사영이다.
%
%   순서는 zyx 오일러각이다. Fossen (2021) Handbook 식 (2.18):
%
%       R_b^n(Theta) = Rz(psi) * Ry(theta) * Rx(phi)
%
%   그래서 네 칸은  {n} --Rz(psi)--> {1} --Ry(theta)--> {2} --Rx(phi)--> {b}.
%   각 칸의 좌표축은 그 단계 행렬의 **열**이고, 갑판은 그 행렬을 곱한 것이다.
%   회전이 일어나는 축 둘레의 호는 그 축에 수직인 평면 위의 원이므로, 사영한
%   타원의 중심이 저절로 축선 위에 놓인다.
%
%   검증: 직교성 · det = +1 · MSS Rzyx 와의 대조를 화면에 찍는다.
%
%   See also W01_6DOF_ARCS.

if nargin < 1 || isempty(outfile)
    root    = fileparts(fileparts(mfilename('fullpath')));
    outfile = fullfile(root, 'figures', 'src', 'w01-euler-R.tex');
end

psi = 40; th = 20; ph = 30;         % 눈에 보이게 넉넉히 잡은 각 [deg]

AXLEN = 1.25;                       % 축 길이
LABD  = 1.52;                       % 축 이름표까지의 거리
ARCR  = 0.26;                       % 호 반지름
NARC  = 60;                         % 호를 이루는 선분 수

% 정사영. 화면 오른쪽 A1, 화면 아래 A2 — w01-euler.tex 의 x/y/z 기저와 같다.
A1 = [ 0.87687  0.48072  0.00000];
A2 = [-0.21477  0.39176  0.89465];

% 갑판 다각형 — 선수가 +x 인 평면 도형
deck = [ 1.00  0.55 -0.85 -1.00 -1.00 -0.85  0.55
         0.00  0.42  0.42  0.24 -0.24 -0.42 -0.42
         0.00  0.00  0.00  0.00  0.00  0.00  0.00 ];

M    = cell(1,4);
M{1} = eye(3);
M{2} = Rz(psi);
M{3} = Rz(psi) * Ry(th);
M{4} = Rz(psi) * Ry(th) * Rx(ph);

% 그 칸에서 **다음에** 돌아갈 축. 1 = x, 2 = y, 3 = z, 0 = 없음
act  = [3 2 1 0];
name = {'A','B','C','D'};

% 호는 한 바퀴가 아니라 300 도만 그린다. 남는 60 도의 **틈**에 각 이름표를 둔다.
% 틈이 어느 쪽을 보게 할지는 칸마다 다르다 — 축 이름표와 겹치지 않는 쪽으로
% 돌려 놓는다. 사영이 짧은 축(칸 B 의 y_1)에서는 축 방향과 틈 방향이 겹쳐서
% 두 이름표가 붙어 버리기 때문이다.
phase = [0 90 0 0];             % [deg]

% ---- 검증 1 : 직교성과 행렬식 -------------------------------------------
for k = 1:4
    e = norm(M{k}'*M{k} - eye(3), 'fro');
    d = det(M{k});
    fprintf('panel %s : ||R''R - I|| = %.2e   det = %.6f\n', name{k}, e, d);
    if e > 1e-12 || abs(d-1) > 1e-12
        error('w01_euler_R:notRotation', 'panel %s is not a rotation', name{k});
    end
end

% ---- 검증 2 : MSS Rzyx 와 대조 -------------------------------------------
% zyx 오일러각의 정본은 MSS 의 Rzyx.m 이다. 우리가 곱한 순서가 그것과 같은지
% 본다. MSS 가 없으면 조용히 건너뛴다 — 볼트는 MSS 를 벤더링하지 않는다.
try
    mss_path();
catch
end
if exist('Rzyx', 'file') == 2
    Rm = Rzyx(ph*pi/180, th*pi/180, psi*pi/180);
    fprintf('vs MSS Rzyx           : max|dR| = %.3e\n', max(max(abs(M{4} - Rm))));
else
    fprintf('vs MSS Rzyx           : Rzyx.m not on the path, skipped\n');
end

% ---- TikZ 매크로 --------------------------------------------------------
fid = fopen(outfile, 'w');
c = onCleanup(@() fclose(fid));

fprintf(fid, '%% figures/src/w01-euler-R.tex — 손으로 고치지 않는다.\n');
fprintf(fid, '%%\n');
fprintf(fid, '%%   matlab -batch "addpath _tools; w01_euler_R"\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% psi = %g deg, theta = %g deg, phi = %g deg. zyx 순서,\n', psi, th, ph);
fprintf(fid, '%% Fossen (2021) Handbook 식 (2.18) R = Rz(psi) Ry(theta) Rx(phi).\n');
fprintf(fid, '%% 매크로 이름에 숫자를 쓰지 않는다 — TeX 제어어에는 숫자가 못 들어간다.\n\n');

for k = 1:4
    R = M{k};
    p = name{k};
    fprintf(fid, '%% ---- panel %s ----------------------------------------------------\n', p);
    fprintf(fid, '\\def\\P%sdeck{%s}\n', p, pathof(R*deck, true));
    fprintf(fid, '\\def\\P%saxX{%s}\n', p, coord(AXLEN*R(:,1)));
    fprintf(fid, '\\def\\P%saxY{%s}\n', p, coord(AXLEN*R(:,2)));
    fprintf(fid, '\\def\\P%saxZ{%s}\n', p, coord(AXLEN*R(:,3)));
    fprintf(fid, '\\def\\P%slabX{%s}\n', p, coord(LABD*R(:,1)));
    fprintf(fid, '\\def\\P%slabY{%s}\n', p, coord(LABD*R(:,2)));
    fprintf(fid, '\\def\\P%slabZ{%s}\n', p, coord(LABD*R(:,3)));

    a = act(k);
    if a > 0
        switch a
            case 3, u = R(:,1); w = R(:,2);     % z 둘레 : x -> y
            case 2, u = R(:,3); w = R(:,1);     % y 둘레 : z -> x
            case 1, u = R(:,2); w = R(:,3);     % x 둘레 : y -> z
        end
        % 호를 축 끝보다 얼마나 더 바깥에 둘지는 **화면 거리**로 정한다. 축마다
        % 사영된 길이가 다르기 때문이다: 칸 B 의 y_1 은 화면에서 x_1 의 절반밖에
        % 안 되어서, 3차원 거리를 똑같이 주면 호가 축 화살촉을 삼켜 버린다.
        %
        %   Ls    축 단위벡터의 화면 길이
        %   ext   호가 축 방향으로 화면에서 뻗는 최대 길이
        %
        % 호의 안쪽 가장자리가 축 끝보다 CLR 만큼 바깥에 오게 한다.
        CLR = 0.14;  GAP = 0.16;
        e   = R(:,a);
        Ls  = hypot(A1*e, A2*e);
        ext = ARCR/Ls * hypot((A1*u)*(A1*e) + (A2*u)*(A2*e), ...
                              (A1*w)*(A1*e) + (A2*w)*(A2*e));
        ARCD = AXLEN + (ext + CLR)/Ls;
        cen = ARCD * R(:,a);
        p0  = phase(k) * pi/180;
        t   = p0 + (40 + 300*(0:NARC)/NARC) * pi/180;
        arcp = cen + ARCR*(u*cos(t) + w*sin(t));
        fprintf(fid, '\\def\\P%sarc{%s}\n',    p, pathof(arcp, false));
        fprintf(fid, '\\def\\P%sarcc{%s}\n',   p, coord(cen));
        fprintf(fid, '\\def\\P%sarcstub{%s}\n',p, coord(AXLEN*R(:,a)));
        % 각 이름표는 호가 **열려 있는** 쪽, 곧 t = p0 방향에 둔다.
        fprintf(fid, '\\def\\P%sarclab{%s}\n', p, ...
                coord(cen + 1.90*ARCR*(u*cos(p0) + w*sin(p0))));
        % 도는 축의 이름표는 호 바깥으로 민다. 호 중심 거리에 두면 타원 안에 갇힌다.
        fprintf(fid, '\\def\\P%slabact{%s}\n', p, coord((ARCD + (ext+GAP)/Ls)*R(:,a)));
        fprintf(fid, ['%%   panel %s: axis projects to %.3f screen units; ' ...
                      'arc reach %.3f, centre at %.3f, label at %.3f\n'], ...
                p, Ls, ext, ARCD, ARCD + (ext+GAP)/Ls);
    end
    fprintf(fid, '\n');
end

fprintf('wrote %s\n', outfile);
end

% ------------------------------------------------------------------------
function s = coord(v)
s = sprintf('(%.4f,%.4f,%.4f)', v(1), v(2), v(3));
end

function s = pathof(P, closed)
parts = cell(1, size(P,2));
for i = 1:size(P,2)
    parts{i} = coord(P(:,i));
end
s = strjoin(parts, ' -- ');
if closed, s = [s ' -- cycle']; end
end

function R = Rz(a), a = a*pi/180;
R = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
end
function R = Ry(a), a = a*pi/180;
R = [cos(a) 0 sin(a); 0 1 0; -sin(a) 0 cos(a)];
end
function R = Rx(a), a = a*pi/180;
R = [1 0 0; 0 cos(a) -sin(a); 0 sin(a) cos(a)];
end
