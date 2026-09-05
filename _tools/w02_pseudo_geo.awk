# w02_pseudo_geo.awk — figures/w02-pseudo-derivative.svg 의 곡선 좌표를 계산한다.
#
#   눈대중으로 그리면 평탄부의 높이가 Kd*N 과 맞지 않는다. 실제 크기응답을
#   계산해서 폴리라인으로 뽑는다.
#
#       ideal      D(jw) = Kd * jw            -> |D| = Kd w          (끝없이 상승)
#       pseudo     D(jw) = Kd N jw / (jw + N) -> |D| = Kd N w / sqrt(w^2 + N^2)
#                                                -> Kd w   (w << N)
#                                                -> Kd N   (w >> N)   평탄
#
#   사용법:  awk -f _tools/w02_pseudo_geo.awk
BEGIN {
    Kd = 2
    X0 = 95; Y0 = 96; W = 420; H = 300          # 그림틀
    wmin = 0.1; wmax = 1000                     # 가로 (rad/s)
    mmin = 0.1; mmax = 3000                     # 세로 (크기)
    lwmin = log(wmin)/log(10); lwmax = log(wmax)/log(10)
    lmmin = log(mmin)/log(10); lmmax = log(mmax)/log(10)

    printf "  <!-- computed by _tools/w02_pseudo_geo.awk : Kd=%g -->\n", Kd

    curve("ideal", 0)                            # N=0 -> 이상 미분
    curve("pseudo100", 100)
    curve("pseudo10", 10)

    #  평탄부의 높이 확인 — 그림에 적을 값
    printf "  <!-- plateau Kd*N : N=10 -> %g , N=100 -> %g -->\n", Kd*10, Kd*100
    printf "  <!-- CHECK |D| at w=1000 : ideal %g , N=10 %g , N=100 %g -->\n", \
           Kd*1000, mag(1000,10), mag(1000,100)
    #  축 눈금 좌표
    for (e = -1; e <= 3; e++) printf "  <!-- xtick 1e%d at x=%.2f -->\n", e, X(10^e)
    for (e = -1; e <= 3; e++) printf "  <!-- ytick 1e%d at y=%.2f -->\n", e, Y(10^e)
}
function mag(w, N) { if (N == 0) return Kd*w; return Kd*N*w/sqrt(w*w + N*N) }
function X(w) { return X0 + W*(log(w)/log(10) - lwmin)/(lwmax - lwmin) }
function Y(m) { return Y0 + H - H*(log(m)/log(10) - lmmin)/(lmmax - lmmin) }
function curve(name, N,   i, w, m, s, n) {
    s = ""; n = 0
    for (i = 0; i <= 120; i++) {
        w = 10^(lwmin + (lwmax-lwmin)*i/120)
        m = mag(w, N)
        if (m > mmax) m = mmax
        if (m < mmin) continue
        s = s sprintf("%.1f,%.1f ", X(w), Y(m))
        n++
    }
    printf "  <!-- %s (%d pts) -->\n  <polyline points=\"%s\"/>\n", name, n, s
}
