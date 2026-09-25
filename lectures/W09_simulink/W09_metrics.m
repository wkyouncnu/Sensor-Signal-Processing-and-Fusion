function M = W09_metrics(R)
%W09_METRICS  한 번의 임무를 여덟 개의 수로 줄인다 / one mission, reduced to eight numbers.
%
%   M = W09_metrics(W09_read('W09_C_full'))
%
%   이 주차의 모든 절이 **같은 정의**로 잰다. 절마다 다르게 재면 표를 나란히
%   놓을 수 없고, 그러면 §9-3 의 물음("이 주차가 무엇을 벌었나")에 답할 수 없다.
%   Every section of this week measures with these definitions. Measured any
%   other way the tables could not be put side by side, and §9-3 could not ask
%   what each week bought.
%
%   M.T      임무 시간 [s] — 끝(모드 3)에 이른 시각. 끝내지 못하면 NaN
%   M.u      이동 속도 [m/s] — 각 다리의 앞 15 s 를 뺀 평균
%   M.ye     다리 끝 횡방향 오차 [m] — 각 다리 마지막 10 s 의 |y_e| 평균
%   M.r      요 각속도 RMS [deg/s] — 같은 구간
%   M.Nerr   내지 못한 모멘트 [N m] — 명령한 N 과 두 추진기가 실제로 만든 것의 최대 차
%   M.Nhf    유지 중 모멘트의 빠른 성분 [N m] — 4 s 이동평균을 뺀 나머지의 표준편차
%   M.hold   유지 오차 [m] — 각 유지의 마지막 20 s 평균
%   M.tset   유지 정착 시간 [s] — 오차가 1 m 안에 들어와 머무르기까지
%   M.legs   끝낸 다리 수 / how many legs were completed

V = R.V;  h = V.h;  m1 = R.mode == 1;  m2 = R.mode == 2;
j = find(R.mode == 3, 1);
if isempty(j), M.T = NaN; else, M.T = R.t(j); end

%  요 각속도는 로그의 선수각에서 만든다 (이음매를 건너도 안전하게)
r = [0; diff(R.psi)/h];  r = atan2d(sind(r*h), cosd(r*h))/h;

%  명령한 모멘트와 두 추진기가 실제로 만든 모멘트 (6주차의 배분을 그대로 다시 푼다)
T1 = R.X/2 + R.Nm/(2*V.y_pont);   T2 = R.X/2 - R.Nm/(2*V.y_pont);
if V.use_scale ~= 0
    s = min(min(min(ones(size(T1)), min(1, V.T_max./max(T1,eps))), min(1, V.T_max./max(T2,eps))), ...
            min(min(1, V.T_min./min(T1,-eps)), min(1, V.T_min./min(T2,-eps))));
    U1 = s.*T1;  U2 = s.*T2;
else
    U1 = min(max(T1, V.T_min), V.T_max);   U2 = min(max(T2, V.T_min), V.T_max);
end
M.Nerr = max(abs((U1 - U2)*V.y_pont - R.Nm));

keep = false(size(m1));  ur = [];  ye = [];  hd = [];  ts = [];
for k = 1:numel(V.WP_N)
    a = (R.wp == k) & m1;  t = R.t(a);
    if ~isempty(t)
        q = a & R.t >= t(1) + 15;   keep = keep | q;   ur(end+1) = mean(R.u(q));   %#ok<AGROW>
        q = a & R.t >= t(end) - 10;  ye(end+1) = mean(abs(R.y_e(q)));              %#ok<AGROW>
    end
    b = (R.wp == k) & m2;  t = R.t(b);
    if ~isempty(t)
        q = b & R.t >= t(end) - 20;  hd(end+1) = mean(R.e(q));                     %#ok<AGROW>
        e = R.e(b);  i1 = find(e > 1, 1, 'last');
        if isempty(i1), ts(end+1) = 0; else, ts(end+1) = t(min(i1+1, numel(t))) - t(1); end %#ok<AGROW>
    end
end
w = max(3, 2*round(4/h/2) + 1);       % 4 s 창 / a four-second window
M.u    = mean_or_nan(ur);   M.ye   = mean_or_nan(ye);
M.hold = mean_or_nan(hd);   M.tset = mean_or_nan(ts);
M.r    = sqrt(mean(r(keep).^2));
if any(m2), M.Nhf = std(R.Nm(m2) - movmean(R.Nm(m2), w)); else, M.Nhf = NaN; end
M.legs = numel(hd);
end

function y = mean_or_nan(x)
if isempty(x), y = NaN; else, y = mean(x); end
end
