# w04_track_curves.awk — LOS 로 경로에 붙는 궤적을 법칙에서 직접 적분한다.
#
#     awk -f _tools/w04_track_curves.awk > figures/src/w04-tracks.tex
#
# 왜. 개념도의 곡선을 손으로 그리면 "이 법칙이 정말 저렇게 수렴하는가" 를
# 그림이 증명하지 못한다. LOS 의 닫힌 운동학은 초등적으로 적분되지 않지만
# 수치적으로는 세 줄이다. 호길이 s 로 매개하면
#
#     chi - pi_p = -atan(y_e / Delta)
#     dy/ds = sin(chi - pi_p) = -y / sqrt(Delta^2 + y^2)
#     dx/ds = cos(chi - pi_p) =  Delta / sqrt(Delta^2 + y^2)
#
# 이고, 이것이 그림에 그려지는 곡선의 전부다.
#
# 출력은 TikZ 좌표 목록 매크로 넷:
#   \LOStrack   \LOStrackTwo   (Delta 가 다른 두 경우)
#   \ATANtrack                 (비교용 직선 — 웨이포인트를 겨냥한다)
BEGIN {
    XS = 0.60          # 1 m -> mm (가로)
    YS = 0.60          # 1 m -> mm (세로)
    Y0 = -18           # 출발 시 cross-track error [m]
    XEND = 100         # 다리 길이 [m]
    ds = 0.25

    emit("LOStrack",    8,  Y0)
    emit("LOStrackTwo", 20, Y0)

    #  atan2 는 웨이포인트를 겨냥하므로 궤적이 직선이다 — 적분할 것이 없다
    printf "\\def\\ATANtrack{(%.2f,%.2f) (%.2f,%.2f)}\n", 0*XS, Y0*YS, XEND*XS, 0

    #  그림에 적을 수치 — 눈으로 읽지 않게 계산해서 남긴다
    printf "%% CHECK  Delta=8  : y_e at x=40 m -> %.3f m\n",  yat(8, Y0, 40)
    printf "%% CHECK  Delta=20 : y_e at x=40 m -> %.3f m\n",  yat(20, Y0, 40)
}

function emit(name, Delta, y,    x, s, out, n) {
    x = 0; out = sprintf("(%.2f,%.2f)", 0, y*YS); n = 1
    while (x < XEND) {
        r = sqrt(Delta*Delta + y*y)
        x = x + ds * Delta / r
        y = y + ds * (-y) / r
        n++
        if (n % 8 == 0 || x >= XEND)
            out = out sprintf(" (%.2f,%.2f)", x*XS, y*YS)
    }
    printf "\\def\\%s{%s}\n", name, out
}

#  x 위치에서의 y_e — 그림에 적을 값을 계산으로 얻는다
function yat(Delta, y, xtarget,    x, r) {
    x = 0
    while (x < xtarget) {
        r = sqrt(Delta*Delta + y*y)
        x = x + ds * Delta / r
        y = y + ds * (-y) / r
    }
    return y
}
