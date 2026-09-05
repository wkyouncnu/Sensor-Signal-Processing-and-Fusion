function ok = verify_alos(verbose)
%VERIFY_ALOS  강의 4-9 의 ALOS 유도를 MSS 의 ALOSpsi.m 과 한 스텝씩 대조한다.
%
%   ok = verify_alos()        % 조용히, 통과하면 true
%   ok = verify_alos(true)    % 표를 찍는다
%
%   이 볼트가 벤더링한 MSS 는 2021 릴리스라 ALOSpsi.m 이 없다. ALOS 는 2023 에
%   들어갔다. 그래서 강의 4-9 는 법칙을 **직접 유도**했고, 이 함수가 그 유도를
%   최신 MSS 구현과 대조한다 — 찾을 수 있을 때만.
%
%   Fossen 의 원 문헌:
%     T. I. Fossen (2023). An Adaptive Line-of-sight (ALOS) Guidance Law for
%     Path Following of Aircraft and Marine Craft. IEEE Transactions on
%     Control Systems Technology 31(6), 2887-2894.
%     https://doi.org/10.1109/TCST.2023.3259819
%
%   2026-09-05 결과: 400 스텝에서 psi_d 와 y_e 모두 차이 **정확히 0**.
%
%   See also VERIFY_GUIDANCE.

if nargin < 1, verbose = false; end
ok = true;

%% ---- 최신 MSS 의 ALOSpsi.m 을 찾는다 -----------------------------------
%  벤더링본이 아니라 디스크의 다른 사본을 쓴다. 못 찾으면 건너뛴다 —
%  검증을 못 했다는 사실은 알리되, 빌드를 세우지는 않는다.
cand = { ...
  'C:\Users\admin\Dropbox\선형제어시스템\MATLAB_source\Examples\[2025] MSS\GNC'
  'C:\Users\admin\Dropbox\선형제어시스템\MATLAB_source\Examples\[2025] PX4 HILS\Otter_linear_v12_renew_system\MSS\GNC'};
gnc = '';
for i = 1:numel(cand)
    if isfile(fullfile(cand{i}, 'ALOSpsi.m')), gnc = cand{i}; break, end
end
if isempty(gnc)
    warning('verify_alos:notFound', ...
        ['ALOSpsi.m 을 찾지 못해 대조를 건너뜁니다. ' ...
         '강의 4-9 의 유도는 수치 수렴으로만 검증된 상태입니다.']);
    ok = false;  return
end
oldp = path;  cleanup = onCleanup(@() path(oldp));
addpath(gnc);

%% ---- W04 의 미션과 게인 -------------------------------------------------
Delta = 8; gamma = 0.005; h = 0.02; R = 5;
wpt.pos.x = [0 60 60  0 60]';
wpt.pos.y = [0  0 60 60 120]';

clear ALOSpsi
st = struct('k',1,'b',0);
x = 0; y = 0; psi = 0; U = 1.31; N = 400;
dpsi = 0; dye = 0;

for i = 1:N
    [psi_mss, ye_mss] = ALOSpsi(x, y, Delta, gamma, h, R, wpt);
    [psi_mine, ye_mine, st] = alos_lecture(x, y, Delta, gamma, h, R, wpt, st);

    dpsi = max(dpsi, abs(atan2(sin(psi_mss-psi_mine), cos(psi_mss-psi_mine))));
    dye  = max(dye,  abs(ye_mss - ye_mine));

    %  같은 궤적을 두 법칙에 먹이기 위한 아주 단순한 운동
    psi = psi + 3.5*atan2(sin(psi_mss-psi), cos(psi_mss-psi))*h;
    x = x + h*U*cos(psi);  y = y + h*U*sin(psi);
end

ok = (dpsi < 1e-12) && (dye < 1e-12);

if verbose
    fprintf('\n  ALOS — 강의 4-9 의 유도 대 MSS ALOSpsi.m\n');
    fprintf('    출처            %s\n', gnc);
    fprintf('    대조한 스텝     %d\n', N);
    fprintf('    max |dpsi_d|    %.3e rad\n', dpsi);
    fprintf('    max |dy_e|      %.3e m\n', dye);
    if ok
        fprintf('    -> 기계 정밀도까지 동일. 유도가 공식 구현과 같다.\n\n');
    else
        fprintf('    -> 다르다. 강의 4-9 를 다시 본다.\n\n');
    end
end
end

% =========================================================================
function [psi_d, y_e, st] = alos_lecture(x, y, Delta, gamma, h, R, wpt, st)
%ALOS_LECTURE  강의 4-9-2 에 실린 식 그대로. MSS 코드를 보지 않고 쓴 것이다.
%
%   psi_d      = pi_p - b_hat - atan(y_e/Delta)
%   b_hat(k+1) = b_hat + h*gamma*Delta*y_e/sqrt(Delta^2 + y_e^2)
n = numel(wpt.pos.x);
if st.k < n
    Xn = wpt.pos.x(st.k+1);  Yn = wpt.pos.y(st.k+1);
else
    %  마지막 다리는 방위각으로 연장한다 — MSS 2023+ 과 같은 처리이고,
    %  2021 판이 마지막 웨이포인트를 양끝으로 두어 pi_p = atan2(0,0) = 0 이
    %  되던 것을 고친 것이다 (강의 4-6).
    br = atan2(wpt.pos.y(n)-wpt.pos.y(n-1), wpt.pos.x(n)-wpt.pos.x(n-1));
    Xn = wpt.pos.x(n) + 1e10*cos(br);  Yn = wpt.pos.y(n) + 1e10*sin(br);
end
Xk = wpt.pos.x(st.k);  Yk = wpt.pos.y(st.k);

pi_p = atan2(Yn-Yk, Xn-Xk);
x_e  =  (x-Xk)*cos(pi_p) + (y-Yk)*sin(pi_p);
y_e  = -(x-Xk)*sin(pi_p) + (y-Yk)*cos(pi_p);

d = sqrt((Xn-Xk)^2 + (Yn-Yk)^2);
if (d - x_e < R) && (st.k < n), st.k = st.k + 1; end

psi_d = pi_p - st.b - atan(y_e/Delta);
st.b  = st.b + h*gamma*Delta*y_e/sqrt(Delta^2 + y_e^2);
end
