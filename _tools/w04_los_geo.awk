# w04_los_geo.awk — the coordinates behind figures/w04-los-geometry.svg
#
#   awk -f _tools/w04_los_geo.awk
#
# The LOS figure contains a RIGHT TRIANGLE whose angle is arctan(y_e/Delta),
# and the number printed on the figure has to be the angle actually drawn.
# Eyeballing it puts the two a few degrees apart, which a reader with a
# protractor will find. So the geometry is computed here and the numbers are
# pasted into the SVG.
#
# The scene, in metres, then mapped to screen pixels:
#
#   wp_k     the active waypoint, at the origin of the path frame
#   wp_next  the next one, along pi_p from it
#   P        the vessel, x_e along the leg and y_e to starboard of it
#   F        the foot of the perpendicular from P to the leg
#   A        the aim point, Delta further along the leg from F
#
# psi_d is the direction from P to A, and the claim of the figure is
#
#   psi_d = pi_p - atan(y_e / Delta)
#
# which the check at the end verifies from the drawn coordinates.

BEGIN {
    PI = 3.14159265358979

    # ---- the scene, in metres --------------------------------------------
    # 62 deg rather than something gentler: the canvas is wide and the path
    # has to use it, and a leg that is neither axis-aligned nor 45 deg stops
    # any coincidence from hiding a transposed sine.
    pi_p_deg = 62.0            # leg direction, from North
    x_e      = 26.0            # how far along the leg the vessel is
    y_e      = 12.0            # how far to starboard of it
    Delta    = 20.0            # look-ahead distance
    leg      = 68.0            # length of the leg
    R        = 9.0             # acceptance radius

    pi_p = pi_p_deg*PI/180
    tx   = cos(pi_p);  ty = sin(pi_p)      # unit vector along the leg  (N,E)
    nx   = -sin(pi_p); ny = cos(pi_p)      # unit normal, to starboard

    # ---- the points, in NED metres ---------------------------------------
    wpk_N = 0;            wpk_E = 0
    wpn_N = leg*tx;       wpn_E = leg*ty
    F_N   = x_e*tx;       F_E   = x_e*ty
    P_N   = F_N + y_e*nx; P_E   = F_E + y_e*ny
    A_N   = (x_e+Delta)*tx; A_E = (x_e+Delta)*ty

    # ---- the angle the figure claims -------------------------------------
    psi_d      = pi_p - atan2(y_e, Delta)
    psi_drawn  = atan2(A_E - P_E, A_N - P_N)
    corr_deg   = atan2(y_e, Delta)*180/PI

    printf "  scene, in metres\n"
    printf "    pi_p        %8.3f deg\n", pi_p_deg
    printf "    x_e         %8.3f m\n", x_e
    printf "    y_e         %8.3f m\n", y_e
    printf "    Delta       %8.3f m\n", Delta
    printf "    atan(y_e/Delta) = %6.3f deg\n", corr_deg
    printf "    psi_d       %8.3f deg   (pi_p - atan(y_e/Delta))\n", psi_d*180/PI
    printf "    psi drawn   %8.3f deg   (the direction P -> A)\n", psi_drawn*180/PI
    printf "    CHECK       %8.2e deg difference\n\n", (psi_d-psi_drawn)*180/PI

    # ---- to screen pixels -------------------------------------------------
    # North is UP on the page and East is RIGHT, so screen x = E, screen y = -N.
    s   = 6.0                      # pixels per metre
    ox  =  95; oy = 405            # the origin of the path frame, in pixels

    printf "  screen, in pixels (x = ox + s*E,  y = oy - s*N)\n"
    printf "    s = %g px/m, origin (%g, %g)\n\n", s, ox, oy
    px("wp_k",    wpk_N, wpk_E, s, ox, oy)
    px("wp_next", wpn_N, wpn_E, s, ox, oy)
    px("F  foot", F_N,   F_E,   s, ox, oy)
    px("P  boat", P_N,   P_E,   s, ox, oy)
    px("A  aim",  A_N,   A_E,   s, ox, oy)
    printf "    R in pixels  %8.2f\n", R*s
    printf "\n  paste these into figures/w04-los-geometry.svg\n"
}

function px(name, N, E, s, ox, oy) {
    printf "    %-10s  (%8.2f, %8.2f)\n", name, ox + s*E, oy - s*N
}
