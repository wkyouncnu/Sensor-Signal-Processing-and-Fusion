# w01_6dof_arcs.awk — assets/w01-6dof.svg 의 모멘트 호를 계산한다.
#
# 그림은 진짜 정사영(orthographic projection)이다. 화면 오른쪽 r, 화면 아래 d 는
# 3차원에서 서로 직교하는 단위벡터이고, 점 v 는 (v·r, v·d) 로 찍힌다.
#
#   alpha = 28.712 deg, beta = 26.53 deg 일 때
#   P(x) = ( 0.87687, -0.21477)   선수  — 오른쪽 위, 관측자에서 멀어진다
#   P(y) = ( 0.48072,  0.39176)   우현  — 오른쪽 아래, 관측자 쪽
#   P(z) = ( 0.00000,  0.89465)   아래
#
# 축 a 에 대한 모멘트는 a 에 수직인 평면 위의 원이다. 그 원을 위 사영으로 찍으면
# 타원이 되고, 타원의 중심은 반드시 축선 위에 앉는다. 오른손 법칙이므로
#   x 축 둘레: y -> z,   y 축 둘레: z -> x,   z 축 둘레: x -> y
# 방향으로 매개변수를 증가시키고, 마지막 점에 화살촉을 단다.
#
# 사용법:  awk -f w01_6dof_arcs.awk        (인수 없음; _k.txt/_m.txt/_n.txt 를 쓴다)

BEGIN {
    PI = 3.14159265358979

    # 화면 원점 o_b, 그리고 105 px 을 1 단위로 놓은 축 사영
    Ox = 200; Oy = 215
    Ax =  92.071; Ay = -22.551      # P(x) * 105
    Bx =  50.476; By =  41.135      # P(y) * 105
    Zx =   0.000; Zy =  93.938      # P(z) * 105

    rho = 0.32                      # 모멘트 원의 반지름 [단위]
    t0  = 40; t1 = 340; nseg = 60   # 300 deg 만 그려 틈을 남긴다

    # --- K: x 축 둘레. 원은 y-z 평면 위에 있고 중심은 x = 2.60 ---
    kx = Ox + Ax*2.60;  ky = Oy + Ay*2.60
    emit(kx, ky, rho*Bx, rho*By, rho*Zx, rho*Zy, "_k.txt")

    # --- M: y 축 둘레. 원은 z-x 평면 위에 있고 중심은 y = 2.85 ---
    mx = Ox + Bx*2.85;  my = Oy + By*2.85
    emit(mx, my, rho*Zx, rho*Zy, rho*Ax, rho*Ay, "_m.txt")

    # --- N: z 축 둘레. 원은 x-y 평면 위에 있고 중심은 z = 2.35 ---
    nx = Ox + Zx*2.35;  ny = Oy + Zy*2.35
    emit(nx, ny, rho*Ax, rho*Ay, rho*Bx, rho*By, "_n.txt")
}

# 중심 (cx,cy), 켤레 반지름 (ux,uy) 과 (wx,wy) 인 타원호를 꺾은선으로 쓴다.
# 매개변수: p(t) = C + cos(t)*u + sin(t)*w  —  u 에서 w 로 도는 것이 양의 방향이다.
function emit(cx, cy, ux, uy, wx, wy, path,    i, t, x, y, d) {
    d = ""
    for (i = 0; i <= nseg; i++) {
        t = (t0 + (t1 - t0) * i / nseg) * PI / 180
        x = cx + cos(t)*ux + sin(t)*wx
        y = cy + cos(t)*uy + sin(t)*wy
        d = d sprintf("%s%.2f,%.2f ", (i == 0 ? "M " : "L "), x, y)
    }
    printf "%s", d > path
    close(path)
}
