function w03_second_order()
%W03_SECOND_ORDER  W03 §3-3 「2차 표준형이 zeta 와 wn 에 따라 어떻게 바뀌는가」.
%
%      w03_second_order
%
%  figures/src/w03-second-order.tex 를 낸다.
%
%  왜 시간영역 두 판인가.
%    사용자가 W02 의 극-영점 지도를 보고 **"너무 어려워"** 라고 했다 (2026-09-08).
%    극점 배치의 내용은 「zeta 가 모양을, wn 이 속도를 정한다」 하나이고, 그것은
%    s-평면 없이 계단응답 두 다발로 그대로 보인다. 극점 공식은 본문에 글로 적고
%    그림은 시간영역으로 둔다.
%
%  검증 (CLAUDE.md §4 규칙 10)
%    계산한 곡선의 오버슛을 exp(-pi zeta / sqrt(1-zeta^2)) 와 대조한다.
%    영점이 없는 표준형이므로 이 공식이 정확히 맞아야 한다 — W02 와 다른 점이고,
%    그 대조가 여기서 공식을 쓸 자격을 준다.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
out  = fullfile(root, 'figures', 'src', 'w03-second-order.tex');

%% ---- 이 강의의 설계점 --------------------------------------------------
WN_D = 1.5312;      % rad/s  — W03 이 고른 값
ZE_D = 0.9;

ZS = [0.3 0.5 0.7 0.9 1.5];         % 왼쪽 판: zeta 를 훑는다 (wn 고정)
WS = [0.75 1.5312 3.0];             % 오른쪽 판: wn 을 훑는다 (zeta 고정)

T  = 12;  N = 240;  t = linspace(0, T, N);

fprintf('\n  W03 3-3 — 2차 표준형, 계단응답\n\n');
fprintf('    wn = %.4f rad/s 고정, zeta 를 훑는다\n\n', WN_D);
fprintf('    %8s %14s %14s %12s\n', 'zeta', '오버슛 계산', '오버슛 공식', '극점');
fprintf('    %s\n', repmat('-', 1, 60));

YZ = zeros(numel(ZS), N);
for i = 1:numel(ZS)
    z = ZS(i);
    YZ(i,:) = so_step(t, WN_D, z);
    Mp_num  = 100*(max(YZ(i,:)) - 1);
    if z < 1
        Mp_f = 100*exp(-pi*z/sqrt(1 - z^2));
        p    = sprintf('%.2f+-%.2fj', -z*WN_D, WN_D*sqrt(1-z^2));
        %  영점이 없으므로 공식과 수치가 맞아야 한다. 0.15 점 이내.
        assert(abs(Mp_num - Mp_f) < 0.15, ...
               'zeta = %g 에서 오버슛이 공식과 다르다 (%.3f vs %.3f)', z, Mp_num, Mp_f);
    else
        Mp_f = 0;
        r    = WN_D*(-z + [1 -1]*sqrt(z^2-1));
        p    = sprintf('%.2f, %.2f', r(1), r(2));
        assert(Mp_num < 0.05, 'zeta >= 1 인데 오버슛이 있다 (%.3f %%)', Mp_num);
    end
    fprintf('    %8.2f %13.2f%% %13.2f%%   %12s\n', z, Mp_num, Mp_f, p);
end

fprintf('\n    zeta = %.2f 고정, wn 을 훑는다\n\n', ZE_D);
fprintf('    %8s %14s %16s\n', 'wn', '오버슛 계산', '2%% 정착 [s]');
fprintf('    %s\n', repmat('-', 1, 44));
YW = zeros(numel(WS), N);
tsv = zeros(1, numel(WS));
for i = 1:numel(WS)
    YW(i,:) = so_step(t, WS(i), ZE_D);
    Mp_num  = 100*(max(YW(i,:)) - 1);
    k       = find(abs(YW(i,:) - 1) > 0.02, 1, 'last');
    tsv(i)  = t(min(k+1, N));
    fprintf('    %8.4f %13.2f%% %15.2f\n', WS(i), Mp_num, tsv(i));
end

%  모양이 정말 같은가 — wn 을 바꾼 셋은 시간축을 wn 배로 늘리면 겹쳐야 한다.
%  이것이 「wn 은 속도만 정한다」 의 수치적 진술이다.
mp = arrayfun(@(i) max(YW(i,:)), 1:numel(WS));
assert(max(mp) - min(mp) < 5e-3, ...
       'wn 을 바꿨는데 오버슛이 달라졌다 — 모양이 같다는 주장이 깨진다');
fprintf(['\n    세 곡선의 오버슛이 %.3f %% 안에서 같다 -> wn 은 모양을 바꾸지 않는다.\n' ...
         '    정착시간은 %.2f, %.2f, %.2f s 로 wn 에 반비례한다 (%.2f : %.2f).\n'], ...
        100*(max(mp)-min(mp)), tsv, tsv(1)/tsv(3), WS(3)/WS(1));

%% ---- .tex --------------------------------------------------------------
XS = 7.0;    % mm per second
YS = 19.0;   % mm per unit — 1.75 단위가 33mm. 이보다 크면 축 꼭대기가 제목을 친다.
X0 = 0;  XB = 104;

f = fopen(out, 'w');
W = @(varargin) fprintf(f, varargin{:});

W('%% figures/w03-second-order.svg — zeta 는 모양을, wn 은 속도를 정한다.\n');
W('%%\n');
W('%%   bash _tools/tikz2svg.sh figures/src/w03-second-order.tex figures/w03-second-order.svg\n');
W('%%\n');
W('%% 손으로 쓰지 않는다 — _tools/w03_second_order.m 이 계산해서 낸다.\n');
W('%% 그 스크립트가 오버슛을 exp(-pi z/sqrt(1-z^2)) 와 대조하고 통과해야 쓴다.\n');
W('%% s-평면 그림을 두지 않은 이유는 그 스크립트 머리말에 있다.\n');
W('\\documentclass[border=5pt]{standalone}\n');
W('\\input{gnc-style}\n\n');
W('\\begin{document}\n');
W('\\begin{tikzpicture}[x=1mm, y=1mm]\n\n');

W('\\node[font=\\small\\bfseries, anchor=north west] at (-14,62)\n');
W('     {The two numbers that describe a second-order loop};\n');
W('\\node[anchor=north west, align=left, text width=176mm, font=\\scriptsize, soft] at (-14,56) {%%\n');
W('  Choosing $K_p$ and $K_d$ is the same act as choosing these two. $\\zeta$ decides\n');
W('  what the response \\emph{looks like}; $\\omega_n$ decides only how \\emph{fast} it is.};\n\n');

%  ---- 왼쪽 판: zeta
W('%% ================= (a) zeta 를 훑는다 =================\n');
W('\\node[font=\\small\\bfseries, anchor=west] at (%.1f,46) {(a)\\quad $\\zeta$ changes the shape};\n', X0-6);
W('\\node[note, anchor=west, text width=84mm] at (%.1f,41.5)\n', X0-6);
W('     {$\\omega_n = %.2f$ rad/s throughout. Only the overshoot changes.};\n', WN_D);
axes_box(W, X0, T, XS, YS, tsv);
for i = 1:numel(ZS)
    if abs(ZS(i)-ZE_D) < 1e-9, sty = 'accent, line width=1.3pt';
    else,                      sty = 'ink, line width=0.7pt';  end
    curve(W, X0, t, YZ(i,:), XS, YS, sty);
    %  이름표 자리. 첫 봉우리는 zeta 가 큰 셋(0.9, 1.5)에서 서로 0.15 % 안으로
    %  붙어 버리므로 봉우리에 붙이면 겹친다. 진동하는 셋은 봉우리 오른쪽에,
    %  거의 진동하지 않는 둘은 곡선이 확실히 갈라져 있는 상승부 아래쪽에 붙인다.
    if ZS(i) < 0.8
        [~, im] = max(YZ(i,:));
        lx = X0 + t(im)*XS + 1.5;   ly = YZ(i,im)*YS;
        anc = 'west';
    elseif ZS(i) < 1.0
        %  설계점. 곡선 아래, 왼쪽으로 뻗게 해서 zeta = 1.5 이름표와 갈라 놓는다.
        im = find(t >= 2.4, 1);
        lx = X0 + t(im)*XS;         ly = YZ(i,im)*YS - 2.4;
        anc = 'north east';
    else
        im = find(t >= 4.6, 1);
        lx = X0 + t(im)*XS;         ly = YZ(i,im)*YS - 2.4;
        anc = 'north west';
    end
    if abs(ZS(i)-ZE_D) < 1e-9
        W('\\node[anote, anchor=%s] at (%.2f,%.2f) {$\\zeta=%.1f$, this course};\n', ...
          anc, lx, ly, ZS(i));
    else
        W('\\node[note, anchor=%s] at (%.2f,%.2f) {$\\zeta=%.1f$};\n', anc, lx, ly, ZS(i));
    end
end

%  ---- 오른쪽 판: wn
W('\n%% ================= (b) wn 을 훑는다 =================\n');
W('\\node[font=\\small\\bfseries, anchor=west] at (%.1f,46) {(b)\\quad $\\omega_n$ changes only the clock};\n', XB-6);
W('\\node[note, anchor=west, text width=84mm] at (%.1f,33.5)\n', XB-6);
W('     {$\\zeta = %.1f$ throughout. All three overshoot by the same $%.1f\\%%$.};\n', ...
  ZE_D, 100*(mean(mp)-1));
axes_box(W, XB, T, XS, YS, tsv);
for i = 1:numel(WS)
    if abs(WS(i)-WN_D) < 1e-9, sty = 'accent, line width=1.3pt';
    else,                      sty = 'ink, line width=0.7pt';  end
    curve(W, XB, t, YW(i,:), XS, YS, sty);
    %  세 곡선은 모양이 같고 시간축만 다르다. y = 0.9 를 지나는 시각은 wn 에
    %  반비례해 잘 벌어지지만(약 3.2, 1.6, 0.8 s) 이름표 폭이 그 간격보다 넓어
    %  가로로만 놓으면 겹친다. 그래서 세로로도 층을 준다 — 느린 것이 위.
    ih = find(YW(i,:) >= 0.9, 1);
    lx = XB + t(ih)*XS;
    ly = (1.12 + 0.20*(numel(WS) - i))*YS;   % 맨 위가 28.9mm, 부제(41.5)와 12mm 뜬다
    W('\\draw[soft, line width=0.35pt] (%.2f,%.2f) -- (%.2f,%.2f);\n', ...
      lx, ly - 0.9, lx, 0.93*YS);
    if abs(WS(i)-WN_D) < 1e-9
        W('\\node[anote, anchor=south west] at (%.2f,%.2f) {$\\omega_n=%.2f$, this course};\n', ...
          lx - 1.0, ly, WS(i));
    else
        W('\\node[note, anchor=south west] at (%.2f,%.2f) {$\\omega_n=%.2f$};\n', lx - 1.0, ly, WS(i));
    end
end

W('\n\\end{tikzpicture}\n\\end{document}\n');
fclose(f);
fprintf('\n  -> %s\n\n', out);
end

% =========================================================================
function y = so_step(t, wn, z)
%SO_STEP  wn^2/(s^2 + 2 z wn s + wn^2) 의 단위계단응답. 닫힌 해를 쓴다.
if z < 1
    wd = wn*sqrt(1 - z^2);
    y  = 1 - exp(-z*wn*t).*(cos(wd*t) + (z*wn/wd)*sin(wd*t));
elseif abs(z - 1) < 1e-12
    y  = 1 - exp(-wn*t).*(1 + wn*t);
else
    r1 = wn*(-z + sqrt(z^2-1));  r2 = wn*(-z - sqrt(z^2-1));
    y  = 1 + (r2*exp(r1*t) - r1*exp(r2*t))/(r1 - r2);
end
end

function axes_box(W, X, T, XS, YS, ~)
W('\\draw[axis, -{Stealth[length=4pt,width=3pt]}] (%.2f,0) -- (%.2f,0);\n', X, X+T*XS+5);
W('\\draw[axis, -{Stealth[length=4pt,width=3pt]}] (%.2f,0) -- (%.2f,%.2f);\n', X, X, 1.75*YS);
W('\\node[font=\\scriptsize, anchor=west]  at (%.2f,0) {time [s]};\n', X+T*XS+6);
W('\\node[font=\\scriptsize, anchor=south] at (%.2f,%.2f) {$\\psi/\\psi_d$};\n', X, 1.75*YS+1);
W('\\draw[soft, line width=0.4pt, densely dotted] (%.2f,%.2f) -- (%.2f,%.2f);\n', ...
  X, YS, X+T*XS, YS);
W('\\node[tick, anchor=east] at (%.2f,%.2f) {$1$};\n', X-1.2, YS);
for s = 0:4:T
    W('\\draw[soft, line width=0.4pt] (%.2f,-1.0) -- (%.2f,1.0);\n', X+s*XS, X+s*XS);
    W('\\node[tick, anchor=north] at (%.2f,-1.4) {$%g$};\n', X+s*XS, s);
end
end

function curve(W, X, t, y, XS, YS, sty)
W('\\draw[%s] ', sty);
for k = 1:numel(t)
    if k > 1, W(' -- '); end
    W('(%.2f,%.2f)', X + t(k)*XS, y(k)*YS);
    if mod(k, 8) == 0, W('\n      '); end
end
W(';\n');
end
