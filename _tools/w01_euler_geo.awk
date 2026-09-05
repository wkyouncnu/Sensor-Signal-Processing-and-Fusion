# w01_euler_geo.awk — assets/w01-euler.svg 의 네 좌표계 그림을 계산한다.
#
# zyx 오일러각을 "돌아간 그림"으로 보여준다. 축을 눈대중으로 기울이지 않고
# 실제 회전행렬을 곱해서 정사영한다 (standing-orders.md §3-2).
#
#   {n} --Rz(psi)--> {1} --Ry(theta)--> {2} --Rx(phi)--> {b}
#
# 각 단계의 좌표축은 그 단계 회전행렬의 열이고, 갑판판은 그 행렬을 곱한 것이다.
# 회전이 일어나는 축 둘레에는 그 축에 수직인 원(= 사영하면 타원)을 그린다.
#
# 사용법:  awk -f w01_euler_geo.awk > _geo.svg

BEGIN {
    PI = 3.14159265358979; D = PI / 180

    # ---- 정사영. 화면 오른쪽 r 과 화면 아래 d 는 3차원의 직교 단위벡터다 ----
    P11 = 0.87687; P12 = 0.48072; P13 = 0.00000
    P21 = -0.21477; P22 = 0.39176; P23 = 0.89465
    S = 52; OY = 205

    OX[0] = 108; OX[1] = 328; OX[2] = 548; OX[3] = 768
    NM[0] = "n";  NM[1] = "1";  NM[2] = "2";  NM[3] = "b"

    psi = 40; th = 20; ph = 30      # 눈에 보이게 넉넉히 잡은 각

    # 회전축 이름표를 축의 어느 쪽으로 비킬지. 칸마다 비어 있는 쪽이 다르다
    PSGN[0] = 1; PSGN[1] = -1; PSGN[2] = 1; PSGN[3] = 0

    AXLEN = 1.25                    # 축 길이 [단위]
    ARCD  = 1.45                    # 모멘트 호 중심까지의 거리
    ARCR  = 0.28                    # 호 반지름

    # 갑판판 — 선수가 +x 인 평면 다각형
    np = 7
    px[1] =  1.00; py[1] =  0.00
    px[2] =  0.55; py[2] =  0.42
    px[3] = -0.85; py[3] =  0.42
    px[4] = -1.00; py[4] =  0.24
    px[5] = -1.00; py[5] = -0.24
    px[6] = -0.85; py[6] = -0.42
    px[7] =  0.55; py[7] = -0.42

    # ---- 단계별 회전행렬 ----
    eye(R0)
    rotz(psi, Rz);            copy(Rz, R1)
    roty(th,  Ry); mul(R1, Ry, R2)
    rotx(ph,  Rx); mul(R2, Rx, R3)

    for (k = 0; k <= 3; k++) {
        if      (k == 0) copy(R0, M)
        else if (k == 1) copy(R1, M)
        else if (k == 2) copy(R2, M)
        else             copy(R3, M)
        panel(k, M)
    }
}

# ---------------------------------------------------------------- 한 칸 그리기
function panel(k, M,    i, a, u1,u2,u3, w1,w2,w3, ax1,ax2,ax3, col, wid, s) {

    printf "  <!-- ============ panel %d : {%s} ============ -->\n", k, NM[k]

    # {n} 의 수평면 — 갑판이 얼마나 기울었는지 이것과 비교해서 읽는다
    printf "  <polygon points=\""
    printf "%s %s %s %s", pt(k,1,1,0), pt(k,1,-1,0), pt(k,-1,-1,0), pt(k,-1,1,0)
    printf "\" fill=\"#f2f5f8\" stroke=\"#d3dae1\" stroke-width=\"1\" stroke-dasharray=\"5 4\"/>\n"

    # 갑판판 — 이 단계의 자세로 회전시킨다
    printf "  <polygon points=\""
    for (i = 1; i <= np; i++) {
        rot(M, px[i], py[i], 0, V)
        printf "%s ", pt(k, V[1], V[2], V[3])
    }
    printf "\" fill=\"#F7DCBE\" fill-opacity=\"0.92\" stroke=\"#8a5a2b\" stroke-width=\"1.8\"/>\n"

    # 세 축. 다음에 회전할 축은 파랑으로 굵게 — 그것이 이 칸의 주인공이다
    a = (k == 0 ? 3 : (k == 1 ? 2 : (k == 2 ? 1 : 0)))
    for (i = 1; i <= 3; i++) {
        col = (i == a ? "#0073BD" : "#1b3a5c")
        wid = (i == a ? "3"       : "2")
        s   = (i == a ? "r"       : "a")
        rot(M, (i==1), (i==2), (i==3), V)
        printf "  <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%s\" ", OX[k], OY, xy(k, AXLEN*V[1], AXLEN*V[2], AXLEN*V[3])
        printf "stroke=\"%s\" stroke-width=\"%s\" marker-end=\"url(#%s)\"/>\n", col, wid, s
        # 회전하는 축의 이름표는 축 끝에서 **옆으로** 비킨다. 축 위에 두면 호 안에 갇히고,
        # 호 바깥으로 더 밀면 축에서 떨어져 보인다. PSGN 은 어느 쪽으로 비킬지의 부호다.
        label(k, i, V, col, (i == a ? PSGN[k]*29 : 0))
    }
    printf "  <circle cx=\"%.2f\" cy=\"%.2f\" r=\"3.6\" fill=\"#1b3a5c\"/>\n", OX[k], OY

    # 회전 호 — 축 a 에 수직인 평면 위의 원. 오른손 법칙 순서대로 u -> w
    if (a) {
        if      (a == 3) { pick(M,1,U); pick(M,2,W) }   # z 둘레: x -> y
        else if (a == 2) { pick(M,3,U); pick(M,1,W) }   # y 둘레: z -> x
        else             { pick(M,2,U); pick(M,3,W) }   # x 둘레: y -> z
        pick(M, a, A)
        arc(k, A, U, W)
    }

    printf "  <text x=\"%.2f\" y=\"344\" font-size=\"15\" font-weight=\"600\" fill=\"#1b3a5c\" text-anchor=\"middle\">{%s}</text>\n", OX[k], NM[k]
    printf "\n"
}

# 축 이름표. perp == 0 이면 축 끝에서 축 방향으로 15 px,
# perp != 0 이면 축 끝에서 축에 **수직으로** perp px (부호가 어느 쪽인지 정한다).
function label(k, i, V, col, perp,    tx, ty, ox, oy, L, nx, ny) {
    tx = sx(AXLEN*V[1], AXLEN*V[2], AXLEN*V[3]); ty = sy(AXLEN*V[1], AXLEN*V[2], AXLEN*V[3])
    L = sqrt(tx*tx + ty*ty); if (L < 1) L = 1
    nx = tx / L; ny = ty / L
    if (perp) { ox = OX[k] + tx - perp*ny; oy = OY + ty + perp*nx + 4 }
    else      { ox = OX[k] + tx + 15*nx;   oy = OY + ty + 15*ny + 4 }
    printf "  <text x=\"%.2f\" y=\"%.2f\" font-size=\"12\" font-weight=\"600\" fill=\"%s\" text-anchor=\"middle\">%s<tspan font-size=\"9\" dy=\"3\">%s</tspan></text>\n", \
           ox, oy, col, (i==1 ? "x" : (i==2 ? "y" : "z")), NM[k]
}

# 축 A 둘레의 회전 호. 중심은 축선 위에 있고, 점선으로 축과 잇는다.
function arc(k, A, U, W,    i, t, cx, cy, c1, c2, c3, d) {
    c1 = ARCD*A[1]; c2 = ARCD*A[2]; c3 = ARCD*A[3]
    printf "  <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%s\" stroke=\"#9aa4b0\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/>\n", \
           OX[k] + sx(AXLEN*A[1],AXLEN*A[2],AXLEN*A[3]), OY + sy(AXLEN*A[1],AXLEN*A[2],AXLEN*A[3]), xy(k, c1, c2, c3)
    d = ""
    for (i = 0; i <= 60; i++) {
        t = (40 + 300*i/60) * D
        d = d sprintf("%s%.2f,%.2f ", (i ? "L " : "M "), \
            OX[k] + sx(c1 + ARCR*(cos(t)*U[1] + sin(t)*W[1]), c2 + ARCR*(cos(t)*U[2] + sin(t)*W[2]), c3 + ARCR*(cos(t)*U[3] + sin(t)*W[3])), \
            OY    + sy(c1 + ARCR*(cos(t)*U[1] + sin(t)*W[1]), c2 + ARCR*(cos(t)*U[2] + sin(t)*W[2]), c3 + ARCR*(cos(t)*U[3] + sin(t)*W[3])))
    }
    printf "  <path d=\"%s\" fill=\"none\" stroke=\"#0073BD\" stroke-width=\"2.4\" marker-end=\"url(#r)\"/>\n", d
    printf "  <circle cx=\"%.2f\" cy=\"%.2f\" r=\"2.4\" fill=\"#0073BD\"/>\n", OX[k] + sx(c1,c2,c3), OY + sy(c1,c2,c3)
}

# ------------------------------------------------------------------ 잔 도구들
function sx(v1, v2, v3) { return S * (P11*v1 + P12*v2 + P13*v3) }
function sy(v1, v2, v3) { return S * (P21*v1 + P22*v2 + P23*v3) }
function pt(k, v1, v2, v3) { return sprintf("%.2f,%.2f", OX[k] + sx(v1,v2,v3), OY + sy(v1,v2,v3)) }
function xy(k, v1, v2, v3) { return sprintf("%.2f\" y2=\"%.2f", OX[k] + sx(v1,v2,v3), OY + sy(v1,v2,v3)) }

function pick(M, i, C) { C[1] = M[i]; C[2] = M[3+i]; C[3] = M[6+i] }
function rot(M, v1, v2, v3, C) {
    C[1] = M[1]*v1 + M[2]*v2 + M[3]*v3
    C[2] = M[4]*v1 + M[5]*v2 + M[6]*v3
    C[3] = M[7]*v1 + M[8]*v2 + M[9]*v3
}
function eye(R,  i)  { for (i = 1; i <= 9; i++) R[i] = 0; R[1] = R[5] = R[9] = 1 }
function copy(A, B,  i) { for (i = 1; i <= 9; i++) B[i] = A[i] }
function mul(A, B, C,  i, j, k2, s) {
    for (i = 0; i < 3; i++) for (j = 1; j <= 3; j++) {
        s = 0; for (k2 = 0; k2 < 3; k2++) s += A[3*i + k2 + 1] * B[3*k2 + j]
        T[3*i + j] = s
    }
    copy(T, C)
}
function rotz(a, R) { a *= D; eye(R); R[1] =  cos(a); R[2] = -sin(a); R[4] = sin(a); R[5] = cos(a) }
function roty(a, R) { a *= D; eye(R); R[1] =  cos(a); R[3] =  sin(a); R[7] = -sin(a); R[9] = cos(a) }
function rotx(a, R) { a *= D; eye(R); R[5] =  cos(a); R[6] = -sin(a); R[8] = sin(a); R[9] = cos(a) }
