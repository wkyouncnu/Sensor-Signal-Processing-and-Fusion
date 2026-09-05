# w02_windup_geo.awk — figures/w02-windup.svg 의 포화 곡선 좌표를 계산한다.
#   가로축 X_cmd, 세로축 X_sat. 한계는 A1-6 의 도달가능 집합에서 온다.
BEGIN {
    lo = -133.42; hi = 239.36            # X_sat 한계 [N]
    cmax = 3480.0                        # section F 가 측정한 X_cmd 최대값
    x0 = -500; x1 = 3700                 # 가로 범위
    y0 = -220; y1 = 320                  # 세로 범위
    PX0 = 545; PW = 325                  # 화면 가로
    PY0 = 130; PH = 200                  # 화면 세로 (위가 작다)

    printf "sat curve:\n"
    pt(x0, lo); pt(lo, lo); pt(hi, hi); pt(x1, hi)
    printf "\nmarks:\n"
    printf "  X_cmd = %.0f  -> x = %.1f\n", cmax, X(cmax)
    printf "  X_sat = %.2f  -> y = %.1f\n", hi, Y(hi)
    printf "  X_sat = %.2f  -> y = %.1f\n", lo, Y(lo)
    printf "  zero  -> x = %.1f , y = %.1f\n", X(0), Y(0)
    printf "  ratio X_cmd/X_max = %.1f\n", cmax/hi
    printf "\nticks x:"
    for (v = 0; v <= 3500; v += 500) printf " %d@%.1f", v, X(v)
    printf "\nticks y:"
    for (v = -100; v <= 300; v += 100) printf " %d@%.1f", v, Y(v)
    printf "\n"
}
function X(v) { return PX0 + PW*(v - x0)/(x1 - x0) }
function Y(v) { return PY0 + PH - PH*(v - y0)/(y1 - y0) }
function pt(a, b) { printf "  (%8.1f,%8.2f) -> %.1f,%.1f\n", a, b, X(a), Y(b) }
