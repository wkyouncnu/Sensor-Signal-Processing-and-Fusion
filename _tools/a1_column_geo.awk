# a1_column_geo.awk — figures/a1-column-rule.svg 의 기하를 계산한다.
#   열 규칙  b = [e_x ; e_y ; x e_y - y e_x]  의 세 번째 성분이 정말
#   "원점에서 작용선까지의 수직거리" 와 같은지 확인하면서 좌표를 뽑는다.
BEGIN {
    PI = 3.14159265358979
    S  = 100                       # 1 m = 100 px
    OX = 210; OY = 350             # o_b 화면 좌표
    x = 1.2; y = 0.8               # 추진기 위치 r = (x, y) [m], x 앞 / y 우현
    a = -40                        # e 의 방향, x_b 에서 잰 각 [deg]
    ex = cos(a*PI/180); ey = sin(a*PI/180)
    N  = x*ey - y*ex               # 열 규칙의 세 번째 성분

    # 화면: x_b 는 위(-y), y_b 는 오른쪽(+x)
    TX = OX + y*S;  TY = OY - x*S
    L  = 110
    dxs = ey; dys = -ex            # e 의 화면 방향
    printf "thruster  r=(%.1f,%.1f) -> screen (%.1f,%.1f)\n", x, y, TX, TY
    printf "e         (%.4f,%.4f)  angle %g deg from x_b\n", ex, ey, a
    printf "tip       (%.1f,%.1f)\n", TX+L*dxs, TY+L*dys
    printf "e_x part  (%.1f,%.1f) -> (%.1f,%.1f)\n", TX, TY, TX, TY-ex*L
    printf "e_y part  (%.1f,%.1f) -> (%.1f,%.1f)\n", TX, TY-ex*L, TX+ey*L, TY-ex*L
    printf "N = x ey - y ex = %.4f m  (per newton)\n", N

    # 원점에서 작용선에 내린 수선의 발
    vx = OX-TX; vy = OY-TY
    t  = vx*dxs + vy*dys
    FX = TX + t*dxs; FY = TY + t*dys
    d  = sqrt((OX-FX)^2 + (OY-FY)^2)
    printf "foot F    (%.1f,%.1f)   |o_b F| = %.1f px = %.4f m\n", FX, FY, d, d/S
    printf "CHECK     |N| = %.4f m  against arm %.4f m  -> diff %.2e\n", (N<0?-N:N), d/S, (N<0?-N:N)-d/S
    # 작용선을 양쪽으로 늘린 끝점
    printf "line ext  (%.1f,%.1f) .. (%.1f,%.1f)\n", TX-1.1*L*dxs, TY-1.1*L*dys, TX+1.35*L*dxs, TY+1.35*L*dys
}
