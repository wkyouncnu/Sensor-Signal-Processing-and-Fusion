%W12_H_WEIGHTS  강의 §12-9 — 가중행렬 W 는 값표다. 무엇이 바뀌고 **무엇은
%  바뀌지 않는가**를 쓸어서 잰다. 표 둘과 그림 하나.
%
%  여기서 재서 알게 된 것(강의에 그대로 들어간다):
%    B 의 둘째 줄이 [0 1 0 1 0 -1 0 -1] 이므로 **Y 는 f_y 열만이 낸다.**
%    따라서 sum|f_y| 는 요구가 정한 값에 묶여 있고, f_y 를 비싸게 매겨도
%    줄지 않는다. 값표가 바꾸는 것은 **누가 내는가**와 **어느 팔로 내는가**다.
%    y 축 성분을 비싸게 하면 N 을 긴 팔(1.5/1.0 m)에서 짧은 팔(0.395 m)로
%    옮기게 되어 f_x 가 한쪽으로 쏠리고, 그래서 최대 각이 오히려 **커진다.**

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'_tools'));  mss_path();
cfg = otter_config('quad_tilt');
B   = cfg.B;

tau_d = [80; 30; 20];
wlist = [1 3 10 30 100 300 1000];

fprintf('\n=== §12-9  가중행렬 W ===\n');
fprintf('요구 tau_d = [%.0f N, %.0f N, %.0f Nm],  W = diag([1 w 1 w 1 w 1 w])\n', tau_d);
fprintf('Y 는 f_y 열만이 낸다 (B 둘째 줄 = [%s]) -> sum|f_y| 는 묶여 있다\n\n', ...
        strtrim(sprintf('%g ', B(2,:))));
fprintf('       w   sum|f_y| [N]   f_x spread [N]   max|delta| [deg]   ||f|| [N]   ||B f - tau||\n');

md = zeros(size(wlist));  nf = md;  sf = md;  sp = md;
for j = 1:numel(wlist)
    P.W = diag(repmat([1 wlist(j)], 1, 4));
    f   = W12_alloc(B, tau_d, 'wpinv', P);
    H   = W12_hw(B, f, cfg);
    fx  = f(1:2:end);  fy = f(2:2:end);
    md(j) = max(abs(rad2deg(H.delta)));
    nf(j) = norm(f);
    sf(j) = sum(abs(fy));
    sp(j) = max(abs(fx)) - min(abs(fx));      % f_x 가 얼마나 쏠렸는가
    fprintf('  %6g %13.2f %16.2f %18.2f %12.2f %15.1e\n', ...
            wlist(j), sf(j), sp(j), md(j), nf(j), norm(B*f - tau_d));
end

%% W 를 통째로 키워도 해가 그대로인가 — 비율만이 뜻을 가진다
f_a = W12_alloc(B, tau_d, 'wpinv', struct('W', diag(repmat([1 10],1,4))));
f_b = W12_alloc(B, tau_d, 'wpinv', struct('W', 1000*diag(repmat([1 10],1,4))));
fprintf('\nW 와 1000*W 의 해 차이 : %.2e N   (비율만이 뜻을 가진다)\n', ...
        norm(f_a - f_b));

%% 값표가 **실제로** 할 수 있는 것 — 어느 추진기가 몫을 지는가
P2.W = diag([1 10 1 10 5 50 5 50]);          % 뒤 두 대를 5배 비싸게
f2   = W12_alloc(B, tau_d, 'wpinv', P2);
H2   = W12_hw(B, f2, cfg);
H1   = W12_hw(B, f_a, cfg);
shr1 = 100*sum(abs(H1.T(3:4)))/sum(abs(H1.T));
shr2 = 100*sum(abs(H2.T(3:4)))/sum(abs(H2.T));
fprintf('\n값표가 바꿀 수 있는 것 — 몫의 배분\n');
fprintf('  앞뒤 같은 값   : |T| = [%6.2f %6.2f %6.2f %6.2f] N   뒤 두 대 몫 %.1f %%\n', ...
        abs(H1.T), shr1);
fprintf('  뒤를 5배 비싸게: |T| = [%6.2f %6.2f %6.2f %6.2f] N   뒤 두 대 몫 %.1f %%\n', ...
        abs(H2.T), shr2);
fprintf('\n값표가 바꿀 수 없는 것 — 요구가 정한 것\n');
fprintf('  sum|f_y| : %.2f N 과 %.2f N  (Y = %.0f N 이 정한다)\n', ...
        sum(abs(f_a(2:2:end))), sum(abs(f2(2:2:end))), tau_d(2));

%% 그림 — 왼쪽: 값표로 각을 줄일 수 없다. 오른쪽: 값표가 할 수 있는 것
W12_plot_weights(cfg, wlist, sf, sp, md, H1, H2, shr1, shr2, ...
                 fileparts(mfilename('fullpath')));
