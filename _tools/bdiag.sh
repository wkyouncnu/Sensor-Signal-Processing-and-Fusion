#  bdiag.sh — 논문 그림처럼 보이는 블록선도 프리미티브.
#
#      source _tools/bdiag.sh
#
#  왜 있는가. 손으로 그린 SVG 가 "어설퍼" 보이는 이유는 대개 내용이 아니라
#  형식이다. 저널 그림과 나란히 놓고 보면 차이가 네 가지로 좁혀진다.
#
#    ① 선 굵기가 제각각이다        -> 신호선 하나, 블록 테두리 하나로 고정
#    ② 화살촉이 크고 둥글다        -> 작고 뾰족한 삼각형 하나로 통일
#    ③ 상자가 알록달록하고 둥글다  -> 흰 바탕, 직각, 검은 테두리
#    ④ 색을 장식으로 쓴다          -> 색은 **강조 하나**에만 쓴다
#
#  여기서 나오는 도형은 전부 그 넷을 지킨다. 수식은 tex2svg.sh 가 조판한다.
#
#  좌표 규약: 블록은 (x, y) 가 **왼쪽 위**, 합산점은 (x, y) 가 **중심**.
#  신호선의 y 는 블록 높이의 중앙에 맞춘다.

BD_INK='#1a1a1a'        # 선과 글자
BD_SIG=1.15             # 신호선 굵기
BD_BOX=1.35             # 블록 테두리 굵기
BD_ACC='#7c3aed'        # 강조색 — 한 그림에 한 가지만

#  defs — 그림마다 한 번
bd_defs() {
  cat <<EOF
  <defs>
    <marker id="ah" markerWidth="7" markerHeight="5.2" refX="6.6" refY="2.6"
            orient="auto" markerUnits="userSpaceOnUse">
      <path d="M0,0 L7,2.6 L0,5.2 z" fill="$BD_INK"/></marker>
    <marker id="ahA" markerWidth="7" markerHeight="5.2" refX="6.6" refY="2.6"
            orient="auto" markerUnits="userSpaceOnUse">
      <path d="M0,0 L7,2.6 L0,5.2 z" fill="$BD_ACC"/></marker>
  </defs>
EOF
}

#  bd_blk x y w h            — 빈 블록 (라벨은 tex2svg 로 따로 얹는다)
bd_blk() {
  printf '  <rect x="%s" y="%s" width="%s" height="%s" fill="#ffffff" stroke="%s" stroke-width="%s"/>\n' \
         "$1" "$2" "$3" "$4" "$BD_INK" "$BD_BOX"
}

#  bd_sum cx cy             — 합산점. 반지름 9, 흰 바탕
bd_sum() {
  printf '  <circle cx="%s" cy="%s" r="9" fill="#ffffff" stroke="%s" stroke-width="%s"/>\n' \
         "$1" "$2" "$BD_INK" "$BD_BOX"
}

#  bd_sign x y ch           — 합산점 옆의 + / −. 작게, 선 밖에
bd_sign() {
  printf '  <text x="%s" y="%s" font-size="11" fill="%s" text-anchor="middle">%s</text>\n' \
         "$1" "$2" "$BD_INK" "$3"
}

#  bd_sig x1 y1 x2 y2       — 화살표 있는 신호선
bd_sig() {
  printf '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" marker-end="url(#ah)"/>\n' \
         "$1" "$2" "$3" "$4" "$BD_INK" "$BD_SIG"
}

#  bd_wire x1 y1 x2 y2      — 화살표 없는 연결선 (꺾이는 도중)
bd_wire() {
  printf '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>\n' \
         "$1" "$2" "$3" "$4" "$BD_INK" "$BD_SIG"
}

#  bd_sigA / bd_wireA       — 강조색 판
bd_sigA() {
  printf '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-dasharray="5 3" marker-end="url(#ahA)"/>\n' \
         "$1" "$2" "$3" "$4" "$BD_ACC" "$BD_SIG"
}
bd_wireA() {
  printf '  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-dasharray="5 3"/>\n' \
         "$1" "$2" "$3" "$4" "$BD_ACC" "$BD_SIG"
}

#  bd_dot x y               — 분기점
bd_dot() {
  printf '  <circle cx="%s" cy="%s" r="2.6" fill="%s"/>\n' "$1" "$2" "$BD_INK"
}

#  bd_note x y size anchor text   — 그림 안의 짧은 설명 (수식 아님)
bd_note() {
  printf '  <text x="%s" y="%s" font-size="%s" fill="%s" text-anchor="%s">%s</text>\n' \
         "$1" "$2" "$3" "$BD_INK" "$4" "$5"
}
