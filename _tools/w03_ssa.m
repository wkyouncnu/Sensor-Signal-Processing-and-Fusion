function w03_ssa()
%W03_SSA  W03 §3-5 「the wrap」 그림의 기하를 계산해서 figures/src/w03-ssa.tex 를 낸다.
%
%      w03_ssa
%
%  CLAUDE.md §4 규칙 6-1·6-2: 각과 회전 방향을 눈대중으로 찍지 않는다.
%  여기서 전부 계산하고 assert 로 확인한 뒤에 .tex 를 쓴다.
%
%  화면 관례
%    나침반각(NED)은 북에서 시계방향이 양(+)이다.
%    화면각은 오른쪽이 0, 반시계가 양이다.
%    따라서  화면각 = 90 - 나침반각  이고,
%    **나침반에서 시계방향으로 도는 것은 화면에서도 시계방향**이다.
%    (나침반각이 커지면 화면각이 작아지므로.)
%
%  그래서 부호 규칙은 이렇게 굳는다.
%    psi 가 +  -> 우현(starboard)  -> 화면에서 시계방향
%    psi 가 -  -> 좌현(port)       -> 화면에서 반시계방향

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
out  = fullfile(root, 'figures', 'src', 'w03-ssa.tex');

%% ---- 예제의 두 각 -------------------------------------------------------
psi   =  170;      % 선박이 향하고 있는 방위 [deg]
psi_d = -170;      % 명령된 방위 [deg]

raw = psi_d - psi;                       % 순진한 뺄셈
ssa = atan2d(sind(raw), cosd(raw));      % 최소 부호각

assert(abs(raw   - (-340)) < 1e-9, '순진한 오차가 -340 이 아니다');
assert(abs(ssa   - ( +20)) < 1e-9, 'ssa 가 +20 이 아니다');
assert(abs(mod(raw - ssa, 360)) < 1e-9, 'raw 와 ssa 가 360 의 배수만큼 다르지 않다');

%  두 방위는 정말 20도 떨어져 있는가 — 단위벡터의 사잇각으로 독립 확인한다.
u1 = [cosd(psi)   sind(psi)];
u2 = [cosd(psi_d) sind(psi_d)];
sep = acosd(max(-1, min(1, dot(u1,u2))));
assert(abs(sep - 20) < 1e-9, '두 방위의 사잇각이 20 도가 아니다');

%% ---- 화면각 -------------------------------------------------------------
sP  = 90 - psi;         % =  -80   화면에서 아래·약간 오른쪽
sPd = 90 - psi_d;       % = +260 == -100   화면에서 아래·약간 왼쪽

assert(abs(sP  - (-80))  < 1e-9, 'psi 의 화면각이 틀렸다');
assert(abs(mod(sPd + 100, 360)) < 1e-9, 'psi_d 의 화면각이 틀렸다');

%  긴 호: raw = -340 이므로 좌현으로 340 도. 화면에서 반시계방향 +340 도.
%  TikZ 의 arc 는 화면각으로 도므로 시작 sP 에서 sP + 340 까지 그린다.
long_a =  sP;
long_b =  sP - raw;                      % -80 - (-340) = +260
assert(abs(mod(long_b - sPd, 360)) < 1e-9, '긴 호의 끝이 psi_d 가 아니다');
assert(long_b - long_a > 0, '긴 호가 반시계방향이 아니다');

%  짧은 호: ssa = +20 이므로 우현으로 20 도. 화면에서 시계방향 -20 도.
shrt_a =  sP;
shrt_b =  sP - ssa;                      % -80 - 20 = -100
assert(abs(mod(shrt_b - sPd, 360)) < 1e-9, '짧은 호의 끝이 psi_d 가 아니다');
assert(shrt_b - shrt_a < 0, '짧은 호가 시계방향이 아니다');

fprintf('\n  W03 3-5 the wrap — 기하 확인\n\n');
fprintf('    psi      = %+7.1f deg   (화면 %+7.1f)\n', psi,   sP);
fprintf('    psi_d    = %+7.1f deg   (화면 %+7.1f)\n', psi_d, sPd);
fprintf('    psi_d - psi          = %+7.1f deg   <- 그냥 빼면\n', raw);
fprintf('    ssa(psi_d - psi)     = %+7.1f deg   <- 최소 부호각\n', ssa);
fprintf('    두 방위의 실제 사잇각 = %7.1f deg   (독립 확인)\n', sep);
fprintf('    긴 호  화면 %+.0f -> %+.0f  (반시계, 좌현 %g deg)\n', long_a, long_b, -raw);
fprintf('    짧은 호 화면 %+.0f -> %+.0f  (시계,  우현 %g deg)\n', shrt_a, shrt_b, ssa);

%% ---- 오른쪽 패널: 톱니 ---------------------------------------------------
%  ssa 는 주기 360 의 톱니이고 180 의 홀수배에서 끊긴다.
%  구간마다 직선이므로 끝점 두 개씩만 있으면 된다.
seg = [-540 -180
       -180  180
        180  540];
S = cell(size(seg,1),1);
for i = 1:size(seg,1)
    a  = seg(i,:);
    b  = a - 360*round(a/360);           % 각 구간의 ssa (끝점은 열린 쪽으로)
    %  구간 내부 한 점으로 오프셋을 정한다 — 끝점은 불연속이라 못 쓴다
    mid  = mean(a);
    offs = atan2d(sind(mid), cosd(mid)) - mid;
    S{i} = [a; a + offs];
    assert(abs(offs - round(offs/360)*360) < 1e-9, '오프셋이 360 의 배수가 아니다');
end
%  예제 점이 가운데가 아닌 왼쪽 구간에 있는지 확인한다
assert(raw >= seg(1,1) && raw <= seg(1,2), '-340 이 왼쪽 구간에 있지 않다');

%% ---- .tex 쓰기 ----------------------------------------------------------
SC = 26;        % 나침반 반지름 [mm]
X0 = 88;        % 오른쪽 패널의 원점 x [mm]
XS = 0.055;     % 톱니 가로 축척 [mm per deg]
YS = 0.085;     % 톱니 세로 축척 [mm per deg]

f = fopen(out, 'w');
W = @(varargin) fprintf(f, varargin{:});

W('%% figures/w03-ssa.svg — 각의 뺄셈은 각이 아니다. ssa 가 무엇을 고치는가.\n');
W('%%\n');
W('%%   bash _tools/tikz2svg.sh figures/src/w03-ssa.tex figures/w03-ssa.svg\n');
W('%%\n');
W('%% 이 파일은 손으로 쓰지 않는다 — _tools/w03_ssa.m 이 계산해서 낸다.\n');
W('%% 그 스크립트가 각·호의 방향·톱니 구간을 전부 assert 로 확인한 뒤에 쓴다.\n');
W('%%\n');
W('%% 회전 방향의 근거 (CLAUDE.md 4 규칙 6-2):\n');
W('%%   화면각 = 90 - 나침반각 이므로 나침반각이 커지면 화면각이 작아진다.\n');
W('%%   따라서 psi 가 커지는 것(우현)은 화면에서 시계방향이다.\n');
W('%%   raw = %+g -> 좌현이므로 화면 반시계, ssa = %+g -> 우현이므로 화면 시계.\n', raw, ssa);
W('\\documentclass[border=5pt]{standalone}\n');
W('\\input{gnc-style}\n\n');
W('\\begin{document}\n');
W('\\begin{tikzpicture}[x=1mm, y=1mm]\n\n');

%  ---- 제목
W('\\node[font=\\small\\bfseries, anchor=north west] at (-34,56)\n');
W('     {Two headings $%g^\\circ$ apart, and the error that says $%g^\\circ$};\n', sep, raw);
W('\\node[anchor=north west, align=left, text width=150mm, font=\\scriptsize, soft] at (-34,50) {%%\n');
W('  Subtracting one angle from another is arithmetic, not geometry. The answer is\n');
W('  right as a number and wrong as an error, and the vessel turns the long way round.};\n\n');

%  ---- 왼쪽: 나침반
W('%% ================= 왼쪽 — 나침반 =================\n');
%  두 방위 사이의 쐐기를 먼저 칠한다 — 20 도가 얼마나 좁은지를 이것이 말한다.
W('%% 두 방위 사이의 쐐기. 화면 %+.0f 에서 %+.0f 까지 (시계방향 %g deg)\n', sP, sP-ssa, ssa);
W('\\fill[accent, opacity=0.13] (0,0) -- (%.2f:%.2f) arc (%.2f:%.2f:%.2f) -- cycle;\n', ...
  sP, SC, sP, sP-ssa, SC);
W('\\draw[soft, line width=0.4pt] (0,0) circle (%.2f);\n', SC);
W('\\draw[axis, -{Stealth[length=4.5pt,width=3.4pt]}] (0,0) -- (0,%.2f);\n', SC+6);
W('\\node[font=\\scriptsize, anchor=south] at (0,%.2f) {$x^n$~(North)};\n', SC+6.4);
for k = 0:3
    ang = 90 - 90*k;
    lbl = {'N','E','S','W'};
    %  S 는 글자를 넣지 않는다. 두 방위가 모두 남쪽을 향하고 있어서 그 자리에
    %  psi 와 psi_d 라벨이 이미 있고, 셋이 겹친다. 눈금만 남긴다.
    if k > 0 && k ~= 2
        W('\\node[tick] at (%.2f,%.2f) {%s};\n', (SC+4.2)*cosd(ang), (SC+4.2)*sind(ang), lbl{k+1});
    end
    W('\\draw[soft, line width=0.4pt] (%.2f,%.2f) -- (%.2f,%.2f);\n', ...
      SC*cosd(ang), SC*sind(ang), (SC+1.8)*cosd(ang), (SC+1.8)*sind(ang));
end

%  긴 호 — 회색, 안쪽
RL = SC*0.62;
W('\n%% 긴 호: 화면 %+.0f -> %+.0f, 반시계 (좌현 %g deg)\n', long_a, long_b, -raw);
W('\\draw[soft, line width=1.5pt, -{Stealth[length=5pt,width=3.8pt]}]\n');
W('      (%.2f:%.2f) arc (%.2f:%.2f:%.2f);\n', long_a, RL, long_a, long_b, RL);
%  라벨은 북쪽 축선 왼쪽에서 끝나야 한다 — anchor=east 로 축을 넘지 않게 한다.
W('\\node[note, anchor=east, align=right] at (%.2f,%.2f)\n', -3.0, SC*0.62);
W('     {$\\psi_d-\\psi = %g^\\circ$,\\\\ the long way};\n', raw);

%  짧은 호 — accent, 바깥쪽
RS = SC*0.90;
W('\n%% 짧은 호: 화면 %+.0f -> %+.0f, 시계 (우현 %g deg)\n', shrt_a, shrt_b, ssa);
W('\\draw[accent, line width=1.6pt, -{Stealth[length=5pt,width=3.8pt]}]\n');
W('      (%.2f:%.2f) arc (%.2f:%.2f:%.2f);\n', shrt_a, RS, shrt_a, shrt_b, RS);

%  두 방위 화살표. 둘 다 거의 남쪽을 향하므로 라벨은 원 밖으로 충분히 뺀다.
W('\n%% 두 방위\n');
W('\\draw[ink, line width=1.0pt, -{Stealth[length=5pt,width=3.6pt]}]\n');
W('      (0,0) -- (%.2f:%.2f);\n', sP, SC);
W('\\node[ink, font=\\scriptsize, anchor=west] at (%.2f:%.2f)\n', sP, SC+3.0);
W('     {$\\psi = %+g^\\circ$};\n', psi);
W('\\draw[ink, line width=1.0pt, densely dashed, -{Stealth[length=5pt,width=3.6pt]}]\n');
W('      (0,0) -- (%.2f:%.2f);\n', sPd, SC);
W('\\node[ink, font=\\scriptsize, anchor=east] at (%.2f:%.2f)\n', sPd, SC+3.0);
W('     {$\\psi_d = %+g^\\circ$};\n', psi_d);

%  ssa 캡션은 나침반 아래, 라벨 두 개보다 더 아래에 둔다.
W('\\node[anote, anchor=north, align=center, text width=62mm] at (0,%.2f)\n', -SC-9.5);
W('     {$\\mathrm{ssa}(%g^\\circ) = %+g^\\circ$ — the short way,\\\\ and the shaded wedge is how wide $%g^\\circ$ really is};\n', ...
  raw, ssa, ssa);

%  ---- 오른쪽: 톱니
W('\n%% ================= 오른쪽 — ssa 는 톱니다 =================\n');
xw = 540*XS;  yw = 180*YS;
W('\\draw[axis, -{Stealth[length=4pt,width=3pt]}] (%.2f,0) -- (%.2f,0);\n', X0-xw-3, X0+xw+5);
W('\\draw[axis, -{Stealth[length=4pt,width=3pt]}] (%.2f,%.2f) -- (%.2f,%.2f);\n', X0, -yw-4, X0, yw+5);
W('\\node[font=\\scriptsize, anchor=west]  at (%.2f,0) {$a$};\n', X0+xw+6);
W('\\node[font=\\scriptsize, anchor=south] at (%.2f,%.2f) {$\\mathrm{ssa}(a)$};\n', X0, yw+5.5);
for v = [-360 -180 180 360]
    W('\\draw[soft, line width=0.4pt] (%.2f,-1.2) -- (%.2f,1.2);\n', X0+v*XS, X0+v*XS);
    W('\\node[tick, anchor=north] at (%.2f,-1.6) {$%g$};\n', X0+v*XS, v);
end
for v = [-180 180]
    W('\\draw[soft, line width=0.4pt] (%.2f,%.2f) -- (%.2f,%.2f);\n', X0-1.2, v*YS, X0+1.2, v*YS);
    W('\\node[tick, anchor=east] at (%.2f,%.2f) {$%g$};\n', X0-1.8, v*YS, v);
end
%  세 구간
for i = 1:numel(S)
    a = S{i}(1,:);  b = S{i}(2,:);
    W('\\draw[ink, line width=0.9pt] (%.2f,%.2f) -- (%.2f,%.2f);\n', ...
      X0+a(1)*XS, b(1)*YS, X0+a(2)*XS, b(2)*YS);
end
%  가운데 구간은 항등이라는 것을 밝힌다
%  「가운데 선분에서는 항등」이라는 말은 그림 안에 두지 않는다 — 어디에 놓아도
%  선분이나 눈금 글자와 부딪힌다. 아래 캡션으로 내린다.
%  예제 점
W('\n%% 예제:  a = %g  ->  %g\n', raw, ssa);
W('\\draw[accent, line width=0.5pt, densely dashed] (%.2f,%.2f) -- (%.2f,%.2f) -- (%.2f,%.2f);\n', ...
  X0+raw*XS, 0, X0+raw*XS, ssa*YS, X0, ssa*YS);
W('\\fill[accent] (%.2f,%.2f) circle (0.9);\n', X0+raw*XS, ssa*YS);
W('\\node[anote, anchor=south west] at (%.2f,%.2f) {$%g \\mapsto %+g$};\n', ...
  X0+raw*XS+1.2, ssa*YS+0.6, raw, ssa);
W('\\node[note, anchor=north, text width=52mm, align=center] at (%.2f,%.2f)\n', X0, -yw-6);
W('     {Every value is mapped into $(-180^\\circ,\\,180^\\circ]$, and on the\n');
W('      middle segment $\\mathrm{ssa}(a)=a$ leaves it alone. The jumps sit at\n');
W('      $\\pm180^\\circ$, which is why the \\emph{error} is wrapped, never the heading.};\n');

W('\n\\end{tikzpicture}\n');
W('\\end{document}\n');
fclose(f);

fprintf('\n  -> %s\n\n', out);
end
